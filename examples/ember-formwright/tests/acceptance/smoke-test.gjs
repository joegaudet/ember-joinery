import { module, test } from 'qunit'
import { visit } from '@ember/test-helpers'
import { setupApplicationTest } from 'ember-qunit'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import {
  CheckboxFieldHarness,
  InputFieldHarness,
  SelectFieldHarness,
  SwitchFieldHarness,
  form,
} from '@ember-joinery/formwright/test-support'

/** The project form, described once with Formwright's harness and Joinery's field harnesses. */
class ProjectForm extends FormHarness {
  static formName = 'project'
  @field(InputFieldHarness) name
  @field(SelectFieldHarness) plan
  @field(SwitchFieldHarness) notify
  @field(CheckboxFieldHarness) terms
}

/** The card around it, a Joinery harness that declares the form with `@form`. */
class ProjectCard extends CardHarness {
  static named = 'project'
  @form(ProjectForm) project
}

module('Acceptance | smoke', function (hooks) {
  setupApplicationTest(hooks)

  test("a Formwright form renders Joinery's inputs in shadcn's Field layout", async function (assert) {
    await visit('/')
    assert.dom('h1').hasText('Joinery with Formwright')

    const project = new ProjectForm()
    assert.strictEqual(project.name.label, 'Project name')
    assert.strictEqual(project.name.hint, 'Shown on your dashboard.')
    assert.dom(project.name.control).hasClass('jn-input', "Joinery's Input")
    assert.dom(project.plan.select.trigger).hasClass('jn-select-trigger', "Joinery's Select")
    assert.dom(project.notify.switch.element).hasClass('jn-switch', "Joinery's Switch")
    assert.dom(project.terms.checkbox.element).hasClass('jn-checkbox', "Joinery's Checkbox")
    assert
      .dom(project.name.element.querySelector('[data-slot="field"]'))
      .hasAttribute('role', 'group', "each field is shadcn's Field")
    assert.strictEqual(
      getComputedStyle(project.name.element).display,
      'contents',
      "joinery.css takes Formwright's wrapper out of the Field's layout",
    )
    assert.strictEqual(
      getComputedStyle(project.name.control).height,
      '32px',
      'joinery.css styles the Input',
    )
    await a11yAudit()
  })

  test("Formwright validates and saves what Joinery's controls write", async function (assert) {
    await visit('/')
    const card = new ProjectCard()
    const { project } = card
    assert.strictEqual(card.title, 'New project')

    await project.submit()
    assert.deepEqual(project.name.errors, ['Enter a project name.'])
    assert.deepEqual(project.plan.errors, ['Choose a plan.'])
    assert.deepEqual(project.terms.errors, ['Accept the terms to continue.'])
    assert.true(project.name.isInvalid)
    assert
      .dom('[data-slot="field-error"]', project.name.element)
      .hasAttribute('role', 'alert', "the errors are shadcn's FieldError")
    await a11yAudit()

    await project.name.fillIn('Atlas')
    await project.plan.choose('pro')
    await project.terms.check()
    await project.notify.toggle()
    assert.strictEqual(project.plan.value, 'pro')
    assert.strictEqual(project.plan.text, 'Pro')
    assert.false(project.notify.value)
    assert.true(project.terms.value)
    assert.false(project.name.isInvalid, 'fixing a field clears its errors')

    await project.submit()
    assert.dom('[role="status"]').hasText('Created Atlas.')
    await a11yAudit()
  })
})
