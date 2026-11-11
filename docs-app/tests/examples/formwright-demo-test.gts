import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import { CardHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import { InputFieldHarness, form } from '@ember-joinery/formwright/test-support'
import FormwrightDemo from 'docs-app/examples/formwright-demo'

class BugReport extends FormHarness {
  @field(InputFieldHarness) declare title: InputFieldHarness
  @field(InputFieldHarness) declare description: InputFieldHarness
}

/** The card, with its form. */
class BugReportCard extends CardHarness {
  @form(BugReport, 'bug-report') declare report: BugReport
}

module('Example | formwright-demo', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a submit shows each field its errors, and a valid one toasts the values', async function (assert) {
    await render(
      <template>
        <FormwrightDemo />
        <Toaster />
      </template>,
    )
    const card = new BugReportCard()
    const { report } = card
    assert.strictEqual(report.title.label, 'Bug Title')
    assert.strictEqual(report.title.placeholder, 'Login button not working on mobile')
    assert.dom(report.description.control).hasAttribute('rows', '6')
    assert.dom(card.element).includesText('0/100 characters')

    await report.submit()
    assert.deepEqual(report.title.errors, ['Bug title must be at least 5 characters.'])
    assert.deepEqual(report.description.errors, ['Description must be at least 20 characters.'])
    await a11yAudit()

    await report.title.fillIn('Login button broken')
    await report.reset()
    assert.strictEqual(report.title.value, '', 'Reset empties it again')

    await report.title.fillIn('Login button broken')
    await report.description.fillIn('The login button does nothing on mobile.')
    assert.dom(card.element).includesText('40/100 characters', 'the count follows the text')
    assert.deepEqual(report.title.errors, [], 'errors clear as they are fixed')
    await report.submit()

    const toast = new ToasterHarness().toast()
    assert.strictEqual(toast.title, 'You submitted the following values:')
    assert.deepEqual(JSON.parse(toast.description!), {
      title: 'Login button broken',
      description: 'The login button does nothing on mobile.',
    })
    await a11yAudit()
  })
})
