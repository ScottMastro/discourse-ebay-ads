# frozen_string_literal: true

class EbayAdPlugin::EbayController < ::ApplicationController
    
    def index
        # Get limit and offset from params, set default values if they don't exist
        limit = params.fetch(:limit, 100).to_i
        offset = params.fetch(:offset, 0).to_i
    
        if EbayAdPlugin::EbayListing.count > 0
            # Use offset and limit to paginate the listings
            paginated_listings = EbayAdPlugin::EbayListing.order("RANDOM()").limit(limit).offset(offset)
            listing_hashes = paginated_listings.map { |listing| listing.attributes }
            listing_hashes.each { |hash| hash["epn_id"] = SiteSetting.ebay_epn_id }
    
            render json: { ebay_listings: listing_hashes }
        else
            render json: { ebay_listings: [] }
        end
    end
    
    

    def random
        n = params[:n].to_i 
      
        if EbayAdPlugin::EbayListing.count > 0
          random_listings = EbayAdPlugin::EbayListing.order("RANDOM()").limit(n)
          listing_hashes = random_listings.map { |listing| listing.attributes }
          listing_hashes.each { |hash| hash["epn_id"] = SiteSetting.ebay_epn_id }
          render json: listing_hashes
        else
          render json: []
        end
      end
      

    def accounts
        Jobs.enqueue(:get_seller_listings)
    end
    
    def info
        accounts = get_all_account_info
        listing_statistics = calculate_listing_statistics
        api_calls = get_api_calls

        render json: {
            accounts: accounts,
            listing_statistics: listing_statistics,
            api_calls: api_calls
        }
    end

    def drop_seller
        Jobs.enqueue(:drop_seller, seller_name: params[:seller_name])
    end

    def block_seller
        seller_name = params[:seller_name]
        reason = params[:reason] || "No reason given."

        render json: { error: "Seller name is required.", status: :unprocessable_entity } if seller_name.blank?

        blocked_seller = EbayAdPlugin::EbaySellerBlock.find_by(seller: seller_name)
        if blocked_seller
            render json: { error: "Seller #{seller_name} has already been blocked. Existing reason: #{blocked_seller.reason}" }
            return
        end

        EbayAdPlugin::EbaySellerBlock.create!(seller: seller_name, reason: reason)
        render json: { status: :ok, message: "Seller #{seller_name} has been blocked. Reason: #{reason}" }
        rescue => e
            Rails.logger.error "Error blocking seller #{seller_name}: #{e.message}"
            render json: { error: "Failed to block seller #{seller_name}.", status: :internal_server_error, message: e.message }
    end

    def unblock_seller
        seller_name = params[:seller_name]
        render json: { error: "Seller name is required.", status: :unprocessable_entity } if seller_name.blank?

        blocked_seller = EbayAdPlugin::EbaySellerBlock.find_by(seller: seller_name)
        if blocked_seller
            blocked_seller.destroy
            render json: { status: :ok, message: "Seller #{seller_name} has been unblocked." }
        else
            render json: { error: "Seller #{seller_name} is not currently blocked.", status: :not_found }
        end
        rescue => e
            Rails.logger.error "Error unblocking seller #{seller_name}: #{e.message}"
            render json: { error: "Failed to unblock seller #{seller_name}.", status: :internal_server_error, message: e.message }
    end

    private

    def get_all_account_info
        UserCustomField.where(name: 'ebay_username').map do |account|
            { 
              user_id: account.user_id, 
              username: account.user.username,
              ebay_username: account.value
            }
        end
    end

    def calculate_listing_statistics
        total_listings = EbayAdPlugin::EbayListing.count
        listings_by_seller = EbayAdPlugin::EbayListing.group(:seller).count
        {
            total_listings: total_listings,
            listings_by_seller: listings_by_seller
        }
    end

    def get_api_calls
        EbayAdPlugin::EbayApiCall.select(:date, :count, :call_type)
                                 .where(date: Date.today)
                                 .map do |api_call|
            {
                date: api_call.date,
                count: api_call.count,
                call_type: api_call.call_type
            }
        end
    end
end