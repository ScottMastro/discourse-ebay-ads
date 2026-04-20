# frozen_string_literal: true
module Jobs
  class GetSellerListings < ::Jobs::Base
    def execute(args)
      ebay_seller = args[:ebay_seller]
      return if ebay_seller.blank?

      raw_listings = EbayAdPlugin::EbayAPI.fetch_listings_by_seller(ebay_seller)

      EbayAdPlugin::ListingManager.record_ebay_listings(raw_listings)

      seen_item_ids = raw_listings.map { |l| l["itemId"] }.compact
      EbayAdPlugin::ListingManager.deactivate_unseen(ebay_seller, seen_item_ids)
    end
  end
end
