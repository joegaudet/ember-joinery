import { click, focus, getContext, settled, triggerEvent, waitUntil } from '@ember/test-helpers'
import { Harness, type ChildOptions } from './harness.ts'
import type { TestHooks } from './test-hooks.ts'

function text(element: Element | null | undefined): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** A direction a toast can be swiped off in. */
export type ToastSwipe = 'left' | 'right' | 'up' | 'down'

export interface ToastSwipeOptions {
  /** How far the pointer moves, in pixels. Default 100 (sonner dismisses from 45). */
  distance?: number
  /**
   * How long the swipe takes, in milliseconds, before the pointer lifts. Default 0. A short,
   * slow swipe (under 45px, and slower than 0.11px per millisecond) springs back.
   */
  duration?: number
}

/**
 * Drives one toast in a `<Toaster>` (from `@ember-joinery/ember` or
 * `@ember-joinery/primitives/toast`): an `<li data-test-jn="toast">`, named by its id. State
 * comes from sonner's data attributes and the toast's text.
 *
 *   const toast = new ToasterHarness().toast() // the newest
 *   assert.strictEqual(toast.title, 'Event has been created')
 *   await toast.clickAction()
 *
 *   new ToastHarness('saved') // toast('Saved', { id: 'saved' })
 */
export class ToastHarness extends Harness {
  static override component = 'toast'

  /** Its id, as `toast()` returned it (or as you gave it), as a string. */
  get id(): string {
    return this.element.getAttribute('data-test-jn-name') ?? ''
  }

  /** Its title, whitespace collapsed. */
  get title(): string {
    return text(this.queryPart('title'))
  }

  /** Its description, or `null` without one. */
  get description(): string | null {
    const description = this.queryPart('description')
    return description ? text(description) : null
  }

  /** Its type (`success`, `error`, `loading`…), or `null` for a plain toast. */
  get type(): string | null {
    return this.element.getAttribute('data-type')
  }

  /** Where it shows, as `top-center` or `bottom-right`. */
  get position(): string {
    const y = this.element.getAttribute('data-y-position')
    const x = this.element.getAttribute('data-x-position')
    return `${y}-${x}`
  }

  #flag(name: string): boolean {
    return this.element.getAttribute(name) === 'true'
  }

  /** Whether it is the newest in its stack, the one in front. */
  get isFront(): boolean {
    return this.#flag('data-front')
  }

  /** Whether it is among the toasts the stack shows (`@visibleToasts`, 3 by default). */
  get isVisible(): boolean {
    return this.#flag('data-visible')
  }

  /** Whether its stack is expanded (hovered, focused, or `@expand`). */
  get isExpanded(): boolean {
    return this.#flag('data-expanded')
  }

  /** Whether it has finished coming in. */
  get isMounted(): boolean {
    return this.#flag('data-mounted')
  }

  /** Whether it is on its way out. */
  get isRemoved(): boolean {
    return this.#flag('data-removed')
  }

  /** Whether it was swiped away. */
  get isSwipedOut(): boolean {
    return this.#flag('data-swipe-out')
  }

  /** Whether it is coloured by its type. */
  get hasRichColors(): boolean {
    return this.#flag('data-rich-colors')
  }

  /** Whether it is inverted. */
  get isInverted(): boolean {
    return this.#flag('data-invert')
  }

  /** Whether the user can close it (`dismissible`). */
  get isDismissible(): boolean {
    return this.#flag('data-dismissible')
  }

  /** Whether it shows sonner's look (`false` for `unstyled` and custom toasts). */
  get isStyled(): boolean {
    return this.#flag('data-styled')
  }

  /** Whether it follows a promise (`toast.promise()`). */
  get isPromise(): boolean {
    return this.#flag('data-promise')
  }

  /** Whether it is loading (`toast.loading()`, or a promise that hasn't settled). */
  get isLoading(): boolean {
    return this.type === 'loading'
  }

  /** Its icon's box (`[data-icon]`), or `null` without one. */
  get icon(): HTMLElement | null {
    return this.queryPart('icon')
  }

  /** Its action button, or `null`. */
  get action(): HTMLButtonElement | null {
    return this.queryPart<HTMLButtonElement>('action')
  }

  /** Its cancel button, or `null`. */
  get cancel(): HTMLButtonElement | null {
    return this.queryPart<HTMLButtonElement>('cancel')
  }

  /** Its close button, or `null` without one (`closeButton`). */
  get closeButton(): HTMLButtonElement | null {
    return this.queryPart<HTMLButtonElement>('close')
  }

  #button(button: HTMLButtonElement | null, name: string): HTMLButtonElement {
    if (!button) throw new Error(`${this} has no ${name} button`)
    return button
  }

  /** Presses its action button. The toast closes, unless the handler prevents it. */
  async clickAction(): Promise<void> {
    await click(this.#button(this.action, 'action'))
  }

  /** Presses its cancel button. The toast closes. */
  async clickCancel(): Promise<void> {
    await click(this.#button(this.cancel, 'cancel'))
  }

  /** Presses its close button. The toast closes. */
  async close(): Promise<void> {
    await click(this.#button(this.closeButton, 'close'))
  }

  /** Moves focus to it, as tabbing to it would. */
  async focus(): Promise<void> {
    await focus(this.element)
  }

  /**
   * Swipes it with a pointer, as a finger would: down on it, across, and up. Far enough (45px,
   * or fast enough) towards a side it can leave by, it goes; otherwise it springs back.
   */
  async swipe(direction: ToastSwipe, options: ToastSwipeOptions = {}): Promise<void> {
    const { distance = 100, duration = 0 } = options
    const element = this.element
    const box = element.getBoundingClientRect()
    const start = { x: box.left + box.width / 2, y: box.top + box.height / 2 }
    const delta = {
      left: [-distance, 0],
      right: [distance, 0],
      up: [0, -distance],
      down: [0, distance],
    }[direction]
    const pointer = { pointerId: 1, pointerType: 'touch', isPrimary: true, button: 0 }
    await triggerEvent(element, 'pointerdown', { ...pointer, clientX: start.x, clientY: start.y })
    const steps = 4
    for (let step = 1; step <= steps; step++) {
      await triggerEvent(element, 'pointermove', {
        ...pointer,
        clientX: start.x + (delta[0]! * step) / steps,
        clientY: start.y + (delta[1]! * step) / steps,
      })
    }
    if (duration > 0) await new Promise(resolve => setTimeout(resolve, duration))
    const end = { clientX: start.x + delta[0]!, clientY: start.y + delta[1]! }
    // triggerEvent settles, so a dismissed toast has gone (its exit is a test waiter).
    await triggerEvent(element, 'pointerup', { ...pointer, ...end })
  }
}

/** The data attributes a toaster's list (`<ol data-sonner-toaster>`) carries. */
export interface ToasterListState {
  /** Its position, as `bottom-right`. */
  position: string
  /** `light` or `dark`. */
  theme: string | null
  /** `ltr` or `rtl`. */
  dir: string | null
}

/**
 * Drives a `<Toaster>` (from `@ember-joinery/ember` or `@ember-joinery/primitives/toast`): the
 * live region, its lists (one per position in use) and its toasts.
 *
 *   const toaster = new ToasterHarness()
 *   await click(saveButton)
 *   assert.deepEqual(toaster.titles, ['Saved'])
 *   await toaster.hover() // expands the stack and pauses the timers
 *
 * Toasts belong to the app, so give each test its own with `setupToaster(hooks)`.
 */
export class ToasterHarness extends Harness {
  static override component = 'toaster'

  /** The region's name: `Notifications alt+T` unless given `@containerAriaLabel`. */
  get label(): string {
    return this.element.getAttribute('aria-label') ?? ''
  }

  /** Its lists (`<ol>`), one for each position with toasts, in document order. */
  get lists(): HTMLOListElement[] {
    return this.parts<HTMLOListElement>('list')
  }

  /** The positions it shows toasts in now. */
  get positions(): string[] {
    return this.values('list')
  }

  /** What each list says about itself: its position, theme and direction. */
  get listStates(): ToasterListState[] {
    return this.lists.map(list => ({
      position: list.getAttribute('data-test-jn-value') ?? '',
      theme: list.getAttribute('data-sonner-theme'),
      dir: list.getAttribute('dir'),
    }))
  }

  /** Its theme (`light` or `dark`), from its lists; `null` while it shows no toasts. */
  get theme(): string | null {
    return this.lists[0]?.getAttribute('data-sonner-theme') ?? null
  }

  /** Every toast it shows (and any on its way out), newest first in each list. */
  get toasts(): ToastHarness[] {
    return this.findAll(ToastHarness)
  }

  /** The toasts' titles, newest first in each list. */
  get titles(): string[] {
    return this.toasts.map(toast => toast.title)
  }

  /** How many toasts it shows, not counting any on their way out. */
  get count(): number {
    return this.toasts.filter(toast => !toast.isRemoved).length
  }

  /**
   * One toast: the newest without options, else by its id (`toast('…', { id })`) or its index
   * among the toasts (newest first).
   */
  toast(options?: ChildOptions): ToastHarness {
    return this.find(ToastHarness, options)
  }

  /** Whether its stack is expanded. */
  get isExpanded(): boolean {
    return this.toasts.some(toast => toast.isExpanded)
  }

  #list(position?: string): HTMLOListElement {
    const lists = this.lists
    const list = position
      ? lists.find(each => each.getAttribute('data-test-jn-value') === position)
      : lists[0]
    if (!list) throw new Error(`${this} shows no toasts${position ? ` at ${position}` : ''}`)
    return list
  }

  /** Puts the pointer on a list (the first, or the one at `position`): it expands and pauses. */
  async hover(position?: string): Promise<void> {
    const list = this.#list(position)
    await triggerEvent(list, 'mouseenter')
    await triggerEvent(list, 'mousemove')
  }

  /** Takes the pointer off a list: it collapses, and the timers run again. */
  async unhover(position?: string): Promise<void> {
    await triggerEvent(this.#list(position), 'mouseleave')
  }

  /**
   * Presses the hotkey, which expands the stack and moves focus to it. Give the keys as the
   * Toaster's `@hotkey` names them: modifier properties and key codes. Default Alt+T,
   * `['altKey', 'KeyT']`, sonner's.
   */
  async pressHotkey(hotkey: readonly string[] = ['altKey', 'KeyT']): Promise<void> {
    const options: Record<string, unknown> = {}
    for (const key of hotkey) {
      if (/Key$/.test(key)) options[key] = true
      else {
        options['code'] = key
        options['key'] = key.replace(/^Key|^Digit/, '').toLowerCase()
      }
    }
    await triggerEvent(document as unknown as Element, 'keydown', options)
  }

  /** Waits until it shows a toast with this title (or any toast), as one made after a delay. */
  async waitForToast(title?: string, options: { timeout?: number } = {}): Promise<ToastHarness> {
    await waitUntil(
      () => this.exists && this.toasts.some(toast => title === undefined || toast.title === title),
      { timeout: options.timeout ?? 3000, timeoutMessage: `${this} showed no toast "${title}"` },
    )
    return this.toasts.find(toast => title === undefined || toast.title === title)!
  }

  /** Waits until every toast has gone, as their time runs out. */
  async waitForNoToasts(options: { timeout?: number } = {}): Promise<void> {
    await waitUntil(() => !this.exists || this.toasts.length === 0, {
      timeout: options.timeout ?? 6000,
      timeoutMessage: `${this} still shows toasts`,
    })
    await settled()
  }
}

const OWNER = 'JOINERY_TOAST_OWNER'

/**
 * Gives each test in a module its own toasts. `toast()` is called from anywhere, so it finds
 * its app through the rendered `<Toaster>`; this points it at the test's owner from the start
 * of each test, so a toast made before a Toaster renders (or in a test that renders none) goes
 * to the test, and never to another one. It sets `globalThis.JOINERY_TOAST_OWNER`, which
 * `@ember-joinery/primitives/toast` reads each time a toast is made, and takes it away after.
 * Call it after `setupRenderingTest(hooks)` or `setupApplicationTest(hooks)`.
 *
 *   module('saving', function (hooks) {
 *     setupRenderingTest(hooks)
 *     setupToaster(hooks)
 *
 *     test('it says so', async function (assert) {
 *       await render(<template><SaveButton /><Toaster /></template>)
 *       await click('button')
 *       assert.deepEqual(new ToasterHarness().titles, ['Saved'])
 *     })
 *   })
 *
 * The toasts themselves are the owner's, so they, and their timers, go with it at the end of
 * the test.
 */
export function setupToaster(hooks: TestHooks): void {
  const global = globalThis as Record<string, unknown>
  hooks.beforeEach(() => {
    const context = getContext() as { owner?: unknown } | undefined
    if (!context?.owner) {
      throw new Error(
        'Joinery: setupToaster(hooks) found no test owner; call it after setupRenderingTest(hooks) or setupApplicationTest(hooks)',
      )
    }
    global[OWNER] = context.owner
  })
  hooks.afterEach(() => {
    delete global[OWNER]
  })
}
