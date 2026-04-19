import { fn } from "@ember/helper";
import DButton from "discourse/components/d-button";
import TextField from "discourse/components/text-field";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";

export default <template>
  <div class="control-group">
    <div class="controls">
      <TextField
        @value={{@controller.ebaySeller}}
        @placeholderKey="ebay_ads.admin.username_prompt"
        @id="ebay-seller-search"
      />
      <DButton
        @action={{@controller.addSeller}}
        @icon="plus"
        @translatedLabel={{i18n "ebay_ads.admin.add"}}
        class="btn-primary"
      />
      <DButton
        @action={{@controller.blockSeller}}
        @translatedLabel={{i18n "ebay_ads.admin.block"}}
        @icon="ban"
        class="btn-primary btn-danger"
      />
    </div>
    <a
      href="https://www.ebay.com/usr/{{@controller.ebaySeller}}"
      target="_blank"
      rel="noopener noreferrer"
    >https://www.ebay.com/usr/{{@controller.ebaySeller}}</a>
  </div>
  <hr />

  <h3>{{i18n "ebay_ads.admin.seller_table"}}</h3>
  <div class="table">
    <table>
      <thead>
        <tr>
          <th>{{i18n "ebay_ads.admin.seller"}}</th>
          <th>{{i18n "ebay_ads.admin.updated"}}</th>
          <th></th>
          <th>{{i18n "ebay_ads.admin.listings"}}</th>
        </tr>
      </thead>

      {{#if @controller.allSellers.length}}
        <tbody>
          {{#each @controller.allSellers as |seller|}}
            <tr>
              <td>
                <a
                  href="/u/{{seller.username}}/preferences/profile"
                >{{seller.username}}</a>
                <br />{{#if seller.blocked}}
                  ❌
                {{/if}}

                <a
                  href="https://www.ebay.com/usr/{{seller.ebay_username}}"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <span class="truncate-text">{{seller.ebay_username}}</span>
                </a>
              </td>
              <td>{{formatDate seller.last_update}}</td>
              <td>
                {{#if seller.blocked}}
                  <DButton
                    @action={{fn
                      @controller.unblockSellerFromTable
                      seller.ebay_username
                    }}
                    @translatedLabel={{i18n "ebay_ads.admin.unblock"}}
                  />
                {{else}}
                  <DButton
                    @action={{fn
                      @controller.blockSellerFromTable
                      seller.ebay_username
                    }}
                    @translatedLabel={{i18n "ebay_ads.admin.block"}}
                    @icon="ban"
                  />
                {{/if}}
                <DButton
                  @action={{fn
                    @controller.deleteSellerFromTable
                    seller.ebay_username
                  }}
                  @translatedLabel={{i18n "ebay_ads.admin.delete"}}
                  class="btn-primary btn-danger"
                  @icon="trash-can"
                />
              </td>
              <td>{{seller.listings_count}}</td>
              <td>
                {{#if seller.username}}
                  <DButton
                    @action={{fn @controller.fetchListings seller.username}}
                    @translatedLabel={{i18n "ebay_ads.admin.update"}}
                    @icon="rotate"
                  />
                {{/if}}

                <DButton
                  @action={{fn
                    @controller.dumpListingsFromTable
                    seller.ebay_username
                  }}
                  @icon="broom"
                  @translatedLabel={{i18n "ebay_ads.admin.clear"}}
                  class="btn-primary btn-danger"
                />
              </td>
            </tr>
          {{/each}}
        </tbody>
      {{else}}
        <div class="spinner"></div>
      {{/if}}
    </table>
  </div>
</template>
