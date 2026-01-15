#!/usr/bin/env ruby
# frozen_string_literal: true

# Add lib to the load path if running directly
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'anvil'
require 'anvil/env_loader'

# Load .env file if it exists
Anvil::EnvLoader.load(File.expand_path('../.env', __dir__))

# Example: Generate PDFs from HTML or Markdown
#
# This example shows how to generate PDFs from HTML/CSS or Markdown content

# Configure Anvil (will use ANVIL_API_KEY from .env)
Anvil.configure do |config|
  config.api_key = ENV['ANVIL_API_KEY']
  config.environment = :development
end

# Example 1: Generate PDF from HTML
def generate_html_invoice
  puts "\n📄 Generating invoice from HTML..."

  html = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Invoice</title>
    </head>
    <body>
      <div class="invoice-header">
        <h1>INVOICE</h1>
        <div class="invoice-number">#INV-2024-001</div>
        <div class="invoice-date">Date: #{Date.today.strftime('%B %d, %Y')}</div>
      </div>

      <div class="company-info">
        <h2>Acme Corporation</h2>
        <p>123 Business Ave<br>San Francisco, CA 94102<br>Phone: (555) 123-4567</p>
      </div>

      <div class="bill-to">
        <h3>Bill To:</h3>
        <p>
          John Doe<br>
          XYZ Company<br>
          456 Client Street<br>
          New York, NY 10001
        </p>
      </div>

      <table class="invoice-items">
        <thead>
          <tr>
            <th>Description</th>
            <th>Quantity</th>
            <th>Unit Price</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Consulting Services</td>
            <td>40</td>
            <td>$150.00</td>
            <td>$6,000.00</td>
          </tr>
          <tr>
            <td>Software License</td>
            <td>1</td>
            <td>$2,500.00</td>
            <td>$2,500.00</td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <td colspan="3">Subtotal</td>
            <td>$8,500.00</td>
          </tr>
          <tr>
            <td colspan="3">Tax (10%)</td>
            <td>$850.00</td>
          </tr>
          <tr class="total">
            <td colspan="3"><strong>Total</strong></td>
            <td><strong>$9,350.00</strong></td>
          </tr>
        </tfoot>
      </table>

      <div class="footer">
        <p>Payment due within 30 days. Thank you for your business!</p>
      </div>
    </body>
    </html>
  HTML

  css = <<~CSS
    body {
      font-family: 'Helvetica Neue', Arial, sans-serif;
      color: #333;
      line-height: 1.6;
      padding: 20px;
    }

    .invoice-header {
      border-bottom: 2px solid #007bff;
      padding-bottom: 20px;
      margin-bottom: 30px;
    }

    h1 {
      color: #007bff;
      margin: 0;
      font-size: 36px;
    }

    .invoice-number {
      font-size: 18px;
      color: #666;
      margin-top: 10px;
    }

    .invoice-date {
      font-size: 14px;
      color: #666;
    }

    .company-info, .bill-to {
      margin-bottom: 30px;
    }

    h2 {
      color: #333;
      font-size: 24px;
      margin-bottom: 10px;
    }

    h3 {
      color: #555;
      font-size: 18px;
      margin-bottom: 10px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      margin: 30px 0;
    }

    th {
      background-color: #007bff;
      color: white;
      padding: 12px;
      text-align: left;
      font-weight: bold;
    }

    td {
      padding: 12px;
      border-bottom: 1px solid #ddd;
    }

    tfoot td {
      font-weight: bold;
      border-top: 2px solid #007bff;
    }

    .total td {
      font-size: 18px;
      color: #007bff;
    }

    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid #ddd;
      text-align: center;
      color: #666;
      font-size: 14px;
    }
  CSS

  pdf = Anvil::PDF.generate_from_html(
    html: html,
    css: css,
    title: 'Invoice #INV-2024-001'
  )

  filename = "invoice_#{Time.now.to_i}.pdf"
  pdf.save_as(filename)

  puts "✅ Invoice PDF generated!"
  puts "📄 Saved as: #{filename}"
  puts "📏 Size: #{pdf.size_human}"
end

# Example 2: Generate PDF from Markdown
def generate_markdown_report
  puts "\n📄 Generating report from Markdown..."

  markdown_content = [
    {
      heading: 'Annual Report 2024',
      content: <<~MD
        ## Executive Summary

        This annual report provides a comprehensive overview of our company's performance
        and achievements during the fiscal year 2024.

        ### Key Highlights

        - Revenue growth of **25%** year-over-year
        - Expanded operations to **3 new markets**
        - Launched **5 innovative products**
        - Increased customer satisfaction to **95%**
      MD
    },
    {
      heading: 'Financial Performance',
      content: <<~MD
        ### Revenue Breakdown

        | Quarter | Revenue    | Growth |
        |---------|------------|--------|
        | Q1 2024 | $2.5M     | +20%   |
        | Q2 2024 | $2.8M     | +22%   |
        | Q3 2024 | $3.2M     | +28%   |
        | Q4 2024 | $3.5M     | +30%   |
        | **Total** | **$12M** | **+25%** |

        ### Operating Expenses

        Our operating expenses remained well-controlled throughout the year:

        - Personnel: $4.2M
        - Marketing: $1.8M
        - R&D: $2.1M
        - Operations: $1.4M
      MD
    },
    {
      heading: 'Future Outlook',
      content: <<~MD
        ## Strategic Initiatives for 2025

        1. **Digital Transformation**
           - Implement AI-driven analytics
           - Upgrade customer portal
           - Automate key processes

        2. **Market Expansion**
           - Enter European markets
           - Strengthen presence in Asia
           - Launch e-commerce platform

        3. **Product Innovation**
           - Release next-gen product line
           - Enhance mobile applications
           - Develop SaaS offerings

        ---

        *This report was prepared by the Executive Team*
        *Date: #{Date.today.strftime('%B %d, %Y')}*
      MD
    }
  ]

  pdf = Anvil::PDF.generate(
    type: :markdown,
    data: markdown_content,
    title: 'Annual Report 2024',
    page: {
      margin_top: '2in',
      margin_bottom: '1in',
      margin_left: '1in',
      margin_right: '1in'
    }
  )

  filename = "report_#{Time.now.to_i}.pdf"
  pdf.save_as(filename)

  puts "✅ Report PDF generated!"
  puts "📄 Saved as: #{filename}"
  puts "📏 Size: #{pdf.size_human}"
end

# Example 3: Simple markdown generation
def generate_simple_document
  puts "\n📄 Generating simple document..."

  pdf = Anvil::PDF.generate_from_markdown(
    <<~MD
      # Welcome to Anvil

      This is a simple example of generating a PDF from markdown.

      ## Features

      - Easy to use API
      - Multiple format support
      - Fast generation
      - Professional output

      ## Code Example

      ```ruby
      pdf = Anvil::PDF.generate_from_markdown(content)
      pdf.save_as('output.pdf')
      ```

      Thank you for using Anvil!
    MD
  )

  filename = "simple_#{Time.now.to_i}.pdf"
  pdf.save_as(filename)

  puts "✅ Simple PDF generated!"
  puts "📄 Saved as: #{filename}"
end

# Run examples
begin
  puts "=" * 50
  puts "Anvil PDF Generation Examples"
  puts "=" * 50

  generate_html_invoice
  generate_markdown_report
  generate_simple_document

  puts "\n✅ All examples completed successfully!"

rescue Anvil::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "Please set your ANVIL_API_KEY environment variable"
rescue Anvil::Error => e
  puts "❌ Anvil error: #{e.message}"
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts e.backtrace.first(5)
end