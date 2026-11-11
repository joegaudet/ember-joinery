import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import {
  ButtonHarness,
  CardHarness,
  ToasterHarness,
  setupToaster,
} from '@ember-joinery/test-support'
import { InputFieldHarness, form } from '@ember-joinery/formwright/test-support'
import FormwrightArray from 'docs-app/examples/formwright-array'

class EmailsForm extends FormHarness {
  static override formName = 'contact-emails'

  /** The address at `index`. */
  email(index: number): InputFieldHarness {
    return this.field(`emails.${index}.address`, InputFieldHarness)
  }
}

class ContactEmails extends CardHarness {
  @form(EmailsForm) declare emails: EmailsForm

  get add(): ButtonHarness {
    return this.findAll(ButtonHarness).find(button => button.label === 'Add Email Address')!
  }

  /** The remove button of the address at `index`, while it has one. */
  remove(index: number): ButtonHarness | undefined {
    return this.findAll(ButtonHarness).find(b => b.label === `Remove email ${index + 1}`)
  }
}

module('Example | formwright-array', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('addresses are added, removed and checked one by one, up to five', async function (assert) {
    await render(
      <template>
        <FormwrightArray />
        <Toaster />
      </template>,
    )
    const card = new ContactEmails()
    const { emails } = card
    assert.dom(emails.email(0).control).hasAttribute('aria-label', 'Email address 1')

    await emails.email(0).fillIn('ada@example.com')
    await emails.email(1).fillIn('not an email')
    await emails.submit()
    assert.deepEqual(emails.email(1).errors, ['Enter a valid email address.'])
    assert.deepEqual(emails.email(0).errors, [])
    await a11yAudit()

    await card.remove(1)!.click()
    assert.strictEqual(card.remove(0), undefined, 'the last address has no remove button')
    for (let i = 0; i < 4; i++) await card.add.click()
    assert.true(card.add.isDisabled, 'five is the most')
    for (let i = 4; i > 0; i--) await card.remove(i)!.click()

    await emails.submit()
    assert.deepEqual(JSON.parse(new ToasterHarness().toast().description!), {
      emails: [{ address: 'ada@example.com' }],
    })

    await emails.reset()
    assert.strictEqual(emails.email(1).value, '', 'Reset brings back two empty addresses')
    await a11yAudit()
  })
})
