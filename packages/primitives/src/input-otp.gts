import Component from '@glimmer/component'
import { cached, tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { registerDestructor } from '@ember/destroyable'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { buildWaiter } from '@ember/test-waiters'
import type { WithBoundArgs } from '@glint/template'
import Modifier from 'ember-modifier'
import { controllable } from './controllable-state.ts'

const waiter = buildWaiter('@ember-joinery/primitives:input-otp')

/** Only digits: `@pattern={{REGEXP_ONLY_DIGITS}}`. */
export const REGEXP_ONLY_DIGITS = '^\\d+$'
/** Only Latin letters. */
export const REGEXP_ONLY_CHARS = '^[a-zA-Z]+$'
/** Digits and Latin letters. */
export const REGEXP_ONLY_DIGITS_AND_CHARS = '^[a-zA-Z0-9]+$'

/** The default `@label`, the input's name when nothing else names it. */
export const INPUT_OTP_LABEL = 'One-time password'

/** How far the input reaches past the slots for a password manager's badge, as input-otp's. */
const PASSWORD_MANAGER_BADGE_SPACE = 40

/** What one slot shows: a character of the code, or where the next one goes. */
export interface OTPSlot {
  /** Its position in the code, from 0. */
  readonly index: number
  /** The character there, or `null` while there is none. */
  readonly char: string | null
  /** The `@placeholder`'s character for it, while the code is empty. */
  readonly placeholderChar: string | null
  /** Whether the selection is on it: the character typing replaces, or where it goes next. */
  readonly isActive: boolean
  /** Whether to draw a caret in it: it is active and empty. */
  readonly hasFakeCaret: boolean
}

type SelectionDirection = 'forward' | 'backward' | 'none'

const EMPTY_SLOT: OTPSlot = {
  index: -1,
  char: null,
  placeholderChar: null,
  isActive: false,
  hasFakeCaret: false,
}

function slotAt(slots: readonly OTPSlot[], index: number): OTPSlot {
  return slots[index] ?? { ...EMPTY_SLOT, index }
}

/** A slot's `data-active`, as React renders upstream's: `true`, `false`, or none past the end. */
function activeAttribute(slots: readonly OTPSlot[], index: number): 'true' | 'false' | undefined {
  const slot = slots[index]
  if (!slot) return undefined
  return slot.isActive ? 'true' : 'false'
}

export interface InputOTPSlotSignature {
  Args: {
    /** Which character of the code it shows, from 0. */
    index: number
    /** @internal Bound by `InputOTP`. */
    slots: readonly OTPSlot[]
  }
  Blocks: {
    /** What it shows, given its state; without a block, its character. */
    default: [slot: OTPSlot]
  }
  Element: HTMLDivElement
}

/**
 * One character's box: a `div` with `data-active` (`"true"` while the selection is on it), and
 * its character inside, or whatever its block draws from the slot it yields (a caret, say).
 */
export const InputOTPSlot: TOC<InputOTPSlotSignature> = <template>
  <div
    data-active={{activeAttribute @slots @index}}
    data-test-jn-part="slot"
    data-test-jn-value="{{@index}}"
    ...attributes
  >
    {{#if (has-block)}}
      {{yield (slotAt @slots @index)}}
    {{else}}
      {{#let (slotAt @slots @index) as |slot|}}{{slot.char}}{{/let}}
    {{/if}}
  </div>
</template>

export interface InputOTPSignature {
  Args: {
    /** How many characters the code has. */
    maxLength: number
    /** The code, when you control it. A change someone makes goes to `@onValueChange`. */
    value?: string
    /** The code it starts with when you don't control it. */
    defaultValue?: string
    /** Called with the new code whenever someone changes it, controlled or not. */
    onValueChange?: (value: string) => void
    /** Called with the code when it becomes complete (`@maxLength` characters). */
    onComplete?: (value: string) => void
    /**
     * What the code may hold, as a regular expression or its source (`REGEXP_ONLY_DIGITS`). A
     * change that would leave a code it doesn't match is refused.
     */
    pattern?: string | RegExp
    /** Turns pasted text into the code to insert: strip a pasted code's dashes, say. */
    pasteTransformer?: (pasted: string) => string
    /** Shown in the slots, a character each, while the code is empty. */
    placeholder?: string
    /**
     * Submits the input's form (`requestSubmit()`, so the form validates) as soon as the code is
     * complete, as ember-primitives' `@autoSubmit`. Default `false`.
     */
    autoSubmit?: boolean
    /**
     * The input's name when nothing else names it (an `aria-label`, `aria-labelledby` or a
     * `<label>`). Pass it to name it so whatever else there is. Default `One-time password`.
     */
    label?: string
    /** Where the (invisible) text sits in the input. Default `left`. */
    textAlign?: 'left' | 'center' | 'right'
    /**
     * `increase-width` (the default) lets the input reach 40px past the slots, where there is
     * room, so a password manager's badge sits beyond the last one; `none` doesn't.
     */
    pushPasswordManagerStrategy?: 'increase-width' | 'none'
    /** Classes for the container that holds the slots and the input. */
    containerClass?: string
    /** Its name, for `InputOTPHarness` (`data-test-jn-name`). Its form field name is `name`. */
    name?: string
  }
  Blocks: {
    default: [
      otp: {
        /** Each slot's state, one per character of `@maxLength`. */
        slots: readonly OTPSlot[]
        /** A slot, bound to this input: `<otp.Slot @index={{0}} />`. */
        Slot: WithBoundArgs<typeof InputOTPSlot, 'slots'>
        /** The code now. */
        value: string
        /** Whether the code has `@maxLength` characters. */
        isComplete: boolean
        /** Whether the input has focus. */
        isFocused: boolean
        /** Whether the pointer is over it (and it isn't disabled). */
        isHovering: boolean
      },
    ]
  }
  /**
   * The one native `<input>` that holds the code, laid over the slots, invisible: give it `id`,
   * `name`, `disabled`, `required`, `aria-*` and listeners, as upstream's props go on its input.
   */
  Element: HTMLInputElement
}

/**
 * A one-time code field, as the `input-otp` library under shadcn's Input OTP has it, which also
 * covers ember-primitives' `OTP`: one native `<input>`, invisible, laid over slots you render
 * from its state, so typing, deleting, paste, the browser's autofill of a code it was sent (the
 * input has `autocomplete="one-time-code"`), and a form all work as on any input. Its selection
 * is kept to one character, the one typing replaces, and the slot under it is active:
 *
 *   <InputOTP @maxLength={{6}} @onComplete={{this.verify}} as |otp|>
 *     {{#each otp.slots as |slot|}}
 *       <otp.Slot @index={{slot.index}} class="my-slot" />
 *     {{/each}}
 *   </InputOTP>
 *
 * Its code is controlled or not, as in Radix (`@value`, `@defaultValue`, `@onValueChange`);
 * `@pattern` refuses what it doesn't match, and a paste goes through `@pasteTransformer`.
 */
export class InputOTP extends Component<InputOTPSignature> {
  code = controllable(this, 'value', '')

  @tracked isFocused = false
  @tracked isHovering = false
  @tracked selectionStart: number | null = null
  @tracked selectionEnd: number | null = null
  /** Whether the input reaches past the slots for a password manager's badge. */
  @tracked reachesForBadge = false

  /** The selection last seen, for telling which way it moved. */
  previousSelection: [number | null, number | null, SelectionDirection] = [null, null, 'none']

  get value(): string {
    return this.code.value
  }

  get maxLength(): number {
    return this.args.maxLength
  }

  get isComplete(): boolean {
    return this.value.length === this.maxLength
  }

  @cached
  get regexp(): RegExp | null {
    const { pattern } = this.args
    if (!pattern) return null
    return typeof pattern === 'string' ? new RegExp(pattern) : pattern
  }

  @cached
  get slots(): readonly OTPSlot[] {
    const { value, isFocused, selectionStart: start, selectionEnd: end } = this
    const placeholder = this.args.placeholder
    return Array.from({ length: Math.max(0, this.maxLength) }, (_, index) => {
      const isActive =
        isFocused &&
        start !== null &&
        end !== null &&
        ((start === end && index === start) || (index >= start && index < end))
      const char = value[index] ?? null
      const placeholderChar = value[0] !== undefined ? null : (placeholder?.[index] ?? null)
      return { index, char, placeholderChar, isActive, hasFakeCaret: isActive && char === null }
    })
  }

  /** Whether `code` is one the input may hold. */
  accepts(code: string): boolean {
    return code.length === 0 || !this.regexp || this.regexp.test(code)
  }

  /** Puts the code in the input, unless it shows it already (which would move the caret). */
  show(input: HTMLInputElement): void {
    if (input.value !== this.value) input.value = this.value
  }

  /** Sets the slots' selection, touching tracked state only when it changed. */
  mirror(start: number | null, end: number | null): void {
    if (this.selectionStart !== start) this.selectionStart = start
    if (this.selectionEnd !== end) this.selectionEnd = end
  }

  /**
   * Keeps the selection on one character, as input-otp does on every `selectionchange`: a caret
   * inside the code selects the character after it (or, moving back, before it), so typing
   * replaces it; a caret after the last character stays there, to add one.
   */
  syncSelection(input: HTMLInputElement): void {
    if (input.ownerDocument.activeElement !== input) {
      this.mirror(null, null)
      return
    }
    const selectionStart = input.selectionStart
    const selectionEnd = input.selectionEnd
    const max = input.maxLength
    const value = input.value
    const previous = this.previousSelection

    let start = -1
    let end = -1
    let direction: SelectionDirection | undefined
    if (value.length !== 0 && selectionStart !== null && selectionEnd !== null) {
      const isSingleCaret = selectionStart === selectionEnd
      const isInsertMode = selectionStart === value.length && value.length < max
      if (isSingleCaret && !isInsertMode) {
        const caret = selectionStart
        if (caret === 0) {
          start = 0
          end = 1
          direction = 'forward'
        } else if (caret === max) {
          start = caret - 1
          end = caret
          direction = 'backward'
        } else if (max > 1 && value.length > 1) {
          let offset = 0
          if (previous[0] !== null && previous[1] !== null) {
            direction = caret < previous[1] ? 'backward' : 'forward'
            const wasInserting = previous[0] === previous[1] && previous[0] < max
            if (direction === 'backward' && !wasInserting) offset = -1
          }
          start = offset + caret
          end = offset + caret + 1
        }
      }
      if (start !== -1 && end !== -1 && start !== end) {
        input.setSelectionRange(start, end, direction)
      }
    }
    const s = start !== -1 ? start : selectionStart
    const e = end !== -1 ? end : selectionEnd
    this.mirror(s, e)
    this.previousSelection = [s, e, direction ?? input.selectionDirection ?? 'none']
  }

  /** The code before the last change, for telling when it becomes complete. */
  #last: string | undefined

  /** @internal What the input showed first, so a change from it can complete the code. */
  started(value: string): void {
    this.#last = value
  }

  /**
   * Notes the code the input holds now. When it has just become complete, calls `@onComplete`
   * and, with `@autoSubmit`, submits the form: at once after someone's change, or after the
   * render when the caller changed `@value` (a render can't run callbacks that change state).
   */
  settle(input: HTMLInputElement, { later = false } = {}): void {
    const last = this.#last
    const value = this.value
    this.#last = value
    if (last === undefined || last === value) return
    if (!(last.length < this.maxLength && value.length === this.maxLength)) return
    const complete = () => {
      this.args.onComplete?.(value)
      if (this.args.autoSubmit) input.form?.requestSubmit()
    }
    if (!later) return complete()
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      try {
        complete()
      } finally {
        waiter.endAsync(token)
      }
    })
  }

  /**
   * Every change, typed, deleted, pasted or autofilled: cut to `@maxLength`, refused when
   * `@pattern` doesn't match it. It listens in the capture phase, so it runs ahead of the
   * caller's own `input` listeners, which never hear a change it refused.
   */
  handleInput = (event: Event): void => {
    const input = event.currentTarget as HTMLInputElement
    const next = input.value.slice(0, this.maxLength)
    if (!this.accepts(next)) {
      // Refused: the input goes back to the code it held, and nothing else hears the change.
      event.stopImmediatePropagation()
      this.show(input)
      this.syncSelection(input)
      return
    }
    if (next.length < this.value.length) {
      // Deleting moves no selection, so nothing else tells the slots.
      input.ownerDocument.dispatchEvent(new Event('selectionchange'))
    }
    this.code.set(next)
    // Controlled, the caller's answer is there now; either way the input shows the code.
    this.show(input)
    this.syncSelection(input)
    this.settle(input)
  }

  /**
   * Every paste goes into the code here, as input-otp does on iOS (and ember-primitives does
   * everywhere): through `@pasteTransformer`, into the selection, cut to `@maxLength`, and
   * refused whole when the code wouldn't match `@pattern`. An `input` event follows, as a
   * native paste's does.
   */
  handlePaste = (event: ClipboardEvent): void => {
    const input = event.currentTarget as HTMLInputElement
    const clipboard = event.clipboardData
    if (!clipboard) return
    event.preventDefault()
    const pasted = clipboard.getData('text/plain')
    const content = this.args.pasteTransformer ? this.args.pasteTransformer(pasted) : pasted
    const value = this.value
    const start = input.selectionStart ?? value.length
    const end = input.selectionEnd ?? start
    const next = (value.slice(0, start) + content + value.slice(end)).slice(0, this.maxLength)
    if (!this.accepts(next)) return
    input.value = next
    input.dispatchEvent(
      new InputEvent('input', { bubbles: true, inputType: 'insertFromPaste', data: content }),
    )
    const caret = Math.min(next.length, this.maxLength - 1)
    input.setSelectionRange(caret, next.length)
    this.syncSelection(input)
  }

  handleFocus = (event: FocusEvent): void => {
    const input = event.currentTarget as HTMLInputElement
    const start = Math.min(input.value.length, this.maxLength - 1)
    const end = input.value.length
    input.setSelectionRange(start, end)
    this.mirror(start, end)
    this.previousSelection = [start, end, input.selectionDirection ?? 'none']
    this.isFocused = true
    this.#reachForBadge(input)
  }

  handleBlur = (): void => {
    this.isFocused = false
  }

  handleMouseOver = (event: MouseEvent): void => {
    const hovering = !(event.currentTarget as HTMLInputElement).disabled
    if (this.isHovering !== hovering) this.isHovering = hovering
  }

  handleMouseLeave = (): void => {
    if (this.isHovering) this.isHovering = false
  }

  /**
   * Once it has focus, the input reaches past the slots, where the viewport leaves room, so a
   * password manager's badge (drawn at an input's inline end) sits beyond the last slot.
   */
  #reachForBadge(input: HTMLInputElement): void {
    if (this.reachesForBadge || this.args.pushPasswordManagerStrategy === 'none') return
    const container = input.closest('[data-input-otp-container]')
    const view = input.ownerDocument.defaultView
    if (!container || !view) return
    const room = view.innerWidth - container.getBoundingClientRect().right
    if (room >= PASSWORD_MANAGER_BADGE_SPACE) this.reachesForBadge = true
  }

  <template>
    <div
      class={{@containerClass}}
      data-input-otp-container=""
      data-test-jn="input-otp"
      data-test-jn-name={{@name}}
    >
      {{yield
        (hash
          slots=this.slots
          Slot=(component InputOTPSlot slots=this.slots)
          value=this.value
          isComplete=this.isComplete
          isFocused=this.isFocused
          isHovering=this.isHovering
        )
      }}
      <div>
        <input
          autocomplete="one-time-code"
          inputmode="numeric"
          aria-label={{@label}}
          data-input-otp=""
          data-input-otp-placeholder-shown={{if this.value undefined "true"}}
          data-input-otp-mss={{this.selectionStart}}
          data-input-otp-mse={{this.selectionEnd}}
          pattern={{if this.regexp this.regexp.source}}
          aria-placeholder={{@placeholder}}
          maxlength={{@maxLength}}
          data-test-jn-part="input"
          {{on "input" this.handleInput capture=true}}
          {{on "paste" this.handlePaste capture=true}}
          {{on "focus" this.handleFocus}}
          {{on "blur" this.handleBlur}}
          {{on "mouseover" this.handleMouseOver}}
          {{on "mouseleave" this.handleMouseLeave}}
          ...attributes
          {{OTPInputModifier
            otp=this
            value=this.value
            textAlign=@textAlign
            reachesForBadge=this.reachesForBadge
          }}
        />
      </div>
    </div>
  </template>
}

interface OTPInputModifierSignature {
  Element: HTMLInputElement
  Args: {
    Named: {
      otp: InputOTP
      value: string
      textAlign: 'left' | 'center' | 'right' | undefined
      reachesForBadge: boolean
    }
  }
}

/**
 * Ties the input to its `InputOTP`: it shows the code (and, when the caller's `@value` makes it
 * complete, calls `@onComplete`), styles the input, and once, listens for `selectionchange`,
 * measures the input for `--root-height`, adopts the shared rules, names the input when
 * nothing else does, and puts the code back after a form reset.
 */
class OTPInputModifier extends Modifier<OTPInputModifierSignature> {
  #connected = false

  override modify(
    input: HTMLInputElement,
    _: [],
    { otp, textAlign = 'left', reachesForBadge }: OTPInputModifierSignature['Args']['Named'],
  ): void {
    otp.show(input)
    style(input, textAlign, reachesForBadge)
    if (!this.#connected) {
      this.#connected = true
      styleContainer(input)
      registerDestructor(this, connect(input, otp))
      return
    }
    otp.settle(input, { later: true })
    // A render can't change what it has read, so the slots follow the selection after it.
    const token = waiter.beginAsync()
    setTimeout(() => {
      try {
        if (input.isConnected) otp.syncSelection(input)
      } finally {
        waiter.endAsync(token)
      }
    }, 0)
  }
}

/**
 * The styles input-otp gives its container and the box around the input: the container takes
 * no pointer (the input does), and the box covers it. Through the CSSOM, as all of these, so a
 * strict Content Security Policy allows them.
 */
function styleContainer(input: HTMLInputElement): void {
  const box = input.parentElement
  const container = box?.parentElement
  if (!box || !container) return
  container.style.setProperty('position', 'relative')
  container.style.setProperty('cursor', 'text')
  container.style.setProperty('user-select', 'none')
  container.style.setProperty('-webkit-user-select', 'none')
  container.style.setProperty('pointer-events', 'none')
  box.style.setProperty('position', 'absolute')
  box.style.setProperty('inset', '0')
  box.style.setProperty('pointer-events', 'none')
}

/** The input's own styles, as input-otp's: it covers the slots, and draws nothing. */
function style(input: HTMLInputElement, textAlign: string, reachesForBadge: boolean): void {
  const style = input.style
  const badge = `${PASSWORD_MANAGER_BADGE_SPACE}px`
  style.setProperty('position', 'absolute')
  style.setProperty('inset', '0')
  style.setProperty('width', reachesForBadge ? `calc(100% + ${badge})` : '100%')
  if (reachesForBadge) style.setProperty('clip-path', `inset(0 ${badge} 0 0)`)
  else style.removeProperty('clip-path')
  style.setProperty('height', '100%')
  style.setProperty('display', 'flex')
  style.setProperty('text-align', textAlign)
  style.setProperty('opacity', '1') // iOS needs it to paste on a long press
  style.setProperty('color', 'transparent')
  style.setProperty('pointer-events', 'all')
  style.setProperty('background', 'transparent')
  style.setProperty('caret-color', 'transparent')
  style.setProperty('border', '0 solid transparent')
  style.setProperty('outline', '0 solid transparent')
  style.setProperty('box-shadow', 'none')
  style.setProperty('line-height', '1')
  style.setProperty('letter-spacing', '-.5em')
  style.setProperty('font-size', 'var(--root-height)')
  style.setProperty('font-family', 'monospace')
  style.setProperty('font-variant-numeric', 'tabular-nums')
}

/** What every input needs whatever its styles: input-otp's injected rules. */
const SHARED_RULES = `
[data-input-otp]::selection { background: transparent !important; color: transparent !important; }
[data-input-otp]:autofill, [data-input-otp]:-webkit-autofill { background: transparent !important; color: transparent !important; border-color: transparent !important; opacity: 0 !important; box-shadow: none !important; -webkit-box-shadow: none !important; -webkit-text-fill-color: transparent !important; }
@supports (-webkit-touch-callout: none) { [data-input-otp] { letter-spacing: -.6em !important; font-weight: 100 !important; font-stretch: ultra-condensed; font-optical-sizing: none !important; left: -1px !important; right: 1px !important; } }
[data-input-otp] + * { pointer-events: all !important; }
`

const sheets = new WeakMap<Document, CSSStyleSheet>()

/**
 * Adopts the shared rules into the input's document (or shadow root), once. A constructed
 * sheet, not a `<style>`, so a strict Content Security Policy allows it.
 */
function adoptRules(input: HTMLInputElement): void {
  const root = input.getRootNode()
  const document = input.ownerDocument
  const View = document.defaultView
  if (!View || !(root instanceof View.Document || root instanceof View.ShadowRoot)) return
  let sheet = sheets.get(document)
  if (!sheet) {
    sheet = new View.CSSStyleSheet()
    try {
      sheet.replaceSync(SHARED_RULES)
    } catch {
      return
    }
    sheets.set(document, sheet)
  }
  if (!root.adoptedStyleSheets.includes(sheet)) {
    root.adoptedStyleSheets = [...root.adoptedStyleSheets, sheet]
  }
}

/** Whether the input has a name of its own: an `aria-label`, `aria-labelledby` or a `<label>`. */
function isNamed(input: HTMLInputElement): boolean {
  return (
    Boolean(input.getAttribute('aria-label')?.trim()) ||
    input.hasAttribute('aria-labelledby') ||
    Boolean(input.labels?.length)
  )
}

/** Starts the input's listeners and observers; returns what stops them. */
function connect(input: HTMLInputElement, otp: InputOTP): () => void {
  const document = input.ownerDocument
  const container = input.closest<HTMLElement>('[data-input-otp-container]')
  otp.started(otp.value)
  adoptRules(input)
  if (!isNamed(input)) input.setAttribute('aria-label', INPUT_OTP_LABEL)

  const onSelectionChange = (): void => otp.syncSelection(input)
  document.addEventListener('selectionchange', onSelectionChange, { capture: true })
  // Focused already (`autofocus`): the slots hear it after the render, which can't change
  // what it has read.
  let focused: { timer: ReturnType<typeof setTimeout>; token: unknown } | undefined
  if (document.activeElement === input) {
    const token = waiter.beginAsync()
    const timer = setTimeout(() => {
      focused = undefined
      try {
        if (document.activeElement !== input) return
        otp.isFocused = true
        otp.syncSelection(input)
      } finally {
        waiter.endAsync(token)
      }
    }, 0)
    focused = { timer, token }
  }

  const measure = (): void => {
    container?.style.setProperty('--root-height', `${input.clientHeight}px`)
  }
  measure()
  const View = document.defaultView
  const observer = View ? new View.ResizeObserver(measure) : undefined
  observer?.observe(input)

  // A form reset puts the code back to the one it started with, as Joinery's inputs do.
  const start = otp.value
  let reset: { timer: ReturnType<typeof setTimeout>; token: unknown } | undefined
  const onReset = (event: Event): void => {
    if (event.target !== input.form || event.defaultPrevented || reset) return
    const token = waiter.beginAsync()
    const timer = setTimeout(() => {
      reset = undefined
      try {
        otp.code.set(start)
        otp.show(input)
        otp.settle(input)
      } finally {
        waiter.endAsync(token)
      }
    }, 0)
    reset = { timer, token }
  }
  document.addEventListener('reset', onReset)

  return () => {
    document.removeEventListener('selectionchange', onSelectionChange, { capture: true })
    document.removeEventListener('reset', onReset)
    observer?.disconnect()
    if (focused) {
      clearTimeout(focused.timer)
      waiter.endAsync(focused.token)
    }
    if (reset) {
      clearTimeout(reset.timer)
      waiter.endAsync(reset.token)
    }
  }
}
