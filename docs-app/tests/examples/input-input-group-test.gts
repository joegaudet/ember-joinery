import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputGroupHarness, LabelHarness } from '@ember-joinery/test-support'
import InputInputGroup from 'docs-app/examples/input-input-group'

module('Example | input-input-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a website URL input with an https:// prefix and an info icon', async function (assert) {
    await render(<template><InputInputGroup /></template>)
    const field = new FieldHarness()
    const url = field.find(InputGroupHarness)
    assert.strictEqual(url.label, 'Website URL', 'the FieldLabel names the input')
    assert.strictEqual(field.control, url.control)
    assert.strictEqual(url.placeholder, 'example.com')
    assert.deepEqual(url.aligns, ['inline-start', 'inline-end'])
    assert.deepEqual(url.texts, ['https://'])
    assert.strictEqual(url.icons.length, 1)
    const input = url.control.getBoundingClientRect()
    assert.ok(
      url.addon('inline-start').getBoundingClientRect().right <= input.left,
      'https:// first',
    )
    assert.ok(input.right <= url.addon('inline-end').getBoundingClientRect().left, 'the icon last')

    await field.find(LabelHarness).click()
    assert.true(url.isFocused)
    await url.typeIn('shadcn.com')
    assert.strictEqual(url.value, 'shadcn.com')
    await a11yAudit()
  })
})
