import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  CardHarness,
  CollapsibleHarness,
  InputHarness,
} from '@ember-joinery/test-support'
import CollapsibleSettings from 'docs-app/examples/collapsible-settings'

module('Example | collapsible-settings', function (hooks) {
  setupRenderingTest(hooks)

  test('two radius fields in a small card, and a button that shows two more', async function (assert) {
    await render(<template><CollapsibleSettings /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Radius')
    assert.strictEqual(card.description, 'Set the corner radius of the element.')
    assert.strictEqual(card.size, 'sm')

    const settings = card.find(CollapsibleHarness)
    const toggle = settings.find(ButtonHarness)
    assert.strictEqual(settings.trigger, toggle.element, 'the outline icon Button is the trigger')
    assert.strictEqual(toggle.variant, 'outline')
    assert.strictEqual(toggle.size, 'icon')
    assert.strictEqual(toggle.label, 'Toggle the radius settings')
    assert.true(settings.controlsContent, 'the trigger controls the content')
    assert.false(settings.isShown, 'the other two fields start hidden')

    const shown = InputHarness.findAll()
    assert.deepEqual(
      shown.map(input => input.label),
      ['Radius X', 'Radius Y'],
      'two inputs show, each named by its label',
    )
    assert.deepEqual(
      shown.map(input => input.value),
      ['0', '0'],
    )
    const [x, y] = shown.map(input => input.element.getBoundingClientRect())
    assert.strictEqual(Math.round(x!.top), Math.round(y!.top), 'two columns: side by side')
    assert.ok(x!.right < y!.left, `a gap between them (${x!.right} < ${y!.left})`)
    const icon = () => toggle.element.querySelector('svg')!.innerHTML
    const maximize = icon()

    await settings.open()
    assert.true(settings.isOpen)
    assert.true(settings.isShown)
    const inputs = InputHarness.findAll()
    assert.deepEqual(
      inputs.map(input => input.label),
      ['Radius X', 'Radius Y', 'Radius X', 'Radius Y'],
      'two more, named the same way',
    )
    assert.deepEqual(
      inputs.map(input => input.value),
      ['0', '0', '0', '0'],
    )
    const [, , xOpen, yOpen] = inputs.map(input => input.element.getBoundingClientRect())
    assert.ok(xOpen!.top > x!.bottom, 'the other two fields take a row of their own')
    assert.strictEqual(Math.round(xOpen!.left), Math.round(x!.left), 'on the same columns')
    assert.strictEqual(Math.round(yOpen!.left), Math.round(y!.left))
    assert.notStrictEqual(icon(), maximize, 'the icon turns to Minimize')
    await inputs[2]!.fillIn('8')
    assert.strictEqual(inputs[2]!.value, '8')

    await toggle.click()
    assert.false(settings.isOpen)
    assert.false(settings.isShown)
    assert.strictEqual(icon(), maximize, 'and back to Maximize')
    await a11yAudit()
  })
})
