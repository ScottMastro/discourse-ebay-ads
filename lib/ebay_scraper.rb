require 'nokogiri'

module EbayAdPlugin::EbayScraper

    def self.scrape_ebay(urls)

        urls = extract_ebay_urls(text)

        urls.map do |url|
            #document = Nokogiri::HTML(URI.open(url))

            id= "195884282726"
            title = " Pokemon Card Infernape LV. X Holo Signed & Sketch Yoshida / Sugimori PSA Auto 8" rescue nil
            price = "US $19,999.00" rescue nil
            image_url = "https://i.ebayimg.com/images/g/ksEAAOSw5ndkjPLA/s-l1600.jpg" rescue nil
            seller_id = "stargazermommy" rescue nil
            feedback_number = "496" rescue nil


            return "id: #{id}\ntitle: #{title}\nprice: #{price}\nimage_url: #{image_url}\nseller_id: #{seller_id}\nfeedback_number: #{feedback_number}"
        end
    end
end
