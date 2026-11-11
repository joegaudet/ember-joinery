import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { ChevronDown } from 'lucide'
import type { TagName } from '@ember-joinery/primitives/as'
import {
  NavigationMenu as NavigationMenuPrimitive,
  type NavigationMenuArgs,
  type NavigationMenuBlockParams as PrimitiveBlockParams,
  type NavigationMenuContentArgs,
  type NavigationMenuItemBlockParams as PrimitiveItemBlockParams,
  type NavigationMenuLinkOptions,
  type NavigationMenuPartLook,
  type NavigationMenuTriggerOptions,
} from '@ember-joinery/primitives/navigation-menu'
import type { PartModifier } from '@ember-joinery/primitives/part'
import Icon, { type IconNode } from './icon.gts'

/**
 * The classes of upstream's `navigationMenuTriggerStyle()`: a trigger's look, for a link that
 * should look like one (`<n.Link class={{(navigationMenuTriggerStyle)}}>`), as upstream's demo
 * does for its Docs link.
 */
export function navigationMenuTriggerStyle(): string {
  return 'jn-navigation-menu-trigger group/navigation-menu-trigger'
}

const TRIGGER_CLASS = `${navigationMenuTriggerStyle()} group`

/** What the trigger and link modifiers add, so each renders what its part does. */
const triggerLook: NavigationMenuPartLook = () => ({
  class: TRIGGER_CLASS,
  attributes: { 'data-slot': 'navigation-menu-trigger' },
})

const linkLook: NavigationMenuPartLook = () => ({
  class: 'jn-navigation-menu-link',
  attributes: { 'data-slot': 'navigation-menu-link' },
})

// ----- The parts -------------------------------------------------------------------------------

interface ListSignature {
  Args: { Part: PrimitiveBlockParams['List'] }
  Blocks: { default: [] }
  Element: HTMLUListElement
}

/** The list of items. */
const NavigationMenuList: TOC<ListSignature> = <template>
  <@Part
    class="jn-navigation-menu-list group"
    data-slot="navigation-menu-list"
    ...attributes
  >{{yield}}</@Part>
</template>

interface TriggerSignature {
  Args: NavigationMenuTriggerOptions & {
    /** @internal The item's primitive Trigger. */
    Part: PrimitiveItemBlockParams['Trigger']
    /** The chevron after its text: one from `lucide`. Default lucide's `chevron-down`. */
    icon?: IconNode
    /** The tag to render. Default `button`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** The button that opens its item's content, with a chevron that turns while it is open. */
const NavigationMenuTrigger: TOC<TriggerSignature> = <template>
  <@Part
    @as={{@as}}
    @disabled={{@disabled}}
    class={{TRIGGER_CLASS}}
    data-slot="navigation-menu-trigger"
    ...attributes
  >{{yield}}{{" "}}<Icon
      @icon={{if @icon @icon ChevronDown}}
      class="jn-navigation-menu-trigger-icon"
      aria-hidden="true"
    /></@Part>
</template>

interface ContentSignature {
  Args: NavigationMenuContentArgs & {
    /** @internal The item's primitive Content. */
    Part: PrimitiveItemBlockParams['Content']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** An item's content: in the viewport, or below its trigger with `@viewport={{false}}`. */
const NavigationMenuContent: TOC<ContentSignature> = <template>
  <@Part
    @as={{@as}}
    @forceMount={{@forceMount}}
    @onEscapeKeyDown={{@onEscapeKeyDown}}
    @onPointerDownOutside={{@onPointerDownOutside}}
    @onFocusOutside={{@onFocusOutside}}
    @onInteractOutside={{@onInteractOutside}}
    class="jn-navigation-menu-content"
    data-slot="navigation-menu-content"
    ...attributes
  >{{yield}}</@Part>
</template>

/** What an item yields: its trigger and content, the trigger's modifier, and its state. */
export interface NavigationMenuItemBlockParams {
  /** The button that opens its content. */
  Trigger: WithBoundArgs<typeof NavigationMenuTrigger, 'Part'>
  /** Its content: the links it opens. */
  Content: WithBoundArgs<typeof NavigationMenuContent, 'Part'>
  /** Makes your own element the trigger, styled as one (its chevron is yours). */
  trigger: PartModifier<HTMLElement, NavigationMenuTriggerOptions>
  /** Its value: the menu's `@value` while its content is open. */
  value: string
  /** Whether its content is open. */
  isOpen: boolean
}

interface ItemSignature {
  Args: {
    /** @internal The primitive's Item, bound by the menu. */
    Part: PrimitiveBlockParams['Item']
    /** Its value, for the menu's `@value`. Default: an id of its own. */
    value?: string
    /** The tag to render. Default `li`. */
    as?: TagName
  }
  Blocks: { default: [NavigationMenuItemBlockParams] }
  Element: HTMLLIElement
}

/** An item of the list: a link, or a trigger and its content. */
const NavigationMenuItem: TOC<ItemSignature> = <template>
  <@Part
    @value={{@value}}
    @as={{@as}}
    @triggerLook={{triggerLook}}
    class="jn-navigation-menu-item"
    data-slot="navigation-menu-item"
    ...attributes
    as |item|
  >{{yield
      (hash
        Trigger=(component NavigationMenuTrigger Part=item.Trigger)
        Content=(component NavigationMenuContent Part=item.Content)
        trigger=item.trigger
        value=item.value
        isOpen=item.isOpen
      )
    }}</@Part>
</template>

interface LinkSignature {
  Args: NavigationMenuLinkOptions & {
    /** @internal The primitive's Link, bound by the menu. */
    Part: PrimitiveBlockParams['Link']
    /** The tag to render. Default `a`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLAnchorElement
}

/** A link (give it `href`): `@active` marks the current page. */
const NavigationMenuLink: TOC<LinkSignature> = <template>
  <@Part
    @as={{@as}}
    @active={{@active}}
    @onSelect={{@onSelect}}
    class="jn-navigation-menu-link"
    data-slot="navigation-menu-link"
    ...attributes
  >{{yield}}</@Part>
</template>

interface IndicatorSignature {
  Args: {
    /** @internal The primitive's Indicator, bound by the menu. */
    Part: PrimitiveBlockParams['Indicator']
    /** Keep it rendered while nothing is open. */
    forceMount?: boolean
  }
  Element: HTMLDivElement
}

/** A small arrow under the open trigger. */
const NavigationMenuIndicator: TOC<IndicatorSignature> = <template>
  <@Part
    @forceMount={{@forceMount}}
    class="jn-navigation-menu-indicator"
    data-slot="navigation-menu-indicator"
    ...attributes
  ><div class="jn-navigation-menu-indicator-arrow"></div></@Part>
</template>

interface ViewportSignature {
  Args: {
    /** @internal The primitive's Viewport, bound by the menu. */
    Part: PrimitiveBlockParams['Viewport']
    /** Keep it rendered while nothing is open. */
    forceMount?: boolean
  }
  Element: HTMLDivElement
}

/**
 * The panel every content shows in, below the list, sized to the open content. The root renders
 * one; with `@viewport={{false}}`, `<n.Viewport />` places one yourself.
 */
const NavigationMenuViewport: TOC<ViewportSignature> = <template>
  <div class="jn-navigation-menu-viewport-wrapper">
    <@Part
      @forceMount={{@forceMount}}
      class="jn-navigation-menu-viewport"
      data-slot="navigation-menu-viewport"
      ...attributes
    />
  </div>
</template>

// ----- The menu ---------------------------------------------------------------------------------

/** What a `<NavigationMenu>` yields: its parts, the link modifier, and its state. */
export interface NavigationMenuBlockParams {
  /** The list of items. */
  List: WithBoundArgs<typeof NavigationMenuList, 'Part'>
  /** An item: it yields its Trigger and Content, or holds a Link. */
  Item: WithBoundArgs<typeof NavigationMenuItem, 'Part'>
  /** A link (give it `href`). */
  Link: WithBoundArgs<typeof NavigationMenuLink, 'Part'>
  /** A small arrow under the open trigger. */
  Indicator: WithBoundArgs<typeof NavigationMenuIndicator, 'Part'>
  /**
   * The panel the contents show in, for placing it yourself with `@viewport={{false}}` (the
   * root renders one below the list otherwise).
   */
  Viewport: WithBoundArgs<typeof NavigationMenuViewport, 'Part'>
  /** Makes your own element a link, styled as one: `<LinkTo @route="docs" {{n.link}}>`. */
  link: PartModifier<HTMLElement, NavigationMenuLinkOptions>
  /** The open item's value, or `''`. */
  value: string
  /** Whether a content is open. */
  isOpen: boolean
  /** Opens the content of the item with this value, or closes it (`''`). */
  setValue: (value: string) => void
}

export type NavigationMenuStyledArgs = Omit<NavigationMenuArgs, 'linkLook'> & {
  /**
   * Whether the contents show in one viewport below the list (the default, as upstream's), or
   * each below its own trigger.
   */
  viewport?: boolean
}

export interface NavigationMenuSignature {
  Args: NavigationMenuStyledArgs
  Blocks: { default: [NavigationMenuBlockParams] }
  Element: HTMLElement
}

function hasViewport(viewport: boolean | undefined): boolean {
  return viewport ?? true
}

/**
 * A collection of links for navigating websites: shadcn's Navigation Menu, on the primitives'
 * headless one. It yields its parts:
 *
 *   <NavigationMenu as |n|>
 *     <n.List>
 *       <n.Item as |item|>
 *         <item.Trigger>Item One</item.Trigger>
 *         <item.Content>
 *           <n.Link href="/docs">Link</n.Link>
 *         </item.Content>
 *       </n.Item>
 *     </n.List>
 *   </NavigationMenu>
 *
 * A trigger opens its content on a click or when the pointer rests on it; the contents show in a
 * viewport below the list (`@viewport={{false}}` puts each below its own trigger), sliding in
 * from the side of the trigger they replace.
 */
const NavigationMenu: TOC<NavigationMenuSignature> = <template>
  <NavigationMenuPrimitive
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @delayDuration={{@delayDuration}}
    @skipDelayDuration={{@skipDelayDuration}}
    @orientation={{@orientation}}
    @dir={{@dir}}
    @name={{@name}}
    @as={{@as}}
    @linkLook={{linkLook}}
    class="jn-navigation-menu group/navigation-menu"
    data-slot="navigation-menu"
    data-viewport={{if (hasViewport @viewport) "true" "false"}}
    ...attributes
    as |n|
  >
    {{yield
      (hash
        List=(component NavigationMenuList Part=n.List)
        Item=(component NavigationMenuItem Part=n.Item)
        Link=(component NavigationMenuLink Part=n.Link)
        Indicator=(component NavigationMenuIndicator Part=n.Indicator)
        Viewport=(component NavigationMenuViewport Part=n.Viewport)
        link=n.link
        value=n.value
        isOpen=n.isOpen
        setValue=n.setValue
      )
    }}
    {{#if (hasViewport @viewport)}}
      <NavigationMenuViewport @Part={{n.Viewport}} />
    {{/if}}
  </NavigationMenuPrimitive>
</template>

export default NavigationMenu
