import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness, SpinnerHarness } from '@ember-joinery/test-support'
import BadgeSpinner from 'docs-app/examples/badge-spinner'

module('Example | badge-spinner', function (hooks) {
  setupRenderingTest(hooks)

  test('a spinner before one label and after the other', async function (assert) {
    await render(<template><BadgeSpinner /></template>)
    const [deleting, generating] = BadgeHarness.findAll()
    assert.deepEqual(
      [deleting!.text, deleting!.variant, generating!.text, generating!.variant],
      ['Deleting', 'destructive', 'Generating', 'secondary'],
    )
    for (const [badge, atTheStart] of [
      [deleting!, true],
      [generating!, false],
    ] as const) {
      const spinner = badge.find(SpinnerHarness)
      assert.strictEqual(spinner.label, 'Loading')
      assert.strictEqual(spinner.role, 'status')
      assert.strictEqual(getComputedStyle(spinner.element).width, '12px', "the badge's size-3")
      const box = badge.element.getBoundingClientRect()
      const left = spinner.element.getBoundingClientRect().left < box.left + box.width / 2
      assert.strictEqual(left, atTheStart, `${badge.text}: the spinner's side`)
    }
    await a11yAudit()
  })
})
