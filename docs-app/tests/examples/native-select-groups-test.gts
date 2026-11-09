import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NativeSelectHarness } from '@ember-joinery/test-support'
import NativeSelectGroups from 'docs-app/examples/native-select-groups'

module('Example | native-select-groups', function (hooks) {
  setupRenderingTest(hooks)

  test('departments in three groups', async function (assert) {
    await render(<template><NativeSelectGroups /></template>)
    const department = new NativeSelectHarness()

    assert.deepEqual(department.groups, ['Engineering', 'Sales', 'Operations'])
    assert.deepEqual(department.optionsIn('Sales'), [
      'sales-rep',
      'account-manager',
      'sales-director',
    ])
    await department.select('account-manager')
    assert.strictEqual(department.selectedText, 'Account Manager')
    await a11yAudit()
  })
})
