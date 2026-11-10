import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Questionnaire } from '@ember-joinery/primitives/questionnaire'
import { QuestionnaireHarness } from '@ember-joinery/test-support'

const ITEMS = [
  { name: 'prototype', required: true, choices: [{ value: 'delegation' }, { value: 'questions' }] },
  { name: 'detail', required: false, choices: [{ value: 'focused' }, { value: 'complete' }] },
]

module('Integration | primitives | questionnaire', function (hooks) {
  setupRenderingTest(hooks)

  test('headless: native parts, no styles, the same behaviour', async function (assert) {
    let answers: FormData | undefined
    const submit = (event: SubmitEvent) => {
      event.preventDefault()
      answers = new FormData(event.currentTarget as HTMLFormElement)
    }
    await render(
      <template>
        <Questionnaire @name="q" @items={{ITEMS}} @shortcuts="letters" @onSubmit={{submit}} as |q|>
          <q.Progress />
          <q.Item @name="prototype" @required={{true}} as |i|>
            <i.Title>What should we prototype next?</i.Title>
            <i.Description>Choose a direction or write your own.</i.Description>
            <i.Choices>
              <i.Choice @value="delegation" as |c|>
                <c.Input />
                <c.Label>Delegation</c.Label>
                <c.Shortcut />
                <span data-test-checked>{{if c.isChecked "checked" "unchecked"}} {{c.type}}</span>
              </i.Choice>
              <i.Choice @value="questions" as |c|>
                <c.Input />
                <c.Label>Question prompts</c.Label>
                <c.Shortcut />
              </i.Choice>
              <i.Input aria-label="Another answer" placeholder="Type another answer…" />
            </i.Choices>
            <i.Error />
          </q.Item>
          <q.Item @name="detail" as |i|>
            <i.Title>How much detail?</i.Title>
            <i.Choices>
              <i.Choice @value="focused" as |c|><c.Input /><c.Label>Focused</c.Label></i.Choice>
              <i.Choice @value="complete" as |c|><c.Input /><c.Label>Complete</c.Label></i.Choice>
            </i.Choices>
            <i.Error />
          </q.Item>
          <q.Previous />
          <q.Skip />
          <q.Next />
          <q.Submit />
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.dom(q.form).hasTagName('form').doesNotHaveAttribute('class')
    assert.dom(q.form).doesNotHaveAttribute('data-slot', 'headless: no styled slots')
    assert.dom(q.item()).hasTagName('fieldset').doesNotHaveAttribute('class')
    assert.dom(q.item().querySelector('legend')).hasText('What should we prototype next?')
    assert.strictEqual(q.progressText, 'Question 1 of 2')
    assert.strictEqual(q.shortcut('delegation'), 'A')
    assert.strictEqual(q.choiceLabel('delegation'), 'Delegation')
    assert.dom('[data-test-checked]').hasText('unchecked radio', 'a choice yields its state')
    assert.dom(q.button('next')).hasText('Next', 'English defaults')
    assert.dom(q.button('previous')).hasText('Previous')

    await q.choose('questions')
    assert.true(q.isChecked('questions'))
    await q.next()
    assert.strictEqual(q.activeItem, 'detail')
    assert.dom(q.button('skip')).hasText('Skip')
    await q.skip()
    assert.deepEqual(answers && [...answers.entries()], [['prototype', 'questions']])
    await a11yAudit()
  })
})
