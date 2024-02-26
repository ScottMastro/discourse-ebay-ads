# frozen_string_literal: true

module EbayAdPlugin
  class EbayListing < ActiveRecord::Base
    self.table_name = 'ebay_listings'
  end

  class EbayApiCall < ActiveRecord::Base
    self.table_name = 'ebay_api_calls'
  end

  class EbaySeller < ActiveRecord::Base
    self.table_name = 'ebay_sellers'
  end

  class EbayClick < ActiveRecord::Base
    self.table_name = 'ebay_clicks'
  end

  class EbaySearchImpression < ActiveRecord::Base
    self.table_name = 'ebay_search_impressions'
  end

  class EbayBannerImpression < ActiveRecord::Base
    self.table_name = 'ebay_banner_impressions'
  end

end