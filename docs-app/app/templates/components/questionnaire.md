# Questionnaire

A multi-step questionnaire with single-choice, multiple-choice, freeform, and skippable questions.

<Example @name="questionnaire-demo" @title="Questionnaire" @align="end" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Questionnaire } from '@ember-joinery/ember'
```

Its behaviour is the primitives' headless [Questionnaire](/primitives/questionnaire.md), as
upstream's comes from `@shadcn/react`.

## Usage

```ts
const items = [
  {
    name: 'direction',
    required: true,
    prompt: 'What should we prototype next?',
    description: 'Choose a direction or write your own.',
    choices: [
      {
        value: 'delegation',
        label: 'Delegation',
        description: 'Show how work moves to a specialist.',
      },
      {
        value: 'questions',
        label: 'Question prompts',
        description: 'Show choices while the interface waits.',
      },
      { value: 'both', label: 'Both together' },
    ],
    input: { label: 'Another answer', placeholder: 'Type another answer…' },
  },
  {
    name: 'detail',
    required: false,
    prompt: 'How much detail should it include?',
    description: 'Skip this if you are not sure yet.',
    choices: [
      { value: 'focused', label: 'Focused' },
      { value: 'complete', label: 'Complete flow' },
    ],
  },
]
```

Define the collection once: pass it to `Questionnaire` as `@items` for progress, actions and
shortcuts that are right from the first render, then map it into the parts.

```gts
<Questionnaire @items={{items}} @onSubmit={{handleSubmit}} as |q|>
  <q.Progress />
  {{#each items as |question|}}
    <q.Item @name={{question.name}} @required={{question.required}} as |i|>
      <i.Title>{{question.prompt}}</i.Title>
      <i.Description>{{question.description}}</i.Description>
      <i.Choices>
        {{#each question.choices as |choice|}}
          <i.Choice @value={{choice.value}}>
            <span class="font-medium">{{choice.label}}</span>
            {{#if choice.description}}
              <span class="text-muted-foreground">{{choice.description}}</span>
            {{/if}}
          </i.Choice>
        {{/each}}
        {{#if question.input}}
          <i.Input aria-label={{question.input.label}} placeholder={{question.input.placeholder}} />
        {{/if}}
      </i.Choices>
      <i.Error />
    </q.Item>
  {{/each}}
  <q.Actions>
    <q.Previous />
    <q.Skip />
    <q.Next />
    <q.Submit />
  </q.Actions>
</Questionnaire>
```

```ts
function handleSubmit(event: SubmitEvent) {
  event.preventDefault()
  const answers = new FormData(event.currentTarget as HTMLFormElement)
  // answers.get('direction'), answers.getAll(…) for multiple items.
}
```

## Composition

```text
Questionnaire
├── q.Progress
├── q.Item
│   ├── i.Title
│   ├── i.Description
│   ├── i.Choices
│   │   ├── i.Choice
│   │   └── i.Input
│   └── i.Error
└── q.Actions
    ├── q.Previous
    ├── q.Skip
    ├── q.Next
    └── q.Submit
```

Questionnaire owns the ordered items, active item, answer state, validation, progress, and
navigation. The containing page, card, dialog, or drawer owns close and cancellation behavior,
persistence, transport, and branching.

## Server Rendering

Pass `@items` so the active item, progress, actions and answer shortcuts are known before the
items render. Without it, the rendered items are stepped through in document order once they
have rendered.

## Multiple Selection

Use `@multiple` for an item that accepts more than one fixed answer.

<Example @name="questionnaire-multiple" @title="Multiple Selection" @align="end" />

## Freeform Answer

Compose `i.Input` with fixed choices when the user can provide another answer.

<Example @name="questionnaire-freeform" @title="Freeform Answer" @align="end" />

## Explicit Skip

Add `q.Skip` when an optional item may be intentionally left unanswered.

<Example @name="questionnaire-skip" @title="Explicit Skip" @align="end" />

## Shortcuts

Assign a letter or number key to each answer with `@shortcuts`.

<Example @name="questionnaire-shortcuts" @title="Shortcuts" @align="end" />

## Custom Validation

Combine controlled navigation with an external schema, such as Zod, to return to an invalid item
and present its error. Upstream's example checks the answers with a Zod schema; the guide's
writes the same rules out, as the guide has no Zod.

<Example @name="questionnaire-validation" @title="Custom Validation" @align="end" />

## Controlled

Control the active item from host state, such as returning to an invalid step.

<Example @name="questionnaire-controlled" @title="Controlled" @align="end" />

## Resume

Restore a saved active item and default answers, then reset changes back to that saved state.

<Example @name="questionnaire-resume" @title="Resume" @align="end" />

## Conditional Items

Disable items that do not apply to the user's earlier answers.

<Example @name="questionnaire-conditional" @title="Conditional Items" @align="end" />

## Navigation State

Read item status to opt into disabled navigation and custom action styling.

<Example @name="questionnaire-navigation-state" @title="Navigation State" @align="end" />

## Custom Progress

Give `q.Progress` a block to build a custom progress indicator from where the questionnaire is
(upstream's `render` prop).

<Example @name="questionnaire-progress" @title="Custom Progress" @align="end" />

## Animated Items

Animate the active item while keeping progress and navigation stationary.

<Example @name="questionnaire-animated" @title="Animated Items" @align="end" />

## Card

Compose Questionnaire with Card slots while keeping the question title and description
semantic: `{{i.title}}` on the card's title (upstream's `render={<CardTitle />}`), and
`aria-labelledby` on the item.

<Example @name="questionnaire-card" @title="Card" @align="end" />

## Dialog

Compose Questionnaire inside a Dialog while keeping cancellation and dismissal host-owned. The
dialog's title and description take the questionnaire's parts (`{{i.title}}`, `{{i.description}}`)
in the active item only: upstream renders them in every item, which leaves two elements with the
dialog's title id, and the dialog named by the first question whichever shows.

<Example @name="questionnaire-dialog" @title="Dialog" @align="end" />

## Accessibility

`q.Item` renders a `fieldset`, and `i.Title` renders its `legend`. Descriptions and active
errors are associated with the current item, and invalid items and answer controls expose
`aria-invalid`.

Fixed choices preserve native radio and checkbox behavior. Progress is exposed as a named
progressbar, navigation uses real buttons, and inactive items and actions are hidden and inert.
Successful navigation focuses the newly active item; failed validation focuses an available
answer control.

Always give `i.Input` an accessible name with a visible label, `aria-label`, or
`aria-labelledby`. A placeholder is not a label. A title of your own (`{{i.title}}` on a card's
title) isn't the fieldset's legend, so name the item with `aria-labelledby`.

## Keyboard interactions

| Key                           | What it does                                                                        |
| ----------------------------- | ----------------------------------------------------------------------------------- |
| `Tab`                         | Moves through the answers and the buttons that show                                 |
| `ArrowDown`, `ArrowUp`        | Moves to the next or previous answer, wrapping; a radio picks itself                |
| `Space`                       | Checks the focused radio, or toggles the focused checkbox                           |
| `Enter`                       | On a checked or filled answer, confirms the item: moves on, or on the last, submits |
| `Meta+Enter`, `Control+Enter` | Confirms the item from anywhere in it                                               |
| `ArrowLeft`                   | Goes back an item (from anywhere but a text field or a radio)                       |
| `ArrowRight`                  | Moves on, once the item is answered or skipped                                      |
| `A`–`Z`, `1`–`9`              | With `@shortcuts`, picks the answer with that key                                   |

Between two radios, the browser's own arrow keys move and pick. In a freeform answer with text,
the arrows stay the caret's. Right to left, `ArrowRight` goes back and `ArrowLeft` moves on.
Each item and answer lists the keys it answers to in `aria-keyshortcuts`.

## API Reference

The behaviour comes from the primitives' [Questionnaire](/primitives/questionnaire.md); the
styled parts take the same arguments, and the navigation buttons also take Button's `@size` and
`@variant`. `q.Actions` is a styled-only layout helper. Every part takes `@as`, the tag to render
instead of its own (upstream's `render`), and the parts you'd put on your own element have a
modifier too.

### Questionnaire

A native `<form>` (with `novalidate`), so answers are read with `FormData`.

| Argument        | Type                            | Default   | What it does                                                    |
| --------------- | ------------------------------- | --------- | --------------------------------------------------------------- |
| `@items`        | `QuestionnaireItemDefinition[]` |           | The items in order: `name`, `required`, `disabled`, `choices`   |
| `@item`         | `string`                        |           | The active item, controlled. Pass `@onItemChange` too           |
| `@defaultItem`  | `string`                        | the first | The item it starts on                                           |
| `@onItemChange` | `(item: string) => void`        |           | Called with each item it moves to                               |
| `@shortcuts`    | `"letters" \| "numbers"`        |           | Keys that pick fixed answers                                    |
| `@noValidate`   | `boolean`                       | `true`    | `false` turns on the browser's own validation of filled answers |
| `@onSubmit`     | `(event: SubmitEvent) => void`  |           | Called when every item is valid and the form submits            |
| `@onReset`      | `(event: Event) => void`        |           | Called on a reset, before the answers go back to their defaults |
| `@name`         | `string`                        |           | Its name, for `QuestionnaireHarness`                            |
| `@as`           | `string`                        | `form`    | The tag to render. Keep it a form: it submits and resets as one |

It yields `Progress`, `Item`, `Actions`, `Previous`, `Skip`, `Next`, `Submit`, the `actions`,
`previous`, `skip`, `next` and `submit` modifiers, and `activeItem`, `current`, `total`, `first`
and `last`. The form has `data-current`, `data-total`, `data-first`, `data-last` and
`data-shortcuts`.

Where `@item` (or `@defaultItem`) names an item it doesn't step through, an unknown one or one
that is now disabled, it moves to the first and calls `@onItemChange` with it, as upstream does,
so a host that controls `@item` follows. In development it also warns, as upstream does, where
`@items` and the rendered items part: a name defined twice, an unknown `@defaultItem`, an item or
a choice on one side only, and choices whose shortcuts won't match.

### Progress

A `div` with `role="progressbar"`, `aria-valuenow` and the rest, live (`aria-live="polite"`), in
small muted figures. It reads `Question 2 of 3`; a block replaces what it shows, and gets
`current`, `total`, `first` and `last`. `@label` names it (default `Questionnaire progress`),
`@formatValue` writes its words (`(current, total) => string`) and `@as` changes its tag.

### Item

| Argument          | Type                                        | Default    | What it does                                                       |
| ----------------- | ------------------------------------------- | ---------- | ------------------------------------------------------------------ |
| `@name`           | `string`                                    |            | Its answers' name in the form, and the item's in `@items`, `@item` |
| `@required`       | `boolean`                                   | `false`    | Whether it must be answered; it can't be skipped                   |
| `@multiple`       | `boolean`                                   | `false`    | Whether it takes several fixed answers (checkboxes)                |
| `@disabled`       | `boolean`                                   | `false`    | Whether it doesn't apply: passed over and not submitted            |
| `@invalid`        | `boolean`                                   | `false`    | Whether your own validation found it invalid                       |
| `@onStatusChange` | `(status: QuestionnaireItemStatus) => void` |            | Called as it becomes `unanswered`, `answered` or `skipped`         |
| `@as`             | `string`                                    | `fieldset` | The tag to render                                                  |

A `fieldset`, hidden and inert unless active, with `data-active`, `data-status`, `data-required`,
`data-multiple`, `data-invalid` and `data-disabled`. Its `aria-describedby` names its
descriptions, then its error while it is invalid, and its `aria-keyshortcuts` lists the keys it
answers to; both keep your own (`<q.Item aria-describedby="hint">`), as upstream merges them: your
ids after the item's, your keys before its own. It yields `Title`, `Description`,
`Choices`, `Choice`, `ChoiceDescription`, `Input` and `Error`, the `title` and `description`
modifiers for your own elements, and `name`, `status`, `isActive` and `isInvalid`.

`Title` (a `legend`), `Description` (a `p`) and `Choices` (a `div`) take `@as`, the tag to
render instead.

An optional item that is unanswered isn't valid either: it is left by answering it or skipping
it, so its error says `Choose an answer or skip this question.`

### Choice

A `<label>` around a radio (a checkbox in a `@multiple` item), so the whole row picks it. Its
block is its text; `i.ChoiceDescription` is a second, muted line.

| Argument           | Type                                       | What it does                                 |
| ------------------ | ------------------------------------------ | -------------------------------------------- |
| `@value`           | `string`                                   | The value it submits                         |
| `@checked`         | `boolean`                                  | Whether it is checked, controlled            |
| `@defaultChecked`  | `boolean`                                  | Whether it starts checked                    |
| `@disabled`        | `boolean`                                  | Whether it can't be chosen                   |
| `@onCheckedChange` | `(checked: boolean, event: Event) => void` | Called as it changes (upstream's `onChange`) |
| `@as`              | `string`                                   | The tag to render. Default `label`           |

It has `data-checked` or `data-unchecked`, `data-type`, `data-shortcut` and `data-invalid`.

### Input

A text `<input>` for another answer: `@value`, `@defaultValue`, `@onValueChange` and `@disabled`,
a `type` attribute for another kind of text, and `@as` for another tag (a custom element of
yours). Pass `@value` with `@onValueChange` to control its text. It is the item's answer while
it has text and was the last answer given: only then does it have the item's `name` and belong
to the form.

### Error

A `p`, hidden until the item is invalid, then an alert the item's `aria-describedby` names. Its
text is the block, else `@message`, else `Choose an answer to continue.` (or, for an optional
item, `Choose an answer or skip this question.`). `@as` changes its tag.

### Previous, Skip, Next and Submit

Buttons that look like Buttons (`@variant`, default `outline` for Previous and Skip and
`default` for Next and Submit; `@size`, default `default`), each shown only where it applies and
hidden and inert otherwise. `@disabled` disables one; `@label` or a block replaces its text
(default `Previous`, `Skip`, `Next`, `Submit`), and `@as` its tag. Each has `data-status` (the
active item's), `data-visible` or `data-hidden`, and Next and Submit `aria-keyshortcuts="Enter"`.

To make your own element or component one of them, with its look and behaviour, use the
questionnaire's `previous`, `skip`, `next` or `submit` modifier, which takes `disabled`,
`variant` and `size`: `<LinkTo {{q.previous}}>`, `<span {{q.next variant="secondary"}}>`.

### Data attributes

| Part        | `class`                                                                        | `data-slot`                 | `data-test-jn-part`                  |
| ----------- | ------------------------------------------------------------------------------ | --------------------------- | ------------------------------------ |
| Root        | `jn-questionnaire`                                                             | `questionnaire`             | (`data-test-jn="questionnaire"`)     |
| Progress    | `jn-questionnaire-progress`                                                    | `questionnaire-progress`    | `progress`                           |
| Item        | `jn-questionnaire-item`                                                        | `questionnaire-item`        | `item` (value: `@name`)              |
| Title       | `jn-questionnaire-title jn-font-heading`                                       | `questionnaire-title`       | `title`                              |
| Description | `jn-questionnaire-description`                                                 | `questionnaire-description` | `description`                        |
| Choices     | `jn-questionnaire-choices group/questionnaire-choices`                         | `questionnaire-choices`     | `choices`                            |
| Choice      | `jn-questionnaire-choice group/questionnaire-choice`                           | `questionnaire-choice`      | `choice` (value: `@value`)           |
| Input       | `jn-questionnaire-input`                                                       | `questionnaire-input`       | `input`                              |
| Error       | `jn-questionnaire-error`                                                       | `questionnaire-error`       | `error`                              |
| Actions     | `jn-questionnaire-actions`                                                     | `questionnaire-actions`     | `actions`                            |
| Previous…   | the Button's, and `jn-questionnaire-previous` (or `-skip`, `-next`, `-submit`) | `questionnaire-previous`…   | `previous`, `skip`, `next`, `submit` |

## Testing

`QuestionnaireHarness` from `@ember-joinery/test-support` drives a questionnaire, styled or
headless. Its methods take an item's `@name`, and default to the active item:

```ts
import { QuestionnaireHarness } from '@ember-joinery/test-support'

const plan = new QuestionnaireHarness('plan') // <Questionnaire @name="plan">
await plan.choose('tool-calls')
await plan.next()
assert.strictEqual(plan.activeItem, 'signals')
assert.strictEqual(plan.progressText, 'Question 2 of 3')
```

| `QuestionnaireHarness`                                                 | What it is                                                    |
| ---------------------------------------------------------------------- | ------------------------------------------------------------- |
| `form`, `formData`                                                     | The form, and what it would submit                            |
| `itemNames`, `activeItem`, `item(name)`                                | The items, the one that shows, and an item's fieldset         |
| `status(name)`, `isInvalid`, `isRequired`, `isMultiple`, `isDisabled`  | An item's state                                               |
| `title`, `description`, `describedBy`, `error`                         | An item's question, description, `aria-describedby` and error |
| `choices`, `checked`, `isChecked(value)`, `shortcut(value)`            | An item's fixed answers                                       |
| `choice(value)`, `choiceInput(value)`, `choiceLabel(value)`, `input()` | The answer controls                                           |
| `progress`, `progressText`, `current`, `total`                         | Where it is                                                   |
| `button(kind)`, `canGoBack`, `canSkip`, `canGoNext`, `canSubmit`       | The navigation buttons that show                              |
| `isFocused`, `isItemFocused`                                           | Whether focus is in an item, or on its fieldset               |
| `choose(value)`, `fillIn(text)`, `focusChoice(value)`                  | Answers, as a reader does                                     |
| `next()`, `previous()`, `skip()`, `submit()`, `press(key)`             | Moves, with the buttons or the keyboard                       |

## Upstream

shadcn/ui's [Questionnaire](https://ui.shadcn.com/docs/components/radix/questionnaire), from
`apps/v4/registry/bases/radix/ui/questionnaire.tsx` (and `@shadcn/react`'s
`packages/react/src/questionnaire`) at shadcn-ui/ui@8ab2771, shown in the Nova style.
