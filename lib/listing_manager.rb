# frozen_string_literal: true
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

  # After a fresh fetch for a seller, mark any of their previously-active
  # listings that did NOT appear in this fetch as inactive. This catches
  # sold/delisted items within one fetch cycle instead of waiting for the
  # 3-day CleanUpListings sweep.
  #
  # Guarded against empty fetches (API error, quota exhausted) — if we
  # didn't see ANY listings for this seller, we can't tell the difference
  # between "seller has no listings" and "fetch failed", so we do nothing
  # and let CleanUpListings handle it as a safety net.
  def self.deactivate_unseen(seller_username, seen_item_ids)
    return if seller_username.blank?
    return if seen_item_ids.blank?

    EbayAdPlugin::EbayListing
      .where(seller: seller_username, active: true)
      .where.not(item_id: seen_item_ids)
      .update_all(active: false, updated_at: Time.current)
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
