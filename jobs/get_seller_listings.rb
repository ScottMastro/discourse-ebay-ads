module Jobs
    class GetSellerListings < ::Jobs::Base
        def execute(args)
            ebay_seller = args[:ebay_seller]
            raw_listings = EbayAdPlugin::EbayAPI::fetch_listings_by_seller(ebay_seller)
            EbayAdPlugin::ListingManager::record_ebay_listings(raw_listings)
        end
    end
end