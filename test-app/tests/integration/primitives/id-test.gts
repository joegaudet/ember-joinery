import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { idFor, uniqueId } from '@ember-joinery/primitives/id'

module('Integration | primitives | id', function (hooks) {
  setupRenderingTest(hooks)

  test('uniqueId gives a new id each call, with an optional prefix', function (assert) {
    const a = uniqueId()
    const b = uniqueId()
    assert.notStrictEqual(a, b)
    assert.true(/^jn-\d+$/.test(a), `${a} is a jn- id`)
    assert.true(/^menu-\d+$/.test(uniqueId('menu')), 'the prefix is used')
  })

  test('idFor is stable for an object, and derives part ids from it', function (assert) {
    const dialog = {}
    const other = {}
    const root = idFor(dialog)
    assert.strictEqual(idFor(dialog), root, 'the same object always gets the same id')
    assert.notStrictEqual(idFor(other), root, 'another object gets another')
    assert.strictEqual(idFor(dialog, 'content'), `${root}-content`)
    assert.strictEqual(idFor(dialog, 'title'), `${root}-title`)
  })

  test('uniqueId works as a helper, to tie a label to its input', async function (assert) {
    await render(
      <template>
        {{#let (uniqueId) as |id|}}
          <label for={{id}}>Email</label>
          <input id={{id}} type="email" />
        {{/let}}
      </template>,
    )
    const field = find('input')!
    assert.true(field.id.startsWith('jn-'))
    assert.dom('label').hasAttribute('for', field.id)
    await a11yAudit()
  })
})
