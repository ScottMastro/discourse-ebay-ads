# frozen_string_literal: true

class EbayAdPlugin::EbaySellerController < ::ApplicationController
    before_action :ensure_logged_in

    def add_sellers_by_custom_field
      UserCustomField.where(name: 'ebay_username').each do |account|
        next if account.value.blank?
    
        ebay_seller = EbayAdPlugin::EbaySeller.find_or_initialize_by(ebay_username: account.value)
        ebay_seller.user_id = account.user_id
        ebay_seller.save
      end
    
      render json: { status: "ok", message: 'Ebay sellers updated.' }
    end

    def add_seller
        username = params[:ebay_username]
      
        ebay_seller = EbayAdPlugin::EbaySeller.find_or_initialize_by(ebay_username: username)  
        if ebay_seller.save
            render json: { status: "ok", message: 'Ebay seller added successfully.' }
            return
        end
        render json: { status: "failed", message: 'Ebay seller was not added.' }, status: :unprocessable_entity
    end

    def remove_seller
        username = params[:ebay_username]
      
        ebay_seller = EbayAdPlugin::EbaySeller.find_by(ebay_username: username)
        if ebay_seller
            if ebay_seller.destroy
                render json: { status: "ok", message: 'Ebay seller removed successfully.' }
            else
                render json: { status: "failed", message: 'Ebay seller could not be removed.', errors: ebay_seller.errors.full_messages }, status: :unprocessable_entity
            end
        else
            render json: { status: "failed", message: 'Ebay seller not found.' }
        end
    end

    def update_user_settings
      username = params[:ebay_username]
      target_user_id = params[:user_id].to_i
      hidden = params.fetch(:hidden, false)
      if current_user.id != target_user_id
        unless current_user.staff?
          return render json: { error: 'You are not authorized to perform this action.' }, status: :forbidden
        end
      end

      user = User.find_by(id: target_user_id)
      unless user
        return render json: { error: 'User not found.' }, status: :not_found
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

    def clear_user_settings
      user_id = params[:user_id]
    
      ebay_seller = EbayAdPlugin::EbaySeller.find_by(user_id: user_id)
      if ebay_seller
        if ebay_seller.destroy
          render json: { status: "ok", message: 'Ebay seller removed successfully.' }
        else
          render json: { status: "failed", message: 'Ebay seller could not be removed.', errors: ebay_seller.errors.full_messages }
        end
      else
        render json: { status: "failed", message: 'Ebay seller not found.' }
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
            listings_count: seller.listings_count # Accessed directly thanks to the SQL COUNT(*) AS listings_count
          }
        end
      
        render json: { sellers: sellers_info }
      end      

    def block_seller
        ebay_username = params[:ebay_username]

        seller = EbayAdPlugin::EbaySeller.find_by(ebay_username: ebay_username)

        if seller.nil?
            EbayAdPlugin::EbaySeller.create!(ebay_username: ebay_username, blocked: true)
            render json: { status: "ok", message: "Seller #{ebay_username} has been blocked." }
            return
          elsif seller.blocked
            render json: { status: "ok", error: "Seller #{ebay_username} has already been blocked." }
            return
          end

          seller.update!(blocked: true)
          render json: { status: "ok", message: "Seller #{ebay_username} has been blocked." }
    end

    def unblock_seller
        ebay_username = params[:ebay_username]

        seller = EbayAdPlugin::EbaySeller.find_by(ebay_username: ebay_username)
        if seller.nil?
            render json: { status: "failed", error: "Seller #{ebay_username} is unknown.", status: :not_found }
            return
        elsif seller.blocked
            seller.update!(blocked: false)
            render json: { status: "ok", message: "Seller #{ebay_username} has been unblocked." }
            return
        end
        
        render json: { status: "ok", error: "Seller #{ebay_username} was not currently blocked." }
    end

    def blocklist
        blocked_sellers = EbayAdPlugin::EbaySeller
                            .joins("LEFT JOIN users ON users.id = ebay_sellers.user_id")
                            .where(blocked: true)
                            .select("ebay_sellers.ebay_username, ebay_sellers.blocked, users.username AS username")
      
        sellers_info = blocked_sellers.map do |seller|
          {
            username: seller.username,
            ebay_username: seller.ebay_username,
            blocked: seller.blocked,
          }
        end
        render json: sellers_info
      end
      
    def dump_seller_listings
        ebay_username = params[:ebay_username]

        Jobs.enqueue(:dump_seller_listings, ebay_username: params[:ebay_username])
        render json: {status: "ok", message: "Dropping eBay listings from #{ebay_username} (job triggered)"}
    end  
end