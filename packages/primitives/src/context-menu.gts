import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import type { VirtualElement } from './anchor/index.ts'
import { As, type TagName } from './as.gts'
import type { Direction } from './direction.gts'
import type { DismissReason, FocusOutsideEvent, PointerDownOutsideEvent } from './dismiss.ts'
import { idFor } from './id.ts'
import { part, type PartModifier, type PartSpec } from './part.ts'
import { Delay, ElementRef, displayContents, type PopperContentArgs } from './-private/popper.gts'
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
  withLook,
  type MenuCheckboxItemOptions,
  type MenuContentHost,
  type MenuItemOptions,
  type MenuPartLook,
  type MenuRoot,
} from './-private/menu.gts'

/** What a `<ContextMenu>` takes. */
export interface ContextMenuArgs {
  /** Called with each state the user asks for. As Radix's, its state is its own. */
  onOpenChange?: (open: boolean) => void
  /**
   * Whether it is modal (the default, as Radix's): while it is open, the rest of the page
   * ignores the pointer, is hidden from assistive technology and doesn't scroll, and focus
   * stays in the menu.
   */
  modal?: boolean
  /** The text direction, when the document's shouldn't decide. */
  dir?: Direction
  /** Its name, for `ContextMenuHarness` (`data-test-jn-name`). */
  name?: string
  /** A styled layer's look for the `trigger` modifier, so it renders what its Trigger does. */
  triggerLook?: MenuPartLook
}

/** What the trigger and its modifier take. */
export interface ContextMenuTriggerOptions {
  /** Whether it is disabled: a right click or long press there does what it would anyway. */
  disabled?: boolean
}

/** How long a touch or pen must stay down to open it, as Radix's: 700ms. */
export const LONG_PRESS = 700

/**
 * Radix's for a context menu's content: beside the pointer, to its right and level with it,
 * 2px off. Radix's ContextMenuContent sets these over whatever it is given.
 */
const CONTENT_FORCED: PopperContentArgs = { side: 'right', sideOffset: 2, align: 'start' }

interface TriggerSignature {
  Args: ContextMenuTriggerOptions & {
    /** @internal The trigger's modifier, bound by the menu. */
    part: PartModifier<HTMLElement, ContextMenuTriggerOptions>
    /** The tag to render. Default `span`, as Radix's. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The area that opens the menu: a right click there, or a long press by touch or pen. */
const ContextMenuTrigger: TOC<TriggerSignature> = <template>
  <As @as={{@as}} @tag="span" ...attributes {{@part disabled=@disabled}}>{{yield}}</As>
</template>

/** Whether an event came from a touch or a pen, which a long press opens the menu for. */
function isTouchOrPen(event: PointerEvent): boolean {
  return event.pointerType !== 'mouse'
}

/** What a `<ContextMenu>` yields: its parts, their modifiers, and its state. */
export interface ContextMenuBlockParams {
  /** The area that opens it. */
  Trigger: WithBoundArgs<typeof ContextMenuTrigger, 'part'>
  /** The menu itself, at the pointer, in the top layer while it is open. */
  Content: WithBoundArgs<typeof MenuContent, 'menu' | 'itemPart'>
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
  /** An arrow on the content's edge, pointing at the pointer. Put it inside the Content. */
  Arrow: WithBoundArgs<typeof MenuArrow, 'arrow'>
  /** Makes your own element the area that opens it. */
  trigger: PartModifier<HTMLElement, ContextMenuTriggerOptions>
  /** Makes your own element an item. */
  item: PartModifier<HTMLElement, MenuItemOptions>
  /** Makes your own element a checkbox item (controlled: `checked`, `onCheckedChange`). */
  checkboxItem: PartModifier<HTMLElement, MenuCheckboxItemOptions>
  /** Makes your own element a group, a label or a separator. */
  group: PartModifier<HTMLElement>
  label: PartModifier<HTMLElement>
  separator: PartModifier<HTMLElement>
  /** The root, for a styled layer's own item modifiers (`menuItemPart(c.menu, look)`). */
  menu: MenuRoot
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
 * A menu opened by a right click, as Radix's ContextMenu (which shadcn's is built on):
 *
 *   <ContextMenu as |c|>
 *     <c.Trigger class="area">Right click here</c.Trigger>
 *     <c.Content>
 *       <c.Item>Back</c.Item>
 *       <c.Item @disabled={{true}}>Forward</c.Item>
 *     </c.Content>
 *   </ContextMenu>
 *
 * A right click on the trigger (or a long press, by touch or pen) opens it where the pointer
 * is, instead of the browser's own menu. Its content and items work as a dropdown menu's do.
 */
export class ContextMenu extends Component<ContextMenuSignature> implements MenuContentHost {
  @tracked isOpen = false
  /** Where it opened, in the viewport. */
  @tracked point = { x: 0, y: 0 }
  triggerRef = new ElementRef()
  arrowRef = new ElementRef()
  keyboard = new KeyboardIntent(this)
  longPress = new Delay(this)
  #interactedOutside = false

  readonly cssName = 'context-menu'
  readonly contentDefaults: PopperContentArgs = {}
  readonly contentForced = CONTENT_FORCED
  readonly labelledBy = undefined
  readonly inside: Array<Element | null> = []

  get id(): string {
    return idFor(this)
  }

  get contentId(): string {
    return idFor(this, 'content')
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

  /** The point it opened at, as Radix's virtual anchor: a box of no size there. */
  get reference(): VirtualElement {
    const { x, y } = this.point
    return { getBoundingClientRect: () => DOMRect.fromRect({ x, y, width: 0, height: 0 }) }
  }

  get positioning(): PopperContentArgs {
    return {}
  }

  setOpen = (open: boolean): void => {
    if (this.isOpen !== open) this.isOpen = open
    this.args.onOpenChange?.(open)
  }

  close = (): void => this.setOpen(false)
  dismiss = (_reason: DismissReason): void => this.close()

  openAt(point: { x: number; y: number }): void {
    this.point = point
    this.setOpen(true)
  }

  /** Focus goes back where it was, unless the user went elsewhere. */
  closeAutoFocus(event: Event, handler?: (event: Event) => void): void {
    handler?.(event)
    if (!event.defaultPrevented && this.#interactedOutside) event.preventDefault()
    this.#interactedOutside = false
  }

  interactOutside(
    event: PointerDownOutsideEvent | FocusOutsideEvent,
    handler?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void,
  ): void {
    handler?.(event)
    if (!event.defaultPrevented && !this.isModal) this.#interactedOutside = true
  }

  // ----- The parts ---------------------------------------------------------------------------

  trigger: PartModifier<HTMLElement, ContextMenuTriggerOptions> = part<
    HTMLElement,
    ContextMenuTriggerOptions
  >(options => {
    const disabled = options.disabled ?? false
    const cancel = () => this.longPress.cancel()
    const spec: PartSpec<HTMLElement> = {
      attributes: {
        'data-state': this.state,
        'data-disabled': disabled ? '' : undefined,
        'data-test-jn-part': 'trigger',
      },
      on: disabled
        ? {}
        : {
            contextmenu: event => {
              cancel()
              this.openAt({ x: event.clientX, y: event.clientY })
              event.preventDefault()
            },
            pointerdown: event => {
              if (!isTouchOrPen(event)) return
              const point = { x: event.clientX, y: event.clientY }
              this.longPress.start(LONG_PRESS, () => this.openAt(point))
            },
            pointermove: event => isTouchOrPen(event) && cancel(),
            pointercancel: event => isTouchOrPen(event) && cancel(),
            pointerup: event => isTouchOrPen(event) && cancel(),
          },
      element: element => {
        this.triggerRef.set(element)
        // No callout on a long press in iOS Safari, which would cover the menu.
        element.style.setProperty('-webkit-touch-callout', 'none')
        return () => {
          element.style.removeProperty('-webkit-touch-callout')
          this.triggerRef.release(element)
        }
      },
    }
    return withLook(spec, { ...options }, this.args.triggerLook)
  })

  item = itemPart(this)
  checkboxItem = checkboxItemPart(this)

  <template>
    <div
      id={{this.id}}
      data-test-jn="context-menu"
      data-test-jn-name={{@name}}
      ...attributes
      {{displayContents}}
    >
      {{yield
        (hash
          Trigger=(component ContextMenuTrigger part=this.trigger)
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
          menu=this
          isOpen=this.isOpen
          close=this.close
        )
      }}
    </div>
  </template>
}

export default ContextMenu
