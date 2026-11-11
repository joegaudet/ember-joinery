import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import {
  ButtonHarness,
  CardHarness,
  SpinnerHarness,
  ToasterHarness,
  setupToaster,
} from '@ember-joinery/test-support'
import { InputFieldHarness, form } from '@ember-joinery/formwright/test-support'
import FormwrightNextDemo from 'docs-app/examples/formwright-next-demo'

class BugReport extends FormHarness {
  @field(InputFieldHarness) declare title: InputFieldHarness
  @field(InputFieldHarness) declare description: InputFieldHarness
}

/*
 * While it saves, the description's Input Group is disabled, and its count fades with it
 * (upstream's `opacity-50`), under the 4.5:1 AA asks of text. That is text in an inactive
 * control, which WCAG's contrast minimum exempts, so the audit then runs every rule but colour
 * contrast, and colour contrast over all of it but the disabled group's count.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_DISABLED_COUNT = {
  include: [['#ember-testing-container']],
  exclude: [['[data-test-fw-field="description"] [data-slot="input-group-addon"]']],
}

/** The card, with its form and its one button, Submit. */
class BugReportCard extends CardHarness {
  @form(BugReport, 'bug-report') declare report: BugReport

  get submitButton(): ButtonHarness {
    return this.find(ButtonHarness)
  }
}

module('Example | formwright-next-demo', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('while it saves, the fields wait and the button spins; then it thanks you and empties', async function (assert) {
    await render(
      <template>
        <FormwrightNextDemo />
        <Toaster />
      </template>,
    )
    const card = new BugReportCard()
    const { report, submitButton } = card
    assert.dom('[data-test-fw-reset]', card.element).doesNotExist('no Reset, as upstream has none')
    assert.strictEqual(submitButton.text, 'Submit')

    await report.submit()
    assert.false(report.isSubmitting, 'an invalid form never starts saving')
    assert.deepEqual(report.title.errors, ['Bug title must be at least 5 characters.'])
    assert.deepEqual(report.description.errors, ['Description must be at least 20 characters.'])

    await report.title.fillIn('Login button broken')
    await report.description.fillIn('The login button does nothing on mobile.')
    const submitted = report.submit()
    await waitUntil(() => report.isSubmitting)
    assert.true(submitButton.isDisabled, 'the button waits')
    assert.dom(submitButton.element).hasAttribute('aria-busy', 'true')
    assert.strictEqual(new SpinnerHarness({ within: submitButton }).label, 'Loading')
    assert.dom(report.title.control).isDisabled('and so do the fields')
    assert.dom(report.description.control).isDisabled()
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_DISABLED_COUNT, { runOnly: ['color-contrast'] })

    await submitted
    assert.false(report.isSubmitting)
    assert.false(submitButton.isDisabled)
    assert.dom(submitButton.element).doesNotHaveAttribute('aria-busy')
    assert.strictEqual(submitButton.text, 'Submit', 'the Spinner goes')
    assert.strictEqual(report.title.value, '', 'the form empties once it is saved')
    assert.strictEqual(report.description.value, '')
    assert.deepEqual(report.title.errors, [], 'with no errors')
    assert.false(report.isDirty)
    const toast = new ToasterHarness().toast()
    assert.strictEqual(toast.title, 'Thank you for your feedback')
    assert.strictEqual(toast.description, "We'll review your report and get back to you soon.")
    await a11yAudit()
  })
})
