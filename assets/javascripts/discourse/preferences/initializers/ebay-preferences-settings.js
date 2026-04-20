import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "extend-for-ebay-preferences",

  initialize() {
    withPluginApi((api) => {
      api.modifyClass(
        "controller:preferences/profile",
        (Superclass) =>
          class extends Superclass {
            pluginId = "discourse-ebay-ads";

            @action
            save() {
              const result = super.save(...arguments);

              const ebayUserSettings = getOwner(this).lookup(
                "service:ebay-user-settings"
              );
              const { discourseId, ebayUsername, hideListings } =
                ebayUserSettings;

              let url;
              if (ebayUsername === "") {
                url = `/ebay/user/clear_settings/${discourseId}`;
              } else {
                const encodedUsername = encodeURIComponent(
                  ebayUsername.toLowerCase()
                ).replace(/\./g, "%2E");
                url = `/ebay/user/update_settings/${encodedUsername}?user_id=${discourseId}&hidden=${hideListings}`;
              }

              ajax(url).catch(popupAjaxError);

              return result;
            }
          }
      );
    });
  },
};
