import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { htmlSafe } from '@ember/template'
import { waitForPromise } from '@ember/test-waiters'
import { loadExample, type LoadedExample } from '../examples/index.ts'
import { highlight } from '../highlight.ts'

type Tab = 'preview' | 'template' | 'test'

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
  }
}

/**
 * A live example, as on ui.shadcn.com's component pages: the rendered example, plus tabs with
 * its exact source and the harness test that covers it, each with a copy button.
 */
export class Example extends Component<ExampleSignature> {
  @tracked tab: Tab = 'preview'
  @tracked example: LoadedExample | undefined
  @tracked missing = false
  @tracked sourceHtml = ''
  @tracked testHtml = ''
  @tracked copied = false

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
    const [source, test] = await Promise.all([
      highlight(example.source),
      example.test ? highlight(example.test) : Promise.resolve(''),
    ])
    if (this.isDestroying) return
    // Shiki output for files in this repository: trusted.
    this.sourceHtml = source
    this.testHtml = test
    this.example = example
  }

  get id() {
    return `example-${this.args.name}`
  }

  get tabs(): Tab[] {
    return this.example?.test ? ['preview', 'template', 'test'] : ['preview', 'template']
  }

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

  copy = async () => {
    const text = this.tab === 'test' ? (this.example?.test ?? '') : (this.example?.source ?? '')
    await navigator.clipboard?.writeText(text)
    if (this.isDestroying) return
    this.copied = true
    setTimeout(() => {
      if (!this.isDestroying) this.copied = false
    }, 1500)
  }

  <template>
    <figure class="example" id={{this.id}} data-test-example={{@name}} ...attributes>
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
            <div
              class="example-preview guide-stage"
              data-align={{if @align @align "center"}}
              dir={{@dir}}
            >
              <this.example.component />
            </div>
          {{else}}
            <div class="example-code">
              <button type="button" class="example-copy" {{on "click" this.copy}}>
                {{if this.copied "Copied" "Copy"}}
              </button>
              <span class="example-copied" role="status">{{if this.copied "Copied"}}</span>
              {{#if (this.isTab "template")}}
                {{this.html this.sourceHtml}}
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
