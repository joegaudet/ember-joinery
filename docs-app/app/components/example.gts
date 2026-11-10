import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { htmlSafe } from '@ember/template'
import { waitForPromise } from '@ember/test-waiters'
import { loadExample, type LoadedExample } from '../examples/index.ts'
import { highlight } from '../highlight.ts'
import {
  BASE_COLORS,
  DEFAULT_THEME,
  RADII,
  STYLES,
  WIDTHS,
  pageIsDark,
  stageTokens,
  titleOf,
} from '../preview.ts'
import PreviewFrame from './preview-frame.gts'

type Tab = 'preview' | 'template' | 'test'

const eqDir = (dir: string | undefined, value: string) => dir === value

interface ExampleSignature {
  Element: HTMLElement
  Args: {
    /** The file name in docs-app/app/examples, without `.gts`. */
    name: string
    title?: string
    /** Where the preview places the example, as upstream's `align`. Centred by default. */
    align?: 'center' | 'start' | 'end'
    /**
     * The preview's text direction, as upstream's `direction`: `rtl` for its right-to-left
     * (`*-rtl`) examples. It sets `dir` on the preview, as the parity route's `?dir=rtl` does,
     * and Joinery's components take their direction from the nearest `dir`. Without it, the
     * preview follows the page.
     */
    dir?: 'ltr' | 'rtl'
    /**
     * Stretches the example across the preview, for one upstream shows full width: the chart
     * demo (its preview's `[&_.preview>div]:w-full`) and the charts gallery's interactive
     * charts. Centred in the preview, an example with no width of its own shrinks to fit its
     * content. The parity map's `fullWidth` does the same on both parity stages.
     */
    fullWidth?: boolean
    /**
     * Upstream's `previewClassName`, as its docs page gives it: Tailwind classes on the preview
     * itself, such as its height (`h-96`, for a menu that opens below the example).
     * examples.css compiles the ones the pages use (its `@source inline()`), and the guide's
     * unit tests check each against upstream/inventory.json. The parity stages leave them out,
     * so the screenshots compare the examples themselves (parity/README.md).
     */
    previewClass?: string
    /**
     * `visible` where upstream's frame doesn't clip the preview (its
     * `className="overflow-visible"`): a part that hangs below the example without being in the
     * top layer, as a navigation menu's viewport does, shows in full, over what follows the
     * frame, instead of being cut off at its edge.
     */
    overflow?: 'visible'
  }
}

/**
 * A live example, as on ui.shadcn.com's component pages: the rendered example, plus tabs with
 * its exact source and the harness test that covers it, each with a copy button. Above the
 * preview, switchers show the example in any of the eight styles, base colours and radii, light
 * or dark, right to left, and at a phone's, a tablet's or a laptop's width. They change this
 * preview only.
 */
export class Example extends Component<ExampleSignature> {
  @tracked tab: Tab = 'preview'
  @tracked example: LoadedExample | undefined
  @tracked missing = false
  @tracked sourceHtml = ''
  @tracked filesHtml: { path: string; html: string }[] = []
  @tracked testHtml = ''
  @tracked copied = false

  @tracked styleName = DEFAULT_THEME.style
  @tracked baseColor = DEFAULT_THEME.baseColor
  @tracked radius = DEFAULT_THEME.radius
  @tracked dark = pageIsDark()
  @tracked rtl = this.args.dir === 'rtl'
  /** The preview's viewport width, or `undefined` to fit the frame. */
  @tracked width: number | undefined

  styles = STYLES
  baseColors = BASE_COLORS
  radii = RADII
  widths = WIDTHS
  titleOf = titleOf

  constructor(owner: unknown, args: ExampleSignature['Args']) {
    super(owner as never, args)
    void waitForPromise(this.load())
  }

  async load() {
    const example = await loadExample(this.args.name)
    if (this.isDestroying) return
    if (!example) {
      this.missing = true
      return
    }
    const [source, test, ...files] = await Promise.all([
      highlight(example.source),
      example.test ? highlight(example.test) : Promise.resolve(''),
      ...example.files.map(file => highlight(file.source)),
    ])
    if (this.isDestroying) return
    // Shiki output for files in this repository: trusted.
    this.sourceHtml = source
    this.filesHtml = example.files.map((file, index) => ({ path: file.path, html: files[index]! }))
    this.testHtml = test
    this.example = example
  }

  get id() {
    return `example-${this.args.name}`
  }

  get tabs(): Tab[] {
    return this.example?.test ? ['preview', 'template', 'test'] : ['preview', 'template']
  }

  /** The preview's direction: the RTL switch's, or the page's while it hasn't been used. */
  get dir(): 'ltr' | 'rtl' | undefined {
    if (this.rtl) return 'rtl'
    return this.args.dir === 'rtl' ? 'ltr' : this.args.dir
  }

  get tokens() {
    return htmlSafe(
      stageTokens({
        style: this.styleName,
        baseColor: this.baseColor,
        radius: this.radius,
        dark: this.dark,
      }),
    )
  }

  /**
   * The theme, as a one-item list the preview is keyed on: a new theme renders a new stage.
   * Browsers don't restyle what's inside an `@scope` root when the attribute that makes it one
   * changes, and the components' transitions would animate the change; a new stage has neither
   * problem.
   */
  get themeKey(): string[] {
    return [`${this.styleName} ${this.baseColor} ${this.radius} ${this.dark}`]
  }

  get frameTitle(): string {
    return `${this.args.title ?? this.args.name}, ${this.width}px wide`
  }

  isStyle = (name: string) => name === this.styleName
  isBaseColor = (name: string) => name === this.baseColor
  isRadius = (value: number) => value === this.radius
  isWidth = (value: number | undefined) => value === this.width
  radiusLabel = (value: number) =>
    value === DEFAULT_THEME.radius ? `${value} (default)` : `${value}`

  pickStyle = (event: Event) => (this.styleName = (event.target as HTMLSelectElement).value)
  pickBaseColor = (event: Event) => (this.baseColor = (event.target as HTMLSelectElement).value)
  pickRadius = (event: Event) => (this.radius = Number((event.target as HTMLSelectElement).value))
  toggleDark = () => (this.dark = !this.dark)
  toggleRtl = () => (this.rtl = this.dir !== 'rtl')
  pickWidth = (value: number | undefined) => (this.width = value)

  label = (tab: Tab) => ({ preview: 'Preview', template: 'Template', test: 'Test' })[tab]
  tabId = (tab: Tab) => `${this.id}-tab-${tab}`
  isTab = (tab: Tab) => this.tab === tab
  html = (markup: string) => htmlSafe(markup)

  select = (tab: Tab) => {
    this.tab = tab
    this.copied = false
  }

  /** The WAI-ARIA tabs pattern: arrow keys, Home and End move between tabs and select them. */
  onTabKeydown = (event: KeyboardEvent) => {
    const tabs = this.tabs
    const index = tabs.indexOf(this.tab)
    const rtl = getComputedStyle(event.currentTarget as Element).direction === 'rtl'
    const next = { ArrowRight: rtl ? -1 : 1, ArrowLeft: rtl ? 1 : -1 }[event.key]
    let target: Tab | undefined
    if (next) target = tabs[(index + next + tabs.length) % tabs.length]
    else if (event.key === 'Home') target = tabs[0]
    else if (event.key === 'End') target = tabs[tabs.length - 1]
    if (!target) return
    event.preventDefault()
    this.select(target)
    const list = (event.currentTarget as HTMLElement).closest('[role="tablist"]')
    list?.querySelector<HTMLElement>(`#${CSS.escape(this.tabId(target))}`)?.focus()
  }

  /** The Template tab's text: the example, then each file it imports, under its path. */
  get templateText(): string {
    const example = this.example
    if (!example) return ''
    return [example.source, ...example.files.map(file => `// ${file.path}\n\n${file.source}`)].join(
      '\n',
    )
  }

  copy = async () => {
    const text = this.tab === 'test' ? (this.example?.test ?? '') : this.templateText
    await navigator.clipboard?.writeText(text)
    if (this.isDestroying) return
    this.copied = true
    setTimeout(() => {
      if (!this.isDestroying) this.copied = false
    }, 1500)
  }

  <template>
    <figure
      class="example"
      id={{this.id}}
      data-test-example={{@name}}
      data-overflow={{@overflow}}
      ...attributes
    >
      <figcaption class="example-bar">
        <span class="example-title">{{if @title @title @name}}</span>
        <div class="example-tabs" role="tablist" aria-label="Example views">
          {{#each this.tabs as |tab|}}
            <button
              type="button"
              role="tab"
              id={{this.tabId tab}}
              aria-selected={{if (this.isTab tab) "true" "false"}}
              aria-controls="{{this.id}}-panel"
              tabindex={{if (this.isTab tab) "0" "-1"}}
              data-test-example-tab={{tab}}
              {{on "click" (fn this.select tab)}}
              {{on "keydown" this.onTabKeydown}}
            >{{this.label tab}}</button>
          {{/each}}
        </div>
      </figcaption>

      {{#if (this.isTab "preview")}}
        <div class="example-tools" data-test-example-tools>
          <label>
            <span>Style</span>
            <select data-test-example-style {{on "change" this.pickStyle}}>
              {{#each this.styles as |name|}}
                <option value={{name}} selected={{this.isStyle name}}>{{this.titleOf name}}</option>
              {{/each}}
            </select>
          </label>
          <label>
            <span>Base colour</span>
            <select data-test-example-base-color {{on "change" this.pickBaseColor}}>
              {{#each this.baseColors as |name|}}
                <option value={{name}} selected={{this.isBaseColor name}}>{{this.titleOf
                    name
                  }}</option>
              {{/each}}
            </select>
          </label>
          <label>
            <span>Radius</span>
            <select data-test-example-radius {{on "change" this.pickRadius}}>
              {{#each this.radii as |value|}}
                <option value={{value}} selected={{this.isRadius value}}>{{this.radiusLabel
                    value
                  }}</option>
              {{/each}}
            </select>
          </label>
          <button
            type="button"
            aria-pressed={{if this.dark "true" "false"}}
            data-test-example-dark
            {{on "click" this.toggleDark}}
          >Dark</button>
          <button
            type="button"
            aria-pressed={{if (eqDir this.dir "rtl") "true" "false"}}
            data-test-example-rtl
            {{on "click" this.toggleRtl}}
          >RTL</button>
          <div class="example-widths" role="group" aria-label="Width">
            <button
              type="button"
              aria-pressed={{if (this.isWidth undefined) "true" "false"}}
              data-test-example-width="fit"
              {{on "click" (fn this.pickWidth undefined)}}
            >Fit</button>
            {{#each this.widths as |value|}}
              <button
                type="button"
                aria-pressed={{if (this.isWidth value) "true" "false"}}
                data-test-example-width={{value}}
                {{on "click" (fn this.pickWidth value)}}
              >{{value}}</button>
            {{/each}}
          </div>
        </div>
      {{/if}}

      <div
        id="{{this.id}}-panel"
        role="tabpanel"
        class="example-panel"
        aria-labelledby={{this.tabId this.tab}}
      >
        {{#if this.missing}}
          <p class="example-missing" role="alert">
            No example named “{{@name}}” in docs-app/app/examples.
          </p>
        {{else if this.example}}
          {{#if (this.isTab "preview")}}
            {{#if this.width}}
              <div class="example-viewport">
                <PreviewFrame @width={{this.width}} @title={{this.frameTitle}}>
                  {{#each this.themeKey key="@identity"}}
                    <div
                      class="example-preview guide-stage {{if this.dark 'dark'}} {{@previewClass}}"
                      data-example={{@name}}
                      data-align={{if @align @align "center"}}
                      data-full-width={{if @fullWidth "true"}}
                      data-style={{this.styleName}}
                      dir={{this.dir}}
                      style={{this.tokens}}
                    >
                      <this.example.component />
                    </div>
                  {{/each}}
                </PreviewFrame>
              </div>
            {{else}}
              {{#each this.themeKey key="@identity"}}
                <div
                  class="example-preview guide-stage {{if this.dark 'dark'}} {{@previewClass}}"
                  data-example={{@name}}
                  data-align={{if @align @align "center"}}
                  data-full-width={{if @fullWidth "true"}}
                  data-style={{this.styleName}}
                  dir={{this.dir}}
                  style={{this.tokens}}
                >
                  <this.example.component />
                </div>
              {{/each}}
            {{/if}}
          {{else}}
            <div class="example-code">
              <button type="button" class="example-copy" {{on "click" this.copy}}>
                {{if this.copied "Copied" "Copy"}}
              </button>
              <span class="example-copied" role="status">{{if this.copied "Copied"}}</span>
              {{#if (this.isTab "template")}}
                {{this.html this.sourceHtml}}
                {{#each this.filesHtml as |file|}}
                  <p class="example-file">{{file.path}}</p>
                  {{this.html file.html}}
                {{/each}}
              {{else}}
                {{this.html this.testHtml}}
              {{/if}}
            </div>
          {{/if}}
        {{else}}
          <p class="example-loading" role="status">Loading…</p>
        {{/if}}
      </div>
    </figure>
  </template>
}
