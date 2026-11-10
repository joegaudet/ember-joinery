import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, focus, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Questionnaire,
  QuestionnaireActions,
  type QuestionnaireItemDefinition,
  type QuestionnaireItemStatus,
} from '@ember-joinery/ember'
import { QuestionnaireHarness } from '@ember-joinery/test-support'

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

const ITEMS: QuestionnaireItemDefinition[] = [
  {
    name: 'direction',
    required: true,
    choices: [{ value: 'tool-calls' }, { value: 'approvals' }, { value: 'handoffs' }],
  },
  {
    name: 'signals',
    choices: [{ value: 'progress' }, { value: 'decisions' }, { value: 'risks' }],
  },
  { name: 'timing', required: true, choices: [{ value: 'now' }, { value: 'later' }] },
]

/** What the form submitted, by item: every value of each name. */
class Submissions {
  @tracked last: Record<string, string[]> | undefined
  count = 0
  submit = (event: SubmitEvent) => {
    event.preventDefault()
    this.count += 1
    const data = new FormData(event.currentTarget as HTMLFormElement)
    const answers: Record<string, string[]> = {}
    for (const [name, value] of data) (answers[name] ??= []).push(String(value))
    this.last = answers
  }
}

module('Integration | components | questionnaire', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes, slots and ARIA on every part', async function (assert) {
    const submissions = new Submissions()
    await render(
      <template>
        <Questionnaire
          @name="plan"
          @items={{ITEMS}}
          @shortcuts="letters"
          @onSubmit={{submissions.submit}}
          as |q|
        >
          <q.Progress />
          <q.Item @name="direction" @required={{true}} as |i|>
            <i.Title>What should the agent build next?</i.Title>
            <i.Description>Choose a direction or describe another task.</i.Description>
            <i.Choices>
              <i.Choice @value="tool-calls">
                <span>Tool call timeline</span>
                <i.ChoiceDescription>Show what the agent ran.</i.ChoiceDescription>
              </i.Choice>
              <i.Choice @value="approvals">Approval checkpoints</i.Choice>
              <i.Choice @value="handoffs">Sub-agent handoffs</i.Choice>
              <i.Input aria-label="Another agent feature" placeholder="Describe another feature…" />
            </i.Choices>
            <i.Error />
          </q.Item>
          <q.Item @name="signals" @multiple={{true}} as |i|>
            <i.Title>What should every update include?</i.Title>
            <i.Choices>
              <i.Choice @value="progress">Progress</i.Choice>
              <i.Choice @value="decisions">Decisions</i.Choice>
              <i.Choice @value="risks">Risks</i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="timing" @required={{true}} as |i|>
            <i.Title>When should work begin?</i.Title>
            <i.Choices>
              <i.Choice @value="now">Start now</i.Choice>
              <i.Choice @value="later">Later</i.Choice>
            </i.Choices>
          </q.Item>
          <q.Actions>
            <q.Previous />
            <q.Skip />
            <q.Next>Next</q.Next>
            <q.Submit>Save plan</q.Submit>
          </q.Actions>
        </Questionnaire>
      </template>,
    )
    const plan = new QuestionnaireHarness('plan')
    assert
      .dom(plan.form)
      .hasTagName('form')
      .hasClass('jn-questionnaire')
      .hasAttribute('data-slot', 'questionnaire')
      .hasAttribute('novalidate', '', 'its own validation, not the browser’s')
      .hasAttribute('data-shortcuts', 'letters')
      .hasAttribute('data-current', '1')
      .hasAttribute('data-total', '3')
      .hasAttribute('data-first', '')
    assert.deepEqual(plan.itemNames, ['direction', 'signals', 'timing'])
    assert.strictEqual(plan.activeItem, 'direction', 'the first item, from @items')

    assert
      .dom(plan.progress)
      .hasClass('jn-questionnaire-progress')
      .hasAttribute('data-slot', 'questionnaire-progress')
      .hasAttribute('role', 'progressbar')
      .hasAttribute('aria-label', 'Questionnaire progress')
      .hasAttribute('aria-live', 'polite')
      .hasAttribute('aria-valuemin', '1')
      .hasAttribute('aria-valuemax', '3')
      .hasAttribute('aria-valuenow', '1')
      .hasText('Question 1 of 3')
    assert.strictEqual(plan.progressText, 'Question 1 of 3')

    const item = plan.item('direction')
    assert
      .dom(item)
      .hasTagName('fieldset')
      .hasClass('jn-questionnaire-item')
      .hasAttribute('data-slot', 'questionnaire-item')
      .hasAttribute('tabindex', '-1')
      .hasAttribute('data-active', '')
      .hasAttribute('data-required', '')
      .hasAttribute('data-status', 'unanswered')
      .doesNotHaveAttribute('hidden')
    assert.dom(plan.item('signals')).hasAttribute('hidden').hasAttribute('inert')
    assert.dom(plan.item('signals')).hasAttribute('data-multiple')
    assert
      .dom(item.querySelector('legend'))
      .hasClass('jn-questionnaire-title')
      .hasClass('jn-font-heading')
      .hasAttribute('data-slot', 'questionnaire-title')
    assert.strictEqual(plan.title(), 'What should the agent build next?')
    assert.strictEqual(
      plan.describedBy(),
      'Choose a direction or describe another task.',
      'the description describes the item',
    )
    assert.strictEqual(plan.error(), '', 'no error until it is invalid')

    const choice = plan.choice('tool-calls')
    assert
      .dom(choice)
      .hasTagName('label')
      .hasClass('jn-questionnaire-choice')
      .hasClass('group/questionnaire-choice')
      .hasAttribute('data-slot', 'questionnaire-choice')
      .hasAttribute('data-type', 'radio')
      .hasAttribute('data-unchecked', '')
      .hasAttribute('data-shortcut', 'A')
    assert
      .dom(plan.choiceInput('tool-calls'))
      .hasClass('jn-questionnaire-choice-input')
      .hasAttribute('type', 'radio')
      .hasAttribute('name', 'direction')
      .hasAttribute('value', 'tool-calls')
      .hasAttribute('aria-keyshortcuts', 'A')
      .doesNotHaveAttribute('required', 'not with a freeform answer beside it')
    assert
      .dom(choice.querySelector('[data-slot="questionnaire-choice-indicator"]'))
      .hasAttribute('aria-hidden', 'true')
    assert.dom(choice.querySelector('[data-slot="questionnaire-choice-description"]')).exists()
    assert.strictEqual(plan.shortcut('tool-calls'), 'A')
    assert.strictEqual(plan.shortcut('handoffs'), 'C')
    assert.deepEqual(plan.choices(), ['tool-calls', 'approvals', 'handoffs'])
    assert
      .dom(plan.input())
      .hasClass('jn-questionnaire-input')
      .hasAttribute('data-slot', 'questionnaire-input')
      .hasAttribute('form', '', 'outside the form until it is the answer')
      .doesNotHaveAttribute('name')
      .hasAttribute('data-empty', '')
    assert.dom(plan.input()!.parentElement).hasClass('jn-questionnaire-input-wrapper')

    const next = plan.button('next')
    assert
      .dom(next)
      .hasClass('jn-button')
      .hasClass('jn-button-variant-default')
      .hasClass('jn-questionnaire-next')
      .hasAttribute('data-slot', 'questionnaire-next')
      .hasAttribute('data-variant', 'default')
      .hasAttribute('data-size', 'default')
      .hasAttribute('type', 'button')
      .hasAttribute('aria-keyshortcuts', 'Enter')
      .hasText('Next')
    assert.dom(plan.button('previous')).hasClass('jn-button-variant-outline').hasText('Previous')
    assert.dom(plan.button('submit')).hasAttribute('type', 'submit').hasText('Save plan')
    assert.false(plan.canGoBack, 'no Previous on the first item')
    assert.false(plan.canSkip, 'no Skip on a required item')
    assert.true(plan.canGoNext)
    assert.false(plan.canSubmit, 'Submit only on the last')
    assert.dom(plan.button('previous')).hasAttribute('aria-hidden', 'true').hasAttribute('inert')
    assert
      .dom(plan.form.querySelector('[data-slot="questionnaire-actions"]'))
      .hasClass('jn-questionnaire-actions')
    await a11yAudit()
  })

  test('the style sheet styles it: bordered rows, round radios, square checkboxes, a grid of actions', async function (assert) {
    await render(
      <template>
        <div style="width: 448px">
          <Questionnaire @name="q" @items={{ITEMS}} @defaultItem="signals" as |q|>
            <q.Item @name="direction" @required={{true}} as |i|>
              <i.Title>Direction</i.Title>
              <i.Choices><i.Choice @value="tool-calls">Tool calls</i.Choice></i.Choices>
            </q.Item>
            <q.Item @name="signals" @multiple={{true}} as |i|>
              <i.Title>Signals</i.Title>
              <i.Description>Select all that apply.</i.Description>
              <i.Choices>
                <i.Choice @value="progress">Progress</i.Choice>
                <i.Choice @value="decisions">Decisions</i.Choice>
              </i.Choices>
            </q.Item>
            <q.Item @name="timing" @required={{true}} as |i|>
              <i.Title>Timing</i.Title>
              <i.Choices><i.Choice @value="now">Now</i.Choice></i.Choices>
            </q.Item>
            <q.Actions>
              <q.Previous />
              <q.Skip />
              <q.Next />
              <q.Submit />
            </q.Actions>
          </Questionnaire>
        </div>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.activeItem, 'signals', '@defaultItem')
    const form = getComputedStyle(q.form)
    assert.strictEqual(form.display, 'flex')
    assert.strictEqual(form.flexDirection, 'column')
    assert.strictEqual(form.rowGap, '16px', 'gap-4')

    const item = getComputedStyle(q.item())
    assert.strictEqual(item.display, 'flex')
    assert.strictEqual(item.rowGap, '16px')
    assert.strictEqual(item.borderTopWidth, '0px', 'a fieldset without its border')
    assert.strictEqual(item.paddingTop, '0px')

    const choices = getComputedStyle(q.choice('progress').parentElement!)
    assert.strictEqual(choices.display, 'grid')
    assert.strictEqual(choices.rowGap, '8px', 'gap-2')

    const row = getComputedStyle(q.choice('progress'))
    assert.strictEqual(row.display, 'flex')
    assert.strictEqual(row.borderTopWidth, '1px')
    assert.strictEqual(row.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(px(row.minHeight), 44, 'min-h-11: a touch target')
    assert.strictEqual(row.cursor, 'pointer')
    assert.strictEqual(row.paddingInlineStart, '12px', 'px-3')

    const input = getComputedStyle(q.choiceInput('progress'))
    assert.strictEqual(input.opacity, '0', 'the native control is invisible…')
    assert.strictEqual(input.position, 'absolute', '…over the whole row')
    const indicator = q
      .choice('progress')
      .querySelector<HTMLElement>('[data-slot="questionnaire-choice-indicator"]')!
    assert.strictEqual(px(getComputedStyle(indicator).width), 16, 'size-4')
    assert.strictEqual(
      getComputedStyle(indicator).borderTopLeftRadius,
      '4px',
      'a checkbox: rounded-[4px]',
    )
    const check = indicator.querySelector('svg')!
    assert.strictEqual(getComputedStyle(check).display, 'none', 'the check shows once checked')

    await q.choose('progress')
    assert.strictEqual(getComputedStyle(check).display, 'block', 'checked: the check shows')
    assert.notStrictEqual(
      getComputedStyle(q.choice('progress')).backgroundColor,
      getComputedStyle(q.choice('decisions')).backgroundColor,
      'data-checked:bg-muted',
    )

    const actions = getComputedStyle(q.form.querySelector('[data-slot="questionnaire-actions"]')!)
    assert.strictEqual(actions.display, 'grid')
    assert.strictEqual(actions.columnGap, '8px', 'gap-2')
    const previous = q.button('previous').getBoundingClientRect()
    const next = q.button('next').getBoundingClientRect()
    assert.ok(previous.left < next.left, 'Previous at the start, Next at the end')
    assert.strictEqual(getComputedStyle(q.button('submit')).display, 'none', 'hidden: no space')
    await a11yAudit()
  })

  test('a single answer: choose, move on, go back, and submit the answers', async function (assert) {
    const submissions = new Submissions()
    await render(
      <template>
        <Questionnaire @name="q" @items={{ITEMS}} @onSubmit={{submissions.submit}} as |q|>
          <q.Progress />
          <q.Item @name="direction" @required={{true}} as |i|>
            <i.Title>Direction</i.Title>
            <i.Choices>
              <i.Choice @value="tool-calls">Tool calls</i.Choice>
              <i.Choice @value="approvals">Approvals</i.Choice>
            </i.Choices>
            <i.Error />
          </q.Item>
          <q.Item @name="signals" @multiple={{true}} as |i|>
            <i.Title>Signals</i.Title>
            <i.Choices>
              <i.Choice @value="progress">Progress</i.Choice>
              <i.Choice @value="risks">Risks</i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="timing" @required={{true}} as |i|>
            <i.Title>Timing</i.Title>
            <i.Choices><i.Choice @value="now">Now</i.Choice></i.Choices>
          </q.Item>
          <q.Actions>
            <q.Previous />
            <q.Skip />
            <q.Next />
            <q.Submit />
          </q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    await q.choose('approvals')
    assert.true(q.isChecked('approvals'))
    assert.strictEqual(q.status(), 'answered')
    assert.dom(q.choice('approvals')).hasAttribute('data-checked', '')
    assert.dom(q.choiceInput('approvals')).hasAttribute('aria-keyshortcuts', 'Enter')

    await q.choose('tool-calls')
    assert.deepEqual(q.checked(), ['tool-calls'], 'one answer: choosing another replaces it')

    await q.next()
    assert.strictEqual(q.activeItem, 'signals')
    assert.strictEqual(q.progressText, 'Question 2 of 3')
    assert.true(q.isItemFocused(), 'focus moves to the item it moved to')
    assert.true(q.canGoBack)
    assert.true(q.canSkip, 'an optional item can be skipped')

    await q.choose('progress')
    await q.choose('risks')
    assert.deepEqual(q.checked(), ['progress', 'risks'], 'several answers')
    assert.strictEqual(q.choiceInput('risks').type, 'checkbox')

    await q.previous()
    assert.strictEqual(q.activeItem, 'direction')
    assert.true(q.isChecked('tool-calls'), 'answers stay as they were')
    await q.next()
    await q.next()
    assert.strictEqual(q.activeItem, 'timing')
    assert.true(q.canSubmit)
    assert.false(q.canGoNext)
    await q.choose('now')
    await q.submit()
    assert.strictEqual(submissions.count, 1)
    assert.deepEqual(submissions.last, {
      direction: ['tool-calls'],
      signals: ['progress', 'risks'],
      timing: ['now'],
    })
    await a11yAudit()
  })

  test('an item must be answered (or skipped) before moving on: it shows its error', async function (assert) {
    const submissions = new Submissions()
    await render(
      <template>
        <Questionnaire @name="q" @items={{ITEMS}} @onSubmit={{submissions.submit}} as |q|>
          <q.Item @name="direction" @required={{true}} as |i|>
            <i.Title>Direction</i.Title>
            <i.Description>Pick one.</i.Description>
            <i.Choices>
              <i.Choice @value="tool-calls">Tool calls</i.Choice>
              <i.Choice @value="approvals">Approvals</i.Choice>
            </i.Choices>
            <i.Error />
          </q.Item>
          <q.Item @name="signals" @multiple={{true}} as |i|>
            <i.Title>Signals</i.Title>
            <i.Choices><i.Choice @value="progress">Progress</i.Choice></i.Choices>
            <i.Error />
          </q.Item>
          <q.Item @name="timing" @required={{true}} as |i|>
            <i.Title>Timing</i.Title>
            <i.Choices><i.Choice @value="now">Now</i.Choice></i.Choices>
            <i.Error @message="Pick a time." />
          </q.Item>
          <q.Actions>
            <q.Previous />
            <q.Skip />
            <q.Next />
            <q.Submit />
          </q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    await q.next()
    assert.strictEqual(q.activeItem, 'direction', 'it stays')
    assert.true(q.isInvalid())
    assert.strictEqual(q.error(), 'Choose an answer to continue.')
    const error = q.item().querySelector('[data-slot="questionnaire-error"]')!
    assert.dom(error).hasAttribute('role', 'alert').hasClass('jn-questionnaire-error')
    assert.strictEqual(
      q.describedBy(),
      'Pick one. Choose an answer to continue.',
      'the error describes the item while it is invalid',
    )
    assert.dom(q.choiceInput('tool-calls')).isFocused('focus goes to the first answer')
    assert.dom(q.choiceInput('tool-calls')).hasAttribute('aria-invalid', 'true')
    assert.dom(q.choice('tool-calls')).hasAttribute('data-invalid', '')

    await q.choose('approvals')
    assert.false(q.isInvalid(), 'answering it makes it valid')
    assert.strictEqual(q.error(), '')
    await q.next()

    await q.next()
    assert.strictEqual(q.activeItem, 'signals', 'an optional item is no different…')
    assert.strictEqual(
      q.error(),
      'Choose an answer or skip this question.',
      '…but says it can be skipped',
    )
    await q.skip()
    assert.strictEqual(q.activeItem, 'timing')
    assert.strictEqual(q.status('signals'), 'skipped')

    await q.submit()
    assert.strictEqual(submissions.count, 0, 'an invalid item stops the submit')
    assert.strictEqual(q.error(), 'Pick a time.', '@message')
    await a11yAudit()
  })

  test('submitting with an invalid item moves back to it and focuses its answer', async function (assert) {
    const submissions = new Submissions()
    const items: QuestionnaireItemDefinition[] = [
      { name: 'one', required: true },
      { name: 'two', required: true },
    ]
    class State {
      @tracked item = 'two'
      setItem = (item: string) => (this.item = item)
    }
    const state = new State()
    await render(
      <template>
        <Questionnaire
          @name="q"
          @items={{items}}
          @item={{state.item}}
          @onItemChange={{state.setItem}}
          @onSubmit={{submissions.submit}}
          as |q|
        >
          <q.Item @name="one" @required={{true}} as |i|>
            <i.Title>One</i.Title>
            <i.Choices><i.Choice @value="a">A</i.Choice></i.Choices>
            <i.Error />
          </q.Item>
          <q.Item @name="two" @required={{true}} as |i|>
            <i.Title>Two</i.Title>
            <i.Choices><i.Choice @value="b">B</i.Choice></i.Choices>
          </q.Item>
          <q.Actions><q.Previous /><q.Next /><q.Submit /></q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.activeItem, 'two', 'controlled: @item')
    await q.choose('b')
    await q.submit()
    assert.strictEqual(submissions.count, 0)
    assert.strictEqual(state.item, 'one', 'it asks the host to move to the invalid item')
    assert.strictEqual(q.activeItem, 'one')
    assert.strictEqual(q.error(), 'Choose an answer to continue.')
    assert.dom(q.choiceInput('a')).isFocused()

    state.item = 'two'
    await settled()
    assert.true(q.isItemFocused('two'), 'the host moving it focuses the new item too')
    await a11yAudit()
  })

  test('a freeform answer takes over from a fixed one, and only then submits', async function (assert) {
    const submissions = new Submissions()
    const items = [{ name: 'approach', required: true }]
    await render(
      <template>
        <Questionnaire @name="q" @items={{items}} @onSubmit={{submissions.submit}} as |q|>
          <q.Item @name="approach" @required={{true}} as |i|>
            <i.Title>Approach</i.Title>
            <i.Choices>
              <i.Choice @value="incremental">Small steps</i.Choice>
              <i.Input aria-label="Another approach" />
            </i.Choices>
            <i.Error />
          </q.Item>
          <q.Actions><q.Submit /></q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    await q.choose('incremental')
    await q.fillIn('Pair with the team')
    assert.false(q.isChecked('incremental'), 'typing an answer unchecks the fixed one')
    assert
      .dom(q.input())
      .hasAttribute('name', 'approach')
      .doesNotHaveAttribute('form')
      .hasAttribute('data-filled', '')
    assert.strictEqual(q.status(), 'answered')
    await q.submit()
    assert.deepEqual(submissions.last, { approach: ['Pair with the team'] })

    await q.choose('incremental')
    assert.dom(q.input()).doesNotHaveAttribute('name').hasAttribute('form', '')
    assert.strictEqual(q.input()!.value, 'Pair with the team', 'its text stays, out of the form')
    await q.submit()
    assert.deepEqual(submissions.last, { approach: ['incremental'] })

    await q.fillIn('')
    assert.strictEqual(q.status(), 'answered', 'clearing it leaves the fixed answer')
    await a11yAudit()
  })

  test('skipping an optional item clears it, reports its status, and on the last item submits', async function (assert) {
    const submissions = new Submissions()
    const items = [{ name: 'task', required: true }, { name: 'constraints' }]
    const statuses: QuestionnaireItemStatus[] = []
    const onStatusChange = (status: QuestionnaireItemStatus) => statuses.push(status)
    await render(
      <template>
        <Questionnaire @name="q" @items={{items}} @onSubmit={{submissions.submit}} as |q|>
          <q.Item @name="task" @required={{true}} as |i|>
            <i.Title>Task</i.Title>
            <i.Choices><i.Choice @value="fix">Fix</i.Choice></i.Choices>
          </q.Item>
          <q.Item @name="constraints" @onStatusChange={{onStatusChange}} as |i|>
            <i.Title>Constraints</i.Title>
            <i.Choices>
              <i.Choice @value="no-deps">No dependencies</i.Choice>
              <i.Input aria-label="Another constraint" />
            </i.Choices>
          </q.Item>
          <q.Actions><q.Previous /><q.Skip /><q.Next /><q.Submit /></q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    await q.choose('fix')
    await q.next()
    await q.choose('no-deps')
    assert.deepEqual(statuses, ['answered'])
    await q.skip()
    assert.deepEqual(statuses, ['answered', 'skipped'])
    assert.strictEqual(q.status(), 'skipped')
    assert.false(q.isChecked('no-deps'), 'its answer is cleared')
    assert.dom(q.choiceInput('no-deps')).doesNotHaveAttribute('name', 'and left out of the form')
    assert.strictEqual(submissions.count, 1, 'skipping the last item submits')
    assert.deepEqual(submissions.last, { task: ['fix'] }, 'without the skipped answer')

    await q.choose('no-deps')
    assert.strictEqual(q.status(), 'answered', 'answering it again undoes the skip')
    assert.deepEqual(statuses, ['answered', 'skipped', 'answered'])
    await a11yAudit()
  })

  test('the keyboard: arrows move between answers and items, Enter confirms, shortcuts pick', async function (assert) {
    const submissions = new Submissions()
    await render(
      <template>
        <Questionnaire
          @name="q"
          @items={{ITEMS}}
          @shortcuts="letters"
          @onSubmit={{submissions.submit}}
          as |q|
        >
          <q.Item @name="direction" @required={{true}} as |i|>
            <i.Title>Direction</i.Title>
            <i.Choices>
              <i.Choice @value="tool-calls">Tool calls</i.Choice>
              <i.Choice @value="approvals">Approvals</i.Choice>
              <i.Choice @value="handoffs">Handoffs</i.Choice>
              <i.Input aria-label="Another feature" />
            </i.Choices>
          </q.Item>
          <q.Item @name="signals" @multiple={{true}} as |i|>
            <i.Title>Signals</i.Title>
            <i.Choices>
              <i.Choice @value="progress">Progress</i.Choice>
              <i.Choice @value="decisions">Decisions</i.Choice>
              <i.Choice @value="risks">Risks</i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="timing" @required={{true}} as |i|>
            <i.Title>Timing</i.Title>
            <i.Choices>
              <i.Choice @value="now">Now</i.Choice>
              <i.Choice @value="later">Later</i.Choice>
            </i.Choices>
          </q.Item>
          <q.Actions><q.Previous /><q.Skip /><q.Next /><q.Submit /></q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    await focus(q.item())
    assert
      .dom(q.item())
      .hasAttribute('aria-keyshortcuts', 'Meta+Enter Control+Enter ArrowUp ArrowDown')
    assert.true(await q.press('ArrowDown'), 'ArrowDown from the item…')
    assert.dom(q.choiceInput('tool-calls')).isFocused('…goes to the first answer')
    assert.true(q.isChecked('tool-calls'), 'and a radio picks itself')

    await q.focusChoice('handoffs')
    assert.true(await q.press('ArrowDown'), 'from the last radio, ArrowDown…')
    assert.dom(q.input()).isFocused('…reaches the freeform answer')
    assert.true(await q.press('ArrowDown'), 'from an empty freeform answer, it wraps')
    assert.dom(q.choiceInput('tool-calls')).isFocused()

    assert.true(await q.press('c'), 'a shortcut letter, in any case')
    assert.true(q.isChecked('handoffs'))
    assert.dom(q.choiceInput('handoffs')).isFocused()

    assert.true(await q.press('Enter'), 'Enter on a checked answer confirms the item')
    assert.strictEqual(q.activeItem, 'signals')
    assert.true(q.isItemFocused())
    assert.strictEqual(q.item().getAttribute('aria-keyshortcuts')?.includes('ArrowLeft'), true)

    assert.true(await q.press('ArrowRight'), 'ArrowRight on an unanswered item…')
    assert.strictEqual(q.activeItem, 'signals', '…does nothing')
    assert.true(await q.press('b'))
    assert.deepEqual(q.checked(), ['decisions'])
    assert.true(await q.press('a'), 'shortcuts toggle checkboxes')
    assert.deepEqual(q.checked(), ['progress', 'decisions'])
    assert.true(await q.press('ArrowRight'), 'an answered item: ArrowRight moves on')
    assert.strictEqual(q.activeItem, 'timing')
    assert.true(await q.press('ArrowLeft'), 'ArrowLeft goes back')
    assert.strictEqual(q.activeItem, 'signals')
    await q.press('ArrowRight')

    assert.strictEqual(q.activeItem, 'timing')
    await focus(q.item())
    assert.true(await q.press('Enter', { metaKey: true }), 'Meta+Enter confirms…')
    assert.true(q.isInvalid(), '…once the item is valid')
    await q.press('b')
    assert.true(await q.press('Enter', { ctrlKey: true }), 'Control+Enter on the last…')
    assert.strictEqual(submissions.count, 1, '…submits')
    assert.deepEqual(submissions.last?.['timing'], ['later'])
    await a11yAudit()
  })

  test('right to left, ArrowRight goes back and ArrowLeft moves on', async function (assert) {
    const items = [
      { name: 'one', required: true },
      { name: 'two', required: true },
      { name: 'three', required: true },
    ]
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div dir="rtl">
            <Questionnaire @name="q" @items={{items}} @defaultItem="two" as |q|>
              {{#each items as |item|}}
                <q.Item @name={{item.name}} @required={{true}} as |i|>
                  <i.Title>{{item.name}}</i.Title>
                  <i.Choices><i.Choice @value="yes">نعم</i.Choice></i.Choices>
                </q.Item>
              {{/each}}
              <q.Actions><q.Previous /><q.Next /><q.Submit /></q.Actions>
            </Questionnaire>
          </div>
        </DirectionProvider>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    await q.choose('yes')
    await focus(q.item())
    assert.true(
      q.item().getAttribute('aria-keyshortcuts')!.includes('ArrowRight ArrowLeft'),
      'back is ArrowRight, forward ArrowLeft',
    )
    await q.press('ArrowLeft')
    assert.strictEqual(q.activeItem, 'three', 'ArrowLeft moves on')
    await q.press('ArrowRight')
    await q.press('ArrowRight')
    assert.strictEqual(q.activeItem, 'one', 'ArrowRight goes back')
    const previous = q.button('next').getBoundingClientRect()
    assert.ok(previous.width > 0)
    const row = getComputedStyle(q.choice('yes'))
    assert.strictEqual(row.textAlign, 'start')
    await a11yAudit()
  })

  test('numbers for shortcuts, and none: no keys shown', async function (assert) {
    class State {
      @tracked shortcuts: 'letters' | 'numbers' | undefined = 'numbers'
    }
    const state = new State()
    const items = [{ name: 'action', required: true, choices: [{ value: 'a' }, { value: 'b' }] }]
    await render(
      <template>
        <Questionnaire @name="q" @items={{items}} @shortcuts={{state.shortcuts}} as |q|>
          <q.Item @name="action" @required={{true}} as |i|>
            <i.Title>Action</i.Title>
            <i.Choices>
              <i.Choice @value="a">Inspect</i.Choice>
              <i.Choice @value="b">Patch</i.Choice>
            </i.Choices>
          </q.Item>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.shortcut('b'), '2')
    const key = q
      .choice('b')
      .querySelector<HTMLElement>('[data-slot="questionnaire-choice-shortcut"]')!
    assert.strictEqual(getComputedStyle(key).display, 'flex', 'inline-flex, blockified in the row')
    assert.strictEqual(px(getComputedStyle(key).width), 20, 'size-5')
    assert.dom(key).hasAttribute('aria-hidden', 'true')
    await focus(q.item())
    await q.press('2')
    assert.true(q.isChecked('b'))

    state.shortcuts = undefined
    await settled()
    assert.strictEqual(q.shortcut('b'), null)
    assert.strictEqual(getComputedStyle(key).display, 'none')
    assert.false(await q.press('1'), 'no shortcut, no key')
    await a11yAudit()
  })

  test('defaults, and a reset that puts them back', async function (assert) {
    const submissions = new Submissions()
    const resets: Event[] = []
    const onReset = (event: Event) => resets.push(event)
    const items = [
      { name: 'change', required: true },
      { name: 'verification', required: true },
      { name: 'notes' },
    ]
    await render(
      <template>
        <Questionnaire
          @name="q"
          @items={{items}}
          @defaultItem="verification"
          @onReset={{onReset}}
          @onSubmit={{submissions.submit}}
          as |q|
        >
          <q.Item @name="change" @required={{true}} as |i|>
            <i.Title>Change</i.Title>
            <i.Choices>
              <i.Choice @value="incremental" @defaultChecked={{true}}>Incremental</i.Choice>
              <i.Choice @value="cutover">Cutover</i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="verification" @multiple={{true}} @required={{true}} as |i|>
            <i.Title>Verification</i.Title>
            <i.Choices>
              <i.Choice @value="tests" @defaultChecked={{true}}>Tests</i.Choice>
              <i.Choice @value="typecheck" @defaultChecked={{true}}>Typecheck</i.Choice>
              <i.Choice @value="manual">Manual</i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="notes" as |i|>
            <i.Title>Notes</i.Title>
            <i.Input aria-label="Saved note" @defaultValue="Keep the API stable." />
          </q.Item>
          <q.Actions>
            <button type="reset">Reset changes</button>
            <q.Previous />
            <q.Next />
            <q.Submit />
          </q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.activeItem, 'verification')
    assert.deepEqual(q.checked(), ['tests', 'typecheck'], 'defaultChecked')
    assert.strictEqual(q.status(), 'answered')
    assert.deepEqual(q.checked('change'), ['incremental'])
    assert.strictEqual(q.input('notes')!.value, 'Keep the API stable.')
    assert.dom(q.input('notes')).hasAttribute('name', 'notes', 'a default answer is in the form')

    await q.choose('manual')
    await q.choose('tests')
    await q.next()
    await q.fillIn('')
    assert.strictEqual(q.status('notes'), 'unanswered')

    await click('button[type="reset"]')
    assert.strictEqual(resets.length, 1, '@onReset')
    assert.strictEqual(q.activeItem, 'verification', 'back to the item it started on')
    assert.deepEqual(q.checked(), ['tests', 'typecheck'], 'and the answers it started with')
    assert.strictEqual(q.input('notes')!.value, 'Keep the API stable.')
    assert.strictEqual(q.status('notes'), 'answered')
    await q.next()
    await q.submit()
    assert.deepEqual(submissions.last, {
      change: ['incremental'],
      verification: ['tests', 'typecheck'],
      notes: ['Keep the API stable.'],
    })
    await a11yAudit()
  })

  test('a disabled item is passed over and not submitted', async function (assert) {
    const submissions = new Submissions()
    class State {
      @tracked runtime = 'local'
      get items(): QuestionnaireItemDefinition[] {
        return [
          { name: 'runtime', required: true },
          { name: 'environment', required: true, disabled: this.runtime !== 'cloud' },
          { name: 'approval', required: true },
        ]
      }
      get isLocal() {
        return this.runtime === 'local'
      }
      get isCloud() {
        return this.runtime === 'cloud'
      }
      local = () => (this.runtime = 'local')
      cloud = () => (this.runtime = 'cloud')
    }
    const state = new State()
    await render(
      <template>
        <Questionnaire @name="q" @items={{state.items}} @onSubmit={{submissions.submit}} as |q|>
          <q.Progress />
          <q.Item @name="runtime" @required={{true}} as |i|>
            <i.Title>Runtime</i.Title>
            <i.Choices>
              <i.Choice @value="local" @checked={{state.isLocal}} @onCheckedChange={{state.local}}>
                Local
              </i.Choice>
              <i.Choice @value="cloud" @checked={{state.isCloud}} @onCheckedChange={{state.cloud}}>
                Cloud
              </i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="environment" @required={{true}} @disabled={{state.isLocal}} as |i|>
            <i.Title>Environment</i.Title>
            <i.Choices><i.Choice @value="preview">Preview</i.Choice></i.Choices>
          </q.Item>
          <q.Item @name="approval" @required={{true}} as |i|>
            <i.Title>Approval</i.Title>
            <i.Choices><i.Choice @value="writes">Before writing</i.Choice></i.Choices>
          </q.Item>
          <q.Actions><q.Previous /><q.Next /><q.Submit /></q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.true(q.isChecked('local'), 'controlled: @checked')
    assert.strictEqual(q.status(), 'answered')
    assert.strictEqual(q.progressText, 'Question 1 of 2', 'the disabled item is left out')
    assert.true(q.isDisabled('environment'))
    await q.next()
    assert.strictEqual(q.activeItem, 'approval', 'Next passes it')

    await q.previous()
    await q.choose('cloud')
    assert.strictEqual(state.runtime, 'cloud', '@onCheckedChange')
    assert.true(q.isChecked('cloud'))
    assert.strictEqual(q.progressText, 'Question 1 of 3')
    await q.next()
    assert.strictEqual(q.activeItem, 'environment')
    await q.choose('preview')
    await q.next()
    await q.choose('writes')
    await q.submit()
    assert.deepEqual(submissions.last, {
      runtime: ['cloud'],
      environment: ['preview'],
      approval: ['writes'],
    })

    await q.previous()
    await q.previous()
    await q.choose('local')
    await q.next()
    await q.submit()
    assert.deepEqual(
      submissions.last,
      { runtime: ['local'], approval: ['writes'] },
      'a disabled item is not submitted',
    )
    await a11yAudit()
  })

  test('your own validation: @invalid and @message', async function (assert) {
    class State {
      @tracked error: string | undefined = 'Public answers need enough context.'
      clear = () => (this.error = undefined)
    }
    const state = new State()
    const items = [{ name: 'detail', required: true }]
    await render(
      <template>
        <Questionnaire @name="q" @items={{items}} as |q|>
          <q.Item @name="detail" @required={{true}} @invalid={{if state.error true false}} as |i|>
            <i.Title>Detail</i.Title>
            <i.Choices>
              <i.Choice @value="summary" @defaultChecked={{true}} @onCheckedChange={{state.clear}}>
                Summary
              </i.Choice>
              <i.Choice @value="complete" @onCheckedChange={{state.clear}}>Complete</i.Choice>
            </i.Choices>
            <i.Error @message={{state.error}} />
          </q.Item>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.true(q.isInvalid(), '@invalid, though answered')
    assert.strictEqual(q.error(), 'Public answers need enough context.')
    await q.choose('complete')
    assert.false(q.isInvalid())
    assert.strictEqual(q.error(), '')
    await a11yAudit()
  })

  test('navigation state: a disabled Next, its status, and a variant', async function (assert) {
    class State {
      @tracked status: QuestionnaireItemStatus = 'unanswered'
      setStatus = (status: QuestionnaireItemStatus) => (this.status = status)
      get unanswered() {
        return this.status === 'unanswered'
      }
    }
    const state = new State()
    const items = [
      { name: 'one', required: true },
      { name: 'two', required: true },
    ]
    await render(
      <template>
        <Questionnaire @name="q" @items={{items}} as |q|>
          <q.Item @name="one" @required={{true}} @onStatusChange={{state.setStatus}} as |i|>
            <i.Title>One</i.Title>
            <i.Choices><i.Choice @value="a">A</i.Choice></i.Choices>
          </q.Item>
          <q.Item @name="two" @required={{true}} as |i|>
            <i.Title>Two</i.Title>
            <i.Choices><i.Choice @value="b">B</i.Choice></i.Choices>
          </q.Item>
          <QuestionnaireActions>
            <q.Next @disabled={{state.unanswered}} @variant="secondary" @size="sm" />
          </QuestionnaireActions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    const next = q.button('next')
    assert.dom(next).isDisabled().hasAttribute('data-status', 'unanswered')
    assert.dom(next).hasAttribute('data-variant', 'secondary').hasAttribute('data-size', 'sm')
    assert.dom(next).hasClass('jn-button-variant-secondary').hasClass('jn-button-size-sm')
    assert.dom(next).doesNotHaveAttribute('aria-keyshortcuts', 'no Enter while disabled')
    await q.choose('a')
    assert.dom(next).isNotDisabled().hasAttribute('data-status', 'answered')
    await q.next()
    assert.strictEqual(q.activeItem, 'two')
    await a11yAudit()
  })

  test('a custom progress, and the title on your own element', async function (assert) {
    const items = [{ name: 'task', required: true }, { name: 'output' }]
    const format = (current: number, total: number) => `Checkpoint ${current} of ${total}`
    await render(
      <template>
        <Questionnaire @name="q" @items={{items}} as |q|>
          <q.Progress @formatValue={{format}} as |p|>
            <span data-test-steps>{{p.current}} / {{p.total}}</span>
          </q.Progress>
          <q.Item @name="task" @required={{true}} aria-labelledby="task-title" as |i|>
            <h3 id="task-title" {{i.title}}>What should the agent work on?</h3>
            <p {{i.description}}>Choose the task.</p>
            <i.Choices><i.Choice @value="fix">Fix</i.Choice></i.Choices>
          </q.Item>
          <q.Item @name="output" as |i|>
            <i.Title>Output</i.Title>
            <i.Choices><i.Choice @value="summary">Summary</i.Choice></i.Choices>
          </q.Item>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.dom('[data-test-steps]').hasText('1 / 2')
    assert.strictEqual(q.progressText, 'Checkpoint 1 of 2', '@formatValue')
    const title = q.form.querySelector('#task-title')!
    assert
      .dom(title)
      .hasClass('jn-questionnaire-title')
      .hasAttribute('data-slot', 'questionnaire-title')
    assert.strictEqual(q.title(), 'What should the agent work on?')
    assert.strictEqual(q.describedBy(), 'Choose the task.', 'a description of your own, named')
    assert.strictEqual(
      getComputedStyle(title).fontWeight,
      '500',
      'the title rule styles your element',
    )
    await a11yAudit()
  })

  test('without @items, the rendered items are stepped through in order', async function (assert) {
    await render(
      <template>
        <Questionnaire @name="q" as |q|>
          <q.Progress />
          <q.Item @name="first" @required={{true}} as |i|>
            <i.Title>First</i.Title>
            <i.Choices><i.Choice @value="a">A</i.Choice></i.Choices>
          </q.Item>
          <q.Item @name="second" @required={{true}} as |i|>
            <i.Title>Second</i.Title>
            <i.Choices><i.Choice @value="b">B</i.Choice></i.Choices>
          </q.Item>
          <q.Actions><q.Next /><q.Submit /></q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.activeItem, 'first')
    assert.strictEqual(q.progressText, 'Question 1 of 2')
    await q.choose('a')
    await q.next()
    assert.strictEqual(q.activeItem, 'second')
    assert.true(q.canSubmit)
    await a11yAudit()
  })

  test('a controlled freeform answer: @value and @onValueChange, and the host has the last word', async function (assert) {
    const submissions = new Submissions()
    const items = [{ name: 'approach', required: true }]
    class State {
      @tracked text = 'Pair with the team'
      changes: string[] = []
      setText = (text: string) => {
        this.changes.push(text)
        this.text = text.toLowerCase()
      }
    }
    const state = new State()
    await render(
      <template>
        <Questionnaire @name="q" @items={{items}} @onSubmit={{submissions.submit}} as |q|>
          <q.Item @name="approach" @required={{true}} as |i|>
            <i.Title>Approach</i.Title>
            <i.Choices>
              <i.Choice @value="incremental">Small steps</i.Choice>
              <i.Input
                aria-label="Another approach"
                @value={{state.text}}
                @onValueChange={{state.setText}}
              />
            </i.Choices>
          </q.Item>
          <q.Actions><q.Submit /></q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.input()!.value, 'Pair with the team', 'it shows @value')
    assert
      .dom(q.input())
      .hasAttribute('name', 'approach', 'a value with text is the answer from the first render')
    assert.strictEqual(q.status(), 'answered')

    await q.choose('incremental')
    assert.dom(q.input()).doesNotHaveAttribute('name', 'a fixed answer takes over')
    assert.strictEqual(q.input()!.value, 'Pair with the team', 'its text stays')

    await q.fillIn('Ship It')
    assert.deepEqual(state.changes, ['Ship It'], '@onValueChange hears the typing')
    assert.strictEqual(q.input()!.value, 'ship it', 'it shows what the host passed back')
    assert.false(q.isChecked('incremental'), 'the new value is the answer again')
    assert.dom(q.input()).hasAttribute('name', 'approach')
    await q.submit()
    assert.deepEqual(submissions.last, { approach: ['ship it'] })

    state.text = ''
    await settled()
    assert.dom(q.input()).doesNotHaveAttribute('name', 'the host clearing it clears the answer')
    assert.strictEqual(q.status(), 'unanswered')

    state.text = 'Later'
    await settled()
    assert.strictEqual(q.input()!.value, 'Later')
    assert
      .dom(q.input())
      .hasAttribute('name', 'approach', 'the host filling it makes it the answer')
    assert.strictEqual(q.status(), 'answered')
    await a11yAudit()
  })

  test('an active item that no longer applies gives way to the first, and @onItemChange hears it', async function (assert) {
    class State {
      @tracked item = 'unknown'
      @tracked twoApplies = true
      changes: string[] = []
      setItem = (item: string) => {
        this.changes.push(item)
        this.item = item
      }
      get items(): QuestionnaireItemDefinition[] {
        return [{ name: 'one' }, { name: 'two', disabled: !this.twoApplies }]
      }
    }
    const state = new State()
    await render(
      <template>
        <Questionnaire
          @name="q"
          @items={{state.items}}
          @item={{state.item}}
          @onItemChange={{state.setItem}}
          as |q|
        >
          <q.Item @name="one" as |i|>
            <i.Title>One</i.Title>
            <i.Choices><i.Choice @value="a">A</i.Choice></i.Choices>
          </q.Item>
          <q.Item @name="two" @disabled={{if state.twoApplies false true}} as |i|>
            <i.Title>Two</i.Title>
            <i.Choices><i.Choice @value="b">B</i.Choice></i.Choices>
          </q.Item>
          <q.Actions><q.Previous /><q.Skip /><q.Next /><q.Submit /></q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.deepEqual(state.changes, ['one'], 'an unknown @item: the host is told of the first')
    assert.strictEqual(state.item, 'one')
    assert.strictEqual(q.activeItem, 'one')
    assert.true(q.isItemFocused('one'), 'and it takes focus, as upstream moves to it')

    await q.choose('a')
    await q.next()
    assert.strictEqual(state.item, 'two')
    state.twoApplies = false
    await settled()
    assert.deepEqual(state.changes, ['one', 'two', 'one'], 'the active item disabled: the first')
    assert.strictEqual(q.activeItem, 'one')
    await a11yAudit()
  })

  test('without @items or @defaultItem, it starts on the first rendered item without a word', async function (assert) {
    const changes: string[] = []
    const onItemChange = (item: string) => changes.push(item)
    await render(
      <template>
        <Questionnaire @name="q" @onItemChange={{onItemChange}} as |q|>
          <q.Item @name="first" as |i|>
            <i.Title>First</i.Title>
            <i.Choices><i.Choice @value="a">A</i.Choice></i.Choices>
          </q.Item>
          <q.Item @name="second" as |i|>
            <i.Title>Second</i.Title>
            <i.Choices><i.Choice @value="b">B</i.Choice></i.Choices>
          </q.Item>
          <q.Actions><q.Skip /><q.Next /></q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.activeItem, 'first')
    assert.deepEqual(changes, [], 'nothing to tell: it named no item of its own')
    assert.false(q.isFocused(), 'and it takes no focus')
    await q.skip()
    assert.deepEqual(changes, ['second'])
    await a11yAudit()
  })

  test('in development, it warns where @items and the rendered items part, once each', async function (assert) {
    const warnings: string[] = []
    const original = console.warn
    console.warn = (...args: unknown[]) => warnings.push(args.map(String).join(' '))
    const items: QuestionnaireItemDefinition[] = [
      { name: 'one', choices: [{ value: 'a' }, { value: 'b' }] },
      { name: 'two', choices: [{ value: 'x' }, { value: 'x' }] },
      { name: 'two' },
      { name: 'ghost' },
    ]
    try {
      await render(
        <template>
          <Questionnaire
            @name="q"
            @items={{items}}
            @defaultItem="missing"
            @shortcuts="letters"
            as |q|
          >
            <q.Item @name="one" @required={{true}} as |i|>
              <i.Title>One</i.Title>
              <i.Choices>
                <i.Choice @value="b">B</i.Choice>
                <i.Choice @value="a">A</i.Choice>
              </i.Choices>
            </q.Item>
            <q.Item @name="two" as |i|>
              <i.Title>Two</i.Title>
              <i.Choices>
                <i.Choice @value="x">X</i.Choice>
                <i.Choice @value="y">Y</i.Choice>
              </i.Choices>
            </q.Item>
            <q.Item @name="extra" as |i|>
              <i.Title>Extra</i.Title>
              <i.Choices><i.Choice @value="z">Z</i.Choice></i.Choices>
            </q.Item>
          </Questionnaire>
        </template>,
      )
      await new QuestionnaireHarness('q').choose('b')
    } finally {
      console.warn = original
    }
    const logged = (text: string) => warnings.filter(warning => warning.includes(text)).length
    for (const text of [
      'Item name "two" is defined more than once.',
      'Choice value "x" is defined more than once in item "two".',
      '@defaultItem "missing" does not identify an enabled item.',
      'Item "one" has different required values in @items and its Item.',
      'Choice order for item "one" differs between @items and the rendered Choices.',
      'Rendered choice "y" in item "two" is missing from @items and will not receive a shortcut.',
      'Item "ghost" is defined in @items but has no rendered Item.',
      'Rendered item "extra" is missing from @items and is excluded from the questionnaire.',
    ]) {
      assert.strictEqual(logged(text), 1, text)
    }
    assert.true(
      warnings.every(warning => warning.includes('[Questionnaire]')),
      'each says where it comes from',
    )
    await a11yAudit()
  })

  test('@as on every part, and the navigation buttons as modifiers on your own elements', async function (assert) {
    const items = [{ name: 'one' }, { name: 'two' }]
    await render(
      <template>
        <Questionnaire @name="q" @as="form" @items={{items}} as |q|>
          <q.Item @name="one" @as="section" role="group" aria-labelledby="as-one" as |i|>
            <i.Title @as="h3" id="as-one">One</i.Title>
            <i.Choices @as="section">
              <i.Choice @value="a" @as="label">A</i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="two" as |i|>
            <i.Title>Two</i.Title>
            <i.Choices>
              <i.Choice @value="b">B</i.Choice>
              <i.Input @as="textarea" aria-label="Another answer" />
            </i.Choices>
          </q.Item>
          <q.Actions>
            <q.Previous @as="span" />
            <button type="button" {{q.skip size="sm"}}>Not now</button>
            <button type="button" {{q.next variant="secondary" size="sm"}}>Continue</button>
            <q.Submit />
          </q.Actions>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.dom(q.form).hasTagName('form')
    assert.dom(q.item('one')).hasTagName('section').hasClass('jn-questionnaire-item')
    assert.dom(q.item('one').querySelector('[data-test-jn-part="title"]')).hasTagName('h3')
    assert.dom(q.item('one').querySelector('[data-test-jn-part="choices"]')).hasTagName('section')
    assert.dom(q.input('two')).hasTagName('textarea').hasClass('jn-questionnaire-input')

    const previous = q.button('previous')
    assert
      .dom(previous)
      .hasTagName('span')
      .hasClass('jn-button')
      .hasClass('jn-questionnaire-previous')
    assert.false(q.canGoBack, 'hidden on the first item, as a button would be')

    const next = q.button('next')
    assert
      .dom(next)
      .hasClass('jn-button')
      .hasClass('jn-button-variant-secondary')
      .hasClass('jn-button-size-sm')
      .hasClass('jn-questionnaire-next')
      .hasAttribute('data-slot', 'questionnaire-next')
      .hasAttribute('data-variant', 'secondary')
      .hasAttribute('data-size', 'sm')
      .hasAttribute('aria-keyshortcuts', 'Enter')
      .hasText('Continue')
    assert
      .dom(q.button('skip'))
      .hasClass('jn-button-variant-outline', 'Skip keeps its default variant')
      .hasClass('jn-questionnaire-skip')

    await q.choose('a')
    await click(next)
    assert.strictEqual(q.activeItem, 'two', 'the modifier moves on, as Next does')
    assert.false(q.isShown('next'), 'and hides on the last item')
    assert.true(q.canGoBack)
    await click(previous)
    assert.strictEqual(q.activeItem, 'one')
    await click(q.button('skip'))
    assert.strictEqual(q.activeItem, 'two', 'skipped')
    assert.strictEqual(q.status('one'), 'skipped')

    await q.fillIn('Something else')
    assert.strictEqual(q.status('two'), 'answered', 'the textarea is the answer')
    assert.dom(q.input('two')).hasAttribute('name', 'two')
    await a11yAudit()
  })
})
