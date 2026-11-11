import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import { InputFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightTextarea from 'docs-app/examples/formwright-textarea'

class PersonalizationForm extends FormHarness {
  static override formName = 'personalization'
  @field(InputFieldHarness) declare about: InputFieldHarness
}

module('Example | formwright-textarea', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('"More about you" needs ten characters', async function (assert) {
    await render(
      <template>
        <FormwrightTextarea />
        <Toaster />
      </template>,
    )
    const personalization = new PersonalizationForm()
    assert.dom(personalization.about.control).hasTagName('textarea').hasClass('jn-textarea')
    assert.strictEqual(
      personalization.about.hint,
      'Tell us more about yourself. This will be used to help us personalize your experience.',
    )
    await personalization.submit()
    assert.deepEqual(personalization.about.errors, ['Please provide at least 10 characters.'])
    await a11yAudit()

    await personalization.about.fillIn("I'm a software engineer.")
    await personalization.submit()
    assert.deepEqual(JSON.parse(new ToasterHarness().toast().description!), {
      about: "I'm a software engineer.",
    })
    await a11yAudit()
  })
})
