import { Button, Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  { name: 'change', required: true },
  { name: 'verification', required: true },
  { name: 'notes' },
]

function handleSubmit(event: SubmitEvent) {
  event.preventDefault()

  const formData = new FormData(event.currentTarget as HTMLFormElement)
  const answers = {
    change: formData.get('change'),
    verification: formData.getAll('verification'),
    notes: formData.get('notes'),
  }

  toast('Draft updated', {
    description: `Migration: ${String(answers.change ?? 'None')} · Verification: ${answers.verification.join(', ') || 'None'} · Notes: ${String(answers.notes || 'None')}`,
  })
}

const handleReset = () => toast('Saved answers restored')

<template>
  <Questionnaire
    class="mx-auto max-w-md"
    @defaultItem="verification"
    @items={{items}}
    @onReset={{handleReset}}
    @onSubmit={{handleSubmit}}
    as |q|
  >
    <q.Progress />

    <q.Item @name="change" @required={{true}} as |i|>
      <i.Title>What kind of migration is this?</i.Title>
      <i.Description>
        This answer was saved during the previous session.
      </i.Description>
      <i.Choices>
        <i.Choice @value="incremental" @defaultChecked={{true}}>
          Incremental migration
        </i.Choice>
        <i.Choice @value="cutover">
          Single cutover
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Item @name="verification" @multiple={{true}} @required={{true}} as |i|>
      <i.Title>
        How should the migration be verified?
      </i.Title>
      <i.Description>
        These checks were selected during the previous session.
      </i.Description>
      <i.Choices>
        <i.Choice @value="tests" @defaultChecked={{true}}>
          Run migration tests
        </i.Choice>
        <i.Choice @value="typecheck" @defaultChecked={{true}}>
          Run the typecheck
        </i.Choice>
        <i.Choice @value="manual">
          Perform a manual smoke test
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Item @name="notes" as |i|>
      <i.Title>
        Anything else the agent should remember?
      </i.Title>
      <i.Description>
        This note was saved with the draft.
      </i.Description>
      <i.Input
        aria-label="Saved migration note"
        @defaultValue="Keep the existing public API stable."
      />
    </q.Item>

    <q.Actions>
      <Button type="reset" @variant="outline">
        Reset changes
      </Button>
      <q.Previous />
      <q.Next>Next</q.Next>
      <q.Submit>Update draft</q.Submit>
    </q.Actions>
  </Questionnaire>
</template>
