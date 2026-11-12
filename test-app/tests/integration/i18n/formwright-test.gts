import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { unlocalized } from 'test-app/tests/helpers/pseudo'
import { click, render } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form } from '@ember-formwright/ember'
import { setupJoineryForms } from '@ember-joinery/formwright'
import { messages } from '@ember-joinery/formwright/messages'
import { ComboboxHarness, pseudoTranslator, setupTranslator } from '@ember-joinery/test-support'

// What a test passes in itself is written pseudo-localized, so only Joinery's own strings can
// show up unwrapped.
const text = () => document.querySelector('#ember-testing')!.textContent!
const OPTIONS = [{ value: 'a', label: '⟦a⟧' }]

class Model {
  @tracked framework: string | null = null
  @tracked dob: Date | null = null
  @tracked price: number[] = [20, 80]
  @tracked stars: number | null = null
  @tracked budget: number | null = 1200
}

module('Integration | i18n | formwright', function (hooks) {
  setupRenderingTest(hooks)

  hooks.before(function () {
    setupJoineryForms()
  })

  module('with the pseudo-locale', function (hooks) {
    setupTranslator(hooks, pseudoTranslator)

    test('every built-in string goes through the translator', async function (assert) {
      const model = new Model()
      await render(
        <template>
          <Form @model={{model}} as |f|>
            <f.Field
              @for="framework"
              @control="combobox"
              @label="⟦framework⟧"
              @options={{OPTIONS}}
            />
            <f.Field @for="dob" @control="date-picker" @label="⟦dob⟧" />
            <f.Field @for="price" @control="range" @label="⟦price⟧" @min={{0}} @max={{100}} />
            <f.Field @for="stars" @control="rating" @label="⟦stars⟧" />
          </Form>
        </template>,
      )
      assert.deepEqual(unlocalized(), [])
      await new ComboboxHarness().type('⟦zzz⟧')
      assert.true(text().includes(pseudoTranslator.t(messages.comboboxEmpty)), 'nothing found')
      assert.deepEqual(unlocalized(), [], 'with nothing found')
      await a11yAudit()
    })

    test('an explicit argument beats the translator', async function (assert) {
      const model = new Model()
      await render(
        <template>
          <Form @model={{model}} as |f|>
            <f.Field @for="dob" @control="date-picker" @label="⟦dob⟧" @placeholder="When" />
          </Form>
        </template>,
      )
      assert.dom('[data-slot="popover-trigger"], button[aria-haspopup]').includesText('When')
      await a11yAudit()
    })
  })

  module('with a translator in German', function (hooks) {
    setupTranslator(hooks, { locale: 'de', t: pseudoTranslator.t })

    test('the date picker and the currency take its locale', async function (assert) {
      const model = new Model()
      model.dob = new Date(2026, 2, 12)
      await render(
        <template>
          <Form @model={{model}} as |f|>
            <f.Field @for="dob" @control="date-picker" @label="⟦dob⟧" />
            <f.Field @for="budget" @control="currency" @label="⟦budget⟧" @currency="EUR" />
          </Form>
        </template>,
      )
      assert.true(text().includes('12. März 2026'), text())
      assert.dom('input[data-slot="input"]').hasValue(/^1\.200,00\s€$/)
      await click('button[aria-haspopup]')
      assert.dom('[role="grid"]').hasAttribute('aria-label', 'März 2026')
      await a11yAudit()
    })
  })

  test('with no translator, English', async function (assert) {
    const model = new Model()
    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="dob" @control="date-picker" @label="Date of birth" />
        </Form>
      </template>,
    )
    assert.true(text().includes('Pick a date'), text())
    await a11yAudit()
  })
})
