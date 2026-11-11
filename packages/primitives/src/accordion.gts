import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import {
  CollapsibleContent,
  CollapsibleState,
  COLLAPSIBLE_CONTENT_HEIGHT,
  COLLAPSIBLE_CONTENT_WIDTH,
  type CollapsibleContentOptions,
  type CollapsibleDataState,
} from './collapsible.gts'
import { ControllableState } from './controllable-state.ts'
import { getDirection, type Direction } from './direction.gts'
import { idFor } from './id.ts'
import { part, type PartModifier, type PartSpec } from './part.ts'

/** Whether one item can be open at a time (`single`), or any number (`multiple`). */
export type AccordionType = 'single' | 'multiple'

/**
 * An accordion's value, by its type: the open item's value (`''` for none) for `single`, and
 * the open items' values for `multiple`.
 */
export type AccordionValue<T extends AccordionType> = T extends 'multiple' ? string[] : string

/** Which way the items run, and so which arrow keys move between their triggers. */
export type AccordionOrientation = 'vertical' | 'horizontal'

/** The CSS variables an accordion's content reads its size from, as Radix names them. */
export const ACCORDION_CONTENT_HEIGHT = '--radix-accordion-content-height'
export const ACCORDION_CONTENT_WIDTH = '--radix-accordion-content-width'

/** The keys an accordion's triggers answer, as Radix's. */
const ACCORDION_KEYS = ['Home', 'End', 'ArrowDown', 'ArrowUp', 'ArrowLeft', 'ArrowRight']

/** Where an `AccordionState` reads its settings. Each is a function, so it reads them live. */
export interface AccordionOptions {
  type: () => AccordionType
  /** The controlled value. */
  value?: () => string | string[] | undefined
  /** The first value, when uncontrolled. */
  defaultValue?: () => string | string[] | undefined
  /** Called with each new value. */
  onValueChange?: () => ((value: never) => void) | undefined
  /** For `single`: whether the open item can be closed, leaving none open. Default `false`. */
  collapsible?: () => boolean | undefined
  /** Whether no item can be opened or closed. */
  disabled?: () => boolean | undefined
  /** Which arrow keys move between the triggers. Default `vertical`. */
  orientation?: () => AccordionOrientation | undefined
  /** The text direction, when the document's (`getDirection`) shouldn't decide. */
  dir?: () => Direction | undefined
}

/** Sorts elements into document order. */
function inDocumentOrder(elements: Iterable<HTMLElement>): HTMLElement[] {
  return [...elements].sort((a, b) =>
    a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1,
  )
}

/**
 * An accordion's state and behaviour, as Radix's `Accordion` has them: the value, the
 * keyboard movement between its triggers, and each item's open state. `<Accordion>` is built on
 * it, and so is the styled one; each item is an `AccordionItemState`.
 *
 *   accordion = new AccordionState({ type: () => 'single', collapsible: () => true })
 *   <div {{this.accordion.root}}>…</div>
 */
export class AccordionState {
  readonly #options: AccordionOptions
  /** The value, controlled or the accordion's own. */
  readonly state: ControllableState<string | string[]>
  /** Each item's trigger, for the arrow keys. */
  readonly #triggers = new Set<HTMLElement>()

  /** Put it on the accordion's element: `data-orientation`, and the arrow keys. */
  readonly root: PartModifier

  constructor(options: AccordionOptions) {
    this.#options = options
    this.state = new ControllableState<string | string[]>({
      name: 'value',
      value: () => options.value?.(),
      defaultValue: () => options.defaultValue?.() ?? (this.type === 'multiple' ? [] : ''),
      onChange: () => options.onValueChange?.() as ((value: string | string[]) => void) | undefined,
      fallback: '',
    })
    this.root = part(() => this.rootSpec())
  }

  get type(): AccordionType {
    return this.#options.type()
  }

  /** Whether the open item can be closed: always for `multiple`, `@collapsible` for `single`. */
  get isCollapsible(): boolean {
    return this.type === 'multiple' || (this.#options.collapsible?.() ?? false)
  }

  get isDisabled(): boolean {
    return this.#options.disabled?.() ?? false
  }

  get orientation(): AccordionOrientation {
    return this.#options.orientation?.() ?? 'vertical'
  }

  /** The values of the open items. */
  get values(): string[] {
    const value = this.state.value
    if (Array.isArray(value)) return value
    return value ? [value] : []
  }

  /** The value, as the accordion's type has it: a string for `single`, an array for `multiple`. */
  get value(): string | string[] {
    return this.type === 'multiple' ? this.values : (this.values[0] ?? '')
  }

  /** Whether the item with this value is open. */
  isOpen = (value: string): boolean => Boolean(value) && this.values.includes(value)

  /** Opens an item: in a `single` accordion, the one open before closes. */
  openItem = (value: string): void => {
    if (this.type === 'multiple') this.state.set([...this.values, value])
    else this.state.set(value)
  }

  /** Closes an item, unless it is a `single` accordion that isn't `@collapsible`. */
  closeItem = (value: string): void => {
    if (this.type === 'multiple') this.state.set(this.values.filter(other => other !== value))
    else if (this.isCollapsible) this.state.set('')
  }

  /** @internal An item's trigger, for the arrow keys; returns its unregistration. */
  registerTrigger(element: HTMLElement): () => void {
    this.#triggers.add(element)
    return () => this.#triggers.delete(element)
  }

  /** The triggers, in document order. */
  triggers(): HTMLElement[] {
    return inDocumentOrder(this.#triggers)
  }

  /**
   * What the accordion's element takes, as a `part()` spec: `data-orientation`, and, unless it
   * is disabled, the keys that move focus between the triggers.
   */
  rootSpec(): PartSpec {
    return {
      attributes: { 'data-orientation': this.orientation },
      on: { keydown: this.onKeyDown },
    }
  }

  /**
   * The keys, as Radix's accordion has them: Home and End go to the first and last trigger, and
   * the arrows along the orientation to the previous and next, wrapping round (left and right
   * swap right to left). Disabled triggers are passed over.
   */
  onKeyDown = (event: KeyboardEvent): void => {
    if (this.isDisabled || !ACCORDION_KEYS.includes(event.key)) return
    const triggers = this.triggers().filter(trigger => !trigger.hasAttribute('disabled'))
    const index = triggers.indexOf(event.target as HTMLElement)
    const count = triggers.length
    if (index === -1) return
    event.preventDefault()

    const root = event.currentTarget as HTMLElement
    const ltr = getDirection(root, this.#options.dir?.()) === 'ltr'
    const horizontal = this.orientation === 'horizontal'
    const next = () => (index + 1) % count
    const previous = () => (index - 1 + count) % count
    let target = index
    switch (event.key) {
      case 'Home':
        target = 0
        break
      case 'End':
        target = count - 1
        break
      case 'ArrowRight':
        if (horizontal) target = ltr ? next() : previous()
        break
      case 'ArrowLeft':
        if (horizontal) target = ltr ? previous() : next()
        break
      case 'ArrowDown':
        if (!horizontal) target = next()
        break
      case 'ArrowUp':
        if (!horizontal) target = previous()
        break
    }
    triggers[target]?.focus()
  }
}

/** Where an `AccordionItemState` reads its settings. */
export interface AccordionItemOptions {
  /** The item's value, unique in its accordion. */
  value: () => string
  /** Whether it can't be opened or closed (the accordion's `@disabled` does the same). */
  disabled?: () => boolean | undefined
}

/**
 * One item of an accordion, as Radix's `AccordionItem`: a collapsible whose open state is the
 * accordion's value, with a header, a trigger that names the content (and that the content's
 * `region` is labelled by), and the content. It makes the item's parts as modifiers, which the
 * headless and the styled accordions both put on their elements.
 */
export class AccordionItemState {
  readonly accordion: AccordionState
  readonly #options: AccordionItemOptions
  /** The item's collapsible, open while the accordion's value includes it. */
  readonly collapsible: CollapsibleState

  /** Put it on the item's element. */
  readonly item: PartModifier
  /** Put it on the header's element (an `<h3>`, as Radix's). */
  readonly header: PartModifier
  /** Put it on the trigger's element. */
  readonly trigger: PartModifier
  /** Put it on the content's element, with whether it is shown. */
  readonly content: PartModifier<HTMLElement, CollapsibleContentOptions>

  constructor(accordion: AccordionState, options: AccordionItemOptions) {
    this.accordion = accordion
    this.#options = options
    this.collapsible = new CollapsibleState({
      open: () => accordion.isOpen(this.value),
      onOpenChange: () => open => {
        if (open) accordion.openItem(this.value)
        else accordion.closeItem(this.value)
      },
      disabled: () => this.isDisabled,
    })
    this.item = part(() => this.itemSpec())
    this.header = part(() => this.headerSpec())
    this.trigger = part(() => this.triggerSpec())
    this.content = part<HTMLElement, CollapsibleContentOptions>(named => this.contentSpec(named))
  }

  get value(): string {
    return this.#options.value()
  }

  get isOpen(): boolean {
    return this.collapsible.isOpen
  }

  /** Whether it can't be opened or closed: its own `@disabled`, or the accordion's. */
  get isDisabled(): boolean {
    return this.accordion.isDisabled || (this.#options.disabled?.() ?? false)
  }

  get dataState(): CollapsibleDataState {
    return this.collapsible.dataState
  }

  /** The trigger's id, which the content's `aria-labelledby` names. */
  get triggerId(): string {
    return idFor(this, 'trigger')
  }

  /** The content's id, which the trigger's `aria-controls` names. */
  get contentId(): string {
    return this.collapsible.contentId
  }

  /** Opens it or closes it, as its trigger does. */
  toggle = (): void => this.collapsible.toggle()

  /** The attributes every part of the item shares: its state, and its value for the harness. */
  #shared(part: string): Record<string, string | boolean | undefined> {
    return {
      'data-orientation': this.accordion.orientation,
      'data-state': this.dataState,
      'data-disabled': this.isDisabled,
      'data-test-jn-part': part,
      'data-test-jn-value': this.value,
    }
  }

  /** The item's element: Radix's `AccordionItem`, which is a collapsible's root. */
  itemSpec(): PartSpec {
    return { attributes: this.#shared('item') }
  }

  /** The header's element: Radix's `AccordionHeader`. */
  headerSpec(): PartSpec {
    return { attributes: this.#shared('header') }
  }

  /**
   * The trigger: a collapsible's trigger (`aria-expanded`, `aria-controls`, `disabled`), with
   * its own id, `aria-disabled` while it is the open item of a `single` accordion that can't
   * close it, and a place in the accordion's arrow keys.
   */
  triggerSpec(): PartSpec {
    const spec = this.collapsible.triggerSpec()
    const register = spec.element
    return {
      ...spec,
      attributes: {
        ...spec.attributes,
        ...this.#shared('trigger'),
        id: this.triggerId,
        'aria-disabled': this.isOpen && !this.accordion.isCollapsible ? 'true' : undefined,
      },
      element: element => {
        register?.(element)
        return this.accordion.registerTrigger(element)
      },
    }
  }

  /**
   * The content: a collapsible's content, as a `region` labelled by its trigger, with
   * `--radix-accordion-content-height` and `-width` reading the measured size.
   */
  contentSpec(options: CollapsibleContentOptions): PartSpec {
    const spec = this.collapsible.contentSpec(options)
    return {
      ...spec,
      attributes: {
        ...spec.attributes,
        ...this.#shared('content'),
        role: 'region',
        'aria-labelledby': this.triggerId,
      },
      element: element => {
        element.style.setProperty(ACCORDION_CONTENT_HEIGHT, `var(${COLLAPSIBLE_CONTENT_HEIGHT})`)
        element.style.setProperty(ACCORDION_CONTENT_WIDTH, `var(${COLLAPSIBLE_CONTENT_WIDTH})`)
        return () => {
          element.style.removeProperty(ACCORDION_CONTENT_HEIGHT)
          element.style.removeProperty(ACCORDION_CONTENT_WIDTH)
        }
      },
    }
  }
}

export interface AccordionTriggerSignature {
  Args: {
    /** The tag to render. Default `button`. */
    as?: TagName
    /** @internal Bound by the item. */
    item: AccordionItemState
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** The button that opens and closes an item, yielded as `item.Trigger` and `header.Trigger`. */
export const AccordionTrigger: TOC<AccordionTriggerSignature> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@item.trigger}}>{{yield}}</As>
</template>

export interface AccordionHeaderSignature {
  Args: {
    /** The tag to render. Default `h3`; use the heading level that fits the page. */
    as?: TagName
    /** @internal Bound by the item. */
    item: AccordionItemState
  }
  Blocks: {
    default: [
      {
        /** The item's trigger, which goes inside its header. */
        Trigger: WithBoundArgs<typeof AccordionTrigger, 'item'>
      },
    ]
  }
  Element: HTMLHeadingElement
}

/** The heading an item's trigger goes in, yielded as `item.Header`: an `<h3>`, as Radix's. */
export const AccordionHeader: TOC<AccordionHeaderSignature> = <template>
  <As @as={{@as}} @tag="h3" ...attributes {{@item.header}}>
    {{yield (hash Trigger=(component AccordionTrigger item=@item))}}
  </As>
</template>

export interface AccordionContentSignature {
  Args: {
    /** Keep the content rendered and shown while closed, for animating it yourself. */
    forceMount?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by the item. */
    item: AccordionItemState
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * What an item shows and hides, yielded as `item.Content`: a collapsible's content (always in
 * the document, `hidden` and empty while closed), as a `region` labelled by the item's trigger.
 */
export const AccordionContent: TOC<AccordionContentSignature> = <template>
  <CollapsibleContent
    @as={{@as}}
    @forceMount={{@forceMount}}
    @collapsible={{@item.collapsible}}
    @part={{@item.content}}
    ...attributes
  >{{yield}}</CollapsibleContent>
</template>

/** What `<a.Item>` yields. */
export interface AccordionItemYield {
  /** The heading its trigger goes in: `<item.Header as |h|><h.Trigger>…</h.Trigger></item.Header>`. */
  Header: WithBoundArgs<typeof AccordionHeader, 'item'>
  /** The button that opens and closes it. Put it in `item.Header`. */
  Trigger: WithBoundArgs<typeof AccordionTrigger, 'item'>
  /** What it shows and hides. */
  Content: WithBoundArgs<typeof AccordionContent, 'item'>
  /** The trigger, as a modifier on your own element or component. */
  trigger: PartModifier
  /** Whether it is open. */
  isOpen: boolean
  /** The same, by the name ember-primitives' accordion yields it. */
  isExpanded: boolean
  /** Whether it can't be opened or closed. */
  isDisabled: boolean
  /** Opens or closes it. */
  toggle: () => void
}

export interface AccordionItemSignature {
  Args: {
    /** The item's value, unique in its accordion. */
    value: string
    /** Whether it can't be opened or closed. */
    disabled?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by the accordion. */
    accordion: AccordionState
  }
  Blocks: { default: [AccordionItemYield] }
  Element: HTMLDivElement
}

/** One of an accordion's items, yielded as `a.Item`. */
export class AccordionItem extends Component<AccordionItemSignature> {
  item = new AccordionItemState(this.args.accordion, {
    value: () => this.args.value,
    disabled: () => this.args.disabled,
  })

  <template>
    <As @as={{@as}} @tag="div" ...attributes {{this.item.item}}>
      {{yield
        (hash
          Header=(component AccordionHeader item=this.item)
          Trigger=(component AccordionTrigger item=this.item)
          Content=(component AccordionContent item=this.item)
          trigger=this.item.trigger
          isOpen=this.item.isOpen
          isExpanded=this.item.isOpen
          isDisabled=this.item.isDisabled
          toggle=this.item.toggle
        )
      }}
    </As>
  </template>
}

/** What `<Accordion>` yields. */
export interface AccordionYield<T extends AccordionType> {
  /** An item: `<a.Item @value="shipping" as |item|>`. */
  Item: WithBoundArgs<typeof AccordionItem, 'accordion'>
  /** The value: the open item's (`''` for none), or the open items'. */
  value: AccordionValue<T>
}

export interface AccordionSignature<T extends AccordionType> {
  Args: {
    /** `single`: one item open at a time. `multiple`: any number. */
    type: T
    /** The controlled value. Pass `@onValueChange` too, to hear the triggers. */
    value?: AccordionValue<T>
    /** The first value, when uncontrolled. */
    defaultValue?: AccordionValue<T>
    /** Called with each new value. */
    onValueChange?: (value: AccordionValue<T>) => void
    /** For `single`: whether the open item can be closed, leaving none open. Default `false`. */
    collapsible?: boolean
    /** Whether no item can be opened or closed. */
    disabled?: boolean
    /** Which arrow keys move between the triggers: up and down, or left and right. Default `vertical`. */
    orientation?: AccordionOrientation
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `AccordionHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [AccordionYield<T>] }
  Element: HTMLDivElement
}

/**
 * A vertically stacked set of interactive headings that each reveal a section of content:
 * Radix's `Accordion`, headless, which also covers ember-primitives'. Each item is a heading
 * with a trigger (`aria-expanded`, `aria-controls`) and a content `region` labelled by it:
 *
 *   <Accordion @type="single" @collapsible={{true}} @defaultValue="item-1" as |a|>
 *     <a.Item @value="item-1" as |item|>
 *       <item.Header as |h|><h.Trigger>Is it accessible?</h.Trigger></item.Header>
 *       <item.Content>Yes. It adheres to the WAI-ARIA design pattern.</item.Content>
 *     </a.Item>
 *   </Accordion>
 *
 * `single` keeps one item open (and, unless `@collapsible`, always one once opened);
 * `multiple` opens any number. The arrow keys, Home and End move between the triggers.
 */
export class Accordion<T extends AccordionType = 'single'> extends Component<
  AccordionSignature<T>
> {
  accordion = new AccordionState({
    type: () => this.args.type,
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    onValueChange: () => this.args.onValueChange as ((value: never) => void) | undefined,
    collapsible: () => this.args.collapsible,
    disabled: () => this.args.disabled,
    orientation: () => this.args.orientation,
    dir: () => this.args.dir,
  })

  get value(): AccordionValue<T> {
    return this.accordion.value as AccordionValue<T>
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      data-test-jn="accordion"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.accordion.root}}
    >
      {{yield (hash Item=(component AccordionItem accordion=this.accordion) value=this.value)}}
    </As>
  </template>
}
