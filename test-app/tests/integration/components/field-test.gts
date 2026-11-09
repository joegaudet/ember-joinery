import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { click, find, render, rerender } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { array, hash } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Checkbox,
  Field,
  FieldContent,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSeparator,
  FieldSet,
  FieldTitle,
  Input,
  RadioGroup,
  Switch,
  asField,
  asFieldContent,
  asFieldDescription,
  asFieldGroup,
  asFieldLabel,
  asFieldLegend,
  asFieldSet,
  asFieldTitle,
  fieldAttributes,
  fieldClasses,
  fieldErrorMessages,
  fieldLabelClasses,
} from '@ember-joinery/ember'
import {
  CheckboxHarness,
  FieldGroupHarness,
  FieldHarness,
  FieldSetHarness,
  InputHarness,
  LabelHarness,
  RadioGroupHarness,
  SwitchHarness,
  tab,
} from '@ember-joinery/test-support'

/** A colour as the browser resolves it, for comparing with a token. */
function resolved(color: string): string {
  const probe = document.createElement('span')
  probe.style.color = color
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe).color
  probe.remove()
  return value
}

const style = (element: Element) => getComputedStyle(element)

module('Integration | components | field', function (hooks) {
  setupRenderingTest(hooks)

  test("each part renders upstream's element, classes and slots", async function (assert) {
    await render(
      <template>
        <FieldSet @name="profile">
          <FieldLegend>Profile</FieldLegend>
          <FieldDescription>This appears on invoices and emails.</FieldDescription>
          <FieldGroup @name="fields">
            <Field @name="name">
              <FieldLabel @name="name-label" for="name">Full name</FieldLabel>
              <Input id="name" autocomplete="off" placeholder="Evil Rabbit" />
              <FieldDescription>This appears on invoices and emails.</FieldDescription>
            </Field>
            <FieldSeparator />
            <Field @name="username" @invalid={{true}}>
              <FieldLabel for="username">Username</FieldLabel>
              <Input id="username" autocomplete="off" aria-invalid="true" />
              <FieldError>Choose another username.</FieldError>
            </Field>
            <FieldSeparator>Or</FieldSeparator>
            <Field @name="newsletter" @orientation="horizontal">
              <Switch id="newsletter" />
              <FieldContent>
                <FieldTitle>Newsletter</FieldTitle>
                <FieldLabel for="newsletter">Subscribe to the newsletter</FieldLabel>
              </FieldContent>
            </Field>
          </FieldGroup>
        </FieldSet>
      </template>,
    )
    const profile = new FieldSetHarness('profile')
    assert
      .dom(profile.element)
      .hasTagName('fieldset')
      .hasClass('jn-field-set')
      .hasAttribute('data-slot', 'field-set')
      .hasAttribute('data-test-jn', 'field-set')
    assert
      .dom(profile.part('legend'))
      .hasTagName('legend')
      .hasClass('jn-field-legend')
      .hasAttribute('data-slot', 'field-legend')
      .hasAttribute('data-variant', 'legend')
    assert
      .dom(profile.part('description'))
      .hasTagName('p')
      .hasClass('jn-field-description')
      .hasAttribute('data-slot', 'field-description')

    const group = new FieldGroupHarness('fields')
    assert
      .dom(group.element)
      .hasTagName('div')
      .hasClass('jn-field-group')
      .hasClass('group/field-group', "the marker upstream's fields' container queries look for")
      .hasAttribute('data-slot', 'field-group')

    const name = new FieldHarness('name')
    assert
      .dom(name.element)
      .hasTagName('div')
      .hasAttribute('role', 'group')
      .hasClass('jn-field')
      .hasClass('group/field')
      .hasClass('jn-field-orientation-vertical')
      .hasAttribute('data-slot', 'field')
      .hasAttribute('data-orientation', 'vertical')
      .doesNotHaveAttribute('data-invalid')
      .doesNotHaveAttribute('data-disabled')
    assert
      .dom(new LabelHarness('name-label').element)
      .hasTagName('label')
      .hasClass('jn-label', 'a field label is a Label')
      .hasClass('jn-field-label')
      .hasClass('group/field-label')
      .hasClass('peer/field-label')
      .hasAttribute('data-slot', 'field-label')
      .hasAttribute('data-test-jn', 'label')

    const username = new FieldHarness('username')
    assert.dom(username.element).hasAttribute('data-invalid', 'true')
    assert
      .dom(username.errorElement)
      .hasTagName('div')
      .hasClass('jn-field-error')
      .hasAttribute('role', 'alert')
      .hasAttribute('data-slot', 'field-error')

    const [plain, labelled] = group.parts('separator')
    assert
      .dom(plain)
      .hasClass('jn-field-separator')
      .hasAttribute('data-slot', 'field-separator')
      .hasAttribute('data-content', 'false')
    assert.dom('.jn-separator', plain).hasClass('jn-field-separator-line')
    assert.dom('[data-slot="field-separator-content"]', plain).doesNotExist()
    assert.dom(labelled).hasAttribute('data-content', 'true')
    assert
      .dom('[data-slot="field-separator-content"]', labelled)
      .hasTagName('span')
      .hasClass('jn-field-separator-content')
      .hasText('Or')

    const newsletter = new FieldHarness('newsletter')
    assert
      .dom(newsletter.element)
      .hasClass('jn-field-orientation-horizontal')
      .hasAttribute('data-orientation', 'horizontal')
    assert
      .dom(newsletter.content)
      .hasClass('jn-field-content')
      .hasClass('group/field-content')
      .hasAttribute('data-slot', 'field-content')
    assert
      .dom(newsletter.part('title'))
      .hasClass('jn-field-title')
      .hasAttribute('data-slot', 'field-label', "upstream's title shares the label's slot")
    await a11yAudit()
  })

  test('its style sheet lays fields out, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="width: 320px">
          <FieldGroup @name="group">
            <FieldSet @name="set">
              <FieldLegend>Payment Method</FieldLegend>
              <FieldDescription>All transactions are secure and encrypted</FieldDescription>
              <FieldGroup data-slot="checkbox-group">
                <Field @name="vertical">
                  <FieldLabel for="card">Name on Card</FieldLabel>
                  <Input id="card" />
                </Field>
                <Field @name="horizontal" @orientation="horizontal">
                  <Checkbox id="same" />
                  <FieldLabel for="same">Same as shipping address</FieldLabel>
                </Field>
              </FieldGroup>
            </FieldSet>
            <FieldSet @name="choices">
              <FieldLegend @variant="label">Show these items</FieldLegend>
            </FieldSet>
            <Field @name="invalid" @invalid={{true}}>
              <FieldLabel for="email">Email</FieldLabel>
              <Input id="email" aria-invalid="true" />
              <FieldError>Enter a valid email address.</FieldError>
            </Field>
            <Field @name="disabled" @disabled={{true}}>
              <FieldLabel for="off">Off</FieldLabel>
              <Input id="off" disabled />
            </Field>
          </FieldGroup>
        </div>
      </template>,
    )
    const group = style(new FieldGroupHarness('group').element)
    assert.strictEqual(group.display, 'flex')
    assert.strictEqual(group.flexDirection, 'column')
    assert.strictEqual(group.rowGap, '20px', 'gap-5')
    assert.strictEqual(group.width, '320px', 'w-full')
    assert.strictEqual(group.containerType, 'inline-size', '@container/field-group')
    assert.strictEqual(group.containerName, 'field-group')

    const set = new FieldSetHarness('set')
    assert.strictEqual(style(set.element).flexDirection, 'column')
    assert.strictEqual(
      style(set.element).rowGap,
      '12px',
      'has-[>[data-slot=checkbox-group]]:gap-3, not gap-4',
    )
    assert.strictEqual(style(new FieldSetHarness('choices').element).rowGap, '16px', 'gap-4')
    const legend = style(set.part('legend'))
    assert.strictEqual(legend.fontSize, '16px', 'data-[variant=legend]:text-base')
    assert.strictEqual(legend.fontWeight, '500', 'font-medium')
    assert.strictEqual(legend.marginBottom, '6px', 'mb-1.5')
    const description = style(set.part('description'))
    assert.strictEqual(description.fontSize, '14px', 'text-sm')
    assert.strictEqual(description.color, resolved('var(--muted-foreground)'))
    assert.strictEqual(
      description.marginTop,
      '-6px',
      '[[data-variant=legend]+&]:-mt-1.5 after a legend, over nth-last-2:-mt-1',
    )
    const checkboxes = set.find(FieldGroupHarness).element
    assert.strictEqual(style(checkboxes).rowGap, '12px', 'data-[slot=checkbox-group]:gap-3')
    assert.strictEqual(
      style(new FieldSetHarness('choices').part('legend')).fontSize,
      '14px',
      'data-[variant=label]:text-sm',
    )

    const vertical = new FieldHarness('vertical')
    assert.strictEqual(style(vertical.element).flexDirection, 'column')
    assert.strictEqual(style(vertical.element).rowGap, '8px', 'gap-2')
    assert.strictEqual(vertical.find(InputHarness).element.offsetWidth, 320, '*:w-full')
    assert.strictEqual(
      vertical.labelElement!.offsetWidth,
      320,
      "*:w-full wins over the field label's own w-fit, as upstream's does",
    )
    const label = style(vertical.labelElement!)
    assert.strictEqual(label.fontSize, '14px', "the label's text-sm")
    assert.strictEqual(label.fontWeight, '500', "the label's font-medium")
    assert.strictEqual(label.lineHeight, '19.25px', "the field label's leading-snug wins")

    const horizontal = new FieldHarness('horizontal')
    assert.strictEqual(style(horizontal.element).flexDirection, 'row')
    assert.strictEqual(style(horizontal.element).alignItems, 'center')
    assert.strictEqual(
      style(horizontal.labelElement!).flexGrow,
      '1',
      '*:data-[slot=field-label]:flex-auto',
    )

    const invalid = new FieldHarness('invalid')
    assert.strictEqual(style(invalid.element).color, resolved('var(--destructive)'))
    const error = style(invalid.errorElement!)
    assert.strictEqual(error.color, resolved('var(--destructive)'))
    assert.strictEqual(error.fontSize, '14px', 'text-sm')
    assert.strictEqual(error.fontWeight, '400', 'font-normal')

    const disabled = new FieldHarness('disabled')
    assert.strictEqual(
      style(disabled.labelElement!).opacity,
      '0.5',
      'group-data-[disabled=true]/field:opacity-50',
    )
    assert.strictEqual(style(vertical.labelElement!).opacity, '1')
    await a11yAudit()
  })

  test('a responsive field lays out by the width of its field group', async function (assert) {
    class State {
      @tracked width = 600
    }
    const state = new State()
    await render(
      <template>
        <div style="width: {{state.width}}px">
          <FieldGroup>
            <Field @name="name" @orientation="responsive">
              <FieldContent>
                <FieldLabel for="name">Name</FieldLabel>
                <FieldDescription>Provide your full name for identification</FieldDescription>
              </FieldContent>
              <Input id="name" />
            </Field>
          </FieldGroup>
        </div>
      </template>,
    )
    const field = new FieldHarness('name')
    assert.strictEqual(field.orientation, 'responsive')
    assert.strictEqual(style(field.element).flexDirection, 'row', '@md/field-group:flex-row')
    const input = field.find(InputHarness).element
    assert.true(
      input.offsetWidth < 300,
      "@md/field-group:*:w-auto: the input's own w-full gives way to its content's width",
    )
    assert.strictEqual(style(field.element).alignItems, 'flex-start', 'beside its content')
    state.width = 400
    await rerender()
    assert.strictEqual(style(field.element).flexDirection, 'column', 'under 28rem it stacks')
    await a11yAudit()
  })

  test('FieldError shows its block, one message, or a list of distinct ones', async function (assert) {
    class State {
      @tracked errors: Array<{ message?: string } | undefined> = []
    }
    const state = new State()
    await render(
      <template>
        <Field @name="block">
          <FieldLabel for="a">A</FieldLabel>
          <Input id="a" />
          <FieldError @errors={{array (hash message="Ignored")}}>Choose another.</FieldError>
        </Field>
        <Field @name="list">
          <FieldLabel for="b">B</FieldLabel>
          <Input id="b" />
          <FieldError @errors={{state.errors}} />
        </Field>
      </template>,
    )
    assert.strictEqual(new FieldHarness('block').error, 'Choose another.', 'the block wins')

    const list = new FieldHarness('list')
    assert.strictEqual(list.errorElement, null, 'nothing renders without errors')
    assert.deepEqual(list.errors, [])

    state.errors = [{ message: 'Too short.' }, { message: 'Too short.' }]
    await rerender()
    assert.strictEqual(list.error, 'Too short.', 'a repeated message shows once')
    assert.dom('ul', list.errorElement!).doesNotExist('one message is plain text')

    state.errors = [{ message: 'Too short.' }, undefined, { message: 'Needs a digit.' }]
    await rerender()
    assert.dom('ul', list.errorElement!).hasClass('jn-field-error-list')
    assert.deepEqual(list.errors, ['Too short.', 'Needs a digit.'])
    const items = style(find('.jn-field-error-list')!)
    assert.strictEqual(items.listStyleType, 'disc', 'list-disc')
    assert.strictEqual(items.marginInlineStart, '16px', 'ms-4')
    assert.strictEqual(items.rowGap, '4px', 'gap-1')

    state.errors = [undefined]
    await rerender()
    assert.strictEqual(list.errorElement, null, 'an error with no message shows nothing')
    await a11yAudit()
  })

  test('fieldErrorMessages() keeps one of each message, in order', function (assert) {
    assert.deepEqual(fieldErrorMessages(undefined), [])
    assert.deepEqual(fieldErrorMessages([{ message: 'a' }, { message: 'b' }, { message: 'a' }]), [
      'a',
      'b',
    ])
    assert.deepEqual(fieldErrorMessages([undefined, {}]), [undefined])
  })

  test('a choice card: a field inside its label, highlighted while checked and focused', async function (assert) {
    await render(
      <template>
        <RadioGroup @name="env" @defaultValue="kubernetes" as |group|>
          <FieldLabel @name="kubernetes" for="kubernetes">
            <Field @name="kubernetes" @orientation="horizontal">
              <FieldContent>
                <FieldTitle id="kubernetes-title">Kubernetes</FieldTitle>
                <FieldDescription>Run GPU workloads on a K8s cluster.</FieldDescription>
              </FieldContent>
              {{! axe can't name it through the field's role="group" inside its label }}
              <group.Item @value="kubernetes" id="kubernetes" aria-labelledby="kubernetes-title" />
            </Field>
          </FieldLabel>
          <FieldLabel @name="vm" for="vm">
            <Field @name="vm" @orientation="horizontal">
              <FieldContent>
                <FieldTitle id="vm-title">Virtual Machine</FieldTitle>
                <FieldDescription>Access a cluster to run GPU workloads.</FieldDescription>
              </FieldContent>
              <group.Item @value="vm" id="vm" aria-labelledby="vm-title" />
            </Field>
          </FieldLabel>
        </RadioGroup>
      </template>,
    )
    const env = new RadioGroupHarness('env')
    assert.deepEqual(
      env.options,
      ['kubernetes', 'vm'],
      "items inside a field are still the group's",
    )
    assert.strictEqual(env.value, 'kubernetes')

    const chosen = style(new LabelHarness('kubernetes').element)
    const other = style(new LabelHarness('vm').element)
    assert.strictEqual(chosen.borderTopWidth, '1px', 'has-[>[data-slot=field]]:border')
    assert.strictEqual(chosen.borderTopLeftRadius, '10px', 'has-[>[data-slot=field]]:rounded-lg')
    assert.strictEqual(chosen.flexDirection, 'column', 'has-[>[data-slot=field]]:flex-col')
    assert.notStrictEqual(chosen.backgroundColor, other.backgroundColor, 'has-data-checked:bg-*')
    assert.strictEqual(
      style(new FieldHarness('kubernetes').element).paddingTop,
      '10px',
      '*:data-[slot=field]:p-2.5',
    )

    const vm = new FieldHarness('vm')
    assert.strictEqual(vm.label, 'Virtual Machine', 'its title is its label')
    assert.strictEqual(vm.title, 'Virtual Machine')
    assert.strictEqual(vm.description, 'Access a cluster to run GPU workloads.')

    await tab()
    assert.dom(env.item('kubernetes')).isFocused('Tab reaches the chosen card')
    const focused = style(new LabelHarness('kubernetes').element)
    assert.notStrictEqual(focused.boxShadow, 'none', 'has-[:focus-visible]:ring-3')
    assert.strictEqual(focused.borderTopColor, resolved('var(--ring)'))

    await click(new LabelHarness('vm').element)
    assert.strictEqual(env.value, 'vm', 'a press anywhere on the card chooses it')
    await a11yAudit()
  })

  test("a field's label passes a press to its control, and the harness reads the field", async function (assert) {
    await render(
      <template>
        <FieldGroup @name="prefs">
          <FieldSet @name="desktop" disabled>
            <FieldLegend @variant="label">Show these items on the desktop</FieldLegend>
            <FieldDescription>Select the items you want to show on the desktop.</FieldDescription>
            <Field @name="disks" @orientation="horizontal">
              <Checkbox id="disks" />
              <FieldLabel for="disks">Hard disks</FieldLabel>
            </Field>
          </FieldSet>
          <FieldSeparator />
          <Field @name="sync" @orientation="horizontal" @disabled={{true}}>
            <Checkbox id="sync" @defaultChecked={{true}} />
            <FieldContent>
              <FieldLabel for="sync">Sync Desktop &amp; Documents folders</FieldLabel>
              <FieldDescription>Your folders are being synced with iCloud Drive.</FieldDescription>
              <FieldDescription>You can access them from other devices.</FieldDescription>
            </FieldContent>
          </Field>
          <FieldSeparator>Or continue with</FieldSeparator>
          <Field @name="email" @invalid={{true}}>
            <FieldLabel for="email">Email</FieldLabel>
            <Input id="email" aria-invalid="true" />
            <FieldError>Enter a valid email address.</FieldError>
          </Field>
        </FieldGroup>
      </template>,
    )
    const prefs = new FieldGroupHarness('prefs')
    assert.deepEqual(
      prefs.fields.map(field => field.label),
      ['Hard disks', 'Sync Desktop & Documents folders', 'Email'],
    )
    assert.strictEqual(prefs.fieldSets.length, 1)
    assert.deepEqual(prefs.separators, ['', 'Or continue with'])

    const desktop = new FieldSetHarness('desktop')
    assert.strictEqual(desktop.legend, 'Show these items on the desktop')
    assert.strictEqual(desktop.legendVariant, 'label')
    assert.strictEqual(desktop.description, 'Select the items you want to show on the desktop.')
    assert.deepEqual(
      desktop.fields.map(field => field.label),
      ['Hard disks'],
    )
    assert.true(desktop.isDisabled)
    assert.true(
      desktop.find(CheckboxHarness).isDisabled,
      'a disabled field set disables its controls',
    )

    const sync = new FieldHarness('sync')
    assert.strictEqual(sync.orientation, 'horizontal')
    assert.true(sync.isDisabled)
    assert.false(sync.isInvalid)
    assert.deepEqual(sync.descriptions, [
      'Your folders are being synced with iCloud Drive.',
      'You can access them from other devices.',
    ])
    assert.strictEqual(
      sync.description,
      'Your folders are being synced with iCloud Drive. You can access them from other devices.',
    )
    assert.strictEqual(sync.control, find('#sync'))
    assert.strictEqual(sync.error, '')
    const checkbox = sync.find(CheckboxHarness)
    await click(sync.labelElement!)
    assert.false(checkbox.isChecked, 'a press on its label toggles its checkbox')
    assert.strictEqual(
      style(sync.element).alignItems,
      'flex-start',
      'has-[>[data-slot=field-content]]:items-start',
    )
    assert.strictEqual(
      style(checkbox.element).marginTop,
      '1px',
      'has-[>[data-slot=field-content]]:[&>[role=checkbox],[role=radio]]:mt-px',
    )

    const email = new FieldHarness('email')
    assert.true(email.isInvalid)
    assert.strictEqual(email.error, 'Enter a valid email address.')
    assert.deepEqual(email.errors, ['Enter a valid email address.'])
    assert.strictEqual(email.content, null)
    assert.strictEqual(email.title, '')
    await email.find(InputHarness).fillIn('ada@example.com')
    assert.strictEqual(email.find(InputHarness).value, 'ada@example.com')
    assert.strictEqual(email.text, 'Email Enter a valid email address.')
    await a11yAudit()
  })

  test('RTL: a horizontal field starts at the right, and an error list indents from it', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="width: 300px">
            <Field @name="rtl" @orientation="horizontal">
              <Switch @name="rtl" id="rtl" />
              <FieldLabel for="rtl">المصادقة متعددة العوامل</FieldLabel>
            </Field>
            <Field @name="errors">
              <FieldError @errors={{array (hash message="قصير جدا") (hash message="يحتاج رقما")}} />
            </Field>
          </div>
        </DirectionProvider>
      </template>,
    )
    const field = new FieldHarness('rtl')
    const row = field.element.getBoundingClientRect()
    const control = new SwitchHarness('rtl').element.getBoundingClientRect()
    assert.strictEqual(
      Math.round(control.right),
      Math.round(row.right),
      'the switch is on the right',
    )
    const label = field.labelElement!.getBoundingClientRect()
    assert.true(label.right <= control.left, 'its label is to the left of it')
    const list = style(find('.jn-field-error-list')!)
    assert.strictEqual(list.marginRight, '16px', 'ms-4 is on the right')
    assert.strictEqual(list.marginLeft, '0px')
    await a11yAudit()
  })

  test('@as and each part modifier render the same classes and attributes', async function (assert) {
    await render(
      <template>
        <div>
          <Field @name="f" @orientation="horizontal" @invalid={{true}} data-case="field">x</Field>
          <div
            {{asField name="f" orientation="horizontal" invalid=true}}
            data-case="field-m"
          >x</div>
          <FieldSet @name="s" data-case="set">x</FieldSet>
          <fieldset {{asFieldSet name="s"}} data-case="set-m">x</fieldset>
          <fieldset>
            <FieldLegend @variant="label" data-case="legend">x</FieldLegend>
          </fieldset>
          <fieldset>
            <legend {{asFieldLegend variant="label"}} data-case="legend-m">x</legend>
          </fieldset>
          <FieldGroup @name="g" data-case="group">x</FieldGroup>
          <div {{asFieldGroup name="g"}} data-case="group-m">x</div>
          <FieldContent data-case="content">x</FieldContent>
          <div {{asFieldContent}} data-case="content-m">x</div>
          <FieldTitle data-case="title">x</FieldTitle>
          <div {{asFieldTitle}} data-case="title-m">x</div>
          <FieldDescription data-case="description">x</FieldDescription>
          <p {{asFieldDescription}} data-case="description-m">x</p>
          <FieldLabel @name="l" for="i" data-case="label">x</FieldLabel>
          <label {{asFieldLabel name="l"}} for="i" data-case="label-m">x</label>
          <input id="i" aria-label="x" />
          <Field @as="section" @name="section">x</Field>
          <FieldDescription @as="div" data-case="as-description">x</FieldDescription>
        </div>
      </template>,
    )
    for (const name of [
      'field',
      'set',
      'legend',
      'group',
      'content',
      'title',
      'description',
      'label',
    ]) {
      assert.deepEqual(
        rendering(find(`[data-case="${name}"]`)!),
        rendering(find(`[data-case="${name}-m"]`)!),
        name,
      )
    }
    assert.deepEqual(
      rendering(find('[data-case="field"]')!).classes,
      fieldClasses({ orientation: 'horizontal' }).split(' ').sort(),
    )
    for (const [attribute, value] of Object.entries(
      fieldAttributes({ orientation: 'horizontal', invalid: true, name: 'f' }),
    )) {
      assert.strictEqual(
        find('[data-case="field"]')!.getAttribute(attribute),
        value ?? null,
        attribute,
      )
    }
    assert.deepEqual(
      rendering(find('[data-case="label"]')!).classes,
      fieldLabelClasses().split(' ').sort(),
    )
    assert.dom(new FieldHarness('section').element).hasTagName('section').hasClass('jn-field')
    assert.dom('[data-case="as-description"]').hasTagName('div').hasClass('jn-field-description')
    await a11yAudit()
  })

  test('a caller’s data-invalid and data-disabled work as upstream’s examples write them', async function (assert) {
    await render(
      <template>
        <Field @name="email" data-invalid="true" data-disabled="true">
          <FieldLabel for="email">Email</FieldLabel>
          <Input id="email" disabled />
        </Field>
      </template>,
    )
    const field = new FieldHarness('email')
    assert.true(field.isInvalid)
    assert.true(field.isDisabled)
    assert.strictEqual(style(field.element).color, resolved('var(--destructive)'))
    await a11yAudit()
  })
})
