module EbayAdPlugin::ListingManager

    def self.record_ebay_listing(listing)
    
        listing_record = EbayAdPlugin::EbayListing.find_or_initialize_by(item_id: listing["itemId"])

        price_value, currency_value = if listing["price"]
                                        [listing["price"]["value"].to_d, listing["price"]["currency"]]
                                      elsif listing["currentBidPrice"]
                                        [listing["currentBidPrice"]["value"].to_d, listing["currentBidPrice"]["currency"]]
                                      else
                                        [0.0, "USD"] # Default values
                                      end
        
        listing_record.assign_attributes(
          active:            true,
          legacy_id:         listing["legacyItemId"],
          title:             listing["title"],
          description:       "",
          price:             price_value,
          currency:          currency_value,
          image_url:         listing.dig("image", "imageUrl"),
          end_date:          Time.now,
          location:          listing.dig("itemLocation", "country"),
          seller:            listing.dig("seller", "username"),
          feedback_score:    listing.dig("seller", "feedbackScore").to_i,
          feedback_percent:  if listing.dig("seller", "feedbackPercentage")
                               listing["seller"]["feedbackPercentage"].to_d
                             else
                               0.0 # Default value if not available
                             end
        )
        
        listing_record.save!
        
    end

    def self.record_ebay_listings(listings)
        listings.each do |listing|
            record_ebay_listing(listing)
        end
    end
end