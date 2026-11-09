import { click, settled } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { isInTopLayer, pressEscape, pressOutside } from './layers.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** The text of the elements an `aria-labelledby` or `aria-describedby` names, joined. */
function textOf(element: Element, attribute: string): string {
  const ids = element.getAttribute(attribute)
  if (!ids) return ''
  return ids
    .split(/\s+/)
    .map(id => element.ownerDocument.getElementById(id))
    .filter((found): found is HTMLElement => Boolean(found))
    .map(text)
    .join(' ')
}

/**
 * Drives a `<Dialog>` from `@ember-joinery/ember` (or the headless one from
 * `@ember-joinery/primitives/dialog`). It reads state through the trigger's `aria-expanded`
 * and the content's role and ARIA, follows the content into the top layer, and acts as a user
 * does: a click on the trigger, Escape, a press on the overlay.
 *
 *   class EditProfile extends DialogHarness {
 *     static named = 'edit-profile'
 *     @child(ButtonHarness, 'save') declare save: ButtonHarness
 *   }
 *
 *   const dialog = new EditProfile()
 *   await dialog.open()
 *   assert.strictEqual(dialog.label, 'Edit profile')
 *   await dialog.close()
 *   assert.dom(dialog.trigger).isFocused()
 */
export class DialogHarness extends Harness {
  static override component: string | readonly string[] = 'dialog'

  /** The trigger. Throws when the dialog has none (one you open yourself, with `@open`). */
  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** The content, or `null` while it is closed (it stays while it animates out). */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  /** The overlay behind a modal dialog's content, or `null`. */
  get overlay(): HTMLElement | null {
    return this.queryPart('overlay')
  }

  /** The title, or `null`. */
  get title(): HTMLElement | null {
    return this.queryPart('title')
  }

  /** The description, or `null`. */
  get description(): HTMLElement | null {
    return this.queryPart('description')
  }

  /** The close button in the corner (`@showCloseButton`), or `null`. */
  get closeButton(): HTMLElement | null {
    return this.queryPart('close-button')
  }

  /**
   * Whether it is open: the trigger's `aria-expanded`, or, without a trigger, the content's
   * `data-state`. It is `false` as soon as it starts closing, while the content animates out.
   */
  get isOpen(): boolean {
    const trigger = this.queryPart('trigger')
    if (trigger) return trigger.getAttribute('aria-expanded') === 'true'
    return this.content?.getAttribute('data-state') === 'open'
  }

  /** Whether it is modal: its content has `aria-modal="true"`. */
  get isModal(): boolean {
    return this.content?.getAttribute('aria-modal') === 'true'
  }

  /** The content's role: `dialog`, or `alertdialog`. */
  get role(): string | null {
    return this.content?.getAttribute('role') ?? null
  }

  /** Its accessible name: the content's `aria-label`, else the text its `aria-labelledby` names. */
  get label(): string {
    const content = this.content
    if (!content) return ''
    return content.getAttribute('aria-label')?.trim() || textOf(content, 'aria-labelledby')
  }

  /** Its accessible description: the text its content's `aria-describedby` names. */
  get descriptionText(): string {
    const content = this.content
    return content ? textOf(content, 'aria-describedby') : ''
  }

  /** Whether the content is in the browser's top layer. */
  get isInTopLayer(): boolean {
    return isInTopLayer(this.content)
  }

  /** Whether focus is inside the content. */
  get hasFocus(): boolean {
    const content = this.content
    return Boolean(content?.contains(content.ownerDocument.activeElement))
  }

  /** Opens it with a click on its trigger, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await click(this.trigger)
  }

  /** Closes it as a user would: with its close button, or else Escape. */
  async close(): Promise<void> {
    const button = this.closeButton
    if (button) await click(button)
    else await this.pressEscape()
  }

  /** Presses Escape inside it. */
  async pressEscape(): Promise<void> {
    const content = this.content
    const active = content?.ownerDocument.activeElement
    await pressEscape(active && content?.contains(active) ? active : (content ?? undefined))
  }

  /**
   * Presses outside the content: on the overlay of a modal dialog, else outside every layer.
   * On the overlay, the press goes as a browser sends it: `pointerdown` (which closes the
   * dialog), then the mouse events, with focus leaving for nothing (the overlay can't take it),
   * all before the dialog has finished closing and given focus back.
   */
  async pressOutside(): Promise<void> {
    const overlay = this.overlay
    if (!overlay) return pressOutside()
    const init = { bubbles: true, cancelable: true, button: 0, isPrimary: true }
    overlay.dispatchEvent(new PointerEvent('pointerdown', { ...init, pointerType: 'mouse' }))
    const target = overlay.isConnected ? overlay : overlay.ownerDocument.body
    target.dispatchEvent(new MouseEvent('mousedown', init))
    const active = overlay.ownerDocument.activeElement
    if (active instanceof HTMLElement && active !== overlay.ownerDocument.body) active.blur()
    target.dispatchEvent(new MouseEvent('mouseup', init))
    target.dispatchEvent(new MouseEvent('click', init))
    target.dispatchEvent(new PointerEvent('pointerup', { ...init, pointerType: 'mouse' }))
    await settled()
  }
}
