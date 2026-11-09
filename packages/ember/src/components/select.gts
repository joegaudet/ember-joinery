import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { Check, ChevronDown, ChevronUp } from 'lucide'
import type { TagName } from '@ember-joinery/primitives/as'
import type { Align, Placement } from '@ember-joinery/primitives/anchor'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  Select as SelectPrimitive,
  type SelectArgs,
  type SelectBlockParams as SelectPrimitiveBlockParams,
  type SelectContentArgs,
  type SelectPosition,
} from '@ember-joinery/primitives/select'
import Icon, { type IconNode } from './icon.gts'

/** How big a select's trigger is. */
export type SelectSize = 'sm' | 'default'

/** `@align`, or upstream's `center` unless a `@placement` decides it. */
function alignOf(align: Align | undefined, placement: Placement | undefined): Align | undefined {
  return align ?? (placement ? undefined : 'center')
}

function positionOf(position: SelectPosition | undefined): SelectPosition {
  return position ?? 'item-aligned'
}

function isItemAligned(position: SelectPosition | undefined): 'true' | 'false' {
  return positionOf(position) === 'item-aligned' ? 'true' : 'false'
}

// ----- Trigger and value ---------------------------------------------------------------------

export interface SelectTriggerSignature {
  Args: {
    /** Default `default` (32px tall); `sm` is 28px. */
    size?: SelectSize
    /** The icon at its end. Default lucide's `chevron-down`, upstream's `ChevronDownIcon`. */
    icon?: IconNode
    /** The tag to render instead of `button`. */
    as?: TagName
    /** @internal The primitive's Trigger, bound by the select. */
    Part: SelectPrimitiveBlockParams['Trigger']
  }
  /** The `Value`, and anything beside it (an icon). */
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/**
 * The button that opens the select, upstream's `SelectTrigger`: its value and a chevron, hidden
 * from assistive technology (Radix's `Select.Icon` around it, `asChild`). The icon keeps
 * `jn-size-own`: upstream's registry build gives it its style rule's `size-4`, which the
 * trigger's `svg:not([class*='size-'])` rule looks for, as upstream's.
 */
const SelectTrigger: TOC<SelectTriggerSignature> = <template>
  <@Part
    @as={{@as}}
    class="jn-select-trigger"
    data-slot="select-trigger"
    data-size={{if @size @size "default"}}
    ...attributes
  >
    {{yield}}
    <Icon
      @icon={{if @icon @icon ChevronDown}}
      class="jn-select-trigger-icon jn-size-own"
      aria-hidden="true"
      data-test-jn-part="icon"
    />
  </@Part>
</template>

export interface SelectValueSignature {
  Args: {
    /** What it shows while no option is chosen. */
    placeholder?: string
    /** @internal The primitive's Value, bound by the select. */
    Part: SelectPrimitiveBlockParams['Value']
  }
  /** Your own content for the chosen value, in place of the option's text. */
  Blocks: { default: [] }
  Element: HTMLSpanElement
}

/** The chosen option's text, or the placeholder: upstream's `SelectValue`. */
const SelectValue: TOC<SelectValueSignature> = <template>
  {{#if (has-block)}}
    <@Part @placeholder={{@placeholder}} data-slot="select-value" ...attributes>{{yield}}</@Part>
  {{else}}
    <@Part @placeholder={{@placeholder}} data-slot="select-value" ...attributes />
  {{/if}}
</template>

// ----- Content -------------------------------------------------------------------------------

export interface SelectContentSignature {
  Args: SelectContentArgs & {
    /** @internal The primitive's parts, bound by the select. */
    Part: SelectPrimitiveBlockParams['Content']
    Viewport: SelectPrimitiveBlockParams['Viewport']
    ScrollUpButton: SelectPrimitiveBlockParams['ScrollUpButton']
    ScrollDownButton: SelectPrimitiveBlockParams['ScrollDownButton']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The list of options, upstream's `SelectContent`: over its trigger with the chosen option on
 * the value (`item-aligned`, the default), or below it (`@position="popper"`, centred, as
 * upstream's `align` default), with scroll buttons at each end while the options scroll.
 *
 * Upstream also marks it `cn-menu-translucent`, a class ui.shadcn.com leaves unstyled (only a
 * translucent menu colour, which its docs don't show, styles it); Joinery's ported sheet would
 * style it, so it is left off, and the menu is opaque, as on ui.shadcn.com.
 */
const SelectContent: TOC<SelectContentSignature> = <template>
  <@Part
    @position={{@position}}
    @as={{@as}}
    @side={{@side}}
    @align={{alignOf @align @placement}}
    @sideOffset={{@sideOffset}}
    @alignOffset={{@alignOffset}}
    @avoidCollisions={{@avoidCollisions}}
    @collisionPadding={{@collisionPadding}}
    @arrowPadding={{@arrowPadding}}
    @sticky={{@sticky}}
    @hideWhenDetached={{@hideWhenDetached}}
    @placement={{@placement}}
    @offsetOptions={{@offsetOptions}}
    @flipOptions={{@flipOptions}}
    @shiftOptions={{@shiftOptions}}
    @middleware={{@middleware}}
    @strategy={{@strategy}}
    @onCloseAutoFocus={{@onCloseAutoFocus}}
    @onEscapeKeyDown={{@onEscapeKeyDown}}
    @onPointerDownOutside={{@onPointerDownOutside}}
    class="jn-select-content jn-menu-target"
    data-slot="select-content"
    data-align-trigger={{isItemAligned @position}}
    ...attributes
  >
    <@ScrollUpButton class="jn-select-scroll-up-button" data-slot="select-scroll-up-button">
      <Icon @icon={{ChevronUp}} />
    </@ScrollUpButton>
    <@Viewport class="jn-select-viewport" data-position={{positionOf @position}}>
      {{yield}}
    </@Viewport>
    <@ScrollDownButton class="jn-select-scroll-down-button" data-slot="select-scroll-down-button">
      <Icon @icon={{ChevronDown}} />
    </@ScrollDownButton>
  </@Part>
</template>

// ----- Items ---------------------------------------------------------------------------------

export interface SelectItemSignature {
  Args: {
    /** The option's value: what `@value` and `@onValueChange` carry. It can't be `''`. */
    value: string
    /** Makes it impossible to choose. */
    disabled?: boolean
    /** The text typeahead matches, when the option's text isn't plain. */
    textValue?: string
    /** The check mark shown while it is chosen. Default lucide's `check`. */
    icon?: IconNode
    /** The tag to render instead of `div`. */
    as?: TagName
    /** @internal The primitive's Item, bound by the select. */
    Part: SelectPrimitiveBlockParams['Item']
  }
  /** The option's text (and any icon): what the value shows when it is chosen. */
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** One option, upstream's `SelectItem`: its text, and a check mark at its end while chosen. */
const SelectItem: TOC<SelectItemSignature> = <template>
  <@Part
    @value={{@value}}
    @disabled={{@disabled}}
    @textValue={{@textValue}}
    @as={{@as}}
    class="jn-select-item"
    data-slot="select-item"
    ...attributes
    as |item|
  >
    <span class="jn-select-item-indicator">
      <item.ItemIndicator>
        <Icon @icon={{if @icon @icon Check}} class="jn-select-item-indicator-icon" />
      </item.ItemIndicator>
    </span>
    <item.ItemText>{{yield}}</item.ItemText>
  </@Part>
</template>

interface PartSignature<Part> {
  Args: {
    /** The tag to render instead. */
    as?: TagName
    /** @internal The primitive's part, bound by the select. */
    Part: Part
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** Options that belong together, upstream's `SelectGroup`, named by its Label. */
const SelectGroup: TOC<PartSignature<SelectPrimitiveBlockParams['Group']>> = <template>
  <@Part @as={{@as}} class="jn-select-group" data-slot="select-group" ...attributes>
    {{yield}}
  </@Part>
</template>

/** The label of a group, upstream's `SelectLabel`. */
const SelectLabel: TOC<PartSignature<SelectPrimitiveBlockParams['Label']>> = <template>
  <@Part @as={{@as}} class="jn-select-label" data-slot="select-label" ...attributes>
    {{yield}}
  </@Part>
</template>

/** A line between options or groups, upstream's `SelectSeparator`, hidden from assistive technology. */
const SelectSeparator: TOC<PartSignature<SelectPrimitiveBlockParams['Separator']>> = <template>
  <@Part @as={{@as}} class="jn-select-separator" data-slot="select-separator" ...attributes />
</template>

// ----- The select ----------------------------------------------------------------------------

/** What a `<Select>` yields: its parts, the trigger's modifier, and its state. */
export interface SelectBlockParams {
  /** The button that opens it, with a chevron at its end (`@size`). */
  Trigger: WithBoundArgs<typeof SelectTrigger, 'Part'>
  /** The chosen option's text, or `@placeholder`. Put it in the Trigger. */
  Value: WithBoundArgs<typeof SelectValue, 'Part'>
  /** The list of options, in the top layer while open (`@position`). */
  Content: WithBoundArgs<
    typeof SelectContent,
    'Part' | 'Viewport' | 'ScrollUpButton' | 'ScrollDownButton'
  >
  /** One option: `<s.Item @value="apple">Apple</s.Item>`. */
  Item: WithBoundArgs<typeof SelectItem, 'Part'>
  /** Options that belong together. */
  Group: WithBoundArgs<typeof SelectGroup, 'Part'>
  /** The label of the group it is in. */
  Label: WithBoundArgs<typeof SelectLabel, 'Part'>
  /** A line between options or groups. */
  Separator: WithBoundArgs<typeof SelectSeparator, 'Part'>
  /** An arrow pointing at the trigger, in the `popper` position (Radix's, unstyled). */
  Arrow: SelectPrimitiveBlockParams['Arrow']
  /** Makes your own element or component the trigger (unstyled): `<Button {{s.trigger}}>`. */
  trigger: PartModifier
  /** The chosen value, or `''`. */
  value: string
  /** Whether it is open. */
  isOpen: boolean
  /** Opens (`true`) or closes (`false`) it. */
  setOpen: (open: boolean) => void
  /** Chooses a value. */
  setValue: (value: string) => void
}

export interface SelectSignature {
  Args: SelectArgs
  Blocks: { default: [SelectBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * Displays a list of options for the user to pick from, triggered by a button: shadcn's Select,
 * on the primitives' headless one (Radix's). It renders no box of its own, and yields its
 * parts:
 *
 *   <Select as |s|>
 *     <s.Trigger class="w-[180px]"><s.Value @placeholder="Theme" /></s.Trigger>
 *     <s.Content>
 *       <s.Group>
 *         <s.Item @value="light">Light</s.Item>
 *         <s.Item @value="dark">Dark</s.Item>
 *       </s.Group>
 *     </s.Content>
 *   </Select>
 *
 * Its value and open state are its own, or yours (`@value` with `@onValueChange`, `@open` with
 * `@onOpenChange`). Name the trigger (`aria-label`, or a `<Label for>` with its `id`): a
 * combobox isn't named by its text.
 */
const Select: TOC<SelectSignature> = <template>
  <SelectPrimitive
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @open={{@open}}
    @defaultOpen={{@defaultOpen}}
    @onOpenChange={{@onOpenChange}}
    @dir={{@dir}}
    @formName={{@formName}}
    @autoComplete={{@autoComplete}}
    @disabled={{@disabled}}
    @required={{@required}}
    @form={{@form}}
    @name={{@name}}
    ...attributes
    as |s|
  >
    {{yield
      (hash
        Trigger=(component SelectTrigger Part=s.Trigger)
        Value=(component SelectValue Part=s.Value)
        Content=(component
          SelectContent
          Part=s.Content
          Viewport=s.Viewport
          ScrollUpButton=s.ScrollUpButton
          ScrollDownButton=s.ScrollDownButton
        )
        Item=(component SelectItem Part=s.Item)
        Group=(component SelectGroup Part=s.Group)
        Label=(component SelectLabel Part=s.Label)
        Separator=(component SelectSeparator Part=s.Separator)
        Arrow=s.Arrow
        trigger=s.trigger
        value=s.value
        isOpen=s.isOpen
        setOpen=s.setOpen
        setValue=s.setValue
      )
    }}
  </SelectPrimitive>
</template>

export default Select
