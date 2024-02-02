def create_system_post(topic_id, post_content)
    user = Discourse.system_user
    PostCreator.new(user,
      topic_id: topic_id,
      raw: post_content
    ).create!
end

module Jobs
  class ItemLookup < ::Jobs::Base
    def execute(args)

      tid=SiteSetting.ebay_topic_id

      begin
          item_id = args[:item_id]

          item_data = EbayAdPlugin::EbayAPI::lookup_ebay_listing(item_id)
          item_id = EbayAdPlugin::EbayAPI::add_ebay_listing(item_data)

          listing = EbayAdPlugin::EbayListing.find_by(item_id: item_id)

          post_reply = "rowid: " + listing["id"].to_s + "\n"
          post_reply = post_reply + "item id: " + listing["item_id"] + "\n"
          post_reply = post_reply + "url id: " + listing["legacy_id"] + "\n"
          post_reply = post_reply + "title: " + listing["title"] + "\n"
          post_reply = post_reply + "price: " + listing["price"].to_s + " " + listing["currency"] + "\n"
          post_reply = post_reply + "image_url: " + listing["image_url"] + "\n"
          post_reply = post_reply + "seller_id: " + listing["seller"] + "\n"
          post_reply = post_reply + "feedback_number: " + listing["feedback_score"].to_s

          create_system_post(tid, post_reply)  
        rescue => e
          create_system_post(tid, "Error: "+e.message)
        end
    end
  end


  class DropSeller < ::Jobs::Base
    def execute(args)
      
      seller_name = args[:seller_name]
      Rails.logger.error "Error dropping items for seller #{seller_name}: Seller name is required."

      begin
          EbayAdPlugin::EbayListing.where(seller: seller_name).destroy_all
      rescue => e
          Rails.logger.error "Error dropping items for eBay seller #{seller_name}: #{e.message}"
      end
    end
  end

  class GetSellerListings < ::Jobs::Base
    def execute(args)
      
      begin

      #todo: one user, one job

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
      
      rescue => e
          Rails.logger.error "Error fetching eBay listings: #{e.message}"
      end
    end
  end

end