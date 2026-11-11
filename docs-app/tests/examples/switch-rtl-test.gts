import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { FieldHarness, SwitchHarness } from '@ember-joinery/test-support'
import SwitchRtl from 'docs-app/examples/switch-rtl'

module('Example | switch-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the text on the right and the switch on the left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><SwitchRtl /></DirectionProvider>
      </template>,
    )
    const field = new FieldHarness()
    const share = field.find(SwitchHarness)

    assert.strictEqual(share.label, 'المشاركة عبر الأجهزة')
    assert.true(
      share.element.getBoundingClientRect().right < field.content!.getBoundingClientRect().left,
      'the switch comes last, on the left',
    )
    await share.toggle()
    assert.true(share.isChecked)
    await a11yAudit()
  })
})
