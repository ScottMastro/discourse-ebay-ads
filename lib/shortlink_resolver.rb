# frozen_string_literal: true

module Ebay
  class ShortlinkResolver
    require "net/http"
    require "uri"

    def self.resolve(url)
      uri = URI.parse(url)

      return { error: "Only ebay.us links are supported" } unless uri.host == "ebay.us"
      return { error: "Only https is supported" } unless uri.scheme == "https"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri, "User-Agent" => "Mozilla/5.0")
      response = http.request(request)

      unless response.is_a?(Net::HTTPRedirection)
        return { error: "Expected a redirect, got #{response.code}" }
      end

      redirect_url = response["location"]
      return { error: "No redirect location found" } unless redirect_url

      item_id_match = redirect_url.match(%r{/itm/(\d{11,14})})
      item_id = item_id_match[1] if item_id_match

      { itemId: item_id, resolvedUrl: redirect_url }
    rescue => e
      { error: e.message }
    end
  end
end
