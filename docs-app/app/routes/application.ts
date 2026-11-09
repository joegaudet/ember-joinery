import Route from '@ember/routing/route'
import { service } from '@ember/service'
import rehypeShikiFromHighlighter from '@shikijs/rehype/core'
import { setupKolay } from 'kolay/setup'
import type RouterService from '@ember/routing/router-service'
import type { Manifest } from 'kolay'
import { highlighter, THEMES } from '../highlight.ts'
import { routeLinks } from '../links.ts'
import { Example } from '../components/example.gts'
import { SectionList } from '../components/section-list.gts'

export default class ApplicationRoute extends Route {
  @service declare router: RouterService

  constructor(...args: ConstructorParameters<typeof Route>) {
    super(...args)
    routeLinks(this, this.router)
  }

  async model(): Promise<{ manifest: Manifest }> {
    const shiki = await highlighter()

    const manifest = await setupKolay(this, {
      // Usable in any page without an import.
      topLevelScope: { Example, SectionList },
      modules: {
        '@ember-joinery/ember': () => import('@ember-joinery/ember'),
        '@ember-joinery/primitives': () => import('@ember-joinery/primitives'),
        '@ember-joinery/test-support': () => import('@ember-joinery/test-support'),
      },
      rehypePlugins: [
        [rehypeShikiFromHighlighter, shiki, { themes: THEMES, defaultColor: 'light-dark()' }],
      ],
    })

    return { manifest }
  }
}
