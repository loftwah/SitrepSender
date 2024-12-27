#!/usr/bin/env ruby

require 'http'
require 'dotenv'
require 'redcarpet'
require 'json'
require 'base64'
require 'mime/types'
require 'pathname'

# Load .env file first thing
Dotenv.load

# Terminal output helper with real ANSI colors
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
  STDOUT.flush
end

begin
  log "\n=== Environment Configuration ===", :info
  
  if ENV['RESEND_API_KEY'].to_s.empty?
    log "⚠️  No RESEND_API_KEY found in .env", :warning
    exit 1
  else
    log "✓ RESEND_API_KEY found", :success
  end

  SENDER_EMAIL = ENV['SENDER_EMAIL']
  if SENDER_EMAIL.to_s.empty?
    log "✗ No SENDER_EMAIL found in .env", :error
    exit 1
  else
    log "✓ SENDER_EMAIL: #{SENDER_EMAIL}", :success
  end

  recipient = ENV['RECIPIENT_EMAIL'].to_s
  if recipient.empty?
    log "✗ No RECIPIENT_EMAIL found in .env", :error
    exit 1
  end
  
  RECIPIENT_EMAILS = if recipient.strip.start_with?('[')
    begin
      JSON.parse(recipient)
    rescue JSON::ParserError
      [recipient]
    end
  else
    [recipient]
  end
  
  log "✓ RECIPIENT_EMAIL: #{RECIPIENT_EMAILS.join(', ')}", :success
  log "===============================\n", :info

  RESEND_API_KEY = ENV['RESEND_API_KEY']

rescue StandardError => e
  log "✗ Environment configuration error: #{e.message}", :error
  exit 1
end

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
      log "📁 Processing local image: #{link}", :info
      %(<p><em>[#{alt_text}]</em></p>)
    end
  end
end

def generate_report(directory)
  log "\n📄 Scanning directory: #{directory}", :info
  return "" unless File.directory?(directory)

  content = ''
  files = Dir.glob("#{directory}/*.{md,html}").sort
  
  if files.empty?
    log "⚠️  No markdown or HTML files found in #{directory}", :warning
    return content
  end
  
  files.each do |file|
    log "  • Reading: #{File.basename(file)}", :debug
    content += File.read(file) + "\n\n"
  end
  
  log "✓ Found #{files.length} files to process", :success
  content
end

def markdown_to_html_with_styles(markdown_content, base_dir)
  return "<p>No content available.</p>" if markdown_content.empty?

  log "\n🔄 Converting markdown to HTML...", :info

  renderer = ImagePathRenderer.new(base_dir)
  markdown = Redcarpet::Markdown.new(
    renderer,
    fenced_code_blocks: true,
    tables: true,
    autolink: true,
    strikethrough: true,
    superscript: true
  )
  
  html_content = markdown.render(markdown_content)

  css = <<-CSS
    <style>
      body { font-family: Arial, sans-serif; line-height: 1.6; background-color: #f9f9f9; padding: 20px; }
      h1, h2, h3 { color: #333; margin-top: 1.5em; }
      h1 { font-size: 2em; border-bottom: 2px solid #eee; }
      h2 { font-size: 1.5em; }
      h3 { font-size: 1.2em; }
      table { border-collapse: collapse; width: 100%; margin: 1em 0; }
      table th, table td { border: 1px solid #ccc; padding: 8px; text-align: left; }
      table th { background-color: #f4f4f4; }
      p { margin: 1em 0; }
      img { max-width: 100%; height: auto; margin: 1em 0; display: block; }
      code { background-color: #f5f5f5; padding: 2px 4px; border-radius: 4px; }
      pre { background-color: #f5f5f5; padding: 1em; overflow-x: auto; }
      blockquote { border-left: 4px solid #ccc; margin: 1em 0; padding-left: 1em; color: #666; }
      .footer { text-align: center; font-size: 0.9em; color: #666; margin-top: 2em; padding-top: 1em; border-top: 1px solid #eee; }
    </style>
  CSS

  full_html = <<-HTML
    #{css}
    <body>
      <div class="content">
        #{html_content}
      </div>
      <div class="footer">
        <p>Generated on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</p>
      </div>
    </body>
  HTML

  log "✓ Markdown conversion complete", :success
  full_html
end

def send_email(subject, body_html)
  log "\n📧 Preparing email...", :info
  
  RECIPIENT_EMAILS.each do |email|
    log "\n📤 Sending to: #{email}", :info
    
    payload = {
      from: SENDER_EMAIL,
      to: email,
      subject: subject,
      html: body_html
    }

    begin
      response = HTTP.auth("Bearer #{RESEND_API_KEY}")
                     .timeout(10)
                     .post('https://api.resend.com/emails', json: payload)

      if response.status.success?
        log "✓ Successfully sent to #{email}", :success
        log "📫 Response ID: #{JSON.parse(response.body.to_s)['id']}", :debug
      else
        log "✗ Failed to send to #{email}", :error
        log "Error: #{response.body}", :error
      end
    rescue StandardError => e
      log "✗ Error sending to #{email}: #{e.message}", :error
    end
  end
end

if __FILE__ == $0
  begin
    log "\n🚀 Starting Email Report Generator", :info
    log "⏰ Time: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}", :debug
    
    directory = './reports'
    markdown_report = generate_report(directory)
    html_report = markdown_to_html_with_styles(markdown_report, directory)
    subject = "Your #{Time.now.strftime('%A')} Report"

    send_email(subject, html_report)
    
    log "\n✨ Process Complete! ✨\n", :success
  rescue StandardError => e
    log "💥 Fatal error: #{e.message}", :error
    log e.backtrace.join("\n"), :debug if ENV['DEBUG']
    exit 1
  end
end