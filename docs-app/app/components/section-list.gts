import Component from '@glimmer/component'
import { docsManager } from 'kolay'
import type { Collection, Page } from 'kolay'
import { title } from '../titles.ts'

interface SectionListSignature {
  Element: HTMLUListElement
  Args: {
    /** The section's folder in docs-app/app/templates, e.g. `components`. */
    section: string
  }
}

function isCollection(node: Page | Collection): node is Collection {
  return 'pages' in node
}

/**
 * The pages in one section of the guide, A–Z, for its overview page. It reads Kolay's manifest,
 * so a page appears here as soon as it exists.
 */
export class SectionList extends Component<SectionListSignature> {
  get pages(): Page[] {
    const docs = docsManager(this)
    const [group] = docs.manifest.groups
    const root = group?.tree
    const section =
      root && isCollection(root)
        ? root.pages.find(node => isCollection(node) && node.name === this.args.section)
        : undefined
    if (!section || !isCollection(section)) return []
    return section.pages.filter(
      (node): node is Page => !isCollection(node) && node.name !== 'index',
    )
  }

  <template>
    {{#if this.pages.length}}
      <ul class="section-list" ...attributes>
        {{#each this.pages as |page|}}
          <li><a href={{page.path}}>{{title page.name}}</a></li>
        {{/each}}
      </ul>
    {{else}}
      <p class="section-list-empty">Nothing here yet.</p>
    {{/if}}
  </template>
}
