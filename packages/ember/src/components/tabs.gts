import Component from '@glimmer/component'
import { get, hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import type { Direction } from '@ember-joinery/primitives/direction'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  TabsState,
  type TabsActivationMode,
  type TabsContentOptions,
  type TabsListOptions,
  type TabsOrientation,
  type TabsTriggerOptions,
} from '@ember-joinery/primitives/tabs'

/** How a tab list looks: a muted bar the selected tab sits up out of, or a line under it. */
export type TabsListVariant = 'default' | 'line'

/** A tab list's look: what both `<t.List>` and the `t.list` modifier take. */
export interface TabsListStyle {
  /** Default `default`. */
  variant?: TabsListVariant
}

/**
 * The classes a tab list renders: upstream's `tabsListVariants`, renamed `jn-` (`jn-tabs-list
 * jn-tabs-list-variant-line`), and the `group/tabs-list` marker its tabs' rules look for.
 */
export function tabsListClasses({ variant = 'default' }: TabsListStyle = {}): string {
  return `jn-tabs-list group/tabs-list jn-tabs-list-variant-${variant}`
}

/** The data attributes a tab list renders, as upstream's. */
export interface TabsListAttributes {
  'data-slot': 'tabs-list'
  'data-variant': TabsListVariant
  [attribute: string]: string | undefined
}

/** The data attributes a tab list renders, as upstream's. */
export function tabsListAttributes({
  variant = 'default',
}: TabsListStyle = {}): TabsListAttributes {
  return { 'data-slot': 'tabs-list', 'data-variant': variant }
}

/** What the styled `t.list` modifier takes: the list's behaviour, and its look. */
export type TabsListModifierOptions = TabsListOptions & TabsListStyle

export interface TabsListSignature {
  Args: TabsListModifierOptions & {
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by `<Tabs>`. */
    tabs: TabsState
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The tab list, yielded as `t.List`: a `role="tablist"` around the tabs, with `@variant`. */
class TabsList extends Component<TabsListSignature> {
  get classes(): string {
    return tabsListClasses(this.args)
  }

  get attributes(): TabsListAttributes {
    return tabsListAttributes(this.args)
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      class={{this.classes}}
      data-slot={{get this.attributes "data-slot"}}
      data-variant={{get this.attributes "data-variant"}}
      ...attributes
      {{@tabs.list loop=@loop}}
    >{{yield}}</As>
  </template>
}

export interface TabsTriggerSignature {
  Args: TabsTriggerOptions & {
    /** The tag to render. Default `button`; `a` (with `href`) for a link tab. */
    as?: TagName
    /** @internal Bound by `<Tabs>`. */
    tabs: TabsState
  }
  Blocks: {
    /** The label, and any icons (mark an icon's side with `data-icon="inline-start"` or `"inline-end"`). */
    default: []
  }
  /** A `<button>`, or with `@as="a"`, a link. */
  Element: HTMLButtonElement | HTMLAnchorElement
}

/** A tab, yielded as `t.Trigger`: a `<button type="button">` with `role="tab"`. */
class TabsTrigger extends Component<TabsTriggerSignature> {
  get type(): string | undefined {
    return (this.args.as ?? 'button') === 'button' ? 'button' : undefined
  }

  <template>
    <As
      @as={{@as}}
      @tag="button"
      type={{this.type}}
      class="jn-tabs-trigger"
      data-slot="tabs-trigger"
      ...attributes
      {{@tabs.trigger value=@value disabled=@disabled}}
    >{{yield}}</As>
  </template>
}

export interface TabsContentSignature {
  Args: TabsContentOptions & {
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by `<Tabs>`. */
    tabs: TabsState
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** A panel, yielded as `t.Content`: its block renders while its tab is selected. */
class TabsContent extends Component<TabsContentSignature> {
  get isShown(): boolean {
    return Boolean(this.args.forceMount) || this.args.tabs.isSelected(this.args.value)
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      class="jn-tabs-content"
      data-slot="tabs-content"
      ...attributes
      {{@tabs.content value=@value forceMount=@forceMount}}
    >
      {{#if this.isShown}}{{yield}}{{/if}}
    </As>
  </template>
}

/** What `<Tabs>` yields. */
export interface TabsYield {
  /** The tab list: `<t.List @variant="line">`. */
  List: WithBoundArgs<typeof TabsList, 'tabs'>
  /** A tab: `<t.Trigger @value="account">Account</t.Trigger>`. */
  Trigger: WithBoundArgs<typeof TabsTrigger, 'tabs'>
  /** A panel: `<t.Content @value="account">…</t.Content>`. */
  Content: WithBoundArgs<typeof TabsContent, 'tabs'>
  /**
   * The tab list, as a modifier on your own element, with the same classes and attributes as
   * `t.List`: `<nav {{t.list variant="line"}}>`.
   */
  list: PartModifier<HTMLElement, TabsListModifierOptions>
  /**
   * A tab, as a modifier on your own element or component, with the same classes and
   * attributes as `t.Trigger`: `<LinkTo @route="billing" {{t.trigger value="billing"}}>`.
   */
  trigger: PartModifier<HTMLElement, TabsTriggerOptions>
  /** A panel, as a modifier on your own element: `<section {{t.content value="billing"}}>`. */
  content: PartModifier<HTMLElement, TabsContentOptions>
  /** The selected tab's value, or `''` for none. */
  value: string
  /** Whether a tab is selected: `(t.isSelected "account")`. */
  isSelected: (value: string) => boolean
  /** Selects a tab. */
  select: (value: string) => void
}

export interface TabsSignature {
  Args: {
    /** The controlled value: the selected tab's. */
    value?: string
    /** The first value, when uncontrolled. Without either, the first tab that isn't disabled. */
    defaultValue?: string
    /** Called with each new value, and the one before it (`''` for none). */
    onValueChange?: (value: string, previous: string) => void
    /** Which way the tabs run, and which arrow keys move between them. Default `horizontal`. */
    orientation?: TabsOrientation
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /** Whether focus selects a tab (`automatic`, the default), or only a press does (`manual`). */
    activationMode?: TabsActivationMode
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `TabsHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [TabsYield] }
  Element: HTMLDivElement
}

/**
 * A set of layered sections of content, known as tab panels, that are displayed one at a time:
 * shadcn's Tabs, on the primitives' `TabsState`.
 *
 *   <Tabs @defaultValue="account" class="w-[400px]" as |t|>
 *     <t.List>
 *       <t.Trigger @value="account">Account</t.Trigger>
 *       <t.Trigger @value="password">Password</t.Trigger>
 *     </t.List>
 *     <t.Content @value="account">Make changes to your account here.</t.Content>
 *     <t.Content @value="password">Change your password here.</t.Content>
 *   </Tabs>
 *
 * `<t.List @variant="line">` draws a line under the selected tab instead of raising it, and
 * `@orientation="vertical"` stacks the tabs beside their panels. The tabs share one tab stop,
 * and the arrow keys along the orientation move between them.
 */
export default class Tabs extends Component<TabsSignature> {
  tabs = new TabsState({
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    onValueChange: () => this.args.onValueChange,
    orientation: () => this.args.orientation,
    dir: () => this.args.dir,
    activationMode: () => this.args.activationMode,
  })

  /** The list's modifier: the primitive's behaviour, with the styled list's look. */
  list: PartModifier<HTMLElement, TabsListModifierOptions> =
    this.tabs.listModifier<TabsListModifierOptions>((spec, named) => ({
      ...spec,
      class: tabsListClasses(named),
      attributes: { ...spec.attributes, ...tabsListAttributes(named) },
    }))

  /** The tabs' modifier: the primitive's behaviour, with the styled tab's look. */
  trigger: PartModifier<HTMLElement, TabsTriggerOptions> = this.tabs.triggerModifier(spec => ({
    ...spec,
    class: 'jn-tabs-trigger',
    attributes: { ...spec.attributes, 'data-slot': 'tabs-trigger' },
  }))

  /** The panels' modifier: the primitive's behaviour, with the styled panel's look. */
  content: PartModifier<HTMLElement, TabsContentOptions> = this.tabs.contentModifier(spec => ({
    ...spec,
    class: 'jn-tabs-content',
    attributes: { ...spec.attributes, 'data-slot': 'tabs-content' },
  }))

  <template>
    <As
      @as={{@as}}
      @tag="div"
      dir={{@dir}}
      class="jn-tabs group/tabs"
      data-slot="tabs"
      data-orientation={{this.tabs.orientation}}
      data-test-jn="tabs"
      data-test-jn-name={{@name}}
      ...attributes
    >
      {{yield
        (hash
          List=(component TabsList tabs=this.tabs)
          Trigger=(component TabsTrigger tabs=this.tabs)
          Content=(component TabsContent tabs=this.tabs)
          list=this.list
          trigger=this.trigger
          content=this.content
          value=this.tabs.value
          isSelected=this.tabs.isSelected
          select=this.tabs.select
        )
      }}
    </As>
  </template>
}
