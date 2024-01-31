# frozen_string_literal: true

class EbayAdPlugin::EbayController < ::ApplicationController
    
    def index

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

    def random

        if EbayAdPlugin::EbayListing.count > 0
            random_listing = EbayAdPlugin::EbayListing.order("RANDOM()").first
            listing_hash = random_listing.attributes
            listing_hash["epn_id"] = SiteSetting.ebay_epn_id
            render json: listing_hash
        else
            render json: { id: nil }
        end
    end

    def accounts

        ebay_items = []
        ebay_accounts = UserCustomField
                        .select("user_custom_fields.id, user_custom_fields.user_id, users.username, user_custom_fields.name, user_custom_fields.value, user_custom_fields.created_at, user_custom_fields.updated_at")
                        .joins(:user)
                        .where(name: 'ebay_username')
        
        #todo: require minimum trust level/group
        ebay_accounts.each do |account|
            items = EbayAdPlugin::EbayAPI::fetch_listings_by_seller(account.value)
            ebay_items.push(items)
        end



        render json: {accounts: ebay_accounts, items: ebay_items}
    end
    
    def api_calls
        ebay_api_calls = EbayAdPlugin::EbayApiCall.where(date: Date.today)
        render json: { calls: ebay_api_calls }
    end



end