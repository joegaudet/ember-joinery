import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { controllable, type ControllableArgs } from './controllable-state.ts'
import type { Direction } from './direction.gts'
import type { DismissReason, FocusOutsideEvent, PointerDownOutsideEvent } from './dismiss.ts'
import { idFor } from './id.ts'
import { part, type PartModifier } from './part.ts'
import {
  ElementRef,
  buttonType,
  displayContents,
  ensureId,
  type PopperContentArgs,
} from './-private/popper.gts'
import {
  KeyboardIntent,
  MenuArrow,
  MenuCheckboxItem,
  MenuContent,
  MenuGroup,
  MenuItem,
  MenuLabel,
  MenuLinkItem,
  MenuPortal,
  MenuRadioGroup,
  MenuSeparator,
  MenuSub,
  checkboxItemPart,
  groupPart,
  itemPart,
  labelPart,
  separatorPart,
  type MenuCheckboxItemOptions,
  type MenuContentHost,
  type MenuItemOptions,
  type MenuRoot,
} from './-private/menu.gts'

export {
  checkboxItemPart as menuCheckboxItemPart,
  itemPart as menuItemPart,
  type MenuCheckedState,
  type MenuItemLook,
  type MenuPartLook,
  type MenuRoot,
  type MenuCheckboxItemBlockParams,
  type MenuCheckboxItemOptions,
  type MenuContentArgs,
  type MenuContentBlockParams,
  type MenuItemOptions,
  type MenuRadioGroupBlockParams,
  type MenuRadioItemOptions,
  type MenuSubBlockParams,
  type MenuSubContentArgs,
} from './-private/menu.gts'

/** ember-primitives' Menu arguments, which the content takes from the root. */
type MenuPositionArgs = Pick<
  PopperContentArgs,
  'placement' | 'offsetOptions' | 'flipOptions' | 'shiftOptions' | 'middleware' | 'strategy'
>

/** What a `<DropdownMenu>` takes. */
export type DropdownMenuArgs = ControllableArgs<'open', boolean> &
  MenuPositionArgs & {
    /**
     * Whether it is modal (the default, as Radix's): while it is open, the rest of the page
     * ignores the pointer, is hidden from assistive technology and doesn't scroll, and focus
     * stays in the menu. A non-modal menu also closes when focus or a press goes outside.
     */
    modal?: boolean
    /** The text direction, when the document's (at the trigger) shouldn't decide. */
    dir?: Direction
    /** Its name, for `DropdownMenuHarness` (`data-test-jn-name`). */
    name?: string
  }

/** What the trigger and its modifier take. */
export interface DropdownMenuTriggerOptions {
  /** Whether it is disabled: it doesn't open the menu. */
  disabled?: boolean
  /** Stop the click from reaching the trigger's ancestors (ember-primitives'). */
  stopPropagation?: boolean
  /** Cancel the click's default action (ember-primitives'). */
  preventDefault?: boolean
}

/** Radix's Popper defaults for a dropdown menu's content: below its trigger, centred, touching it. */
const CONTENT_DEFAULTS: PopperContentArgs = { side: 'bottom', align: 'center', sideOffset: 0 }

interface TriggerSignature {
  Args: DropdownMenuTriggerOptions & {
    /** @internal The trigger's modifier, bound by the menu. */
    part: PartModifier<HTMLElement, DropdownMenuTriggerOptions>
    /** The tag to render. Default `button`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** A `<button type="button">`, or `@as`, that opens and closes the menu. */
const DropdownMenuTrigger: TOC<TriggerSignature> = <template>
  <As
    @as={{@as}}
    @tag="button"
    type="button"
    disabled={{@disabled}}
    ...attributes
    {{@part disabled=@disabled stopPropagation=@stopPropagation preventDefault=@preventDefault}}
  >{{yield}}</As>
</template>

/** What a `<DropdownMenu>` yields: its parts, their modifiers, and its state. */
export interface DropdownMenuBlockParams {
  /** A `<button>` that opens and closes it (`@as` for another tag). */
  Trigger: WithBoundArgs<typeof DropdownMenuTrigger, 'part'>
  /** The menu itself, in the top layer while it is open. */
  Content: WithBoundArgs<typeof MenuContent, 'menu' | 'itemPart'>
  /** Radix's `Portal`: renders its block in place (the top layer needs no portal). */
  Portal: typeof MenuPortal
  /** A group of items. */
  Group: WithBoundArgs<typeof MenuGroup, 'part'>
  /** A label for the items after it. */
  Label: WithBoundArgs<typeof MenuLabel, 'part'>
  /** An item: selecting it calls `@onSelect` and closes the menu. */
  Item: WithBoundArgs<typeof MenuItem, 'part'>
  /** An item that is a link: ember-primitives' `LinkItem`. */
  LinkItem: WithBoundArgs<typeof MenuLinkItem, 'part'>
  /** An item that toggles: `@checked` and `@onCheckedChange`. */
  CheckboxItem: WithBoundArgs<typeof MenuCheckboxItem, 'part'>
  /** A group of radio items, the one whose value is `@value` checked: `@onValueChange`. */
  RadioGroup: WithBoundArgs<typeof MenuRadioGroup, 'menu'>
  /** A line between items. */
  Separator: WithBoundArgs<typeof MenuSeparator, 'part'>
  /** A submenu: it yields its Trigger and Content. */
  Sub: WithBoundArgs<typeof MenuSub, 'menu'>
  /** An arrow on the content's edge, pointing at the trigger. Put it inside the Content. */
  Arrow: WithBoundArgs<typeof MenuArrow, 'arrow'>
  /** Makes your own element or component the trigger: `<Button {{m.trigger}}>`. */
  trigger: PartModifier<HTMLElement, DropdownMenuTriggerOptions>
  /** Makes your own element an item: `<LinkTo {{m.item}}>`. */
  item: PartModifier<HTMLElement, MenuItemOptions>
  /** Makes your own element a checkbox item (controlled: `checked`, `onCheckedChange`). */
  checkboxItem: PartModifier<HTMLElement, MenuCheckboxItemOptions>
  /** Makes your own element a group, a label or a separator. */
  group: PartModifier<HTMLElement>
  label: PartModifier<HTMLElement>
  separator: PartModifier<HTMLElement>
  /** Makes your own element the arrow (ember-primitives'). */
  arrow: PartModifier<HTMLElement>
  /** The root, for a styled layer's own item modifiers (`menuItemPart(m.menu, look)`). */
  menu: MenuRoot
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
 * A menu opened by a button, as Radix's DropdownMenu (which shadcn's is built on), covering
 * ember-primitives' Menu. It renders no box of its own, and yields its parts:
 *
 *   <DropdownMenu as |m|>
 *     <m.Trigger>Options</m.Trigger>
 *     <m.Content @align="start" @sideOffset={{4}}>
 *       <m.Label>My Account</m.Label>
 *       <m.Item @onSelect={{this.profile}}>Profile</m.Item>
 *       <m.Separator />
 *       <m.Sub as |s|>
 *         <s.Trigger>Invite users</s.Trigger>
 *         <s.Content><m.Item>Email</m.Item></s.Content>
 *       </m.Sub>
 *     </m.Content>
 *   </DropdownMenu>
 *
 * The trigger opens it on a press (the pointer going down), Enter, Space or ArrowDown. Its
 * content is a `role="menu"` in the top layer, placed against the trigger: the arrow keys,
 * Home and End move between its items, typing jumps to one, Enter or Space selects it, Escape
 * or a press outside closes it, and focus goes back to the trigger. Submenus open on hover
 * (with a grace area for the pointer on its way) or the arrow pointing into them. Its state is
 * its own, or yours with `@open` and `@onOpenChange` (and `@defaultOpen` to start open).
 */
export class DropdownMenu extends Component<DropdownMenuSignature> implements MenuContentHost {
  openState = controllable(this, 'open', false)
  triggerRef = new ElementRef()
  arrowRef = new ElementRef()
  keyboard = new KeyboardIntent(this)
  #interactedOutside = false

  readonly cssName = 'dropdown-menu'
  readonly contentDefaults = CONTENT_DEFAULTS
  readonly contentForced: PopperContentArgs = {}

  get id(): string {
    return idFor(this)
  }

  get contentId(): string {
    return idFor(this, 'content')
  }

  get isOpen(): boolean {
    return this.openState.value
  }

  get isModal(): boolean {
    return this.args.modal ?? true
  }

  get explicitDir(): Direction | undefined {
    return this.args.dir
  }

  get isUsingKeyboard(): boolean {
    return this.keyboard.isUsingKeyboard
  }

  get state(): 'open' | 'closed' {
    return this.isOpen ? 'open' : 'closed'
  }

  get reference(): Element | null {
    return this.triggerRef.value
  }

  get inside(): Array<Element | null> {
    return [this.triggerRef.value]
  }

  get labelledBy(): string | undefined {
    return this.triggerRef.value?.id || undefined
  }

  get positioning(): PopperContentArgs {
    return this.args
  }

  setOpen = (open: boolean): void => this.openState.set(open)
  open = (): void => this.setOpen(true)
  close = (): void => this.setOpen(false)
  toggle = (): void => this.openState.set(open => !open)
  dismiss = (_reason: DismissReason): void => this.close()

  /** Focus goes back to the trigger, unless the user went elsewhere (or right-clicked outside). */
  closeAutoFocus(event: Event, handler?: (event: Event) => void): void {
    handler?.(event)
    const interacted = this.#interactedOutside
    this.#interactedOutside = false
    if (event.defaultPrevented) return
    if (!interacted) this.triggerRef.current?.focus()
    event.preventDefault()
  }

  interactOutside(
    event: PointerDownOutsideEvent | FocusOutsideEvent,
    handler?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void,
  ): void {
    handler?.(event)
    if (event.defaultPrevented) return
    const original = event.detail.originalEvent as Partial<PointerEvent>
    const ctrlLeftClick = original.button === 0 && original.ctrlKey === true
    const rightClick = original.button === 2 || ctrlLeftClick
    if (!this.isModal || rightClick) this.#interactedOutside = true
  }

  // ----- The parts ---------------------------------------------------------------------------

  trigger: PartModifier<HTMLElement, DropdownMenuTriggerOptions> = part<
    HTMLElement,
    DropdownMenuTriggerOptions
  >(options => {
    const disabled = options.disabled ?? false
    return {
      attributes: {
        'aria-haspopup': 'menu',
        'aria-expanded': String(this.isOpen),
        'aria-controls': this.isOpen ? this.contentId : undefined,
        'data-state': this.state,
        'data-disabled': disabled ? '' : undefined,
        'data-test-jn-part': 'trigger',
      },
      on: {
        // As Radix's: the press opens it, so the menu is there before the pointer comes up.
        pointerdown: event => {
          if (disabled || event.button !== 0 || event.ctrlKey) return
          const wasOpen = this.isOpen
          this.toggle()
          // Keep focus off the trigger, so the content can take it.
          if (!wasOpen) event.preventDefault()
        },
        keydown: event => {
          if (disabled) return
          if (event.key === 'Enter' || event.key === ' ') this.toggle()
          if (event.key === 'ArrowDown') this.open()
          if (['Enter', ' ', 'ArrowDown'].includes(event.key)) event.preventDefault()
        },
        click: event => {
          if (options.stopPropagation) event.stopPropagation()
          if (options.preventDefault) event.preventDefault()
        },
      },
      element: element => {
        this.triggerRef.set(element)
        const restoreType = buttonType(element)
        const restoreId = ensureId(element, idFor(this, 'trigger'))
        return () => {
          restoreType()
          restoreId()
          this.triggerRef.release(element)
        }
      },
    }
  })

  item = itemPart(this)
  checkboxItem = checkboxItemPart(this)

  arrow: PartModifier = part<HTMLElement>(() => ({
    attributes: { 'data-test-jn-part': 'arrow' },
    element: element => {
      this.arrowRef.set(element)
      return () => this.arrowRef.release(element)
    },
  }))

  <template>
    <div
      id={{this.id}}
      data-test-jn="dropdown-menu"
      data-test-jn-name={{@name}}
      ...attributes
      {{displayContents}}
    >
      {{yield
        (hash
          Trigger=(component DropdownMenuTrigger part=this.trigger)
          Content=(component MenuContent menu=this itemPart=this.item)
          Portal=MenuPortal
          Group=(component MenuGroup part=groupPart)
          Label=(component MenuLabel part=labelPart)
          Item=(component MenuItem part=this.item)
          LinkItem=(component MenuLinkItem part=this.item)
          CheckboxItem=(component MenuCheckboxItem part=this.checkboxItem)
          RadioGroup=(component MenuRadioGroup menu=this)
          Separator=(component MenuSeparator part=separatorPart)
          Sub=(component MenuSub menu=this)
          Arrow=(component MenuArrow arrow=this.arrowRef)
          trigger=this.trigger
          item=this.item
          checkboxItem=this.checkboxItem
          group=groupPart
          label=labelPart
          separator=separatorPart
          arrow=this.arrow
          menu=this
          isOpen=this.isOpen
          open=this.open
          close=this.close
          toggle=this.toggle
          setOpen=this.setOpen
        )
      }}
    </div>
  </template>
}

/** ember-primitives' name for it. */
export { DropdownMenu as Menu }

export default DropdownMenu
