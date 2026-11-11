import { Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  {
    choices: [{ value: 'tool-calls' }, { value: 'approvals' }, { value: 'handoffs' }],
    name: 'direction',
    required: true,
  },
  {
    choices: [
      { value: 'progress' },
      { value: 'decisions' },
      { value: 'risks' },
      { value: 'next-step' },
    ],
    name: 'signals',
  },
  {
    choices: [{ value: 'now' }, { value: 'next-cycle' }, { value: 'backlog' }],
    name: 'timing',
    required: true,
  },
]

function handleSubmit(event: SubmitEvent) {
  event.preventDefault()

  const formData = new FormData(event.currentTarget as HTMLFormElement)
  const answers = {
    direction: formData.get('direction'),
    signals: formData.getAll('signals'),
    timing: formData.get('timing'),
  }

  toast('Agent plan saved', {
    description: `Direction: ${String(answers.direction ?? 'None')} · Progress signals: ${answers.signals.join(', ') || 'None'} · Timing: ${String(answers.timing ?? 'None')}`,
  })
}

<template>
  <Questionnaire
    class="mx-auto max-w-md"
    @defaultItem="direction"
    @items={{items}}
    @shortcuts="letters"
    @onSubmit={{handleSubmit}}
    as |q|
  >
    <q.Progress />

    <q.Item @name="direction" @required={{true}} as |i|>
      <i.Title>
        What should the agent build next?
      </i.Title>
      <i.Description>
        Choose a direction or describe another task.
      </i.Description>
      <i.Choices>
        <i.Choice @value="tool-calls">
          <span class="font-medium">Tool call timeline</span>
          <span class="text-muted-foreground">
            Show what the agent ran and what came back.
          </span>
        </i.Choice>
        <i.Choice @value="approvals">
          <span class="font-medium">Approval checkpoints</span>
          <span class="text-muted-foreground">
            Ask before sensitive or destructive actions.
          </span>
        </i.Choice>
        <i.Choice @value="handoffs">
          <span class="font-medium">Sub-agent handoffs</span>
          <span class="text-muted-foreground">
            Make delegated work and results easier to follow.
          </span>
        </i.Choice>
        <i.Input aria-label="Another agent feature" placeholder="Describe another feature…" />
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Item @name="signals" @multiple={{true}} as |i|>
      <i.Title>
        What should every progress update include?
      </i.Title>
      <i.Description>
        Select all that apply, or skip this question.
      </i.Description>
      <i.Choices>
        <i.Choice @value="progress">Progress</i.Choice>
        <i.Choice @value="decisions">Decisions</i.Choice>
        <i.Choice @value="risks">Risks</i.Choice>
        <i.Choice @value="next-step">Next step</i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Item @name="timing" @required={{true}} as |i|>
      <i.Title>When should work begin?</i.Title>
      <i.Description>
        Choose when the agent should begin the work.
      </i.Description>
      <i.Choices>
        <i.Choice @value="now">Start now</i.Choice>
        <i.Choice @value="next-cycle">
          Next development cycle
        </i.Choice>
        <i.Choice @value="backlog">
          Add it to the backlog
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Actions>
      <q.Previous />
      <q.Skip />
      <q.Next>Next</q.Next>
      <q.Submit>Save plan</q.Submit>
    </q.Actions>
  </Questionnaire>
</template>
