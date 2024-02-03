import { ajax } from 'discourse/lib/ajax';
import { withPluginApi } from "discourse/lib/plugin-api";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { getOwner } from '@ember/application';

export default {
  name: "extend-for-ebay-preferences",
  initialize() {

    withPluginApi("0.8", (api) => {
      api.modifyClass('controller:preferences/profile', {
        pluginId: 'discourse-ebay-ads',
      
        actions: {
          save() {
            this._super(...arguments);
            const ebayUserSettings = getOwner(this).lookup('service:ebay-user-settings');
            const { ebayUsername, hideListings } = ebayUserSettings;
            const encodedUsername = encodeURIComponent(ebayUsername);
            let url = `/ebay/user/update_settings/${encodedUsername}?hidden=${hideListings}`;
            ajax(url).catch(popupAjaxError);
          },
        },
      });
    });
  }
    
};
