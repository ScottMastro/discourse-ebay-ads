module EbayAdPlugin::ListingManager

    def self.record_ebay_listing(listing)
             
        EbayAdPlugin::EbayListing.create!(
          item_id:                         listing["itemId"],
          legacy_id:                       listing["legacyItemId"],
          title:                           listing["title"],
          description:                     "",
          price:                           listing["price"]["value"].to_d,
          currency:                        listing["price"]["currency"],
          image_url:                       listing["image"]["imageUrl"],
          end_date:                        Time.now,
          location:                        listing["itemLocation"]["country"],
          seller:                          listing["seller"]["username"],
          feedback_score:                  listing["seller"]["feedbackScore"].to_i,
          feedback_percent:                listing["seller"]["feedbackPercentage"].to_d
        )
    end

    def self.record_ebay_listings(listings)
        listings.each do |listing|
            record_ebay_listing(listing)
        end
    end
end