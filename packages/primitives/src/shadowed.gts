import Component from '@glimmer/component'
import type Owner from '@ember/owner'
import { modifier } from 'ember-modifier'

export interface ShadowedSignature {
  Args: {
    /**
     * Bring the page's style sheets in: a copy of each `<style>` and `<link rel="stylesheet">`
     * in the document's `<head>`, and its adopted style sheets. Default `false`: the content
     * starts from the browser's own styles, untouched by the app's.
     */
    includeStyles?: boolean
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The content to render in the shadow root. */
    default: []
  }
  /**
   * The outer `<div>`, which has the attributes. The shadow root's host is the `<div>` inside
   * it, and the content is in a `<div>` in the shadow root.
   */
  Element: HTMLDivElement
}

/**
 * Renders its content in a shadow root, as ember-primitives' `Shadowed`, so the app's styles
 * don't reach it: for content that must look as it would on a page of its own, such as an
 * email preview or a third-party widget. The content is still the component's (its state,
 * actions and destruction); only the styles stop at the shadow boundary.
 *
 *   <Shadowed>
 *     <p class="card">Not styled by the app's .card</p>
 *   </Shadowed>
 *
 * The shadow root is open, so a test can reach it (`ShadowedHarness`). Ember can't render
 * straight into a shadow root on every version Joinery supports, so, as in ember-primitives,
 * the host is a `<div>` inside the outer one, and the content renders in a `<div>` inside the
 * shadow root. Harnesses don't look into shadow roots: drive what's inside through
 * `ShadowedHarness`.
 */
export class Shadowed extends Component<ShadowedSignature> {
  /** The shadow root's host, rendered in the outer `<div>`. */
  readonly host: HTMLDivElement
  /** The shadow root. */
  readonly shadowRoot: ShadowRoot
  /** Where the content renders, inside the shadow root. */
  readonly target: HTMLDivElement

  constructor(owner: Owner, args: ShadowedSignature['Args']) {
    super(owner, args)
    this.host = document.createElement('div')
    this.shadowRoot = this.host.attachShadow({ mode: 'open' })
    this.target = document.createElement('div')
    this.shadowRoot.append(this.target)
  }

  /** A copy of each style sheet in the document's `<head>`, in order. */
  copyStyles = (): Node[] => {
    const document = this.host.ownerDocument
    return [...document.head.querySelectorAll('style, link[rel~="stylesheet"]')].map(sheet =>
      sheet.cloneNode(true),
    )
  }

  /**
   * With `@includeStyles`, the document's adopted style sheets too, ahead of the root's own.
   * When `@includeStyles` turns off, or the component goes, it takes out the ones it added
   * (and leaves the root's own, such as a layout primitive's rules, where they are).
   */
  adoptSheets = modifier((element: HTMLElement, [include]: [boolean | undefined]) => {
    if (!include) return
    const root = this.shadowRoot
    const added = (element.ownerDocument.adoptedStyleSheets ?? []).filter(
      sheet => !root.adoptedStyleSheets.includes(sheet),
    )
    if (!added.length) return
    try {
      root.adoptedStyleSheets = [...added, ...root.adoptedStyleSheets]
    } catch {
      // A sheet made in another window (an iframe) can't be adopted here; the copies remain.
      return
    }
    return () => {
      root.adoptedStyleSheets = root.adoptedStyleSheets.filter(sheet => !added.includes(sheet))
    }
  })

  <template>
    <div
      data-test-jn="shadowed"
      data-test-jn-wrapper
      data-test-jn-name={{@name}}
      ...attributes
      {{this.adoptSheets @includeStyles}}
    >{{this.host}}</div>
    {{#in-element this.target insertBefore=null}}
      {{#if @includeStyles}}
        {{#each (this.copyStyles) as |sheet|}}{{sheet}}{{/each}}
      {{/if}}
      {{yield}}
    {{/in-element}}
  </template>
}
