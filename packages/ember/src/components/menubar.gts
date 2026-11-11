import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import type { TagName } from '@ember-joinery/primitives/as'
import {
  Menubar as MenubarPrimitive,
  type MenubarArgs,
  type MenubarBlockParams as PrimitiveBlockParams,
  type MenubarMenuBlockParams as PrimitiveMenuBlockParams,
  type MenubarTriggerOptions,
} from '@ember-joinery/primitives/menubar'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  MenuCheckboxItem,
  MenuContent,
  MenuGroup,
  MenuItem,
  MenuLabel,
  MenuLinkItem,
  MenuRadioGroup,
  MenuSeparator,
  MenuShortcut,
  MenuSub,
  menuLook,
  styledCheckboxItem,
  styledItem,
  type MenuCheckboxItemModifierOptions,
  type MenuItemModifierOptions,
} from '../-private/menu-parts.gts'

const LOOK = menuLook('menubar')

interface TriggerSignature {
  Args: MenubarTriggerOptions & {
    /** @internal The primitive's Trigger, bound by the menu. */
    Part: PrimitiveMenuBlockParams['Trigger']
    /** The tag to render. Default `button`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** A menu's `<button>` in the bar. For your own element, use `trigger`. */
const MenubarTrigger: TOC<TriggerSignature> = <template>
  <@Part
    @as={{@as}}
    @disabled={{@disabled}}
    class={{LOOK.trigger.class}}
    data-slot={{LOOK.trigger.slot}}
    ...attributes
  >{{yield}}</@Part>
</template>

/** What a menubar's menu yields: its parts, their modifiers, and its state. */
export interface MenubarMenuBlockParams {
  /** Its `<button>` in the bar. For your own element, use `trigger`. */
  Trigger: WithBoundArgs<typeof MenubarTrigger, 'Part'>
  /** The menu, below its trigger, at its start, 8px off. */
  Content: WithBoundArgs<typeof MenuContent, 'Part' | 'look' | 'rootPlacement'>
  /** Radix's `Portal`, kept for upstream's markup: it renders its block in place. */
  Portal: PrimitiveMenuBlockParams['Portal']
  /** A group of items. */
  Group: WithBoundArgs<typeof MenuGroup, 'Part' | 'look'>
  /** A label for the items after it (`@inset` to line it up with icons). */
  Label: WithBoundArgs<typeof MenuLabel, 'Part' | 'look'>
  /** An item: `@onSelect`, `@variant="destructive"`, `@inset`, `@disabled`. */
  Item: WithBoundArgs<typeof MenuItem, 'Part' | 'look'>
  /** An item that is a link. */
  LinkItem: WithBoundArgs<typeof MenuLinkItem, 'Part' | 'look'>
  /** An item that toggles, with a check mark: `@checked` and `@onCheckedChange`. */
  CheckboxItem: WithBoundArgs<typeof MenuCheckboxItem, 'Part' | 'look'>
  /** A group of radio items, the one whose value is `@value` checked: `@onValueChange`. */
  RadioGroup: WithBoundArgs<typeof MenuRadioGroup, 'Part' | 'look'>
  /** A line between items. */
  Separator: WithBoundArgs<typeof MenuSeparator, 'Part' | 'look'>
  /** An item's keyboard shortcut, at its end. */
  Shortcut: WithBoundArgs<typeof MenuShortcut, 'look'>
  /** A submenu: it yields its Trigger and Content. */
  Sub: WithBoundArgs<typeof MenuSub, 'Part' | 'look'>
  /** An arrow on the content's edge (Radix's, unstyled). */
  Arrow: PrimitiveMenuBlockParams['Arrow']
  /** Makes your own element the trigger, styled as one: `<button {{m.trigger}}>`. */
  trigger: PrimitiveMenuBlockParams['trigger']
  /** Makes your own element an item, styled as one: `<LinkTo {{m.item}}>`. */
  item: PartModifier<HTMLElement, MenuItemModifierOptions>
  /** Makes your own element a checkbox item, styled as one (its check mark is yours). */
  checkboxItem: PartModifier<HTMLElement, MenuCheckboxItemModifierOptions>
  /** Its value: the menubar's `@value` while it is open. */
  value: string
  /** Whether it is open. */
  isOpen: boolean
  /** Opens it (and closes any other). */
  open: () => void
  /** Closes it. */
  close: () => void
}

interface MenuSignature {
  Args: {
    /** @internal The primitive's Menu, bound by the menubar. */
    Part: PrimitiveBlockParams['Menu']
    /** Its value, for the menubar's `@value`. Default: an id of its own. */
    value?: string
  }
  Blocks: { default: [MenubarMenuBlockParams] }
}

/** One menu of the menubar: its trigger and its content. It renders nothing of its own. */
const MenubarMenu: TOC<MenuSignature> = <template>
  <@Part @value={{@value}} @triggerLook={{LOOK.triggerLook}} as |m|>
    {{yield
      (hash
        Trigger=(component MenubarTrigger Part=m.Trigger)
        Content=(component MenuContent Part=m.Content look=LOOK rootPlacement=undefined)
        Portal=m.Portal
        Group=(component MenuGroup Part=m.Group look=LOOK)
        Label=(component MenuLabel Part=m.Label look=LOOK)
        Item=(component MenuItem Part=m.Item look=LOOK)
        LinkItem=(component MenuLinkItem Part=m.LinkItem look=LOOK)
        CheckboxItem=(component MenuCheckboxItem Part=m.CheckboxItem look=LOOK)
        RadioGroup=(component MenuRadioGroup Part=m.RadioGroup look=LOOK)
        Separator=(component MenuSeparator Part=m.Separator look=LOOK)
        Shortcut=(component MenuShortcut look=LOOK)
        Sub=(component MenuSub Part=m.Sub look=LOOK)
        Arrow=m.Arrow
        trigger=m.trigger
        item=(styledItem m.menu LOOK)
        checkboxItem=(styledCheckboxItem m.menu LOOK)
        value=m.value
        isOpen=m.isOpen
        open=m.open
        close=m.close
      )
    }}
  </@Part>
</template>

/** What a `<Menubar>` yields. */
export interface MenubarBlockParams {
  /** A menu: it yields its Trigger, Content and items. */
  Menu: WithBoundArgs<typeof MenubarMenu, 'Part'>
  /** The open menu's value, or `''`. */
  value: string
  /** Closes whichever menu is open. */
  close: () => void
}

export interface MenubarSignature {
  Args: MenubarArgs
  Blocks: { default: [MenubarBlockParams] }
  Element: HTMLDivElement
}

/**
 * A visually persistent menu common in desktop applications that provides quick access to a
 * consistent set of commands: shadcn's Menubar, on the primitives' headless one. It yields its
 * menus, and each menu yields the parts of a [Dropdown Menu](./dropdown-menu.gts):
 *
 *   <Menubar as |bar|>
 *     <bar.Menu as |m|>
 *       <m.Trigger>File</m.Trigger>
 *       <m.Content>
 *         <m.Group>
 *           <m.Item>New Tab <m.Shortcut>⌘T</m.Shortcut></m.Item>
 *           <m.Item>New Window</m.Item>
 *         </m.Group>
 *         <m.Separator />
 *         <m.Item>Print</m.Item>
 *       </m.Content>
 *     </bar.Menu>
 *   </Menubar>
 *
 * The arrow keys move between its triggers; Enter, Space or ArrowDown open a menu, and while one
 * is open the arrows and the pointer move to the others. Which menu is open is `@value`, its own
 * or yours with `@onValueChange`.
 */
const Menubar: TOC<MenubarSignature> = <template>
  <MenubarPrimitive
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @loop={{@loop}}
    @dir={{@dir}}
    @name={{@name}}
    @as={{@as}}
    class="jn-menubar"
    data-slot="menubar"
    ...attributes
    as |bar|
  >
    {{yield (hash Menu=(component MenubarMenu Part=bar.Menu) value=bar.value close=bar.close)}}
  </MenubarPrimitive>
</template>

export default Menubar
