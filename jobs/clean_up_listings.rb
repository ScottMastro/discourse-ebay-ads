module Jobs
    class CleanUpListings < ::Jobs::Base
        def execute(args)

            EbayAdPlugin::EbayListing.where("updated_at < ?", 3.days.ago).find_each do |listing|
                listing.update(active: false)
            end
        end
    end
end