import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BreadcrumbHarness, DialogHarness, SidebarHarness } from '@ember-joinery/test-support'
import Sidebar13 from 'docs-app/examples/sidebar-13'

/** The settings dialog, as a page object: its sidebar of sections and its breadcrumb. */
class SettingsDialog extends DialogHarness {
  get sidebar(): SidebarHarness {
    return new SidebarHarness({ within: this.content! })
  }

  get breadcrumb(): BreadcrumbHarness {
    return new BreadcrumbHarness({ within: this.content! })
  }

  /** The panel beside the sidebar, which scrolls. */
  get panel(): HTMLElement {
    return this.content!.querySelector<HTMLElement>('main > .overflow-y-auto')!
  }
}

const SECTIONS = [
  'Notifications',
  'Navigation',
  'Home',
  'Appearance',
  'Messages & media',
  'Language & region',
  'Accessibility',
  'Mark as read',
  'Audio & video',
  'Connected accounts',
  'Privacy & visibility',
  'Advanced',
]

module('Example | sidebar-13', function (hooks) {
  setupRenderingTest(hooks)

  test('a settings dialog that starts open, with a sidebar of sections and a breadcrumb', async function (assert) {
    await render(<template><Sidebar13 /></template>)
    const dialog = new SettingsDialog()
    assert.true(dialog.isOpen, 'it opens at once')
    assert.true(dialog.isModal)
    assert.strictEqual(dialog.label, 'Settings', 'its visually hidden title names it')
    assert.strictEqual(dialog.descriptionText, 'Customize your settings here.')

    const sidebar = dialog.sidebar
    assert.strictEqual(sidebar.collapsible, 'none')
    assert.deepEqual(sidebar.menuButtonLabels, SECTIONS)
    assert.deepEqual(
      sidebar.menuButtons.filter(button => button.isActive).map(button => button.label),
      ['Messages & media'],
      'the section shown is the active one',
    )
    assert.strictEqual(sidebar.menuButton('Home').href, '#', 'each section is a link')

    assert.deepEqual(dialog.breadcrumb.links, ['Settings'])
    assert.strictEqual(dialog.breadcrumb.current, 'Messages & media')

    const main = dialog.content!.querySelector('main')!
    assert.strictEqual(main.offsetHeight, 480, 'h-[480px]')
    assert.strictEqual(dialog.panel.children.length, 10, 'ten placeholders')
    assert.ok(
      dialog.panel.scrollHeight > dialog.panel.clientHeight,
      'they scroll inside the panel, not the dialog',
    )
    await a11yAudit()
  })

  test('closed, the dialog opens again from its button', async function (assert) {
    await render(<template><Sidebar13 /></template>)
    const dialog = new SettingsDialog()
    await dialog.pressEscape()
    assert.false(dialog.isOpen)
    assert.strictEqual(dialog.trigger.textContent?.trim(), 'Open Dialog')
    await a11yAudit()

    await dialog.open()
    assert.true(dialog.isOpen)
    await dialog.close()
    assert.false(dialog.isOpen)
    assert.dom(dialog.trigger).isFocused('focus goes back to the button')
  })

  test('at md and up, the dialog is 700px wide at most and the sidebar shows', async function (assert) {
    await render(<template><Sidebar13 /></template>)
    const dialog = new SettingsDialog()
    const content = dialog.content!
    // The test runs at 1440px: lg's max-w-[800px] applies over md's 700px.
    assert.ok(content.offsetWidth <= 800, 'lg:max-w-[800px]')
    assert.ok(content.offsetHeight <= 500, 'md:max-h-[500px]')
    assert.strictEqual(getComputedStyle(content).paddingTop, '0px', 'p-0')
    assert.notStrictEqual(getComputedStyle(dialog.sidebar.panel!).display, 'none', 'md:flex')
    await a11yAudit()
  })
})
