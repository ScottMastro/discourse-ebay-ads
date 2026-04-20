# frozen_string_literal: true

class EbayAdPlugin::EbayAdController < ::ApplicationController
  requires_plugin "discourse-ebay-ads"

  def ad_data
    seller = EbayAdPlugin::AdPool.sample_seller
    return render(json: {}) if seller.nil?

    listing =
      EbayAdPlugin::EbayListing
        .where(seller: seller[:ebay_username], active: true)
        .order("RANDOM()")
        .first
    return render(json: {}) if listing.nil?

    listing_hash = listing.attributes
    listing_hash["seller_info"] = seller[:user_info]
    listing_hash["epn_id"] = SiteSetting.ebay_epn_id
    render json: listing_hash
  end

  def vote
    item_id = params[:item_id]
    vote = params[:vote]

    user_id = current_user ? current_user.id : -1
    ebay_vote = EbayAdPlugin::EbayVote.find_or_initialize_by(user_id: user_id, item_id: item_id)
    ebay_vote.vote = vote

    if ebay_vote.save
      render json: { message: "Vote recorded" }, status: :ok
    else
      render json: {
               message: "Failed to record vote",
               errors: ebay_vote.errors.full_messages,
             },
             status: :unprocessable_entity
    end
  end

  def ad_click
    item_id = params[:item_id]
    banner_click = params.fetch(:banner, "false") == "true"
    user_id = current_user ? current_user.id : -1
    EbayAdPlugin::EbayClick.create(user_id: user_id, item_id: item_id, banner_click: banner_click)

    render json: { message: "Click recorded" }
  end

  def ad_impression
    item_ids = params[:item_ids].split("&")

    sellers_by_increment =
      EbayAdPlugin::EbayListing.where(item_id: item_ids).pluck(:seller).compact.tally
    return render json: { message: "Impression(s) recorded" } if sellers_by_increment.empty?

    today = Date.current
    now = Time.current
    sellers_by_increment.each do |seller, increment|
      EbayAdPlugin::EbayImpression.upsert(
        { ebay_username: seller, date: today, count: increment, created_at: now, updated_at: now },
        unique_by: %i[ebay_username date],
        on_duplicate:
          Arel.sql(
            "count = ebay_impressions.count + EXCLUDED.count, " \
              "updated_at = EXCLUDED.updated_at",
          ),
      )
    end

    render json: { message: "Impression(s) recorded" }
  end

  def resolve_ebay_us
    url = params[:url]
    if url.blank?
      render json: { error: "Missing url parameter" }, status: :bad_request
      return
    end

    result = ShortlinkResolver.resolve(url)
    if result[:error]
      render json: result, status: :unprocessable_entity
    else
      render json: result
    end
  end
end
