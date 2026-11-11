import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  DropdownMenuHarness,
  SidebarHarness,
  child,
  type SidebarMenuButtonHarness,
} from '@ember-joinery/test-support'
import SidebarDemo from 'docs-app/examples/sidebar-demo'

/**
 * Upstream draws the avatar's initials `--muted-foreground` on `--muted`, 4.34:1 in the default
 * theme, under the 4.5:1 WCAG AA asks of their 14px text (the Avatar page's Accessibility notes
 * say how an app can darken it). So the audit runs every rule but colour contrast over the
 * whole example, then colour contrast over all of it but the initials.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
  runOnly: ['color-contrast'],
}

/** The demo's sidebar, as a page object: its team switcher and its user's menu. */
class AppSidebar extends SidebarHarness {
  @child(DropdownMenuHarness, { index: 0 }) declare teams: DropdownMenuHarness
  @child(DropdownMenuHarness, { index: 4 }) declare account: DropdownMenuHarness

  get playground(): SidebarMenuButtonHarness {
    return this.menuButton('Playground')
  }
}

module('Example | sidebar-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a sidebar that collapses to icons, with a team switcher, collapsible navigation and a user menu', async function (assert) {
    await render(<template><SidebarDemo /></template>)
    const sidebar = new AppSidebar()
    assert.strictEqual(sidebar.state, 'expanded')
    assert.deepEqual(sidebar.groupLabels, ['Platform', 'Projects'])
    assert.true(sidebar.playground.isExpanded, 'Playground starts open')
    assert.deepEqual(sidebar.menuSubButtonLabels, ['History', 'Starred', 'Settings'])
    await sidebar.menuButton('Models').click()
    assert.deepEqual(sidebar.menuSubButtonLabels, [
      'History',
      'Starred',
      'Settings',
      'Genesis',
      'Explorer',
      'Quantum',
    ])
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)

    await sidebar.teams.open()
    assert.strictEqual(sidebar.teams.side, 'right')
    assert.deepEqual(sidebar.teams.labels, ['Teams'])
    assert.deepEqual(sidebar.teams.items, ['Acme Inc', 'Acme Corp.', 'Evil Corp.', 'Add team'])
    await sidebar.teams.select('Evil Corp.')
    assert.strictEqual(sidebar.menuButtons[0]!.text, 'Evil Corp. Free', 'it switches teams')

    await sidebar.account.open()
    assert.strictEqual(sidebar.account.align, 'end')
    assert.deepEqual(sidebar.account.items, [
      'Upgrade to Pro',
      'Account',
      'Billing',
      'Notifications',
      'Log out',
    ])
    await sidebar.account.close()
  })

  test('collapsed, it shows its icons, and tooltips name them', async function (assert) {
    await render(<template><SidebarDemo /></template>)
    const sidebar = new AppSidebar()
    await sidebar.toggle()
    // The sidebar and the page header ease to their new sizes: end that, to measure them.
    for (const animation of document.getAnimations()) animation.finish()
    assert.strictEqual(sidebar.state, 'collapsed')
    assert.strictEqual(sidebar.collapsible, 'icon')
    const projects = sidebar.element.querySelectorAll('[data-slot="sidebar-group"]')[1]!
    assert.strictEqual(getComputedStyle(projects).display, 'none', 'the projects hide')
    const header = sidebar.inset!.querySelector('header')!
    assert.strictEqual(getComputedStyle(header).height, '48px', 'the page header shrinks to h-12')

    await sidebar.playground.hover()
    assert.true(sidebar.playground.isTooltipShown)
    assert.strictEqual(sidebar.playground.tooltip, 'Playground')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)
    await sidebar.playground.unhover()

    await sidebar.toggleWithRail()
    assert.strictEqual(sidebar.state, 'expanded', 'the rail opens it again')
  })
})
