# frozen_string_literal: true

class EbayAdPlugin::EbayAdController < ::ApplicationController
    
    def ad_data
        if EbayAdPlugin::EbayListing.count > 0
          random_seller = weighted_random_selector
          if random_seller.nil?
            render json: { error: "No seller found." }, status: :not_found
            return
          end
      
          random_listing = EbayAdPlugin::EbayListing.where(seller: random_seller.ebay_username).order("RANDOM()").first
      
          # Check if a listing was successfully selected for the seller
          if random_listing.nil?
            render json: { error: "No listing found for selected seller." }, status: :not_found
            return
          end
      
          listing_hash = random_listing.attributes
          listing_hash["epn_id"] = SiteSetting.ebay_epn_id
          render json: listing_hash
        else
          render json: { error: "No listings available." }, status: :not_found
        end
      end
      

    def weighted_random_selector
        
        all_weights = fetch_all_weights
        STDERR.puts all_weights
        sellers = EbayAdPlugin::EbaySeller.where(hidden: false, blocked: false)
        weighted_pool = []
        
        sellers.each do |seller|
            weight = all_weights[seller.user_id.to_s] || 0 # Fallback to 0 if no weight is found
            next if weight == 0
            weight.times { weighted_pool << seller }
            
        end
        

        weighted_pool.sample
    end
    
  
    def fetch_all_weights
        key = "ebay_seller_weights"
        all_weights = PluginStore.get("ebay_ad_plugin", key)
      
        if all_weights && all_weights[:timestamp] && Time.now.utc.to_i - all_weights[:timestamp].to_i < 6.hours.to_i
          return all_weights[:data]
        else
          all_weights_data = calculate_all_weights
          PluginStore.set("ebay_ad_plugin", key, { data: all_weights_data, timestamp: Time.now.utc.to_i })
          return all_weights_data
        end
    end
      
    def calculate_all_weights
        weights = {}
        EbayAdPlugin::EbaySeller.where(hidden: false, blocked: false).find_each do |seller|
          weight = calculate_weight_for(seller)
          weights[seller.user_id.to_s] = weight
        end
        weights
      end
      
    
    def calculate_weight_for(seller)
        has_listings = EbayAdPlugin::EbayListing.where(seller: seller.ebay_username).exists?
        return 0 unless has_listings
    
        user = User.find_by(id: seller.user_id)
        return 0 if user.nil?
        return 0 if !user.in_any_groups?(SiteSetting.ebay_seller_allowed_groups_map)

        total_time_read_last_month = UserVisit.where(user_id: seller.user_id)
                                              .where("visited_at >= ?", 1.month.ago.to_date)
                                              .sum(:time_read)
        weight = total_time_read_last_month > 0 ? 1 : 0
        additional_weight = [total_time_read_last_month / 3600, 100].min
        return weight + additional_weight
    end

end