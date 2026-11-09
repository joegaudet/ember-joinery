import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ButtonHarness, EmptyHarness, IconHarness } from '@ember-joinery/test-support'
import EmptyRtl from 'docs-app/examples/empty-rtl'

module('Example | empty-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the actions run from the right and the arrow turns', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><EmptyRtl /></DirectionProvider>
      </template>,
    )
    const empty = new EmptyHarness()
    assert.strictEqual(empty.title, 'لا توجد مشاريع بعد')
    const [create, imported, learn] = empty.findAll(ButtonHarness)
    assert.strictEqual(create!.label, 'إنشاء مشروع')
    assert.ok(
      create!.element.getBoundingClientRect().left > imported!.element.getBoundingClientRect().left,
      'the first action is on the right',
    )
    assert.strictEqual(learn!.label, 'تعرف على المزيد')
    const arrow = learn!.find(IconHarness).element
    assert.strictEqual(getComputedStyle(arrow).rotate, '270deg', 'rtl:rotate-270')
    const box = learn!.element.getBoundingClientRect()
    assert.ok(arrow.getBoundingClientRect().left < box.left + box.width / 2, 'at the inline end')
    await a11yAudit()
  })
})
