import Component from '@glimmer/component'
import { get } from '@ember/helper'
import type { TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import {
  Toggle as TogglePrimitive,
  toggleSpec,
  type ToggleOptions,
} from '@ember-joinery/primitives/toggle'

/** How a toggle looks: shadcn's two variants. */
export type ToggleVariant = 'default' | 'outline'

/** How big a toggle is. */
export type ToggleSize = 'default' | 'sm' | 'lg'

/** A toggle's look, as `<Toggle>`, the `asToggle` modifier and a toggle group's items take it. */
export interface ToggleStyle {
  /** Default `default`. */
  variant?: ToggleVariant
  /** Default `default`. */
  size?: ToggleSize
}

/**
 * The classes a toggle renders: upstream's `toggleVariants`, renamed `jn-` (`jn-toggle
 * jn-toggle-variant-outline jn-toggle-size-sm`), and the `group/toggle` marker an icon inside
 * can style itself by (`group-data-[state=on]/toggle:fill-foreground`).
 */
export function toggleClasses({ variant = 'default', size = 'default' }: ToggleStyle = {}): string {
  return `jn-toggle group/toggle jn-toggle-variant-${variant} jn-toggle-size-${size}`
}

/** The data attributes a toggle renders: upstream's, and its harness's. */
export interface ToggleAttributes {
  'data-slot': 'toggle'
  'data-variant': ToggleVariant
  'data-size': ToggleSize
  'data-test-jn': 'toggle'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

/** The data attributes a toggle renders, as upstream's and for its harness. */
export function toggleAttributes({
  variant = 'default',
  size = 'default',
  name,
}: ToggleStyle & { name?: string } = {}): ToggleAttributes {
  return {
    'data-slot': 'toggle',
    'data-variant': variant,
    'data-size': size,
    'data-test-jn': 'toggle',
    'data-test-jn-name': name,
  }
}

/** What the `asToggle` modifier takes: the state (it is controlled), the look and a name. */
export interface AsToggleOptions extends ToggleOptions, ToggleStyle {
  /** Its name, for `ToggleHarness` (`data-test-jn-name`). */
  name?: string
}

/**
 * Makes any element or component a toggle, as upstream's `asChild` does: the classes and
 * attributes `<Toggle>` renders, `aria-pressed` and `data-state`, and a click that asks
 * `onPressedChange` for the other state. The state is yours: pass it back as `pressed`.
 *
 *   <button type="button" {{asToggle pressed=this.bold onPressedChange=this.setBold}}>Bold</button>
 *
 * It isn't named `toggle`: name a binding after a component and it reads like one.
 */
export const asToggle: PartModifier<HTMLElement, AsToggleOptions> = part<
  HTMLElement,
  AsToggleOptions
>(options => {
  const spec = toggleSpec(options)
  return {
    ...spec,
    class: toggleClasses(options),
    attributes: { ...spec.attributes, ...toggleAttributes(options) },
  }
})

export interface ToggleSignature {
  Args: ToggleStyle & {
    /** The controlled state. */
    pressed?: boolean
    /** The first state, when uncontrolled. Default `false`. */
    defaultPressed?: boolean
    /** Called with each new state a press asks for. */
    onPressedChange?: (pressed: boolean) => void
    /** Whether it can't be pressed. */
    disabled?: boolean
    /** The tag to render. Default `button`. For a component of your own, use `asToggle`. */
    as?: TagName
    /** Its name, for `ToggleHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The label, and any icons, given whether it is pressed. */
    default: [pressed: boolean]
  }
  /** A `<button type="button">`, or the tag `@as` names. */
  Element: HTMLButtonElement
}

/**
 * A two-state button that can be either on or off: shadcn's Toggle, on the primitives'
 * `Toggle`. It renders a `<button type="button">` with `aria-pressed` and `data-state`, and
 * its state is controlled (`@pressed`, `@onPressedChange`) or its own (`@defaultPressed`):
 *
 *   <Toggle @variant="outline" @size="sm" aria-label="Toggle italic">
 *     <Icon @icon={{Italic}} /> Italic
 *   </Toggle>
 */
export default class Toggle extends Component<ToggleSignature> {
  get classes(): string {
    return toggleClasses(this.args)
  }

  get attributes(): ToggleAttributes {
    return toggleAttributes(this.args)
  }

  <template>
    <TogglePrimitive
      @pressed={{@pressed}}
      @defaultPressed={{@defaultPressed}}
      @onPressedChange={{@onPressedChange}}
      @disabled={{@disabled}}
      @as={{@as}}
      @name={{@name}}
      class={{this.classes}}
      data-slot={{get this.attributes "data-slot"}}
      data-variant={{get this.attributes "data-variant"}}
      data-size={{get this.attributes "data-size"}}
      ...attributes
      as |pressed|
    >{{yield pressed}}</TogglePrimitive>
  </template>
}
