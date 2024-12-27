#!/usr/bin/env ruby

require 'http'
require 'dotenv'
require 'redcarpet'
require 'json'
require 'base64'
require 'mime/types'

# Load environment variables
Dotenv.load

# Terminal output helper
def log(message, type = :info)
  timestamp = Time.now.strftime('%H:%M:%S')
  color = case type
          when :info then "\e[34m"    # Blue
          when :success then "\e[32m"  # Green
          when :warning then "\e[33m"  # Yellow
          when :error then "\e[31m"    # Red
          when :debug then "\e[36m"    # Cyan
          else "\e[0m"                 # Default
          end
  STDOUT.puts "#{color}[#{timestamp}] #{message}\e[0m"
end

# Configuration validation
begin
  log "=== Environment Configuration ===", :info
  if ENV['RESEND_API_KEY'].to_s.empty?
    log "⚠️ No RESEND_API_KEY found in .env", :error
    exit 1
  end

  SENDER_EMAIL = ENV['SENDER_EMAIL']
  if SENDER_EMAIL.to_s.empty?
    log "⚠️ No SENDER_EMAIL found in .env", :error
    exit 1
  end

  RECIPIENT_EMAIL = ENV['RECIPIENT_EMAIL']
  if RECIPIENT_EMAIL.to_s.empty?
    log "⚠️ No RECIPIENT_EMAIL found in .env", :error
    exit 1
  end

  log "Configuration validated successfully!", :success
rescue StandardError => e
  log "💥 Error during configuration: #{e.message}", :error
  exit 1
end

# Redcarpet Renderer for Markdown
class ImagePathRenderer < Redcarpet::Render::HTML
  attr_reader :base_dir

  def initialize(base_dir)
    @base_dir = base_dir
    super()
  end

  def image(link, title, alt_text)
    if link.start_with?('http://', 'https://')
      log "🌐 Processing URL image: #{link}", :info
      %(<img src="#{link}" alt="#{alt_text}"#{title ? %[ title="#{title}"] : ''} />)
    else
      image_path = File.join(base_dir, link)
      if File.exist?(image_path)
        begin
          mime_type = MIME::Types.type_for(image_path).first.to_s
          content_id = "#{File.basename(image_path)}@example.com"
          
          # Add image as attachment
          ImagePathRenderer.image_attachments << { path: image_path, mime_type: mime_type, content_id: content_id }
  
          # Replace inline image with a note
          log "📝 Replacing inline image with text note for #{File.basename(image_path)}", :info
          %(<p><em>[Image: #{alt_text} - see attached file: #{File.basename(image_path)}]</em></p>)
        rescue StandardError => e
          log "⚠️ Failed to process image #{link}: #{e.message}", :error
          %(<p><em>[Error loading image: #{alt_text}]</em></p>)
        end
      else
        log "⚠️ Image not found: #{link}", :warning
        %(<p><em>[Image not found: #{alt_text}]</em></p>)
      end
    end
  end  

  @image_attachments = []
  class << self
    attr_accessor :image_attachments
  end
end

# Generate email body from Markdown
def generate_report(directory)
  files = Dir.glob("#{directory}/*.{md,html}")
  content = files.map { |file| File.read(file) }.join("\n\n")
  renderer = ImagePathRenderer.new(directory)
  markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true, fenced_code_blocks: true)
  markdown.render(content)
end

# Prepare email payload
def send_email(subject, html_content)
  attachments = ImagePathRenderer.image_attachments.map do |attachment|
    {
      content: Base64.strict_encode64(File.binread(attachment[:path])),
      filename: File.basename(attachment[:path]),
      type: attachment[:mime_type],
      disposition: "inline",
      content_id: attachment[:content_id]
    }
  end

  payload = {
    from: ENV['SENDER_EMAIL'],
    to: ENV['RECIPIENT_EMAIL'],
    subject: subject,
    html: html_content,
    attachments: attachments
  }

  response = HTTP.auth("Bearer #{ENV['RESEND_API_KEY']}")
                 .post('https://api.resend.com/emails', json: payload)

  if response.status.success?
    log "📧 Email sent successfully!", :success
  else
    log "⚠️ Failed to send email. Response: #{response.body}", :error
  end
end

# Main process
if __FILE__ == $0
  begin
    log "🚀 Starting Email Report Generator", :info
    report_directory = './reports'
    report_content = generate_report(report_directory)
    email_subject = "Your Report for #{Time.now.strftime('%Y-%m-%d')}"
    send_email(email_subject, report_content)
    log "✨ Process completed!", :success
  rescue StandardError => e
    log "💥 Fatal error: #{e.message}", :error
  end
end
