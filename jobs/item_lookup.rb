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
end