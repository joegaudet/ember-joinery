import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, DropdownMenuHarness } from '@ember-joinery/test-support'
import ButtonGroupRtl from 'docs-app/examples/button-group-rtl'

const style = (element: Element) => getComputedStyle(element)

module('Example | button-group-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('the mail toolbar right to left: the menu joins the group on its left', async function (assert) {
    await render(
      <template>
        <div dir="rtl"><ButtonGroupRtl /></div>
      </template>,
    )
    const toolbar = new ButtonGroupHarness()
    const [snooze, more] = toolbar.groups[2]!.buttons
    assert.strictEqual(snooze!.label, 'تأجيل')
    // Right to left, the inline end is the left.
    assert.strictEqual(style(snooze!.element).borderTopLeftRadius, '0px', 'joined to the menu')
    assert.strictEqual(style(more!.element).borderTopRightRadius, '0px')
    assert.strictEqual(style(more!.element).borderRightWidth, '0px', 'one border between them')
    assert.notStrictEqual(style(more!.element).borderTopLeftRadius, '0px', 'the end is rounded')

    const menu = new DropdownMenuHarness()
    await menu.open()
    assert.strictEqual(menu.content!.getAttribute('data-lang'), 'ar')
    assert.strictEqual(menu.items[0], 'وضع علامة كمقروء')
    const label = menu.sub('تصنيف كـ...')
    await label.openWithKeyboard()
    assert.true(label.isOpen, 'the arrow toward the inline end, ArrowLeft, opens it')
    assert.true(label.isChecked('شخصي'))
    await a11yAudit()
  })
})
