import Route from '@ember/routing/route'
import { service } from '@ember/service'
import { handlePotentialIndexVisit } from 'kolay'
import type RouterService from '@ember/routing/router-service'
import type Transition from '@ember/routing/transition'

/**
 * Pages that moved, from their old address to their new one. Kolay has no redirects, and
 * READMEs on npm and other guides still link to the old addresses.
 */
const MOVED: Record<string, string> = {
  'getting-started/accessibility.md': 'accessibility/index.md',
  'getting-started/i18n.md': 'internationalization/index.md',
  'getting-started/rtl.md': 'internationalization/rtl.md',
}

export default class PageRoute extends Route {
  @service declare router: RouterService

  beforeModel(transition: Transition) {
    const moved = MOVED[String(transition.to?.parent?.params?.page)]
    if (moved) {
      this.router.replaceWith(`/${moved}`)
      return
    }
    handlePotentialIndexVisit(this, transition)
  }
}
