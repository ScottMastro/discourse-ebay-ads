import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class EbayUserSettingsService extends Service {
  @tracked discourseId = null;
  @tracked ebayUsername = "";
  @tracked hideListings = false;
}
