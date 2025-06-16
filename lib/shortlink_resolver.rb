# frozen_string_literal: true

module Ebay
  class ShortlinkResolver
    require "net/http"
    require "uri"

    def self.resolve(url)
      uri = URI.parse(url)

      unless uri.host == "ebay.us"
        return { error: "Only ebay.us links are supported" }
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      response = http.request_head(uri.request_uri)
      redirect_url = response["location"]

      unless redirect_url
        return { error: "No redirect location found" }
      end

      item_id = redirect_url.match(/\/itm\/(\d{11,14})/)
      item_id = item_id[1] if item_id


      {
        itemId: item_id,
        resolvedUrl: redirect_url
      }
    rescue => e
      { error: e.message }
    end
  end
end
