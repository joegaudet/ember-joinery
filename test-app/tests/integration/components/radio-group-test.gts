import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Field, FieldLabel, RadioGroup } from '@ember-joinery/ember'
import { RadioGroupHarness, tab } from '@ember-joinery/test-support'

/** A colour as the browser resolves it, for comparing with a token. */
function resolved(color: string): string {
  const probe = document.createElement('span')
  probe.style.color = color
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe).color
  probe.remove()
  return value
}

/** Where an element's centre is. */
function centre(element: Element): { x: number; y: number } {
  const box = element.getBoundingClientRect()
  return { x: Math.round(box.left + box.width / 2), y: Math.round(box.top + box.height / 2) }
}

module('Integration | components | radio-group', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's classes and slots, with a dot on the choice", async function (assert) {
    await render(
      <template>
        <RadioGroup @name="spacing" @defaultValue="comfortable" aria-label="Spacing" as |group|>
          <group.Item @value="default" id="r1" />
          <label for="r1">Default</label>
          <group.Item @value="comfortable" id="r2" />
          <label for="r2">Comfortable</label>
        </RadioGroup>
      </template>,
    )
    const spacing = new RadioGroupHarness('spacing')
    assert
      .dom(spacing.element)
      .hasClass('jn-radio-group')
      .hasAttribute('data-slot', 'radio-group')
      .hasAttribute('role', 'radiogroup')
    for (const item of spacing.items) {
      assert
        .dom(item)
        .hasClass('jn-radio-group-item')
        .hasClass('group/radio-group-item')
        .hasClass('peer')
        .hasAttribute('data-slot', 'radio-group-item')
    }
    assert.strictEqual(spacing.value, 'comfortable')
    assert.strictEqual(spacing.labelOf('default'), 'Default')
    const indicators = spacing.element.querySelectorAll('[data-slot="radio-group-indicator"]')
    assert.strictEqual(indicators.length, 1)
    assert.dom(indicators[0]).hasClass('jn-radio-group-indicator')
    assert.ok(spacing.item('comfortable').contains(indicators[0]!), 'on the chosen item')
    assert.dom('.jn-radio-group-indicator-icon').exists({ count: 1 })
    await a11yAudit()
  })

  test('its style sheet lays it out and draws the ring and dot, without Tailwind', async function (assert) {
    await render(
      <template>
        <RadioGroup @name="plan" @defaultValue="b" aria-label="Plan" as |group|>
          <group.Item @value="a" aria-label="A" />
          <group.Item @value="b" aria-label="B" />
          <group.Item @value="c" aria-invalid="true" aria-label="C" />
          <group.Item @value="d" @disabled={{true}} aria-label="D" />
        </RadioGroup>
      </template>,
    )
    const plan = new RadioGroupHarness('plan')
    const group = getComputedStyle(plan.element)
    assert.strictEqual(group.display, 'grid', 'grid gap-2')
    assert.strictEqual(group.rowGap, '8px')

    const ring = getComputedStyle(plan.item('a'))
    assert.strictEqual(ring.width, '16px', 'size-4')
    assert.strictEqual(ring.height, '16px', 'aspect-square')
    assert.strictEqual(ring.borderTopWidth, '1px')
    assert.strictEqual(ring.borderTopColor, resolved('var(--input)'))
    assert.true(Number.parseFloat(ring.borderTopLeftRadius) > 1000, 'rounded-full')

    const chosen = getComputedStyle(plan.item('b'))
    assert.strictEqual(chosen.backgroundColor, resolved('var(--primary)'))
    const dot = plan.item('b').querySelector('.jn-radio-group-indicator-icon')!
    assert.strictEqual(getComputedStyle(dot).width, '8px', 'size-2')
    assert.strictEqual(getComputedStyle(dot).backgroundColor, resolved('var(--primary-foreground)'))
    assert.deepEqual(centre(dot), centre(plan.item('b')), 'the dot is centred')

    assert.strictEqual(
      getComputedStyle(plan.item('c')).borderTopColor,
      resolved('var(--destructive)'),
    )
    assert.true(plan.isItemInvalid('c'))
    assert.strictEqual(getComputedStyle(plan.item('d')).opacity, '0.5')
    await a11yAudit()
  })

  test('controlled, uncontrolled, and the keyboard', async function (assert) {
    class State {
      @tracked value: string | null = 'monthly'
    }
    const state = new State()
    const change = (value: string) => (state.value = value)
    await render(
      <template>
        <RadioGroup
          @name="plan"
          @value={{state.value}}
          @onValueChange={{change}}
          aria-label="Plan"
          as |group|
        >
          <group.Item @value="monthly" aria-label="Monthly" />
          <group.Item @value="yearly" aria-label="Yearly" />
          <group.Item @value="lifetime" aria-label="Lifetime" />
        </RadioGroup>
      </template>,
    )
    const plan = new RadioGroupHarness('plan')
    await tab()
    assert.strictEqual(plan.focused, 'monthly', 'Tab enters on the choice')
    await plan.press('ArrowDown')
    assert.strictEqual(state.value, 'yearly', 'an arrow moves the choice')
    await plan.choose('lifetime')
    assert.strictEqual(state.value, 'lifetime')
    state.value = 'monthly'
    await settled()
    assert.strictEqual(plan.value, 'monthly', 'it follows @value')
    await a11yAudit()
  })

  test('RTL: the dot stays centred, and the left arrow moves forward', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <RadioGroup @name="rtl" @defaultValue="default" aria-label="التباعد" as |group|>
            <group.Item @value="default" aria-label="افتراضي" />
            <group.Item @value="comfortable" aria-label="مريح" />
          </RadioGroup>
        </DirectionProvider>
      </template>,
    )
    const rtl = new RadioGroupHarness('rtl')
    const dot = rtl.item('default').querySelector('.jn-radio-group-indicator-icon')!
    assert.deepEqual(centre(dot), centre(rtl.item('default')), 'start-1/2 with rtl:translate-x-1/2')
    await rtl.focus('default')
    await rtl.press('ArrowLeft')
    assert.strictEqual(rtl.value, 'comfortable')
    await a11yAudit()
  })

  test('the harness finds items inside a Field, whether the group has its own id or yours', async function (assert) {
    // Each item is named with aria-label: axe reads no name through the field's role="group"
    // inside the label, though browsers do (see radio-group-choice-card).
    await render(
      <template>
        <RadioGroup @name="ours" @defaultValue="pro" aria-label="Ours" as |group|>
          <FieldLabel for="ours-pro">
            <Field @orientation="horizontal">
              <group.Item @value="pro" id="ours-pro" aria-label="Pro" />
              Pro
            </Field>
          </FieldLabel>
        </RadioGroup>
        <RadioGroup @name="yours" @defaultValue="plus" id="plans" aria-label="Yours" as |group|>
          <FieldLabel for="yours-plus">
            <Field @orientation="horizontal">
              <group.Item @value="plus" id="yours-plus" aria-label="Plus" />
              Plus
            </Field>
          </FieldLabel>
          <FieldLabel for="yours-team">
            <Field @orientation="horizontal">
              <group.Item @value="team" id="yours-team" aria-label="Team" />
              Team
            </Field>
          </FieldLabel>
        </RadioGroup>
      </template>,
    )
    assert.deepEqual(new RadioGroupHarness('ours').options, ['pro'])
    const yours = new RadioGroupHarness('yours')
    assert.dom(yours.element).hasAttribute('id', 'plans', 'the caller’s id wins')
    assert.dom(yours.item('plus')).hasAttribute('data-test-jn-owner', 'plans')
    assert.deepEqual(yours.options, ['plus', 'team'], 'its items follow it')
    assert.strictEqual(yours.value, 'plus')
    await yours.choose('team')
    assert.strictEqual(yours.value, 'team')
    await a11yAudit()
  })

  test('in a form, @as and the harness', async function (assert) {
    await render(
      <template>
        <form id="prefs">
          <RadioGroup
            @name="notify"
            @formName="notify"
            @required={{true}}
            aria-label="Notify"
            as |group|
          >
            <group.Item @value="email" aria-label="Email" />
            <group.Item @value="sms" @as="span" tabindex="-1" aria-label="SMS" />
          </RadioGroup>
        </form>
      </template>,
    )

    const notify = new RadioGroupHarness('notify')
    assert.true(notify.isRequired)
    assert.false(notify.isDisabled)
    assert.strictEqual(notify.orientation, null)
    assert.deepEqual(notify.options, ['email', 'sms'])
    assert.dom(notify.item('sms')).hasTagName('span').hasClass('jn-radio-group-item')
    assert.dom(notify.inputOf('email')).hasAttribute('name', 'notify')
    await notify.choose('sms')
    assert.true(notify.isChecked('sms'))
    assert.false(notify.isChecked('email'))
    const formElement = document.querySelector<HTMLFormElement>('#prefs')!
    assert.deepEqual([...new FormData(formElement).entries()], [['notify', 'sms']])
    assert.strictEqual(notify.tabStop, 'sms')
    assert.throws(() => notify.item('fax'), /no "item" part "fax"/)
    await a11yAudit()
  })
})
