import { module, test } from 'qunit'
import { setupApplicationTest } from 'test-app/tests/helpers'
import { currentURL, visit } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  BreadcrumbHarness,
  CardHarness,
  DialogHarness,
  SidebarHarness,
} from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import { DataTableHarness } from '@ember-joinery/data-table/test-support'

/**
 * Upstream draws the avatar's initials `--muted-foreground` on `--muted`, under the 4.5:1 WCAG
 * AA asks of their text (the Avatar page's Accessibility notes say how an app can darken it).
 * So the audit runs every rule but colour contrast over the whole demo, then colour contrast
 * over all of it but the initials.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]']],
  runOnly: ['color-contrast'],
}

/** The settings dialog the demo opens at /settings, as a page object. */
class SettingsDialog extends DialogHarness {
  static override named = 'settings'

  get sections(): SidebarHarness {
    return new SidebarHarness({ within: this.content! })
  }

  get breadcrumb(): BreadcrumbHarness {
    return new BreadcrumbHarness({ within: this.content! })
  }

  /** The section the dialog shows: its active link, and the breadcrumb's page. */
  get section(): string | undefined {
    return this.sections.menuButtons.find(button => button.isActive)?.label
  }
}

module('Application | the live demo', function (hooks) {
  setupApplicationTest(hooks)

  test('the dashboard: its sidebar, section cards, chart and table', async function (assert) {
    await visit('/')
    const sidebar = new SidebarHarness('demo')
    assert.strictEqual(sidebar.variant, 'inset')
    assert.strictEqual(sidebar.state, 'expanded')
    assert.deepEqual(sidebar.groupLabels, ['Documents'])
    assert.strictEqual(sidebar.menuButton('Settings').href, '/settings', 'Settings is a route')

    assert.deepEqual(
      CardHarness.findAll()
        .slice(0, 4)
        .map(card => card.description),
      ['Total Revenue', 'New Customers', 'Active Accounts', 'Growth Rate'],
    )
    assert.strictEqual(new ChartHarness().series.length, 2)
    const table = new DataTableHarness()
    assert.strictEqual(table.rowCount, 10)
    assert.strictEqual(table.column('header')[0], 'Cover page')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)
  })

  test("Tailwind's utilities lay the demo out, and only the demo", async function (assert) {
    await visit('/')
    const sidebar = new SidebarHarness('demo')
    const header = sidebar.inset!.querySelector('header')!
    assert.strictEqual(getComputedStyle(header).display, 'flex', 'in the demo, `flex` lays out')
    assert.strictEqual(getComputedStyle(sidebar.container!).width, '288px', '--spacing is set')

    const outside = document.createElement('div')
    outside.className = 'flex'
    document.querySelector('#ember-testing')!.append(outside)
    try {
      assert.strictEqual(getComputedStyle(outside).display, 'block', 'outside it, nothing')
    } finally {
      outside.remove()
    }
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)
  })

  test("the sidebar's Settings opens the settings dialog, a section at a time", async function (assert) {
    await visit('/')
    await new SidebarHarness('demo').menuButton('Settings').click()
    assert.strictEqual(currentURL(), '/settings')
    const dialog = new SettingsDialog()
    assert.true(dialog.isOpen)
    assert.strictEqual(dialog.label, 'Settings')
    assert.strictEqual(dialog.section, 'Messages & media', "upstream's, until one is picked")
    assert.strictEqual(dialog.breadcrumb.current, 'Messages & media')

    await dialog.sections.menuButton('Appearance').click()
    assert.strictEqual(currentURL(), '/settings?section=Appearance')
    assert.strictEqual(dialog.section, 'Appearance')
    assert.strictEqual(dialog.breadcrumb.current, 'Appearance')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)

    await dialog.pressEscape()
    assert.strictEqual(currentURL(), '/', 'closing it goes back to the dashboard')
    assert.false(dialog.exists)
  })

  test('a section has a URL of its own', async function (assert) {
    await visit('/settings?section=Advanced')
    const dialog = new SettingsDialog()
    assert.true(dialog.isOpen)
    assert.strictEqual(dialog.section, 'Advanced')
    assert.strictEqual(dialog.breadcrumb.current, 'Advanced')
    await dialog.breadcrumb.clickLink('Settings')
    assert.strictEqual(currentURL(), '/settings', "the breadcrumb's Settings")
    assert.strictEqual(dialog.section, 'Messages & media')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_INITIALS)
  })
})
