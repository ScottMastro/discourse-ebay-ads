module EbayAdPlugin::ListingManager
  def self.record_ebay_listings(listings)
    return if listings.blank?

    now = Time.current
    rows = listings.map { |l| row_for(l, now) }.compact

    EbayAdPlugin::EbayListing.upsert_all(rows, unique_by: :item_id) if rows.any?
  end

  def self.record_ebay_listing(listing)
    record_ebay_listings([listing])
  end

  def self.row_for(listing, now)
    return nil if listing["itemId"].blank?

    price_value, currency_value =
      if listing["price"]
        [listing["price"]["value"].to_d, listing["price"]["currency"]]
      elsif listing["currentBidPrice"]
        [listing["currentBidPrice"]["value"].to_d, listing["currentBidPrice"]["currency"]]
      else
        [0.0, "USD"]
      end

    feedback_percent =
      if listing.dig("seller", "feedbackPercentage")
        listing["seller"]["feedbackPercentage"].to_d
      else
        0.0
      end

    {
      item_id: listing["itemId"],
      active: true,
      legacy_id: listing["legacyItemId"],
      title: listing["title"],
      description: "",
      price: price_value,
      currency: currency_value,
      image_url: listing.dig("image", "imageUrl"),
      end_date: now,
      location: listing.dig("itemLocation", "country"),
      seller: listing.dig("seller", "username"),
      feedback_score: listing.dig("seller", "feedbackScore").to_i,
      feedback_percent: feedback_percent,
      created_at: now,
      updated_at: now,
    }
  end
end
