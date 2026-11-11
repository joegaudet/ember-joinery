import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { assert } from '@ember/debug'
import { isDestroyed, isDestroying } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'
import { findNearestTarget, type PortalName } from './targets.gts'

const waiter = buildWaiter('@ember-joinery/primitives:portal')

/**
 * The element for an id or a selector, as ember-primitives' `wormhole` (ember-wormhole's
 * `destinationElementId`): `<Portal @to={{wormhole "sidebar"}}>`. An element is returned as is.
 */
export function wormhole(query: string | Element | null | undefined): Element | null {
  assert('Joinery: wormhole() needs an id, a selector or an element', query)
  if (query instanceof Element) return query
  return document.getElementById(query) ?? document.querySelector(query)
}

function isElement(value: unknown): value is Element {
  return value instanceof Element
}

/** `display: contents` through the CSSOM, which a strict Content Security Policy allows. */
const displayContents = modifier((element: HTMLElement) => {
  element.style.setProperty('display', 'contents')
})

interface ElementSignature {
  Args: { to: Element; append?: boolean }
  Blocks: { default: [] }
}

const ToElement: TOC<ElementSignature> = <template>
  {{#if @append}}
    {{#in-element @to insertBefore=null}}{{yield}}{{/in-element}}
  {{else}}
    {{#in-element @to}}{{yield}}{{/in-element}}
  {{/if}}
</template>

interface NamedSignature {
  Args: { to: string; append?: boolean }
  Blocks: { default: [] }
}

/** Finds the nearest target for a name from where the portal is rendered, then renders there. */
class ToNamed extends Component<NamedSignature> {
  /** Where the portal is, once rendered: targets are looked up from there. */
  @tracked origin: Element | undefined

  /** The target, found again when a `<PortalTarget>` comes or goes. */
  get target(): Element | undefined {
    return this.origin ? findNearestTarget(this.origin, this.args.to) : undefined
  }

  find = modifier((origin: Element) => {
    // Looked up once the render is over, as ember-primitives does: the target may be rendered
    // by the same render, after the portal.
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      waiter.endAsync(token)
      if (isDestroying(this) || isDestroyed(this)) return
      this.origin = origin
    })
  })

  <template>
    {{! Always empty: the content renders in the target. }}
    <div data-portal-origin {{displayContents}} {{this.find}}>
      {{#if this.target}}
        <ToElement @to={{this.target}} @append={{@append}}>{{yield}}</ToElement>
      {{/if}}
    </div>
  </template>
}

interface WormholeSignature {
  Args: { to: string | Element }
  Blocks: { default: [] }
}

/** ember-wormhole's behaviour: an id or selector, looked up again once the render is over. */
class ToWormhole extends Component<WormholeSignature> {
  @tracked found: Element | null | undefined

  get target(): Element | null | undefined {
    return this.found ?? wormhole(this.args.to)
  }

  /** Given what the render found: when that was nothing, look again once the render is over. */
  look = modifier((_element: Element, [rendered]: [Element | null | undefined]) => {
    if (rendered) return
    // The element may come later in the same render, as ember-wormhole allows.
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      waiter.endAsync(token)
      if (isDestroying(this) || isDestroyed(this)) return
      const found = wormhole(this.args.to)
      assert(`Joinery: <Portal @wormhole> found no element for \`${String(this.args.to)}\``, found)
      this.found = found
    })
  })

  <template>
    {{#let this.target as |target|}}
      <div data-portal-origin {{displayContents}} {{this.look target}}>
        {{#if target}}
          <ToElement @to={{target}} @append={{true}}>{{yield}}</ToElement>
        {{/if}}
      </div>
    {{/let}}
  </template>
}

function body(): Element {
  return document.body
}

export interface PortalSignature {
  Args: {
    /**
     * Where to render: a target's name (`popover`, `tooltip`, `modal`, a `<PortalTarget
     * @name>`, or a selector), found nearest to the portal, or an element. Without `@to` or
     * `@wormhole`, the content goes at the end of `<body>`, as Radix's Portal does.
     */
    to?: PortalName | (string & {}) | Element
    /**
     * Add to what the target holds, instead of replacing it. Default `false`, as in
     * ember-primitives. Rendering to `<body>` always appends.
     */
    append?: boolean
    /** ember-wormhole's way: an element's id, or a selector, or an element. Always appends. */
    wormhole?: string | Element
  }
  Blocks: {
    /** The content to render elsewhere. */
    default: []
  }
}

/**
 * Renders its content somewhere else in the document, as ember-primitives' and Radix's
 * `Portal` do: in a named target, an element, an id (`@wormhole`), or the end of `<body>`.
 * The content stays part of the component that renders it (its state, actions and
 * destruction), only its DOM moves.
 *
 *   <PortalTargets />                      {{! once, in the application template }}
 *
 *   <Portal @to="popover">…</Portal>       {{! renders in the popover target }}
 *   <Portal>…</Portal>                     {{! renders at the end of <body> }}
 *
 * Joinery's overlays don't need one: the top layer (`topLayer`) puts them above everything
 * without moving them. Use a portal where the DOM position matters, such as rendering into
 * another part of the page. A part rendered elsewhere carries `data-test-jn-owner`, so the
 * harnesses still find it.
 */
export const Portal: TOC<PortalSignature> = <template>
  {{#if (isElement @to)}}
    <ToElement @to={{@to}} @append={{@append}}>{{yield}}</ToElement>
  {{else if @wormhole}}
    <ToWormhole @to={{@wormhole}}>{{yield}}</ToWormhole>
  {{else if @to}}
    <ToNamed @to={{@to}} @append={{@append}}>{{yield}}</ToNamed>
  {{else}}
    <ToElement @to={{(body)}} @append={{true}}>{{yield}}</ToElement>
  {{/if}}
</template>
