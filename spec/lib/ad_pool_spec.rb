# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe EbayAdPlugin::AdPool do
  before { described_class.bust! }
  after { described_class.bust! }

  describe ".fetch" do
    it "returns an empty pool when there are no sellers" do
      pool = described_class.fetch
      expect(pool[:total_weight]).to eq(0)
      expect(pool[:sellers]).to be_empty
    end

    it "excludes hidden sellers" do
      user = Fabricate(:admin)
      Fabricate(:ebay_listing, seller: "ghost")
      Fabricate(:ebay_seller, user_id: user.id, ebay_username: "ghost", hidden: true)

      expect(described_class.fetch[:sellers]).to be_empty
    end

    it "excludes blocked sellers" do
      user = Fabricate(:admin)
      Fabricate(:ebay_listing, seller: "bad")
      Fabricate(:ebay_seller, user_id: user.id, ebay_username: "bad", blocked: true)

      expect(described_class.fetch[:sellers]).to be_empty
    end

    it "excludes sellers with no active listings" do
      user = Fabricate(:admin)
      Fabricate(:ebay_listing, seller: "dormant", active: false)
      Fabricate(:ebay_seller, user_id: user.id, ebay_username: "dormant")

      expect(described_class.fetch[:sellers]).to be_empty
    end

    it "excludes sellers whose Discourse user isn't in the allowed groups" do
      regular = Fabricate(:user) # not staff
      Fabricate(:ebay_listing, seller: "outsider")
      Fabricate(:ebay_seller, user_id: regular.id, ebay_username: "outsider")

      # Default ebay_banner_allowed_groups is staff only (group id 3)
      expect(described_class.fetch[:sellers]).to be_empty
    end

    it "includes eligible sellers with weight >= 1" do
      SiteSetting.ebay_seller_base_weight = 1

      admin = Fabricate(:admin)
      Fabricate(:ebay_listing, seller: "active_seller")
      Fabricate(:ebay_seller, user_id: admin.id, ebay_username: "active_seller")

      pool = described_class.fetch
      expect(pool[:sellers].size).to eq(1)
      expect(pool[:sellers].first[:ebay_username]).to eq("active_seller")
      expect(pool[:total_weight]).to be >= 1
    end

    it "caches the pool between calls" do
      SiteSetting.ebay_seller_base_weight = 1

      admin = Fabricate(:admin)
      Fabricate(:ebay_listing, seller: "cached_seller")
      Fabricate(:ebay_seller, user_id: admin.id, ebay_username: "cached_seller")

      pool1 = described_class.fetch

      # Add a new eligible seller after the cache was built
      admin2 = Fabricate(:admin)
      Fabricate(:ebay_listing, seller: "new_seller")
      Fabricate(:ebay_seller, user_id: admin2.id, ebay_username: "new_seller")

      pool2 = described_class.fetch
      expect(pool2[:sellers].size).to eq(pool1[:sellers].size) # cache hit

      described_class.bust!
      pool3 = described_class.fetch
      expect(pool3[:sellers].size).to eq(pool1[:sellers].size + 1) # rebuilt
    end
  end

  describe ".sample_seller" do
    it "returns nil on an empty pool" do
      expect(described_class.sample_seller).to be_nil
    end

    it "samples each seller with probability proportional to weight" do
      SiteSetting.ebay_seller_base_weight = 1

      admin_a = Fabricate(:admin)
      admin_b = Fabricate(:admin)
      Fabricate(:ebay_listing, seller: "a")
      Fabricate(:ebay_listing, seller: "b")
      Fabricate(:ebay_seller, user_id: admin_a.id, ebay_username: "a")
      Fabricate(:ebay_seller, user_id: admin_b.id, ebay_username: "b")

      # Both sellers weight 1, so each ~50%. 4000 draws, σ ≈ 31.
      # ±150 is safely past 3σ — no flake risk.
      n = 4000
      counts = Hash.new(0)
      n.times { counts[described_class.sample_seller[:ebay_username]] += 1 }

      expect(counts["a"]).to be_within(150).of(n / 2)
      expect(counts["b"]).to be_within(150).of(n / 2)
      expect(counts["a"] + counts["b"]).to eq(n)
    end
  end
end
