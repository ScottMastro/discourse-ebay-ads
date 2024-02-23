import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class AdminPluginsEbayController extends Controller {
  @tracked allSellers = [];
  @tracked ebaySeller = "";

  init(){
    super.init(...arguments);
    ajax("/ebay/seller/info")
    .then((result) => {
      this.allSellers = result.sellers;
    }).catch(popupAjaxError);
  }

  @action
  addSeller() {
    this._addSeller(this.ebaySeller, false);
  }
  
  @action
  blockSeller() {
    this._addSeller(this.ebaySeller, true);
  }

  _addSeller(ebay_username, blocked) {
    if (ebay_username !== "") {
      const encodedSeller = encodeURIComponent(ebay_username);
      ajax(`/ebay/seller/add/${encodedSeller}.json`)
        .then((result) => {
          if (result.status == "ok") {
            const index = this.allSellers.findIndex(seller => seller.ebay_username === ebay_username);
            if (index == -1) {

              const newSeller = {
                username: null,
                ebay_username: ebay_username,
                listings_count: 0,
                blocked: false
              };
  
              this.allSellers.unshift(newSeller);            
              this.notifyPropertyChange('allSellers');
            }
            
            if (blocked){
              this._blockSeller(ebay_username);
            }

          }
        }).catch(popupAjaxError);
    }
  }

  _blockSeller(ebay_username) {
    if (ebay_username != ""){
      const encodedUsername = encodeURIComponent(ebay_username);
      ajax(`/ebay/seller/block/${encodedUsername}.json`)
        .then((result) => {
          if(result.status == "ok"){
            this.allSellers.forEach(seller => {
              if (seller.ebay_username === ebay_username) {
                const index = this.allSellers.findIndex(seller => seller.ebay_username === ebay_username);
                if (index !== -1) {
                  let modifiedSeller = Object.assign({}, this.allSellers[index]);
                  modifiedSeller.blocked = true;
                  this.allSellers.splice(index, 1);
                  this.allSellers.splice(index, 0, modifiedSeller);
                  this.notifyPropertyChange('allSellers');
                }
              }
            });
          }
        }).catch(popupAjaxError);
      }
  }
  _unblockSeller(ebay_username) {
    if (ebay_username !== "") {
      const encodedUsername = encodeURIComponent(ebay_username);
      ajax(`/ebay/seller/unblock/${encodedUsername}.json`)
        .then((result) => {
          if (result.status == "ok") {
            const index = this.allSellers.findIndex(seller => seller.ebay_username === ebay_username);
            if (index !== -1) {
              let modifiedSeller = Object.assign({}, this.allSellers[index]);
              modifiedSeller.blocked = false;
              this.allSellers.splice(index, 1);
              this.allSellers.splice(index, 0, modifiedSeller);
              this.notifyPropertyChange('allSellers');
            }
          }
        }).catch(popupAjaxError);
    }
  }

  @action
  unblockSellerFromTable(ebay_username) {
    this._unblockSeller(ebay_username);
  }
  
  @action
  blockSellerFromTable(ebay_username) {
    this._blockSeller(ebay_username)
  }

  @action
  deleteSellerFromTable(ebay_username){
    const encodedUsername = encodeURIComponent(ebay_username);
    ajax(`/ebay/seller/remove/${encodedUsername}`)
    .then((result) => {
      if(result.status == "ok"){
        this.allSellers = this.allSellers.filter(seller => seller.ebay_username !== ebay_username);
      }
    }).catch(popupAjaxError);    
  }



  @action
  dumpListingsFromTable(ebay_username){
    const encodedSeller = encodeURIComponent(ebay_username);
    ajax(`/ebay/seller/dump/${encodedSeller}.json`)
      .then((result) => {
        if (result.status == "ok") {
          const index = this.allSellers.findIndex(seller => seller.ebay_username === ebay_username);
          if (index !== -1) {
            let modifiedSeller = Object.assign({}, this.allSellers[index]);
            modifiedSeller.listings_count = 0;
            this.allSellers.splice(index, 1);
            this.allSellers.splice(index, 0, modifiedSeller);
            this.notifyPropertyChange('allSellers');
          }
        }

      }).catch(popupAjaxError);
  }

  @action
  fetchListings(username){

    let encodedUser = encodeURIComponent(username);

    encodedUser = encodedUser.replace(/\./g, '%2E');
    ajax(`/ebay/user/update/${encodedUser}.json`)
      .then((result) => {
        console.log(result)
      
      }).catch(popupAjaxError);
  }
}