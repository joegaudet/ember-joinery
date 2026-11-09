import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness, TabsHarness } from '@ember-joinery/test-support'
import TabsDemo from 'docs-app/examples/tabs-demo'

/** Each tab's card: its title, the start of its description, and what it says. */
const CARDS = {
  overview: [
    'Overview',
    'View your key metrics',
    'You have 12 active projects and 3 pending tasks.',
  ],
  analytics: ['Analytics', 'Track performance', 'Page views are up 25% compared to last month.'],
  reports: [
    'Reports',
    'Generate and download',
    'You have 5 reports ready and available to export.',
  ],
  settings: ['Settings', 'Manage your account', 'Configure notifications, security, and themes.'],
} as const

module('Example | tabs-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('each tab shows its own card', async function (assert) {
    await render(<template><TabsDemo /></template>)
    const tabs = new TabsHarness()
    assert.deepEqual(tabs.tabValues, ['overview', 'analytics', 'reports', 'settings'])
    assert.strictEqual(tabs.selected, 'overview')
    assert.strictEqual(getComputedStyle(tabs.element).width, '400px', 'w-[400px]')

    for (const [value, [title, description, content]] of Object.entries(CARDS)) {
      await tabs.select(value)
      assert.strictEqual(tabs.selected, value)
      const card = new CardHarness({ within: tabs.panel! })
      assert.strictEqual(card.title, title, `${value}: its title`)
      assert.true(card.description.startsWith(description), `${value}: its description`)
      assert.strictEqual(card.content.textContent!.trim(), content, `${value}: its content`)
      for (const other of tabs.tabValues) {
        if (other !== value) assert.false(tabs.isShown(other), `${value}: ${other} is hidden`)
      }
    }

    const content = new CardHarness({ within: tabs.panel! }).content
    assert.strictEqual(getComputedStyle(content).fontSize, '14px', 'text-sm')
    await a11yAudit()
  })

  test('the arrow keys move between the tabs, and focus selects', async function (assert) {
    await render(<template><TabsDemo /></template>)
    const tabs = new TabsHarness()
    await tabs.focus('overview')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.selected, 'analytics')
    await tabs.press('End')
    assert.strictEqual(tabs.selected, 'settings')
    assert.strictEqual(new CardHarness({ within: tabs.panel! }).title, 'Settings')
    await a11yAudit()
  })
})
