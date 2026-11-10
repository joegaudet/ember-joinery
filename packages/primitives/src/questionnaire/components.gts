import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from '../as.gts'
import { nativeValue } from '../native-value.ts'
import type { PartModifier } from '../part.ts'
import {
  QuestionnaireChoiceState,
  QuestionnaireInputState,
  QuestionnaireItemState,
  QuestionnaireState,
} from './state.ts'
import type {
  QuestionnaireItemDefinition,
  QuestionnaireItemStatus,
  QuestionnaireShortcutMode,
} from './utils.ts'

/** What a progress block gets: where the questionnaire is. */
export interface QuestionnaireProgressState {
  /** The active item's position, from 1. */
  current: number
  /** How many items it steps through. */
  total: number
  /** Whether the active item is the first. */
  first: boolean
  /** Whether the active item is the last. */
  last: boolean
}

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
 * `Question 2 of 3`. Give it a block to draw your own, from where it is:
 *
 *   <q.Progress as |p|>{{p.current}} / {{p.total}}</q.Progress>
 */
export class QuestionnaireProgress extends Component<QuestionnaireProgressSignature> {
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
      aria-label={{if @label @label "Questionnaire progress"}}
      aria-valuetext={{this.text}}
      ...attributes
      {{@questionnaire.progress}}
    >{{#if (has-block)}}{{yield this.state}}{{else}}{{this.text}}{{/if}}</As>
  </template>
}

export interface QuestionnairePartSignature<E extends Element = HTMLElement> {
  Args: {
    /** The tag to render instead of the part's own. */
    as?: TagName
    /** @internal Bound by the item. */
    part: PartModifier
  }
  Blocks: { default: [] }
  Element: E
}

/** The item's question, yielded as `i.Title`: its fieldset's `<legend>`. */
export const QuestionnaireTitle: TOC<QuestionnairePartSignature<HTMLLegendElement>> = <template>
  <As @as={{@as}} @tag="legend" ...attributes {{@part}}>{{yield}}</As>
</template>

/** More about the question, yielded as `i.Description`: the item's `aria-describedby` names it. */
export const QuestionnaireDescription: TOC<QuestionnairePartSignature<HTMLParagraphElement>> =
  <template>
    <As @as={{@as}} @tag="p" ...attributes {{@part}}>{{yield}}</As>
  </template>

/** What holds the item's answers, yielded as `i.Choices`. */
export const QuestionnaireChoices: TOC<QuestionnairePartSignature<HTMLDivElement>> = <template>
  <As @as={{@as}} @tag="div" ...attributes {{@part}}>{{yield}}</As>
</template>

export interface QuestionnaireErrorSignature {
  Args: {
    /** The message. Default: `Choose an answer to continue.`, or for an optional item, `Choose an answer or skip this question.` */
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
 * The item's error, yielded as `i.Error`: hidden until the item is invalid, then an alert the
 * item's `aria-describedby` names. Its text is the block, else `@message`, else the default.
 */
export const QuestionnaireError: TOC<QuestionnaireErrorSignature> = <template>
  <As @as={{@as}} @tag="p" ...attributes {{@item.error}}>
    {{~#if (has-block)~}}
      {{yield}}
    {{~else~}}
      {{if @message @message @item.defaultError}}
    {{~/if~}}
  </As>
</template>

export interface QuestionnaireChoiceInputSignature {
  Args: { choice: QuestionnaireChoiceState }
  Element: HTMLInputElement
}

/** The choice's radio or checkbox, yielded as `c.Input`. */
export const QuestionnaireChoiceInput: TOC<QuestionnaireChoiceInputSignature> = <template>
  <input ...attributes {{@choice.input}} {{@choice.sync}} />
</template>

export interface QuestionnaireChoiceTextSignature {
  Args: {
    /** The tag to render. Default `span`. */
    as?: TagName
    choice: QuestionnaireChoiceState
  }
  Blocks: { default: [] }
  Element: HTMLSpanElement
}

/** The choice's text, yielded as `c.Label`. */
export const QuestionnaireChoiceLabel: TOC<QuestionnaireChoiceTextSignature> = <template>
  <As @as={{@as}} @tag="span" ...attributes {{@choice.label}}>{{yield}}</As>
</template>

/** The choice's shortcut key (hidden without one), yielded as `c.Shortcut`. */
export const QuestionnaireChoiceShortcut: TOC<QuestionnaireChoiceTextSignature> = <template>
  <As @as={{@as}} @tag="span" ...attributes {{@choice.shortcutKey}}>
    {{~#if (has-block)}}{{yield}}{{else}}{{@choice.shortcut}}{{/if~}}
  </As>
</template>

/** What `i.Choice` yields: its parts, and its state. */
export interface QuestionnaireChoiceYield {
  /** The radio (or checkbox): `<c.Input />`. */
  Input: WithBoundArgs<typeof QuestionnaireChoiceInput, 'choice'>
  /** The choice's text. */
  Label: WithBoundArgs<typeof QuestionnaireChoiceLabel, 'choice'>
  /** Its shortcut key. */
  Shortcut: WithBoundArgs<typeof QuestionnaireChoiceShortcut, 'choice'>
  /** Whether it is checked. */
  isChecked: boolean
  /** `radio`, or `checkbox` in an item that takes several answers. */
  type: 'checkbox' | 'radio'
  /** Its shortcut key, or `null`. */
  shortcut: string | null
  /** The choice's state, for building a part of your own. */
  choice: QuestionnaireChoiceState
}

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
    /** Called as it is checked or unchecked, with the `change` event. */
    onCheckedChange?: (checked: boolean, event: Event) => void
    /** @internal Bound by the item. */
    item: QuestionnaireItemState
  }
  Blocks: { default: [QuestionnaireChoiceYield] }
  Element: HTMLLabelElement
}

/**
 * A fixed answer, yielded as `i.Choice`: a `<label>` around its radio (a checkbox, in an item
 * with `@multiple`), so the whole row picks it. Put its parts in it:
 *
 *   <i.Choice @value="tests" as |c|>
 *     <c.Input />
 *     <c.Label>Run the relevant tests</c.Label>
 *     <c.Shortcut />
 *   </i.Choice>
 */
export class QuestionnaireChoice extends Component<QuestionnaireChoiceSignature> {
  choice = new QuestionnaireChoiceState(this.args.item, {
    value: () => this.args.value,
    checked: () => this.args.checked,
    defaultChecked: () => this.args.defaultChecked,
    disabled: () => this.args.disabled,
    onCheckedChange: () => this.args.onCheckedChange,
  })

  <template>
    <label ...attributes {{this.choice.choice}}>
      {{yield
        (hash
          Input=(component QuestionnaireChoiceInput choice=this.choice)
          Label=(component QuestionnaireChoiceLabel choice=this.choice)
          Shortcut=(component QuestionnaireChoiceShortcut choice=this.choice)
          isChecked=this.choice.isChecked
          type=this.choice.type
          shortcut=this.choice.shortcut
          choice=this.choice
        )
      }}
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
 * A freeform answer, yielded as `i.Input`: a text input beside the fixed answers. Name it, with
 * `aria-label` or a visible label: a placeholder is not a label. Give it `type` for another
 * kind of text (`email`, `number`…).
 */
export class QuestionnaireInput extends Component<QuestionnaireInputSignature> {
  answer = new QuestionnaireInputState(this.args.item, {
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    disabled: () => this.args.disabled,
    onValueChange: () => this.args.onValueChange,
  })

  <template>
    <input
      type="text"
      ...attributes
      {{this.answer.input}}
      {{nativeValue
        value=@value
        defaultValue=@defaultValue
        onValueChange=this.answer.onValueChange
      }}
    />
  </template>
}

/** What `q.Item` yields: its parts, each as a component and, where useful, a modifier. */
export interface QuestionnaireItemYield {
  /** The question: the fieldset's `<legend>`. */
  Title: WithBoundArgs<typeof QuestionnaireTitle, 'part'>
  /** More about the question. */
  Description: WithBoundArgs<typeof QuestionnaireDescription, 'part'>
  /** What holds the answers. */
  Choices: WithBoundArgs<typeof QuestionnaireChoices, 'part'>
  /** A fixed answer. */
  Choice: WithBoundArgs<typeof QuestionnaireChoice, 'item'>
  /** A freeform answer. */
  Input: WithBoundArgs<typeof QuestionnaireInput, 'item'>
  /** The error, shown while the item is invalid. */
  Error: WithBoundArgs<typeof QuestionnaireError, 'item'>
  /** Makes your own element (a card's or a dialog's title) the question. */
  title: PartModifier
  /** Makes your own element a description the item names. */
  description: PartModifier
  /** Its name. */
  name: string
  /** `unanswered`, `answered` or `skipped`. */
  status: QuestionnaireItemStatus
  /** Whether it is the item that shows. */
  isActive: boolean
  /** Whether it shows as invalid. */
  isInvalid: boolean
  /** The item's state, for building a part of your own. */
  item: QuestionnaireItemState
}

export interface QuestionnaireItemSignature {
  Args: {
    /** Its name: the form field's (`FormData`), and the item's in `@items` and `@item`. */
    name: string
    /** Whether it must be answered. It can't be skipped. */
    required?: boolean
    /** Whether it takes several fixed answers: checkboxes, not radios. */
    multiple?: boolean
    /** Whether it doesn't apply: navigation passes it and it isn't submitted. */
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
 * One question, yielded as `q.Item`: a `<fieldset>`, hidden and inert unless it is the active
 * item. Its `@name` names its answers in the form, and the item in `@items`.
 */
export class QuestionnaireItem extends Component<QuestionnaireItemSignature> {
  item = new QuestionnaireItemState(this, this.args.questionnaire, {
    name: () => this.args.name,
    required: () => this.args.required,
    multiple: () => this.args.multiple,
    disabled: () => this.args.disabled,
    invalid: () => this.args.invalid,
    onStatusChange: () => this.args.onStatusChange,
  })

  <template>
    <fieldset ...attributes {{this.item.item}}>
      {{yield
        (hash
          Title=(component QuestionnaireTitle part=this.item.title)
          Description=(component QuestionnaireDescription part=this.item.description)
          Choices=(component QuestionnaireChoices part=this.item.choices)
          Choice=(component QuestionnaireChoice item=this.item)
          Input=(component QuestionnaireInput item=this.item)
          Error=(component QuestionnaireError item=this.item)
          title=this.item.title
          description=this.item.description
          name=@name
          status=this.item.status
          isActive=this.item.isActive
          isInvalid=this.item.invalid
          item=this.item
        )
      }}
    </fieldset>
  </template>
}

export interface QuestionnaireNavigationSignature {
  Args: {
    /** Its text. Default `Previous`, `Skip`, `Next` or `Submit`. A block replaces it. */
    label?: string
    /** Whether it is disabled (it never disables itself). */
    disabled?: boolean
    /** @internal Bound by the questionnaire. */
    part: PartModifier<HTMLButtonElement, { disabled?: boolean }>
    /** @internal Bound by the questionnaire. */
    defaultLabel: string
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/**
 * A navigation button, yielded as `q.Previous`, `q.Skip`, `q.Next` and `q.Submit`. Each shows
 * only where it applies (and is hidden and inert otherwise): Previous after the first item,
 * Skip on an optional one, Next before the last, Submit on the last.
 */
export const QuestionnaireNavigation: TOC<QuestionnaireNavigationSignature> = <template>
  <button type="button" ...attributes {{@part disabled=@disabled}}>
    {{~#if (has-block)}}{{yield}}{{else}}{{if @label @label @defaultLabel}}{{/if~}}
  </button>
</template>

/** What `<Questionnaire>` yields. */
export interface QuestionnaireYield {
  /** The progress: `Question 2 of 3`. */
  Progress: WithBoundArgs<typeof QuestionnaireProgress, 'questionnaire'>
  /** A question. */
  Item: WithBoundArgs<typeof QuestionnaireItem, 'questionnaire'>
  /** Goes back an item. */
  Previous: WithBoundArgs<typeof QuestionnaireNavigation, 'part' | 'defaultLabel'>
  /** Skips an optional item. */
  Skip: WithBoundArgs<typeof QuestionnaireNavigation, 'part' | 'defaultLabel'>
  /** Moves on, once the item is valid. */
  Next: WithBoundArgs<typeof QuestionnaireNavigation, 'part' | 'defaultLabel'>
  /** Submits the form, on the last item. */
  Submit: WithBoundArgs<typeof QuestionnaireNavigation, 'part' | 'defaultLabel'>
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
  /** The questionnaire's state, for building a part of your own. */
  questionnaire: QuestionnaireState
}

export interface QuestionnaireSignature {
  Args: {
    /**
     * The items, in order: their names, whether each is required or disabled, and their fixed
     * answers' values (for the shortcuts). Without it, the rendered items are stepped through
     * in document order once they have rendered.
     */
    items?: readonly QuestionnaireItemDefinition[]
    /** The active item's name, when you control it. Pass `@onItemChange` too. */
    item?: string
    /** The item it starts on. Default the first enabled item. */
    defaultItem?: string
    /** Called with the name of each item it moves to. */
    onItemChange?: (item: string) => void
    /** The keys that pick a fixed answer: `letters` or `numbers`. Default none. */
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
 * questions: `@shadcn/react`'s headless Questionnaire. It is a native `<form>`, so answers are
 * read with `FormData`; it owns the ordered items, the active one, answer state, validation,
 * progress and navigation, and the page around it owns closing, saving and branching.
 *
 *   <Questionnaire @items={{items}} @onSubmit={{this.submit}} as |q|>
 *     <q.Progress />
 *     <q.Item @name="detail" @required={{true}} as |i|>
 *       <i.Title>How much detail?</i.Title>
 *       <i.Choices>
 *         <i.Choice @value="focused" as |c|><c.Input /><c.Label>Focused</c.Label></i.Choice>
 *       </i.Choices>
 *       <i.Error />
 *     </q.Item>
 *     <q.Previous /><q.Skip /><q.Next /><q.Submit />
 *   </Questionnaire>
 */
export class Questionnaire extends Component<QuestionnaireSignature> {
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

  <template>
    <form
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
          Previous=(component
            QuestionnaireNavigation part=this.questionnaire.previous defaultLabel="Previous"
          )
          Skip=(component QuestionnaireNavigation part=this.questionnaire.skip defaultLabel="Skip")
          Next=(component QuestionnaireNavigation part=this.questionnaire.next defaultLabel="Next")
          Submit=(component
            QuestionnaireNavigation part=this.questionnaire.submit defaultLabel="Submit"
          )
          activeItem=this.questionnaire.activeName
          current=this.questionnaire.current
          total=this.questionnaire.total
          first=this.questionnaire.first
          last=this.questionnaire.last
          questionnaire=this.questionnaire
        )
      }}
    </form>
  </template>
}
