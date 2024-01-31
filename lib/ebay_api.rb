require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'erb'

module EbayAdPlugin::EbayAPI

    @@access_token = nil
    @@token_time = Time.now
    @@token_expiry = 0

    @@browse_api = "https://api.ebay.com/buy/browse/v1"

    def self.token_expired?
        if  @@access_token.nil?
            return true
        end
        elapsed_time = Time.now - @@token_time
        elapsed_time > @@token_expiry
    end



    def self.update_token()

        client_id = SiteSetting.client_id
        client_secret = SiteSetting.client_secret

        scope = "https://api.ebay.com/oauth/api_scope"
        
        uri = URI.parse("https://api.ebay.com/identity/v1/oauth2/token")
        
        header = {"Content-Type": "application/x-www-form-urlencoded"}
        header["Authorization"] = "Basic " + Base64.strict_encode64("#{client_id}:#{client_secret}")


        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri, header)
        request.body = "grant_type=client_credentials&scope=#{ERB::Util.url_encode(scope)}"

        response = http.request(request)
        response_info = JSON.parse(response.body)
        
        @@access_token = response_info["access_token"]
        @@token_time = Time.now
        @@token_expiry = response_info["expires_in"]    

        ebay_api_call = EbayAdPlugin::EbayApiCall.find_or_initialize_by(date: Date.today, type: "oauth")
        ebay_api_call.increment!(:count)

    end
    
    def self.add_ebay_listing(item_data)
        puts item_data
        
        EbayAdPlugin::EbayListing.create!(
          item_id:                         item_data["itemId"],
          legacy_id:                       item_data["legacyItemId"],
          title:                           item_data["title"],
          description:                     "",
          price:                           item_data["price"]["value"].to_d,
          currency:                        item_data["price"]["currency"],
          image_url:                       item_data["image"]["imageUrl"],
          end_date:                        Time.now,
          location:                        item_data["itemLocation"]["country"],
          seller:                          item_data["seller"]["username"],
          feedback_score:                  item_data["seller"]["feedbackScore"],
          feedback_percent:                item_data["seller"]["feedbackPercentage"]
        )

        item_data["itemId"]
    end

    def self.make_request(url)

        if token_expired?
            update_token()
        end

        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri.request_uri)
        request['Authorization'] = "Bearer " + @@access_token
        request['Content-Type'] = 'application/json'
        request['X-EBAY-C-ENDUSERCTX'] = 'contextualLocation=country%3DUS%2Czip%3D19406'

        ebay_api_call = EbayAdPlugin::EbayApiCall.find_or_initialize_by(date: Date.today, type: "api")
        ebay_api_call.increment!(:count)

        return http.request(request)

    end

    def self.lookup_ebay_listing(item_id)

        url = "#{@@browse_api}/item/get_item_by_legacy_id?legacy_item_id=#{item_id}"
        response = self.make_request(url)

        if response.code == '200'
            item = JSON.parse(response.body)
            return item
        else
            # Handle errors
            puts "Error fetching listings: #{response.body}"
            return response.body
        end
    end


    def self.fetch_listings_by_seller(seller_id)

        query_string = "q=pokemon"
        buy_options = "buyingOptions:{AUCTION|FIXED_PRICE}"
        newly_listed = "sort=newlyListed"
    
        url = "#{@@browse_api}/item_summary/search?#{query_string}&filter=sellers:{#{seller_id}},#{buy_options}&#{newly_listed}"
    
        response = self.make_request(url)

        if response.code == '200'
            listings = JSON.parse(response.body)
            return listings
        else
            # Handle errors
            puts "Error fetching listings: #{response.body}"
            return response.body
        end
    end

end