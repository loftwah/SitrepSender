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
def generate_report(directory, report_period = "Weekly")
  files = Dir.glob("#{directory}/*.{md,html}")
  if files.empty?
    log "⚠️ No content found in #{directory}, skipping report generation.", :warning
    return nil
  end

  content = files.map { |file| File.read(file) }.join("\n\n")
  renderer = ImagePathRenderer.new(directory)
  markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true, fenced_code_blocks: true)

  html_content = markdown.render(content)

  # Wrap the HTML content in a styled template
  <<-HTML
    <html>
      <head>
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f4f4f9;
            margin: 0;
            padding: 0;
          }
          .wrapper {
            max-width: 600px;
            margin: 0 auto;
            background: #fff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          }
          .header {
            background: #4CAF50;
            color: #fff;
            padding: 20px;
            text-align: center;
          }
          .content {
            padding: 20px;
          }
          .content h1, .content h2, .content h3 {
            color: #4CAF50;
          }
          .content p {
            margin: 1em 0;
          }
          .content table {
            border-collapse: collapse;
            width: 100%;
            margin: 1em 0;
          }
          .content table th, .content table td {
            border: 1px solid #ddd;
            padding: 8px;
          }
          .content table th {
            background: #f4f4f4;
          }
          .content img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 10px 0;
          }
          .footer {
            text-align: center;
            padding: 10px;
            background: #f4f4f4;
            color: #666;
          }
        </style>
      </head>
      <body>
        <div class="wrapper">
          <div class="header">
            <h1>Loftwah's #{report_period} Report</h1>
          </div>
          <div class="content">
            #{html_content}
          </div>
          <div class="footer">
            <p>Generated on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</p>
          </div>
        </div>
      </body>
    </html>
  HTML
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
    report_period = ENV.fetch('REPORT_PERIOD', "Weekly")
    report_directory = "./reports/#{report_period.downcase}"

    unless Dir.exist?(report_directory)
      log "⚠️ Report directory #{report_directory} does not exist, skipping.", :warning
      exit 0
    end

    report_content = generate_report(report_directory, report_period)
    if report_content
      email_subject = "Loftwah's #{report_period} Report"
      send_email(email_subject, report_content)
    else
      log "⚠️ No content generated for #{report_period} report.", :warning
    end

    log "✨ Process completed!", :success
  rescue StandardError => e
    log "💥 Fatal error: #{e.message}", :error
  end
end
