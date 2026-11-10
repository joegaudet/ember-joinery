import Controller from '@ember/controller'
import { tracked } from '@glimmer/tracking'

/** The settings dialog's section, in the URL: /settings?section=Appearance. */
export default class PreferencesController extends Controller {
  queryParams = ['section']

  @tracked section: string | null = null
}
