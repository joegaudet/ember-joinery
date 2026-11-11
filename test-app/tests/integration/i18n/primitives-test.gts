import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { unlocalized } from 'test-app/tests/helpers/pseudo'
import { click, render, settled } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Breadcrumb } from '@ember-joinery/primitives/breadcrumb'
import { Calendar, parseIsoDate } from '@ember-joinery/primitives/calendar'
import { Command, CommandDialog, CommandLoading } from '@ember-joinery/primitives/command'
import { InputOTP } from '@ember-joinery/primitives/input-otp'
import { MessageScrollerProvider } from '@ember-joinery/primitives/message-scroller'
import { NavigationMenu } from '@ember-joinery/primitives/navigation-menu'
import { Questionnaire } from '@ember-joinery/primitives/questionnaire'
import { Rating } from '@ember-joinery/primitives/rating'
import { Slider } from '@ember-joinery/primitives/slider'
import { Toaster, toast } from '@ember-joinery/primitives/toast'
import { Zoetrope } from '@ember-joinery/primitives/zoetrope'
import { messages } from '@ember-joinery/primitives/messages'
import { pseudoTranslator, setupToaster, setupTranslator } from '@ember-joinery/test-support'

// What a test passes in itself is written pseudo-localized, so only Joinery's own strings can
// show up unwrapped.
const ITEMS = [{ name: 'q1', required: true, choices: [{ value: 'a' }] }, { name: 'q2' }]
const today = parseIsoDate('2026-03-12')
// Dates, and the names of months and days, are Intl's, not messages.
const DATES = [
  /^(Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day(, \w+ \d+, 2026)?$/,
  /^(Su|Mo|Tu|We|Th|Fr|Sa)$/,
  /^(January|February|March|April|May|June|July|August|September|October|November|December)( 2026)?$/,
]

module('Integration | i18n | primitives', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  module('with the pseudo-locale', function (hooks) {
    setupTranslator(hooks, pseudoTranslator)

    test('every built-in string goes through the translator', async function (assert) {
      await render(
        <template>
          <Breadcrumb><li>⟦1⟧</li></Breadcrumb>
          <NavigationMenu />
          <Command as |c|>
            <c.Input aria-label="⟦search⟧" />
            <c.List><c.Item>⟦1⟧</c.Item></c.List>
            <CommandLoading />
          </Command>
          <InputOTP @maxLength={{2}} as |otp|>
            {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
          </InputOTP>
          <MessageScrollerProvider as |s|>
            <s.Root>
              <s.Viewport><s.Content /></s.Viewport>
              <s.Button />
              <s.Button @direction="start" />
            </s.Root>
          </MessageScrollerProvider>
          <Rating />
          <Rating @value={{3}} @interactive={{false}} />
          {{#each (array (array 1) (array 1 2) (array 1 2 3)) as |values|}}
            <Slider @defaultValue={{values}} as |s|>
              {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
            </Slider>
          {{/each}}
          <div style="width: 100px">
            <Zoetrope aria-label="⟦cards⟧">
              <:content>
                <div style="width: 400px; flex: none">⟦1⟧</div>
              </:content>
            </Zoetrope>
          </div>
          <Calendar
            @mode="single"
            @today={{today}}
            @value={{today}}
            @captionLayout="dropdown"
            @showWeekNumber={{true}}
          />
          <Toaster @closeButton={{true}} />
        </template>,
      )
      toast('⟦saved⟧')
      await settled()
      assert.deepEqual(unlocalized(undefined, DATES), [])
      await a11yAudit()
    })

    test('the questionnaire and the command dialog', async function (assert) {
      await render(
        <template>
          <Questionnaire @items={{ITEMS}} as |q|>
            <q.Progress />
            <q.Item @name="q1" @required={{true}} as |i|>
              <i.Title>⟦1⟧</i.Title>
              <i.Choices>
                <i.Choice @value="a" as |c|><c.Input /><c.Label>⟦a⟧</c.Label></i.Choice>
              </i.Choices>
              <i.Error />
            </q.Item>
            <q.Item @name="q2" as |i|><i.Title>⟦2⟧</i.Title><i.Error /></q.Item>
            <q.Previous />
            <q.Skip />
            <q.Next />
            <q.Submit />
          </Questionnaire>
          <CommandDialog @open={{true}} />
        </template>,
      )
      await click('[data-test-jn-part="next"]')
      assert.deepEqual(unlocalized(), [], 'with the error shown, and the dialog open')
      const text = document.querySelector('#ember-testing')!.textContent!
      assert.true(text.includes(pseudoTranslator.t(messages.commandDialogTitle)), 'the dialog')
      assert.true(text.includes(pseudoTranslator.t(messages.questionnaireRequired)), 'the error')
      await a11yAudit()
    })

    test('an explicit argument beats the translator', async function (assert) {
      await render(
        <template>
          <Breadcrumb @label="Mine"><li>⟦1⟧</li></Breadcrumb>
        </template>,
      )
      assert.dom('nav').hasAttribute('aria-label', 'Mine')
      await a11yAudit()
    })
  })

  module('with a translator in German', function (hooks) {
    setupTranslator(hooks, { locale: 'de', t: pseudoTranslator.t })

    test('the calendar takes its locale, unless @locale is given', async function (assert) {
      await render(<template><Calendar @today={{today}} /></template>)
      assert.dom('[role="grid"]').hasAttribute('aria-label', 'März 2026')
      await a11yAudit()
      await render(<template><Calendar @today={{today}} @locale="fr" /></template>)
      assert.dom('[role="grid"]').hasAttribute('aria-label', 'mars 2026')
    })
  })

  test('with no translator, English', async function (assert) {
    await render(
      <template>
        <Breadcrumb><li>Home</li></Breadcrumb>
      </template>,
    )
    assert.dom('nav').hasAttribute('aria-label', 'Breadcrumb')
    await a11yAudit()
  })
})
