import Component from '@glimmer/component'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'

/** How a button looks: shadcn's six variants. */
export type ButtonVariant = 'default' | 'outline' | 'secondary' | 'ghost' | 'destructive' | 'link'

/** How big a button is. The `icon` sizes are square, for a button with only an icon. */
export type ButtonSize = 'default' | 'xs' | 'sm' | 'lg' | 'icon' | 'icon-xs' | 'icon-sm' | 'icon-lg'

/** A button's look: what both `<Button>` and the `button` modifier take. */
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

/** The data attributes a button renders, as upstream's and for its harness. */
export function buttonAttributes({
  variant = 'default',
  size = 'default',
  name,
}: ButtonOptions = {}): Record<string, string | undefined> {
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
 *   <LinkTo @route="login" {{button}}>Login</LinkTo>
 *   <a href="/docs" {{button variant="outline" size="sm"}}>Docs</a>
 */
export const button: PartModifier<HTMLElement, ButtonOptions> = part<HTMLElement, ButtonOptions>(
  options => ({ class: buttonClasses(options), attributes: buttonAttributes(options) }),
)

export interface ButtonSignature {
  Args: ButtonOptions & {
    /**
     * The tag to render instead of `button`, such as `a` for a link that looks like a button
     * (`<Button @as="a" href="/login">`). For a component, such as `LinkTo`, use the `button`
     * modifier.
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
  get variant(): ButtonVariant {
    return this.args.variant ?? 'default'
  }

  get size(): ButtonSize {
    return this.args.size ?? 'default'
  }

  get classes(): string {
    return buttonClasses({ variant: this.variant, size: this.size })
  }

  <template>
    <As
      @as={{@as}}
      @tag="button"
      class={{this.classes}}
      data-slot="button"
      data-variant={{this.variant}}
      data-size={{this.size}}
      data-test-jn="button"
      data-test-jn-name={{@name}}
      ...attributes
    >{{yield}}</As>
  </template>
}
