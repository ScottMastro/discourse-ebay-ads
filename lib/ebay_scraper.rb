# frozen_string_literal: true
require "nokogiri"

module EbayAdPlugin::EbayScraper
  def self.scrape_ebay(urls)
    urls.map do |url|
      #document = Nokogiri::HTML(URI.open(url))

      id = "195884282726"
      title =
        begin
          " Pokemon Card Infernape LV. X Holo Signed & Sketch Yoshida / Sugimori PSA Auto 8"
        rescue StandardError
          nil
        end
      price =
        begin
          "US $19,999.00"
        rescue StandardError
          nil
        end
      image_url =
        begin
          "https://i.ebayimg.com/images/g/ksEAAOSw5ndkjPLA/s-l1600.jpg"
        rescue StandardError
          nil
        end
      seller_id =
        begin
          "stargazermommy"
        rescue StandardError
          nil
        end
      feedback_number =
        begin
          "496"
        rescue StandardError
          nil
        end

      return(
        "id: #{id}\ntitle: #{title}\nprice: #{price}\nimage_url: #{image_url}\nseller_id: #{seller_id}\nfeedback_number: #{feedback_number}"
      )
    end
  end
end
