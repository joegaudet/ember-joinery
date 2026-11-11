import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import type Owner from '@ember/owner'
import type { TOC } from '@ember/component/template-only'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import { buttonClasses, Icon, InputGroup, Popover, type IconNode } from '@ember-joinery/ember'
import {
  controllable,
  type ControllableArgs,
  type ControllableState,
} from '@ember-joinery/primitives/controllable-state'
import { idFor } from '@ember-joinery/primitives/id'
import { ensureDateLibrary } from '../date-library.ts'
import type { CalendarOptions } from './state.ts'

type Align = 'start' | 'center' | 'end'
type Side = 'top' | 'right' | 'bottom' | 'left'

/** What both pickers take, besides their value and the calendar's options. */
export type PickerOptions = ControllableArgs<'open', boolean> &
  Omit<CalendarOptions, 'name' | 'disabled'> & {
    /**
     * What opens the calendar: an outlined `button` showing the value (the default), or an
     * `input` the date can be typed into, with a calendar button at its end (an Input Group).
     */
    trigger?: 'button' | 'input'
    /** The id of the button, or of the input, for a `<label for>`. */
    id?: string
    /** Its name, for `DatePickerHarness` (`data-test-jn-name`). */
    name?: string
    /** What the button or input shows with no date. */
    placeholder?: string
    /** How the date is written: `Intl.DateTimeFormat` options. */
    format?: Intl.DateTimeFormatOptions
    /** It can't be opened, nor typed into. */
    disabled?: boolean
    /** Marks it invalid (`aria-invalid`), as a FieldError would. */
    invalid?: boolean
    /** The ids of what describes it (a FieldDescription, a FieldError), as `aria-describedby`. */
    describedBy?: string
    /** The button's icon, one from `lucide`, or `null` for none. */
    icon?: IconNode | null
    /** Where the button's icon goes. */
    iconPosition?: 'inline-start' | 'inline-end'
    /** The calendar button's name, when `@trigger` is `input`. */
    triggerLabel?: string
    /** Where the calendar opens, along the trigger's edge. Default `start` (`end` for an input). */
    align?: Align
    /** Which side of the trigger it opens on. Default `bottom`. */
    side?: Side
  }

/** What the picker's frame reads from the picker that draws it. */
export interface PickerHost {
  readonly component: 'date-picker' | 'date-range-picker'
  readonly name: string | undefined
  readonly isOpen: boolean
  readonly inputMode: boolean
  readonly text: string
  readonly isEmpty: boolean
  readonly placeholder: string
  readonly inputText: string
  readonly triggerId: string | undefined
  readonly inputId: string
  readonly valueId: string
  readonly disabled: boolean
  readonly invalid: boolean
  readonly describedBy: string | undefined
  readonly icon: IconNode | null
  readonly iconAtStart: boolean
  readonly inputIcon: IconNode
  readonly triggerLabel: string
  readonly align: Align
  readonly side: Side | undefined
  readonly sideOffset: number | undefined
  readonly alignOffset: number | undefined
  setOpen: (open: boolean) => void
  onInput: (text: string) => void
  onInputKeydown: (event: KeyboardEvent) => void
  onInputBlur: () => void
  onOpenAutoFocus: (event: Event) => void
  onCloseAutoFocus: (event: Event) => void
  onEscapeKeyDown: (event: KeyboardEvent) => void
}

/**
 * What both pickers share: the popover's state (controlled or theirs), the trigger's text and
 * name, the typed text of an input trigger, and where focus goes as the calendar opens (its tab
 * stop: the chosen day, else today) and closes (back to the button, or to the input).
 */
export abstract class PickerBase<S extends { Args: PickerOptions }>
  extends Component<S>
  implements PickerHost
{
  openState: ControllableState<boolean> = controllable(this, 'open', false)
  /** What was typed into the input since the value was last written there. */
  @tracked typed: string | null = null
  /** The month shown, while the user pages away from the value's. */
  @tracked center: Date | undefined
  #focusInput = false

  constructor(owner: Owner, args: S['Args']) {
    super(owner, args)
    ensureDateLibrary()
  }

  abstract get component(): 'date-picker' | 'date-range-picker'
  abstract get text(): string
  abstract get isEmpty(): boolean
  abstract get defaultPlaceholder(): string
  abstract get defaultIcon(): IconNode
  abstract get defaultIconPosition(): 'inline-start' | 'inline-end'
  abstract get defaultTriggerLabel(): string
  /** The input's text for the value. */
  abstract get valueText(): string
  /** Reads typed text: whether it named a value, which the picker then takes. */
  abstract readTyped(text: string): boolean
  /** Clears the value, as emptying the input does. */
  abstract clear(): void
  /** Forgets what the calendar held while it was open. */
  abstract reset(): void

  get name(): string | undefined {
    return this.args.name
  }

  get isOpen(): boolean {
    return this.openState.value
  }

  get inputMode(): boolean {
    return this.args.trigger === 'input'
  }

  get placeholder(): string {
    return this.args.placeholder ?? this.defaultPlaceholder
  }

  get inputText(): string {
    return this.typed ?? this.valueText
  }

  get triggerId(): string | undefined {
    return this.inputMode ? undefined : this.args.id
  }

  get inputId(): string {
    return this.args.id ?? idFor(this, 'input')
  }

  get valueId(): string {
    return idFor(this, 'value')
  }

  get disabled(): boolean {
    return Boolean(this.args.disabled)
  }

  get invalid(): boolean {
    return Boolean(this.args.invalid)
  }

  get describedBy(): string | undefined {
    return this.args.describedBy
  }

  get icon(): IconNode | null {
    return this.args.icon === undefined ? this.defaultIcon : this.args.icon
  }

  get iconAtStart(): boolean {
    return (this.args.iconPosition ?? this.defaultIconPosition) === 'inline-start'
  }

  get inputIcon(): IconNode {
    return this.args.icon ?? this.defaultIcon
  }

  get triggerLabel(): string {
    return this.args.triggerLabel ?? this.defaultTriggerLabel
  }

  get align(): Align {
    return this.args.align ?? (this.inputMode ? 'end' : 'start')
  }

  get side(): Side | undefined {
    return this.args.side
  }

  /** Upstream's date-picker-input places its calendar 10px off, and 8px further along. */
  get sideOffset(): number | undefined {
    return this.inputMode ? 10 : undefined
  }

  get alignOffset(): number | undefined {
    return this.inputMode ? -8 : undefined
  }

  setOpen = (open: boolean): void => {
    if (open && this.disabled) return
    if (!open) {
      this.center = undefined
      this.reset()
    }
    this.openState.set(open)
  }

  /** Closes the calendar once a value is chosen, focus going back to the trigger or input. */
  close(): void {
    this.typed = null
    this.#focusInput = this.inputMode
    this.setOpen(false)
  }

  setCenter = (center: Date): void => {
    this.center = center
  }

  onInput = (text: string): void => {
    this.typed = text
    if (this.readTyped(text)) this.center = undefined
  }

  onInputKeydown = (event: KeyboardEvent): void => {
    if (event.key === 'ArrowDown' && !event.altKey) {
      event.preventDefault()
      this.setOpen(true)
    }
  }

  onInputBlur = (): void => {
    const typed = this.typed
    if (typed === null) return
    if (!typed.trim()) {
      this.clear()
      this.typed = null
    } else if (this.readTyped(typed)) {
      this.typed = null
    }
  }

  /** Focus goes to the calendar's tab stop (the chosen day, else today), not its first button. */
  onOpenAutoFocus = (event: Event): void => {
    const content = event.target as HTMLElement | null
    const day = content?.querySelector<HTMLElement>('[data-test-jn-part="day"][tabindex="0"]')
    if (!day) return
    event.preventDefault()
    day.focus()
  }

  /** Escape, as a choice does, sends focus back to the input it was typed into. */
  onEscapeKeyDown = (): void => {
    this.#focusInput = this.inputMode
  }

  onCloseAutoFocus = (event: Event): void => {
    if (!this.#focusInput) return
    this.#focusInput = false
    const input = document.getElementById(this.inputId)
    if (!input) return
    event.preventDefault()
    input.focus()
  }
}

/** Elements this modifier named, so it leaves a caller's own `aria-labelledby` alone. */
const named = new WeakSet<Element>()

/**
 * A `<label for>` names a button by the label's text alone, so the value it shows would go
 * unread. Once the button has a label, its name is the label's text and then the value
 * (`aria-labelledby`, giving the label an id if it has none), as a select's is.
 */
const nameWithValue = modifier((button: HTMLButtonElement, [valueId]: [string]) => {
  if (button.hasAttribute('aria-label')) return
  if (button.hasAttribute('aria-labelledby') && !named.has(button)) return
  const labels = [...(button.labels ?? [])]
  if (!labels.length) {
    if (named.has(button)) button.removeAttribute('aria-labelledby')
    return
  }
  const ids = labels.map((label, i) => label.id || (label.id = `${valueId}-label-${i}`))
  button.setAttribute('aria-labelledby', [...ids, valueId].join(' '))
  named.add(button)
})

const TRIGGER_CLASSES = `${buttonClasses({ variant: 'outline' })} jn-date-picker jn-date-picker-trigger`

export interface PickerFrameSignature {
  Args: { picker: PickerHost }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * A picker's markup: the trigger (an outlined Button, or an Input Group's input and calendar
 * button) and the Popover the calendar opens in, as upstream's date-picker examples compose
 * them. The caller's attributes go on the button, or on the Input Group.
 */
export const PickerFrame: TOC<PickerFrameSignature> = <template>
  <Popover @open={{@picker.isOpen}} @onOpenChange={{@picker.setOpen}} as |p|>
    {{#if @picker.inputMode}}
      <InputGroup
        class="jn-date-picker"
        data-slot={{@picker.component}}
        data-test-jn={{@picker.component}}
        data-test-jn-name={{@picker.name}}
        data-disabled={{if @picker.disabled "true"}}
        ...attributes
        as |g|
      >
        <g.Input
          id={{@picker.inputId}}
          @value={{@picker.inputText}}
          @onValueChange={{@picker.onInput}}
          placeholder={{@picker.placeholder}}
          disabled={{@picker.disabled}}
          aria-invalid={{if @picker.invalid "true"}}
          aria-describedby={{@picker.describedBy}}
          data-test-jn-part="input"
          {{on "keydown" @picker.onInputKeydown}}
          {{on "blur" @picker.onInputBlur}}
        />
        <g.Addon @align="inline-end">
          <g.Button
            @size="icon-xs"
            aria-label={{@picker.triggerLabel}}
            disabled={{@picker.disabled}}
            {{p.trigger}}
          ><Icon @icon={{@picker.inputIcon}} /></g.Button>
        </g.Addon>
      </InputGroup>
    {{else}}
      <button
        type="button"
        id={{@picker.triggerId}}
        class={{TRIGGER_CLASSES}}
        data-slot={{@picker.component}}
        data-variant="outline"
        data-size="default"
        data-empty={{if @picker.isEmpty "true" "false"}}
        data-test-jn={{@picker.component}}
        data-test-jn-name={{@picker.name}}
        aria-invalid={{if @picker.invalid "true"}}
        aria-describedby={{@picker.describedBy}}
        disabled={{@picker.disabled}}
        {{p.trigger}}
        {{nameWithValue @picker.valueId}}
        ...attributes
      >
        {{#if @picker.icon}}
          {{#if @picker.iconAtStart}}
            <Icon @icon={{@picker.icon}} data-icon="inline-start" />
          {{/if}}
        {{/if}}
        <span
          id={{@picker.valueId}}
          class="jn-date-picker-trigger-value"
          data-test-jn-part="value"
        >{{if @picker.isEmpty @picker.placeholder @picker.text}}</span>
        {{#if @picker.icon}}
          {{#unless @picker.iconAtStart}}
            <Icon @icon={{@picker.icon}} data-icon="inline-end" />
          {{/unless}}
        {{/if}}
      </button>
    {{/if}}
    <p.Content
      @align={{@picker.align}}
      @side={{@picker.side}}
      @sideOffset={{@picker.sideOffset}}
      @alignOffset={{@picker.alignOffset}}
      @onOpenAutoFocus={{@picker.onOpenAutoFocus}}
      @onCloseAutoFocus={{@picker.onCloseAutoFocus}}
      @onEscapeKeyDown={{@picker.onEscapeKeyDown}}
      class="jn-date-picker-content"
    >{{yield}}</p.Content>
  </Popover>
</template>
