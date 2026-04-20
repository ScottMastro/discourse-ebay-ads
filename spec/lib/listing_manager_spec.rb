# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe EbayAdPlugin::ListingManager do
  describe ".record_ebay_listings" do
    let(:payload) do
      [
        {
          "itemId" => "v1|111|0",
          "legacyItemId" => "111",
          "title" => "Charizard",
          "price" => {
            "value" => "100.00",
            "currency" => "USD",
          },
          "seller" => {
            "username" => "pokefan",
            "feedbackScore" => 500,
          },
        },
      ]
    end

    it "inserts a new listing" do
      expect { described_class.record_ebay_listings(payload) }.to change {
        EbayAdPlugin::EbayListing.count
      }.by(1)
    end

    it "is idempotent on item_id" do
      described_class.record_ebay_listings(payload)
      expect { described_class.record_ebay_listings(payload) }.not_to change {
        EbayAdPlugin::EbayListing.count
      }
    end

    it "bumps updated_at on re-ingest" do
      described_class.record_ebay_listings(payload)
      row = EbayAdPlugin::EbayListing.find_by(item_id: "v1|111|0")
      row.update_columns(updated_at: 1.week.ago)
      described_class.record_ebay_listings(payload)
      expect(row.reload.updated_at).to be > 1.hour.ago
    end

    it "skips rows without an item_id" do
      bad = [{ "title" => "no id" }]
      expect { described_class.record_ebay_listings(bad) }.not_to change {
        EbayAdPlugin::EbayListing.count
      }
    end

    it "returns early on empty input" do
      expect { described_class.record_ebay_listings([]) }.not_to raise_error
    end
  end

  describe ".deactivate_unseen" do
    fab!(:kept) { Fabricate(:ebay_listing, seller: "alice", item_id: "keep-1", active: true) }
    fab!(:removed) { Fabricate(:ebay_listing, seller: "alice", item_id: "gone-1", active: true) }
    fab!(:other) { Fabricate(:ebay_listing, seller: "bob", item_id: "bob-1", active: true) }

    it "deactivates listings not in the fresh fetch for the seller" do
      described_class.deactivate_unseen("alice", %w[keep-1])

      expect(kept.reload.active).to be true
      expect(removed.reload.active).to be false
    end

    it "does not touch other sellers' listings" do
      described_class.deactivate_unseen("alice", %w[keep-1])
      expect(other.reload.active).to be true
    end

    it "does nothing when seen_item_ids is empty (treats as fetch failure)" do
      described_class.deactivate_unseen("alice", [])
      expect(kept.reload.active).to be true
      expect(removed.reload.active).to be true
    end

    it "does nothing when seller is blank" do
      expect { described_class.deactivate_unseen(nil, %w[keep-1]) }.not_to change {
        EbayAdPlugin::EbayListing.where(active: false).count
      }
    end
  end
end
