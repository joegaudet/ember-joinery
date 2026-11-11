/* global ParentNode -- a DOM type, which ESLint's browser globals don't list */
import { tracked } from '@glimmer/tracking'
import { assert } from '@ember/debug'
import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'

/**
 * The names of the targets `<PortalTargets>` renders, as ember-primitives' `PORTALS`. `@to`
 * also takes the short names: `<Portal @to="popover">`.
 */
export const PORTALS = Object.freeze({
  popover: 'joinery__portal-targets__popover',
  tooltip: 'joinery__portal-targets__tooltip',
  modal: 'joinery__portal-targets__modal',
})

/** A target `<PortalTargets>` renders, by its short name or its full one. */
export type PortalName = keyof typeof PORTALS | (typeof PORTALS)[keyof typeof PORTALS]

/** The targets `<PortalTarget @name>` registered, by name, in the order they rendered. */
class Registry {
  @tracked version = 0
  readonly targets = new Map<string, Set<Element>>()

  add(name: string, element: Element): void {
    let set = this.targets.get(name)
    if (!set) this.targets.set(name, (set = new Set()))
    set.add(element)
    this.version += 1
  }

  delete(name: string, element: Element): void {
    const set = this.targets.get(name)
    if (!set?.delete(element)) return
    if (!set.size) this.targets.delete(name)
    this.version += 1
  }

  /** The registered targets with that name. Reading it entangles with registrations. */
  named(name: string): Element[] {
    void this.version
    return [...(this.targets.get(name) ?? [])]
  }
}

const registry = new Registry()

function fullName(name: string): string {
  return name in PORTALS ? PORTALS[name as keyof typeof PORTALS] : name
}

/**
 * The target nearest to `origin` for a portal name, as ember-primitives' `findNearestTarget`:
 * from the origin's parent up to the document, the first ancestor holding a target. A target
 * is a `<PortalTarget @name>` registered under the name, or else, for the names `PORTALS`
 * lists, an element with that `data-portal-name`, and for any other name, an element matching
 * it as a selector.
 */
export function findNearestTarget(origin: Element, name: string): Element | undefined {
  const full = fullName(name)
  const registered = registry.named(full)
  const builtin = (Object.values(PORTALS) as string[]).includes(full)
  const selector = builtin ? `[data-portal-name="${full}"]` : full

  const within = (host: ParentNode): Element | undefined => {
    if (registered.length) return registered.find(element => host.contains(element))
    return host.querySelector(selector) ?? undefined
  }

  for (let host: ParentNode | null = origin.parentNode; host; host = host.parentNode) {
    const found = within(host)
    if (found) return found
  }

  assert(
    `Joinery: <Portal @to="${name}"> found no target. Render <PortalTargets /> (for ` +
      `${Object.keys(PORTALS).join(', ')}), a <PortalTarget @name="${name}" />, or an element ` +
      `matching it, above the portal.`,
    !builtin,
  )
  return undefined
}

const register = modifier((element: Element, [name]: [name: string]) => {
  assert('Joinery: <PortalTarget> needs a @name', name)
  // Registered once the render is over: the portals that look for it have rendered already.
  let registered = false
  queueMicrotask(() => {
    if (!element.isConnected) return
    registered = true
    registry.add(fullName(name), element)
  })
  return () => {
    if (registered) registry.delete(fullName(name), element)
  }
})

export interface PortalTargetsSignature {
  Element: null
}

/**
 * The three targets ember-primitives' `<PortalTargets>` renders, for popovers, tooltips and
 * modals, each an empty `<div data-portal-name>`. Put it once near the end of your application
 * template, and `<Portal @to="popover">` renders there. Joinery's own overlays use the top
 * layer and need no target.
 */
export const PortalTargets: TOC<PortalTargetsSignature> = <template>
  <div data-portal-name={{PORTALS.popover}}></div>
  <div data-portal-name={{PORTALS.tooltip}}></div>
  <div data-portal-name={{PORTALS.modal}}></div>
</template>

export interface PortalTargetSignature {
  Element: HTMLDivElement
  Args: {
    /** The name a `<Portal @to>` finds it by. */
    name: string
  }
}

/** A target of your own: `<PortalTarget @name="sidebar" />`, for `<Portal @to="sidebar">`. */
export const PortalTarget: TOC<PortalTargetSignature> = <template>
  <div {{register @name}} ...attributes></div>
</template>
