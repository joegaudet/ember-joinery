import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type Owner from '@ember/owner'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { controllable, type ControllableArgs } from './controllable-state.ts'
import { getDirection, type Direction } from './direction.gts'
import type { DismissReason, FocusOutsideEvent, PointerDownOutsideEvent } from './dismiss.ts'
import { idFor } from './id.ts'
import { part, type PartModifier } from './part.ts'
import { RovingFocus, type RovingFocusItemState } from './roving-focus.gts'
import { ElementRef, buttonType, ensureId, type PopperContentArgs } from './-private/popper.gts'
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
  type MenuContentArgs,
  type MenuContentHost,
  type MenuItemOptions,
  type MenuRoot,
} from './-private/menu.gts'

/** What a `<Menubar>` takes. */
export type MenubarArgs = ControllableArgs<'value', string> & {
  /**
   * Whether the arrow keys go round from the last menu to the first, and back. Default `true`,
   * as Radix's.
   */
  loop?: boolean
  /** The text direction, when the document's (at the menubar) shouldn't decide. */
  dir?: Direction
  /** Its name, for `MenubarHarness` (`data-test-jn-name`). */
  name?: string
  /** The tag to render. Default `div`. */
  as?: TagName
}

/** What a menu's trigger and its modifier take. */
export interface MenubarTriggerOptions {
  /** Whether it is disabled: it doesn't open its menu, and the arrow keys skip it. */
  disabled?: boolean
}

/** Radix's Popper defaults for a menubar menu's content: below its trigger, at its start. */
const CONTENT_DEFAULTS: PopperContentArgs = { side: 'bottom', align: 'start', sideOffset: 0 }

const MENU = '[role="menu"]'

/** A submenu's trigger, which the arrow pointing into its submenu opens. */
function isSubTrigger(element: Element): boolean {
  return element.matches('[role="menuitem"][aria-haspopup="menu"]')
}

// ----- The menubar ------------------------------------------------------------------------------

/**
 * A row of menus, as Radix's `Menubar` (which shadcn's is built on) and a desktop app's menu bar:
 * a `role="menubar"` whose triggers share one tab stop. It yields its menus:
 *
 *   <Menubar as |bar|>
 *     <bar.Menu as |m|>
 *       <m.Trigger>File</m.Trigger>
 *       <m.Content>
 *         <m.Item @onSelect={{this.newTab}}>New Tab</m.Item>
 *         <m.Separator />
 *         <m.Sub as |s|>
 *           <s.Trigger>Share</s.Trigger>
 *           <s.Content><m.Item>Email link</m.Item></s.Content>
 *         </m.Sub>
 *       </m.Content>
 *     </bar.Menu>
 *     <bar.Menu as |m|>…</bar.Menu>
 *   </Menubar>
 *
 * ArrowLeft and ArrowRight move between the triggers (flipped right to left); Enter, Space or
 * ArrowDown open a menu, its first item focused. While one is open, ArrowLeft and ArrowRight
 * open the menu beside it, the pointer opens whichever trigger it rests on, and Escape or a
 * press outside closes it, focus going back to its trigger. Each menu's content is a
 * [Dropdown Menu's](dropdown-menu.gts), not modal. Which menu is open is `@value` (the menu's
 * own `@value`, or `''` for none), its own or yours with `@onValueChange`.
 */
export class Menubar extends Component<MenubarSignature> {
  valueState = controllable(this, 'value', '')
  keyboard = new KeyboardIntent(this)
  readonly menus = new Set<MenubarMenu>()

  roving = new RovingFocus({
    orientation: () => 'horizontal',
    dir: () => this.args.dir,
    loop: () => this.loop,
  })

  get id(): string {
    return idFor(this)
  }

  /** The open menu's value, or `''`. */
  get value(): string {
    return this.valueState.value
  }

  get isOpen(): boolean {
    return this.value !== ''
  }

  get loop(): boolean {
    return this.args.loop ?? true
  }

  /** The direction the arrow keys follow: `@dir`, or the document's at the menubar. */
  dir(element?: Element | null): Direction {
    return getDirection(element, this.args.dir)
  }

  /** Its menus whose triggers are rendered, in the triggers' order. */
  orderedMenus(): MenubarMenu[] {
    return [...this.menus]
      .filter(menu => menu.triggerRef.current)
      .sort((a, b) =>
        a.triggerRef.current!.compareDocumentPosition(b.triggerRef.current!) &
        Node.DOCUMENT_POSITION_FOLLOWING
          ? -1
          : 1,
      )
  }

  /** Every menu's trigger: a press or focus there counts as inside each menu's content. */
  get triggers(): Element[] {
    return this.orderedMenus().map(menu => menu.triggerRef.current!)
  }

  #setValue(value: string): void {
    for (const menu of this.menus) if (menu.value !== value) menu.keyboardOpened = false
    this.valueState.set(value)
  }

  /** Opens a menu, and makes its trigger the tab stop. */
  openMenu = (value: string): void => {
    this.#setValue(value)
    this.roving.onItemFocus(value)
  }

  /** Closes whichever menu is open. */
  close = (): void => this.#setValue('')

  /** Opens a menu, or closes the menubar's open one. */
  toggleMenu = (value: string): void => {
    this.#setValue(this.isOpen ? '' : value)
    this.roving.onItemFocus(value)
  }

  /**
   * ArrowLeft and ArrowRight in an open menu, as Radix's MenubarContent: the previous or next
   * menu opens (going round, unless `@loop` is false). The arrow pointing into a submenu from
   * its trigger opens that instead, and the one pointing back from inside a submenu closes it.
   */
  onContentKeyDown(event: KeyboardEvent, menu: MenubarMenu): void {
    if (event.key !== 'ArrowRight' && event.key !== 'ArrowLeft') return
    const target = event.target as HTMLElement
    const content = event.currentTarget as HTMLElement
    const isKeyDownInsideSubMenu = target.closest(MENU) !== content
    const prevMenuKey = this.dir(content) === 'rtl' ? 'ArrowRight' : 'ArrowLeft'
    const isPrevKey = event.key === prevMenuKey
    if (!isPrevKey && isSubTrigger(target)) return
    if (isKeyDownInsideSubMenu && isPrevKey) return
    let candidates = this.orderedMenus()
      .filter(other => !other.triggerDisabled)
      .map(other => other.value)
    if (isPrevKey) candidates.reverse()
    const index = candidates.indexOf(menu.value)
    candidates = this.loop
      ? candidates.map((_, offset) => candidates[(index + 1 + offset) % candidates.length]!)
      : candidates.slice(index + 1)
    const [next] = candidates
    if (next) this.openMenu(next)
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      id={{this.id}}
      role="menubar"
      data-test-jn="menubar"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.roving.group}}
    >{{yield
        (hash Menu=(component MenubarMenu menubar=this) value=this.value close=this.close)
      }}</As>
  </template>
}

// ----- A menu ---------------------------------------------------------------------------------

interface TriggerSignature {
  Args: MenubarTriggerOptions & {
    /** @internal The trigger's modifier, bound by the menu. */
    part: PartModifier<HTMLElement, MenubarTriggerOptions>
    /** The tag to render. Default `button`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** A `<button type="button">` (or `@as`), the `role="menuitem"` that opens its menu. */
const MenubarTrigger: TOC<TriggerSignature> = <template>
  <As
    @as={{@as}}
    @tag="button"
    type="button"
    disabled={{@disabled}}
    ...attributes
    {{@part disabled=@disabled}}
  >{{yield}}</As>
</template>

interface ContentSignature {
  Args: MenuContentArgs & {
    /** @internal The menu, bound by it. */
    menu: MenubarMenu
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** A menu's content: a Dropdown Menu's, with ArrowLeft and ArrowRight opening the next menu. */
class MenubarContent extends Component<ContentSignature> {
  onKeyDown = (event: KeyboardEvent): void =>
    this.args.menu.menubar.onContentKeyDown(event, this.args.menu)

  <template>
    <MenuContent
      @menu={{@menu}}
      @itemPart={{@menu.item}}
      @as={{@as}}
      @forceMount={{@forceMount}}
      @loop={{@loop}}
      @side={{@side}}
      @align={{@align}}
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
      @onFocusOutside={{@onFocusOutside}}
      @onInteractOutside={{@onInteractOutside}}
      ...attributes
      {{on "keydown" this.onKeyDown}}
    >{{yield}}</MenuContent>
  </template>
}

/** What a menubar's menu yields: its parts, their modifiers, and its state. */
export interface MenubarMenuBlockParams {
  /** The `<button>` in the menubar that opens it (`@as` for another tag). */
  Trigger: WithBoundArgs<typeof MenubarTrigger, 'part'>
  /** The menu itself, in the top layer while it is open, below its trigger. */
  Content: WithBoundArgs<typeof MenubarContent, 'menu'>
  /** Radix's `Portal`: renders its block in place (the top layer needs no portal). */
  Portal: typeof MenuPortal
  /** A group of items. */
  Group: WithBoundArgs<typeof MenuGroup, 'part'>
  /** A label for the items after it. */
  Label: WithBoundArgs<typeof MenuLabel, 'part'>
  /** An item: selecting it calls `@onSelect` and closes the menu. */
  Item: WithBoundArgs<typeof MenuItem, 'part'>
  /** An item that is a link. */
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
  /** Makes your own element the trigger: `<button {{m.trigger}}>`. */
  trigger: PartModifier<HTMLElement, MenubarTriggerOptions>
  /** Makes your own element an item: `<LinkTo {{m.item}}>`. */
  item: PartModifier<HTMLElement, MenuItemOptions>
  /** Makes your own element a checkbox item (controlled: `checked`, `onCheckedChange`). */
  checkboxItem: PartModifier<HTMLElement, MenuCheckboxItemOptions>
  /** Makes your own element a group, a label or a separator. */
  group: PartModifier<HTMLElement>
  label: PartModifier<HTMLElement>
  separator: PartModifier<HTMLElement>
  /** Makes your own element the arrow. */
  arrow: PartModifier<HTMLElement>
  /** The menu, for a styled layer's own item modifiers (`menuItemPart(m.menu, look)`). */
  menu: MenuRoot
  /** Its value: the menubar's `@value` while it is open. */
  value: string
  /** Whether it is open. */
  isOpen: boolean
  /** Opens it (and closes any other). */
  open: () => void
  /** Closes it. */
  close: () => void
}

export interface MenubarMenuSignature {
  Args: {
    /** @internal The menubar, bound by it. */
    menubar: Menubar
    /** Its value, for the menubar's `@value`. Default: an id of its own. */
    value?: string
  }
  Blocks: { default: [MenubarMenuBlockParams] }
}

/**
 * One menu of a menubar, as Radix's `MenubarMenu`: a trigger in the bar, and its content. It
 * renders nothing of its own.
 */
export class MenubarMenu extends Component<MenubarMenuSignature> implements MenuContentHost {
  triggerRef = new ElementRef()
  arrowRef = new ElementRef()
  /** Whether its trigger's keys opened it, so focus goes on to its first item. */
  keyboardOpened = false
  /** Whether its trigger is disabled, so the arrow keys skip it. */
  triggerDisabled = false
  #interactedOutside = false
  #rovingItem: RovingFocusItemState | undefined

  readonly cssName = 'menubar'
  readonly isModal = false
  readonly contentDefaults = CONTENT_DEFAULTS
  readonly contentForced: PopperContentArgs = {}
  readonly positioning: PopperContentArgs = {}

  constructor(owner: Owner, args: MenubarMenuSignature['Args']) {
    super(owner, args)
    this.menubar.menus.add(this)
  }

  override willDestroy(): void {
    super.willDestroy()
    this.menubar.menus.delete(this)
  }

  get menubar(): Menubar {
    return this.args.menubar
  }

  get value(): string {
    return this.args.value || idFor(this, 'menu')
  }

  /** The menubar's id: its contents belong to the menubar (`data-test-jn-owner`). */
  get id(): string {
    return this.menubar.id
  }

  get contentId(): string {
    return idFor(this, 'content')
  }

  get triggerId(): string {
    return this.triggerRef.value?.id || idFor(this, 'trigger')
  }

  get isOpen(): boolean {
    return this.menubar.value === this.value
  }

  get explicitDir(): Direction | undefined {
    return this.menubar.args.dir
  }

  get isUsingKeyboard(): boolean {
    return this.menubar.keyboard.isUsingKeyboard
  }

  get preventsEntryFocus(): boolean {
    return !this.keyboardOpened
  }

  get state(): 'open' | 'closed' {
    return this.isOpen ? 'open' : 'closed'
  }

  get reference(): Element | null {
    return this.triggerRef.value
  }

  get inside(): Array<Element | null> {
    return this.menubar.triggers
  }

  get labelledBy(): string | undefined {
    return this.triggerId
  }

  open = (): void => this.menubar.openMenu(this.value)
  close = (): void => this.menubar.close()
  dismiss = (_reason: DismissReason): void => this.close()

  /** Focus goes back to the trigger when the menubar has closed, unless the user went elsewhere. */
  closeAutoFocus(event: Event, handler?: (event: Event) => void): void {
    handler?.(event)
    const interacted = this.#interactedOutside
    this.#interactedOutside = false
    if (event.defaultPrevented) return
    if (!this.menubar.isOpen && !interacted) this.triggerRef.current?.focus()
    event.preventDefault()
  }

  interactOutside(
    event: PointerDownOutsideEvent | FocusOutsideEvent,
    handler?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void,
  ): void {
    handler?.(event)
    if (!event.defaultPrevented) this.#interactedOutside = true
  }

  // ----- The parts ---------------------------------------------------------------------------

  /**
   * The trigger: Radix's MenubarTrigger, a `menuitem` that is one of the menubar's roving
   * items (its tab stop is the menu's value).
   */
  trigger: PartModifier<HTMLElement, MenubarTriggerOptions> = part<
    HTMLElement,
    MenubarTriggerOptions
  >(options => {
    const disabled = options.disabled ?? false
    this.triggerDisabled = disabled
    const { menubar } = this
    const roving = menubar.roving
    const open = this.isOpen
    if (this.#rovingItem && this.#rovingItem.focusable === disabled) {
      this.#rovingItem.focusable = !disabled
      roving.changed()
    }
    return {
      attributes: {
        role: 'menuitem',
        'aria-haspopup': 'menu',
        'aria-expanded': String(open),
        'aria-controls': open ? this.contentId : undefined,
        'data-state': this.state,
        'data-disabled': disabled ? '' : undefined,
        'data-orientation': 'horizontal',
        tabindex: roving.currentTabStopId === this.value ? '0' : '-1',
        'data-test-jn-part': 'trigger',
        'data-test-jn-value': this.value,
      },
      on: {
        // As Radix's: the press opens it, so the menu is there before the pointer comes up. A
        // press on an open menu's trigger closes it (Radix's dismisses it as a press outside).
        pointerdown: event => {
          if (disabled || event.button !== 0 || event.ctrlKey) return
          if (this.isOpen) return this.close()
          this.open()
          // Keep focus off the trigger, so the content can take it.
          event.preventDefault()
        },
        // While a menu is open, the pointer opens the one it rests on.
        pointerenter: event => {
          if (!menubar.isOpen || this.isOpen) return
          this.open()
          ;(event.currentTarget as HTMLElement).focus()
        },
        keydown: event => {
          const item = this.#rovingItem
          if (item) roving.onItemKeyDown(event, item)
          if (disabled || event.defaultPrevented) return
          if (event.key === 'Enter' || event.key === ' ') menubar.toggleMenu(this.value)
          if (event.key === 'ArrowDown') this.open()
          if (['Enter', ' ', 'ArrowDown'].includes(event.key)) {
            this.keyboardOpened = true
            event.preventDefault()
          }
        },
        mousedown: event => {
          const item = this.#rovingItem
          if (item) roving.onItemMouseDown(event, item)
        },
        focusin: () => roving.onItemFocus(this.value),
        focus: event => (event.currentTarget as HTMLElement).setAttribute('data-highlighted', ''),
        blur: event => (event.currentTarget as HTMLElement).removeAttribute('data-highlighted'),
      },
      element: element => {
        this.triggerRef.set(element)
        const restoreType = buttonType(element)
        const restoreId = ensureId(element, idFor(this, 'trigger'))
        const item = (this.#rovingItem = {
          element,
          id: this.value,
          focusable: !disabled,
          active: false,
        })
        const unregister = roving.register(item)
        return () => {
          unregister()
          if (this.#rovingItem === item) this.#rovingItem = undefined
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
    {{yield
      (hash
        Trigger=(component MenubarTrigger part=this.trigger)
        Content=(component MenubarContent menu=this)
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
        value=this.value
        isOpen=this.isOpen
        open=this.open
        close=this.close
      )
    }}
  </template>
}

/** What a `<Menubar>` yields. */
export interface MenubarBlockParams {
  /** A menu: it yields its Trigger, Content and items. */
  Menu: WithBoundArgs<typeof MenubarMenu, 'menubar'>
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

export default Menubar
