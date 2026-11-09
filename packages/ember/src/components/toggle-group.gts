import Component from '@glimmer/component'
import { get, hash } from '@ember/helper'
import { htmlSafe, type SafeString } from '@ember/template'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import type { Direction } from '@ember-joinery/primitives/direction'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import {
  ToggleGroupState,
  type ToggleGroupItemOptions,
  type ToggleGroupType,
  type ToggleGroupValue,
} from '@ember-joinery/primitives/toggle-group'
import { toggleClasses, type ToggleSize, type ToggleVariant } from './toggle.gts'

/** Which way a toggle group's items run. */
export type ToggleGroupOrientation = 'horizontal' | 'vertical'

/** An item's look: its own `variant` and `size`, which the group's win over, and the spacing. */
export interface ToggleGroupItemStyle {
  /** Default `default`. The group's `@variant` wins over it. */
  variant?: ToggleVariant
  /** Default `default`. The group's `@size` wins over it. */
  size?: ToggleSize
  /** The group's `@spacing`. */
  spacing?: number
}

/**
 * The classes a toggle group's item renders: `jn-toggle-group-item`, then a toggle's (see
 * `toggleClasses`), as upstream's item adds `toggleVariants` to its own.
 */
export function toggleGroupItemClasses({
  variant = 'default',
  size = 'default',
}: ToggleGroupItemStyle = {}): string {
  return `jn-toggle-group-item ${toggleClasses({ variant, size })}`
}

/** The data attributes a toggle group's item renders, as upstream's. */
export interface ToggleGroupItemAttributes {
  'data-slot': 'toggle-group-item'
  'data-variant': ToggleVariant
  'data-size': ToggleSize
  'data-spacing': string
  [attribute: string]: string | undefined
}

/** The data attributes a toggle group's item renders, as upstream's. */
export function toggleGroupItemAttributes({
  variant = 'default',
  size = 'default',
  spacing = 2,
}: ToggleGroupItemStyle = {}): ToggleGroupItemAttributes {
  return {
    'data-slot': 'toggle-group-item',
    'data-variant': variant,
    'data-size': size,
    'data-spacing': String(spacing),
  }
}

/** The look an item takes from its group and its own arguments, the group's first. */
function itemStyle(
  group: ToggleGroupItemStyle,
  own: Pick<ToggleGroupItemStyle, 'variant' | 'size'>,
): ToggleGroupItemStyle {
  return {
    variant: group.variant || own.variant || 'default',
    size: group.size || own.size || 'default',
    spacing: group.spacing,
  }
}

/**
 * `--gap`, the spacing between items, as upstream's inline style sets it. A number Joinery
 * reads from `@spacing`, so it is safe to bind as a style; a `style` of your own replaces it.
 */
function gapStyle(spacing: number): SafeString {
  return htmlSafe(`--gap: ${Number(spacing)}`)
}

export interface ToggleGroupItemSignature {
  Args: Pick<ToggleGroupItemStyle, 'variant' | 'size'> & {
    /** The item's value, unique in its group. */
    value: string
    /** Whether it can't be pressed. */
    disabled?: boolean
    /** The tag to render. Default `button`. */
    as?: TagName
    /** @internal Bound by the group. */
    group: ToggleGroupState
    /** @internal Bound by the group. */
    groupStyle: ToggleGroupItemStyle
  }
  Blocks: {
    /** Its content, given whether it is pressed. */
    default: [pressed: boolean]
  }
  Element: HTMLButtonElement
}

/** One of a toggle group's items, yielded as `g.Item`: a toggle, sized and spaced by its group. */
class ToggleGroupItem extends Component<ToggleGroupItemSignature> {
  get style(): ToggleGroupItemStyle {
    return itemStyle(this.args.groupStyle, this.args)
  }

  get classes(): string {
    return toggleGroupItemClasses(this.style)
  }

  get attributes(): ToggleGroupItemAttributes {
    return toggleGroupItemAttributes(this.style)
  }

  <template>
    <As
      @as={{@as}}
      @tag="button"
      type="button"
      class={{this.classes}}
      data-slot={{get this.attributes "data-slot"}}
      data-variant={{get this.attributes "data-variant"}}
      data-size={{get this.attributes "data-size"}}
      data-spacing={{get this.attributes "data-spacing"}}
      ...attributes
      {{@group.item value=@value disabled=@disabled}}
    >{{yield (@group.isPressed @value)}}</As>
  </template>
}

/** What the styled `item` modifier takes: the item, and its own look. */
export type ToggleGroupItemModifierOptions = ToggleGroupItemOptions &
  Pick<ToggleGroupItemStyle, 'variant' | 'size'>

/** What `<ToggleGroup>` yields. */
export interface ToggleGroupYield<T extends ToggleGroupType> {
  /** An item: `<g.Item @value="bold" aria-label="Toggle bold">`. */
  Item: WithBoundArgs<typeof ToggleGroupItem, 'group' | 'groupStyle'>
  /**
   * An item, as a modifier on your own element or component, with the same classes and
   * attributes as `g.Item`: `<button type="button" {{g.item value="bold"}}>`.
   */
  item: PartModifier<HTMLElement, ToggleGroupItemModifierOptions>
  /** The value: the pressed item's (`''` for none), or the pressed items'. */
  value: ToggleGroupValue<T>
  /** Whether an item is pressed: `(g.isPressed "bold")`. */
  isPressed: (value: string) => boolean
}

export interface ToggleGroupSignature<T extends ToggleGroupType> {
  Args: {
    /** `single`: one item pressed at a time, or none. `multiple`: any number. */
    type: T
    /** The controlled value. */
    value?: ToggleGroupValue<T>
    /** The first value, when uncontrolled. */
    defaultValue?: ToggleGroupValue<T>
    /** Called with each new value. */
    onValueChange?: (value: ToggleGroupValue<T>) => void
    /** Every item's variant. Without it, each item's own (default `default`). */
    variant?: ToggleVariant
    /** Every item's size. Without it, each item's own (default `default`). */
    size?: ToggleSize
    /** The space between items, in Tailwind's spacing steps (0.25rem). Default 2; 0 joins them. */
    spacing?: number
    /** Which way the items run, and the arrow keys move. Default `horizontal`. */
    orientation?: ToggleGroupOrientation
    /** Whether no item can be pressed. */
    disabled?: boolean
    /** Whether Tab stops once, with the arrow keys moving between items. Default `true`. */
    rovingFocus?: boolean
    /** Whether the arrows wrap round from the last item to the first. Default `true`. */
    loop?: boolean
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `ToggleGroupHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [ToggleGroupYield<T>] }
  Element: HTMLDivElement
}

/**
 * A set of two-state buttons that can be toggled on or off: shadcn's Toggle Group, on the
 * primitives' `ToggleGroupState`. Its items are toggles, which take the group's `@variant` and
 * `@size`, spaced by `@spacing`:
 *
 *   <ToggleGroup @type="multiple" @variant="outline" as |g|>
 *     <g.Item @value="bold" aria-label="Toggle bold"><Icon @icon={{Bold}} /></g.Item>
 *     <g.Item @value="italic" aria-label="Toggle italic"><Icon @icon={{Italic}} /></g.Item>
 *   </ToggleGroup>
 *
 * The items share one tab stop, and the arrow keys along `@orientation` move between them.
 */
export default class ToggleGroup<T extends ToggleGroupType = 'single'> extends Component<
  ToggleGroupSignature<T>
> {
  group = new ToggleGroupState({
    type: () => this.args.type,
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    onValueChange: () => this.args.onValueChange as ((value: never) => void) | undefined,
    disabled: () => this.args.disabled,
    rovingFocus: () => this.args.rovingFocus,
    orientation: () => this.orientation,
    dir: () => this.args.dir,
    loop: () => this.args.loop,
  })

  get spacing(): number {
    return this.args.spacing ?? 2
  }

  get orientation(): ToggleGroupOrientation {
    return this.args.orientation ?? 'horizontal'
  }

  get groupStyle(): ToggleGroupItemStyle {
    return { variant: this.args.variant, size: this.args.size, spacing: this.spacing }
  }

  get value(): ToggleGroupValue<T> {
    return this.group.value as ToggleGroupValue<T>
  }

  /** The items' modifier: the primitive's behaviour, with the styled item's look. */
  item: PartModifier<HTMLElement, ToggleGroupItemModifierOptions> = part<
    HTMLElement,
    ToggleGroupItemModifierOptions
  >(named => {
    const spec = this.group.itemSpec(named)
    const style = itemStyle(this.groupStyle, named)
    return {
      ...spec,
      class: toggleGroupItemClasses(style),
      attributes: { ...spec.attributes, ...toggleGroupItemAttributes(style) },
    }
  })

  <template>
    <As
      @as={{@as}}
      @tag="div"
      role="group"
      dir={{@dir}}
      class="jn-toggle-group group/toggle-group"
      data-slot="toggle-group"
      data-variant={{@variant}}
      data-size={{@size}}
      data-spacing={{this.spacing}}
      data-orientation={{this.orientation}}
      data-test-jn="toggle-group"
      data-test-jn-name={{@name}}
      style={{gapStyle this.spacing}}
      ...attributes
      {{this.group.group}}
    >
      {{yield
        (hash
          Item=(component ToggleGroupItem group=this.group groupStyle=this.groupStyle)
          item=this.item
          value=this.value
          isPressed=this.group.isPressed
        )
      }}
    </As>
  </template>
}
