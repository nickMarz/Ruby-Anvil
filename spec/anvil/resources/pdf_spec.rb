# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Anvil::PDF do
  let(:pdf_data) { 'fake pdf data' }
  let(:pdf) { described_class.new(pdf_data) }

  describe '#initialize' do
    it 'stores raw data' do
      expect(pdf.raw_data).to eq(pdf_data)
    end

    it 'accepts attributes' do
      # Ruby 2.7 keyword argument separation: pass empty keywords to prevent misinterpretation
      pdf_with_attrs = described_class.new(pdf_data, { template_id: '123' }, **{})
      expect(pdf_with_attrs.template_id).to eq('123')
    end
  end

  describe '#save_as' do
    let(:filename) { 'test.pdf' }

    it 'saves PDF data to file' do
      expect(File).to receive(:open).with(filename, 'wb')
      pdf.save_as(filename)
    end

    it 'raises error when no data' do
      empty_pdf = described_class.new(nil)
      expect { empty_pdf.save_as(filename) }.to raise_error(Anvil::FileError, /No PDF data/)
    end
  end

  describe '#save_as!' do
    let(:filename) { '/invalid/path/test.pdf' }

    it 'raises FileError on save failure' do
      allow(File).to receive(:open).and_raise(Errno::ENOENT)
      expect { pdf.save_as!(filename) }.to raise_error(Anvil::FileError, /Failed to save PDF/)
    end
  end

  describe '#to_base64' do
    it 'returns base64 encoded data' do
      expect(pdf.to_base64).to eq(Base64.strict_encode64(pdf_data))
    end

    it 'returns nil when no data' do
      empty_pdf = described_class.new(nil)
      expect(empty_pdf.to_base64).to be_nil
    end
  end

  describe '#size' do
    it 'returns size in bytes' do
      expect(pdf.size).to eq(pdf_data.bytesize)
    end

    it 'returns 0 when no data' do
      empty_pdf = described_class.new(nil)
      expect(empty_pdf.size).to eq(0)
    end
  end

  describe '#size_human' do
    it 'formats size in human readable format' do
      expect(pdf.size_human).to eq('13.00 B')
    end

    it 'handles KB sizes' do
      kb_pdf = described_class.new('x' * 2048)
      expect(kb_pdf.size_human).to eq('2.00 KB')
    end

    it 'handles MB sizes' do
      mb_pdf = described_class.new('x' * (2 * 1024 * 1024))
      expect(mb_pdf.size_human).to eq('2.00 MB')
    end
  end

  describe '.fill', :configured do
    let(:template_id) { 'template_123' }
    let(:data) { { name: 'John Doe' } }
    let(:client) { instance_double(Anvil::Client) }
    let(:response) { instance_double(Anvil::Response, binary?: true, raw_body: pdf_data) }

    before do
      # Reset class-level client to avoid test double leaking
      described_class.instance_variable_set(:@client, nil)
      allow(Anvil::Client).to receive(:new).and_return(client)
      allow(client).to receive(:post).and_return(response)
    end

    after do
      # Clean up class-level client after each test
      described_class.instance_variable_set(:@client, nil)
    end

    it 'fills PDF template with data' do
      expect(client).to receive(:post).with(
        "/fill/#{template_id}.pdf",
        { data: data }
      )

      result = described_class.fill(template_id: template_id, data: data)
      expect(result).to be_a(described_class)
      expect(result.raw_data).to eq(pdf_data)
    end

    it 'includes optional parameters' do
      expect(client).to receive(:post).with(
        "/fill/#{template_id}.pdf",
        hash_including(
          data: data,
          title: 'Test PDF',
          fontSize: 12
        )
      )

      described_class.fill(
        template_id: template_id,
        data: data,
        title: 'Test PDF',
        font_size: 12
      )
    end

    it 'uses custom API key when provided' do
      custom_client = instance_double(Anvil::Client)
      allow(Anvil::Client).to receive(:new).with(api_key: 'custom_key').and_return(custom_client)
      allow(custom_client).to receive(:post).and_return(response)

      described_class.fill(
        template_id: template_id,
        data: data,
        api_key: 'custom_key'
      )
    end

    it 'raises error for non-binary response' do
      allow(response).to receive(:binary?).and_return(false)
      allow(response).to receive(:content_type).and_return('text/html')

      expect do
        described_class.fill(template_id: template_id, data: data)
      end.to raise_error(Anvil::APIError, /Expected PDF response/)
    end
  end

  describe '.generate', :configured do
    let(:client) { instance_double(Anvil::Client) }
    let(:response) { instance_double(Anvil::Response, binary?: true, raw_body: pdf_data) }

    before do
      # Reset class-level client to avoid test double leaking
      described_class.instance_variable_set(:@client, nil)
      allow(Anvil::Client).to receive(:new).and_return(client)
      allow(client).to receive(:post).and_return(response)
    end

    after do
      # Clean up class-level client after each test
      described_class.instance_variable_set(:@client, nil)
    end

    context 'with HTML' do
      it 'generates PDF from HTML' do
        expect(client).to receive(:post).with(
          '/generate-pdf',
          hash_including(
            type: 'html',
            data: { html: '<h1>Test</h1>', css: 'h1 { color: blue; }' }
          )
        )

        result = described_class.generate(
          type: :html,
          data: { html: '<h1>Test</h1>', css: 'h1 { color: blue; }' }
        )

        expect(result).to be_a(described_class)
      end
    end

    context 'with Markdown' do
      it 'generates PDF from Markdown' do
        expect(client).to receive(:post).with(
          '/generate-pdf',
          hash_including(
            type: 'markdown',
            data: [{ content: '# Title' }]
          )
        )

        result = described_class.generate(
          type: :markdown,
          data: [{ content: '# Title' }]
        )

        expect(result).to be_a(described_class)
      end
    end

    it 'validates type parameter' do
      expect do
        described_class.generate(type: :invalid, data: {})
      end.to raise_error(ArgumentError, /Type must be :html or :markdown/)
    end
  end

  describe '.generate_from_html', :configured do
    let(:client) { instance_double(Anvil::Client) }
    let(:response) { instance_double(Anvil::Response, binary?: true, raw_body: pdf_data) }

    before do
      # Reset class-level client to avoid test double leaking
      described_class.instance_variable_set(:@client, nil)
      allow(Anvil::Client).to receive(:new).and_return(client)
      allow(client).to receive(:post).and_return(response)
    end

    after do
      # Clean up class-level client after each test
      described_class.instance_variable_set(:@client, nil)
    end

    it 'generates PDF from HTML and CSS' do
      expect(client).to receive(:post).with(
        '/generate-pdf',
        hash_including(
          type: 'html',
          data: { html: '<h1>Test</h1>', css: 'h1 { color: red; }' }
        )
      )

      described_class.generate_from_html(
        html: '<h1>Test</h1>',
        css: 'h1 { color: red; }'
      )
    end
  end

  describe '.generate_from_markdown', :configured do
    let(:client) { instance_double(Anvil::Client) }
    let(:response) { instance_double(Anvil::Response, binary?: true, raw_body: pdf_data) }

    before do
      # Reset class-level client to avoid test double leaking
      described_class.instance_variable_set(:@client, nil)
      allow(Anvil::Client).to receive(:new).and_return(client)
      allow(client).to receive(:post).and_return(response)
    end

    after do
      # Clean up class-level client after each test
      described_class.instance_variable_set(:@client, nil)
    end

    it 'generates PDF from markdown string' do
      expect(client).to receive(:post).with(
        '/generate-pdf',
        hash_including(
          type: 'markdown',
          data: [{ content: '# Title' }]
        )
      )

      described_class.generate_from_markdown('# Title')
    end

    it 'generates PDF from markdown array' do
      data = [{ content: '# Title' }, { content: '## Subtitle' }]

      expect(client).to receive(:post).with(
        '/generate-pdf',
        hash_including(type: 'markdown', data: data)
      )

      described_class.generate_from_markdown(data)
    end

    it 'raises error for invalid content type' do
      expect do
        described_class.generate_from_markdown(123)
      end.to raise_error(ArgumentError, /Markdown content must be a string or array/)
    end
  end
end
