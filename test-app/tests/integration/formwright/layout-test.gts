import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import type { InputHarness } from '@ember-formwright/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { FieldGroup } from '@ember-joinery/ember'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { JoineryFieldLayout, setupJoineryForms } from '@ember-joinery/formwright'
import {
  CheckboxFieldHarness,
  InputFieldHarness,
  SwitchFieldHarness,
} from '@ember-joinery/formwright/test-support'

class Profile {
  @tracked name = ''
  @tracked bio = ''
  @tracked twoFactor = false
  @tracked terms = false
}

const requireName = (model: Profile): ErrorMap =>
  model.name.length >= 3 ? {} : { name: ['Name must be at least 3 characters.'] }

const requireAll = (model: Profile): ErrorMap => ({
  ...(model.name ? {} : { name: ['Enter a name.', 'Name must be at least 3 characters.'] }),
  ...(model.terms ? {} : { terms: ['Accept the terms.'] }),
})

class ProfileForm extends FormHarness {
  static override formName = 'profile'
  @field(InputFieldHarness) declare name: InputFieldHarness
  @field(InputFieldHarness) declare bio: InputFieldHarness
  @field(SwitchFieldHarness) declare twoFactor: SwitchFieldHarness
  @field(CheckboxFieldHarness) declare terms: CheckboxFieldHarness
}

const px = (value: number) => `${value}px`

module('Integration | formwright | layout', function (hooks) {
  setupRenderingTest(hooks)

  hooks.before(function () {
    setupJoineryForms()
  })

  test("a field is shadcn's Field: its label, control, hint and errors, in order", async function (assert) {
    const model = new Profile()
    await render(
      <template>
        <Form @model={{model}} @name="profile" @validator={{requireName}} as |f|>
          <FieldGroup>
            <f.Field @for="name" @label="Name" @hint="Your public name." @placeholder="Ada" />
          </FieldGroup>
          <f.Submit>Save</f.Submit>
        </Form>
      </template>,
    )
    const form = new ProfileForm()
    const fieldElement = form.name.element
    const group = fieldElement.querySelector<HTMLElement>(':scope > [data-slot="field"]')!

    assert.dom(group).hasAttribute('role', 'group')
    assert.dom(group).hasClass('jn-field')
    assert.dom(group).hasAttribute('data-orientation', 'vertical')
    assert.dom(group).doesNotHaveAttribute('data-invalid')
    assert.deepEqual(
      [...group.children].map(child => child.getAttribute('data-slot') ?? child.className),
      ['field-label', 'fw-control-area', 'field-description'],
      'the label, the control, then the hint; no error region while it is valid',
    )

    const label = group.querySelector('label')!
    assert.dom(label).hasClass('jn-field-label')
    assert.dom(label).hasAttribute('data-slot', 'field-label')
    assert.dom(label).hasAttribute('for', form.name.control.id)
    assert.dom(form.name.control).hasClass('jn-input')
    assert.dom(form.name.control).hasAttribute('data-slot', 'input')
    assert.dom(form.name.control).hasAttribute('placeholder', 'Ada')
    assert.dom('[data-slot="field-description"]').hasText('Your public name.')
    assert.strictEqual(form.name.label, 'Name')
    assert.strictEqual(form.name.hint, 'Your public name.')

    assert.strictEqual(
      getComputedStyle(fieldElement).display,
      'contents',
      "Formwright's wrapper takes no box",
    )
    assert.strictEqual(
      getComputedStyle(group.querySelector('.fw-control-area')!).display,
      'contents',
      "nor does the control's",
    )
    assert.strictEqual(getComputedStyle(group).flexDirection, 'column')
    assert.strictEqual(
      form.name.control.getBoundingClientRect().width,
      group.getBoundingClientRect().width,
      'the input is the field wide',
    )

    await form.name.fillIn('Al')
    await form.submit()

    assert.true(form.name.isInvalid)
    assert.dom(group).hasAttribute('data-invalid', 'true')
    assert.deepEqual(form.name.errors, ['Name must be at least 3 characters.'])
    const error = group.querySelector<HTMLElement>('[data-slot="field-error"]')!
    assert.dom(error).hasAttribute('role', 'alert')
    assert.dom(error).hasClass('jn-field-error')
    assert.strictEqual(group.lastElementChild, error, 'the error comes last')
    assert.dom(form.name.control).hasAttribute('aria-invalid', 'true')
    assert.true(
      form.name.control.getAttribute('aria-describedby')!.split(' ').includes(error.id),
      'the input is described by its error',
    )
    assert.strictEqual(
      getComputedStyle(error).color,
      getComputedStyle(group).color,
      'the field turns the error colour',
    )

    await form.name.fillIn('Ada')
    assert.false(form.name.isInvalid, 'the error clears as it is fixed')
    assert.dom('[data-slot="field-error"]').doesNotExist()
    await a11yAudit()
  })

  test('several errors show as a list, from the inline start', async function (assert) {
    const model = new Profile()
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div dir="rtl">
            <Form @model={{model}} @name="profile" @validator={{requireAll}} as |f|>
              <f.Field @for="name" @label="Name" />
              <f.Submit>Save</f.Submit>
            </Form>
          </div>
        </DirectionProvider>
      </template>,
    )
    const form = new ProfileForm()
    await form.submit()
    assert.deepEqual(form.name.errors, ['Enter a name.', 'Name must be at least 3 characters.'])
    const list = form.name.element.querySelector<HTMLElement>('[data-slot="field-error"] > ul')!
    const style = getComputedStyle(list)
    assert.strictEqual(style.listStyleType, 'disc')
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.marginRight, px(16), 'right to left, its margin is on the right')
    assert.strictEqual(style.marginLeft, px(0))
    await a11yAudit()
  })

  test('a switch goes after its label and hint, which share a FieldContent', async function (assert) {
    const model = new Profile()
    await render(
      <template>
        <Form @model={{model}} @name="profile" as |f|>
          <f.Field
            @for="twoFactor"
            @control="switch"
            @label="Multi-factor authentication"
            @hint="Secure your account."
          />
        </Form>
      </template>,
    )
    const form = new ProfileForm()
    const group = form.twoFactor.element.querySelector<HTMLElement>('[data-slot="field"]')!
    assert.dom(group).hasAttribute('data-orientation', 'horizontal')
    assert.deepEqual(
      [...group.children].map(child => child.getAttribute('data-slot') ?? child.className),
      ['field-content', 'fw-control-area'],
    )
    assert.dom('[data-slot="field-content"] > [data-slot="field-label"]').exists()
    assert.dom('[data-slot="field-content"] > [data-slot="field-description"]').exists()
    assert.strictEqual(getComputedStyle(group).flexDirection, 'row')
    assert.dom(form.twoFactor.control).hasAttribute('role', 'switch')

    assert.false(form.twoFactor.value)
    await form.twoFactor.toggle()
    assert.true(form.twoFactor.value)
    assert.true(model.twoFactor, 'the model has it')
    assert.true(form.twoFactor.isDirty)
    await a11yAudit()
  })

  test('a checkbox comes before its label, and its error joins the label in a FieldContent', async function (assert) {
    const model = new Profile()
    await render(
      <template>
        <Form @model={{model}} @name="profile" @validator={{requireAll}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Field @for="terms" @control="checkbox" @label="Accept the terms" />
          <f.Submit>Save</f.Submit>
        </Form>
      </template>,
    )
    const form = new ProfileForm()
    const group = form.terms.element.querySelector<HTMLElement>('[data-slot="field"]')!
    assert.deepEqual(
      [...group.children].map(child => child.getAttribute('data-slot') ?? child.className),
      ['fw-control-area', 'field-label'],
      'the checkbox, then its label',
    )
    await form.submit()
    assert.deepEqual(
      [...group.children].map(child => child.getAttribute('data-slot') ?? child.className),
      ['fw-control-area', 'field-content'],
    )
    assert.deepEqual(form.terms.errors, ['Accept the terms.'])
    assert.strictEqual(
      getComputedStyle(form.terms.control).marginTop,
      px(1),
      'beside a FieldContent, the checkbox comes down a pixel',
    )
    await form.terms.check()
    assert.true(model.terms)
    assert.false(form.terms.isInvalid)
    await a11yAudit()
  })

  test('a field or its form picks an orientation', async function (assert) {
    const model = new Profile()
    await render(
      <template>
        <Form @model={{model}} @name="profile" @layout="joinery-horizontal" as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Field
            @for="bio"
            @label="Bio"
            @layout={{component JoineryFieldLayout orientation="responsive"}}
          />
          <f.Field @for="terms" @control="checkbox" @label="Terms" @layout="joinery-vertical" />
          <f.Field
            @for="twoFactor"
            @control="switch"
            @label="Two-factor"
            @layout={{component JoineryFieldLayout labelClass="extra" controlFirst=true}}
          />
        </Form>
      </template>,
    )
    const form = new ProfileForm()
    const orientation = (harness: InputHarness | CheckboxFieldHarness | SwitchFieldHarness) =>
      harness.element.querySelector('[data-slot="field"]')!.getAttribute('data-orientation')
    assert.strictEqual(orientation(form.name), 'horizontal')
    assert.strictEqual(orientation(form.bio), 'responsive')
    assert.strictEqual(orientation(form.terms), 'vertical')
    const group = form.twoFactor.element.querySelector('[data-slot="field"]')!
    assert.dom(group.querySelector('label')).hasClass('extra', '@labelClass goes on the label')
    assert.strictEqual(
      group.firstElementChild!.className,
      'fw-control-area',
      '@controlFirst puts the switch first',
    )
    await a11yAudit()
  })
})
