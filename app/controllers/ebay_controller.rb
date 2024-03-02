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

    def search
        limit = params.fetch(:limit, 100).to_i
        offset = params.fetch(:offset, 0).to_i
        search_keys = params[:search_keys]
        discourse_username = params[:username]
      
        listings_query = EbayAdPlugin::EbayListing.joins("INNER JOIN ebay_sellers ON ebay_listings.seller = ebay_sellers.ebay_username")
      
        if discourse_username.present?
          user = User.find_by(username: discourse_username)
          if user
            ebay_seller = EbayAdPlugin::EbaySeller.find_by(user_id: user.id)
            listings_query = listings_query.where(ebay_sellers: { id: ebay_seller.id }) if ebay_seller
          else
            listings_query = EbayAdPlugin::EbayListing.none
          end
        end
      
        if search_keys.present?
            listings_query = listings_query.where("ebay_listings.title ILIKE :search OR ebay_listings.description ILIKE :search", search: "%#{search_keys}%")
        else
            listings_query = listings_query.order("RANDOM()")
        end
      
        total_count = listings_query.count
      
        date_seed = Date.today.to_s.hash

        paginated_listings = listings_query.limit(limit).offset(offset)
        listing_hashes = paginated_listings.map do |listing|
          listing_hash = listing.attributes
          listing_hash["epn_id"] = SiteSetting.ebay_epn_id 
          listing_hash
        end
      
        render json: { ebay_listings: listing_hashes, total_count: total_count }
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

    def update_user

        total_calls_today = EbayAdPlugin::EbayApiCall.where(date: Date.today, call_type: "browse").sum(:count)
        max_calls_allowed = SiteSetting.max_api_calls_per_day.to_i
        
        if total_calls_today >= max_calls_allowed
            return render json: {status: "failed", message: "Hit max API calls per day."}
        end

        username = params[:username]
        user = User.find_by(username: username)
    
        if user.nil?
            return render json: {status: "failed", message: "No user with username: #{username}"}     
        end
    
        seller = EbayAdPlugin::EbaySeller.find_by(user_id: user.id)
    
        if seller.nil? || seller.ebay_username.blank?
            return render json: {status: "failed", message: "No eBay account associated with username: #{username}"}
        end

        ebay_username = seller.ebay_username

        if user_meets_criteria?(user, ebay_username)
                Jobs.enqueue(:get_seller_listings, ebay_seller: ebay_username)
                render json: {status: "job triggered", message: "Fetching eBay listings.", discourse_user: user.username, ebay_username: ebay_username}
        else 
            render json: {status: "failed", message: "User does not meet group/trust criteria or is blocked: #{username}"}
        end
    end
    
    private

    def user_meets_criteria?(user, seller_name)
        ebay_seller = EbayAdPlugin::EbaySeller.find_by(ebay_username: seller_name)
        return false unless ebay_seller && !ebay_seller.blocked && !ebay_seller.hidden
                    
        user.in_any_groups?(SiteSetting.ebay_seller_allowed_groups_map)
    end


    def get_all_account_info
        account_info = EbayAdPlugin::EbaySeller.find_each.map do |seller|
            if seller.user_id.nil?
                next
            else
                user = User.find_by(id: seller.user_id)
                username = user.nil? ? nil : user.username
                {
                    user_id: seller.user_id,
                    username: username,
                    ebay_username: seller.ebay_username
                }
            end
        end

        account_info.compact
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
