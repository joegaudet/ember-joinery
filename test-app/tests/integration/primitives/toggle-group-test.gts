import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ToggleGroup } from '@ember-joinery/primitives/toggle-group'
import { ToggleGroupHarness, tab } from '@ember-joinery/test-support'

class Value {
  @tracked value = 'left'
  changes: string[] = []
  set = (value: string) => {
    this.changes.push(value)
    this.value = value
  }
}

module('Integration | primitives | toggle-group', function (hooks) {
  setupRenderingTest(hooks)

  test('multiple: a group of toggles, any number pressed', async function (assert) {
    const changes: string[][] = []
    const change = (value: string[]) => changes.push(value)
    await render(
      <template>
        <ToggleGroup
          @type="multiple"
          @defaultValue={{array "bold"}}
          @onValueChange={{change}}
          @name="format"
          aria-label="Format"
          as |g|
        >
          <g.Item @value="bold" aria-label="Bold">B</g.Item>
          <g.Item @value="italic" as |pressed|>Italic{{if pressed " on"}}</g.Item>
          <g.Item @value="underline" aria-label="Underline">U</g.Item>
          <output>{{g.value.length}}</output>
        </ToggleGroup>
      </template>,
    )
    const format = new ToggleGroupHarness('format')
    assert.dom(format.element).hasAttribute('role', 'group')
    assert.strictEqual(format.type, 'multiple')
    assert.deepEqual(format.itemValues, ['bold', 'italic', 'underline'])
    for (const item of format.items) {
      assert.dom(item).hasTagName('button').hasAttribute('type', 'button')
      assert.dom(item).doesNotHaveAttribute('role')
    }
    assert
      .dom(format.item('bold'))
      .hasAttribute('aria-pressed', 'true')
      .hasAttribute('data-state', 'on')
    assert
      .dom(format.item('italic'))
      .hasAttribute('aria-pressed', 'false')
      .hasAttribute('data-state', 'off')
    assert.deepEqual(format.value, ['bold'])

    await format.toggle('italic')
    assert.deepEqual(format.value, ['bold', 'italic'])
    assert.dom(format.item('italic')).hasText('Italic on', 'an item yields whether it is pressed')
    assert.dom('output').hasText('2', 'the group yields its value')
    await format.toggle('bold')
    assert.deepEqual(format.value, ['italic'])
    assert.deepEqual(changes, [['bold', 'italic'], ['italic']])
    await a11yAudit()
  })

  test('single: radios, one pressed at a time, or none', async function (assert) {
    const changes: string[] = []
    const change = (value: string) => changes.push(value)
    await render(
      <template>
        <ToggleGroup
          @type="single"
          @defaultValue="all"
          @onValueChange={{change}}
          aria-label="Show"
          as |g|
        >
          <g.Item @value="all">All</g.Item>
          <g.Item @value="missed">Missed</g.Item>
        </ToggleGroup>
      </template>,
    )
    const show = new ToggleGroupHarness()
    assert.strictEqual(show.type, 'single')
    assert
      .dom(show.item('all'))
      .hasAttribute('role', 'radio')
      .hasAttribute('aria-checked', 'true')
      .doesNotHaveAttribute('aria-pressed', 'a radio has no aria-pressed')
    assert.deepEqual(show.value, ['all'])

    await show.toggle('missed')
    assert.deepEqual(show.value, ['missed'], 'pressing one lets go of the other')
    assert.dom(show.item('all')).hasAttribute('aria-checked', 'false')
    await show.toggle('missed')
    assert.deepEqual(show.value, [], 'and pressing it again lets it go')
    assert.deepEqual(changes, ['missed', ''])
    await a11yAudit()
  })

  test('controlled: @value is the value, and @onValueChange asks for a new one', async function (assert) {
    const align = new Value()
    const asked: string[] = []
    const ask = (value: string) => asked.push(value)
    await render(
      <template>
        <ToggleGroup
          @type="single"
          @value={{align.value}}
          @onValueChange={{align.set}}
          @name="taken"
          aria-label="Align"
          as |g|
        >
          <g.Item @value="left">Left</g.Item>
          <g.Item @value="right">Right</g.Item>
        </ToggleGroup>
        <ToggleGroup
          @type="single"
          @value="left"
          @onValueChange={{ask}}
          @name="kept"
          aria-label="Kept"
          as |g|
        >
          <g.Item @value="left">Left</g.Item>
          <g.Item @value="right">Right</g.Item>
        </ToggleGroup>
      </template>,
    )
    const taken = new ToggleGroupHarness('taken')
    await taken.toggle('right')
    assert.deepEqual(taken.value, ['right'])
    align.value = 'left'
    await settled()
    assert.deepEqual(taken.value, ['left'], 'it follows @value')

    const kept = new ToggleGroupHarness('kept')
    await kept.toggle('right')
    assert.deepEqual(asked, ['right'], 'it asked')
    assert.deepEqual(kept.value, ['left'], 'but stays as the caller has it')
    await a11yAudit()
  })

  test('keyboard: one tab stop, the arrows move between items and wrap, Space presses', async function (assert) {
    await render(
      <template>
        <button type="button">Before</button>
        <ToggleGroup @type="multiple" @orientation="horizontal" aria-label="Format" as |g|>
          <g.Item @value="bold">Bold</g.Item>
          <g.Item @value="italic" @disabled={{true}}>Italic</g.Item>
          <g.Item @value="underline">Underline</g.Item>
        </ToggleGroup>
        <button type="button">After</button>
      </template>,
    )
    const format = new ToggleGroupHarness()
    await tab()
    await tab()
    assert.strictEqual(format.focused, 'bold', 'Tab enters on the first item')
    assert.strictEqual(format.tabStop, 'bold')
    await format.press('ArrowRight')
    assert.strictEqual(format.focused, 'underline', 'past the disabled item')
    await format.press('ArrowRight')
    assert.strictEqual(format.focused, 'bold', 'round to the first')
    await format.press('ArrowLeft')
    assert.strictEqual(format.focused, 'underline')
    await format.press('ArrowDown')
    assert.strictEqual(format.focused, 'underline', 'a horizontal group ignores up and down')
    await format.press('Home')
    assert.strictEqual(format.focused, 'bold')
    await format.press('End')
    assert.strictEqual(format.focused, 'underline')
    await tab()
    assert.dom(document.activeElement).hasText('After', 'Tab leaves the group in one step')
    await tab({ shift: true })
    assert.strictEqual(format.focused, 'underline', 'and comes back to the item focused last')
    await a11yAudit()
  })

  test('Tab enters on the pressed item', async function (assert) {
    await render(
      <template>
        <ToggleGroup @type="single" @defaultValue="center" aria-label="Align" as |g|>
          <g.Item @value="left">Left</g.Item>
          <g.Item @value="center">Center</g.Item>
          <g.Item @value="right">Right</g.Item>
        </ToggleGroup>
      </template>,
    )
    await tab()
    assert.strictEqual(new ToggleGroupHarness().focused, 'center')
    await a11yAudit()
  })

  test('RTL: left and right swap', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <ToggleGroup @type="multiple" @orientation="horizontal" aria-label="Format" as |g|>
            <g.Item @value="bold">Bold</g.Item>
            <g.Item @value="italic">Italic</g.Item>
          </ToggleGroup>
        </DirectionProvider>
      </template>,
    )
    const format = new ToggleGroupHarness()
    await format.focus('bold')
    await format.press('ArrowLeft')
    assert.strictEqual(format.focused, 'italic', 'right to left, the left arrow moves forward')
    await a11yAudit()
  })

  test('disabled: no item can be pressed or focused', async function (assert) {
    await render(
      <template>
        <ToggleGroup @type="multiple" @disabled={{true}} aria-label="Format" as |g|>
          <g.Item @value="bold">Bold</g.Item>
          <g.Item @value="italic">Italic</g.Item>
        </ToggleGroup>
      </template>,
    )
    const format = new ToggleGroupHarness()
    assert.true(format.isDisabled())
    assert.true(format.isDisabled('bold'))
    for (const item of format.items) assert.dom(item).isDisabled().hasAttribute('data-disabled')
    await format.toggle('bold').catch(() => undefined)
    assert.deepEqual(format.value, [])
    await a11yAudit()
  })

  test('@rovingFocus={{false}}: each item is its own tab stop', async function (assert) {
    await render(
      <template>
        <ToggleGroup @type="multiple" @rovingFocus={{false}} aria-label="Format" as |g|>
          <g.Item @value="bold">Bold</g.Item>
          <g.Item @value="italic">Italic</g.Item>
        </ToggleGroup>
      </template>,
    )
    const format = new ToggleGroupHarness()
    assert.dom(format.element).doesNotHaveAttribute('tabindex')
    await tab()
    await tab()
    assert.strictEqual(format.focused, 'italic', 'Tab visits every item')
    await a11yAudit()
  })

  test('g.item puts the same behaviour on an element of your own', async function (assert) {
    await render(
      <template>
        <ToggleGroup @type="multiple" aria-label="Format" as |g|>
          <g.Item @value="bold">Bold</g.Item>
          <button type="button" {{g.item value="italic"}}>Italic</button>
        </ToggleGroup>
      </template>,
    )
    const format = new ToggleGroupHarness()
    assert.deepEqual(format.itemValues, ['bold', 'italic'])
    await format.toggle('italic')
    assert.deepEqual(format.value, ['italic'])
    await format.focus('bold')
    await format.press('ArrowRight')
    assert.strictEqual(format.focused, 'italic', 'it is in the roving focus too')
    await a11yAudit()
  })
})
