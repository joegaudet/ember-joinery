import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form } from '@ember-formwright/ember'
import { Card, Field, FieldGroup, asButton } from '@ember-joinery/ember'

const plans = [
  { id: 'hobby', label: 'Hobby' },
  { id: 'pro', label: 'Pro' },
  { id: 'team', label: 'Team' },
]

/** Formwright takes a Standard Schema (zod, valibot…) or a function returning the errors. */
function validate(project) {
  const errors = {}
  if (!project.name.trim()) errors.name = ['Enter a project name.']
  if (!project.plan) errors.plan = ['Choose a plan.']
  if (!project.terms) errors.terms = ['Accept the terms to continue.']
  return errors
}

/** A Formwright form drawn by Joinery: each control the Joinery component of that name. */
class NewProject extends Component {
  model = { name: '', plan: null, notify: true, terms: false }
  @tracked saved

  save = project => {
    this.saved = project.name
  }

  get status() {
    return this.saved ? `Created ${this.saved}.` : ''
  }

  <template>
    <Card @name="project" as |c|>
      <c.Header>
        <c.Title>New project</c.Title>
        <c.Description>Set up a project and choose its plan.</c.Description>
      </c.Header>
      <Form
        @model={{this.model}}
        @name="project"
        @validator={{validate}}
        @onSubmit={{this.save}}
        class="contents"
        as |f|
      >
        <c.Content>
          <FieldGroup>
            <f.Field @for="name" @label="Project name" @hint="Shown on your dashboard." />
            <f.Field
              @for="plan"
              @control="select"
              @label="Plan"
              @options={{plans}}
              @placeholder="Choose a plan"
            />
            <f.Field @for="notify" @control="switch" @label="Email me about deploys" />
            <f.Field @for="terms" @control="checkbox" @label="I accept the terms" />
          </FieldGroup>
        </c.Content>
        <c.Footer>
          <Field @orientation="horizontal">
            <f.Submit {{asButton}}>Create</f.Submit>
          </Field>
        </c.Footer>
      </Form>
    </Card>
    <p role="status">{{this.status}}</p>
  </template>
}

<template>
  <main>
    <h1>Joinery with Formwright</h1>
    <p>
      This app sets Formwright up with
      <code>setupJoineryForms()</code>, so its forms render Joinery's inputs in shadcn's Field
      layout. CI builds it and runs its smoke test.
    </p>
    <NewProject />
  </main>
</template>
