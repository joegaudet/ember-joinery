import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { ChevronDown, ChevronUp } from 'lucide'
import {
  AccordionItemState,
  AccordionState,
  type AccordionOrientation,
  type AccordionType,
  type AccordionValue,
} from '@ember-joinery/primitives/accordion'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { CollapsibleContent } from '@ember-joinery/primitives/collapsible'
import type { Direction } from '@ember-joinery/primitives/direction'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import Icon, { type IconNode } from './icon.gts'

/** The classes an accordion's trigger renders: upstream's, and the `group/` marker its icons read. */
const ACCORDION_TRIGGER_CLASSES = 'jn-accordion-trigger group/accordion-trigger'

export interface AccordionTriggerSignature {
  Args: {
    /** The tag to render. Default `button`. */
    as?: TagName
    /** The heading's tag. Default `h3`; use the level that fits the page. */
    headingAs?: TagName
    /** The icon shown while the item is closed. Default lucide's `chevron-down`. */
    icon?: IconNode
    /** The icon shown while the item is open. Default lucide's `chevron-up`. */
    openIcon?: IconNode
    /** @internal Bound by the item. */
    item: AccordionItemState
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/**
 * An item's trigger, yielded as `item.Trigger`: upstream's `AccordionTrigger`, a button in the
 * item's heading (an `<h3>`), with a chevron that turns from down to up as it opens.
 */
const AccordionTrigger: TOC<AccordionTriggerSignature> = <template>
  <As @as={{@headingAs}} @tag="h3" class="jn-accordion-header" {{@item.header}}>
    <As
      @as={{@as}}
      @tag="button"
      type="button"
      class={{ACCORDION_TRIGGER_CLASSES}}
      data-slot="accordion-trigger"
      ...attributes
      {{@item.trigger}}
    >
      {{yield}}
      <Icon
        @icon={{if @icon @icon ChevronDown}}
        class="jn-accordion-trigger-icon jn-accordion-trigger-icon-closed"
        data-slot="accordion-trigger-icon"
      />
      <Icon
        @icon={{if @openIcon @openIcon ChevronUp}}
        class="jn-accordion-trigger-icon jn-accordion-trigger-icon-open"
        data-slot="accordion-trigger-icon"
      />
    </As>
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
  /** The inner element, which takes your `class` and attributes, as upstream's `className`. */
  Element: HTMLDivElement
}

/**
 * What an item shows and hides, yielded as `item.Content`: upstream's `AccordionContent`, a
 * `region` labelled by the item's trigger that animates open and shut from its measured height.
 * As upstream's `className`, your `class` and attributes go on the inner element, which holds
 * the padding.
 */
const AccordionContent: TOC<AccordionContentSignature> = <template>
  <CollapsibleContent
    @as={{@as}}
    @forceMount={{@forceMount}}
    @collapsible={{@item.collapsible}}
    @part={{@item.content}}
    class="jn-accordion-content"
    data-slot="accordion-content"
  >
    <div class="jn-accordion-content-inner" ...attributes>{{yield}}</div>
  </CollapsibleContent>
</template>

/** What `<a.Item>` yields. */
export interface AccordionItemYield {
  /** The item's heading and the button in it: `<item.Trigger>Is it accessible?</item.Trigger>`. */
  Trigger: WithBoundArgs<typeof AccordionTrigger, 'item'>
  /** What it shows and hides. */
  Content: WithBoundArgs<typeof AccordionContent, 'item'>
  /**
   * The trigger's behaviour, classes and `data-slot`, as a modifier on your own element or
   * component; put it in a heading of your own. It draws no chevrons.
   */
  trigger: PartModifier
  /** Whether it is open. */
  isOpen: boolean
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

/** One of an accordion's items, yielded as `a.Item`: upstream's `AccordionItem`. */
class AccordionItem extends Component<AccordionItemSignature> {
  item = new AccordionItemState(this.args.accordion, {
    value: () => this.args.value,
    disabled: () => this.args.disabled,
  })

  /** The headless trigger, with upstream's classes and `data-slot`. */
  trigger: PartModifier = part(() => {
    const spec = this.item.triggerSpec()
    return {
      ...spec,
      class: ACCORDION_TRIGGER_CLASSES,
      attributes: { ...spec.attributes, 'data-slot': 'accordion-trigger' },
    }
  })

  <template>
    <As
      @as={{@as}}
      @tag="div"
      class="jn-accordion-item"
      data-slot="accordion-item"
      ...attributes
      {{this.item.item}}
    >
      {{yield
        (hash
          Trigger=(component AccordionTrigger item=this.item)
          Content=(component AccordionContent item=this.item)
          trigger=this.trigger
          isOpen=this.item.isOpen
          isDisabled=this.item.isDisabled
          toggle=this.item.toggle
        )
      }}
    </As>
  </template>
}

/** What `<Accordion>` yields. */
export interface AccordionYield<T extends AccordionType> {
  /** An item: `<accordion.Item @value="shipping" as |item|>`. */
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
    /** The text direction for the arrow keys; by default the document's, from the nearest `dir`. */
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
 * shadcn's Accordion, on the primitives' `AccordionState`.
 *
 *   <Accordion @type="single" @collapsible={{true}} @defaultValue="item-1" as |accordion|>
 *     <accordion.Item @value="item-1" as |item|>
 *       <item.Trigger>Is it accessible?</item.Trigger>
 *       <item.Content>Yes. It adheres to the WAI-ARIA design pattern.</item.Content>
 *     </accordion.Item>
 *   </Accordion>
 *
 * `single` keeps one item open (and, unless `@collapsible`, always one once opened);
 * `multiple` opens any number. The arrow keys, Home and End move between the triggers.
 */
export default class Accordion<T extends AccordionType = 'single'> extends Component<
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
      class="jn-accordion"
      data-slot="accordion"
      data-orientation={{this.accordion.orientation}}
      data-test-jn="accordion"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.accordion.root}}
    >
      {{yield (hash Item=(component AccordionItem accordion=this.accordion) value=this.value)}}
    </As>
  </template>
}
