import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { array } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import { CurrencyHarness, FormHarness, field } from '@ember-formwright/test-support'
import { FieldGroup, InputGroup } from '@ember-joinery/ember'
import { JoineryFieldLayout, setupJoineryForms } from '@ember-joinery/formwright'
import {
  CheckboxGroupFieldHarness,
  ComboboxFieldHarness,
  DatePickerFieldHarness,
  InputFieldHarness,
  InputOTPFieldHarness,
  NativeSelectFieldHarness,
  NumberFieldHarness,
  RadioGroupFieldHarness,
  SelectFieldHarness,
  SliderFieldHarness,
  ToggleFieldHarness,
  ToggleGroupFieldHarness,
} from '@ember-joinery/formwright/test-support'

const languages = [
  { value: 'en', label: 'English' },
  { value: 'fr', label: 'French' },
  { value: 'de', label: 'German' },
]

const plans = [
  { id: 'starter', title: 'Starter', description: 'For everyday use.' },
  { id: 'pro', title: 'Pro', description: 'For advanced use.' },
]

const tasks = [
  { id: 'push', label: 'Push notifications' },
  { id: 'email', label: 'Email notifications' },
  { id: 'sms', label: 'Text messages', disabled: true },
]

const sizes = ['s', 'm', 'l']

class Settings {
  @tracked language: string | null = null
  @tracked nativeLanguage: unknown = null
  @tracked plan: string | null = null
  @tracked tasks: string[] = []
  @tracked size: string | null = null
  @tracked marks: string[] = []
  @tracked bold = false
  @tracked volume = 50
  @tracked price: number[] = [20, 80]
  @tracked code = ''
  @tracked framework: string | null = null
  @tracked dob: Date | null = null
  @tracked seats: number | null = 2
  @tracked budget: number | null = 1200
  @tracked bio = ''
}

class SettingsForm extends FormHarness {
  static override formName = 'settings'
  @field(SelectFieldHarness) declare language: SelectFieldHarness
  @field(NativeSelectFieldHarness) declare nativeLanguage: NativeSelectFieldHarness
  @field(RadioGroupFieldHarness) declare plan: RadioGroupFieldHarness
  @field(CheckboxGroupFieldHarness) declare tasks: CheckboxGroupFieldHarness
  @field(ToggleGroupFieldHarness) declare size: ToggleGroupFieldHarness
  @field(ToggleGroupFieldHarness) declare marks: ToggleGroupFieldHarness
  @field(ToggleFieldHarness) declare bold: ToggleFieldHarness
  @field(SliderFieldHarness) declare volume: SliderFieldHarness
  @field(SliderFieldHarness) declare price: SliderFieldHarness
  @field(InputOTPFieldHarness) declare code: InputOTPFieldHarness
  @field(ComboboxFieldHarness) declare framework: ComboboxFieldHarness
  @field(DatePickerFieldHarness) declare dob: DatePickerFieldHarness
  @field(NumberFieldHarness) declare seats: NumberFieldHarness
  @field(CurrencyHarness) declare budget: CurrencyHarness
  @field(InputFieldHarness) declare bio: InputFieldHarness
}

const requireLanguage = (model: Settings): ErrorMap =>
  model.language ? {} : { language: ['Choose a language.'] }

const requireTasks = (model: Settings): ErrorMap =>
  model.tasks.length ? {} : { tasks: ['Choose at least one.'] }

module('Integration | formwright | controls', function (hooks) {
  setupRenderingTest(hooks)

  hooks.before(function () {
    setupJoineryForms()
  })

  test("select is Joinery's Select, its trigger the field wide and named by the label", async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" @validator={{requireLanguage}} as |f|>
          <FieldGroup>
            <f.Field
              @for="language"
              @control="select"
              @label="Spoken language"
              @placeholder="Select"
              @options={{languages}}
              @storeKey={{true}}
            />
          </FieldGroup>
          <f.Submit>Save</f.Submit>
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const trigger = form.language.control
    assert.dom(trigger).hasAttribute('role', 'combobox')
    assert.dom(trigger).hasClass('jn-select-trigger')
    assert.strictEqual(form.language.text, 'Select')
    assert.strictEqual(form.language.value, null)
    assert.strictEqual(
      trigger.getBoundingClientRect().width,
      form.language.element.querySelector('[data-slot="field"]')!.getBoundingClientRect().width,
      'a vertical field stretches the trigger, as upstream does',
    )

    await form.submit()
    assert.deepEqual(form.language.errors, ['Choose a language.'])
    assert.dom(trigger).hasAttribute('aria-invalid', 'true')

    await form.language.open()
    assert.deepEqual(form.language.options, ['en', 'fr', 'de'])
    await form.language.select.select('fr')
    assert.strictEqual(model.language, 'fr', 'it stores the key')
    assert.strictEqual(form.language.value, 'fr')
    assert.strictEqual(form.language.text, 'French')
    assert.false(form.language.isInvalid)
    await a11yAudit()
  })

  test('a select writes its own items with a block', async function (assert) {
    const model = new Settings()
    model.language = 'auto'
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field
            @for="language"
            @control="select"
            @label="Spoken language"
            @options={{languages}}
            @storeKey={{true}}
            as |field|
          >
            <field.Control @position="popper" as |s|>
              <s.Item @value="auto">Auto</s.Item>
              <s.Separator />
              {{#each languages as |language|}}
                <s.Item @value={{language.value}}>{{language.label}}</s.Item>
              {{/each}}
            </field.Control>
          </f.Field>
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.strictEqual(form.language.text, 'Auto', 'a key from the block shows its item')
    await form.language.choose('de')
    assert.strictEqual(model.language, 'de')
    await form.language.choose('auto')
    assert.strictEqual(model.language, 'auto', 'an item with no option behind it stores its key')
    await a11yAudit()
  })

  test("native-select is Joinery's Native Select, with Formwright's harness", async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field
            @for="nativeLanguage"
            @control="native-select"
            @label="Language"
            @placeholder="Choose one"
            @options={{languages}}
            @optionKey="value"
          />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.dom(form.nativeLanguage.control).hasClass('jn-native-select')
    assert.deepEqual(form.nativeLanguage.options, ['en', 'fr', 'de'])
    await form.nativeLanguage.select('de')
    assert.deepEqual(model.nativeLanguage, languages[2], 'it stores the option')
    assert.strictEqual(form.nativeLanguage.value, 'de')
    await a11yAudit()
  })

  test('radio is a Radio Group in a FieldSet; the arrow keys move between choices', async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field
            @for="plan"
            @control="radio"
            @label="Plan"
            @hint="Upgrade any time."
            @options={{plans}}
            @optionLabel="title"
            @storeKey={{true}}
          />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const set = form.plan.element.querySelector<HTMLElement>('fieldset')!
    assert.dom(set).hasAttribute('data-slot', 'field-set')
    assert.dom(set.firstElementChild).hasAttribute('data-slot', 'field-legend')
    assert.dom(set.firstElementChild).hasAttribute('data-variant', 'legend')
    assert.dom(set.firstElementChild).hasText('Plan')
    assert.dom('[role="radiogroup"]').exists()
    assert.strictEqual(getComputedStyle(set).rowGap, '12px', 'a set of radios sits closer, gap-3')
    assert.deepEqual(form.plan.options, ['starter', 'pro'])
    assert.dom('[data-slot="field-description"]', set).exists({ count: 3 })

    await form.plan.select('pro')
    assert.strictEqual(model.plan, 'pro')
    assert.strictEqual(form.plan.value, 'pro')
    await form.plan.radioGroup.press('ArrowUp')
    assert.strictEqual(model.plan, 'starter', 'the arrow keys choose too')
    await a11yAudit()
  })

  test('a radio group shows its choices as cards with @variant="card"', async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field
            @for="plan"
            @control="radio"
            @label="Plan"
            @options={{plans}}
            @optionLabel="title"
            @storeKey={{true}}
            @layout={{component JoineryFieldLayout legend="label"}}
            as |field|
          >
            <field.Control @variant="card" />
          </f.Field>
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.dom('legend').hasAttribute('data-variant', 'label')
    assert.dom('label[data-slot="field-label"] > [data-slot="field"]').exists({ count: 2 })
    assert.dom('[data-slot="field-title"]').doesNotExist()
    const pro = form.element.querySelector<HTMLElement>('[data-test-fw-option="pro"]')!
    assert.dom(pro).hasAttribute('aria-labelledby')
    await form.plan.select('pro')
    assert.strictEqual(model.plan, 'pro')
    const card = pro.closest('label')!
    assert.notStrictEqual(
      getComputedStyle(card).borderTopWidth,
      '0px',
      'a choice card has a border',
    )
    // A chosen card's description is upstream's muted text on the card's tint, under AA's
    // 4.5:1 (see the Forms page's Accessibility notes): every rule but colour contrast, then
    // colour contrast on all but it.
    await a11yAudit({ rules: { 'color-contrast': { enabled: false } } })
    await a11yAudit(
      {
        include: [['#ember-testing-container']],
        exclude: [
          ['[data-slot="field-label"]:has([aria-checked="true"]) [data-slot="field-description"]'],
        ],
      },
      { runOnly: ['color-contrast'] },
    )
  })

  test('checkbox-group is Checkboxes in a FieldGroup, and @max caps them', async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" @validator={{requireTasks}} as |f|>
          <f.Field
            @for="tasks"
            @control="checkbox-group"
            @label="Tasks"
            @options={{tasks}}
            @storeKey={{true}}
            @max={{1}}
          />
          <f.Submit>Save</f.Submit>
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.dom('[data-slot="checkbox-group"]').hasClass('jn-field-group')
    const set = form.tasks.element.querySelector<HTMLElement>('fieldset')!
    assert.strictEqual(getComputedStyle(set).rowGap, '12px')
    const label = form.element.querySelector<HTMLElement>('[data-slot="checkbox-group"] label')!
    assert.strictEqual(getComputedStyle(label).fontWeight, '400', "a choice's label is font-normal")

    await form.submit()
    assert.deepEqual(form.tasks.errors, ['Choose at least one.'])
    assert
      .dom('[data-slot="checkbox-group"] [data-slot="field"][data-invalid="true"]')
      .exists({ count: 3 })

    await form.tasks.toggle('email')
    assert.deepEqual(model.tasks, ['email'])
    assert.deepEqual(form.tasks.value, ['email'])
    assert.true(form.tasks.isOptionDisabled('push'), '@max is reached')
    assert.true(form.tasks.isOptionDisabled('sms'), 'a disabled option')
    await form.tasks.select([])
    assert.deepEqual(model.tasks, [])
    assert.false(form.tasks.isOptionDisabled('push'))
    await a11yAudit()
  })

  test('toggle-group is a Toggle Group, single or multiple by the value', async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field @for="size" @control="toggle-group" @label="Size" @options={{sizes}} as |field|>
            <field.Control @variant="outline" as |option|>{{option}}</field.Control>
          </f.Field>
          <f.Field @for="marks" @control="toggle-group" @label="Marks" @options={{sizes}} />
          <f.Field @for="bold" @control="toggle" @label="Bold" />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.dom('fieldset legend', form.size.element).hasText('Size')
    assert
      .dom('[data-test-fw-option="m"]', form.size.element)
      .hasAttribute('aria-label', 'm', "with a block, each item is named by its option's label")
    assert.dom('[data-test-fw-option="m"]', form.marks.element).doesNotHaveAttribute('aria-label')
    await form.size.toggle('m')
    assert.strictEqual(model.size, 'm')
    assert.deepEqual(form.size.value, ['m'])
    await form.size.toggle('l')
    assert.strictEqual(model.size, 'l', 'a single group keeps one')

    await form.marks.select(['s', 'l'])
    assert.deepEqual(model.marks, ['s', 'l'])
    assert.deepEqual(form.marks.value, ['s', 'l'])

    assert.false(form.bold.value)
    await form.bold.toggle()
    assert.true(model.bold)
    assert.dom(form.bold.control).hasText('Bold', 'a toggle shows its label without a block')
    await a11yAudit()
  })

  test('slider is a Slider, a number or a range', async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field @for="volume" @control="slider" @label="Volume" @step={{10}} />
          <f.Field @for="price" @control="range" @label="Price" @min={{0}} @max={{100}} />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.deepEqual(form.volume.value, [50])
    await form.volume.press('ArrowRight')
    assert.strictEqual(model.volume, 60, 'it stores a number, in steps of @step')
    assert.deepEqual(form.price.value, [20, 80])
    await form.price.press('ArrowLeft', 1)
    assert.deepEqual(model.price, [20, 79], 'a range stores a list')
    assert.deepEqual(form.price.slider.labels, ['Price, Minimum', 'Price, Maximum'])
    assert.deepEqual(form.volume.slider.labels, ['Volume'])
    await a11yAudit()
  })

  test('input-otp is an Input OTP, in groups', async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field @for="code" @control="input-otp" @label="Code" @maxLength={{6}} as |field|>
            <field.Control @groups={{array 3 3}} />
          </f.Field>
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.strictEqual(form.code.otp.slots.length, 6)
    assert.strictEqual(form.code.otp.groups.length, 2)
    assert.strictEqual(form.code.otp.separators.length, 1)
    await form.code.fillIn('123456')
    assert.strictEqual(model.code, '123456')
    assert.true(form.code.isComplete)
    assert.strictEqual(form.code.otp.label, 'Code', 'its label names it')
    await a11yAudit()
  })

  test('combobox is a Combobox that filters the options', async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field
            @for="framework"
            @control="combobox"
            @label="Language"
            @placeholder="Select a language"
            @options={{languages}}
            @storeKey={{true}}
          />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    await form.framework.typeIn('fr')
    assert.deepEqual(form.framework.items, ['French'])
    await form.framework.select('French')
    assert.strictEqual(model.framework, 'fr')
    assert.strictEqual(form.framework.value, 'French')
    await a11yAudit()
  })

  test("date-picker is upstream's Date Picker: a Popover's Calendar", async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field @for="dob" @control="date-picker" @label="Date of birth" @locale="en-US" />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.true(form.dob.isEmpty)
    assert.strictEqual(form.dob.text, 'Pick a date')
    await form.dob.pick('2026-11-10')
    assert.strictEqual(model.dob?.toDateString(), new Date(2026, 10, 10).toDateString())
    assert.strictEqual(form.dob.text, 'November 10, 2026')
    assert.false(form.dob.datePicker.isOpen, 'picking a day closes it')
    assert.false(form.dob.isEmpty)
    await a11yAudit()
  })

  test("number, currency and textarea are Joinery's Input and Textarea", async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field @for="seats" @control="number" @label="Seats" @min={{1}} as |field|>
            <field.Control @autocomplete="off" />
          </f.Field>
          <f.Field
            @for="budget"
            @control="currency"
            @label="Budget"
            @currency="EUR"
            @locale="en-US"
          />
          <f.Field @for="bio" @control="textarea" @label="Bio" as |field|>
            <InputGroup as |g|>
              <field.Control @group={{g}} @rows={{4}} />
              <g.Addon @align="block-end"><g.Text>{{field.value.length}}/100</g.Text></g.Addon>
            </InputGroup>
          </f.Field>
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.dom(form.seats.control).hasClass('jn-input').hasAttribute('type', 'number')
    assert.dom(form.seats.control).hasAttribute('autocomplete', 'off')
    await form.seats.fillIn(4)
    assert.strictEqual(model.seats, 4)
    await form.seats.fillIn('')
    assert.strictEqual(model.seats, null)

    assert.dom(form.budget.control).hasClass('jn-input').hasClass('fw-currency')
    assert.strictEqual(form.budget.value, '€1,200.00')
    await form.budget.fillIn('99.5')
    assert.strictEqual(model.budget, 99.5)

    assert.dom(form.bio.control).hasClass('jn-input-group-textarea')
    assert.dom(form.bio.control).hasAttribute('data-slot', 'input-group-control')
    assert.dom(form.bio.control).hasAttribute('rows', '4')
    await form.bio.fillIn('Hello')
    assert.strictEqual(model.bio, 'Hello')
    assert.dom('[data-slot="input-group"]').hasText('5/100')
    await a11yAudit()
  })

  test('readonly and disabled reach every control', async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" @disabled={{true}} as |f|>
          <f.Field @for="language" @control="select" @label="Language" @options={{languages}} />
          <f.Field @for="plan" @control="radio" @label="Plan" @options={{plans}} />
          <f.Field @for="bold" @control="toggle" @label="Bold" />
          <f.Field @for="dob" @control="date-picker" @label="Date of birth" />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.dom(form.language.control).isDisabled()
    assert.dom(form.bold.control).isDisabled()
    assert.dom(form.dob.control).isDisabled()
    assert.true(form.plan.isDisabled)
    assert.dom('[data-slot="field"][data-disabled="true"]').exists()
    await a11yAudit()
  })
})
