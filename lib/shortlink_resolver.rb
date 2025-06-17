# frozen_string_literal: true

module Ebay
  class ShortlinkResolver
    require "open-uri"
    require "uri"

    def self.resolve(url)
      uri = URI.parse(url)

      unless uri.host == "ebay.us"
        return { error: "Only ebay.us links are supported" }
      end

      # Follow redirect with a browser-like User-Agent
      redirect_url = URI.open(url, "User-Agent" => "Mozilla/5.0", redirect: false) do |resp|
        # If not redirected, bail
        location = resp.meta["location"]
        unless location
          return { error: "No redirect location found" }
        end
        location
      end

      item_id_match = redirect_url.match(/\/itm\/(\d{11,14})/)
      item_id = item_id_match[1] if item_id_match

      {
        itemId: item_id,
        resolvedUrl: redirect_url
      }
    rescue => e
      { error: e.message }
    end
  end
end
