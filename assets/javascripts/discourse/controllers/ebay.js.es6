import Controller from '@ember/controller';
import { ajax } from 'discourse/lib/ajax';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { scheduleOnce } from '@ember/runloop';

export default class extends Controller {
  @tracked ebayListings = [];
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
    this.loadEbayListings(true);
    scheduleOnce('afterRender', this, this.setupObserver); 
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
      console.log(this.ebayListings);
      this.offset += this.limit;
      this.isLoading = false;
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
    });;
  }

  @action
  onScrollToEnd() {
    this.loadEbayListings(false);
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

    const sentinel = document.querySelector('.sentinel');
    if (!sentinel) {
      console.error('Sentinel element not found.');
    } else {
      this.observer.observe(sentinel);
    }
  }

}
