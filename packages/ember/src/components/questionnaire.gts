import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { Check } from 'lucide'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { nativeValue } from '@ember-joinery/primitives/native-value'
import { part, type PartModifier, type PartSpec } from '@ember-joinery/primitives/part'
import {
  QuestionnaireChoiceState,
  QuestionnaireInputState,
  QuestionnaireItemState,
  QuestionnaireState,
  type QuestionnaireItemDefinition,
  type QuestionnaireItemStatus,
  type QuestionnaireProgressState,
  type QuestionnaireShortcutMode,
} from '@ember-joinery/primitives/questionnaire'
import Icon from './icon.gts'
import { buttonClasses, type ButtonSize, type ButtonVariant } from './button.gts'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../-private/static-part.gts'
import { taggedPart, type TaggedPartSignature } from '../-private/tagged-part.gts'

export type {
  QuestionnaireChoiceDefinition,
  QuestionnaireItemDefinition,
  QuestionnaireItemStatus,
  QuestionnaireShortcutMode,
} from '@ember-joinery/primitives/questionnaire'

export interface QuestionnaireProgressSignature {
  Args: {
    /** Its name for screen readers. Default `Questionnaire progress`. */
    label?: string
    /** The words for where it is. Default `Question <current> of <total>`. */
    formatValue?: (current: number, total: number) => string
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by the questionnaire. */
    questionnaire: QuestionnaireState
  }
  Blocks: { default: [QuestionnaireProgressState] }
  Element: HTMLDivElement
}

/**
 * The questionnaire's progress, yielded as `q.Progress`: a named, live progressbar that reads
 * `Question 2 of 3`, in small muted figures. Give it a block to draw your own from where it is
 * (upstream's `render` prop):
 *
 *   <q.Progress as |p|>{{p.current}} / {{p.total}}</q.Progress>
 */
class QuestionnaireProgress extends Component<QuestionnaireProgressSignature> {
  get text(): string | undefined {
    return this.args.questionnaire.progressText(this.args.formatValue)
  }

  get state(): QuestionnaireProgressState {
    const q = this.args.questionnaire
    return { current: q.current, total: q.total, first: q.first, last: q.last }
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      class="jn-questionnaire-progress"
      data-slot="questionnaire-progress"
      aria-label={{if @label @label "Questionnaire progress"}}
      aria-valuetext={{this.text}}
      ...attributes
      {{@questionnaire.progress}}
    >{{#if (has-block)}}{{yield this.state}}{{else}}{{this.text}}{{/if}}</As>
  </template>
}

/** A part of an item with state from the item: its `part()` bound. */
interface ItemPartSignature<E extends Element = HTMLElement> {
  Args: {
    /** The tag to render instead of the part's own. */
    as?: TagName
    /** @internal Bound by the item. */
    part: PartModifier
  }
  Blocks: { default: [] }
  Element: E
}

/**
 * The question, yielded as `i.Title`: the fieldset's `<legend>`, in the theme's heading font.
 * To make another element the question (a card's title, a dialog's), use `{{i.title}}` on it.
 */
const QuestionnaireTitle: TOC<ItemPartSignature<HTMLLegendElement>> = <template>
  <As
    @as={{@as}}
    @tag="legend"
    class="jn-questionnaire-title jn-font-heading"
    data-slot="questionnaire-title"
    ...attributes
    {{@part}}
  >{{yield}}</As>
</template>

/** More about the question, yielded as `i.Description`, muted; the item's `aria-describedby` names it. */
const QuestionnaireDescription: TOC<ItemPartSignature<HTMLParagraphElement>> = <template>
  <As
    @as={{@as}}
    @tag="p"
    class="jn-questionnaire-description"
    data-slot="questionnaire-description"
    ...attributes
    {{@part}}
  >{{yield}}</As>
</template>

/** What holds the item's answers, yielded as `i.Choices`: a grid of rows. */
const QuestionnaireChoices: TOC<ItemPartSignature<HTMLDivElement>> = <template>
  <As
    @as={{@as}}
    @tag="div"
    class="jn-questionnaire-choices group/questionnaire-choices"
    data-slot="questionnaire-choices"
    ...attributes
    {{@part}}
  >{{yield}}</As>
</template>

const CHOICE_DESCRIPTION = {
  tag: 'span',
  class: 'jn-questionnaire-choice-description',
  slot: 'questionnaire-choice-description',
  part: 'choice-description',
} as const

/**
 * A choice's secondary line, muted, under its label: `<i.ChoiceDescription>`, inside an
 * `i.Choice`. It also nudges the choice's indicator and shortcut to the first line.
 */
export const QuestionnaireChoiceDescription: TOC<TaggedPartSignature> =
  taggedPart(CHOICE_DESCRIPTION)

export interface QuestionnaireChoiceSignature {
  Args: {
    /** The value it submits. */
    value: string
    /** Whether it is checked, when you control it. Pass `@onCheckedChange` too. */
    checked?: boolean
    /** Whether it starts checked, when uncontrolled. */
    defaultChecked?: boolean
    /** Whether it can't be chosen. */
    disabled?: boolean
    /**
     * Called as it is checked or unchecked, with the `change` event (upstream's `onChange`).
     * Calling `preventDefault()` on the event keeps the questionnaire from taking the change.
     */
    onCheckedChange?: (checked: boolean, event: Event) => void
    /** @internal Bound by the item. */
    item: QuestionnaireItemState
  }
  Blocks: { default: [] }
  Element: HTMLLabelElement
}

/**
 * A fixed answer, yielded as `i.Choice`: a bordered row that is a `<label>` around its radio
 * (a checkbox, in an item with `@multiple`), so the whole row picks it. The native control is
 * there, invisible, over the row; the row draws its indicator, its text (the block) and, with
 * shortcuts on, its key.
 *
 *   <i.Choice @value="tests">Run the relevant tests</i.Choice>
 */
class QuestionnaireChoice extends Component<QuestionnaireChoiceSignature> {
  choice = new QuestionnaireChoiceState(this.args.item, {
    value: () => this.args.value,
    checked: () => this.args.checked,
    defaultChecked: () => this.args.defaultChecked,
    disabled: () => this.args.disabled,
    onCheckedChange: () => this.args.onCheckedChange,
  })

  <template>
    <label
      class="jn-questionnaire-choice group/questionnaire-choice"
      data-slot="questionnaire-choice"
      ...attributes
      {{this.choice.choice}}
    >
      <input
        class="jn-questionnaire-choice-input"
        data-slot="questionnaire-choice-input"
        {{this.choice.input}}
        {{this.choice.sync}}
      />
      <span
        aria-hidden="true"
        class="jn-questionnaire-choice-indicator"
        data-slot="questionnaire-choice-indicator"
      >
        <span
          class="jn-questionnaire-choice-indicator-dot"
          data-slot="questionnaire-choice-indicator-dot"
        ></span>
        <Icon
          @icon={{Check}}
          class="jn-questionnaire-choice-indicator-check"
          data-slot="questionnaire-choice-indicator-check"
        />
      </span>
      <span
        class="jn-questionnaire-choice-label jn-questionnaire-choice-content"
        data-slot="questionnaire-choice-label"
        {{this.choice.label}}
      >{{yield}}</span>
      <span
        class="jn-questionnaire-choice-shortcut jn-questionnaire-shortcut"
        data-slot="questionnaire-choice-shortcut"
        {{this.choice.shortcutKey}}
      >{{this.choice.shortcut}}</span>
    </label>
  </template>
}

export interface QuestionnaireInputSignature {
  Args: {
    /** The value, when you control it. Pass `@onValueChange` too. */
    value?: string
    /** The value it starts with, when uncontrolled. */
    defaultValue?: string
    /** Called with the new value as someone types. */
    onValueChange?: (value: string) => void
    /** Whether it can't be typed in. */
    disabled?: boolean
    /** @internal Bound by the item. */
    item: QuestionnaireItemState
  }
  Element: HTMLInputElement
}

/**
 * A freeform answer, yielded as `i.Input`: a text field beside the fixed answers, for another
 * answer. Name it with `aria-label` or a visible label: a placeholder is not a label. A class
 * or attribute you give it goes on the `<input>`, inside its wrapper, as upstream's does.
 */
class QuestionnaireInput extends Component<QuestionnaireInputSignature> {
  answer = new QuestionnaireInputState(this.args.item, {
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    disabled: () => this.args.disabled,
    onValueChange: () => this.args.onValueChange,
  })

  <template>
    <div
      class="jn-questionnaire-input-wrapper group/questionnaire-input"
      data-slot="questionnaire-input-wrapper"
    >
      <input
        type="text"
        class="jn-questionnaire-input"
        data-slot="questionnaire-input"
        ...attributes
        {{this.answer.input}}
        {{nativeValue
          value=@value
          defaultValue=@defaultValue
          onValueChange=this.answer.onValueChange
        }}
      />
    </div>
  </template>
}

export interface QuestionnaireErrorSignature {
  Args: {
    /**
     * The message. Default `Choose an answer to continue.`, or for an optional item, `Choose
     * an answer or skip this question.` A block replaces it.
     */
    message?: string
    /** The tag to render. Default `p`. */
    as?: TagName
    /** @internal Bound by the item. */
    item: QuestionnaireItemState
  }
  Blocks: { default: [] }
  Element: HTMLParagraphElement
}

/**
 * The item's error, yielded as `i.Error`, in the destructive colour: hidden until the item is
 * invalid, then an alert its `aria-describedby` names. Pass your own validation's message as
 * `@message`; without one, it says what to do.
 */
const QuestionnaireError: TOC<QuestionnaireErrorSignature> = <template>
  <As
    @as={{@as}}
    @tag="p"
    class="jn-questionnaire-error"
    data-slot="questionnaire-error"
    ...attributes
    {{@item.error}}
  >
    {{~#if (has-block)~}}
      {{yield}}
    {{~else~}}
      {{if @message @message @item.defaultError}}
    {{~/if~}}
  </As>
</template>

/** A headless part's spec, with the styled part's classes and `data-slot` added. */
function styled(spec: PartSpec, classes: string, slot: string): PartSpec {
  return { ...spec, class: classes, attributes: { ...spec.attributes, 'data-slot': slot } }
}

/** What `q.Item` yields: its parts, each as a component, and the title's and description's modifiers. */
export interface QuestionnaireItemYield {
  /** The question: the fieldset's `<legend>`. */
  Title: WithBoundArgs<typeof QuestionnaireTitle, 'part'>
  /** More about the question. */
  Description: WithBoundArgs<typeof QuestionnaireDescription, 'part'>
  /** What holds the answers. */
  Choices: WithBoundArgs<typeof QuestionnaireChoices, 'part'>
  /** A fixed answer. */
  Choice: WithBoundArgs<typeof QuestionnaireChoice, 'item'>
  /** A fixed answer's secondary line. */
  ChoiceDescription: typeof QuestionnaireChoiceDescription
  /** A freeform answer. */
  Input: WithBoundArgs<typeof QuestionnaireInput, 'item'>
  /** The error, shown while the item is invalid. */
  Error: WithBoundArgs<typeof QuestionnaireError, 'item'>
  /**
   * Makes your own element the question, with the title's classes, as upstream's
   * `render={<CardTitle />}`: `<c.Title {{i.title}}>`. A card's title isn't the fieldset's
   * legend, so name the item with `aria-labelledby` and the title's `id`.
   */
  title: PartModifier
  /** Makes your own element a description the item names: `<c.Description {{i.description}}>`. */
  description: PartModifier
  /** Its name. */
  name: string
  /** `unanswered`, `answered` or `skipped`. */
  status: QuestionnaireItemStatus
  /** Whether it is the item that shows. */
  isActive: boolean
  /** Whether it shows as invalid. */
  isInvalid: boolean
}

export interface QuestionnaireItemSignature {
  Args: {
    /**
     * Its name: its answers' in the form (`FormData`), the item's in `@items`, `@item` and
     * `@defaultItem`, and the harness's (`data-test-jn-value`).
     */
    name: string
    /** Whether it must be answered. It can't be skipped. */
    required?: boolean
    /** Whether it takes several fixed answers: checkboxes, not radios. */
    multiple?: boolean
    /** Whether it doesn't apply: navigation passes it, and it isn't submitted. */
    disabled?: boolean
    /** Whether your own validation found it invalid: it shows its error. */
    invalid?: boolean
    /** Called with its status whenever that changes. */
    onStatusChange?: (status: QuestionnaireItemStatus) => void
    /** @internal Bound by the questionnaire. */
    questionnaire: QuestionnaireState
  }
  Blocks: { default: [QuestionnaireItemYield] }
  Element: HTMLFieldSetElement
}

/**
 * One question, yielded as `q.Item`: a `<fieldset>` laid out as a column, hidden and inert
 * unless it is the active item, and focused when the questionnaire moves to it.
 */
class QuestionnaireItem extends Component<QuestionnaireItemSignature> {
  item = new QuestionnaireItemState(this, this.args.questionnaire, {
    name: () => this.args.name,
    required: () => this.args.required,
    multiple: () => this.args.multiple,
    disabled: () => this.args.disabled,
    invalid: () => this.args.invalid,
    onStatusChange: () => this.args.onStatusChange,
  })

  /** The title, as a modifier for your own element: the styled classes and the headless part. */
  title: PartModifier = part(() =>
    styled(this.item.titleSpec(), 'jn-questionnaire-title jn-font-heading', 'questionnaire-title'),
  )

  /** A description, as a modifier for your own element. */
  description: PartModifier = part(() =>
    styled(
      this.item.descriptionSpec(),
      'jn-questionnaire-description',
      'questionnaire-description',
    ),
  )

  <template>
    <fieldset
      class="jn-questionnaire-item"
      data-slot="questionnaire-item"
      ...attributes
      {{this.item.item}}
    >
      {{yield
        (hash
          Title=(component QuestionnaireTitle part=this.item.title)
          Description=(component QuestionnaireDescription part=this.item.description)
          Choices=(component QuestionnaireChoices part=this.item.choices)
          Choice=(component QuestionnaireChoice item=this.item)
          ChoiceDescription=QuestionnaireChoiceDescription
          Input=(component QuestionnaireInput item=this.item)
          Error=(component QuestionnaireError item=this.item)
          title=this.title
          description=this.description
          name=@name
          status=this.item.status
          isActive=this.item.isActive
          isInvalid=this.item.invalid
        )
      }}
    </fieldset>
  </template>
}

const ACTIONS = {
  class: 'jn-questionnaire-actions',
  slot: 'questionnaire-actions',
  part: 'actions',
} as const

/**
 * Lays out the navigation buttons, as `q.Actions`: a grid with Previous at the start, Skip in
 * the middle and Next (or Submit) at the end. Styled only: it has no behaviour.
 */
export const QuestionnaireActions: TOC<StaticPartSignature> = staticPart(ACTIONS)

export interface QuestionnaireNavigationSignature {
  Args: {
    /** Its text. Default `Previous`, `Skip`, `Next` or `Submit`. A block replaces it. */
    label?: string
    /** Whether it is disabled (it never disables itself). */
    disabled?: boolean
    /** The Button variant it looks like. Default `outline` for Previous and Skip, `default` for Next and Submit. */
    variant?: ButtonVariant
    /** The Button size it is. Default `default`. */
    size?: ButtonSize
    /** @internal Bound by the questionnaire. */
    part: PartModifier<HTMLButtonElement, { disabled?: boolean }>
    /** @internal Bound by the questionnaire. */
    kind: 'previous' | 'skip' | 'next' | 'submit'
    /** @internal Bound by the questionnaire. */
    defaultLabel: string
    /** @internal Bound by the questionnaire. */
    defaultVariant: ButtonVariant
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/**
 * A navigation button, yielded as `q.Previous`, `q.Skip`, `q.Next` and `q.Submit`: a button
 * that looks like a Button (`@variant`, `@size`). Each shows only where it applies, and is
 * hidden and inert otherwise: Previous after the first item, Skip on an optional one, Next
 * before the last, Submit on the last.
 */
class QuestionnaireNavigation extends Component<QuestionnaireNavigationSignature> {
  get variant(): ButtonVariant {
    return this.args.variant ?? this.args.defaultVariant
  }

  get size(): ButtonSize {
    return this.args.size ?? 'default'
  }

  get classes(): string {
    return `${buttonClasses({ variant: this.variant, size: this.size })} jn-questionnaire-${this.args.kind}`
  }

  <template>
    <button
      type="button"
      class={{this.classes}}
      data-slot="questionnaire-{{@kind}}"
      data-size={{this.size}}
      data-variant={{this.variant}}
      ...attributes
      {{@part disabled=@disabled}}
    >
      {{~#if (has-block)}}{{yield}}{{else}}{{if @label @label @defaultLabel}}{{/if~}}
    </button>
  </template>
}

/** What `<Questionnaire>` yields. */
export interface QuestionnaireYield {
  /** The progress: `Question 2 of 3`. */
  Progress: WithBoundArgs<typeof QuestionnaireProgress, 'questionnaire'>
  /** A question. */
  Item: WithBoundArgs<typeof QuestionnaireItem, 'questionnaire'>
  /** Lays out the navigation buttons. */
  Actions: typeof QuestionnaireActions
  /** Goes back an item. */
  Previous: WithBoundArgs<
    typeof QuestionnaireNavigation,
    'part' | 'kind' | 'defaultLabel' | 'defaultVariant'
  >
  /** Skips an optional item. */
  Skip: WithBoundArgs<
    typeof QuestionnaireNavigation,
    'part' | 'kind' | 'defaultLabel' | 'defaultVariant'
  >
  /** Moves on, once the item is valid. */
  Next: WithBoundArgs<
    typeof QuestionnaireNavigation,
    'part' | 'kind' | 'defaultLabel' | 'defaultVariant'
  >
  /** Submits the form, on the last item. */
  Submit: WithBoundArgs<
    typeof QuestionnaireNavigation,
    'part' | 'kind' | 'defaultLabel' | 'defaultVariant'
  >
  /** Makes your own element the actions' grid. */
  actions: PartModifier
  /** The active item's name. */
  activeItem: string | null
  /** The active item's position, from 1. */
  current: number
  /** How many items it steps through. */
  total: number
  /** Whether the active item is the first. */
  first: boolean
  /** Whether the active item is the last. */
  last: boolean
}

export interface QuestionnaireSignature {
  Args: {
    /**
     * The items, in order: their names, whether each is required or disabled, and their fixed
     * answers' values (for the shortcuts). Pass it so progress, the actions and the shortcuts
     * are right from the first render; without it, the rendered items are stepped through in
     * document order.
     */
    items?: readonly QuestionnaireItemDefinition[]
    /** The active item's name, when you control it. Pass `@onItemChange` too. */
    item?: string
    /** The item it starts on. Default the first enabled item. */
    defaultItem?: string
    /** Called with the name of each item it moves to. */
    onItemChange?: (item: string) => void
    /** The keys that pick a fixed answer: `letters` (A–Z) or `numbers` (1–9). Default none. */
    shortcuts?: QuestionnaireShortcutMode
    /** `false` turns on the browser's own validation of filled answers. Default `true`. */
    noValidate?: boolean
    /** Called when the form submits with every item valid. Read the answers with `FormData`. */
    onSubmit?: (event: SubmitEvent) => void
    /** Called when the form resets, before the answers go back to their defaults. */
    onReset?: (event: Event) => void
    /** Its name, for `QuestionnaireHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [QuestionnaireYield] }
  Element: HTMLFormElement
}

/**
 * A multi-step questionnaire with single-choice, multiple-choice, freeform and skippable
 * questions: shadcn's Questionnaire, on the primitives' `QuestionnaireState`. It is a native
 * `<form>`, so answers are read with `FormData`:
 *
 *   <Questionnaire @items={{items}} @onSubmit={{this.submit}} as |q|>
 *     <q.Progress />
 *     <q.Item @name="detail" @required={{true}} as |i|>
 *       <i.Title>How much detail should it include?</i.Title>
 *       <i.Choices>
 *         <i.Choice @value="focused">Focused</i.Choice>
 *         <i.Choice @value="complete">Complete flow</i.Choice>
 *       </i.Choices>
 *       <i.Error />
 *     </q.Item>
 *     <q.Actions>
 *       <q.Previous /><q.Skip /><q.Next /><q.Submit />
 *     </q.Actions>
 *   </Questionnaire>
 *
 * It owns the ordered items, the active one, answer state, validation, progress and
 * navigation; the page, card or dialog around it owns closing, saving and branching.
 */
export default class Questionnaire extends Component<QuestionnaireSignature> {
  questionnaire = new QuestionnaireState(this, {
    items: () => this.args.items,
    item: () => this.args.item,
    defaultItem: () => this.args.defaultItem,
    onItemChange: () => this.args.onItemChange,
    shortcuts: () => this.args.shortcuts,
    noValidate: () => this.args.noValidate,
    onSubmit: () => this.args.onSubmit,
    onReset: () => this.args.onReset,
  })

  actions: PartModifier = staticPartModifier(ACTIONS)

  <template>
    <form
      class="jn-questionnaire"
      data-slot="questionnaire"
      data-test-jn="questionnaire"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.questionnaire.root}}
      {{this.questionnaire.focusEffect this.questionnaire.activeName}}
    >
      {{yield
        (hash
          Progress=(component QuestionnaireProgress questionnaire=this.questionnaire)
          Item=(component QuestionnaireItem questionnaire=this.questionnaire)
          Actions=QuestionnaireActions
          Previous=(component
            QuestionnaireNavigation
            part=this.questionnaire.previous
            kind="previous"
            defaultLabel="Previous"
            defaultVariant="outline"
          )
          Skip=(component
            QuestionnaireNavigation
            part=this.questionnaire.skip
            kind="skip"
            defaultLabel="Skip"
            defaultVariant="outline"
          )
          Next=(component
            QuestionnaireNavigation
            part=this.questionnaire.next
            kind="next"
            defaultLabel="Next"
            defaultVariant="default"
          )
          Submit=(component
            QuestionnaireNavigation
            part=this.questionnaire.submit
            kind="submit"
            defaultLabel="Submit"
            defaultVariant="default"
          )
          actions=this.actions
          activeItem=this.questionnaire.activeName
          current=this.questionnaire.current
          total=this.questionnaire.total
          first=this.questionnaire.first
          last=this.questionnaire.last
        )
      }}
    </form>
  </template>
}
