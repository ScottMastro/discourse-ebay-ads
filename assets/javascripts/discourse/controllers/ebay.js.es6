import Controller from '@ember/controller';
import { ajax } from 'discourse/lib/ajax';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class extends Controller {
  @tracked ebayListings = [];
  @tracked isLoading = false;
  @tracked hasMore = true;
  @tracked search_keys = "";
  @tracked mode_row = true;

  limit = 20;
  offset = 0;
  observer = null;

  init() {
    super.init();
    this.loadEbayListings();
    this.setupObserver();
  }

  loadEbayListings() {
    if (this.isLoading || !this.hasMore) return;

    this.isLoading = true;

    ajax(`/ebay.json?limit=${this.limit}&offset=${this.offset}`).then((result) => {
      if (result.ebay_listings.length < this.limit) {
        this.hasMore = false;
      }

      this.ebayListings = [...this.ebayListings, ...result.ebay_listings];
      this.offset += this.limit;
      this.isLoading = false;
    }).catch((error) => {
      this.isLoading = false;
      console.error('Error fetching eBay listings:', error);
    });


  }

  @action
  onChangeSearchForUsername(username){
    //this.set("searched_username", username.length ? username : null);
    console.log(username);
  }

  @action
  updateSearch(search_text){
    console.log(search_text);

  }

  @action
  switchModeGrid(){
    this.mode_row = false;
  }

  @action
  switchModeRow(){
    this.mode_row = true;
  }


  @action
  onScrollToEnd() {
    console.log("END")

    this.loadEbayListings();
  }

  setupObserver() {
    let options = {
      root: null,
      rootMargin: '0px',
      threshold: 1.0
    };

    this.observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !this.isLoading) {
        this.onScrollToEnd();
      }
    }, options);

    console.log(this.observer)

    const sentinel = document.querySelector('.sentinel');
    if (!sentinel) {
      console.error('Sentinel element not found.');
    } else {
      this.observer.observe(sentinel);
    }
  }




  //didRender does not run!!!
  @action
  didRender() {
    this._super(...arguments);
    // Ensure that observer is only set up once and only when elements are rendered
    if (!this.observer) {
      this.setupObserver();
    }
  }

  willDestroy() {
    super.willDestroy();
    // Clean up the observer when the controller is destroyed
    if (this.observer) {
      this.observer.disconnect();
    }
  }
}
