import Component from '@glimmer/component'
import { get } from '@ember/helper'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'

/** How a button looks: shadcn's six variants. */
export type ButtonVariant = 'default' | 'outline' | 'secondary' | 'ghost' | 'destructive' | 'link'

/** How big a button is. The `icon` sizes are square, for a button with only an icon. */
export type ButtonSize = 'default' | 'xs' | 'sm' | 'lg' | 'icon' | 'icon-xs' | 'icon-sm' | 'icon-lg'

/** A button's look: what both `<Button>` and the `asButton` modifier take. */
export interface ButtonOptions {
  /** Default `default`. */
  variant?: ButtonVariant
  /** Default `default`. */
  size?: ButtonSize
  /** The button's name, for its harness (`data-test-jn-name`). */
  name?: string
}

/**
 * The classes a button renders: upstream's semantic classes, renamed `jn-` (`jn-button
 * jn-button-variant-outline jn-button-size-sm`), which the style sheets style, and the
 * `group/button` marker other components' rules look for.
 */
export function buttonClasses({
  variant = 'default',
  size = 'default',
}: ButtonOptions = {}): string {
  return `jn-button group/button jn-button-variant-${variant} jn-button-size-${size}`
}

/** The data attributes a button renders: upstream's, and its harness's. */
export interface ButtonAttributes {
  'data-slot': 'button'
  'data-variant': ButtonVariant
  'data-size': ButtonSize
  'data-test-jn': 'button'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

/** The data attributes a button renders, as upstream's and for its harness. */
export function buttonAttributes({
  variant = 'default',
  size = 'default',
  name,
}: ButtonOptions = {}): ButtonAttributes {
  return {
    'data-slot': 'button',
    'data-variant': variant,
    'data-size': size,
    'data-test-jn': 'button',
    'data-test-jn-name': name,
  }
}

/**
 * Makes any element or component a button, as upstream's `asChild` (and `buttonVariants`) do:
 * it adds the button's classes and attributes, and keeps them current.
 *
 *   <LinkTo @route="login" {{asButton}}>Login</LinkTo>
 *   <a href="/docs" {{asButton variant="outline" size="sm"}}>Docs</a>
 *
 * It isn't named `button`: in a template, a binding by that name would turn every `<button>`
 * element into a call to it.
 */
export const asButton: PartModifier<HTMLElement, ButtonOptions> = part<HTMLElement, ButtonOptions>(
  options => ({ class: buttonClasses(options), attributes: buttonAttributes(options) }),
)

export interface ButtonSignature {
  Args: ButtonOptions & {
    /**
     * The tag to render instead of `button`, such as `a` for a link that looks like a button
     * (`<Button @as="a" href="/login">`). For a component, such as `LinkTo`, use the
     * `asButton` modifier.
     */
    as?: TagName
  }
  Blocks: {
    /** The label, and any icons (mark an icon's side with `data-icon="inline-start"` or `"inline-end"`). */
    default: []
  }
  /** A `<button>`, or with `@as="a"`, a link. */
  Element: HTMLButtonElement | HTMLAnchorElement
}

/**
 * Displays a button or a component that looks like a button: shadcn's Button. It renders a
 * native `<button>`, so it takes `type`, `disabled` and its listeners as attributes:
 *
 *   <Button @variant="outline" @size="sm" type="submit" {{on "click" this.save}}>Save</Button>
 *
 * Like upstream's (and the native element), it doesn't set `type`, so in a form it submits.
 */
export default class Button extends Component<ButtonSignature> {
  get options(): ButtonOptions {
    return { variant: this.args.variant, size: this.args.size, name: this.args.name }
  }

  /** What `asButton` adds too, from the same functions, so both render the same. */
  get classes(): string {
    return buttonClasses(this.options)
  }

  get attributes(): ButtonAttributes {
    return buttonAttributes(this.options)
  }

  // Rendered in the template, not by the modifier, so a server-rendered page is styled; a test
  // checks the two render the same attributes.
  <template>
    <As
      @as={{@as}}
      @tag="button"
      class={{this.classes}}
      data-slot={{get this.attributes "data-slot"}}
      data-variant={{get this.attributes "data-variant"}}
      data-size={{get this.attributes "data-size"}}
      data-test-jn={{get this.attributes "data-test-jn"}}
      data-test-jn-name={{get this.attributes "data-test-jn-name"}}
      ...attributes
    >{{yield}}</As>
  </template>
}
