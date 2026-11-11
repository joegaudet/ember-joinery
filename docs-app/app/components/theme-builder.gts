import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { htmlSafe } from '@ember/template'
import { waitForPromise } from '@ember/test-waiters'
import { modifier } from 'ember-modifier'
import { Button, Input, Label, NativeSelect, Switch } from '@ember-joinery/ember'
import type { ComponentLike } from '@glint/template'
import { baseColors } from 'virtual:joinery-themes'
import {
  BASE_COLORS,
  DEFAULT_THEME,
  RADII,
  STYLES,
  pageIsDark,
  stageTokens,
  titleOf,
} from '../preview.ts'
import {
  colorToHex,
  hexToOklch,
  isColor,
  loadDemoComponent,
  loadDemos,
  previewStyle,
  styleSheetFor,
  themeCss,
  tokenGroups,
  tokensFor,
  type Demo,
  type Edits,
  type Mode,
} from '../theme-builder.ts'

/** Renders a demo once it nears the viewport, so the page doesn't start all seventy at once. */
const whenNear = modifier((element: Element, [show]: [() => void]) => {
  if (typeof IntersectionObserver === 'undefined') {
    show()
    return
  }
  const observer = new IntersectionObserver(
    entries => {
      if (entries.some(entry => entry.isIntersecting)) {
        observer.disconnect()
        show()
      }
    },
    { rootMargin: '600px 0px' },
  )
  observer.observe(element)
  return () => observer.disconnect()
})

interface DemoCardSignature {
  Args: { demo: Demo; style: string; dark: boolean; tokens: ReturnType<typeof htmlSafe> }
}

/** One component page's demo, in the theme being built, under a link to its page. */
class DemoCard extends Component<DemoCardSignature> {
  @tracked component: ComponentLike | undefined

  show = () => {
    void waitForPromise(
      loadDemoComponent(this.args.demo.example).then(component => {
        if (!this.isDestroying) this.component = component
      }),
    )
  }

  get href() {
    return `${import.meta.env.BASE_URL}${this.args.demo.page}`
  }

  /** As an example frame's: a new stage for a new style or scheme (see example.gts). */
  get themeKey(): string[] {
    return [`${this.args.style} ${this.args.dark}`]
  }

  <template>
    <section class="tb-demo" data-test-theme-demo={{@demo.example}}>
      <h3 class="tb-demo-title"><a href={{this.href}}>{{@demo.title}}</a></h3>
      {{#each this.themeKey key="@identity"}}
        <div
          class="example-preview guide-stage tb-demo-stage {{if @dark 'dark'}}"
          data-example={{@demo.example}}
          data-style={{@style}}
          dir={{@demo.dir}}
          style={{@tokens}}
          {{whenNear this.show}}
        >
          {{#if this.component}}
            <this.component />
          {{else}}
            <p class="example-loading">Loading {{@demo.title}}…</p>
          {{/if}}
        </div>
      {{/each}}
    </section>
  </template>
}

const eq = (a: unknown, b: unknown) => a === b

/**
 * The theme builder: pick one of the eight styles and a base colour, set the radius, edit any
 * token, light or dark, and see every component page's demo in the result; then copy the CSS.
 * Its own controls are Joinery's components, in Nova on the Neutral base colour.
 */
export class ThemeBuilder extends Component {
  @tracked styleName = DEFAULT_THEME.style
  @tracked baseColor = DEFAULT_THEME.baseColor
  @tracked radius = DEFAULT_THEME.radius
  @tracked mode: Mode = 'light'
  @tracked edits: Edits = { light: {}, dark: {} }
  @tracked demos: Demo[] = []
  @tracked copied = false

  styles = STYLES
  baseColorNames = BASE_COLORS
  radii = RADII
  titleOf = titleOf

  /** The panel's own look: Nova and Neutral, light or dark as the page is. */
  panelDark = pageIsDark()
  panelTokens = htmlSafe(stageTokens({ ...DEFAULT_THEME, dark: this.panelDark }))

  constructor(owner: unknown, args: object) {
    super(owner as never, args)
    void waitForPromise(
      loadDemos().then(demos => {
        if (!this.isDestroying) this.demos = demos
      }),
    )
  }

  get colors() {
    return baseColors[this.baseColor] ?? baseColors[DEFAULT_THEME.baseColor]!
  }

  get groups() {
    return tokenGroups(this.colors)
  }

  get dark(): boolean {
    return this.mode === 'dark'
  }

  /** The tokens of the mode being edited and shown. */
  get tokens(): Record<string, string> {
    return tokensFor(this.colors, this.edits, this.mode)
  }

  get previewTokens() {
    return htmlSafe(previewStyle(this.tokens, this.radius))
  }

  get css(): string {
    return themeCss({
      style: this.styleName,
      baseColor: this.baseColor,
      radius: this.radius,
      light: tokensFor(this.colors, this.edits, 'light'),
      dark: tokensFor(this.colors, this.edits, 'dark'),
    })
  }

  get styleSheet(): string {
    return styleSheetFor(this.styleName)
  }

  get editCount(): number {
    return Object.keys(this.edits.light).length + Object.keys(this.edits.dark).length
  }

  /** What the token's field shows: the edit typed, or the value in effect. */
  valueOf = (token: string) => this.edits[this.mode][token] ?? this.tokens[token] ?? ''
  isInvalid = (token: string) => {
    const edit = this.edits[this.mode][token]
    return edit !== undefined && !isColor(edit)
  }
  hexOf = (token: string) => colorToHex(this.tokens[token] ?? '')
  inputId = (token: string) => `theme-token${token}`
  isEdited = (token: string) => token in this.edits[this.mode]
  radiusLabel = (value: number) =>
    value === DEFAULT_THEME.radius ? `${value} (default)` : `${value}`

  setStyle = (value: string) => (this.styleName = value)
  setBaseColor = (value: string) => (this.baseColor = value)
  setRadius = (value: string) => (this.radius = Number(value))
  setDark = (dark: boolean) => (this.mode = dark ? 'dark' : 'light')

  setToken = (token: string, value: string) => {
    this.edits = { ...this.edits, [this.mode]: { ...this.edits[this.mode], [token]: value } }
  }

  pickColor = (token: string, event: Event) => {
    this.setToken(token, hexToOklch((event.target as HTMLInputElement).value))
  }

  resetToken = (token: string) => {
    const { [token]: _removed, ...rest } = this.edits[this.mode]
    this.edits = { ...this.edits, [this.mode]: rest }
  }

  reset = () => {
    this.edits = { light: {}, dark: {} }
  }

  copy = async () => {
    await navigator.clipboard?.writeText(this.css)
    if (this.isDestroying) return
    this.copied = true
    setTimeout(() => {
      if (!this.isDestroying) this.copied = false
    }, 1500)
  }

  <template>
    <div class="theme-builder" data-test-theme-builder>
      <div
        class="tb-panel guide-stage {{if this.panelDark 'dark'}}"
        data-style="nova"
        style={{this.panelTokens}}
      >
        <div class="tb-pickers">
          <div class="tb-field">
            <Label for="theme-style">Style</Label>
            <NativeSelect
              id="theme-style"
              @name="style"
              @value={{this.styleName}}
              @onValueChange={{this.setStyle}}
              as |s|
            >
              {{#each this.styles as |name|}}
                <s.Option @value={{name}}>{{this.titleOf name}}</s.Option>
              {{/each}}
            </NativeSelect>
          </div>
          <div class="tb-field">
            <Label for="theme-base-color">Base colour</Label>
            <NativeSelect
              id="theme-base-color"
              @name="base-color"
              @value={{this.baseColor}}
              @onValueChange={{this.setBaseColor}}
              as |s|
            >
              {{#each this.baseColorNames as |name|}}
                <s.Option @value={{name}}>{{this.titleOf name}}</s.Option>
              {{/each}}
            </NativeSelect>
          </div>
          <div class="tb-field">
            <Label for="theme-radius">Radius (rem)</Label>
            <NativeSelect
              id="theme-radius"
              @name="radius"
              @value={{String this.radius}}
              @onValueChange={{this.setRadius}}
              as |s|
            >
              {{#each this.radii as |value|}}
                <s.Option @value={{String value}}>{{this.radiusLabel value}}</s.Option>
              {{/each}}
            </NativeSelect>
          </div>
          <div class="tb-field tb-switch">
            <Switch
              id="theme-dark"
              @name="dark"
              @checked={{this.dark}}
              @onCheckedChange={{this.setDark}}
            />
            <Label for="theme-dark">Dark</Label>
          </div>
        </div>

        <div class="tb-tokens" role="group" aria-label="{{if this.dark 'Dark' 'Light'}} tokens">
          <p class="tb-hint">
            The
            {{if this.dark "dark" "light"}}
            tokens: type any CSS colour, or pick one. Turn on Dark to edit the dark ones.
          </p>
          {{#each this.groups as |group|}}
            <fieldset class="tb-group">
              <legend>{{group.title}}</legend>
              {{#each group.tokens as |token|}}
                <div class="tb-token" data-test-theme-token={{token}}>
                  <input
                    type="color"
                    class="tb-swatch"
                    aria-label="Pick {{token}}"
                    value={{this.hexOf token}}
                    {{on "input" (fn this.pickColor token)}}
                  />
                  <Label for={{this.inputId token}}><code>{{token}}</code></Label>
                  <Input
                    id={{this.inputId token}}
                    @name={{token}}
                    @value={{this.valueOf token}}
                    @onValueChange={{fn this.setToken token}}
                    aria-invalid={{if (this.isInvalid token) "true"}}
                    spellcheck="false"
                    autocomplete="off"
                  />
                  {{#if (this.isEdited token)}}
                    <Button
                      @variant="ghost"
                      @size="xs"
                      @name="reset-token"
                      aria-label="Reset {{token}}"
                      {{on "click" (fn this.resetToken token)}}
                    >Reset</Button>
                  {{/if}}
                </div>
              {{/each}}
            </fieldset>
          {{/each}}
        </div>

        <div class="tb-actions">
          <Button @name="copy-css" {{on "click" this.copy}}>{{if
              this.copied
              "Copied"
              "Copy CSS"
            }}</Button>
          <Button
            @variant="outline"
            @name="reset"
            disabled={{eq this.editCount 0}}
            {{on "click" this.reset}}
          >Reset tokens</Button>
          <span class="tb-copied" role="status">{{if this.copied "Copied the CSS"}}</span>
        </div>
      </div>

      <div class="tb-main">
        <div class="tb-css">
          <p class="tb-css-title">
            Your theme: import
            <code>@ember-joinery/ember/{{this.styleSheet}}</code>
            and this CSS, in place of
            <code>tokens.css</code>.
          </p>
          <pre data-test-theme-css tabindex="0" aria-label="Your theme's CSS"><code
            >{{this.css}}</code></pre>
        </div>

        <h2 class="tb-preview-title">Every component, in your theme</h2>
        <div class="tb-demos" data-test-theme-demos>
          {{#each this.demos key="example" as |demo|}}
            <DemoCard
              @demo={{demo}}
              @style={{this.styleName}}
              @dark={{this.dark}}
              @tokens={{this.previewTokens}}
            />
          {{else}}
            <p class="guide-loading" role="status">Loading the components…</p>
          {{/each}}
        </div>
      </div>
    </div>
  </template>
}
