import Modifier from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'

/** An attribute's value in a part: `true` sets it empty, and `false`, `null` or `undefined` leave it off. */
export type AttributeValue = string | number | boolean | null | undefined

/** Event listeners by event name, as `{ click: …, keydown: … }`. */
export type PartListeners = {
  [K in keyof HTMLElementEventMap]?: (event: HTMLElementEventMap[K]) => void
}

/** What a part puts on its element. */
export interface PartSpec<E extends Element = HTMLElement> {
  /**
   * The part's attributes: its ARIA (`aria-expanded`, `aria-controls`), `role`, `id`,
   * `data-state`, `data-slot` and `data-test-jn-part`. They are kept up to date, and an
   * attribute the part stops setting goes back to what the element had.
   */
  attributes?: Readonly<Record<string, AttributeValue>>
  /** Classes to add, space separated. They go next to the element's own. */
  class?: string | null
  /**
   * Listeners. As in Radix, a listener is skipped when an earlier one for the same event (one
   * of the caller's own, on the same element) called `event.preventDefault()`.
   */
  on?: PartListeners
  /**
   * Called once, with the element, when the part is installed: to keep it for focus or
   * positioning. It may return a cleanup, called when the element goes. It runs during
   * rendering, so it must not change tracked state the template has read.
   */
  element?: (element: E) => void | (() => void)
}

/** The signature of a part's modifier: the element it goes on, and the arguments it takes. */
export interface PartSignature<
  E extends Element = HTMLElement,
  Named extends object = Record<string, never>,
  Positional extends unknown[] = [],
> {
  Element: E
  Args: { Named: Named; Positional: Positional }
}

/** A part's modifier, as `part()` makes it. */
export type PartModifier<
  E extends Element = HTMLElement,
  Named extends object = Record<string, never>,
  Positional extends unknown[] = [],
> = typeof Modifier<PartSignature<E, Named, Positional>>

function normalize(value: AttributeValue): string | null {
  if (value === true) return ''
  if (value === false || value === null || value === undefined) return null
  return String(value)
}

function classesOf(value: string | null | undefined): string[] {
  return value ? value.split(/\s+/).filter(Boolean) : []
}

/**
 * A modifier that turns any element into one of a component's parts: it sets the part's
 * attributes, adds its classes and listens for its events, and keeps them current. A component
 * yields one for each part that callers may want to render themselves, which is how
 * `<LinkTo {{d.trigger}}>` (or any element or component) becomes the trigger. The part's own
 * component uses the same modifier, so both render the same thing:
 *
 *   class Disclosure extends Component {
 *     open = controllable(this, 'open', false)
 *
 *     trigger = part(() => ({
 *       attributes: {
 *         'aria-expanded': String(this.open.value),
 *         'aria-controls': idFor(this, 'content'),
 *         'data-state': this.open.value ? 'open' : 'closed',
 *         'data-test-jn-part': 'trigger',
 *       },
 *       on: { click: () => this.open.set(open => !open) },
 *     }))
 *
 *     <template>
 *       {{yield (hash trigger=this.trigger Trigger=(component Trigger part=this.trigger))}}
 *     </template>
 *   }
 *
 *   // the Trigger part: the caller's attributes, then the part's
 *   <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
 *
 * The function runs again whenever tracked state it reads changes, and only what changed is
 * touched on the element. A part that takes arguments, such as an item's value, reads them from
 * the modifier's arguments: `part((named) => …)` for `<a {{m.item value="profile"}}>`.
 *
 * The part's attributes win over the element's own, except `class`, which adds to it; on
 * events, the caller's listeners run first when they come first (`...attributes` before the
 * part modifier), and can stop the part's by calling `preventDefault()`.
 */
export function part<
  E extends Element = HTMLElement,
  Named extends object = Record<string, never>,
  Positional extends unknown[] = [],
>(spec: (named: Named, positional: Positional) => PartSpec<E>): PartModifier<E, Named, Positional> {
  return class Part extends Modifier<PartSignature<E, Named, Positional>> {
    #element: E | undefined
    /** The attributes this part set, with what the element had before. */
    #originals = new Map<string, string | null>()
    /** The classes this part added (and the element didn't already have). */
    #classes = new Set<string>()
    #handlers = new Map<string, (event: Event) => void>()
    #listeners = new Map<string, (event: Event) => void>()
    #cleanup: (() => void) | undefined

    override modify(element: E, positional: Positional, named: Named): void {
      const next = spec(named, positional)
      const installing = this.#element === undefined
      if (installing) {
        this.#element = element
        registerDestructor(this, () => this.#teardown())
      }

      this.#applyAttributes(element, next.attributes ?? {})
      this.#applyClasses(element, classesOf(next.class))
      this.#applyListeners(element, next.on ?? {})

      if (installing && next.element) this.#cleanup = next.element(element) ?? undefined
    }

    #applyAttributes(element: E, attributes: Readonly<Record<string, AttributeValue>>): void {
      const wanted = new Map<string, string | null>()
      for (const [name, value] of Object.entries(attributes)) wanted.set(name, normalize(value))

      for (const [name, original] of this.#originals) {
        if (wanted.get(name) != null) continue
        restore(element, name, original)
        this.#originals.delete(name)
      }
      for (const [name, value] of wanted) {
        if (value === null) continue
        if (!this.#originals.has(name)) this.#originals.set(name, element.getAttribute(name))
        if (element.getAttribute(name) !== value) element.setAttribute(name, value)
      }
    }

    #applyClasses(element: E, classes: string[]): void {
      const wanted = new Set(classes)
      for (const name of this.#classes) {
        if (wanted.has(name)) continue
        element.classList.remove(name)
        this.#classes.delete(name)
      }
      for (const name of wanted) {
        if (this.#classes.has(name) || element.classList.contains(name)) continue
        element.classList.add(name)
        this.#classes.add(name)
      }
    }

    #applyListeners(element: E, on: PartListeners): void {
      const handlers = on as Record<string, ((event: Event) => void) | undefined>
      for (const [type, listener] of this.#listeners) {
        if (handlers[type]) continue
        element.removeEventListener(type, listener)
        this.#listeners.delete(type)
        this.#handlers.delete(type)
      }
      for (const [type, handler] of Object.entries(handlers)) {
        if (!handler) continue
        this.#handlers.set(type, handler)
        if (this.#listeners.has(type)) continue
        // One listener per event for the part's life; it calls whichever handler is current.
        const listener = (event: Event) => {
          if (event.defaultPrevented) return
          this.#handlers.get(type)?.(event)
        }
        this.#listeners.set(type, listener)
        element.addEventListener(type, listener)
      }
    }

    #teardown(): void {
      const element = this.#element
      if (!element) return
      this.#cleanup?.()
      for (const [type, listener] of this.#listeners) element.removeEventListener(type, listener)
      for (const [name, original] of this.#originals) restore(element, name, original)
      for (const name of this.#classes) element.classList.remove(name)
      this.#listeners.clear()
      this.#handlers.clear()
      this.#originals.clear()
      this.#classes.clear()
    }
  }
}

function restore(element: Element, name: string, original: string | null): void {
  if (original === null) element.removeAttribute(name)
  else element.setAttribute(name, original)
}
