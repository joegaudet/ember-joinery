# Questionnaire

A multi-step form of single-choice, multiple-choice, freeform and skippable questions:
`@shadcn/react`'s headless Questionnaire. It has no styles; the styled
[Questionnaire](/components/questionnaire.md) is the same with shadcn's classes and `data-slot`s.

<Example @name="questionnaire-headless" @title="A two-step questionnaire" @align="start" />

## Usage

```gts
import { Questionnaire } from '@ember-joinery/primitives/questionnaire'

const items = [
  { name: 'prototype', required: true, choices: [{ value: 'delegation' }, { value: 'questions' }] },
  { name: 'detail', choices: [{ value: 'focused' }, { value: 'complete' }] },
]

<template>
  <Questionnaire @items={{items}} @onSubmit={{submit}} as |q|>
    <q.Progress />
    <q.Item @name="prototype" @required={{true}} as |i|>
      <i.Title>What should we prototype next?</i.Title>
      <i.Description>Choose a direction or write your own.</i.Description>
      <i.Choices>
        <i.Choice @value="delegation" as |c|>
          <c.Input />
          <c.Label>Delegation</c.Label>
          <c.Shortcut />
        </i.Choice>
        <i.Input aria-label="Another answer" />
      </i.Choices>
      <i.Error />
    </q.Item>
    <q.Previous />
    <q.Skip />
    <q.Next />
    <q.Submit />
  </Questionnaire>
</template>
```

- **The root** is a native `<form>` with `novalidate`, so answers are read with `FormData` in
  `@onSubmit`. It checks every item before it calls it: an invalid one stops the submit, and the
  questionnaire moves to it and focuses its first answer.
- **The items** are `<fieldset>`s, hidden and inert unless active. `@items` names them in order
  (with `required`, `disabled` and each item's `choices`, for the shortcuts), so progress and the
  buttons are right from the first render; without it, the rendered items are stepped through in
  document order. Moving to an item focuses it. An item's `aria-describedby` and
  `aria-keyshortcuts` keep the ones you give it, merged with its own.
- **An item's status** is `unanswered`, `answered` or `skipped`. A required item must be
  answered; an optional one must be answered or skipped. `@onStatusChange` hears each change.
- **A choice** is a `<label>` around its `<input>` (a radio, or a checkbox in a `@multiple`
  item), named after the item, so the browser's own radio behaviour holds. `@checked` (with
  `@onCheckedChange`) controls it; `@defaultChecked` starts it checked, and a form reset puts it
  back.
- **A freeform answer** (`i.Input`) belongs to the form only while it has text and was the last
  answer given; choosing a fixed answer of a single-answer item takes over from it.
- **The buttons** show where they apply: Previous after the first item, Skip on an optional one,
  Next before the last, Submit on the last. Each is hidden and inert otherwise.
- **The keyboard**: see [the styled page](/components/questionnaire.md#keyboard-interactions).

### In a component

`QuestionnaireState`, `QuestionnaireItemState`, `QuestionnaireChoiceState` and
`QuestionnaireInputState` are the behaviour, for a component that renders its own parts, as the
styled one does. Each part is a `part()` modifier to put on any element (`q.root`, `item.item`,
`choice.input`…), and the `*Spec()` methods return what they put there, for a part of your own
that adds attributes:

```ts
import { QuestionnaireItemState } from '@ember-joinery/primitives/questionnaire'
import { part } from '@ember-joinery/primitives/part'

class StyledItem extends Component {
  item = new QuestionnaireItemState(this, this.args.questionnaire, { name: () => this.args.name })
  title = part(() => {
    const spec = this.item.titleSpec()
    return { ...spec, class: 'my-title', attributes: { ...spec.attributes, 'data-slot': 'title' } }
  })
}
```

## API

The arguments are the styled Questionnaire's; see its
[API reference](/components/questionnaire.md#api-reference). The headless parts are:

| Yielded by        | Parts                                                                                                                       |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `<Questionnaire>` | `Progress`, `Item`, `Previous`, `Skip`, `Next`, `Submit`, and its state                                                     |
| `q.Item`          | `Title` (`legend`), `Description` (`p`), `Choices`, `Choice`, `Input`, `Error`, and the `title` and `description` modifiers |
| `i.Choice`        | `Input` (the radio or checkbox), `Label` (`span`), `Shortcut` (`span`), and `isChecked`, `type`, `shortcut`                 |

Every part takes `@as` for another tag (the root, a `form`; an item, a `fieldset`; a choice, a
`label`; the freeform `Input`, an `input`; the navigation buttons, a `button`), and attributes,
but a choice's own radio or checkbox (`c.Input`). The state attributes are upstream's
(`data-status`, `data-checked`, `data-type`, `data-shortcut`, `data-visible`…).

## Testing

`QuestionnaireHarness` drives it; see [Questionnaire](/components/questionnaire.md#testing).
