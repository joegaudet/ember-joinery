import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, SheetHarness } from '@ember-joinery/test-support'
import SheetSide from 'docs-app/examples/sheet-side'

module('Example | sheet-side', function (hooks) {
  setupRenderingTest(hooks)

  test('one sheet from each edge', async function (assert) {
    await render(<template><SheetSide /></template>)
    const sheets = SheetHarness.findAll()
    assert.deepEqual(
      sheets.map(sheet => new ButtonHarness({ within: sheet }).text),
      ['top', 'right', 'bottom', 'left'],
    )

    for (const sheet of sheets) {
      await sheet.open()
      const side = sheet.side!
      for (const animation of sheet.content!.getAnimations()) animation.finish()
      const rect = sheet.content!.getBoundingClientRect()
      if (side === 'top' || side === 'bottom') {
        assert.ok(rect.height <= window.innerHeight / 2 + 1, `${side}: at most half the screen`)
      }
      assert.strictEqual(sheet.label, 'Edit profile', `${side}: named by its title`)
      await a11yAudit()
      await sheet
        .findAll(ButtonHarness)
        .find(button => button.text === 'Cancel')!
        .click()
      assert.false(sheet.isOpen, `${side}: its Cancel closes it`)
    }
    await a11yAudit()
  })
})
