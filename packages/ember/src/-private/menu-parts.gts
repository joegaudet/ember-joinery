// The styled parts Dropdown Menu and Context Menu share. Upstream's two are the same but for
// their names (`cn-dropdown-menu-item`, `cn-context-menu-item`…) and a detail or two, so each
// part here takes the menu's `@look`: its classes and `data-slot`s. dropdown-menu.gts and
// context-menu.gts are the public modules.
import { hash } from '@ember/helper'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { Check, ChevronRight } from 'lucide'
import type { TagName } from '@ember-joinery/primitives/as'
import {
  menuCheckboxItemPart,
  menuItemPart,
  type DropdownMenuBlockParams,
  type MenuCheckboxItemOptions,
  type MenuContentArgs,
  type MenuItemOptions,
  type MenuRadioGroupBlockParams,
  type MenuRoot,
  type MenuSubBlockParams,
  type MenuSubContentArgs,
} from '@ember-joinery/primitives/dropdown-menu'
import type { PartModifier } from '@ember-joinery/primitives/part'
import Icon, { type IconNode } from '../components/icon.gts'

/** Which menu the parts are for: their classes and `data-slot`s start with it. */
export type MenuName = 'dropdown-menu' | 'context-menu'

/** An item's look: `default`, or `destructive` for one that can't be undone. */
export type MenuItemVariant = 'default' | 'destructive'

/** A part's class and `data-slot`. */
interface Slot {
  readonly class?: string
  readonly slot: string
}

/** A menu's classes and `data-slot`s, part by part, as upstream's source gives them. */
export interface MenuLook {
  readonly name: MenuName
  readonly trigger: Slot
  readonly content: Slot
  readonly group: Slot
  readonly label: Slot
  readonly item: Slot
  readonly checkboxItem: Slot
  readonly radioGroup: Slot
  readonly radioItem: Slot
  readonly separator: Slot
  readonly shortcut: Slot
  readonly subTrigger: Slot
  readonly subContent: Slot
  /** The span around a checkbox or radio item's check mark. Context Menu's has no `data-slot`. */
  readonly checkboxIndicator: Slot | { readonly class: string; readonly slot?: undefined }
  readonly radioIndicator: Slot | { readonly class: string; readonly slot?: undefined }
  /** The content's alignment and distance when it is given none: upstream's own. */
  readonly contentAlign: 'start' | undefined
  readonly contentSideOffset: number | undefined
}

/**
 * The look of upstream's menu called `name`. `jn-menu-target` is kept, as transformStyle keeps
 * `cn-menu-target`, for shadcn's menu colour option (no style sheet rule styles it).
 * `cn-menu-translucent` is left off: shadcn's default menu colour, which ui.shadcn.com and
 * every style's preset use, takes it away (add `class="jn-menu-translucent"` to a Content for
 * the translucent menus).
 */
export function menuLook(name: MenuName): MenuLook {
  const indicator = `jn-${name}-item-indicator`
  return {
    name,
    trigger: {
      class: name === 'context-menu' ? 'jn-context-menu-trigger' : undefined,
      slot: `${name}-trigger`,
    },
    content: { class: `jn-${name}-content jn-menu-target`, slot: `${name}-content` },
    group: { slot: `${name}-group` },
    label: { class: `jn-${name}-label`, slot: `${name}-label` },
    item: { class: `jn-${name}-item group/${name}-item`, slot: `${name}-item` },
    checkboxItem: { class: `jn-${name}-checkbox-item`, slot: `${name}-checkbox-item` },
    radioGroup: { slot: `${name}-radio-group` },
    radioItem: { class: `jn-${name}-radio-item`, slot: `${name}-radio-item` },
    separator: { class: `jn-${name}-separator`, slot: `${name}-separator` },
    shortcut: { class: `jn-${name}-shortcut`, slot: `${name}-shortcut` },
    subTrigger: { class: `jn-${name}-sub-trigger`, slot: `${name}-sub-trigger` },
    subContent: { class: `jn-${name}-sub-content jn-menu-target`, slot: `${name}-sub-content` },
    checkboxIndicator:
      name === 'dropdown-menu'
        ? { class: indicator, slot: `${name}-checkbox-item-indicator` }
        : { class: indicator },
    radioIndicator:
      name === 'dropdown-menu'
        ? { class: indicator, slot: `${name}-radio-item-indicator` }
        : { class: indicator },
    // Upstream's DropdownMenuContent starts at the trigger's start, 4px off; a context menu's
    // place is the pointer's, which the primitive decides.
    contentAlign: name === 'dropdown-menu' ? 'start' : undefined,
    contentSideOffset: name === 'dropdown-menu' ? 4 : undefined,
  }
}

/** The primitive's parts the styled ones render, from either menu's yield. */
type Parts = DropdownMenuBlockParams

// ----- Items --------------------------------------------------------------------------------

/** What a styled item takes beyond the primitive's: its look. */
export interface MenuItemStyle {
  /** Its look. Default `default`. */
  variant?: MenuItemVariant
  /** Indent it, to line it up with items that have an icon or a check mark. */
  inset?: boolean
}

/** What the styled `item` modifier takes: the item, and its look. */
export type MenuItemModifierOptions = MenuItemOptions & MenuItemStyle

/** What the styled `checkboxItem` modifier takes. */
export type MenuCheckboxItemModifierOptions = MenuCheckboxItemOptions & Pick<MenuItemStyle, 'inset'>

const itemModifiers = new WeakMap<MenuRoot, Map<string, unknown>>()

/** One modifier for each root, menu and kind: made on first use, then kept. */
function cached<T>(root: MenuRoot, key: string, make: () => T): T {
  let byKey = itemModifiers.get(root)
  if (!byKey) itemModifiers.set(root, (byKey = new Map()))
  if (!byKey.has(key)) byKey.set(key, make())
  return byKey.get(key) as T
}

/** The styled item modifier of a menu: the primitive's behaviour, with the Item's look. */
export function styledItem(
  root: MenuRoot,
  look: MenuLook,
): PartModifier<HTMLElement, MenuItemModifierOptions> {
  return cached(root, `item:${look.name}`, () =>
    menuItemPart<MenuItemModifierOptions>(root, named => ({
      class: look.item.class,
      attributes: {
        'data-slot': look.item.slot,
        'data-variant': named.variant ?? 'default',
        'data-inset': named.inset ? 'true' : undefined,
      },
    })),
  )
}

/** The styled checkbox item modifier of a menu (its check mark is yours to render). */
export function styledCheckboxItem(
  root: MenuRoot,
  look: MenuLook,
): PartModifier<HTMLElement, MenuCheckboxItemModifierOptions> {
  return cached(root, `checkbox:${look.name}`, () =>
    menuCheckboxItemPart<MenuCheckboxItemModifierOptions>(root, named => ({
      class: look.checkboxItem.class,
      attributes: {
        'data-slot': look.checkboxItem.slot,
        'data-inset': named.inset ? 'true' : undefined,
      },
    })),
  )
}

interface ItemArgs extends MenuItemOptions, MenuItemStyle {
  /** The tag to render. Default `div`. */
  as?: TagName
}

export interface MenuItemSignature {
  Args: ItemArgs & {
    /** @internal The primitive's Item, bound by the menu. */
    Part: Parts['Item']
    /** @internal The menu's look. */
    look: MenuLook
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

function variantOf(variant: MenuItemVariant | undefined): MenuItemVariant {
  return variant ?? 'default'
}

/** An item: selecting it calls `@onSelect` and closes the menu. */
export const MenuItem: TOC<MenuItemSignature> = <template>
  <@Part
    @as={{@as}}
    @disabled={{@disabled}}
    @onSelect={{@onSelect}}
    @textValue={{@textValue}}
    class={{@look.item.class}}
    data-slot={{@look.item.slot}}
    data-inset={{@inset}}
    data-variant={{variantOf @variant}}
    ...attributes
  >{{yield}}</@Part>
</template>

export interface MenuCheckboxItemSignature {
  Args: Omit<ItemArgs, 'variant'> &
    Pick<MenuCheckboxItemOptions, 'checked' | 'onCheckedChange'> & {
      /** @internal The primitive's CheckboxItem, bound by the menu. */
      Part: Parts['CheckboxItem']
      /** @internal The menu's look. */
      look: MenuLook
      /** The check mark: one from `lucide`. Default lucide's `check`. */
      icon?: IconNode
    }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** An item that toggles, with a check mark at its end while it is checked. */
export const MenuCheckboxItem: TOC<MenuCheckboxItemSignature> = <template>
  <@Part
    @as={{@as}}
    @checked={{@checked}}
    @onCheckedChange={{@onCheckedChange}}
    @disabled={{@disabled}}
    @onSelect={{@onSelect}}
    @textValue={{@textValue}}
    class={{@look.checkboxItem.class}}
    data-slot={{@look.checkboxItem.slot}}
    data-inset={{@inset}}
    ...attributes
    as |item|
  ><span
      class={{@look.checkboxIndicator.class}}
      data-slot={{@look.checkboxIndicator.slot}}
    ><item.Indicator><Icon
          @icon={{if @icon @icon Check}}
        /></item.Indicator></span>{{yield}}</@Part>
</template>

export interface MenuLinkItemSignature {
  Args: Omit<ItemArgs, 'as'> & {
    /** @internal The primitive's LinkItem, bound by the menu. */
    Part: Parts['LinkItem']
    /** @internal The menu's look. */
    look: MenuLook
    /** Where it goes. A link to one of the app's routes is a transition, not a page load. */
    href: string
    /** Whether the query params count towards its being active (`data-active`). */
    includeActiveQueryParams?: boolean | string[]
    /** Whether it is active on the routes below it too. */
    activeOnSubPaths?: boolean
  }
  Blocks: { default: [{ isActive: boolean; isExternal: boolean }] }
  Element: HTMLAnchorElement
}

/** An item that is a link, styled as an item: ember-primitives' `LinkItem`. */
export const MenuLinkItem: TOC<MenuLinkItemSignature> = <template>
  <@Part
    @href={{@href}}
    @includeActiveQueryParams={{@includeActiveQueryParams}}
    @activeOnSubPaths={{@activeOnSubPaths}}
    @disabled={{@disabled}}
    @onSelect={{@onSelect}}
    @textValue={{@textValue}}
    class={{@look.item.class}}
    data-slot={{@look.item.slot}}
    data-inset={{@inset}}
    data-variant={{variantOf @variant}}
    ...attributes
    as |link|
  >{{yield link}}</@Part>
</template>

/** The primitive radio group's item. */
type PrimitiveRadioItem = MenuRadioGroupBlockParams['Item']

export interface MenuRadioItemSignature {
  Args: Omit<ItemArgs, 'variant'> & {
    /** @internal The group's primitive item, bound by the group. */
    Part: PrimitiveRadioItem
    /** @internal The menu's look. */
    look: MenuLook
    /** Its value: selecting it makes it the group's. */
    value: string
    /** The mark of the checked item: one from `lucide`. Default lucide's `check`, as upstream's. */
    icon?: IconNode
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** A radio item, with a mark at its end while it is the checked one. */
export const MenuRadioItem: TOC<MenuRadioItemSignature> = <template>
  <@Part
    @as={{@as}}
    @value={{@value}}
    @disabled={{@disabled}}
    @onSelect={{@onSelect}}
    @textValue={{@textValue}}
    class={{@look.radioItem.class}}
    data-slot={{@look.radioItem.slot}}
    data-inset={{@inset}}
    ...attributes
    as |item|
  ><span
      class={{@look.radioIndicator.class}}
      data-slot={{@look.radioIndicator.slot}}
    ><item.Indicator><Icon
          @icon={{if @icon @icon Check}}
        /></item.Indicator></span>{{yield}}</@Part>
</template>

export interface MenuRadioGroupSignature {
  Args: {
    /** @internal The primitive's RadioGroup, bound by the menu. */
    Part: Parts['RadioGroup']
    /** @internal The menu's look. */
    look: MenuLook
    /** The value of the checked item. */
    value?: string
    /** Called with an item's value when it is selected. */
    onValueChange?: (value: string) => void
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: {
    default: [
      {
        /** A radio item of this group: `<g.Item @value="top">Top</g.Item>`. */
        Item: WithBoundArgs<typeof MenuRadioItem, 'Part' | 'look'>
        /** The group's value. */
        value: string | undefined
      },
    ]
  }
  Element: HTMLElement
}

/** A group of radio items, the one whose value is `@value` checked. */
export const MenuRadioGroup: TOC<MenuRadioGroupSignature> = <template>
  <@Part
    @as={{@as}}
    @value={{@value}}
    @onValueChange={{@onValueChange}}
    data-slot={{@look.radioGroup.slot}}
    ...attributes
    as |group|
  >{{yield
      (hash Item=(component MenuRadioItem Part=group.Item look=@look) value=group.value)
    }}</@Part>
</template>

// ----- The parts with nothing of their own to track ----------------------------------------

interface StaticSignature<Part> {
  Args: {
    /** @internal The primitive's part, bound by the menu. */
    Part: Part
    /** @internal The menu's look. */
    look: MenuLook
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** A group of items. */
export const MenuGroup: TOC<StaticSignature<Parts['Group']>> = <template>
  <@Part @as={{@as}} data-slot={{@look.group.slot}} ...attributes>{{yield}}</@Part>
</template>

export interface MenuLabelSignature {
  Args: StaticSignature<Parts['Label']>['Args'] & {
    /** Indent it, to line it up with items that have an icon or a check mark. */
    inset?: boolean
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** A label for the items after it. */
export const MenuLabel: TOC<MenuLabelSignature> = <template>
  <@Part
    @as={{@as}}
    class={{@look.label.class}}
    data-slot={{@look.label.slot}}
    data-inset={{@inset}}
    ...attributes
  >{{yield}}</@Part>
</template>

export interface MenuSeparatorSignature {
  Args: { Part: Parts['Separator']; look: MenuLook; as?: TagName }
  Element: HTMLElement
}

/** A line between items. */
export const MenuSeparator: TOC<MenuSeparatorSignature> = <template>
  <@Part
    @as={{@as}}
    class={{@look.separator.class}}
    data-slot={{@look.separator.slot}}
    ...attributes
  />
</template>

export interface MenuShortcutSignature {
  Args: {
    /** @internal The menu's look. */
    look: MenuLook
  }
  Blocks: { default: [] }
  Element: HTMLSpanElement
}

/** An item's keyboard shortcut, at its end: a hint only, which the menu doesn't listen for. */
export const MenuShortcut: TOC<MenuShortcutSignature> = <template>
  <span
    class={{@look.shortcut.class}}
    data-slot={{@look.shortcut.slot}}
    data-test-jn-part="shortcut"
    ...attributes
  >{{yield}}</span>
</template>

// ----- Contents -------------------------------------------------------------------------------

export interface MenuContentSignature {
  Args: MenuContentArgs & {
    /** @internal The primitive's Content, bound by the menu. */
    Part: Parts['Content']
    /** @internal The menu's look. */
    look: MenuLook
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** `@align`, or the menu's own unless a `@placement` decides it. */
function alignOf(
  align: MenuContentArgs['align'],
  placement: MenuContentArgs['placement'],
  look: MenuLook,
): MenuContentArgs['align'] {
  return align ?? (placement ? undefined : look.contentAlign)
}

function sideOffsetOf(sideOffset: number | undefined, look: MenuLook): number | undefined {
  return sideOffset ?? look.contentSideOffset
}

/** The menu's content, with Radix's placement arguments and upstream's defaults. */
export const MenuContent: TOC<MenuContentSignature> = <template>
  <@Part
    @as={{@as}}
    @forceMount={{@forceMount}}
    @loop={{@loop}}
    @side={{@side}}
    @align={{alignOf @align @placement @look}}
    @sideOffset={{sideOffsetOf @sideOffset @look}}
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
    @onFocusOutside={{@onFocusOutside}}
    @onInteractOutside={{@onInteractOutside}}
    class={{@look.content.class}}
    data-slot={{@look.content.slot}}
    ...attributes
  >{{yield}}</@Part>
</template>

// ----- Submenus -------------------------------------------------------------------------------

export interface MenuSubTriggerSignature {
  Args: Omit<MenuItemOptions, 'onSelect'> & {
    /** @internal The submenu's primitive Trigger. */
    Part: MenuSubBlockParams['Trigger']
    /** @internal The menu's look. */
    look: MenuLook
    /** Indent it, to line it up with items that have an icon or a check mark. */
    inset?: boolean
    /** The chevron at its end: one from `lucide`. Default lucide's `chevron-right`. */
    icon?: IconNode
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The item that opens a submenu, with a chevron that points the way the submenu opens. */
export const MenuSubTrigger: TOC<MenuSubTriggerSignature> = <template>
  <@Part
    @as={{@as}}
    @disabled={{@disabled}}
    @textValue={{@textValue}}
    class={{@look.subTrigger.class}}
    data-slot={{@look.subTrigger.slot}}
    data-inset={{@inset}}
    ...attributes
  >{{yield}}<Icon @icon={{if @icon @icon ChevronRight}} class="jn-rtl-flip" /></@Part>
</template>

export interface MenuSubContentSignature {
  Args: MenuSubContentArgs & {
    /** @internal The submenu's primitive Content. */
    Part: MenuSubBlockParams['Content']
    /** @internal The menu's look. */
    look: MenuLook
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** A submenu's content, beside its trigger. */
export const MenuSubContent: TOC<MenuSubContentSignature> = <template>
  <@Part
    @as={{@as}}
    @forceMount={{@forceMount}}
    @loop={{@loop}}
    @sideOffset={{@sideOffset}}
    @alignOffset={{@alignOffset}}
    @avoidCollisions={{@avoidCollisions}}
    @collisionPadding={{@collisionPadding}}
    @arrowPadding={{@arrowPadding}}
    @sticky={{@sticky}}
    @hideWhenDetached={{@hideWhenDetached}}
    @onEscapeKeyDown={{@onEscapeKeyDown}}
    @onPointerDownOutside={{@onPointerDownOutside}}
    @onFocusOutside={{@onFocusOutside}}
    @onInteractOutside={{@onInteractOutside}}
    class={{@look.subContent.class}}
    data-slot={{@look.subContent.slot}}
    ...attributes
  >{{yield}}</@Part>
</template>

/** What a styled submenu yields. */
export interface MenuSubBlock {
  /** The item that opens it. */
  Trigger: WithBoundArgs<typeof MenuSubTrigger, 'Part' | 'look'>
  /** Its content, beside the trigger. */
  Content: WithBoundArgs<typeof MenuSubContent, 'Part' | 'look'>
  /** Makes your own element the item that opens it (the primitive's, unstyled). */
  trigger: MenuSubBlockParams['trigger']
  /** Whether it is open. */
  isOpen: boolean
  /** Opens (`true`) or closes (`false`) it. */
  setOpen: (open: boolean) => void
}

export interface MenuSubSignature {
  Args: {
    /** @internal The primitive's Sub, bound by the menu. */
    Part: Parts['Sub']
    /** @internal The menu's look. */
    look: MenuLook
    /** Whether it is open, controlled. */
    open?: boolean
    /** Whether it starts open, uncontrolled. */
    defaultOpen?: boolean
    /** Called with each state the user asks for. */
    onOpenChange?: (open: boolean) => void
  }
  Blocks: { default: [MenuSubBlock] }
}

/** A submenu: it yields its Trigger and Content. */
export const MenuSub: TOC<MenuSubSignature> = <template>
  <@Part @open={{@open}} @defaultOpen={{@defaultOpen}} @onOpenChange={{@onOpenChange}} as |sub|>
    {{yield
      (hash
        Trigger=(component MenuSubTrigger Part=sub.Trigger look=@look)
        Content=(component MenuSubContent Part=sub.Content look=@look)
        trigger=sub.trigger
        isOpen=sub.isOpen
        setOpen=sub.setOpen
      )
    }}
  </@Part>
</template>
