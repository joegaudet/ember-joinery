import { Questionnaire, toast } from '@ember-joinery/ember'

const items = [
  { name: 'scope', required: true },
  { name: 'strategy', required: true },
  { name: 'tests', required: true },
  { name: 'delivery', required: true },
]

function handleSubmit(event: SubmitEvent) {
  event.preventDefault()

  const formData = new FormData(event.currentTarget as HTMLFormElement)

  toast('Pull request plan ready', {
    description: `Scope: ${String(formData.get('scope') ?? 'None')} · Commits: ${String(formData.get('strategy') ?? 'None')} · Tests: ${String(formData.get('tests') ?? 'None')} · Delivery: ${String(formData.get('delivery') ?? 'None')}`,
  })
}

/** One segment per item, the ones up to the active item filled. */
const segments = (current: number, total: number) =>
  Array.from({ length: total }, (_, index) => index < current)

<template>
  <Questionnaire
    class="mx-auto max-w-md"
    @defaultItem="scope"
    @items={{items}}
    @onSubmit={{handleSubmit}}
    as |q|
  >
    <q.Progress class="w-full" as |p|>
      <div class="mb-2 flex gap-1.5" aria-hidden="true">
        {{#each (segments p.current p.total) as |filled|}}
          <span
            class={{if
              filled
              "h-1.5 flex-1 rounded-full bg-primary"
              "h-1.5 flex-1 rounded-full bg-muted"
            }}
          ></span>
        {{/each}}
      </div>
      <span>
        Checkpoint
        {{p.current}}
        of
        {{p.total}}
      </span>
    </q.Progress>

    <q.Item @name="scope" @required={{true}} as |i|>
      <i.Title>How large is the change?</i.Title>
      <i.Choices>
        <i.Choice @value="small">Small patch</i.Choice>
        <i.Choice @value="medium">
          Feature-sized change
        </i.Choice>
        <i.Choice @value="large">
          Cross-package change
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Item @name="strategy" @required={{true}} as |i|>
      <i.Title>
        How should commits be organized?
      </i.Title>
      <i.Choices>
        <i.Choice @value="single">
          Single commit
        </i.Choice>
        <i.Choice @value="logical">
          Logical commits
        </i.Choice>
        <i.Choice @value="squash">
          Squash before review
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Item @name="tests" @required={{true}} as |i|>
      <i.Title>Which tests should run?</i.Title>
      <i.Choices>
        <i.Choice @value="targeted">
          Targeted tests
        </i.Choice>
        <i.Choice @value="package">
          Package suite
        </i.Choice>
        <i.Choice @value="workspace">
          Full workspace
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Item @name="delivery" @required={{true}} as |i|>
      <i.Title>
        How should the work be delivered?
      </i.Title>
      <i.Choices>
        <i.Choice @value="patch">Patch only</i.Choice>
        <i.Choice @value="commit">
          Committed locally
        </i.Choice>
        <i.Choice @value="branch">
          Push a review branch
        </i.Choice>
      </i.Choices>
      <i.Error />
    </q.Item>

    <q.Actions>
      <q.Previous />
      <q.Next>Next</q.Next>
      <q.Submit>Finish plan</q.Submit>
    </q.Actions>
  </Questionnaire>
</template>
