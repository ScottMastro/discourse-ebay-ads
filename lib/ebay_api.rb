require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'erb'
require 'logger'

module EbayAdPlugin::EbayAPI

    SLEEP_TIME = 0.2 #seconds
    TOKEN_EXPIRY_BUFFER = 60 # seconds
    EBAY_API_BASE = "https://api.ebay.com"
    BROWSE_API = "#{EBAY_API_BASE}/buy/browse/v1"
    AUTH_API = "#{EBAY_API_BASE}/identity/v1/oauth2/token"
    SCOPE = "https://api.ebay.com/oauth/api_scope"

    @access_token = nil
    @token_time = Time.now
    @token_expiry = 0

    class << self
        attr_accessor :access_token, :token_time, :token_expiry
    end

    def self.logger
        @logger ||= Logger.new($stdout)
    end

    def self.token_expired?
        return true if @access_token.nil?
        elapsed_time = Time.now - @token_time
        elapsed_time > (@token_expiry - TOKEN_EXPIRY_BUFFER)
    end


    def self.count_call(call_type)
        ebay_api_call = EbayAdPlugin::EbayApiCall.find_or_initialize_by(date: Date.today, call_type: call_type)

        if ebay_api_call.new_record?
          ebay_api_call.count = 1
          ebay_api_call.save
        else
          ebay_api_call.increment!(:count)
        end
    end

    def self.update_token()

        client_id = SiteSetting.client_id
        client_secret = SiteSetting.client_secret

        scope = "https://api.ebay.com/oauth/api_scope"
        
        uri = URI.parse(AUTH_API)

        header = {"Content-Type": "application/x-www-form-urlencoded"}
        header["Authorization"] = "Basic " + Base64.strict_encode64("#{client_id}:#{client_secret}")

        begin
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            request = Net::HTTP::Post.new(uri.request_uri, header)
            request.body = "grant_type=client_credentials&scope=#{ERB::Util.url_encode(SCOPE)}"

            response = http.request(request)
            response_info = JSON.parse(response.body)
            
            @access_token = response_info["access_token"]
            @token_time = Time.now
            @token_expiry = response_info["expires_in"]    

            count_call("oauth")
        rescue => e
            logger.error "Failed to update token: #{e.message}"
        end
    end
    
    def self.add_ebay_listing(item_data)

        #todo: add to db in another file? increased modularity
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
          feedback_score:                  item_data["seller"]["feedbackScore"].to_i,
          feedback_percent:                item_data["seller"]["feedbackPercentage"].to_d
        )

        item_data["itemId"]
    end

    def self.make_request(url)
        update_token() if token_expired?

        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri.request_uri)
        request['Authorization'] = "Bearer " + @access_token
        request['Content-Type'] = 'application/json'
        request['X-EBAY-C-ENDUSERCTX'] = 'contextualLocation=country%3DUS%2Czip%3D19406'

        count_call("browse")

        return http.request(request)
    end


    def self.lookup_ebay_listing(item_id)
        url = "#{BROWSE_API}/item/get_item_by_legacy_id?legacy_item_id=#{item_id}"   
        response = make_request(url)

        if response.code == '200'
            item = JSON.parse(response.body)
            return item
        else
            # Handle errors
            puts "Error fetching listings: #{response.body}"
            return response.body
        end
    end


    def self.fetch_listings_by_seller(seller_id, query = "pokemon")

        total_items_fetched = 0
        total_items_available = 0
        listings = []

        loop do
            url = "#{BROWSE_API}/item_summary/search?q=#{query}"
            url += "&filter=sellers:{#{seller_id}},buyingOptions:{AUCTION|FIXED_PRICE}"
            url += "&sort=newlyListed"
            url += "&offset=#{total_items_fetched}&limit=200"

            response = make_request(url)

            if response && response.code == '200'
                response_body = JSON.parse(response.body)
                total_items_available = response_body["total"].to_i

                response_body["itemSummaries"].each do |listing|
                    add_ebay_listing(listing)
                    listings << listing
                end

                total_items_fetched += response_body["itemSummaries"].size

                break if total_items_fetched >= total_items_available
                sleep SLEEP_TIME
            else
                logger.error "Error fetching listings: #{response&.body}"
                break
            end
        end

        listings

    end

end