import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { click, focus, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Questionnaire } from '@ember-joinery/primitives/questionnaire'
import { QuestionnaireHarness } from '@ember-joinery/test-support'

const ITEMS = [
  { name: 'prototype', required: true, choices: [{ value: 'delegation' }, { value: 'questions' }] },
  { name: 'detail', required: false, choices: [{ value: 'focused' }, { value: 'complete' }] },
]

/** The same two items, without choices: for tests with no shortcuts, which render fewer. */
const STEPS = [{ name: 'prototype', required: true }, { name: 'detail' }]

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
    // Before 7.1, Ember gives an element rendered through `As` `ember-view`; rendering() leaves
    // that out.
    assert.dom(q.form).hasTagName('form')
    assert.deepEqual(rendering(q.form).classes, [], 'the form has no classes')
    assert.dom(q.form).doesNotHaveAttribute('data-slot', 'headless: no styled slots')
    assert.dom(q.item()).hasTagName('fieldset')
    assert.deepEqual(rendering(q.item()).classes, [], 'nor has an item')
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

  test('headless keyboard: arrows move between answers and items, Enter confirms, shortcuts pick', async function (assert) {
    let submitted = 0
    const submit = (event: SubmitEvent) => {
      event.preventDefault()
      submitted += 1
    }
    await render(
      <template>
        <Questionnaire @name="q" @items={{ITEMS}} @shortcuts="numbers" @onSubmit={{submit}} as |q|>
          <q.Item @name="prototype" @required={{true}} as |i|>
            <i.Title>Prototype</i.Title>
            <i.Choices>
              <i.Choice @value="delegation" as |c|>
                <c.Input />
                <c.Label>Delegation</c.Label>
                <c.Shortcut />
              </i.Choice>
              <i.Choice @value="questions" as |c|>
                <c.Input />
                <c.Label>Questions</c.Label>
                <c.Shortcut />
              </i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="detail" @multiple={{true}} as |i|>
            <i.Title>Detail</i.Title>
            <i.Choices>
              <i.Choice @value="focused" as |c|><c.Input /><c.Label>Focused</c.Label></i.Choice>
              <i.Choice @value="complete" as |c|><c.Input /><c.Label>Complete</c.Label></i.Choice>
            </i.Choices>
          </q.Item>
          <q.Previous />
          <q.Next />
          <q.Submit />
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.shortcut('delegation'), '1', 'numbers')
    assert
      .dom(q.choiceInput('delegation'))
      .hasAttribute('type', 'radio')
      .hasAttribute('aria-keyshortcuts', '1')
    await focus(q.item())
    assert
      .dom(q.item())
      .hasAttribute('aria-keyshortcuts', 'Meta+Enter Control+Enter ArrowUp ArrowDown')
    await q.press('ArrowDown')
    assert.dom(q.choiceInput('delegation')).isFocused('ArrowDown goes to the first answer')
    assert.true(q.isChecked('delegation'), 'a radio picks itself')
    await q.press('2')
    assert.true(q.isChecked('questions'), 'a shortcut picks its answer')
    assert.dom(q.choiceInput('questions')).isFocused()
    await q.press('Enter')
    assert.strictEqual(q.activeItem, 'detail', 'Enter on a checked answer confirms the item')
    assert.true(q.isItemFocused(), 'and the next item takes focus')

    await q.press('ArrowLeft')
    assert.strictEqual(q.activeItem, 'prototype', 'ArrowLeft goes back')
    await q.press('ArrowRight')
    assert.strictEqual(q.activeItem, 'detail', 'ArrowRight moves on from an answered item')
    assert.dom(q.choiceInput('focused')).hasAttribute('type', 'checkbox', '@multiple: checkboxes')
    await focus(q.item())
    await q.press('Enter', { ctrlKey: true })
    assert.strictEqual(submitted, 0, 'an optional item unanswered: not yet')
    assert.true(q.isInvalid(), 'it asks for an answer or a skip')
    await q.press('1')
    assert.deepEqual(q.checked(), ['focused'], 'a shortcut toggles a checkbox')
    await focus(q.item())
    await q.press('Enter', { ctrlKey: true })
    assert.strictEqual(submitted, 1, 'Control+Enter on the last item submits')
    await a11yAudit()
  })

  test('headless, controlled: @item, @checked and @value, each with its change callback', async function (assert) {
    class State {
      @tracked item = 'detail'
      @tracked focused = true
      @tracked note = 'Short'
      items: string[] = []
      checks: boolean[] = []
      setItem = (item: string) => {
        this.items.push(item)
        this.item = item
      }
      setFocused = (checked: boolean) => {
        this.checks.push(checked)
        this.focused = checked
      }
      setNote = (note: string) => (this.note = note.toUpperCase())
    }
    const state = new State()
    await render(
      <template>
        <Questionnaire
          @name="q"
          @items={{STEPS}}
          @item={{state.item}}
          @onItemChange={{state.setItem}}
          as |q|
        >
          <q.Item @name="prototype" @required={{true}} as |i|>
            <i.Title>Prototype</i.Title>
            <i.Choices>
              <i.Choice @value="delegation" as |c|><c.Input /><c.Label
                >Delegation</c.Label></i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="detail" @multiple={{true}} as |i|>
            <i.Title>Detail</i.Title>
            <i.Choices>
              <i.Choice
                @value="focused"
                @checked={{state.focused}}
                @onCheckedChange={{state.setFocused}}
                as |c|
              ><c.Input /><c.Label>Focused</c.Label></i.Choice>
              <i.Input aria-label="A note" @value={{state.note}} @onValueChange={{state.setNote}} />
            </i.Choices>
          </q.Item>
          <q.Previous />
          <q.Next />
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.activeItem, 'detail', 'it shows @item')
    assert.true(q.isChecked('focused'), 'and @checked')
    assert.strictEqual(q.input()!.value, 'Short', 'and @value')

    await q.choose('focused')
    assert.deepEqual(state.checks, [false], '@onCheckedChange hears the click')
    assert.false(q.isChecked('focused'), 'the host passed false back')
    state.focused = true
    await settled()
    assert.true(q.isChecked('focused'), 'the host checks it again')

    await q.fillIn('long')
    assert.strictEqual(q.input()!.value, 'LONG', 'the host has the last word on @value')

    await q.previous()
    assert.deepEqual(state.items, ['prototype'], '@onItemChange hears the move')
    assert.strictEqual(q.activeItem, 'prototype')
    state.item = 'detail'
    await settled()
    assert.strictEqual(q.activeItem, 'detail', 'the host moves it')
    await a11yAudit()
  })

  test('headless: a reset puts back the item and answers it started with', async function (assert) {
    const resets: Event[] = []
    const onReset = (event: Event) => resets.push(event)
    await render(
      <template>
        <Questionnaire @name="q" @items={{STEPS}} @defaultItem="detail" @onReset={{onReset}} as |q|>
          <q.Item @name="prototype" @required={{true}} as |i|>
            <i.Title>Prototype</i.Title>
            <i.Choices>
              <i.Choice @value="delegation" as |c|><c.Input /><c.Label
                >Delegation</c.Label></i.Choice>
            </i.Choices>
          </q.Item>
          <q.Item @name="detail" as |i|>
            <i.Title>Detail</i.Title>
            <i.Choices>
              <i.Choice @value="focused" @defaultChecked={{true}} as |c|>
                <c.Input /><c.Label>Focused</c.Label>
              </i.Choice>
              <i.Choice @value="complete" as |c|><c.Input /><c.Label>Complete</c.Label></i.Choice>
              <i.Input aria-label="A note" @defaultValue="Keep it short" />
            </i.Choices>
          </q.Item>
          <q.Previous />
          <q.Next />
          <q.Submit />
          <button type="reset">Start over</button>
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.strictEqual(q.activeItem, 'detail', '@defaultItem')
    assert.true(q.isChecked('focused'), '@defaultChecked')
    assert.strictEqual(q.input()!.value, 'Keep it short', '@defaultValue')

    await q.choose('complete')
    await q.fillIn('')
    await q.previous()
    await click('button[type="reset"]')
    assert.strictEqual(resets.length, 1, '@onReset')
    assert.strictEqual(q.activeItem, 'detail', 'back on the item it started on')
    assert.deepEqual(q.checked(), ['focused'], 'with the answers it started with')
    assert.strictEqual(q.input()!.value, 'Keep it short')
    await a11yAudit()
  })

  test('headless, right to left: ArrowRight goes back and ArrowLeft moves on', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div dir="rtl">
            <Questionnaire @name="q" @items={{STEPS}} @defaultItem="detail" as |q|>
              <q.Item @name="prototype" @required={{true}} as |i|>
                <i.Title>النموذج</i.Title>
                <i.Choices>
                  <i.Choice @value="delegation" @defaultChecked={{true}} as |c|>
                    <c.Input /><c.Label>التفويض</c.Label>
                  </i.Choice>
                </i.Choices>
              </q.Item>
              <q.Item @name="detail" as |i|>
                <i.Title>التفاصيل</i.Title>
                <i.Choices>
                  <i.Choice @value="focused" as |c|><c.Input /><c.Label>مركز</c.Label></i.Choice>
                </i.Choices>
              </q.Item>
              <q.Previous />
              <q.Next />
              <q.Submit />
            </Questionnaire>
          </div>
        </DirectionProvider>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    await focus(q.item())
    assert.true(
      q.item().getAttribute('aria-keyshortcuts')!.includes('ArrowRight'),
      'back is ArrowRight',
    )
    await q.press('ArrowLeft')
    assert.strictEqual(q.activeItem, 'detail', 'ArrowLeft does not go back')
    await q.press('ArrowRight')
    assert.strictEqual(q.activeItem, 'prototype', 'ArrowRight goes back')
    await q.press('ArrowLeft')
    assert.strictEqual(q.activeItem, 'detail', 'ArrowLeft moves on from an answered item')
    await a11yAudit()
  })

  test("headless: @as on the parts, and a caller's aria-describedby and aria-keyshortcuts kept", async function (assert) {
    class State {
      @tracked hint = 'hint'
    }
    const state = new State()
    await render(
      <template>
        <p id="hint">Answer for the whole team.</p>
        <p id="other">Or for yourself.</p>
        <Questionnaire @name="q" @items={{STEPS}} as |q|>
          <q.Progress @as="span" />
          <q.Item
            @name="prototype"
            @required={{true}}
            aria-describedby={{state.hint}}
            aria-keyshortcuts="Shift+Slash"
            as |i|
          >
            <i.Title>What should we prototype next?</i.Title>
            <i.Description @as="span">Choose a direction.</i.Description>
            <i.Choices @as="ul">
              <li>
                <i.Choice @value="delegation" as |c|>
                  <c.Input />
                  <c.Label @as="strong">Delegation</c.Label>
                  <c.Shortcut @as="kbd" />
                </i.Choice>
              </li>
            </i.Choices>
            <i.Error @as="span" />
          </q.Item>
          <q.Item @name="detail" as |i|>
            <i.Title>How much detail?</i.Title>
            <i.Choices>
              <i.Choice @value="focused" as |c|><c.Input /><c.Label>Focused</c.Label></i.Choice>
            </i.Choices>
          </q.Item>
          <q.Previous @as="span" />
          <q.Next />
        </Questionnaire>
      </template>,
    )
    const q = new QuestionnaireHarness('q')
    assert.dom(q.form.querySelector('[data-test-jn-part="progress"]')).hasTagName('span')
    const description = q.item().querySelector('[data-test-jn-part="description"]')!
    assert.dom(description).hasTagName('span')
    assert.dom(q.item().querySelector('[data-test-jn-part="choices"]')).hasTagName('ul')
    assert
      .dom(q.choice('delegation').querySelector('[data-test-jn-part="choice-label"]'))
      .hasTagName('strong')
    assert.dom(q.button('previous')).hasTagName('span')

    assert.strictEqual(
      q.item().getAttribute('aria-describedby'),
      `${description.id} hint`,
      "the item's description, then the caller's",
    )
    assert.true(
      q.item().getAttribute('aria-keyshortcuts')!.startsWith('Shift+Slash Meta+Enter'),
      "the caller's keys, then the item's own",
    )

    await click(q.button('next'))
    assert.true(q.isInvalid(), 'unanswered: invalid')
    const error = q.item().querySelector('[data-test-jn-part="error"]')!
    assert.dom(error).hasTagName('span')
    assert.strictEqual(
      q.item().getAttribute('aria-describedby'),
      `${description.id} ${error.id} hint`,
      'its error joins in while it is invalid',
    )

    state.hint = 'other'
    await settled()
    assert.strictEqual(
      q.item().getAttribute('aria-describedby'),
      `${description.id} ${error.id} other`,
      "the caller's changing ids are merged again",
    )
    await a11yAudit()
  })
})
