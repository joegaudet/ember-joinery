import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import { Check, ChevronDown, X } from 'lucide'
import { As, type TagName } from '@ember-joinery/primitives/as'
import type { Align, Side } from '@ember-joinery/primitives/anchor'
import {
  Combobox as ComboboxPrimitive,
  type ComboboxArgs,
  type ComboboxBlockParams as ComboboxPrimitiveBlockParams,
  type ComboboxGroupBlockParams,
} from '@ember-joinery/primitives/combobox'
import type { PartModifier } from '@ember-joinery/primitives/part'
import { buttonClasses } from './button.gts'
import Icon, { type IconNode } from './icon.gts'
import { inputClasses } from './input.gts'
import {
  inputGroupAddonClasses,
  inputGroupButtonClasses,
  type InputGroupAddonOptions,
} from './input-group.gts'
import { t } from '@ember-joinery/primitives/i18n'
import { messages } from '../messages.ts'

// The classes of the buttons upstream renders as an `InputGroupButton` (ghost, `icon-xs`), and
// as a `Button` (a chip's remove button): Button's, then the group's own. ComboboxInput renders
// InputGroup's markup and classes (see it below), so input-group.css styles them.
const INPUT_GROUP_BUTTON = inputGroupButtonClasses({ variant: 'ghost', size: 'icon-xs' })
const TRIGGER_CLASSES = `${INPUT_GROUP_BUTTON} jn-combobox-trigger`
const CLEAR_CLASSES = `${INPUT_GROUP_BUTTON} jn-combobox-clear`
const CHIP_REMOVE_CLASSES = `${buttonClasses({ variant: 'ghost', size: 'icon-xs' })} jn-combobox-chip-remove`
const INPUT_CLASSES = `${inputClasses()} jn-input-group-input`
const ADDON_CLASSES = inputGroupAddonClasses({ align: 'inline-end' })

/** A press on the addon (not on a button in it) focuses the input, as upstream's InputGroupAddon. */
function focusInput(event: MouseEvent): void {
  if ((event.target as Element | null)?.closest('button')) return
  const addon = event.currentTarget as HTMLElement
  addon.parentElement?.querySelector('input')?.focus()
}

// ----- Trigger, clear, value -----------------------------------------------------------------

export interface ComboboxTriggerSignature {
  Args: {
    /** The chevron. Default lucide's `chevron-down`. */
    icon?: IconNode
    /** The tag to render instead of `button`. */
    as?: TagName
    /** @internal The primitive's Trigger, bound by the combobox. */
    Part: ComboboxPrimitiveBlockParams['Trigger']
  }
  /** What it shows before the chevron: the `Value`, for a combobox whose input is in its popup. */
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/**
 * A button that opens the list, upstream's `ComboboxTrigger`: its block and a chevron. For a
 * Button of your own, use the `trigger` modifier and the `TriggerIcon` (upstream's `render`).
 */
const ComboboxTrigger: TOC<ComboboxTriggerSignature> = <template>
  <@Part @as={{@as}} class="jn-combobox-trigger" data-slot="combobox-trigger" ...attributes>
    {{yield}}
    <ComboboxTriggerIcon @icon={{@icon}} />
  </@Part>
</template>

export interface ComboboxTriggerIconSignature {
  Args: {
    /** The chevron. Default lucide's `chevron-down`. */
    icon?: IconNode
  }
  Element: SVGSVGElement
}

/**
 * The trigger's chevron, hidden from assistive technology, for a trigger of your own:
 * `<Button {{c.trigger}}><c.Value /><c.TriggerIcon /></Button>`. It keeps `jn-size-own`:
 * upstream's registry build gives it its style rule's `size-4`, which a button's
 * `svg:not([class*='size-'])` rule looks for, as upstream's.
 */
const ComboboxTriggerIcon: TOC<ComboboxTriggerIconSignature> = <template>
  <Icon
    @icon={{if @icon @icon ChevronDown}}
    class="jn-combobox-trigger-icon jn-size-own"
    aria-hidden="true"
    data-test-jn-part="trigger-icon"
    ...attributes
  />
</template>

export interface ComboboxValueSignature {
  Args: {
    /** What it shows while nothing is chosen. */
    placeholder?: string
    /** @internal The primitive's Value, bound by the combobox. */
    Part: ComboboxPrimitiveBlockParams['Value']
  }
  /** Your own rendering of the chosen item, or items: `as |values|`. */
  // An item is whatever @items holds, so the template can read its fields.
  Blocks: { default: [value: any] }
}

/** The chosen item's label, or a block to render the value yourself: upstream's `ComboboxValue`. */
const ComboboxValue: TOC<ComboboxValueSignature> = <template>
  {{#if (has-block)}}
    <@Part @placeholder={{@placeholder}} as |value|>{{yield value}}</@Part>
  {{else}}
    <@Part @placeholder={{@placeholder}} />
  {{/if}}
</template>

export interface ComboboxClearSignature {
  Args: {
    /** What the icon-only button is called, for assistive technology. Default `Clear`. */
    label?: string
    /** @internal The primitive's Clear, bound by the combobox. */
    Part: ComboboxPrimitiveBlockParams['Clear']
  }
  Element: HTMLButtonElement
}

/**
 * Clears the input and the value, upstream's `ComboboxClear`: a ghost `icon-xs` group button,
 * rendered while there is something to clear. Upstream leaves it unnamed; Joinery names it
 * (`@label`), as an icon-only button must be.
 */
const ComboboxClear: TOC<ComboboxClearSignature> = <template>
  <@Part
    class={{CLEAR_CLASSES}}
    data-slot="combobox-clear"
    data-variant="ghost"
    data-size="icon-xs"
    aria-label={{if @label @label (t messages.comboboxClear)}}
    ...attributes
  >
    <Icon @icon={{X}} class="jn-combobox-clear-icon" />
  </@Part>
</template>

// ----- Inputs --------------------------------------------------------------------------------

export interface ComboboxInputAddonSignature {
  Args: InputGroupAddonOptions & {
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  /** An icon or text beside the input. */
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * An addon in the combobox's input group, as upstream puts an `InputGroupAddon` inside
 * `ComboboxInput`: Input Group's addon (`@align`, `inline-start` by default), whose press (not
 * on a button in it) focuses the input. It renders the addon's markup and classes, as the group
 * around it does (see `ComboboxInput`).
 */
const ComboboxInputAddon: TOC<ComboboxInputAddonSignature> = <template>
  <As
    @as={{@as}}
    class={{inputGroupAddonClasses align=@align}}
    role="group"
    data-slot="input-group-addon"
    data-align={{if @align @align "inline-start"}}
    data-test-jn-part="addon"
    {{on "click" focusInput}}
    ...attributes
  >{{yield}}</As>
</template>

/** What `<c.Input as |g|>` yields: an addon for the input group around the input. */
export interface ComboboxInputParts {
  /** Icons or text beside the input, upstream's `InputGroupAddon` (`@align`). */
  Addon: ComponentLike<ComboboxInputAddonSignature>
}

export interface ComboboxInputSignature {
  Args: {
    /** Show the chevron button that opens the list. Default `true`. */
    showTrigger?: boolean
    /** Show the button that clears the value, while there is one. Default `false`. */
    showClear?: boolean
    /** Disables the input and its buttons. */
    disabled?: boolean
    /** What the chevron button is called, for assistive technology. Default `Show options`. */
    triggerLabel?: string
    /** What the clear button is called. Default `Clear`. */
    clearLabel?: string
    /**
     * Classes for the input group around the input, where upstream's `className` goes
     * (`@groupClass="w-full"`); `class` goes on the `<input>`.
     */
    groupClass?: string
    /** @internal The primitive's parts, bound by the combobox. */
    Input: ComboboxPrimitiveBlockParams['Input']
    Trigger: ComboboxPrimitiveBlockParams['Trigger']
    Clear: ComboboxPrimitiveBlockParams['Clear']
  }
  /**
   * Addons after the input, as upstream's children: `as |g|`, then `<g.Addon>` with an icon at
   * its start.
   */
  Blocks: { default: [ComboboxInputParts] }
  /** The `<input>`: `placeholder`, `aria-invalid` and the rest go on it. */
  Element: HTMLInputElement
}

/**
 * The text input, upstream's `ComboboxInput`: an input group around the input, with the chevron
 * button (`@showTrigger`) and the clear button (`@showClear`) at its end. Attributes go on the
 * `<input>`, as upstream's other props do. Its `className` goes on the group, but an Ember
 * component has one `...attributes`: the group's classes are `@groupClass`.
 *
 * It renders InputGroup's markup and classes rather than `<InputGroup>`, as CommandInput does:
 * InputGroup's `data-test-jn="input-group"` root would make the input and its buttons that
 * group's parts, not the combobox's, so `ComboboxHarness` couldn't reach them.
 */
const ComboboxInput: TOC<ComboboxInputSignature> = <template>
  <div
    class="group/input-group jn-input-group jn-combobox-input {{@groupClass}}"
    role="group"
    data-slot="input-group"
    data-test-jn-part="input-group"
  >
    <@Input
      class={{INPUT_CLASSES}}
      data-slot="input-group-control"
      disabled={{@disabled}}
      ...attributes
    />
    <div
      class={{ADDON_CLASSES}}
      role="group"
      data-slot="input-group-addon"
      data-align="inline-end"
      {{on "click" focusInput}}
    >
      {{#unless (eq @showTrigger false)}}
        <@Trigger
          class={{TRIGGER_CLASSES}}
          data-slot="input-group-button"
          data-variant="ghost"
          data-size="icon-xs"
          disabled={{@disabled}}
          aria-label={{if @triggerLabel @triggerLabel (t messages.comboboxShowOptions)}}
        >
          <ComboboxTriggerIcon />
        </@Trigger>
      {{/unless}}
      {{#if @showClear}}
        <@Clear
          class={{CLEAR_CLASSES}}
          data-slot="combobox-clear"
          data-variant="ghost"
          data-size="icon-xs"
          disabled={{@disabled}}
          aria-label={{if @clearLabel @clearLabel (t messages.comboboxClear)}}
        >
          <Icon @icon={{X}} class="jn-combobox-clear-icon" />
        </@Clear>
      {{/if}}
    </div>
    {{yield (hash Addon=ComboboxInputAddon)}}
  </div>
</template>

function eq(a: unknown, b: unknown): boolean {
  return a === b
}

/** `@sideOffset`, or upstream's 6. */
function sideOffsetOf(sideOffset: number | undefined): number {
  return sideOffset ?? 6
}

export interface ComboboxChipsInputSignature {
  Args: {
    /** @internal The primitive's Input, bound by the combobox. */
    Input: ComboboxPrimitiveBlockParams['Input']
  }
  Element: HTMLInputElement
}

/** The input among the chips, upstream's `ComboboxChipsInput`: as wide as the room left. */
const ComboboxChipsInput: TOC<ComboboxChipsInputSignature> = <template>
  <@Input class="jn-combobox-chip-input" data-slot="combobox-chip-input" ...attributes />
</template>

// ----- Chips ---------------------------------------------------------------------------------

export interface ComboboxChipsSignature {
  Args: {
    /** @internal The primitive's chips modifier, bound by the combobox. */
    part: PartModifier
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The chips and their input, upstream's `ComboboxChips`, drawn as one field. A press on it (not
 * on a chip's button) focuses the input and opens the list. Place the list against it with
 * `<c.Content @anchor={{c.chipsElement}}>`, as upstream's `useComboboxAnchor`.
 */
const ComboboxChips: TOC<ComboboxChipsSignature> = <template>
  <div class="jn-combobox-chips" data-slot="combobox-chips" ...attributes {{@part}}>{{yield}}</div>
</template>

export interface ComboboxChipSignature {
  Args: {
    /** The chosen item this chip shows. */
    value: unknown
    /** Show the button that removes it. Default `true`. */
    showRemove?: boolean
    /** What the remove button is called, for assistive technology. Default `Remove`. */
    removeLabel?: string
    /** @internal The primitive's Chip, bound by the combobox. */
    Part: ComboboxPrimitiveBlockParams['Chip']
  }
  /** Its text. */
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * One chosen item, upstream's `ComboboxChip`: its text and a ghost `icon-xs` button that removes
 * it (`@showRemove`). Upstream leaves that button unnamed; Joinery names it (`@removeLabel`).
 */
const ComboboxChip: TOC<ComboboxChipSignature> = <template>
  <@Part
    @value={{@value}}
    class="jn-combobox-chip"
    data-slot="combobox-chip"
    ...attributes
    as |chip|
  >
    {{yield}}
    {{#unless (eq @showRemove false)}}
      <chip.Remove
        class={{CHIP_REMOVE_CLASSES}}
        data-slot="combobox-chip-remove"
        data-variant="ghost"
        data-size="icon-xs"
        aria-label={{if @removeLabel @removeLabel (t messages.comboboxRemove)}}
      >
        <Icon @icon={{X}} class="jn-combobox-chip-indicator-icon" />
      </chip.Remove>
    {{/unless}}
  </@Part>
</template>

// ----- Content and items ---------------------------------------------------------------------

export interface ComboboxContentSignature {
  Args: {
    /** The side of the input to place it on. Default `bottom`. */
    side?: Side
    /** Where along that side. Default `start`. */
    align?: Align
    /** The distance from the input, in pixels. Default 6. */
    sideOffset?: number
    /** The shift along the side, in pixels. Default 0. */
    alignOffset?: number
    /** What to place it against instead of the input: the chips (`c.chipsElement`). */
    anchor?: Element | null
    /** @internal The primitive's Content, bound by the combobox. */
    Part: ComboboxPrimitiveBlockParams['Content']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The popup, upstream's `ComboboxContent`: below the input, at its start, 6px off, at least as
 * wide as the input and its buttons (as wide as the chips, given them as `@anchor`).
 *
 * Upstream also marks it `cn-menu-translucent`, a class ui.shadcn.com leaves unstyled (only a
 * translucent menu colour, which its docs don't show, styles it); Joinery's ported sheet would
 * style it, so it is left off, and the popup is opaque, as on ui.shadcn.com.
 */
const ComboboxContent: TOC<ComboboxContentSignature> = <template>
  <@Part
    @side={{if @side @side "bottom"}}
    @align={{if @align @align "start"}}
    @sideOffset={{sideOffsetOf @sideOffset}}
    @alignOffset={{if @alignOffset @alignOffset 0}}
    @anchor={{@anchor}}
    class="jn-combobox-content jn-combobox-content-logical jn-menu-target group/combobox-content"
    data-slot="combobox-content"
    data-chips={{if @anchor "true" "false"}}
    ...attributes
  >{{yield}}</@Part>
</template>

interface WrappedSignature<Part, E extends Element = HTMLDivElement> {
  Args: {
    /** @internal The primitive's part, bound by the combobox. */
    Part: Part
  }
  Blocks: { default: [] }
  Element: E
}

/** What it says when nothing matches, upstream's `ComboboxEmpty`. */
const ComboboxEmpty: TOC<WrappedSignature<ComboboxPrimitiveBlockParams['Empty']>> = <template>
  <@Part class="jn-combobox-empty" data-slot="combobox-empty" ...attributes>{{yield}}</@Part>
</template>

/** The label of a group, upstream's `ComboboxLabel`. */
const ComboboxLabel: TOC<WrappedSignature<ComboboxPrimitiveBlockParams['GroupLabel']>> = <template>
  <@Part class="jn-combobox-label" data-slot="combobox-label" ...attributes>{{yield}}</@Part>
</template>

/** A line between groups, upstream's `ComboboxSeparator`, hidden from assistive technology. */
const ComboboxSeparator: TOC<WrappedSignature<ComboboxPrimitiveBlockParams['Separator']>> =
  <template>
    <@Part class="jn-combobox-separator" data-slot="combobox-separator" ...attributes />
  </template>

export interface ComboboxListSignature {
  Args: {
    /** @internal The primitive's List, bound by the combobox. */
    Part: ComboboxPrimitiveBlockParams['List']
  }
  /** Called for each filtered item (or group): `as |item index|`. */
  // An item is whatever @items holds, so the template can read its fields.
  Blocks: { default: [item: any, index: number] }
  Element: HTMLDivElement
}

/** The `listbox` of items, upstream's `ComboboxList`, scrolling within the popup. */
const ComboboxList: TOC<ComboboxListSignature> = <template>
  <@Part class="jn-combobox-list" data-slot="combobox-list" ...attributes as |item index|>
    {{yield item index}}
  </@Part>
</template>

export interface ComboboxGroupSignature {
  Args: {
    /** The group's items, filtered: the `items` of a group the List yields. */
    items?: readonly unknown[]
    /** @internal The primitive's Group, bound by the combobox. */
    Part: ComboboxPrimitiveBlockParams['Group']
  }
  /** Yields the group's `Collection`: `as |g|`, then `<g.Collection as |item|>`. */
  Blocks: { default: [ComboboxGroupBlockParams] }
  Element: HTMLDivElement
}

/** Items that belong together, upstream's `ComboboxGroup`: yields the `Collection` of its items. */
const ComboboxGroup: TOC<ComboboxGroupSignature> = <template>
  <@Part
    @items={{@items}}
    class="jn-combobox-group"
    data-slot="combobox-group"
    ...attributes
    as |group|
  >{{yield group}}</@Part>
</template>

export interface ComboboxItemSignature {
  Args: {
    /** The item this option chooses. */
    value: unknown
    /** Makes it impossible to choose. */
    disabled?: boolean
    /** The check mark shown while it is chosen. Default lucide's `check`. */
    icon?: IconNode
    /** @internal The primitive's Item, bound by the combobox. */
    Part: ComboboxPrimitiveBlockParams['Item']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** One item, upstream's `ComboboxItem`: its content, and a check mark at its end while chosen. */
const ComboboxItem: TOC<ComboboxItemSignature> = <template>
  <@Part
    @value={{@value}}
    @disabled={{@disabled}}
    class="jn-combobox-item"
    data-slot="combobox-item"
    ...attributes
    as |item|
  >
    {{yield}}
    <item.ItemIndicator class="jn-combobox-item-indicator">
      <Icon @icon={{if @icon @icon Check}} class="jn-combobox-item-indicator-icon" />
    </item.ItemIndicator>
  </@Part>
</template>

// ----- The combobox --------------------------------------------------------------------------

/** What a `<Combobox>` yields: its parts, their modifiers, and its state. */
export interface ComboboxBlockParams {
  /** The input in its input group, with the chevron (`@showTrigger`) and clear (`@showClear`) buttons. */
  Input: WithBoundArgs<typeof ComboboxInput, 'Input' | 'Trigger' | 'Clear'>
  /** A button that opens the list: the chevron after its block. */
  Trigger: WithBoundArgs<typeof ComboboxTrigger, 'Part'>
  /** The chevron, for a trigger of your own. */
  TriggerIcon: typeof ComboboxTriggerIcon
  /** A button that clears the value, while there is one. */
  Clear: WithBoundArgs<typeof ComboboxClear, 'Part'>
  /** The chosen item's label (`@placeholder` while none), or a block for the value yourself. */
  Value: WithBoundArgs<typeof ComboboxValue, 'Part'>
  /** The popup, in the top layer while open. */
  Content: WithBoundArgs<typeof ComboboxContent, 'Part'>
  /** The listbox, yielding each filtered item. */
  List: WithBoundArgs<typeof ComboboxList, 'Part'>
  /** One item. */
  Item: WithBoundArgs<typeof ComboboxItem, 'Part'>
  /** Items that belong together. */
  Group: WithBoundArgs<typeof ComboboxGroup, 'Part'>
  /** The label of the group it is in. */
  Label: WithBoundArgs<typeof ComboboxLabel, 'Part'>
  /** Renders each item of the filtered list (or a group's, as the Group yields it). */
  Collection: ComboboxPrimitiveBlockParams['Collection']
  /** What it says when nothing matches. */
  Empty: WithBoundArgs<typeof ComboboxEmpty, 'Part'>
  /** A line between groups. */
  Separator: WithBoundArgs<typeof ComboboxSeparator, 'Part'>
  /** The chips of a multiple combobox, and their input. */
  Chips: WithBoundArgs<typeof ComboboxChips, 'part'>
  /** One chip. */
  Chip: WithBoundArgs<typeof ComboboxChip, 'Part'>
  /** The input among the chips. */
  ChipsInput: WithBoundArgs<typeof ComboboxChipsInput, 'Input'>
  /** Makes your own input the combobox's. */
  input: ComboboxPrimitiveBlockParams['input']
  /** Makes your own element or component the trigger: `<Button {{c.trigger}}>`. */
  trigger: PartModifier
  /** The chips' element, for `<c.Content @anchor={{c.chipsElement}}>`. */
  chipsElement: HTMLElement | null
  /** The chosen item, or items. */
  value: unknown
  /** The input's text. */
  inputValue: string
  /** Whether it is open. */
  isOpen: boolean
  /** Opens (`true`) or closes (`false`) it. */
  setOpen: (open: boolean) => void
  /** Chooses an item (or items). */
  setValue: (value: unknown) => void
}

export interface ComboboxSignature {
  Args: ComboboxArgs
  Blocks: { default: [ComboboxBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * Autocomplete input with a list of suggestions: shadcn's Combobox, on the primitives' headless
 * one (Base UI's). It renders no box of its own, and yields its parts:
 *
 *   <Combobox @items={{frameworks}} as |c|>
 *     <c.Input placeholder="Select a framework" />
 *     <c.Content>
 *       <c.Empty>No items found.</c.Empty>
 *       <c.List as |item|>
 *         <c.Item @value={{item}}>{{item}}</c.Item>
 *       </c.List>
 *     </c.Content>
 *   </Combobox>
 *
 * Typing filters `@items` and opens the list; the arrow keys highlight an item (focus stays in
 * the input) and Enter or a press chooses it. With `@multiple` the value is an array, shown in
 * `Chips`.
 */
const Combobox: TOC<ComboboxSignature> = <template>
  <ComboboxPrimitive
    @items={{@items}}
    @filteredItems={{@filteredItems}}
    @multiple={{@multiple}}
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @inputValue={{@inputValue}}
    @defaultInputValue={{@defaultInputValue}}
    @onInputValueChange={{@onInputValueChange}}
    @open={{@open}}
    @defaultOpen={{@defaultOpen}}
    @onOpenChange={{@onOpenChange}}
    @autoHighlight={{@autoHighlight}}
    @itemToStringLabel={{@itemToStringLabel}}
    @itemToStringValue={{@itemToStringValue}}
    @isItemEqualToValue={{@isItemEqualToValue}}
    @filter={{@filter}}
    @limit={{@limit}}
    @locale={{@locale}}
    @openOnInputClick={{@openOnInputClick}}
    @highlightItemOnHover={{@highlightItemOnHover}}
    @loopFocus={{@loopFocus}}
    @disabled={{@disabled}}
    @readOnly={{@readOnly}}
    @required={{@required}}
    @formName={{@formName}}
    @form={{@form}}
    @name={{@name}}
    ...attributes
    as |c|
  >
    {{yield
      (hash
        Input=(component ComboboxInput Input=c.Input Trigger=c.Trigger Clear=c.Clear)
        Trigger=(component ComboboxTrigger Part=c.Trigger)
        TriggerIcon=ComboboxTriggerIcon
        Clear=(component ComboboxClear Part=c.Clear)
        Value=(component ComboboxValue Part=c.Value)
        Content=(component ComboboxContent Part=c.Content)
        List=(component ComboboxList Part=c.List)
        Item=(component ComboboxItem Part=c.Item)
        Group=(component ComboboxGroup Part=c.Group)
        Label=(component ComboboxLabel Part=c.GroupLabel)
        Collection=c.Collection
        Empty=(component ComboboxEmpty Part=c.Empty)
        Separator=(component ComboboxSeparator Part=c.Separator)
        Chips=(component ComboboxChips part=c.chips)
        Chip=(component ComboboxChip Part=c.Chip)
        ChipsInput=(component ComboboxChipsInput Input=c.Input)
        input=c.input
        trigger=c.trigger
        chipsElement=c.chipsElement
        value=c.value
        inputValue=c.inputValue
        isOpen=c.isOpen
        setOpen=c.setOpen
        setValue=c.setValue
      )
    }}
  </ComboboxPrimitive>
</template>

export default Combobox
