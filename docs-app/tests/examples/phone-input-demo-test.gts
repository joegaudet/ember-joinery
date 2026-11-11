import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, FieldHarness } from '@ember-joinery/test-support'
import { PhoneInputHarness } from '@ember-joinery/maskito/test-support'
import PhoneInputDemo, { Contact } from 'docs-app/examples/phone-input-demo'

/** The contact form: its three numbers, and the fields around them for their errors. */
class ContactForm {
  phone = new PhoneInputHarness('phone')
  mobile = new PhoneInputHarness('mobile')
  office = new PhoneInputHarness('office')
  save = new ButtonHarness('save')
  get fields(): FieldHarness[] {
    return FieldHarness.findAll()
  }
}

module('Example | phone-input-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('masks as you type, stores E.164, validates', async function (assert) {
    const contact = new Contact()
    await render(<template><PhoneInputDemo @contact={{contact}} /></template>)
    const contactForm = new ContactForm()

    assert.strictEqual(contactForm.phone.value, '+1 212 555-0123', 'the stored number, formatted')
    assert.strictEqual(contactForm.phone.country, 'US')
    assert.deepEqual(
      [contactForm.phone, contactForm.mobile, contactForm.office].map(field => field.picker.label),
      ['Phone country', 'UK mobile country', 'Office country'],
      'each picker is named after its number',
    )

    assert.strictEqual(contactForm.mobile.country, 'GB', 'its default country')
    await contactForm.mobile.typeText('7400123456')
    assert.strictEqual(contactForm.mobile.value, '+44 7400 123456')
    assert.strictEqual(contact.mobile, '+447400123456')

    await contactForm.office.paste('+33612')
    assert.strictEqual(contactForm.office.country, 'FR', 'a pasted number picks its country')
    await contactForm.phone.fillIn('+447400123456')
    assert.strictEqual(contactForm.phone.country, 'GB', 'and so does one autofilled')
    assert.strictEqual(contact.phone, '+447400123456')
    await contactForm.save.click()
    assert.deepEqual(
      contactForm.fields.map(field => field.error),
      ['', '', 'That number looks off'],
    )
    assert.true(contactForm.office.isInvalid)

    await contactForm.office.paste('+33 6 12 34 56 78')
    assert.strictEqual(contact.office, '+33612345678')
    assert.deepEqual(
      contactForm.fields.map(field => field.error),
      ['', '', ''],
      'checked again as it changes',
    )
    await a11yAudit()
  })
})
