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
      
    
    def info
        accounts = get_all_account_info
        api_calls = get_api_calls

        total_listings = EbayAdPlugin::EbayListing.count
        listings_by_seller = EbayAdPlugin::EbayListing.group(:seller).count
        listing_statistics = {
            total_listings: total_listings,
            listings_by_seller: listings_by_seller
        }

        render json: {
            listing_statistics: listing_statistics,
            api_calls: api_calls,
            accounts: accounts
        }
    end



    def user_info

        username = params[:username]
        user = User.find_by(username: username)
        ebay_username_field = UserCustomField
                                .where(name: 'ebay_username', user_id: user.id)
                                .first
        
        if ebay_username_field.nil? || ebay_username_field.value.empty?
            render json: {user: user, discourse_user: username, ebay_username: nil, blocked: nil}
            return
        end
        ebay_username = ebay_username_field.value

        blocked_seller = EbayAdPlugin::EbaySellerBlock.find_by(seller: ebay_username)

        render json: {user: user, discourse_user: username, ebay_username: ebay_username, blocked: blocked_seller}
    end




    def update_user
        username = params[:username]
        user = User.find_by(username: username)
    
        if user.nil?
            render json: {status: "failed", message: "No user with username: #{username}"}
            return
        end
    
        ebay_username_field = UserCustomField
                                .where(name: 'ebay_username', user_id: user.id)
                                .first
        
        if ebay_username_field.nil? || ebay_username_field.value.empty?
            render json: {status: "failed", message: "No eBay account associated with username: #{username}"}
            return
        end

        ebay_username = ebay_username_field.value

        if user_meets_criteria?(user, ebay_username)
                Jobs.enqueue(:get_seller_listings, ebay_seller: ebay_username)
                render json: {status: "job triggered", message: "Fetching eBay listings.", discourse_user: user.username, ebay_username: ebay_username}
        else 
            render json: {status: "failed", message: "User does not meet group/trust criteria or is blocked: #{username}"}
        end
    end

    def dump_seller_listings
        seller_name = params[:seller_name]

        Jobs.enqueue(:dump_seller_listings, seller_name: params[:seller_name])
        render json: {status: "job triggered", message: "Dropping eBay listings from #{seller_name}"}
    end


    private

    def user_meets_criteria?(user, seller_name)
        blocked_seller = EbayAdPlugin::EbaySellerBlock.find_by(seller: seller_name)
        return false if blocked_seller
                    
        user.in_any_groups?(SiteSetting.ebay_seller_allowed_groups_map)
    end


    def get_all_account_info
        UserCustomField.where(name: 'ebay_username').map do |account|
            { 
              user_id: account.user_id, 
              username: account.user.username,
              ebay_username: account.value
            }
        end
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