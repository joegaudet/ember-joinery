import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import type { TagName } from '@ember-joinery/primitives/as'
import {
  ContextMenu as ContextMenuPrimitive,
  type ContextMenuArgs,
  type ContextMenuBlockParams as PrimitiveBlockParams,
  type ContextMenuTriggerOptions,
} from '@ember-joinery/primitives/context-menu'
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

const LOOK = menuLook('context-menu')

interface TriggerSignature {
  Args: ContextMenuTriggerOptions & {
    /** @internal The primitive's Trigger, bound by the menu. */
    Part: PrimitiveBlockParams['Trigger']
    /** The tag to render. Default `span`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The area a right click (or a long press) opens the menu on. Its text isn't selectable. */
const ContextMenuTrigger: TOC<TriggerSignature> = <template>
  <@Part
    @as={{@as}}
    @disabled={{@disabled}}
    class={{LOOK.trigger.class}}
    data-slot={{LOOK.trigger.slot}}
    ...attributes
  >{{yield}}</@Part>
</template>

/** What a `<ContextMenu>` yields: its parts, their modifiers, and its state. */
export interface ContextMenuBlockParams {
  /** The area a right click (or a long press) opens it on. */
  Trigger: WithBoundArgs<typeof ContextMenuTrigger, 'Part'>
  /** The menu, beside the pointer. */
  Content: WithBoundArgs<typeof MenuContent, 'Part' | 'look' | 'rootPlacement'>
  /** Radix's `Portal`, kept for upstream's markup: it renders its block in place. */
  Portal: PrimitiveBlockParams['Portal']
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
  /** Makes your own element the area that opens it, styled as the Trigger is: `<div {{c.trigger}}>`. */
  trigger: PrimitiveBlockParams['trigger']
  /** Makes your own element an item, styled as one. */
  item: PartModifier<HTMLElement, MenuItemModifierOptions>
  /** Makes your own element a checkbox item, styled as one (its check mark is yours). */
  checkboxItem: PartModifier<HTMLElement, MenuCheckboxItemModifierOptions>
  /** Whether it is open. */
  isOpen: boolean
  /** Closes it. */
  close: () => void
}

export interface ContextMenuSignature {
  Args: ContextMenuArgs
  Blocks: { default: [ContextMenuBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * Displays a menu of actions triggered by a right click: shadcn's Context Menu, on the
 * primitives' headless one. It renders no box of its own, and yields its parts:
 *
 *   <ContextMenu as |c|>
 *     <c.Trigger class="flex h-36 w-72 items-center justify-center">Right click here</c.Trigger>
 *     <c.Content>
 *       <c.Item>Back <c.Shortcut>⌘[</c.Shortcut></c.Item>
 *       <c.Item @disabled={{true}}>Forward</c.Item>
 *     </c.Content>
 *   </ContextMenu>
 *
 * A right click on the trigger (or a long press, by touch or pen) opens the content where the
 * pointer is. Its items work as a dropdown menu's do.
 */
const ContextMenu: TOC<ContextMenuSignature> = <template>
  <ContextMenuPrimitive
    @onOpenChange={{@onOpenChange}}
    @modal={{@modal}}
    @dir={{@dir}}
    @name={{@name}}
    @triggerLook={{LOOK.triggerLook}}
    ...attributes
    as |c|
  >
    {{yield
      (hash
        Trigger=(component ContextMenuTrigger Part=c.Trigger)
        Content=(component MenuContent Part=c.Content look=LOOK rootPlacement=undefined)
        Portal=c.Portal
        Group=(component MenuGroup Part=c.Group look=LOOK)
        Label=(component MenuLabel Part=c.Label look=LOOK)
        Item=(component MenuItem Part=c.Item look=LOOK)
        LinkItem=(component MenuLinkItem Part=c.LinkItem look=LOOK)
        CheckboxItem=(component MenuCheckboxItem Part=c.CheckboxItem look=LOOK)
        RadioGroup=(component MenuRadioGroup Part=c.RadioGroup look=LOOK)
        Separator=(component MenuSeparator Part=c.Separator look=LOOK)
        Shortcut=(component MenuShortcut look=LOOK)
        Sub=(component MenuSub Part=c.Sub look=LOOK)
        trigger=c.trigger
        item=(styledItem c.menu LOOK)
        checkboxItem=(styledCheckboxItem c.menu LOOK)
        isOpen=c.isOpen
        close=c.close
      )
    }}
  </ContextMenuPrimitive>
</template>

export default ContextMenu
