import Component from '@glimmer/component'
import { service } from '@ember/service'
import { PageNav } from 'kolay/components'
import type RouterService from '@ember/routing/router-service'
import { title } from '../titles.ts'

const LOGO = `${import.meta.env.BASE_URL}logo.svg`
const SITE = 'https://joegaudet.com/ember-joinery/'

/** On phones the contents start collapsed, so the page isn't pushed below the fold. */
const WIDE = typeof matchMedia === 'function' && matchMedia('(min-width: 861px)').matches

/** The guide's chrome: header, contents and footer. The parity route renders without it. */
export default class ApplicationTemplate extends Component {
  @service declare router: RouterService

  get bare() {
    return this.router.currentRouteName === 'parity'
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

        <main class="guide-main">
          {{outlet}}
        </main>
      </div>

      <footer class="guide-footer">
        <p>
          Design, component APIs and examples ported from
          <a href="https://ui.shadcn.com/">shadcn/ui</a>
          (MIT). The headless layer covers
          <a href="https://github.com/universal-ember/ember-primitives">ember-primitives</a>
          (MIT).
        </p>
        <p>
          More open source from
          <a href="https://joegaudet.com/">Joe Gaudet</a>:
          <a href="https://joegaudet.com/ember-formwright/">Formwright</a>
          ·
          <a href="https://joegaudet.com/real-enums/">real-enums</a>
          ·
          <a href={{SITE}} aria-current="page">Joinery</a>
        </p>
      </footer>
    {{/if}}
  </template>
}
