import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { As, type TagName } from './as.gts'
import { controllable } from './controllable-state.ts'
import type { PartSpec } from './part.ts'

/** Radix's `data-state` for a toggle: `on` while it is pressed. */
export type ToggleState = 'on' | 'off'

/** What a toggle is: whether it is pressed, and whether it can be used. */
export interface ToggleOptions {
  /** Whether it is pressed. */
  pressed?: boolean
  /** Whether it can't be used. */
  disabled?: boolean
  /** Called with the state a press asks for. */
  onPressedChange?: (pressed: boolean) => void
}

/** The ARIA and data attributes a toggle renders, as Radix's `Toggle`. */
export function toggleStateAttributes({ pressed = false, disabled = false }: ToggleOptions = {}): {
  'aria-pressed': 'true' | 'false'
  'data-state': ToggleState
  'data-disabled': '' | undefined
} {
  return {
    'aria-pressed': pressed ? 'true' : 'false',
    'data-state': pressed ? 'on' : 'off',
    'data-disabled': disabled ? '' : undefined,
  }
}

/**
 * What makes an element of your own a toggle, for a `part()` modifier: `aria-pressed`,
 * `data-state` and `data-disabled`, and a click that asks `onPressedChange` for the other state.
 * The state is the caller's (it's controlled): pass it back as `pressed`.
 *
 *   const asToggle = part((options: ToggleOptions) => toggleSpec(options))
 *   <a href="#" {{asToggle pressed=this.bold onPressedChange=this.setBold}}>Bold</a>
 *
 * The styled `asToggle` from `@ember-joinery/ember` is this, with the styles.
 */
export function toggleSpec(options: ToggleOptions): PartSpec {
  const { pressed = false, disabled = false, onPressedChange } = options
  return {
    attributes: { ...toggleStateAttributes(options), disabled },
    on: {
      click: () => {
        if (!disabled) onPressedChange?.(!pressed)
      },
    },
  }
}

export interface ToggleSignature {
  Args: {
    /** The controlled state. */
    pressed?: boolean
    /** The first state, when uncontrolled. Default `false`. */
    defaultPressed?: boolean
    /** Called with each new state a press asks for. */
    onPressedChange?: (pressed: boolean) => void
    /** Whether it can't be pressed. */
    disabled?: boolean
    /** The tag to render. Default `button`. */
    as?: TagName
    /** Its name, for `ToggleHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** Its content, given whether it is pressed. */
    default: [pressed: boolean]
  }
  /** A `<button>`, or the tag `@as` names. */
  Element: HTMLButtonElement
}

/**
 * A two-state button that can be either on or off: Radix's `Toggle`, headless, which also
 * covers ember-primitives' `Toggle`. It is a `<button type="button">` with `aria-pressed` and
 * `data-state` (`on` or `off`), which a click, Enter or Space flips. Its state is controlled or
 * not, as in Radix:
 *
 *   <Toggle @pressed={{this.bold}} @onPressedChange={{this.setBold}} aria-label="Bold">B</Toggle>
 *   <Toggle @defaultPressed={{true}} as |pressed|>{{if pressed "On" "Off"}}</Toggle>
 */
export class Toggle extends Component<ToggleSignature> {
  pressed = controllable(this, 'pressed', false)

  get isPressed(): boolean {
    return this.pressed.value
  }

  /** Flips it, unless a listener of the caller's called `preventDefault()` first. */
  toggle = (event: MouseEvent): void => {
    if (event.defaultPrevented || this.args.disabled) return
    this.pressed.set(pressed => !pressed)
  }

  <template>
    <As
      @as={{@as}}
      @tag="button"
      type="button"
      aria-pressed={{if this.isPressed "true" "false"}}
      data-state={{if this.isPressed "on" "off"}}
      data-disabled={{if @disabled ""}}
      disabled={{@disabled}}
      data-test-jn="toggle"
      data-test-jn-name={{@name}}
      ...attributes
      {{on "click" this.toggle}}
    >{{yield this.isPressed}}</As>
  </template>
}

export default Toggle
