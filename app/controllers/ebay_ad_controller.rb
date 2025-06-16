# frozen_string_literal: true

class EbayAdPlugin::EbayAdController < ::ApplicationController
    
    def ad_data
        if EbayAdPlugin::EbayListing.count > 0
          random_seller = weighted_random_selector
          if random_seller.nil?
            render json: {} and return
          end
      
          random_listing = EbayAdPlugin::EbayListing.where(seller: random_seller.ebay_username).where(active: true).order("RANDOM()").first
      
          # Check if a listing was successfully selected for the seller
          if random_listing.nil?
            render json: {} and return
          end
      
          listing_hash = random_listing.attributes
      
          discourse_user = User.find_by(id: random_seller.user_id)
          if discourse_user
            user_info = {
              username: discourse_user.username,
              name: discourse_user.name,
              title: discourse_user.title,
              avatar: discourse_user.avatar_template,
            }
      
            listing_hash["seller_info"] = user_info
          end

          listing_hash["epn_id"] = SiteSetting.ebay_epn_id
          render json: listing_hash
        else
          render json: {} and return
        end
      end

    def weighted_random_selector
        
        all_weights = fetch_all_weights
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
        has_listings = EbayAdPlugin::EbayListing.where(seller: seller.ebay_username).where(active: true).exists?
        return 0 unless has_listings
        
        user = User.find_by(id: seller.user_id)
        return 0 if user.nil?
        return 0 if !user.in_any_groups?(SiteSetting.ebay_banner_allowed_groups_map)
        
        total_time_read_last_month = UserVisit.where(user_id: seller.user_id)
                                              .where("visited_at >= ?", 1.month.ago.to_date)
                                              .sum(:time_read)
        weight = total_time_read_last_month > 0 ? 1 : 0
        additional_weight = SiteSetting.ebay_seller_base_weight #[total_time_read_last_month / 3600, 100].min 
        return weight + additional_weight
    end

    def vote
      item_id = params[:item_id]
      vote = params[:vote]

      user_id = current_user ? current_user.id : -1
      ebay_vote = EbayAdPlugin::EbayVote.find_or_initialize_by(user_id: user_id, item_id: item_id)
      ebay_vote.vote = vote

      if ebay_vote.save
        render json: { message: 'Vote recorded' }, status: :ok
      else
        render json: { message: 'Failed to record vote', errors: ebay_vote.errors.full_messages }, status: :unprocessable_entity
      end    
    end

    def ad_click
      item_id = params[:item_id]
      banner_click = params.fetch(:banner, 'false') == 'true'
      user_id = current_user ? current_user.id : -1
      EbayAdPlugin::EbayClick.create(user_id: user_id, item_id: item_id, banner_click: banner_click)

      return render json: { message: 'Click recorded' }
    end

    def ad_impression
      item_ids = params[:item_ids].split('&')
      banner_impression = params.fetch(:banner, 'false') == 'true'
      user_id = current_user ? current_user.id : -1

      item_ids.each do |item_id|
        if banner_impression
          EbayAdPlugin::EbayBannerImpression.create(user_id: user_id, item_id: item_id)
        else
          search_impression = EbayAdPlugin::EbaySearchImpression.find_or_create_by(item_id: item_id)
          search_impression.increment!(:count)
        end
      end 

      return render json: { message: "Impression(s) recorded" }    
    end

    def resolve_ebay_us
      url = params[:url]
      if url.blank?
        render json: { error: "Missing url parameter" }, status: 400
        return
      end

      result = ShortlinkResolver.resolve(url)
      if result[:error]
        render json: result, status: 422
      else
        render json: result
      end
    end
end
