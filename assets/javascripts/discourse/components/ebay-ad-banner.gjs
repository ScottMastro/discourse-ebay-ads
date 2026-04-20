import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class EbayAdBanner extends Component {
  @tracked model = null;
  @tracked voteStatus = 0;

  constructor() {
    super(...arguments);
    this.loadAd();
  }

  get formattedPrice() {
    if (this.model && this.model.price) {
      return "$" + parseFloat(this.model.price).toFixed(2);
    }
    return "?";
  }

  async loadAd() {
    try {
      const result = await ajax("/ebay/ad");

      if (!result || Object.keys(result).length === 0) {
        return;
      }

      this.model = result;
      const avatarUrl = this.model.seller_info.avatar;
      this.model.seller_info.avatar = avatarUrl.replace("{size}", "96");
      this.setupImpressionWatcher();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  trackEbayClick() {
    const encodedId = encodeURIComponent(this.model.item_id);
    ajax(`/ebay/adclick/${encodedId}?banner=true`);
  }

  @action
  goToSeller(event) {
    event.preventDefault();
    event.stopPropagation();
    window.open(`/u/${this.model.seller_info.username}`, "_blank", "noopener");
  }

  @action
  likeAd() {
    const vote = this.voteStatus === 1 ? 0 : 1;
    const encodedId = encodeURIComponent(this.model.item_id);
    ajax(`/ebay/vote/${encodedId}?vote=${vote}`).then(() => {
      this.voteStatus = vote;
    });
  }

  @action
  dislikeAd() {
    const vote = this.voteStatus === -1 ? 0 : -1;
    const encodedId = encodeURIComponent(this.model.item_id);
    ajax(`/ebay/vote/${encodedId}?vote=${vote}`).then(() => {
      this.voteStatus = vote;
    });
  }

  trackEbayImpression() {
    const encodedId = encodeURIComponent(this.model.item_id);
    ajax(`/ebay/adimpression/${encodedId}`);
  }

  setupImpressionWatcher() {
    const options = { root: null, rootMargin: "0px", threshold: 1.0 };

    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        this.trackEbayImpression();
        observer.disconnect();
      }
    }, options);

    const impression = document.querySelector(".impression-observer");
    if (impression) {
      observer.observe(impression);
    }
  }

  <template>
    <div class="advertisement-info">
      {{i18n "ebay_ads.advertisement"}}
      ⓘ
      <a class="all-listings-link" href="/ebay">
        {{i18n "ebay_ads.banner.all_listings"}}
      </a>
    </div>

    <div class="ebay-ad-container">
      <div class="impression-observer"></div>
      {{#if this.model}}
        <div class="ebay-ad-banner">
          <a
            class="ebay-ad-item-info ebay-ad-flex"
            href="https://www.ebay.com/itm/{{this.model.legacy_id}}?mkevt=1&mkcid=1&mkrid=711-53200-19255-0&campid={{this.model.epn_id}}&toolid=1001"
            target="_blank"
            rel="noopener noreferrer"
            {{on "click" this.trackEbayClick}}
          >
            <div class="ebay-ad-image">
              <img
                class="ebay-ad-thumbnail-img"
                src={{this.model.image_url}}
                alt=""
              />
            </div>

            <div class="ebay-ad-info-details">
              <div class="ebay-ad-title">{{this.model.title}}</div>

              <div class="ebay-ad-clickables-container">
                {{#if this.model.seller_info}}
                  {{! template-lint-disable no-invalid-interactive }}
                  <div class="ebay-ad-clickable" {{on "click" this.goToSeller}}>
                    <img
                      class="ebay-ad-avatar"
                      src={{this.model.seller_info.avatar}}
                    />
                    <div class="ebay-ad-seller-info-name">
                      {{this.model.seller_info.username}}
                    </div>
                  </div>
                {{/if}}

                <div class="vote-div">
                  <DButton
                    @action={{this.likeAd}}
                    @icon={{if (eq this.voteStatus 1) "heart" "far-heart"}}
                    class="vote-button vote-like-button
                      {{if
                        (eq this.voteStatus 1)
                        'vote-up-cast'
                        'no-vote-cast'
                      }}"
                  />
                  <DButton
                    @action={{this.dislikeAd}}
                    @icon={{if (eq this.voteStatus -1) "circle-xmark" "xmark"}}
                    class="vote-button vote-dislike-button
                      {{if
                        (eq this.voteStatus -1)
                        'vote-down-cast'
                        'no-vote-cast'
                      }}"
                  />
                </div>
              </div>
            </div>
          </a>
        </div>
      {{/if}}
    </div>
  </template>
}
