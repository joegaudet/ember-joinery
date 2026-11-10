import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  ButtonHarness,
  FieldHarness,
  InputGroupHarness,
  SpinnerHarness,
} from '@ember-joinery/test-support'
import InputGroupRtl from 'docs-app/examples/input-group-rtl'

module('Example | input-group-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, each group runs right to left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><InputGroupRtl /></DirectionProvider>
      </template>,
    )
    const [search, searching, saving, comment] = InputGroupHarness.findAll()

    assert.strictEqual(search!.label, 'بحث...', 'its placeholder names it')
    assert.deepEqual(search!.aligns, ['inline-start', 'inline-end'], 'an addon at each side')
    assert.strictEqual(search!.addonText('inline-end'), '١٢ نتيجة')
    const start = search!.addon('inline-start').getBoundingClientRect()
    const end = search!.addon('inline-end').getBoundingClientRect()
    const input = search!.control.getBoundingClientRect()
    assert.ok(start.left >= input.right, 'the search icon is on the right')
    assert.ok(end.right <= input.left, 'the results are on the left')
    assert.strictEqual(getComputedStyle(search!.element).maxWidth, '320px', 'max-w-xs')

    assert.strictEqual(searching!.placeholder, 'جاري البحث...')
    assert.true(searching!.find(SpinnerHarness).exists, 'a spinner while it searches')
    assert.deepEqual(saving!.texts, ['جاري الحفظ...'])
    assert.true(saving!.find(SpinnerHarness).exists, 'and one while it saves')

    const field = new FieldHarness()
    assert.strictEqual(comment!.label, 'منطقة النص', 'the FieldLabel names the textarea')
    assert.strictEqual(field.description, 'تذييل موضع أسفل منطقة النص.')
    assert.deepEqual(comment!.texts, ['٠/٢٨٠'])
    const post = comment!.find(ButtonHarness)
    assert.strictEqual(post.label, 'نشر')
    const count = comment!.addon('block-end').querySelector('[data-test-jn-part="text"]')!
    assert.ok(
      post.element.getBoundingClientRect().right < count.getBoundingClientRect().left,
      'the counter at the right, Post at the left',
    )
    // Upstream's ml-auto is a physical margin, so right to left it takes the room on Post's
    // left, and Post stays beside the counter, as on ui.shadcn.com.
    await a11yAudit()
  })
})
