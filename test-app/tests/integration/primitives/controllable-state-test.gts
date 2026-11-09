import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, find, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ControllableState,
  controllable,
  type ControllableArgs,
} from '@ember-joinery/primitives/controllable-state'

interface DisclosureSignature {
  Args: ControllableArgs<'open', boolean>
  Blocks: { default: [] }
}

/** A disclosure written the way Joinery's components are: open is controllable. */
class Disclosure extends Component<DisclosureSignature> {
  open = controllable(this, 'open', false)

  toggle = () => this.open.set(open => !open)

  <template>
    <button
      type="button"
      aria-expanded={{if this.open.value "true" "false"}}
      {{on "click" this.toggle}}
    >
      Details
    </button>
    {{#if this.open.value}}
      <p>{{yield}}</p>
    {{/if}}
  </template>
}

interface PickerSignature {
  Args: ControllableArgs<'value', string>
}

/** The @value / @defaultValue / @onValueChange pattern. */
class Picker extends Component<PickerSignature> {
  value = controllable(this, 'value', 'apple')

  pick = (event: Event) => this.value.set((event.target as HTMLButtonElement).value)

  <template>
    <output>{{this.value.value}}</output>
    <button type="button" value="apple" {{on "click" this.pick}}>Apple</button>
    <button type="button" value="pear" {{on "click" this.pick}}>Pear</button>
  </template>
}

const expanded = () => find('button')!.getAttribute('aria-expanded')

module('Integration | primitives | controllable-state', function (hooks) {
  setupRenderingTest(hooks)

  test('uncontrolled, it owns the state, starting from the default', async function (assert) {
    const changes: boolean[] = []
    const record = (open: boolean) => changes.push(open)

    await render(
      <template>
        <Disclosure @defaultOpen={{true}} @onOpenChange={{record}}>Shown</Disclosure>
      </template>,
    )
    assert.strictEqual(expanded(), 'true', '@defaultOpen seeds it')
    assert.dom('p').hasText('Shown')

    await click('button')
    assert.strictEqual(expanded(), 'false', 'a change takes effect without the caller')
    assert.dom('p').doesNotExist()

    await click('button')
    assert.strictEqual(expanded(), 'true')
    assert.deepEqual(changes, [false, true], '@onOpenChange hears every change')
    await a11yAudit()
  })

  test('with no value and no default, it starts from the fallback', async function (assert) {
    await render(
      <template>
        <Disclosure>Shown</Disclosure>
      </template>,
    )
    assert.strictEqual(expanded(), 'false')
    await click('button')
    assert.strictEqual(expanded(), 'true', 'and works without @onOpenChange')
  })

  test('controlled, it follows @open, and the caller decides', async function (assert) {
    class State {
      @tracked open = false
      accept = true
      changes: boolean[] = []
      change = (open: boolean) => {
        this.changes.push(open)
        if (this.accept) this.open = open
      }
    }
    const state = new State()

    await render(
      <template>
        <Disclosure @open={{state.open}} @onOpenChange={{state.change}}>Shown</Disclosure>
      </template>,
    )
    assert.strictEqual(expanded(), 'false')

    await click('button')
    assert.strictEqual(expanded(), 'true', 'the caller took the change')

    state.accept = false
    await click('button')
    assert.strictEqual(expanded(), 'true', 'the caller refused it, so nothing changed')
    assert.deepEqual(state.changes, [true, false], 'each request reached the caller')

    state.open = false
    await settled()
    assert.strictEqual(expanded(), 'false', 'a change from the caller shows')
    await a11yAudit()
  })

  test('a controlled @open ignores @defaultOpen', async function (assert) {
    await render(
      <template>
        <Disclosure @open={{false}} @defaultOpen={{true}}>Shown</Disclosure>
      </template>,
    )
    assert.strictEqual(expanded(), 'false')
  })

  test('the @value pattern, and no call when the value stays the same', async function (assert) {
    const changes: string[] = []
    const record = (value: string) => changes.push(value)

    await render(<template><Picker @defaultValue="pear" @onValueChange={{record}} /></template>)
    assert.dom('output').hasText('pear')

    await click('button[value="pear"]')
    assert.deepEqual(changes, [], 'picking the current value changes nothing')

    await click('button[value="apple"]')
    assert.dom('output').hasText('apple')
    assert.deepEqual(changes, ['apple'])
    await a11yAudit()
  })

  test('ControllableState reads its inputs live, outside a component too', function (assert) {
    class Caller {
      @tracked value: number | undefined = undefined
      calls: number[] = []
    }
    const caller = new Caller()
    const state = new ControllableState<number>({
      value: () => caller.value,
      defaultValue: () => 5,
      onChange: () => value => caller.calls.push(value),
      fallback: 0,
    })

    assert.false(state.isControlled)
    assert.strictEqual(state.value, 5, 'the default seeds it')
    state.set(n => n + 1)
    assert.strictEqual(state.value, 6, 'an updater gets the current value')

    caller.value = 10
    assert.true(state.isControlled, 'a value makes it controlled')
    assert.strictEqual(state.value, 10)
    state.set(11)
    assert.strictEqual(state.value, 10, 'controlled, set() only reports')
    assert.deepEqual(caller.calls, [6, 11])
  })
})
