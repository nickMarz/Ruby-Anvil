# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Anvil::Signature, :configured do
  let(:client) { instance_double(Anvil::Client, config: Anvil.configuration) }
  let(:packet_attrs) do
    {
      eid: 'pkt_123',
      name: 'Test Packet',
      status: 'draft',
      signers: [
        { eid: 'sgn_1', name: 'John', email: 'john@example.com', status: 'pending' }
      ]
    }
  end
  let(:packet) { described_class.new(packet_attrs, client: client) }

  before do
    described_class.instance_variable_set(:@client, nil)
    allow(Anvil::Client).to receive(:new).and_return(client)
  end

  after do
    described_class.instance_variable_set(:@client, nil)
  end

  describe '#update' do
    it 'updates the packet via GraphQL' do
      updated = packet_attrs.merge(name: 'Updated Packet')
      expect(client).to receive(:graphql).and_return({ updateEtchPacket: updated })

      packet.update(name: 'Updated Packet')
      expect(packet.name).to eq('Updated Packet')
    end

    it 'raises APIError on failure' do
      expect(client).to receive(:graphql).and_return(nil)

      expect { packet.update(name: 'Updated') }.to raise_error(Anvil::APIError, /Failed to update/)
    end
  end

  describe '#send!' do
    it 'sends the draft packet' do
      sent_attrs = packet_attrs.merge(status: 'sent')
      expect(client).to receive(:graphql).and_return({ sendEtchPacket: sent_attrs })

      packet.send!
      expect(packet.status).to eq('sent')
    end

    it 'raises APIError on failure' do
      expect(client).to receive(:graphql).and_return(nil)

      expect { packet.send! }.to raise_error(Anvil::APIError, /Failed to send/)
    end
  end

  describe '#delete!' do
    it 'deletes the packet' do
      expect(client).to receive(:graphql).and_return({ removeEtchPacket: true })

      expect(packet.delete!).to be true
    end

    it 'raises APIError on failure' do
      expect(client).to receive(:graphql).and_return(nil)

      expect { packet.delete! }.to raise_error(Anvil::APIError, /Failed to delete/)
    end
  end

  describe '#skip_signer' do
    it 'skips the signer and reloads' do
      expect(client).to receive(:graphql).with(anything, variables: { signerEid: 'sgn_1', packetEid: 'pkt_123' }).and_return({ skipSigner: true })
      expect(described_class).to receive(:find).with('pkt_123', client: client).and_return(packet)

      packet.skip_signer('sgn_1')
    end

    it 'raises APIError on failure' do
      expect(client).to receive(:graphql).and_return(nil)

      expect { packet.skip_signer('sgn_1') }.to raise_error(Anvil::APIError, /Failed to skip signer/)
    end
  end

  describe '#notify_signer' do
    it 'sends a reminder to the signer' do
      expect(client).to receive(:graphql).and_return({ notifySigner: true })

      expect(packet.notify_signer('sgn_1')).to be true
    end

    it 'raises APIError on failure' do
      expect(client).to receive(:graphql).and_return(nil)

      expect { packet.notify_signer('sgn_1') }.to raise_error(Anvil::APIError, /Failed to notify signer/)
    end
  end

  describe '#void!' do
    it 'voids the document group' do
      expect(client).to receive(:graphql).and_return({ voidDocumentGroup: true })
      expect(described_class).to receive(:find).with('pkt_123', client: client).and_return(packet)

      expect(packet.void!).to be true
    end
  end

  describe '#expire_tokens!' do
    it 'expires all signer tokens' do
      expect(client).to receive(:graphql).and_return({ expireSignerTokens: true })

      expect(packet.expire_tokens!).to be true
    end
  end

  describe 'status predicates' do
    it 'detects draft status' do
      expect(packet).to be_draft
      expect(packet).not_to be_sent
      expect(packet).not_to be_complete
    end

    it 'detects sent status' do
      sent_packet = described_class.new(packet_attrs.merge(status: 'sent'), client: client)
      expect(sent_packet).to be_sent
      expect(sent_packet).to be_in_progress
    end

    it 'detects complete status' do
      complete_packet = described_class.new(packet_attrs.merge(status: 'complete'), client: client)
      expect(complete_packet).to be_complete
      expect(complete_packet).to be_completed
    end
  end
end

RSpec.describe Anvil::SignatureSigner do
  let(:client) { instance_double(Anvil::Client, config: Anvil.configuration) }
  let(:packet) { Anvil::Signature.new({ eid: 'pkt_123', status: 'sent' }, client: client) }
  let(:signer) do
    described_class.new(
      { eid: 'sgn_1', name: 'John', email: 'john@example.com', status: 'pending' },
      packet: packet
    )
  end

  describe '#skip!' do
    it 'delegates to packet#skip_signer' do
      expect(packet).to receive(:skip_signer).with('sgn_1')
      signer.skip!
    end

    it 'raises error without packet' do
      orphan = described_class.new({ eid: 'sgn_1' })
      expect { orphan.skip! }.to raise_error(Anvil::Error, /No packet/)
    end
  end

  describe '#send_reminder!' do
    it 'delegates to packet#notify_signer' do
      expect(packet).to receive(:notify_signer).with('sgn_1')
      signer.send_reminder!
    end

    it 'raises error without packet' do
      orphan = described_class.new({ eid: 'sgn_1' })
      expect { orphan.send_reminder! }.to raise_error(Anvil::Error, /No packet/)
    end
  end
end
