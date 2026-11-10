import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, SidebarHarness } from '@ember-joinery/test-support'
import SidebarRtl from 'docs-app/examples/sidebar-rtl'

/** The avatar's initials, upstream's 4.34:1 (see the Avatar page's Accessibility notes). */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
  runOnly: ['color-contrast'],
}

module('Example | sidebar-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left: the sidebar on the right', async function (assert) {
    await render(
      <template>
        <div dir="rtl"><SidebarRtl /></div>
      </template>,
    )
    const sidebar = new SidebarHarness()
    assert.strictEqual(sidebar.side, 'right')
    assert.dom(sidebar.container).hasAttribute('dir', 'rtl')
    assert.strictEqual(getComputedStyle(sidebar.container!).right, '0px')
    assert.deepEqual(sidebar.groupLabels, ['المنصة', 'المشاريع'])
    assert.deepEqual(sidebar.menuSubButtonLabels, ['السجل', 'المميز', 'الإعدادات'])
    const playground = sidebar.menuButton('ملعب')
    assert.true(playground.isExpanded)
    const chevron = playground.element.querySelectorAll('svg')[1]!
    assert.strictEqual(
      getComputedStyle(chevron).rotate,
      '90deg',
      'open, the chevron points down, whichever way the text runs',
    )
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)

    const project = sidebar.findAll(DropdownMenuHarness)[0]!
    await project.open()
    assert.deepEqual(project.items, ['عرض المشروع', 'مشاركة المشروع', 'حذف المشروع'])
    await project.close()
    await sidebar.toggle()
    assert.strictEqual(sidebar.collapsible, 'icon')
  })
})
