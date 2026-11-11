import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import { SelectFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightSelect from 'docs-app/examples/formwright-select'

class LanguageForm extends FormHarness {
  static override formName = 'language-preferences'
  @field(SelectFieldHarness) declare language: SelectFieldHarness
}

module('Example | formwright-select', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a language must be chosen, and not Auto', async function (assert) {
    await render(
      <template>
        <FormwrightSelect />
        <Toaster />
      </template>,
    )
    const preferences = new LanguageForm()
    const field = preferences.language.element.querySelector('[data-slot="field"]')!
    assert.dom(field).hasAttribute('data-orientation', 'responsive')
    assert.strictEqual(preferences.language.text, 'Select')

    await preferences.submit()
    assert.deepEqual(preferences.language.errors, ['Please select your spoken language.'])
    await a11yAudit()

    await preferences.language.open()
    assert.deepEqual(preferences.language.options, [
      'auto',
      'en',
      'es',
      'fr',
      'de',
      'it',
      'zh',
      'ja',
    ])
    await preferences.language.select.pressOption('auto')
    assert.deepEqual(preferences.language.errors, [
      'Auto-detection is not allowed. Please select a specific language.',
    ])

    await preferences.language.choose('fr')
    assert.strictEqual(preferences.language.text, 'French')
    await preferences.submit()
    assert.deepEqual(JSON.parse(new ToasterHarness().toast().description!), { language: 'fr' })
    await a11yAudit()
  })
})
