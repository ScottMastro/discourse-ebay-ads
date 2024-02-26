import Controller from '@ember/controller';
import { ajax } from 'discourse/lib/ajax';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { scheduleOnce } from '@ember/runloop';

export default class extends Controller {
  @tracked ebayListings = [];
  @tracked impressionList = [];

  @tracked isLoading = false;
  @tracked hasMore = true;
  @tracked search_keys = "";
  @tracked filtered_username = null;

  @tracked mode_row = true;

  @tracked selectedCompany = 'all';
  @tracked selectedGrade = true;


  limit = 20;
  offset = 0;
  observer = null;

  init() {
    super.init();
    this.flushTimer = null;
    this.flushInterval = 500;
  
    this.loadEbayListings(true);
    scheduleOnce('afterRender', this, this.setupScrollObserver);
   }

  loadEbayListings(force) {
    if (!force && (this.isLoading || !this.hasMore)) return;

    this.isLoading = true;
    let url = `/ebay/search.json?limit=${this.limit}&offset=${this.offset}`;
    if(this.search_keys){
      url = url + "&search_keys="+encodeURIComponent(this.search_keys);
    }
    if(this.filtered_username){ 
      url = url + "&username="+encodeURIComponent(this.filtered_username);
    }
    
    console.log(url);

    ajax(url).then((result) => {
      if (result.ebay_listings.length < this.limit) {
        this.hasMore = false;
      }

      this.ebayListings = [...this.ebayListings, ...result.ebay_listings];
      this.offset += this.limit;
      this.isLoading = false;

      const container = document.querySelector('#listings-container');
      const observer = new MutationObserver((mutations, obs) => {
        result.ebay_listings.forEach((item) => {
          this.setupImpressionObserver(item.item_id);
        });
        obs.disconnect(); 
      });
      
      observer.observe(container, { childList: true });


    }).catch((error) => {
      this.isLoading = false;
      console.error('Error fetching eBay listings:', error);
    });
  }


  @action
  onChangeSearchForUsername(username){
    this.filtered_username = username;
    this.offset=0;
    this.ebayListings=[];
    this.loadEbayListings(true);
  }

  @action
  updateSearch(search_text){
    this.search_keys = search_text;
    this.offset=0;
    this.ebayListings=[];
    this.loadEbayListings(true);
  }

  @action
  updateSelectedGrade(){

  }
  @action
  updateSelectedCompany(company){
    this.selectedCompany = company;
    console.log(this.selectedCompany)
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
  trackEbayClick(itemId) {
    const encodedId = encodeURIComponent(itemId);
    let url = `/ebay/adclick/${encodedId}`;
    ajax(url).then((result) => { 

    }).catch((error) => {
      console.error('Click not recorded:', error);
    });
  }

  trackEbayImpression(itemId) {
    this.impressionList.push(itemId);
  
    if (this.flushTimer) {
      clearTimeout(this.flushTimer);
    }

    if (this.impressionList.length >= 20) {
      this.flushImpressions()
    } else{
      this.flushTimer = setTimeout(() => {
        this.flushImpressions();
      }, this.flushInterval);
    }
  
  }

  flushImpressions() {
    console.log(this.impressionList.length, this.impressionList)
    if (this.impressionList.length > 0) {

      const encodedItemsList = Array.from(this.impressionList).map(item =>
        encodeURIComponent(item)
      );

      const encodedItems = encodedItemsList.join('&');
      const url = `/ebay/adimpression/${encodedItems}`;
      this.impressionList.clear();

      ajax(url).then((result) => {
      }).catch((error) => {

        console.error('Failed to send impressions:', error);
      });
  
    }

    this.flushTimer = null;
  }

  @action
  onScrollToEnd() {
    this.loadEbayListings(false);
  }

  setupScrollObserver() {
    let options = { root: null, rootMargin: '0px', threshold: 1.0 };

    this.observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !this.isLoading) {
        this.onScrollToEnd();
      }
    }, options);

    const sentinel = document.querySelector('.ebay-search-scroll-sentinel');
    if (!sentinel) {
      console.error('Sentinel element not found.');
    } else {
      this.observer.observe(sentinel);
    }
  }

  setupImpressionObserver(itemId) {
    let options = { root: null, rootMargin: '0px', threshold: 1.0 };

    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        this.trackEbayImpression(itemId);
        observer.disconnect();
      }
    }, options);

    const impression = document.getElementById(`impression-observer-${itemId}`);
    if (!impression) {
      console.error(`#impression-observer-${itemId} not found.`);
    } else {
      observer.observe(impression);
    }
  }



}
