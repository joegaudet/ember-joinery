import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { RadioGroup } from '@ember-joinery/primitives/radio-group'
import { RadioGroupHarness, tab } from '@ember-joinery/test-support'

const SPACINGS = ['default', 'comfortable', 'compact']

module('Integration | primitives | radio-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a radiogroup of radio buttons, with aria-checked and data-state', async function (assert) {
    await render(
      <template>
        <RadioGroup @name="spacing" @defaultValue="comfortable" aria-label="Spacing" as |group|>
          {{#each SPACINGS as |value|}}
            <group.Item @value={{value}} id="r-{{value}}" as |item|>
              <item.Indicator>●</item.Indicator>
            </group.Item>
            <label for="r-{{value}}">{{value}}</label>
          {{/each}}
          <output>{{group.value}}</output>
        </RadioGroup>
      </template>,
    )
    const spacing = new RadioGroupHarness('spacing')
    assert.dom(spacing.element).hasAttribute('role', 'radiogroup').doesNotHaveAttribute('dir')
    assert.deepEqual(spacing.options, SPACINGS)
    assert.strictEqual(spacing.value, 'comfortable')
    assert.strictEqual(spacing.label, 'Spacing')
    assert.strictEqual(spacing.labelOf('compact'), 'compact')
    for (const value of SPACINGS) {
      const checked = value === 'comfortable'
      assert
        .dom(spacing.item(value))
        .hasTagName('button')
        .hasAttribute('type', 'button')
        .hasAttribute('role', 'radio')
        .hasAttribute('value', value)
        .hasAttribute('aria-checked', String(checked))
        .hasAttribute('data-state', checked ? 'checked' : 'unchecked')
    }
    assert.dom('[data-test-jn-part="indicator"]').exists({ count: 1 }, 'one mark, on the choice')
    assert.dom('output').hasText('comfortable', 'it yields its value')
    await a11yAudit()
  })

  test('uncontrolled and controlled: a click chooses, and @onValueChange hears it', async function (assert) {
    class State {
      @tracked plan: string | null = 'monthly'
    }
    const state = new State()
    const heard: string[] = []
    const change = (value: string) => {
      heard.push(value)
      state.plan = value
    }
    await render(
      <template>
        <RadioGroup @name="mine" aria-label="Mine" as |group|>
          <group.Item @value="a" aria-label="A" />
          <group.Item @value="b" aria-label="B" />
        </RadioGroup>
        <RadioGroup
          @name="plan"
          @value={{state.plan}}
          @onValueChange={{change}}
          aria-label="Plan"
          as |group|
        >
          <group.Item @value="monthly" aria-label="Monthly" />
          <group.Item @value="yearly" aria-label="Yearly" />
        </RadioGroup>
      </template>,
    )
    const mine = new RadioGroupHarness('mine')
    assert.strictEqual(mine.value, null, 'nothing is chosen by default')
    await mine.choose('b')
    assert.strictEqual(mine.value, 'b')
    await mine.choose('b')
    assert.strictEqual(mine.value, 'b', 'a chosen radio stays chosen')

    const plan = new RadioGroupHarness('plan')
    await plan.choose('yearly')
    assert.deepEqual(heard, ['yearly'])
    assert.strictEqual(plan.value, 'yearly')
    await plan.choose('yearly')
    assert.deepEqual(heard, ['yearly'], 'no change, no call')
    state.plan = null
    await settled()
    assert.strictEqual(plan.value, null, 'it follows @value, null included')
    await a11yAudit()
  })

  test('keyboard: one tab stop, on the choice; the arrows move and choose, and go round', async function (assert) {
    await render(
      <template>
        <button type="button" id="before">Before</button>
        <RadioGroup @name="spacing" @defaultValue="comfortable" aria-label="Spacing" as |group|>
          {{#each SPACINGS as |value|}}
            <group.Item @value={{value}} aria-label={{value}} />
          {{/each}}
        </RadioGroup>
        <button type="button" id="after">After</button>
      </template>,
    )
    const spacing = new RadioGroupHarness('spacing')
    await click('#before')
    await tab()
    assert.strictEqual(spacing.focused, 'comfortable', 'Tab enters on the chosen item')

    await spacing.press('ArrowDown')
    assert.strictEqual(spacing.focused, 'compact')
    assert.strictEqual(spacing.value, 'compact', 'the arrow chose it too')
    await spacing.press('ArrowRight')
    assert.strictEqual(spacing.value, 'default', 'and went round, as Radix loops')
    await spacing.press('ArrowUp')
    assert.strictEqual(spacing.value, 'compact')
    await spacing.press('ArrowLeft')
    assert.strictEqual(spacing.value, 'comfortable')

    await spacing.press('Home')
    assert.strictEqual(spacing.focused, 'default', 'Home moves to the first')
    assert.strictEqual(spacing.value, 'comfortable', 'without choosing it, as in Radix')
    assert.true(await spacing.press('Enter'), 'Enter is cancelled: only Space chooses')
    assert.strictEqual(spacing.value, 'comfortable')

    await tab()
    assert.dom('#after').isFocused('Tab leaves the group')
    await tab({ shift: true })
    assert.strictEqual(
      spacing.focused,
      'default',
      'and comes back to the item focused last, as in Radix',
    )
    await spacing.press('ArrowDown')
    await tab()
    await tab({ shift: true })
    assert.strictEqual(
      spacing.focused,
      'comfortable',
      'which is the choice, once an arrow has moved',
    )
    await a11yAudit()
  })

  test('disabled items are passed over, and a disabled group takes no focus', async function (assert) {
    await render(
      <template>
        <RadioGroup @name="options" @defaultValue="option2" aria-label="Options" as |group|>
          <group.Item @value="option1" @disabled={{true}} aria-label="Disabled" />
          <group.Item @value="option2" aria-label="Option 2" />
          <group.Item @value="option3" aria-label="Option 3" />
        </RadioGroup>
        <RadioGroup @name="off" @disabled={{true}} aria-label="Off" as |group|>
          <group.Item @value="x" aria-label="X" />
        </RadioGroup>
      </template>,
    )
    const options = new RadioGroupHarness('options')
    assert.true(options.isItemDisabled('option1'))
    assert.dom(options.item('option1')).hasAttribute('data-disabled', '')
    await options.focus('option2')
    await options.press('ArrowUp')
    assert.strictEqual(options.value, 'option3', 'up from the second goes round, past the first')
    await click(options.item('option1')).catch(() => undefined)
    assert.strictEqual(options.value, 'option3', 'a disabled item ignores clicks')

    const off = new RadioGroupHarness('off')
    assert.true(off.isDisabled)
    assert.true(off.isItemDisabled('x'))
    assert.dom(off.element).hasAttribute('tabindex', '-1')
    await a11yAudit()
  })

  test('@orientation and @loop narrow the keys', async function (assert) {
    await render(
      <template>
        <RadioGroup
          @name="row"
          @orientation="horizontal"
          @loop={{false}}
          @defaultValue="a"
          aria-label="Row"
          as |group|
        >
          <group.Item @value="a" aria-label="A" />
          <group.Item @value="b" aria-label="B" />
        </RadioGroup>
      </template>,
    )
    const row = new RadioGroupHarness('row')
    assert.strictEqual(row.orientation, 'horizontal')
    assert.dom(row.element).hasAttribute('data-orientation', 'horizontal')
    await row.focus('a')
    await row.press('ArrowDown')
    assert.strictEqual(row.value, 'a', 'up and down do nothing across a row')
    await row.press('ArrowLeft')
    assert.strictEqual(row.value, 'a', 'and it stops at the ends')
    await row.press('ArrowRight')
    assert.strictEqual(row.value, 'b')
    await a11yAudit()
  })

  test('RTL: the left arrow moves forward', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <RadioGroup @name="rtl" @defaultValue="a" aria-label="RTL" as |group|>
            <group.Item @value="a" aria-label="A" />
            <group.Item @value="b" aria-label="B" />
          </RadioGroup>
        </DirectionProvider>
        <RadioGroup @name="own" @dir="rtl" @defaultValue="a" aria-label="Own" as |group|>
          <group.Item @value="a" aria-label="A" />
          <group.Item @value="b" aria-label="B" />
        </RadioGroup>
      </template>,
    )
    const rtl = new RadioGroupHarness('rtl')
    await rtl.focus('a')
    await rtl.press('ArrowLeft')
    assert.strictEqual(rtl.value, 'b')

    const own = new RadioGroupHarness('own')
    assert.dom(own.element).hasAttribute('dir', 'rtl', '@dir sets the direction itself')
    await own.focus('a')
    await own.press('ArrowLeft')
    assert.strictEqual(own.value, 'b')
    await a11yAudit()
  })

  test("in a form: hidden radios submit the choice under the group's @formName", async function (assert) {
    let changes = 0
    const counted = () => changes++
    await render(
      <template>
        <form id="plans" {{on "change" counted}}>
          <RadioGroup @name="plan" @formName="plan" @required={{true}} aria-label="Plan" as |group|>
            <group.Item @value="monthly" aria-label="Monthly" />
            <group.Item @value="yearly" aria-label="Yearly" />
          </RadioGroup>
        </form>
      </template>,
    )

    const formElement = document.querySelector<HTMLFormElement>('#plans')!
    const plan = new RadioGroupHarness('plan')
    assert.true(plan.isRequired)
    assert.dom(plan.inputOf('monthly')).hasAttribute('type', 'radio').hasAttribute('name', 'plan')
    assert.dom(plan.inputOf('yearly')).hasAttribute('value', 'yearly')
    assert.false(formElement.checkValidity(), 'a required group needs a choice')

    await plan.choose('yearly')
    assert.true(formElement.checkValidity())
    assert.deepEqual([...new FormData(formElement).entries()], [['plan', 'yearly']])
    await plan.choose('monthly')
    assert.deepEqual([...new FormData(formElement).entries()], [['plan', 'monthly']])
    assert.strictEqual(changes, 2, 'one change for each choice, from the radio chosen')
    await a11yAudit()
  })
})
