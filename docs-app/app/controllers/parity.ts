import Controller from '@ember/controller'
import { tracked } from '@glimmer/tracking'
import { htmlSafe } from '@ember/template'
import { DEFAULT_THEME, stageTokens } from '../preview.ts'

/** The parity route's query parameters; see routes/parity.ts. */
export default class ParityController extends Controller {
  queryParams = ['theme', 'dir', 'align', 'style', 'base']

  @tracked theme: 'light' | 'dark' = 'light'
  @tracked dir: 'ltr' | 'rtl' = 'ltr'
  @tracked align: 'center' | 'start' | 'end' = 'center'
  @tracked style = DEFAULT_THEME.style
  @tracked base = DEFAULT_THEME.baseColor

  /** The stage's tokens: the base colour, light or dark, and the default radius. */
  get tokens() {
    return htmlSafe(
      stageTokens({
        ...DEFAULT_THEME,
        style: this.style,
        baseColor: this.base,
        dark: this.theme === 'dark',
      }),
    )
  }
}
