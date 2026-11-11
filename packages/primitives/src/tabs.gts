import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import { buildWaiter } from '@ember/test-waiters'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { ControllableState } from './controllable-state.ts'
import type { Direction } from './direction.gts'
import { idFor } from './id.ts'
import { part, type PartModifier, type PartSpec } from './part.ts'
import { RovingFocus, type RovingFocusItemState } from './roving-focus.gts'

const waiter = buildWaiter('@ember-joinery/primitives:tabs')

/** Which way a tab list runs, and which arrow keys move along it. */
export type TabsOrientation = 'horizontal' | 'vertical'

/**
 * When a tab is selected: as soon as it takes focus (`automatic`, so the arrow keys show each
 * panel in turn), or only when it is clicked or Enter or Space is pressed on it (`manual`).
 */
export type TabsActivationMode = 'automatic' | 'manual'

/** What a tab list takes, as `<t.List>` or the `t.list` modifier. */
export interface TabsListOptions {
  /** Whether the arrow keys wrap round from the last tab to the first and back. Default `true`. */
  loop?: boolean
}

/** What a tab takes, as `<t.Trigger>` or the `t.trigger` modifier. */
export interface TabsTriggerOptions {
  /** The value it selects: the `@value` of the panel it shows. Unique among the tabs. */
  value: string
  /** Whether it can't be selected, and focus passes it by. */
  disabled?: boolean
}

/** What a panel takes, as `<t.Content>` or the `t.content` modifier. */
export interface TabsContentOptions {
  /** The value of the tab that shows it. */
  value: string
  /**
   * Keep it rendered and shown while its tab isn't selected (only `data-state` says so), for
   * hiding or animating it in CSS of your own.
   */
  forceMount?: boolean
}

/** Where a `TabsState` reads its settings. Each is a function, so it reads them live. */
export interface TabsOptions {
  /** The controlled value: the selected tab's. */
  value?: () => string | undefined
  /** The first value, when uncontrolled. Without either, the first tab that isn't disabled. */
  defaultValue?: () => string | undefined
  /** Called with each new value, and the one before (`''` for none). */
  onValueChange?: () => ((value: string, previous: string) => void) | undefined
  /** Default `horizontal`. */
  orientation?: () => TabsOrientation | undefined
  /** The text direction, when the document's shouldn't decide. */
  dir?: () => Direction | undefined
  /** Default `automatic`. */
  activationMode?: () => TabsActivationMode | undefined
}

/** For each element, whether it had an attribute of its own when a part first saw it. */
const own = new WeakMap<Element, Map<string, boolean>>()

/** Whether the element had `name` of its own, before any part set it. Read once, and kept. */
function hasOwn(element: Element, name: string): boolean {
  let names = own.get(element)
  if (!names) own.set(element, (names = new Map()))
  let has = names.get(name)
  if (has === undefined) names.set(name, (has = element.hasAttribute(name)))
  return has
}

/** A link tab: an `<a href>`, such as a `LinkTo`. It navigates, so focus alone never selects it. */
function isLink(element: Element): boolean {
  return element instanceof HTMLAnchorElement && element.hasAttribute('href')
}

/** A value, made safe for an id (an id can't hold spaces). */
function slug(value: string): string {
  return value.replace(/\s+/g, '-')
}

/**
 * `part()`, with the element passed to the spec too: a tab is a `<button>` or a link, and a
 * panel may bring its own `tabindex`, so what each part sets depends on its element.
 */
function elementPart<Named extends object>(
  spec: (named: Named, element: HTMLElement) => PartSpec,
): PartModifier<HTMLElement, Named> {
  const ELEMENT = Symbol('element')
  type WithElement = Named & { [ELEMENT]: HTMLElement }
  const Base = part<HTMLElement, WithElement>(named => spec(named, named[ELEMENT]))
  class ElementPart extends Base {
    override modify(element: HTMLElement, positional: [], named: WithElement): void {
      super.modify(element, positional, { ...named, [ELEMENT]: element })
    }
  }
  return ElementPart as unknown as PartModifier<HTMLElement, Named>
}

/** How a component built on `TabsState` adds its own classes and attributes to a part's. */
export type TabsPartExtension<Named> = (spec: PartSpec, named: Named) => PartSpec

/**
 * Tabs' state and behaviour, as Radix's `Tabs` has them: the selected value, the tab list's
 * roving focus, and the ids that tie each tab to its panel. `<Tabs>` is built on it, and so is
 * the styled one, which adds its classes to the same parts through `listModifier()`,
 * `triggerModifier()` and `contentModifier()`.
 *
 *   tabs = new TabsState({ value: () => this.args.value, defaultValue: () => 'account' })
 *
 *   <div {{this.tabs.list}}>
 *     <button type="button" {{this.tabs.trigger value="account"}}>Account</button>
 *   </div>
 *   <div {{this.tabs.content value="account"}}>…</div>
 */
export class TabsState {
  readonly #options: TabsOptions
  /** The selected value, controlled or the state's own. */
  readonly state: ControllableState<string>
  /** The tab list's roving focus: one tab stop, the arrow keys, Home and End. */
  readonly roving: RovingFocus
  /** Each tab the roving focus knows, by its element. */
  readonly #items = new WeakMap<Element, RovingFocusItemState>()
  /** The list's `loop`, as its modifier last read it. */
  #loop: boolean | undefined
  /** The value before the one being set, for `onValueChange`. */
  #previous = ''
  /** Each panel's value, by its element. */
  readonly #contents = new Map<Element, string>()
  /** The tab a press has just selected, so the focus that follows doesn't ask again. */
  #pressed: Element | undefined
  /** Bumped just after tabs and panels come, go or change: see `#changed()`. */
  @tracked private registrations = 0
  #bumping = false

  /** Put it on the tab list's element: `{{tabs.list}}`, or `{{tabs.list loop=false}}`. */
  readonly list: PartModifier<HTMLElement, TabsListOptions>
  /** Put it on each tab's element: `{{tabs.trigger value="account"}}`. */
  readonly trigger: PartModifier<HTMLElement, TabsTriggerOptions>
  /** Put it on each panel's element: `{{tabs.content value="account"}}`. */
  readonly content: PartModifier<HTMLElement, TabsContentOptions>

  constructor(options: TabsOptions = {}) {
    this.#options = options
    this.state = new ControllableState<string>({
      name: 'value',
      value: () => options.value?.(),
      defaultValue: () => options.defaultValue?.(),
      onChange: () => {
        const onValueChange = options.onValueChange?.()
        return onValueChange && ((value: string) => onValueChange(value, this.#previous))
      },
      fallback: '',
    })
    this.roving = new RovingFocus({
      orientation: () => this.orientation,
      dir: () => options.dir?.(),
      loop: () => this.#loop ?? true,
    })
    this.list = this.listModifier()
    this.trigger = this.triggerModifier()
    this.content = this.contentModifier()
  }

  get orientation(): TabsOrientation {
    return this.#options.orientation?.() ?? 'horizontal'
  }

  get activationMode(): TabsActivationMode {
    return this.#options.activationMode?.() ?? 'automatic'
  }

  /** Whether no value has been given or chosen, so the first tab is selected. */
  get #usesFirst(): boolean {
    return (
      !this.state.isControlled &&
      this.state.value === '' &&
      this.#options.defaultValue?.() === undefined
    )
  }

  /**
   * The selected tab's value. Uncontrolled and with no `defaultValue`, that is the first tab
   * that isn't disabled, as in ember-primitives (Radix selects none); an explicit `''` selects
   * none.
   */
  get value(): string {
    if (!this.#usesFirst) return this.state.value
    void this.registrations
    return this.roving.items().find(item => item.focusable)?.id ?? ''
  }

  /** Whether a tab with this value is rendered. */
  #hasTrigger(value: string): boolean {
    void this.registrations
    return this.roving.items().some(item => item.id === value)
  }

  /** Whether a panel with this value is rendered. */
  #hasContent(value: string): boolean {
    void this.registrations
    return [...this.#contents.values()].includes(value)
  }

  /** Whether the tab with this value is selected. */
  isSelected = (value: string): boolean => this.value === value

  /** Selects a tab, as clicking it does. Nothing happens when it is selected already. */
  select = (value: string): void => {
    const previous = this.value
    if (value === previous) return
    this.#previous = previous
    this.state.set(value)
  }

  /** The id of the tab for a value, which its panel's `aria-labelledby` names. */
  triggerId(value: string): string {
    return idFor(this, `trigger-${slug(value)}`)
  }

  /** The id of the panel for a value, which its tab's `aria-controls` names. */
  contentId(value: string): string {
    return idFor(this, `content-${slug(value)}`)
  }

  /**
   * Tabs and panels come, go and change while the page renders, which can't change what it has
   * read, so what depends on them is read again just after, before the browser paints: which tab
   * is first (while it stands in for a value), and whether a tab's panel and a panel's tab are
   * there for `aria-controls` and `aria-labelledby` to name.
   */
  #changed(): void {
    if (this.#bumping) return
    this.#bumping = true
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      this.#bumping = false
      this.registrations += 1
      waiter.endAsync(token)
    })
  }

  // ----- The parts -------------------------------------------------------------------------

  /**
   * What the tab list puts on its element, as a `part()` spec: Radix's `TabsList`, a
   * `role="tablist"` with `aria-orientation`, that takes the tab stop until a tab has had focus
   * and passes Tab on to the selected tab.
   */
  listSpec = ({ loop }: TabsListOptions): PartSpec => {
    this.#loop = loop
    return {
      attributes: {
        role: 'tablist',
        'aria-orientation': this.orientation,
        'data-orientation': this.orientation,
        'data-test-jn-part': 'list',
      },
      element: element => {
        const tabindex = element.getAttribute('tabindex')
        const uninstall = this.roving.installGroup(element)
        return () => {
          uninstall()
          if (tabindex === null) element.removeAttribute('tabindex')
          else element.setAttribute('tabindex', tabindex)
        }
      },
    }
  }

  /**
   * What a tab puts on its element: Radix's `TabsTrigger`. A `role="tab"` with
   * `aria-selected`, `aria-controls` naming its panel, `data-state` (`active` or `inactive`),
   * `data-disabled`, and a place in the list's roving focus. A press selects it, and so do
   * Enter and Space; in `automatic` mode, so does focus. On a `<button>` it is `type="button"`
   * (unless the button has a type of its own) and `disabled`; on another element, disabled is
   * `aria-disabled`.
   *
   * A link (`<a href>`, a `LinkTo`) is a link tab: a click selects it as it navigates (unless
   * something else, as LinkTo does, handles the click first), and focus never does, whatever the
   * activation mode, because focus doesn't navigate. Link tabs usually take the selection from
   * the route, through `value`.
   */
  triggerSpec = (
    { value, disabled = false }: TabsTriggerOptions,
    element: HTMLElement,
  ): PartSpec => {
    const selected = this.isSelected(value)
    const link = isLink(element)
    const button = element instanceof HTMLButtonElement
    const item = this.#items.get(element)
    if (item) {
      const focusableChanged = item.focusable === disabled
      const idChanged = item.id !== value
      Object.assign(item, { id: value, focusable: !disabled, active: selected })
      if (focusableChanged) this.roving.changed()
      if (focusableChanged || idChanged) this.#changed()
    }
    const roving = (handle: (item: RovingFocusItemState) => void) => {
      const current = this.#items.get(element)
      if (current) handle(current)
    }
    return {
      attributes: {
        role: 'tab',
        type: button && !hasOwn(element, 'type') ? 'button' : undefined,
        'aria-selected': String(selected),
        // Only once its panel is there: upstream's examples show tabs with no panels at all.
        'aria-controls': this.#hasContent(value) ? this.contentId(value) : undefined,
        'data-state': selected ? 'active' : 'inactive',
        'data-disabled': disabled,
        disabled: button && disabled,
        'aria-disabled': !button && disabled ? 'true' : undefined,
        id: this.triggerId(value),
        tabindex: this.roving.currentTabStopId === value ? '0' : '-1',
        'data-orientation': this.orientation,
        'data-test-jn-part': 'trigger',
        'data-test-jn-value': value,
      },
      on: {
        mousedown: (event: MouseEvent) => {
          if (link && !disabled) {
            // A link is selected by its click, so a press to open it elsewhere selects nothing.
          } else if (!disabled && event.button === 0 && !event.ctrlKey) {
            // The focus a press gives comes in the same task; let a later one select as usual.
            this.#pressed = element
            setTimeout(() => {
              if (this.#pressed === element) this.#pressed = undefined
            })
            this.select(value)
          } else {
            // As in Radix: another button, Ctrl, or a disabled tab doesn't even take focus.
            event.preventDefault()
          }
          if (!event.defaultPrevented) roving(item => this.roving.onItemMouseDown(event, item))
        },
        click: (event: MouseEvent) => {
          if (disabled) return event.preventDefault()
          const plain = !event.metaKey && !event.ctrlKey && !event.shiftKey && !event.altKey
          if (link && event.button === 0 && plain) this.select(value)
        },
        keydown: (event: KeyboardEvent) => {
          if (!disabled && !link && (event.key === ' ' || event.key === 'Enter')) {
            this.select(value)
          }
          roving(item => this.roving.onItemKeyDown(event, item))
        },
        focus: () => {
          // The press that focused it has selected it already (or asked to, when controlled).
          if (this.#pressed === element) return void (this.#pressed = undefined)
          if (!disabled && !link && this.activationMode === 'automatic') this.select(value)
        },
        focusin: () => this.roving.onItemFocus(value),
      },
      element: element => {
        const state: RovingFocusItemState = {
          element,
          id: value,
          focusable: !disabled,
          active: selected,
        }
        this.#items.set(element, state)
        const unregister = this.roving.register(state)
        this.#changed()
        return () => {
          unregister()
          this.#items.delete(element)
          this.#changed()
        }
      },
    }
  }

  /**
   * What a panel puts on its element: Radix's `TabsContent`. A `role="tabpanel"`, labelled by
   * its tab, with `data-state`, and `hidden` while its tab isn't selected (unless
   * `forceMount`). It is in the tab order (`tabindex="0"`, unless it has a `tabindex` of its
   * own), so a panel with nothing to focus can still be reached.
   */
  contentSpec = (
    { value, forceMount = false }: TabsContentOptions,
    element: HTMLElement,
  ): PartSpec => {
    const selected = this.isSelected(value)
    if (this.#contents.get(element) !== value) {
      this.#contents.set(element, value)
      this.#changed()
    }
    return {
      attributes: {
        role: 'tabpanel',
        id: this.contentId(value),
        'aria-labelledby': this.#hasTrigger(value) ? this.triggerId(value) : undefined,
        tabindex: hasOwn(element, 'tabindex') ? undefined : '0',
        'data-state': selected ? 'active' : 'inactive',
        'data-orientation': this.orientation,
        hidden: !selected && !forceMount,
        'data-test-jn-part': 'content',
        'data-test-jn-value': value,
      },
      element: element => () => {
        this.#contents.delete(element)
        this.#changed()
      },
    }
  }

  /** The tab list's modifier, with `extend` adding to it: a styled list's classes. */
  listModifier<Named extends TabsListOptions = TabsListOptions>(
    extend?: TabsPartExtension<Named>,
  ): PartModifier<HTMLElement, Named> {
    return part<HTMLElement, Named>(named => {
      const spec = this.listSpec(named)
      return extend ? extend(spec, named) : spec
    })
  }

  /** A tab's modifier, with `extend` adding to it: a styled tab's classes. */
  triggerModifier<Named extends TabsTriggerOptions = TabsTriggerOptions>(
    extend?: TabsPartExtension<Named>,
  ): PartModifier<HTMLElement, Named> {
    return elementPart<Named>((named, element) => {
      const spec = this.triggerSpec(named, element)
      return extend ? extend(spec, named) : spec
    })
  }

  /** A panel's modifier, with `extend` adding to it: a styled panel's classes. */
  contentModifier<Named extends TabsContentOptions = TabsContentOptions>(
    extend?: TabsPartExtension<Named>,
  ): PartModifier<HTMLElement, Named> {
    return elementPart<Named>((named, element) => {
      const spec = this.contentSpec(named, element)
      return extend ? extend(spec, named) : spec
    })
  }
}

export interface TabsListSignature {
  Args: TabsListOptions & {
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by `<Tabs>`. */
    tabs: TabsState
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The tab list, yielded as `t.List`: a `role="tablist"` around the tabs. */
const TabsList: TOC<TabsListSignature> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@tabs.list loop=@loop}}>{{yield}}</As>
</template>

export interface TabsTriggerSignature {
  Args: TabsTriggerOptions & {
    /** The tag to render. Default `button`; `a` (with `href`) for a link tab. */
    as?: TagName
    /** @internal Bound by `<Tabs>`. */
    tabs: TabsState
  }
  Blocks: { default: [] }
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

/**
 * A panel, yielded as `t.Content`: a `role="tabpanel"` whose block renders only while its tab is
 * selected (or with `@forceMount`). The panel itself stays, `hidden`, so its tab's
 * `aria-controls` always names an element.
 */
class TabsContent extends Component<TabsContentSignature> {
  get isShown(): boolean {
    return Boolean(this.args.forceMount) || this.args.tabs.isSelected(this.args.value)
  }

  <template>
    <As @as={{@as}} @tag="div" ...attributes {{@tabs.content value=@value forceMount=@forceMount}}>
      {{#if this.isShown}}{{yield}}{{/if}}
    </As>
  </template>
}

/** What `<Tabs>` yields. */
export interface TabsYield {
  /** The tab list: `<t.List aria-label="Settings">`. */
  List: WithBoundArgs<typeof TabsList, 'tabs'>
  /** A tab: `<t.Trigger @value="account">Account</t.Trigger>`. */
  Trigger: WithBoundArgs<typeof TabsTrigger, 'tabs'>
  /** A panel: `<t.Content @value="account">…</t.Content>`. */
  Content: WithBoundArgs<typeof TabsContent, 'tabs'>
  /** The tab list, as a modifier on your own element: `<ul {{t.list}}>`. */
  list: TabsState['list']
  /** A tab, as a modifier on your own element or component: `<LinkTo {{t.trigger value="a"}}>`. */
  trigger: TabsState['trigger']
  /** A panel, as a modifier on your own element: `<section {{t.content value="a"}}>`. */
  content: TabsState['content']
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
 * Radix's `Tabs`, headless, which also covers ember-primitives' (link tabs, the activation mode,
 * and the first tab selected when no value is given).
 *
 *   <Tabs @defaultValue="account" as |t|>
 *     <t.List aria-label="Settings">
 *       <t.Trigger @value="account">Account</t.Trigger>
 *       <t.Trigger @value="password">Password</t.Trigger>
 *     </t.List>
 *     <t.Content @value="account">Make changes to your account here.</t.Content>
 *     <t.Content @value="password">Change your password here.</t.Content>
 *   </Tabs>
 *
 * The tabs share one tab stop; the arrow keys along `@orientation` move between them (right to
 * left, the left arrow moves forward) and wrap round, and Home and End go to the ends.
 */
export class Tabs extends Component<TabsSignature> {
  tabs = new TabsState({
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    onValueChange: () => this.args.onValueChange,
    orientation: () => this.args.orientation,
    dir: () => this.args.dir,
    activationMode: () => this.args.activationMode,
  })

  <template>
    <As
      @as={{@as}}
      @tag="div"
      dir={{@dir}}
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
          list=this.tabs.list
          trigger=this.tabs.trigger
          content=this.tabs.content
          value=this.tabs.value
          isSelected=this.tabs.isSelected
          select=this.tabs.select
        )
      }}
    </As>
  </template>
}

export default Tabs
