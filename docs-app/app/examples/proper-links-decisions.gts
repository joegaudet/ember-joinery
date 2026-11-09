import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { modifier } from 'ember-modifier'
import { shouldHandle } from '@ember-joinery/primitives/proper-links'

const links = [
  // Relative to this page, so they stay under the guide's rootURL.
  { label: 'A page in the app', href: 'store.md', attrs: '' },
  { label: 'A heading on this page', href: '#usage', attrs: '' },
  { label: 'In a new tab', href: 'store.md', attrs: 'target' },
  { label: 'A download', href: 'store.md', attrs: 'download' },
  { label: 'Another site', href: 'https://developer.mozilla.org', attrs: '' },
] as const

const eq = (a: string, b: string) => a === b

/** A plain left click, as properLinks sees one. */
const plainClick = () => new MouseEvent('click', { button: 0 })

/**
 * Who follows each kind of link once the router has `properLinks`: the router (a transition)
 * or the browser (a page load, a new tab, a download). `shouldHandle` decides.
 */
class Decision extends Component<{ Args: { label: string; href: string; attrs: string } }> {
  @tracked byRouter: boolean | undefined

  decide = modifier((anchor: HTMLAnchorElement) => {
    this.byRouter = shouldHandle(location.href, anchor, plainClick())
  })

  <template>
    <tr data-test-jn-part="link" data-test-jn-value={{@label}}>
      <th scope="row">
        <a
          href={{@href}}
          target={{if (eq @attrs "target") "_blank"}}
          download={{if (eq @attrs "download") ""}}
          {{this.decide}}
        >{{@label}}</a>
      </th>
      <td data-test-jn-part="decision">{{if this.byRouter "The router" "The browser"}}</td>
    </tr>
  </template>
}

<template>
  <table data-test-jn="link-decisions">
    <caption>Who follows each link</caption>
    <thead>
      <tr><th scope="col">Link</th><th scope="col">Followed by</th></tr>
    </thead>
    <tbody>
      {{#each links as |l|}}
        <Decision @label={{l.label}} @href={{l.href}} @attrs={{l.attrs}} />
      {{/each}}
    </tbody>
  </table>
</template>
