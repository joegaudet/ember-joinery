import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import { registerDestructor } from '@ember/destroyable'
import Modifier from 'ember-modifier'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { ControllableState } from './controllable-state.ts'
import { idFor } from './id.ts'
import { part, type PartModifier, type PartSpec } from './part.ts'
import { Presence } from './presence.gts'

/** Radix's `data-state` for a collapsible's parts. */
export type CollapsibleDataState = 'open' | 'closed'

/** Where a `CollapsibleState` reads its settings. Each is a function, so it reads them live. */
export interface CollapsibleOptions {
  /** The controlled open state. */
  open?: () => boolean | undefined
  /** Whether it starts open, when uncontrolled. */
  defaultOpen?: () => boolean | undefined
  /** Called with each new open state. */
  onOpenChange?: () => ((open: boolean) => void) | undefined
  /** Whether the trigger can't open or close it. */
  disabled?: () => boolean | undefined
}

/** What the content part takes: whether its content shows, from the content's `Presence`. */
export interface CollapsibleContentOptions {
  /** Open, on its way out, or force-mounted: the content is rendered and not `hidden`. */
  shown: boolean
}

/** The CSS variables the content's size is measured into, as Radix names them. */
export const COLLAPSIBLE_CONTENT_HEIGHT = '--radix-collapsible-content-height'
export const COLLAPSIBLE_CONTENT_WIDTH = '--radix-collapsible-content-width'

/** Whether an element is a `<button>`, which a trigger makes `type="button"`. */
function isButton(element: Element): element is HTMLButtonElement {
  return element.localName === 'button'
}

/**
 * A collapsible's state and behaviour, as Radix's `Collapsible` has them: the open state, the
 * ids that tie the trigger to the content, and the parts. `<Collapsible>` is built on it, and so
 * are the styled Collapsible and each item of an accordion, which add their own attributes to
 * the same parts through `triggerSpec()` and `contentSpec()`.
 *
 *   collapsible = new CollapsibleState({
 *     open: () => this.args.open,
 *     defaultOpen: () => this.args.defaultOpen,
 *     onOpenChange: () => this.args.onOpenChange,
 *   })
 *   <button type="button" {{this.collapsible.trigger}}>Details</button>
 */
export class CollapsibleState {
  readonly #options: CollapsibleOptions
  /** The open state, controlled or the collapsible's own. */
  readonly state: ControllableState<boolean>

  /** Put it on the trigger's element: `<button {{c.trigger}}>`. */
  readonly trigger: PartModifier
  /** Put it on the content's element, with whether it is shown. */
  readonly content: PartModifier<HTMLElement, CollapsibleContentOptions>
  /**
   * Put it on the content's element, after `content`: it measures the content into
   * `--radix-collapsible-content-height` and `-width` each time it opens or closes, for an
   * animation to read.
   */
  readonly measure: typeof Modifier<CollapsibleMeasureSignature> = CollapsibleMeasure

  constructor(options: CollapsibleOptions = {}) {
    this.#options = options
    this.state = new ControllableState<boolean>({
      name: 'open',
      value: () => options.open?.(),
      defaultValue: () => options.defaultOpen?.(),
      onChange: () => options.onOpenChange?.(),
      fallback: false,
    })
    this.trigger = part(() => this.triggerSpec())
    this.content = part<HTMLElement, CollapsibleContentOptions>(named => this.contentSpec(named))
  }

  /** Whether it is open. */
  get isOpen(): boolean {
    return this.state.value
  }

  /** Whether the trigger can't open or close it. */
  get isDisabled(): boolean {
    return this.#options.disabled?.() ?? false
  }

  /** `open` or `closed`, for `data-state`. */
  get dataState(): CollapsibleDataState {
    return this.isOpen ? 'open' : 'closed'
  }

  /** The content's id, which the trigger's `aria-controls` names. */
  get contentId(): string {
    return idFor(this, 'content')
  }

  /** Opens it or closes it, as the trigger does. */
  toggle = (): void => {
    if (this.isDisabled) return
    this.state.set(open => !open)
  }

  /** Opens it (`true`) or closes it (`false`). */
  setOpen = (open: boolean): void => {
    this.state.set(open)
  }

  /** What the root renders: `data-state` and `data-disabled`, as Radix's. */
  get rootAttributes(): { 'data-state': CollapsibleDataState; 'data-disabled': '' | undefined } {
    return { 'data-state': this.dataState, 'data-disabled': this.isDisabled ? '' : undefined }
  }

  /**
   * What the trigger puts on its element, as a `part()` spec: Radix's `CollapsibleTrigger`.
   * `aria-expanded`, and `aria-controls` naming the content; `data-state` and `data-disabled`;
   * `disabled` while the collapsible is; and a click that opens or closes it. A `<button>`
   * without a `type` becomes `type="button"`, so it never submits a form.
   */
  triggerSpec(): PartSpec {
    const disabled = this.isDisabled
    return {
      attributes: {
        'aria-controls': this.contentId,
        'aria-expanded': String(this.isOpen),
        'data-state': this.dataState,
        'data-disabled': disabled,
        disabled,
        'data-test-jn-part': 'trigger',
      },
      on: { click: this.toggle },
      element: element => {
        if (isButton(element) && !element.hasAttribute('type')) element.type = 'button'
      },
    }
  }

  /**
   * What the content puts on its element, as a `part()` spec: Radix's `CollapsibleContent`.
   * Its `id`, `data-state` and `data-disabled`, and `hidden` once it is closed and done
   * animating out.
   */
  contentSpec({ shown }: CollapsibleContentOptions): PartSpec {
    return {
      attributes: {
        id: this.contentId,
        'data-state': this.dataState,
        'data-disabled': this.isDisabled,
        hidden: !shown,
        'data-test-jn-part': 'content',
      },
    }
  }
}

export interface CollapsibleMeasureSignature {
  Element: HTMLElement
  Args: { Named: { open: boolean } }
}

/** Sets a size variable, or removes it for no size (`NaN` for `auto`: the content is hidden). */
function setSize(element: HTMLElement, name: string, size: number): void {
  if (size > 0) element.style.setProperty(name, `${size}px`)
  else element.style.removeProperty(name)
}

/**
 * Measures a collapsible's content each time it opens or closes, as Radix's
 * `CollapsibleContent` does: its animation and transitions are turned off for the moment it is
 * measured, so the size is the whole content's, then turned back on so the change animates. The
 * size goes in `--radix-collapsible-content-height` and `-width`, set through the CSSOM (a
 * strict Content Security Policy blocks a `style` attribute, not this).
 *
 * Content that is open when it first renders doesn't animate in: its animation stays off until
 * it next opens or closes. Nor is it measured until then, as in Radix, whose first measurement
 * only reaches the variables on a later render: a part that sizes itself from them (an
 * accordion's content) stays `auto` until the first change, so a web font that loads late
 * doesn't leave it at the size it had before.
 *
 * Radix measures the element's box on screen (`getBoundingClientRect`); this reads its CSS size
 * instead, which is the same on an ordinary page and stays right inside a scaled ancestor (such
 * as a test runner's), and follows `box-sizing`, so an animation can set `height` to it.
 */
export class CollapsibleMeasure extends Modifier<CollapsibleMeasureSignature> {
  #original: { transitionDuration: string; animationName: string } | undefined
  #mountAnimationPrevented = false

  override modify(element: HTMLElement, _: [], { open }: { open: boolean }): void {
    const style = element.style
    if (!this.#original) {
      this.#original = {
        transitionDuration: style.transitionDuration,
        animationName: style.animationName,
      }
      this.#mountAnimationPrevented = open
      if (open) this.#pause(style)
      const frame = requestAnimationFrame(() => (this.#mountAnimationPrevented = false))
      registerDestructor(this, () => cancelAnimationFrame(frame))
      return
    }

    this.#pause(style)
    const styles = getComputedStyle(element)
    setSize(element, COLLAPSIBLE_CONTENT_HEIGHT, Number.parseFloat(styles.height))
    setSize(element, COLLAPSIBLE_CONTENT_WIDTH, Number.parseFloat(styles.width))
    if (!this.#mountAnimationPrevented) {
      style.transitionDuration = this.#original.transitionDuration
      style.animationName = this.#original.animationName
    }
  }

  /** Turns the element's animation and transitions off, so it can be measured as it will be. */
  #pause(style: CSSStyleDeclaration): void {
    style.transitionDuration = '0s'
    style.animationName = 'none'
  }
}

export interface CollapsibleTriggerSignature {
  Args: {
    /** The tag to render. Default `button`. */
    as?: TagName
    /** @internal Bound by the collapsible. */
    collapsible: CollapsibleState
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** The button that opens and closes the collapsible, yielded as `c.Trigger`. */
export const CollapsibleTrigger: TOC<CollapsibleTriggerSignature> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@collapsible.trigger}}>
    {{yield}}
  </As>
</template>

export interface CollapsibleContentSignature {
  Args: {
    /**
     * Keep the content rendered and shown while closed, for animating it yourself from its
     * `data-state`, as Radix's `forceMount`.
     */
    forceMount?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by the collapsible. */
    collapsible: CollapsibleState
    /**
     * @internal The part to put on the element instead of the collapsible's `content`, for a
     * component built on it (an accordion's item adds its `region` this way).
     */
    part?: PartModifier<HTMLElement, CollapsibleContentOptions>
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The content the collapsible shows and hides, yielded as `c.Content`. Its element is always
 * there, so the trigger's `aria-controls` always names it; while closed it is `hidden` and
 * empty. Closing, it stays shown until its exit animation (from `data-state="closed"`) ends.
 */
export class CollapsibleContent extends Component<CollapsibleContentSignature> {
  get part(): PartModifier<HTMLElement, CollapsibleContentOptions> {
    return this.args.part ?? this.args.collapsible.content
  }

  /** Whether the content is shown now: open, on its way out, or force-mounted. */
  isShown = (exiting: boolean): boolean =>
    this.args.collapsible.isOpen || exiting || Boolean(this.args.forceMount)

  <template>
    <Presence
      @present={{if @forceMount true @collapsible.isOpen}}
      @forceMount={{true}}
      as |presence|
    >
      <As
        @as={{@as}}
        @tag="div"
        ...attributes
        {{this.part shown=(this.isShown presence.isExiting)}}
        {{@collapsible.measure open=@collapsible.isOpen}}
        {{presence.ref}}
      >
        {{#if (this.isShown presence.isExiting)}}
          {{yield}}
        {{/if}}
      </As>
    </Presence>
  </template>
}

/** What `<Collapsible>` yields. */
export interface CollapsibleYield {
  /** The button that opens and closes it: `<c.Trigger>Details</c.Trigger>`. */
  Trigger: WithBoundArgs<typeof CollapsibleTrigger, 'collapsible'>
  /** What it shows and hides: `<c.Content>…</c.Content>`. */
  Content: WithBoundArgs<typeof CollapsibleContent, 'collapsible'>
  /** The trigger, as a modifier on your own element or component: `<Button {{c.trigger}}>`. */
  trigger: PartModifier
  /** Whether it is open. */
  isOpen: boolean
  /** Opens or closes it. */
  toggle: () => void
}

export interface CollapsibleSignature {
  Args: {
    /** The controlled open state. Pass `@onOpenChange` too, to hear the trigger. */
    open?: boolean
    /** Whether it starts open, when uncontrolled. Default `false`. */
    defaultOpen?: boolean
    /** Called with each new open state. */
    onOpenChange?: (open: boolean) => void
    /** Whether the trigger can't open or close it. */
    disabled?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `CollapsibleHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [CollapsibleYield] }
  Element: HTMLDivElement
}

/**
 * An interactive component which expands and collapses a panel: Radix's `Collapsible`,
 * headless. A trigger (`aria-expanded`, `aria-controls`) shows and hides the content, which
 * stays until its exit animation ends and is measured into `--radix-collapsible-content-height`
 * for an animation to use:
 *
 *   <Collapsible as |c|>
 *     <c.Trigger>Can I use this in my project?</c.Trigger>
 *     <c.Content>Yes. Free to use for personal and commercial projects.</c.Content>
 *   </Collapsible>
 *
 * It is uncontrolled unless given `@open` (with `@onOpenChange`), and `@defaultOpen` starts it
 * open. Make your own element or component the trigger with the yielded modifier:
 * `<Button {{c.trigger}}>`.
 */
export class Collapsible extends Component<CollapsibleSignature> {
  collapsible = new CollapsibleState({
    open: () => this.args.open,
    defaultOpen: () => this.args.defaultOpen,
    onOpenChange: () => this.args.onOpenChange,
    disabled: () => this.args.disabled,
  })

  <template>
    <As
      @as={{@as}}
      @tag="div"
      data-state={{this.collapsible.dataState}}
      data-disabled={{if this.collapsible.isDisabled ""}}
      data-test-jn="collapsible"
      data-test-jn-name={{@name}}
      ...attributes
    >
      {{yield
        (hash
          Trigger=(component CollapsibleTrigger collapsible=this.collapsible)
          Content=(component CollapsibleContent collapsible=this.collapsible)
          trigger=this.collapsible.trigger
          isOpen=this.collapsible.isOpen
          toggle=this.collapsible.toggle
        )
      }}
    </As>
  </template>
}
