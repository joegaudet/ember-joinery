import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import { As, type TagName } from '../as.gts'
import type { Direction } from '../direction.gts'
import { Consume, Provide } from '../dom-context.gts'
import { Presence } from '../presence.gts'
import {
  ScrollAreaState,
  ScrollbarPart,
  ScrollbarState,
  type ScrollAreaOrientation,
  type ScrollAreaType,
} from './state.ts'

export interface ScrollAreaViewportSignature {
  Args: {
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * The part of a `<ScrollArea>` that scrolls, with the content inside. Its own scrollbars are
 * hidden; it scrolls with the wheel, touch and the keyboard as any scroller does. It takes
 * focus (`tabindex="0"`), so a keyboard can scroll it when nothing inside can take focus;
 * Chrome makes scrollers focusable the same way. Give it a `tabindex` of your own to change
 * that.
 */
export const ScrollAreaViewport: TOC<ScrollAreaViewportSignature> = <template>
  <Consume @key={{ScrollAreaState}} as |context|>
    <As
      @as={{@as}}
      @tag="div"
      tabindex="0"
      data-slot="scroll-area-viewport"
      data-radix-scroll-area-viewport=""
      data-test-jn-part="viewport"
      ...attributes
      {{context.data.viewportPart}}
    >
      <div {{context.data.contentPart}}>{{yield}}</div>
    </As>
  </Consume>
</template>

export interface ScrollAreaThumbSignature {
  Args: {
    /** Keep it rendered when the content fits, for hiding it in CSS of your own. */
    forceMount?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The thumb of a scrollbar: it shows where the viewport is, and drags to scroll. */
export const ScrollAreaThumb: TOC<ScrollAreaThumbSignature> = <template>
  <Consume @key={{ScrollAreaState}} as |area|>
    <Consume @key={{ScrollbarState}} as |bar|>
      <Presence @present={{bar.data.hasThumb}} @forceMount={{@forceMount}} as |presence|>
        <As
          @as={{@as}}
          @tag="div"
          data-state={{if bar.data.hasThumb "visible" "hidden"}}
          data-slot="scroll-area-thumb"
          data-test-jn-part="thumb"
          data-test-jn-value={{bar.data.orientation}}
          ...attributes
          {{presence.ref}}
          {{ScrollbarPart area.data bar.data "thumb"}}
        >{{yield}}</As>
      </Presence>
    </Consume>
  </Consume>
</template>

export interface ScrollAreaScrollbarSignature {
  Args: {
    /** `vertical` (the default) or `horizontal`. */
    orientation?: ScrollAreaOrientation
    /** Keep it rendered while it is hidden, for hiding it in CSS of your own. */
    forceMount?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: {
    /** The thumb goes inside: `<bar.Thumb />`, or `<ScrollAreaThumb />`. */
    default: [bar: { Thumb: typeof ScrollAreaThumb; isVisible: boolean }]
  }
  Element: HTMLElement
}

interface ScrollbarImplSignature extends ScrollAreaScrollbarSignature {
  Args: ScrollAreaScrollbarSignature['Args'] & { area: ScrollAreaState }
}

class ScrollbarImpl extends Component<ScrollbarImplSignature> {
  readonly bar: ScrollbarState

  constructor(owner: Owner, args: ScrollbarImplSignature['Args']) {
    super(owner, args)
    this.bar = args.area.scrollbar(args.orientation ?? 'vertical')
    registerDestructor(this, args.area.mountScrollbar(this.bar.orientation))
  }

  get isPresent(): boolean {
    return Boolean(this.args.forceMount) || this.bar.isVisible
  }

  <template>
    <Presence @present={{this.isPresent}} as |presence|>
      <As
        @as={{@as}}
        @tag="div"
        data-orientation={{this.bar.orientation}}
        data-state={{if this.bar.isVisible "visible" "hidden"}}
        data-slot="scroll-area-scrollbar"
        data-test-jn-part="scrollbar"
        data-test-jn-value={{this.bar.orientation}}
        ...attributes
        {{presence.ref}}
        {{ScrollbarPart @area this.bar "scrollbar"}}
      >
        <Provide @data={{this.bar}} @key={{ScrollbarState}} @element={{false}}>
          {{yield (hash Thumb=ScrollAreaThumb isVisible=this.bar.isVisible)}}
        </Provide>
      </As>
    </Presence>
  </template>
}

/**
 * A scrollbar of a `<ScrollArea>`, vertical or horizontal, with its thumb inside. It shows
 * for the area's `@type`, and only when the content overflows that way.
 */
export const ScrollAreaScrollbar: TOC<ScrollAreaScrollbarSignature> = <template>
  <Consume @key={{ScrollAreaState}} as |context|>
    <ScrollbarImpl
      @area={{context.data}}
      @orientation={{@orientation}}
      @forceMount={{@forceMount}}
      @as={{@as}}
      ...attributes
      as |bar|
    >{{yield bar}}</ScrollbarImpl>
  </Consume>
</template>

export interface ScrollAreaCornerSignature {
  Args: {
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The corner where the two scrollbars meet: there only while both are, and not for `scroll`. */
export const ScrollAreaCorner: TOC<ScrollAreaCornerSignature> = <template>
  <Consume @key={{ScrollAreaState}} as |context|>
    {{#if context.data.hasCorner}}
      <As
        @as={{@as}}
        @tag="div"
        data-slot="scroll-area-corner"
        data-test-jn-part="corner"
        ...attributes
        {{context.data.cornerPart}}
      >{{yield}}</As>
    {{/if}}
  </Consume>
</template>

/** What `<ScrollArea>` yields. */
export interface ScrollAreaYield {
  /** The viewport, around the content: `<s.Viewport>…</s.Viewport>`. */
  Viewport: typeof ScrollAreaViewport
  /** A scrollbar: `<s.Scrollbar @orientation="horizontal" as |bar|><bar.Thumb /></s.Scrollbar>`. */
  Scrollbar: typeof ScrollAreaScrollbar
  /** A thumb, for inside a scrollbar. */
  Thumb: typeof ScrollAreaThumb
  /** The corner: `<s.Corner />`. */
  Corner: typeof ScrollAreaCorner
  /** The area's engine, for a part of your own. */
  state: ScrollAreaState
}

export interface ScrollAreaSignature {
  Args: {
    /**
     * When the scrollbars show: while the pointer is over the area (`hover`, the default), while
     * it scrolls (`scroll`), whenever the content overflows (`auto`), or `always`.
     */
    type?: ScrollAreaType
    /** How long a scrollbar stays once the pointer leaves or the scrolling stops, in ms. Default 600. */
    scrollHideDelay?: number
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `ScrollAreaHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [area: ScrollAreaYield] }
  Element: HTMLElement
}

/**
 * A scrollable area with scrollbars of its own drawing, as Radix's `ScrollArea`: the content
 * scrolls natively (wheel, touch, keyboard), and the scrollbars can be styled and show only
 * when wanted (`@type`).
 *
 *   <ScrollArea @type="auto" class="h-72" as |s|>
 *     <s.Viewport>…</s.Viewport>
 *     <s.Scrollbar as |bar|><bar.Thumb /></s.Scrollbar>
 *     <s.Corner />
 *   </ScrollArea>
 *
 * The parts are components of their own too (`ScrollAreaViewport`, `ScrollAreaScrollbar`,
 * `ScrollAreaThumb`, `ScrollAreaCorner`), which find their area through the DOM, so a
 * scrollbar can go anywhere inside it, even inside the viewport.
 */
export class ScrollArea extends Component<ScrollAreaSignature> {
  state = new ScrollAreaState(this, {
    type: () => this.args.type,
    scrollHideDelay: () => this.args.scrollHideDelay,
    dir: () => this.args.dir,
  })

  <template>
    <As
      @as={{@as}}
      @tag="div"
      dir={{@dir}}
      data-slot="scroll-area"
      data-test-jn="scroll-area"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.state.rootPart}}
    >
      <Provide @data={{this.state}} @key={{ScrollAreaState}} @element={{false}}>
        {{yield
          (hash
            Viewport=ScrollAreaViewport
            Scrollbar=ScrollAreaScrollbar
            Thumb=ScrollAreaThumb
            Corner=ScrollAreaCorner
            state=this.state
          )
        }}
      </Provide>
    </As>
  </template>
}
