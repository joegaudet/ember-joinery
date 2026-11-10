import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import type { TagName } from '@ember-joinery/primitives/as'
import {
  DropdownMenu as DropdownMenuPrimitive,
  type DropdownMenuArgs,
  type DropdownMenuBlockParams as PrimitiveBlockParams,
  type DropdownMenuTriggerOptions,
} from '@ember-joinery/primitives/dropdown-menu'
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

export type {
  MenuItemModifierOptions,
  MenuItemStyle,
  MenuItemVariant,
  MenuRadioItemModifierOptions,
  MenuSubBlock,
  MenuSubTriggerModifierOptions,
} from '../-private/menu-parts.gts'

const LOOK = menuLook('dropdown-menu')

interface TriggerSignature {
  Args: DropdownMenuTriggerOptions & {
    /** @internal The primitive's Trigger, bound by the menu. */
    Part: PrimitiveBlockParams['Trigger']
    /** The tag to render. Default `button`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** A `<button>` that opens and closes the menu. For your own element, use `trigger`. */
const DropdownMenuTrigger: TOC<TriggerSignature> = <template>
  <@Part
    @as={{@as}}
    @disabled={{@disabled}}
    @stopPropagation={{@stopPropagation}}
    @preventDefault={{@preventDefault}}
    data-slot="dropdown-menu-trigger"
    ...attributes
  >{{yield}}</@Part>
</template>

/** What a `<DropdownMenu>` yields: its parts, their modifiers, and its state. */
export interface DropdownMenuBlockParams {
  /** A `<button>` that opens and closes it. For your own element, use `trigger`. */
  Trigger: WithBoundArgs<typeof DropdownMenuTrigger, 'Part'>
  /** The menu, below its trigger and lined up with its start (or at `@placement`), 4px off. */
  Content: WithBoundArgs<typeof MenuContent, 'Part' | 'look' | 'rootPlacement'>
  /** Radix's `Portal`, kept for upstream's markup: it renders its block in place. */
  Portal: PrimitiveBlockParams['Portal']
  /** A group of items. */
  Group: WithBoundArgs<typeof MenuGroup, 'Part' | 'look'>
  /** A label for the items after it (`@inset` to line it up with icons). */
  Label: WithBoundArgs<typeof MenuLabel, 'Part' | 'look'>
  /** An item: `@onSelect`, `@variant="destructive"`, `@inset`, `@disabled`. */
  Item: WithBoundArgs<typeof MenuItem, 'Part' | 'look'>
  /** An item that is a link: ember-primitives' `LinkItem`. */
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
  Arrow: PrimitiveBlockParams['Arrow']
  /** Makes your own element or component the trigger: `<Button {{m.trigger}}>`. */
  trigger: PrimitiveBlockParams['trigger']
  /** Makes your own element an item, styled as one: `<LinkTo {{m.item}}>`. */
  item: PartModifier<HTMLElement, MenuItemModifierOptions>
  /** Makes your own element a checkbox item, styled as one (its check mark is yours). */
  checkboxItem: PartModifier<HTMLElement, MenuCheckboxItemModifierOptions>
  /** Whether it is open. */
  isOpen: boolean
  /** Opens it. */
  open: () => void
  /** Closes it. */
  close: () => void
  /** Opens it if it is closed, and closes it if it is open. */
  toggle: () => void
  /** Opens (`true`) or closes (`false`) it: `(fn m.setOpen false)`. */
  setOpen: (open: boolean) => void
}

export interface DropdownMenuSignature {
  Args: DropdownMenuArgs
  Blocks: { default: [DropdownMenuBlockParams] }
  /** An element with `display: contents`, so it doesn't change the layout. */
  Element: HTMLDivElement
}

/**
 * Displays a menu to the user, such as a set of actions or functions, triggered by a button:
 * shadcn's Dropdown Menu, on the primitives' headless one. It renders no box of its own, and
 * yields its parts:
 *
 *   <DropdownMenu as |m|>
 *     <Button @variant="outline" {{m.trigger}}>Open</Button>
 *     <m.Content>
 *       <m.Group>
 *         <m.Label>My Account</m.Label>
 *         <m.Item>Profile <m.Shortcut>⇧⌘P</m.Shortcut></m.Item>
 *       </m.Group>
 *       <m.Separator />
 *       <m.Item @variant="destructive">Log out</m.Item>
 *     </m.Content>
 *   </DropdownMenu>
 *
 * Its state is its own, or yours with `@open` and `@onOpenChange` (`@defaultOpen` starts it
 * open). The content is in the top layer while open: the arrow keys and typing move between
 * its items, Enter or a click selects one, Escape or a press outside closes it, and focus goes
 * back to the trigger.
 */
const DropdownMenu: TOC<DropdownMenuSignature> = <template>
  <DropdownMenuPrimitive
    @open={{@open}}
    @defaultOpen={{@defaultOpen}}
    @onOpenChange={{@onOpenChange}}
    @modal={{@modal}}
    @dir={{@dir}}
    @name={{@name}}
    @placement={{@placement}}
    @offsetOptions={{@offsetOptions}}
    @flipOptions={{@flipOptions}}
    @shiftOptions={{@shiftOptions}}
    @middleware={{@middleware}}
    @strategy={{@strategy}}
    ...attributes
    as |m|
  >
    {{yield
      (hash
        Trigger=(component DropdownMenuTrigger Part=m.Trigger)
        Content=(component MenuContent Part=m.Content look=LOOK rootPlacement=@placement)
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
        isOpen=m.isOpen
        open=m.open
        close=m.close
        toggle=m.toggle
        setOpen=m.setOpen
      )
    }}
  </DropdownMenuPrimitive>
</template>

export default DropdownMenu
