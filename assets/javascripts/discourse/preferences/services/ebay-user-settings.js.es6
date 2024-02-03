import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class EbayUserSettingsService extends Service {
  @tracked ebayUsername = "";
  @tracked hideListings = false;
}
