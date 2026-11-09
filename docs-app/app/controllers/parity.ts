import Controller from '@ember/controller'
import { tracked } from '@glimmer/tracking'

/** The parity route's query parameters; see routes/parity.ts. */
export default class ParityController extends Controller {
  queryParams = ['theme', 'dir', 'align']

  @tracked theme: 'light' | 'dark' = 'light'
  @tracked dir: 'ltr' | 'rtl' = 'ltr'
  @tracked align: 'center' | 'start' | 'end' = 'center'
}
