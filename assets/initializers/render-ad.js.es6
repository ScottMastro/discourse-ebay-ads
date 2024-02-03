import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";

export default {
  name: "initialize-ebay-ad-plugin",
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    if (siteSettings.enable_ebay_ads) {
      withPluginApi("0.1", (api) => generateAd(api, siteSettings));
    }
  },
};

function renderAd(component){

  ajax("/ebay.json")
  .then((result) => {
    
    if (result.id == null){
      component.setProperties({"valid": false});
    }
    else{
      component.setProperties({
        "valid" : true,
        "legacy_id": result.legacy_id,
        "title": result.title,
        "price": parseFloat(result.price).toFixed(2),
        "currency": result.currency,
        "location": result.location,

        "image_url":result.image_url,
        "seller": result.seller,
        "feedback_score": result.feedback_score,
        "feedback_percent": result.feedback_percent,
        "epn": result.epn_id
      });
    }

  }).catch(popupAjaxError);

    return component;
}

function generateAd(api, siteSettings) {
  api.registerConnectorClass('discovery-list-container-top', 'ebay-ad', {
    setupComponent(attrs, component) { component = renderAd(component); },
  });
  api.registerConnectorClass('topic-above-post-stream', 'ebay-ad', {
    setupComponent(attrs, component) { component = renderAd(component); },
  });

}