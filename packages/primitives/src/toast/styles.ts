import Modifier from 'ember-modifier'
import type { ToastStyle } from './state.ts'

/** A style property's CSS name: custom properties as they are, `marginTop` as `margin-top`. */
function cssName(name: string): string {
  return name.startsWith('--') ? name : name.replace(/[A-Z]/g, upper => `-${upper.toLowerCase()}`)
}

interface StylesSignature {
  Element: HTMLElement
  Args: { Positional: [styles: ToastStyle | undefined] }
}

/**
 * Sets inline styles through the CSSOM, as React's `style` does, so a strict Content Security
 * Policy (one without `style-src 'unsafe-inline'`) doesn't block them as it would a `style`
 * attribute. It removes what an earlier run set and this one doesn't, and leaves alone what
 * others set (a toast's `--swipe-amount-x`).
 */
export class styles extends Modifier<StylesSignature> {
  #set = new Set<string>()

  override modify(element: HTMLElement, [styles]: [ToastStyle | undefined]): void {
    const next = new Set<string>()
    for (const [name, value] of Object.entries(styles ?? {})) {
      const property = cssName(name)
      element.style.setProperty(property, value)
      next.add(property)
    }
    for (const property of this.#set)
      if (!next.has(property)) element.style.removeProperty(property)
    this.#set = next
  }
}
