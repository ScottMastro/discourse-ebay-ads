# frozen_string_literal: true

class EbayAdPlugin::EbaySellerController < ::ApplicationController
    before_action :ensure_logged_in

    def update_user_settings
      username = params[:ebay_username]
      hidden = params.fetch(:hidden, false)
      user = current_user

      if username.blank?
        existing_seller = EbayAdPlugin::EbaySeller.find_by(user_id: user.id)
        if existing_seller&.destroy
          render json: { message: 'Ebay seller removed.' }, status: :ok
        else
          render json: { message: 'Nothing to do.' }, status: :ok
        end
        return
      end
    
      ebay_seller = EbayAdPlugin::EbaySeller.find_or_initialize_by(user_id: user.id)
      ebay_seller.update(ebay_username: username, hidden: hidden)

      if ebay_seller.save
        render json: { message: 'Ebay seller updated successfully.' }, status: :ok
      else
        render json: { errors: ebay_seller.errors.full_messages }, status: :unprocessable_entity
      end
    end
   
    def get_user_settings
        @user_id = params[:user_id]
        seller = EbayAdPlugin::EbaySeller.find_by(user_id: @user_id)
  
        if seller
            render json: { seller: seller.as_json(only: [:user_id, :ebay_username, :hidden]) }
        else
          render json: { seller: nil }
        end    
    end

    def seller_info
        ebay_username = params[:ebay_username]
        seller = EbayAdPlugin::EbaySeller.find_by(ebay_username: ebay_username)
        listings_count = EbayAdPlugin::EbayListing.where(seller: ebay_username).count
        render json: {seller: seller, listings_count: listings_count}
    end

    def all_seller_info
        sql = <<-SQL
          SELECT ebay_sellers.*, users.username AS user_username, 
          (SELECT COUNT(*) FROM ebay_listings WHERE ebay_listings.seller = ebay_sellers.ebay_username) AS listings_count
          FROM ebay_sellers
          LEFT JOIN users ON users.id = ebay_sellers.user_id
        SQL
      
        sellers_info = EbayAdPlugin::EbaySeller.find_by_sql(sql).map do |seller|
          {
            user_id: seller.user_id,
            username: seller.user_username, # Accessed directly thanks to the SQL alias
            ebay_username: seller.ebay_username,
            hidden: seller.hidden,
            blocked: seller.blocked,
            blocked_reason: seller.blocked_reason,
            listings_count: seller.listings_count # Accessed directly thanks to the SQL COUNT(*) AS listings_count
          }
        end
      
        render json: { sellers: sellers_info }
      end
      
      

    def block_seller
        ebay_username = params[:ebay_username]
        reason = params[:reason] || ""

        seller = EbayAdPlugin::EbaySeller.find_by(ebay_username: ebay_username)

        if seller.nil?
            EbayAdPlugin::EbaySeller.create!(ebay_username: ebay_username, blocked: true, blocked_reason: reason)
            render json: { status: "ok", message: "Seller #{ebay_username} has been blocked. Reason: #{reason}" }
            return
          elsif seller.blocked
            render json: { status: "ok", error: "Seller #{ebay_username} has already been blocked. Existing reason: #{seller.blocked_reason}" }
            return
          end

          seller.update!(blocked: true, blocked_reason: reason)
          render json: { status: "ok", message: "Seller #{ebay_username} has been blocked. Reason: #{reason}" }
    end

    def unblock_seller
        ebay_username = params[:ebay_username]

        seller = EbayAdPlugin::EbaySeller.find_by(ebay_username: ebay_username)
        if seller.nil?
            render json: { status: "failed", error: "Seller #{ebay_username} is unknown.", status: :not_found }
            return
        elsif seller.blocked
            seller.update!(blocked: false, blocked_reason: nil)
            render json: { status: "ok", message: "Seller #{ebay_username} has been unblocked." }
            return
        end
        
        render json: { status: "ok", error: "Seller #{ebay_username} was not currently blocked." }
    end

    def blocklist
        blocked_sellers = EbayAdPlugin::EbaySeller
                            .joins("LEFT JOIN users ON users.id = ebay_sellers.user_id")
                            .where(blocked: true)
                            .select("ebay_sellers.ebay_username, ebay_sellers.blocked, ebay_sellers.blocked_reason, users.username AS username")
      
        sellers_info = blocked_sellers.map do |seller|
          {
            username: seller.username,
            ebay_username: seller.ebay_username,
            blocked: seller.blocked,
            blocked_reason: seller.blocked_reason,
          }
        end
      
        render json: sellers_info
      end
      
      
end