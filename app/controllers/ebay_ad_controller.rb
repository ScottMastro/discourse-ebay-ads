# frozen_string_literal: true

class EbayAdPlugin::EbayAdController < ::ApplicationController
    
    def ad_data

        if EbayAdPlugin::EbayListing.count > 0

            #listings = EbayAdPlugin::EbayListing.all
            #listings.each do |listing|
            #  puts listing.attributes.inspect
            #end

            random_listing = EbayAdPlugin::EbayListing.order("RANDOM()").first
            listing_hash = random_listing.attributes
            listing_hash["epn_id"] = SiteSetting.ebay_epn_id
            render json: listing_hash

        else
            render json: { id: nil }
        end
    end
end