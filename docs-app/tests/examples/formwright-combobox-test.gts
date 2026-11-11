import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { ComboboxFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightCombobox from 'docs-app/examples/formwright-combobox'

class ProjectForm extends FormHarness {
  static override formName = 'project'
  @field(ComboboxFieldHarness) declare framework: ComboboxFieldHarness
}

module('Example | formwright-combobox', function (hooks) {
  setupRenderingTest(hooks)

  test('typing filters the frameworks, and choosing one fills the field', async function (assert) {
    await render(<template><FormwrightCombobox /></template>)
    const project = new ProjectForm()
    assert.strictEqual(project.framework.label, 'Framework')
    await project.framework.typeIn('n')
    assert.deepEqual(project.framework.items, ['Next.js', 'Nuxt.js'])
    await project.framework.select('Nuxt.js')
    assert.strictEqual(project.framework.value, 'Nuxt.js')
    assert.true(project.framework.isDirty)
    await a11yAudit()
  })
})
