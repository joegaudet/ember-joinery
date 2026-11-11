import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { array } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import { CurrencyHarness, FormHarness, field } from '@ember-formwright/test-support'
import { FieldGroup, InputGroup, Rating, Slider } from '@ember-joinery/ember'
import { RatingHarness, SliderHarness } from '@ember-joinery/test-support'
import { JoineryFieldLayout, setupJoineryForms } from '@ember-joinery/formwright'
import {
  CheckboxFieldHarness,
  CheckboxGroupFieldHarness,
  ComboboxFieldHarness,
  DatePickerFieldHarness,
  InputFieldHarness,
  InputOTPFieldHarness,
  NativeSelectFieldHarness,
  NumberFieldHarness,
  RadioGroupFieldHarness,
  RatingFieldHarness,
  SelectFieldHarness,
  SliderFieldHarness,
  SwitchFieldHarness,
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
  @tracked stars: number | null = null
  @tracked code = ''
  @tracked framework: string | null = null
  @tracked dob: Date | null = null
  @tracked seats: number | null = 2
  @tracked budget: number | null = 1200
  @tracked bio = ''
  @tracked about = ''
  @tracked agree = false
  @tracked notify = false
}

class Mode {
  @tracked readonly = false
  @tracked disabled = false
}

class Group {
  @tracked wide = false
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
  @field(RatingFieldHarness) declare stars: RatingFieldHarness
  @field(InputOTPFieldHarness) declare code: InputOTPFieldHarness
  @field(ComboboxFieldHarness) declare framework: ComboboxFieldHarness
  @field(DatePickerFieldHarness) declare dob: DatePickerFieldHarness
  @field(NumberFieldHarness) declare seats: NumberFieldHarness
  @field(CurrencyHarness) declare budget: CurrencyHarness
  @field(InputFieldHarness) declare bio: InputFieldHarness
  @field(InputFieldHarness) declare about: InputFieldHarness
  @field(CheckboxFieldHarness) declare agree: CheckboxFieldHarness
  @field(SwitchFieldHarness) declare notify: SwitchFieldHarness
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
    await form.language.select('fr')
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
    await form.language.select('de')
    assert.strictEqual(model.language, 'de')
    await form.language.select('auto')
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

  test("a slider's hint and errors describe each thumb, aria-invalid while the field is", async function (assert) {
    const model = new Settings()
    const requireLoud = (settings: Settings): ErrorMap =>
      settings.volume >= 60 ? {} : { volume: ['Turn it up to at least 60.'] }
    await render(
      <template>
        <Form @model={{model}} @name="settings" @validator={{requireLoud}} as |f|>
          <FieldGroup>
            <f.Field @for="bio" @label="Bio" />
            <f.Field
              @for="volume"
              @control="slider"
              @label="Volume"
              @hint="Turn it up in steps of ten."
              @step={{10}}
            />
            <f.Field @for="price" @control="range" @label="Price" @hint="Between $0 and $100." />
          </FieldGroup>
          <f.Submit>Save</f.Submit>
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const hintOf = (field: SliderFieldHarness): string =>
      field.element.querySelector('[data-test-fw-hint]')!.id
    const errorsOf = (field: SliderFieldHarness): string =>
      field.element.querySelector('[data-test-fw-errors]')!.id
    const [volumeThumb] = form.volume.slider.thumbs
    assert.strictEqual(form.volume.control, volumeThumb, "the field's id is on its first thumb")
    assert.dom(form.volume.control).hasAttribute('role', 'slider')
    for (const thumb of [...form.volume.slider.thumbs, ...form.price.slider.thumbs]) {
      const field = form.volume.element.contains(thumb) ? form.volume : form.price
      assert.dom(thumb).hasAttribute('aria-describedby', hintOf(field), 'its hint describes it')
      assert.dom(thumb).doesNotHaveAttribute('aria-invalid')
    }

    await form.submit()
    assert.true(form.volume.isInvalid)
    assert.deepEqual(form.volume.errors, ['Turn it up to at least 60.'])
    assert
      .dom(volumeThumb)
      .hasAttribute('aria-describedby', `${hintOf(form.volume)} ${errorsOf(form.volume)}`)
      .hasAttribute('aria-invalid', 'true')
    assert.dom(volumeThumb).isFocused('a failed submit focuses the invalid slider')
    for (const thumb of form.price.slider.thumbs) {
      assert.dom(thumb).doesNotHaveAttribute('aria-invalid', 'a valid range is not invalid')
    }
    await a11yAudit()

    await form.volume.press('ArrowRight')
    assert.strictEqual(model.volume, 60)
    assert.false(form.volume.isInvalid, 'its error clears as it is fixed')
    assert.dom(volumeThumb).hasAttribute('aria-describedby', hintOf(form.volume))
    assert.dom(volumeThumb).doesNotHaveAttribute('aria-invalid')
    await a11yAudit()
  })

  test("a slider field renders Joinery's Slider markup", async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Slider @defaultValue={{array 20 80}} @name="plain" />
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field @for="price" @control="range" @label="Price" />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const markup = (root: HTMLElement): string[] =>
      [root, ...root.querySelectorAll<HTMLElement>('[data-slot]')].map(
        element => `${element.dataset['slot']}: ${rendering(element).classes.join(' ')}`,
      )
    const plain = new SliderHarness('plain')
    assert.deepEqual(markup(form.price.slider.element), markup(plain.element))
    assert.deepEqual(markup(plain.element), [
      'slider: jn-slider',
      'slider-track: jn-slider-track',
      'slider-range: jn-slider-range',
      'slider-thumb: jn-slider-thumb',
      'slider-thumb: jn-slider-thumb',
    ])
    await a11yAudit()
  })

  test('rating is a Rating, named by the label: a star picks it, and the same star clears it', async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field @for="stars" @control="rating" @label="Stars" @hint="How was it?" />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const { rating } = form.stars
    assert.strictEqual(form.stars.control, rating.element, "the field's id is on the Rating")
    assert.dom(rating.element).hasAttribute('role', 'radiogroup')
    assert.strictEqual(rating.label, 'Stars', "the field's label names its group")
    assert
      .dom('[data-slot="field-set"]', form.stars.element)
      .doesNotExist('which is the only group: the field is a Field, not a FieldSet around it')
    assert.deepEqual(form.stars.options, [1, 2, 3, 4, 5])
    assert.strictEqual(form.stars.value, null, 'no rating to start with')
    assert.strictEqual(rating.labelOf(3), '3 stars')

    await form.stars.select(4)
    assert.strictEqual(model.stars, 4, 'it stores the rating picked')
    assert.strictEqual(form.stars.stars, '★ ★ ★ ★ ☆')
    assert.dom(rating.input(4)).isChecked()

    await form.stars.focus()
    await form.stars.press('ArrowRight')
    assert.strictEqual(model.stars, 5, 'the arrow keys move between the stars, and pick them')
    assert.strictEqual(rating.focused, 5)

    await form.stars.select(5)
    assert.strictEqual(model.stars, null, 'picking the rating already picked clears it')
    assert.strictEqual(form.stars.stars, '☆ ☆ ☆ ☆ ☆')
    await a11yAudit()
  })

  test('a rating takes half stars with @step, and as many as @max', async function (assert) {
    const model = new Settings()
    model.stars = 2.5
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field @for="stars" @control="rating" @label="Stars" @max={{3}} @step={{0.5}} />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    assert.deepEqual(form.stars.options, [0.5, 1, 1.5, 2, 2.5, 3])
    assert.strictEqual(form.stars.value, 2.5)
    assert.dom(form.stars.rating.item(2.5)).hasAttribute('data-half', 'start')
    assert.dom(form.stars.rating.item(3)).hasAttribute('data-half', 'end')
    await form.stars.select(1.5)
    assert.strictEqual(model.stars, 1.5)
    await a11yAudit()
  })

  test("a rating's hint and errors describe each radio, aria-invalid while the field is", async function (assert) {
    const model = new Settings()
    const requireStars = (settings: Settings): ErrorMap =>
      settings.stars ? {} : { stars: ['Rate it, please.'] }
    await render(
      <template>
        <Form @model={{model}} @name="settings" @validator={{requireStars}} as |f|>
          <FieldGroup>
            <f.Field @for="bio" @label="Bio" />
            <f.Field @for="stars" @control="rating" @label="Stars" @hint="How was it?" />
          </FieldGroup>
          <f.Submit>Save</f.Submit>
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const hint = form.stars.element.querySelector('[data-test-fw-hint]')!.id
    const errors = (): string => form.stars.element.querySelector('[data-test-fw-errors]')!.id
    const radios = form.stars.rating.options.map(value => form.stars.rating.input(value))
    for (const radio of radios) {
      assert.dom(radio).hasAttribute('aria-describedby', hint, 'its hint describes each radio')
      assert.dom(radio).doesNotHaveAttribute('aria-invalid')
    }

    await form.submit()
    assert.true(form.stars.isInvalid)
    assert.deepEqual(form.stars.errors, ['Rate it, please.'])
    for (const radio of radios) {
      assert
        .dom(radio)
        .hasAttribute('aria-describedby', `${hint} ${errors()}`)
        .hasAttribute('aria-invalid', 'true')
    }
    assert.dom(radios[0]).isFocused('a failed submit focuses the first star')
    await a11yAudit()

    await form.stars.select(3)
    assert.false(form.stars.isInvalid, 'its error clears as it is fixed')
    for (const radio of radios) {
      assert.dom(radio).hasAttribute('aria-describedby', hint).doesNotHaveAttribute('aria-invalid')
    }
    await a11yAudit()
  })

  test("a rating field renders Joinery's Rating markup", async function (assert) {
    const model = new Settings()
    model.stars = 2
    await render(
      <template>
        <Rating @defaultValue={{2}} @name="plain" aria-label="Plain" />
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field @for="stars" @control="rating" @label="Stars" />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const plain = new RatingHarness('plain')
    const markup = (root: HTMLElement): string[] =>
      [root, ...root.querySelectorAll<HTMLElement>('[data-slot]')].map(
        element => `${element.dataset['slot']}: ${rendering(element).classes.join(' ')}`,
      )
    assert.deepEqual(markup(form.stars.rating.element), markup(plain.element))
    assert.deepEqual(markup(plain.element).slice(0, 3), [
      'rating: jn-rating',
      'rating-items: jn-rating-items',
      'rating-item: jn-rating-item',
    ])
    // Each item's own attributes, and its radio's, but for what the field adds to the radio.
    const FIELD_ONLY = new Set([
      'id',
      'name',
      'aria-describedby',
      'aria-invalid',
      'data-test-fw-option',
    ])
    const attributesOf = (element: Element): string =>
      [...element.attributes]
        .filter(a => !FIELD_ONLY.has(a.name))
        .map(a => `${a.name}=${a.value}`)
        .sort()
        .join(' ')
    const shape = (harness: RatingHarness): string[] =>
      harness.items.flatMap(item => [
        attributesOf(item),
        attributesOf(item.querySelector('input')!),
        item
          .querySelector('label')!
          // Before Ember 7.1 `As` renders through a classic component, whose id is Ember's own.
          .innerHTML.replace(/ id="ember\d+"/g, '')
          .replace(/<!---->/g, '')
          .replace(/\s+/g, ' ')
          .replace(/> | </g, m => m.trim()),
      ])
    assert.deepEqual(shape(form.stars.rating), shape(plain))
    assert.dom(form.stars.rating.element).hasAttribute('data-size', 'default')
    await a11yAudit()
  })

  test("in a vertical field each control is the field wide, through its own root's box", async function (assert) {
    const model = new Settings()
    const group = new Group()
    await render(
      <template>
        <div style={{if group.wide "width: 40rem" "width: 20rem"}}>
          <Form
            @model={{model}}
            @name="settings"
            @layout={{if group.wide "joinery-responsive" "joinery-vertical"}}
            as |f|
          >
            <FieldGroup>
              <f.Field @for="bio" @label="Bio" />
              <f.Field
                @for="language"
                @control="select"
                @label="Language"
                @options={{languages}}
                @storeKey={{true}}
              />
              <f.Field
                @for="framework"
                @control="combobox"
                @label="Framework"
                @options={{languages}}
                @storeKey={{true}}
              />
              <f.Field @for="dob" @control="date-picker" @label="Date of birth" />
            </FieldGroup>
          </Form>
        </div>
      </template>,
    )
    const form = new SettingsForm()
    const width = (element: Element): number => element.getBoundingClientRect().width
    const fieldWidth = (): number => width(form.bio.element.querySelector('[data-slot="field"]')!)
    const controls = (): [string, Element][] => [
      ['select', form.language.selectHarness.trigger],
      ['combobox', form.framework.element.querySelector('.jn-combobox-input')!],
      ['date picker', form.dob.control],
    ]
    assert.strictEqual(width(form.bio.control), fieldWidth(), 'an input is the field wide')
    for (const [name, control] of controls()) {
      assert.strictEqual(width(control), fieldWidth(), `and so is a ${name}`)
    }

    group.wide = true
    await settled()
    for (const [name, control] of controls()) {
      assert.true(
        width(control) < fieldWidth() / 2,
        `responsive, in a group 28rem wide, a ${name} sizes to its content`,
      )
    }
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

  test("a textarea field's @showCount puts its count in an Input Group, as Formwright's shows one", async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" as |f|>
          <f.Field
            @for="bio"
            @control="textarea"
            @label="Bio"
            @showCount={{true}}
            @maxLength={{100}}
          />
          <f.Field @for="about" @control="textarea" @label="About" @showCount={{true}} />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const group = form.bio.element.querySelector('[data-slot="input-group"]')!
    assert.dom(form.bio.control).hasClass('jn-input-group-textarea')
    assert.dom(form.bio.control).hasAttribute('data-slot', 'input-group-control')
    assert.true(group.contains(form.bio.control), 'the textarea is in the group')
    const count = group.querySelector('[data-test-fw-count]')!
    assert.dom(count).hasText('0 / 100').hasAttribute('aria-live', 'polite')
    await form.bio.fillIn('Hello')
    assert.strictEqual(model.bio, 'Hello')
    assert.dom(count).hasText('5 / 100', 'it counts as you type')
    await form.about.fillIn('Hi')
    assert
      .dom('[data-test-fw-count]', form.about.element)
      .hasText('2', 'with no @maxLength, the length')
    await a11yAudit()
  })

  test("in an inline form's callout, a select, a combobox and a date picker open and pick in it", async function (assert) {
    const model = new Settings()
    await render(
      <template>
        <Form @model={{model}} @name="settings" @inline={{true}} @callout={{true}} as |f|>
          <f.Field
            @for="language"
            @control="select"
            @label="Language"
            @options={{languages}}
            @storeKey={{true}}
          />
          <f.Field
            @for="framework"
            @control="combobox"
            @label="Framework"
            @options={{languages}}
            @storeKey={{true}}
          />
          <f.Field @for="dob" @control="date-picker" @label="Date of birth" @locale="en-US" />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const calloutOf = (harness: { element: Element }): Element | null =>
      harness.element.querySelector('.fw-callout')
    const isOpen = (harness: { element: Element }): boolean =>
      calloutOf(harness)?.matches(':popover-open') ?? false

    await form.language.edit()
    assert.true(isOpen(form.language), "the select's callout opens")
    await form.language.select('fr')
    assert.true(isOpen(form.language), 'and stays open while its list picks, over it')
    await form.language.commit()
    assert.strictEqual(model.language, 'fr')

    await form.framework.edit()
    await form.framework.select('German')
    assert.true(isOpen(form.framework), "a combobox's list picks in its callout too")
    await form.framework.commit()
    assert.strictEqual(model.framework, 'de')

    await form.dob.edit()
    await form.dob.pick('2026-11-10')
    assert.true(isOpen(form.dob), "and a date picker's calendar")
    await form.dob.commit()
    assert.strictEqual(model.dob?.toDateString(), new Date(2026, 10, 10).toDateString())
    await a11yAudit()
  })

  test('readonly and disabled reach every control, each as it can take them', async function (assert) {
    const model = new Settings()
    const mode = new Mode()
    await render(
      <template>
        <Form
          @model={{model}}
          @name="settings"
          @readonly={{mode.readonly}}
          @disabled={{mode.disabled}}
          as |f|
        >
          <f.Field @for="bio" @label="Bio" />
          <f.Field @for="about" @control="textarea" @label="About" />
          <f.Field @for="seats" @control="number" @label="Seats" />
          <f.Field @for="budget" @control="currency" @label="Budget" @locale="en-US" />
          <f.Field
            @for="language"
            @control="select"
            @label="Language"
            @options={{languages}}
            @storeKey={{true}}
          />
          <f.Field
            @for="nativeLanguage"
            @control="native-select"
            @label="Native language"
            @options={{languages}}
          />
          <f.Field
            @for="framework"
            @control="combobox"
            @label="Framework"
            @options={{languages}}
            @storeKey={{true}}
          />
          <f.Field @for="agree" @control="checkbox" @label="Agree" />
          <f.Field @for="notify" @control="switch" @label="Notify" />
          <f.Field @for="bold" @control="toggle" @label="Bold" />
          <f.Field
            @for="plan"
            @control="radio"
            @label="Plan"
            @options={{plans}}
            @storeKey={{true}}
          />
          <f.Field
            @for="tasks"
            @control="checkbox-group"
            @label="Tasks"
            @options={{tasks}}
            @storeKey={{true}}
          />
          <f.Field
            @for="size"
            @control="toggle-group"
            @label="Size"
            @options={{sizes}}
            @storeKey={{true}}
          />
          <f.Field @for="volume" @control="slider" @label="Volume" />
          <f.Field @for="stars" @control="rating" @label="Stars" />
          <f.Field @for="code" @control="input-otp" @label="Code" />
          <f.Field @for="dob" @control="date-picker" @label="Date of birth" />
        </Form>
      </template>,
    )
    const form = new SettingsForm()
    const textual = [form.bio, form.about, form.seats, form.budget] as const
    const pressable = [
      form.language,
      form.nativeLanguage,
      form.agree,
      form.notify,
      form.bold,
      form.code,
      form.dob,
    ] as const
    const options = (harness: { element: Element }) => [
      ...harness.element.querySelectorAll<HTMLElement>('[data-test-fw-option]'),
    ]

    mode.readonly = true
    await settled()
    for (const harness of textual) {
      assert.dom(harness.control).hasAttribute('readonly', '', `${harness.path} is read-only`)
      assert.dom(harness.control).isNotDisabled(`${harness.path} still takes focus`)
    }
    assert
      .dom(form.framework.control)
      .hasAttribute('readonly', '', "a combobox's input is read-only")
      .hasAttribute('aria-readonly', 'true')
      .isNotDisabled()
    for (const harness of pressable) {
      assert
        .dom(harness.control)
        .isDisabled(`${harness.path}, which can't be read-only, is disabled`)
    }
    assert.true(form.plan.radioGroup.isDisabled, 'a radio group is disabled')
    for (const option of [...options(form.tasks), ...options(form.size)]) {
      assert.dom(option).isDisabled('so are a checkbox group and a toggle group')
    }
    assert.true(form.volume.slider.isDisabled, 'and a slider')
    assert.true(form.stars.rating.isReadonly, 'a rating is read-only')
    assert.false(form.stars.rating.isDisabled, 'and its stars still take focus')
    await form.stars.select(2)
    assert.strictEqual(model.stars, null, 'but picking one changes nothing')
    assert.dom('[data-slot="field"][data-disabled="true"]').doesNotExist('no field looks disabled')
    await a11yAudit()

    mode.readonly = false
    mode.disabled = true
    await settled()
    for (const harness of [...textual, form.framework, ...pressable]) {
      assert.dom(harness.control).isDisabled(`${harness.path} is disabled`)
    }
    assert.true(form.plan.radioGroup.isDisabled)
    for (const option of [...options(form.tasks), ...options(form.size)]) {
      assert.dom(option).isDisabled()
    }
    assert.true(form.volume.slider.isDisabled)
    assert.true(form.stars.rating.isDisabled)
    assert.true(form.plan.isDisabled)
    for (const harness of [...textual, form.framework, ...pressable, form.volume, form.stars]) {
      assert
        .dom(harness.element.querySelector('[data-slot="field"]'))
        .hasAttribute('data-disabled', 'true', `${harness.path}'s Field looks disabled`)
    }
    for (const harness of [form.plan, form.tasks, form.size]) {
      assert
        .dom(harness.element.querySelector('[data-slot="field-set"]'))
        .hasAttribute('data-disabled', 'true', `and ${harness.path}'s FieldSet`)
    }
    await a11yAudit()

    mode.disabled = false
    await settled()
    for (const harness of [...textual, form.framework]) {
      assert.dom(harness.control).isNotDisabled().doesNotHaveAttribute('readonly')
    }
    for (const harness of pressable) assert.dom(harness.control).isNotDisabled()
    assert.false(form.plan.radioGroup.isDisabled)
    assert.false(form.volume.slider.isDisabled)
    assert.false(form.stars.rating.isDisabled)
    assert.false(form.stars.rating.isReadonly)
    await a11yAudit()
  })
})
