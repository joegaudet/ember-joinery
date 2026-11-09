import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { SelectHarness } from '@ember-joinery/test-support'
import SelectRtl from 'docs-app/examples/select-rtl'

module('Example | select-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, in Arabic, the chosen fruit fills the trigger', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><SelectRtl /></DirectionProvider>
      </template>,
    )
    const select = new SelectHarness()
    assert.strictEqual(select.valueText, 'اختر فاكهة')
    assert.dom(select.trigger).hasAttribute('dir', 'rtl')
    await select.open()
    assert.dom(select.content).hasAttribute('dir', 'rtl').hasAttribute('data-lang', 'ar')
    assert.deepEqual(select.groups, ['الفواكه', 'الخضروات'])
    const option = select.option('banana')
    const indicator = option.querySelector('.jn-select-item-indicator')!
    assert.true(
      indicator.getBoundingClientRect().left < option.getBoundingClientRect().left + 20,
      'the check mark is at the left, the end right to left',
    )
    await select.pressOption('banana')
    assert.strictEqual(select.valueText, 'موز')
    assert.strictEqual(select.value, 'banana')
    await a11yAudit()
  })
})
