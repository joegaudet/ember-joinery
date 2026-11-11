import { Questionnaire } from '@ember-joinery/primitives/questionnaire'

const items = [
  {
    name: 'prototype',
    required: true,
    choices: [{ value: 'delegation' }, { value: 'questions' }],
  },
  { name: 'detail', choices: [{ value: 'focused' }, { value: 'complete' }] },
]

function submit(event: SubmitEvent) {
  event.preventDefault()
}

<template>
  <Questionnaire class="survey" @items={{items}} @shortcuts="letters" @onSubmit={{submit}} as |q|>
    <q.Progress class="survey-progress" />
    <q.Item @name="prototype" @required={{true}} as |i|>
      <i.Title>What should we prototype next?</i.Title>
      <i.Description>Choose a direction or write your own.</i.Description>
      <i.Choices class="survey-choices">
        <i.Choice @value="delegation" class="survey-choice" as |c|>
          <c.Input />
          <c.Label>Delegation</c.Label>
          <c.Shortcut class="survey-key" />
        </i.Choice>
        <i.Choice @value="questions" class="survey-choice" as |c|>
          <c.Input />
          <c.Label>Question prompts</c.Label>
          <c.Shortcut class="survey-key" />
        </i.Choice>
        <i.Input aria-label="Another answer" placeholder="Type another answer…" />
      </i.Choices>
      <i.Error class="survey-error" />
    </q.Item>
    <q.Item @name="detail" as |i|>
      <i.Title>How much detail?</i.Title>
      <i.Choices class="survey-choices">
        <i.Choice @value="focused" class="survey-choice" as |c|>
          <c.Input />
          <c.Label>Focused</c.Label>
          <c.Shortcut class="survey-key" />
        </i.Choice>
        <i.Choice @value="complete" class="survey-choice" as |c|>
          <c.Input />
          <c.Label>Complete flow</c.Label>
          <c.Shortcut class="survey-key" />
        </i.Choice>
      </i.Choices>
      <i.Error class="survey-error" />
    </q.Item>
    <div class="survey-actions">
      <q.Previous />
      <q.Skip />
      <q.Next />
      <q.Submit />
    </div>
  </Questionnaire>
  <style>
    .survey {
      display: grid;
      gap: 0.75rem;
      max-width: 24rem;
      font-size: 0.875rem;
    }
    .survey fieldset {
      display: grid;
      gap: 0.5rem;
      margin: 0;
      padding: 0;
      border: 0;
    }
    .survey legend {
      font-weight: 600;
    }
    .survey p {
      margin: 0;
    }
    .survey-progress {
      font-variant-numeric: tabular-nums;
    }
    .survey-choices {
      display: grid;
      gap: 0.25rem;
    }
    .survey-choice {
      display: flex;
      gap: 0.5rem;
      align-items: center;
    }
    .survey-key {
      margin-inline-start: auto;
      font-family: ui-monospace, monospace;
    }
    .survey-error {
      color: oklch(0.5 0.2 27);
    }
    .survey-actions {
      display: flex;
      gap: 0.5rem;
      justify-content: flex-end;
    }
  </style>
</template>
