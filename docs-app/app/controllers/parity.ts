import Controller from '@ember/controller'
import { tracked } from '@glimmer/tracking'
import { htmlSafe } from '@ember/template'
import { DEFAULT_THEME, stageTokens } from '../preview.ts'

/** The parity route's query parameters; see routes/parity.ts. */
export default class ParityController extends Controller {
  queryParams = ['theme', 'dir', 'align', 'fullWidth', 'style', 'base']

  @tracked theme: 'light' | 'dark' = 'light'
  @tracked dir: 'ltr' | 'rtl' = 'ltr'
  @tracked align: 'center' | 'start' | 'end' = 'center'
  @tracked fullWidth = false
  @tracked style = DEFAULT_THEME.style
  @tracked base = DEFAULT_THEME.baseColor

  /**
   * The style, as a one-item list the stage is keyed on: a new style renders a new stage.
   * Browsers don't restyle what's inside an `@scope` root when the attribute that makes it one
   * (`data-style`) changes, so `?style=` changed in place would leave the old style's rules.
   */
  get stageKey(): string[] {
    return [this.style]
  }

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
