import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { format, type Message, type Translator } from '@ember-joinery/primitives/i18n'
import { messages } from '@ember-joinery/primitives/messages'
import { SliderHarness, pseudoTranslator, setupTranslator } from '@ember-joinery/test-support'
import I18nTranslator from 'docs-app/examples/i18n-translator'

// A catalog by message id, as a .po file's po2json gives one, with English for the rest.
const es: Record<string, string> = {
  [messages.sliderMinimum.id]: 'Mínimo',
  [messages.sliderMaximum.id]: 'Máximo',
}

const spanish: Translator = {
  locale: 'es',
  t: (message: Message, values) =>
    format({ ...message, message: es[message.id] ?? message.message }, values),
}

module('Example | i18n-translator', function (hooks) {
  setupRenderingTest(hooks)

  test('without a translator, the built-in strings are English', async function (assert) {
    await render(<template><I18nTranslator /></template>)
    assert.deepEqual(new SliderHarness().labels, ['Minimum', 'Maximum'])
    await a11yAudit()
  })

  module('with a translator', function (hooks) {
    setupTranslator(hooks, spanish)

    test("they are the translator's", async function (assert) {
      await render(<template><I18nTranslator /></template>)
      assert.deepEqual(new SliderHarness().labels, ['Mínimo', 'Máximo'])
      await a11yAudit()
    })
  })

  module('with the pseudo-locale', function (hooks) {
    setupTranslator(hooks, pseudoTranslator)

    test('every one is wrapped, so a missed string shows', async function (assert) {
      await render(<template><I18nTranslator /></template>)
      assert.deepEqual(
        new SliderHarness().labels,
        [messages.sliderMinimum, messages.sliderMaximum].map(m => pseudoTranslator.t(m)),
      )
      await a11yAudit()
    })
  })
})
