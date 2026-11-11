import { blur, focus, settled } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressKey, type KeyModifiers } from './focus.ts'

/** A number from an attribute, or `undefined` when it's missing or isn't one. */
function numberOf(element: Element, name: string): number | undefined {
  const value = element.getAttribute(name)
  if (value === null || value.trim() === '') return undefined
  const number = Number(value)
  return Number.isFinite(number) ? number : undefined
}

/** Sends one pointer event, as a pointer does. */
function pointer(target: Element, type: string, clientX: number, clientY: number): void {
  target.dispatchEvent(
    new PointerEvent(type, {
      bubbles: true,
      cancelable: true,
      composed: true,
      pointerId: 1,
      pointerType: 'mouse',
      isPrimary: true,
      button: 0,
      buttons: type === 'pointerup' ? 0 : 1,
      clientX,
      clientY,
    }),
  )
}

/**
 * Drives a `<Slider>` from `@ember-joinery/ember`, or the primitives' `Slider`. Each thumb is a
 * `role="slider"`, read through its ARIA; the keys and the pointer move them as a user does.
 *
 *   const volume = new SliderHarness('volume') // <Slider @name="volume">
 *   await volume.focus()
 *   await volume.press('ArrowRight')
 *   assert.deepEqual(volume.value, [76])
 *   await volume.slideTo(25)                    // a press at 25% along the track
 */
export class SliderHarness extends Harness {
  static override component = 'slider'

  /** Each thumb's element (its `role="slider"`), in order. */
  get thumbs(): HTMLElement[] {
    return this.parts('thumb')
  }

  /** The thumb that moves the value at `index` (default 0). Throws when there is none. */
  thumb(index = 0): HTMLElement {
    return this.part('thumb', String(index))
  }

  /**
   * Its value, as Radix's: each thumb's (`aria-valuenow`), in order. A one-thumb slider's is
   * `value[0]`.
   */
  get value(): number[] {
    return this.thumbs
      .map(thumb => numberOf(thumb, 'aria-valuenow'))
      .filter((value): value is number => value !== undefined)
  }

  /** Its lowest value (`aria-valuemin`). */
  get min(): number | undefined {
    const [thumb] = this.thumbs
    return thumb ? numberOf(thumb, 'aria-valuemin') : undefined
  }

  /** Its highest value (`aria-valuemax`). */
  get max(): number | undefined {
    const [thumb] = this.thumbs
    return thumb ? numberOf(thumb, 'aria-valuemax') : undefined
  }

  /** Each thumb's accessible name, in order. */
  get labels(): string[] {
    return this.thumbs.map(thumb => {
      const labelledBy = thumb.getAttribute('aria-labelledby')
      if (labelledBy) {
        return labelledBy
          .split(/\s+/)
          .map(id => thumb.ownerDocument.getElementById(id)?.textContent?.trim() ?? '')
          .join(' ')
      }
      return thumb.getAttribute('aria-label') ?? ''
    })
  }

  /** `horizontal` or `vertical`. */
  get orientation(): string | null {
    return this.element.getAttribute('data-orientation')
  }

  /** Whether it can't be moved: `data-disabled`, and its thumbs out of the tab order. */
  get isDisabled(): boolean {
    return this.element.hasAttribute('data-disabled')
  }

  /** The index of the thumb that has focus, or `null` when focus is elsewhere. */
  get focused(): number | null {
    const index = this.thumbs.indexOf(document.activeElement as HTMLElement)
    return index === -1 ? null : index
  }

  /** Focuses a thumb (default the first), as tabbing to it would. */
  async focus(index = 0): Promise<void> {
    await focus(this.thumb(index))
  }

  /** Moves focus away from it. */
  async blur(): Promise<void> {
    const index = this.focused
    if (index !== null) await blur(this.thumb(index))
  }

  /**
   * Presses a key on the focused thumb: `ArrowRight`, `PageUp`, `Home`… Focus a thumb first
   * (`focus()`), or give its index here.
   */
  async press(key: string, modifiers?: KeyModifiers & { thumb?: number }): Promise<void> {
    if (modifiers?.thumb !== undefined) await this.focus(modifiers.thumb)
    else if (this.focused === null) await this.focus()
    await pressKey(key, modifiers)
  }

  /**
   * Where along the slider a share of its length is, from where its values start: the left
   * (the right, right to left) or the bottom. For an inverted slider, that is the far end.
   */
  pointAt(percent: number): { clientX: number; clientY: number } {
    const element = this.element
    const rect = element.getBoundingClientRect()
    const share = percent / 100
    if (this.orientation === 'vertical') {
      return { clientX: rect.left + rect.width / 2, clientY: rect.bottom - rect.height * share }
    }
    const rtl = getComputedStyle(element).direction === 'rtl'
    const clientX = rtl ? rect.right - rect.width * share : rect.left + rect.width * share
    return { clientX, clientY: rect.top + rect.height / 2 }
  }

  /**
   * Presses the slider at `percent` of its length (see `pointAt`) and lets go, as a click on
   * the track: the nearest thumb moves there.
   */
  async slideTo(percent: number): Promise<void> {
    const { clientX, clientY } = this.pointAt(percent)
    const target = this.element.querySelector('[data-test-jn-part="track"]') ?? this.element
    pointer(target, 'pointerdown', clientX, clientY)
    await settled()
    pointer(target, 'pointerup', clientX, clientY)
    await settled()
  }

  /** Drags a thumb (default the first) to `percent` of the slider's length, and lets go. */
  async drag(to: number, { thumb = 0, from }: { thumb?: number; from?: number } = {}) {
    const element = this.thumb(thumb)
    const box = element.getBoundingClientRect()
    const start =
      from === undefined
        ? { clientX: box.left + box.width / 2, clientY: box.top + box.height / 2 }
        : this.pointAt(from)
    pointer(element, 'pointerdown', start.clientX, start.clientY)
    await settled()
    const { clientX, clientY } = this.pointAt(to)
    pointer(element, 'pointermove', clientX, clientY)
    await settled()
    pointer(element, 'pointerup', clientX, clientY)
    await settled()
  }
}
