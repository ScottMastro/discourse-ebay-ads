import Component from '@glimmer/component';
import { ajax } from 'discourse/lib/ajax';
import { withPluginApi } from "discourse/lib/plugin-api";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";

export default class EbayPreferencesSettings extends Component {
      @service ebayUserSettings;
  
      get ebayUsername() {
        return this.ebayUserSettings.ebayUsername;
      }   
      set ebayUsername(value) {
        this.ebayUserSettings.ebayUsername = value;
      }
    
      get hideListings() {
        return this.ebayUserSettings.hideListings;
      }
    
      set hideListings(value) {
        this.ebayUserSettings.hideListings = value;
      }
    
    constructor() {
      super(...arguments);
      withPluginApi("0.8", (api) => {

        const currentUser = api.getCurrentUser();
        if (currentUser) {
            ajax(`/ebay/user/settings/${currentUser.id}`)
                .then((result) => {
                    if (result.seller) {
                        this.ebayUsername = result.seller.ebay_username;
                        this.hideListings = result.seller.hidden;
                    }
                }).catch(popupAjaxError);
        }
        
      }); 

  }
}