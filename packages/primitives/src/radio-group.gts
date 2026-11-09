import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { registerDestructor } from '@ember/destroyable'
import Modifier from 'ember-modifier'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { ControllableState } from './controllable-state.ts'
import { idFor } from './id.ts'
import type { Direction } from './direction.gts'
import { RovingFocus, type Orientation } from './roving-focus.gts'
import { BubbleInput, FormControl, preventEnter } from './-private/form-control.ts'
import { Indicator } from './-private/indicator.gts'

const ARROW_KEYS = ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']

interface ArrowKeysSignature {
  Element: HTMLElement
  Args: { Named: { group: RadioGroup } }
}

/**
 * Notes whether an arrow key is down, as Radix's items do, so the item the arrow moves focus to
 * is chosen too. It listens on the document in the capture phase: roving focus moves focus
 * during the key's own `keydown`, before the event bubbles anywhere.
 */
class ArrowKeys extends Modifier<ArrowKeysSignature> {
  #installed = false

  override modify(element: HTMLElement, _: [], { group }: { group: RadioGroup }): void {
    if (this.#installed) return
    this.#installed = true
    const document = element.ownerDocument
    const down = (event: KeyboardEvent) => {
      if (ARROW_KEYS.includes(event.key)) group.isArrowKeyPressed = true
    }
    const up = () => (group.isArrowKeyPressed = false)
    document.addEventListener('keydown', down, true)
    document.addEventListener('keyup', up, true)
    registerDestructor(this, () => {
      document.removeEventListener('keydown', down, true)
      document.removeEventListener('keyup', up, true)
    })
  }
}

export interface RadioGroupItemSignature {
  Args: {
    /** What choosing it sets the group's value to. Unique in the group. */
    value: string
    /** Whether it can't be chosen. The arrow keys pass over it. */
    disabled?: boolean
    /** The tag to render. Default `button`. */
    as?: TagName
    /** @internal Bound by the group. */
    group: RadioGroup
  }
  Blocks: {
    default: [
      item: {
        /** The mark, rendered while it is chosen: `<item.Indicator>●</item.Indicator>`. */
        Indicator: WithBoundArgs<typeof Indicator, 'present' | 'state' | 'disabled'>
        /** Whether it is the group's value. */
        isChecked: boolean
      },
    ]
  }
  /** A `<button role="radio">`, or the tag `@as` names. */
  Element: HTMLButtonElement
}

/** One choice in a `<RadioGroup>`, yielded as `group.Item`: Radix's `RadioGroup.Item`. */
class RadioGroupItem extends Component<RadioGroupItemSignature> {
  get isChecked(): boolean {
    return this.args.group.value === this.args.value
  }

  get isDisabled(): boolean {
    return Boolean(this.args.group.args.disabled || this.args.disabled)
  }

  get isFocusable(): boolean {
    return !this.isDisabled
  }

  get stateName(): string {
    return this.isChecked ? 'checked' : 'unchecked'
  }

  /** Chooses it, unless a listener of the caller's called `preventDefault()` first. */
  choose = (event: MouseEvent): void => {
    if (event.defaultPrevented || this.isChecked) return
    this.args.group.choose(this.args.value)
  }

  /** An arrow key moved focus here: choose it too, as Radix does. */
  focused = (event: FocusEvent): void => {
    if (this.args.group.isArrowKeyPressed) (event.currentTarget as HTMLElement).click()
  }

  <template>
    <As
      @as={{@as}}
      @tag="button"
      type="button"
      role="radio"
      aria-checked={{if this.isChecked "true" "false"}}
      data-state={{this.stateName}}
      data-disabled={{if this.isDisabled ""}}
      disabled={{this.isDisabled}}
      value={{@value}}
      data-test-jn-part="item"
      data-test-jn-value={{@value}}
      data-test-jn-owner={{idFor @group}}
      ...attributes
      {{@group.roving.item tabStopId=@value focusable=this.isFocusable active=this.isChecked}}
      {{on "keydown" preventEnter}}
      {{on "click" this.choose}}
      {{on "focus" this.focused}}
    >
      {{yield
        (hash
          Indicator=(component
            Indicator present=this.isChecked state=this.stateName disabled=this.isDisabled
          )
          isChecked=this.isChecked
        )
      }}
    </As>
    {{#if @group.form.isFormControl}}
      <input
        type="radio"
        aria-hidden="true"
        tabindex="-1"
        name={{@group.form.fieldName}}
        value={{@value}}
        form={{@group.form.form}}
        required={{@group.args.required}}
        disabled={{this.isDisabled}}
        {{BubbleInput checked=this.isChecked announceUncheck=false}}
      />
    {{/if}}
  </template>
}

export interface RadioGroupSignature {
  Args: {
    /** The controlled value: the chosen item's `@value`, or `null` for none. */
    value?: string | null
    /** The first value, when uncontrolled. Default: none. */
    defaultValue?: string
    /** Called with each value the user chooses. */
    onValueChange?: (value: string) => void
    /** Whether every item is disabled. */
    disabled?: boolean
    /** Whether a form needs a choice to submit. */
    required?: boolean
    /** Which arrow keys move between items: `horizontal`, `vertical`, or (unset) all four. */
    orientation?: Orientation
    /** The text direction, for the arrow keys. Default: the document's, from the nearest `dir`. */
    dir?: Direction
    /** Whether the arrow keys go round from the last item to the first and back. Default `true`. */
    loop?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
    /**
     * The form field its choice submits as, in a form: each item's hidden radio takes this
     * `name`. (Radix's `name`; the root is a `<div>`, which takes no `name` attribute.)
     */
    formName?: string
    /** Its name, for `RadioGroupHarness` (`data-test-jn-name`). Its form field is `@formName`. */
    name?: string
  }
  Blocks: {
    default: [
      group: {
        /** One choice: `<group.Item @value="comfortable" id="r2" />`. */
        Item: WithBoundArgs<typeof RadioGroupItem, 'group'>
        /** The chosen item's value, or `null`. */
        value: string | null
      },
    ]
  }
  Element: HTMLDivElement
}

/**
 * A set of choices of which one, at most, is chosen: Radix's `RadioGroup`, headless. It is a
 * `role="radiogroup"` whose items are `<button role="radio">`s with `aria-checked`, sharing one
 * tab stop. Tab enters on the chosen item (or the first); the arrow keys move between the
 * items and choose the one they reach, going round at the ends (`@loop`), flipped right to
 * left; Space chooses the focused item; Home and End move without choosing. Its value is
 * controlled or not, as in Radix:
 *
 *   <RadioGroup @defaultValue="comfortable" aria-label="Spacing" as |group|>
 *     <group.Item @value="default" id="r1" as |item|><item.Indicator>●</item.Indicator></group.Item>
 *     <label for="r1">Default</label>
 *   </RadioGroup>
 *
 * In a form, each item renders a hidden native radio beside it, as Radix's does, named by the
 * group's `@formName`, so the form submits the chosen value and checks `@required`.
 *
 * Each item names the group's `id` in `data-test-jn-owner`, so `RadioGroupHarness` still finds
 * an item that sits inside another component, such as a Field or a label around it. A caller's
 * own `id` on the group wins; its items are then found where they sit, inside nothing else.
 */
export class RadioGroup extends Component<RadioGroupSignature> {
  selection = new ControllableState<string | null>({
    name: 'value',
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    onChange: () => this.args.onValueChange as ((value: string | null) => void) | undefined,
    fallback: null,
  })

  roving = new RovingFocus({
    orientation: () => this.args.orientation,
    dir: () => this.args.dir,
    loop: () => this.args.loop ?? true,
  })

  form = new FormControl({ name: () => this.args.formName })

  /** @internal Whether an arrow key is down, so the item it focuses is chosen too. */
  isArrowKeyPressed = false

  get value(): string | null {
    return this.selection.value
  }

  /** @internal */
  choose(value: string): void {
    this.selection.set(value)
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      id={{idFor this}}
      role="radiogroup"
      aria-required={{if @required "true"}}
      aria-orientation={{@orientation}}
      data-disabled={{if @disabled ""}}
      dir={{@dir}}
      data-test-jn="radio-group"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.roving.group}}
      {{this.form.source}}
      {{ArrowKeys group=this}}
    >
      {{yield (hash Item=(component RadioGroupItem group=this) value=this.value)}}
    </As>
  </template>
}

export default RadioGroup
