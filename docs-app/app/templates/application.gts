import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { service } from '@ember/service'
import { htmlSafe } from '@ember/template'
import { PageNav } from 'kolay/components'
import type RouterService from '@ember/routing/router-service'
import { Toaster } from '@ember-joinery/ember'
import { title } from '../titles.ts'

const LOGO = `${import.meta.env.BASE_URL}logo.svg`
const SITE = 'https://joegaudet.com/ember-joinery/'

/** On phones the contents start collapsed, so the page isn't pushed below the fold. */
const WIDE = typeof matchMedia === 'function' && matchMedia('(min-width: 861px)').matches

/** How a preview looks, as its frame's switchers set it: what the guide's Toaster takes on. */
interface PreviewLook {
  /** Its style (`data-style`). */
  style: string
  dark: boolean
  /** Its `dir`, when it sets one. */
  dir: string | undefined
  /** Its tokens: the base colour's and the radius, as its `style` attribute. */
  tokens: string
}

/** The look of the example preview an event happened in, or `undefined` outside one. */
function lookOf(target: EventTarget | null): PreviewLook | undefined {
  const preview = target instanceof Element ? target.closest('.example-preview') : null
  if (!(preview instanceof HTMLElement)) return undefined
  return {
    style: preview.dataset['style'] ?? 'nova',
    dark: preview.classList.contains('dark'),
    dir: preview.getAttribute('dir') ?? undefined,
    tokens: preview.getAttribute('style') ?? '',
  }
}

const keyOf = (look: PreviewLook | undefined) =>
  look ? `${look.style} ${look.dark} ${look.dir} ${look.tokens}` : 'page'

/** The guide's chrome: header, contents and footer. The parity route renders without it. */
export default class ApplicationTemplate extends Component {
  @service declare router: RouterService

  get bare() {
    return this.router.currentRouteName === 'parity'
  }

  /**
   * The look of the example preview last pressed or focused, which the examples' toasts take.
   * The guide renders one Toaster, as an app does, and the Sonner examples' toasts show there;
   * a press or focus in a preview comes before the toast its example makes, so the frame's
   * style, base colour, radius, dark and RTL switchers reach the toasts too.
   */
  @tracked look: PreviewLook | undefined

  followPreview = (event: Event): void => {
    const look = lookOf(event.target)
    if (!look || keyOf(look) === keyOf(this.look)) return
    // A microtask on: a focus can come while the page renders (a part focusing as it shows),
    // and still lands before the click or key that makes a toast.
    queueMicrotask(() => {
      if (!this.isDestroying) this.look = look
    })
  }

  /**
   * The look, as a one-item list the Toaster's stage is keyed on: as with a preview, a new style
   * renders a new stage, which the browser styles afresh (see example.gts's `themeKey`).
   */
  get lookKey(): string[] {
    return [keyOf(this.look)]
  }

  get lookTokens() {
    return htmlSafe(this.look?.tokens ?? '')
  }

  /** Until a preview is used, the Toaster follows the page (`.dark` on `<html>`). */
  get toastTheme(): 'light' | 'dark' | undefined {
    const look = this.look
    if (!look) return undefined
    return look.dark ? 'dark' : 'light'
  }

  <template>
    {{#if this.bare}}
      {{outlet}}
    {{else}}
      <header class="guide-header">
        <a class="guide-brand" href={{SITE}}>
          <img src={{LOGO}} alt="" width="26" height="26" />
          <strong>Joinery</strong>
          <span class="guide-tag">Guide</span>
        </a>
        <nav aria-label="Site">
          <a href={{SITE}}>Home</a>
          <a href="{{SITE}}demo/">Demo</a>
          <a href="https://github.com/joegaudet/ember-joinery">GitHub</a>
        </nav>
      </header>

      <div class="guide-layout">
        <details class="guide-sidebar" open={{WIDE}}>
          <summary>Contents</summary>
          <PageNav aria-label="Guide">
            <:page as |x|>
              <x.Link>{{title x.page.name}}</x.Link>
            </:page>
            <:collection as |x|>
              {{#if x.index}}
                <x.index.Link>{{title x.collection.name}}</x.index.Link>
              {{else}}
                {{title x.collection.name}}
              {{/if}}
            </:collection>
          </PageNav>
        </details>

        {{! Capturing, so the look is taken before the example's own handlers run. }}
        <main
          class="guide-main"
          {{on "pointerdown" this.followPreview capture=true}}
          {{on "focusin" this.followPreview capture=true}}
        >
          {{outlet}}
        </main>
      </div>

      <footer class="guide-footer">
        <p>
          Design, component APIs and examples ported from
          <a href="https://ui.shadcn.com/">shadcn/ui</a>
          (MIT). The headless layer covers
          <a href="https://github.com/universal-ember/ember-primitives">ember-primitives</a>
          (MIT). The toasts port
          <a href="https://github.com/emilkowalski/sonner">sonner</a>
          (MIT).
        </p>
        <p>
          More open source from
          <a href="https://joegaudet.com/">Joe Gaudet</a>:
          <a href="https://joegaudet.com/harnessed/">harnessed</a>
          ·
          <a href="https://joegaudet.com/ember-formwright/">Formwright</a>
          ·
          <a href="https://joegaudet.com/real-enums/">real-enums</a>
          ·
          <a href={{SITE}} aria-current="page">Joinery</a>
        </p>
      </footer>
    {{/if}}

    {{!
      The examples' toasts (Sonner's page), shown as on ui.shadcn.com, whose reference app
      renders its Toaster top-center. Its wrapper is a stage, as a preview is: the guide loads
      Joinery's styles only for the stages that pick one (joinery-css.mjs). It starts in Nova,
      following the page's colour scheme, and takes on the look of the preview last pressed or
      focused (its style, tokens, dark and direction), so the frame's switchers reach the
      toasts its example makes.
    }}
    {{#each this.lookKey key="@identity"}}
      <div
        class="guide-stage guide-toaster {{if this.look.dark 'dark'}}"
        data-style={{if this.look this.look.style "nova"}}
        dir={{this.look.dir}}
        style={{this.lookTokens}}
      >
        <Toaster @position="top-center" @theme={{this.toastTheme}} />
      </div>
    {{/each}}
  </template>
}
