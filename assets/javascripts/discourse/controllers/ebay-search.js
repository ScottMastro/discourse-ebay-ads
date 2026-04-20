import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { ajax } from "discourse/lib/ajax";

export default class extends Controller {
  @tracked ebayListings = [];
  @tracked totalCount = 0;
  @tracked impressionList = [];

  @tracked isLoading = false;
  @tracked hasMore = true;
  @tracked search_keys = "";
  @tracked filtered_username = null;

  @tracked mode_row = true;

  limit = 20;
  offset = 0;
  observer = null;

  init() {
    super.init();
    this.flushTimer = null;
    this.flushInterval = 500;

    this.loadEbayListings(true);
    scheduleOnce("afterRender", this, this.setupScrollObserver);
  }

  loadEbayListings(force) {
    if (!force && (this.isLoading || !this.hasMore)) {
      return;
    }

    this.isLoading = true;
    let url = `/ebay/search.json?limit=${this.limit}&offset=${this.offset}`;
    if (this.search_keys) {
      url = url + "&search_keys=" + encodeURIComponent(this.search_keys);
    }
    if (this.filtered_username) {
      url = url + "&username=" + encodeURIComponent(this.filtered_username);
    }

    ajax(url)
      .then((result) => {
        if (result.ebay_listings.length < this.limit) {
          this.hasMore = false;
        }

        this.totalCount = result.total_count;
        this.ebayListings = [...this.ebayListings, ...result.ebay_listings];
        this.offset += this.limit;
        this.isLoading = false;

        const container = document.querySelector("#listings-container");
        const observer = new MutationObserver((mutations, obs) => {
          result.ebay_listings.forEach((item) => {
            this.setupImpressionObserver(item.item_id);
          });
          obs.disconnect();
        });

        observer.observe(container, { childList: true });
      })
      .catch(() => {
        this.isLoading = false;
      });
  }

  @action
  onChangeSearchForUsername(username) {
    this.filtered_username = username;
    this.offset = 0;
    this.ebayListings = [];
    this.loadEbayListings(true);
  }

  @action
  updateSearch(search_text) {
    this.search_keys = search_text;
    this.offset = 0;
    this.ebayListings = [];
    this.loadEbayListings(true);
  }

  @action
  switchModeGrid() {
    this.mode_row = false;
  }

  @action
  switchModeRow() {
    this.mode_row = true;
  }

  @action
  trackEbayClick(itemId) {
    const encodedId = encodeURIComponent(itemId);
    ajax(`/ebay/adclick/${encodedId}`);
  }

  trackEbayImpression(itemId) {
    this.impressionList.push(itemId);

    if (this.flushTimer) {
      clearTimeout(this.flushTimer);
    }

    if (this.impressionList.length >= 20) {
      this.flushImpressions();
    } else {
      this.flushTimer = setTimeout(() => {
        this.flushImpressions();
      }, this.flushInterval);
    }
  }

  flushImpressions() {
    if (this.impressionList.length > 0) {
      const encodedItemsList = Array.from(this.impressionList).map((item) =>
        encodeURIComponent(item)
      );

      const encodedItems = encodedItemsList.join("&");
      const url = `/ebay/adimpression/${encodedItems}`;
      this.impressionList = [];

      ajax(url);
    }

    this.flushTimer = null;
  }

  @action
  onScrollToEnd() {
    this.loadEbayListings(false);
  }

  setupScrollObserver() {
    let options = { root: null, rootMargin: "0px", threshold: 1.0 };

    this.observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !this.isLoading) {
        this.onScrollToEnd();
      }
    }, options);

    const sentinel = document.querySelector(".ebay-search-scroll-sentinel");
    if (sentinel) {
      this.observer.observe(sentinel);
    }
  }

  setupImpressionObserver(itemId) {
    let options = { root: null, rootMargin: "0px", threshold: 1.0 };

    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        this.trackEbayImpression(itemId);
        observer.disconnect();
      }
    }, options);

    const impression = document.getElementById(`impression-observer-${itemId}`);
    if (impression) {
      observer.observe(impression);
    }
  }
}
