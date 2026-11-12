import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { hash } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  format,
  t,
  translate,
  translator,
  type Message,
  type Translator,
} from '@ember-joinery/primitives/i18n'
import { pseudoTranslator, setupTranslator } from '@ember-joinery/test-support'

const greeting: Message = { id: 'test.greeting', message: 'Hello, {name}' }
const files: Message = { id: 'test.files', message: '{count} file', plural: '{count} files' }

const upper: Translator = {
  locale: 'fr-CA',
  t: (message, values) => format(message, values).toUpperCase(),
}

module('Integration | primitives | i18n', function (hooks) {
  setupRenderingTest(hooks)

  test('format interpolates, and leaves an unknown placeholder as written', function (assert) {
    assert.strictEqual(format(greeting, { name: 'Ada' }), 'Hello, Ada')
    assert.strictEqual(format(greeting), 'Hello, {name}')
    assert.strictEqual(format(greeting, { other: 1 }), 'Hello, {name}')
    assert.strictEqual(format(greeting, { name: 0 }), 'Hello, 0', 'String() of any value')
    assert.strictEqual(
      format({ id: 'test.own', message: '{constructor}' }, {}),
      '{constructor}',
      'only its own values',
    )
  })

  test("format picks the plural by English's plural rules", function (assert) {
    assert.strictEqual(format(files, { count: 1 }), '1 file')
    assert.strictEqual(format(files, { count: 0 }), '0 files')
    assert.strictEqual(format(files, { count: 2 }), '2 files')
    assert.strictEqual(format(files, { count: 2.5 }), '2.5 files')
    assert.strictEqual(format(files, { count: '2' }), '2 file', 'only a number counts')
    assert.strictEqual(format(files), '{count} file')
  })

  test('with no translator, translate and t give English', async function (assert) {
    assert.strictEqual(translator(this.owner), undefined)
    assert.strictEqual(translate(this.owner, greeting, { name: 'Ada' }), 'Hello, Ada')
    await render(
      <template>
        <p>{{t greeting (hash name="Ada")}}</p>
      </template>,
    )
    assert.dom('p').hasText('Hello, Ada')
    await a11yAudit()
  })

  module('with a translator', function (hooks) {
    setupTranslator(hooks, upper)

    test('translate and t use the registered translator', async function (assert) {
      assert.strictEqual(translator(this.owner), upper)
      assert.strictEqual(translate(this.owner, greeting, { name: 'Ada' }), 'HELLO, ADA')
      await render(
        <template>
          <p>{{t greeting (hash name="Ada")}}</p>
        </template>,
      )
      assert.dom('p').hasText('HELLO, ADA')
      await a11yAudit()
    })
  })

  module('the pseudo-locale', function (hooks) {
    setupTranslator(hooks, pseudoTranslator)

    test('wraps and accents the English, but not the values', async function (assert) {
      const text = translate(this.owner, greeting, { name: 'Ada' })
      assert.true(text.startsWith('⟦') && text.endsWith('⟧'), text)
      assert.notStrictEqual(text, '⟦Hello, Ada⟧', 'accented')
      assert.true(text.includes('Ada'), 'the value as given')
      assert.strictEqual(
        translate(this.owner, files, { count: 2 })
          .replace(/[^\d ]/g, '')
          .trim(),
        '2',
      )
      assert.true(translate(this.owner, files, { count: 2 }).includes('ś'), 'the plural')
      assert.strictEqual(pseudoTranslator.locale, 'en-XA')
      await render(
        <template>
          <p>{{t greeting (hash name="Ada")}}</p>
        </template>,
      )
      assert.dom('p').hasText(text)
      await a11yAudit()
    })
  })
})
