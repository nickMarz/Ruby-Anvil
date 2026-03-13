# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Anvil::Workflow, :configured do
  let(:client) { instance_double(Anvil::Client, config: Anvil.configuration) }
  let(:workflow_attrs) do
    {
      eid: 'weld_123',
      name: 'Employee Onboarding',
      slug: 'employee-onboarding',
      status: 'published'
    }
  end
  let(:workflow) { described_class.new(workflow_attrs, client: client) }

  before do
    described_class.instance_variable_set(:@client, nil)
    allow(Anvil::Client).to receive(:new).and_return(client)
  end

  after do
    described_class.instance_variable_set(:@client, nil)
  end

  describe '.create' do
    it 'creates a new workflow' do
      expect(client).to receive(:graphql).and_return({ createWeld: workflow_attrs })

      result = described_class.create(name: 'Employee Onboarding')
      expect(result).to be_a(described_class)
      expect(result.name).to eq('Employee Onboarding')
      expect(result.eid).to eq('weld_123')
    end

    it 'raises APIError on failure' do
      expect(client).to receive(:graphql).and_return(nil)

      expect { described_class.create(name: 'Test') }.to raise_error(Anvil::APIError, /Failed to create workflow/)
    end
  end

  describe '.find' do
    it 'finds a workflow by EID' do
      expect(client).to receive(:graphql).and_return({ weld: workflow_attrs })

      result = described_class.find('weld_123', client: client)
      expect(result).to be_a(described_class)
      expect(result.name).to eq('Employee Onboarding')
    end

    it 'raises NotFoundError when not found' do
      expect(client).to receive(:graphql).and_return(nil)

      expect { described_class.find('weld_bad', client: client) }.to raise_error(Anvil::NotFoundError, /Workflow not found/)
    end
  end

  describe '#start' do
    it 'starts the workflow with data' do
      expect(client).to receive(:graphql).and_return({
        createWeldData: { eid: 'wd_123', status: 'in_progress', data: { name: 'John' } }
      })

      result = workflow.start(data: { name: 'John' })
      expect(result[:eid]).to eq('wd_123')
    end

    it 'raises APIError on failure' do
      expect(client).to receive(:graphql).and_return(nil)

      expect { workflow.start(data: {}) }.to raise_error(Anvil::APIError, /Failed to start workflow/)
    end
  end

  describe '#submissions' do
    it 'returns workflow submissions' do
      expect(client).to receive(:graphql).and_return({
        weldData: [
          { eid: 'wd_1', status: 'complete', data: {} },
          { eid: 'wd_2', status: 'in_progress', data: {} }
        ]
      })

      results = workflow.submissions
      expect(results.length).to eq(2)
    end

    it 'returns empty array when no submissions' do
      expect(client).to receive(:graphql).and_return(nil)

      expect(workflow.submissions).to eq([])
    end
  end

  describe 'status predicates' do
    it 'detects published status' do
      expect(workflow).to be_published
      expect(workflow).not_to be_draft
    end

    it 'detects draft status' do
      draft = described_class.new(workflow_attrs.merge(status: 'draft'), client: client)
      expect(draft).to be_draft
      expect(draft).not_to be_published
    end
  end
end
