# frozen_string_literal: true

# Cached pool of eligible (seller, listings, weight) tuples used by the
# ad-serving hot path. Replaces per-request DB queries in ad_data with a
# binary search over cumulative weights and an O(1) array sample.
#
# Contents of the cached pool:
#   sellers:      parallel array of { user_id, ebay_username, user_info }
#   cum_weights:  cumulative sum of each seller's weight, same length as `sellers`
#   total_weight: cum_weights.last (or 0)
#
# Listing IDs are NOT cached — the (seller, active) partial index makes
# `ORDER BY RANDOM() LIMIT 1` per-seller fast (~0.4ms on 32k active rows),
# and keeping them in the cache bloats the PluginStore payload enough to
# hurt the hot path.
#
# Stored in PluginStore with a 6h TTL. Call `bust!` after any change that
# invalidates the pool (seller added/hidden, listings activated/deactivated).
module EbayAdPlugin::AdPool
  PLUGIN_NAME = "ebay_ad_plugin"
  CACHE_KEY = "ebay_ad_pool"
  TTL_SECONDS = 6.hours.to_i

  class << self
    def fetch
      cached = PluginStore.get(PLUGIN_NAME, CACHE_KEY)
      if cached && cached[:timestamp] && Time.now.utc.to_i - cached[:timestamp].to_i < TTL_SECONDS
        return cached[:data]
      end

      pool = build
      PluginStore.set(PLUGIN_NAME, CACHE_KEY, { data: pool, timestamp: Time.now.utc.to_i })
      pool
    end

    def bust!
      PluginStore.remove(PLUGIN_NAME, CACHE_KEY)
    end

    # Returns a seller hash (or nil if the pool is empty).
    def sample_seller
      pool = fetch
      total = pool[:total_weight]
      return nil if total.zero?

      r = rand(total)
      idx = pool[:cum_weights].bsearch_index { |cw| cw > r }
      pool[:sellers][idx]
    end

    private

    def build
      sellers = []
      cum_weights = []
      running = 0

      allowed_groups = SiteSetting.ebay_banner_allowed_groups_map
      base_weight = SiteSetting.ebay_seller_base_weight.to_i
      cutoff = 1.month.ago.to_date

      sellers_with_listings =
        EbayAdPlugin::EbayListing.where(active: true).distinct.pluck(:seller).to_set

      EbayAdPlugin::EbaySeller
        .where(hidden: false, blocked: false)
        .find_each do |seller|
          next if sellers_with_listings.exclude?(seller.ebay_username)

          user = User.find_by(id: seller.user_id)
          next if user.nil?
          next unless user.in_any_groups?(allowed_groups)

          time_read =
            UserVisit
              .where(user_id: seller.user_id)
              .where("visited_at >= ?", cutoff)
              .sum(:time_read)
          weight = (time_read.to_i > 0 ? 1 : 0) + base_weight
          next if weight.zero?

          running += weight
          cum_weights << running
          sellers << {
            user_id: seller.user_id,
            ebay_username: seller.ebay_username,
            user_info: {
              username: user.username,
              name: user.name,
              title: user.title,
              avatar: user.avatar_template,
            },
          }
        end

      { sellers: sellers, cum_weights: cum_weights, total_weight: running }
    end
  end
end
