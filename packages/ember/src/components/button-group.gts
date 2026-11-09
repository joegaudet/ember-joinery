import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import { separatorPartAria, type Orientation } from '../-private/separator-aria.ts'

/** Which way a button group runs: a row, or a column. */
export type ButtonGroupOrientation = 'horizontal' | 'vertical'

/** What a button group takes. */
export interface ButtonGroupOptions {
  /** Default `horizontal`. */
  orientation?: ButtonGroupOrientation
}

/**
 * The classes a button group renders: upstream's semantic classes, renamed `jn-`
 * (`jn-button-group jn-button-group-orientation-horizontal`), and the `group/button-group`
 * marker, as upstream's `buttonGroupVariants` gives them.
 */
export function buttonGroupClasses({
  orientation = 'horizontal',
}: ButtonGroupOptions = {}): string {
  return `jn-button-group group/button-group jn-button-group-orientation-${orientation}`
}

function orientationOf(orientation: ButtonGroupOrientation | undefined): ButtonGroupOrientation {
  return orientation ?? 'horizontal'
}

/** What the separator part takes, as a component and as a modifier. */
export interface ButtonGroupSeparatorOptions {
  /** Default `vertical`: a line between two buttons in a row. */
  orientation?: Orientation
  /** Whether assistive technology skips it. Default `true`, as upstream's. */
  decorative?: boolean
}

export interface ButtonGroupSeparatorSignature {
  Args: ButtonGroupSeparatorOptions & {
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Element: HTMLElement
}

const SEPARATOR_CLASS = 'jn-button-group-separator'

function separatorAttributes({ orientation, decorative }: ButtonGroupSeparatorOptions = {}): Record<
  string,
  string | undefined
> {
  return {
    'data-slot': 'button-group-separator',
    ...separatorPartAria(orientation, decorative, 'vertical'),
    'data-test-jn-part': 'separator',
  }
}

/**
 * A line between two buttons, in the input colour: upstream's Separator, vertical by default
 * and decorative unless you say. Outline buttons have borders and need none.
 */
const Separator: TOC<ButtonGroupSeparatorSignature> = <template>
  {{#let (separatorAttributes orientation=@orientation decorative=@decorative) as |attributes|}}
    <As
      @as={{@as}}
      class={{SEPARATOR_CLASS}}
      data-slot={{get attributes "data-slot"}}
      role={{get attributes "role"}}
      aria-orientation={{get attributes "aria-orientation"}}
      data-orientation={{get attributes "data-orientation"}}
      data-test-jn-part={{get attributes "data-test-jn-part"}}
      ...attributes
    />
  {{/let}}
</template>

export interface ButtonGroupTextSignature {
  Args: {
    /**
     * The tag to render instead of `div`, such as `label` for one that names the input beside
     * it (`<g.Text @as="label" for="name">`). For a component, use the `text` modifier.
     */
    as?: TagName
  }
  Blocks: { default: [] }
  /** A `<div>`, or with `@as="label"`, a label. */
  Element: HTMLDivElement | HTMLLabelElement
}

const TEXT_CLASS = 'jn-button-group-text'

/**
 * Text in the group, on a muted tile with a border, as tall as the buttons. Like upstream's it
 * has no `data-slot`, so the group's rounding treats the controls around it as the ends.
 */
const Text: TOC<ButtonGroupTextSignature> = <template>
  <As @as={{@as}} class={{TEXT_CLASS}} data-test-jn-part="text" ...attributes>{{yield}}</As>
</template>

/** What a button group yields: its parts, each as a component and as a modifier. */
export interface ButtonGroupParts {
  /** A line between two buttons. */
  Separator: ComponentLike<ButtonGroupSeparatorSignature>
  /** Text beside the buttons or an input. */
  Text: ComponentLike<ButtonGroupTextSignature>
  /** `<span {{g.separator}}>`: makes your own element the separator. */
  separator: PartModifier<HTMLElement, ButtonGroupSeparatorOptions>
  /** `<Label {{g.text}}>`: makes your own element or component the text. */
  text: PartModifier<HTMLElement>
}

const PARTS: ButtonGroupParts = {
  Separator,
  Text,
  separator: part<HTMLElement, ButtonGroupSeparatorOptions>(options => ({
    class: SEPARATOR_CLASS,
    attributes: separatorAttributes(options),
  })),
  text: part<HTMLElement>(() => ({
    class: TEXT_CLASS,
    attributes: { 'data-test-jn-part': 'text' },
  })),
}

export interface ButtonGroupSignature {
  Args: ButtonGroupOptions & {
    /** The tag to render instead of `div`. */
    as?: TagName
    /** The group's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** Buttons, inputs, nested groups, and the group's parts. */
    default: [ButtonGroupParts]
  }
  Element: HTMLElement
}

/**
 * A container that groups related buttons together with consistent styling: shadcn's Button
 * Group. The buttons join into one control, their inner corners square and their shared
 * borders one line; nested groups sit apart, with a gap. It has the `group` role: name it with
 * `aria-label` or `aria-labelledby`.
 *
 *   <ButtonGroup aria-label="Text formatting" as |g|>
 *     <Button @variant="secondary">Copy</Button>
 *     <g.Separator />
 *     <Button @variant="secondary">Paste</Button>
 *   </ButtonGroup>
 *
 * For buttons that toggle a state, use Toggle Group instead.
 */
const ButtonGroup: TOC<ButtonGroupSignature> = <template>
  <As
    @as={{@as}}
    role="group"
    class={{buttonGroupClasses orientation=@orientation}}
    data-slot="button-group"
    data-orientation={{orientationOf @orientation}}
    data-test-jn="button-group"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</As>
</template>

export default ButtonGroup
