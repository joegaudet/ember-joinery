import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { destroy, registerDestructor } from '@ember/destroyable'
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import type Owner from '@ember/owner'
import type RouterService from '@ember/routing/router-service'
import Service from '@ember/service'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { asyncService, service } from '@ember-joinery/primitives/service'
import { Harness } from '@ember-joinery/test-support'
import { ReadoutHarness } from 'test-app/tests/fixtures/primitives/readout'

/** State a whole app shares, like a toaster's queue. */
class Counter {
  static made = 0
  static destroyed = 0

  @tracked count = 0
  owner: Owner

  constructor(owner: Owner) {
    Counter.made += 1
    this.owner = owner
    registerDestructor(this, () => (Counter.destroyed += 1))
  }

  increment = () => (this.count += 1)
}

class Increment extends Component {
  get counter() {
    return service(this, Counter)
  }

  <template>
    <button type="button" data-test-jn="increment" {{on "click" this.counter.increment}}>
      Add one
    </button>
  </template>
}

/** A button that adds one, and says what the count is when it shows it. */
class IncrementHarness extends Harness {
  static override component = 'increment'

  get label(): string {
    return this.element.textContent!.replace(/\s+/g, ' ').trim()
  }

  async add(): Promise<void> {
    await click(this.element)
  }
}

/** A service registered by name, typed through the registry as an app's own would be. */
class Greeter extends Service {
  greeting = 'hello from a registered service'
}

declare module '@ember/service' {
  interface Registry {
    'test-greeter': Greeter
  }
}

module('Integration | primitives | service', function (hooks) {
  setupRenderingTest(hooks)

  hooks.beforeEach(function () {
    Counter.made = 0
    Counter.destroyed = 0
  })

  test('components and templates share one instance per owner', async function (assert) {
    await render(
      <template>
        <Increment />
        <Increment />
        {{#let (service Counter) as |counter|}}
          <output data-test-jn="readout">{{counter.count}}</output>
        {{/let}}
      </template>,
    )
    const count = new ReadoutHarness()
    const [first, second] = IncrementHarness.findAll()
    assert.strictEqual(count.text, '0')

    await first!.add()
    await second!.add()
    assert.strictEqual(count.text, '2', 'both buttons and the template use the same counter')
    assert.strictEqual(Counter.made, 1, 'made once')

    const shared = service(this.owner, Counter)
    assert.strictEqual(shared.count, 2, 'the owner itself works as the context')
    assert.strictEqual(shared.owner, this.owner, 'the class is constructed with the owner')
    await a11yAudit()
  })

  test('each test gets its own instance', async function (assert) {
    assert.strictEqual(service(this.owner, Counter).count, 0, 'nothing carried over')
    assert.strictEqual(Counter.made, 1)
    await a11yAudit()
  })

  test('the instance is destroyed with its owner', async function (assert) {
    // Any object with lookup() counts as an owner; destroying the test's own owner early would
    // upset ember-qunit's teardown.
    const owner = { lookup: () => undefined } as unknown as Owner
    const counter = service(owner, Counter)
    assert.strictEqual(counter.owner, owner)
    destroy(owner)
    await settled()
    assert.strictEqual(Counter.destroyed, 1, 'its destructor ran')
    await a11yAudit()
  })

  test('a function makes the instance itself, once per owner', async function (assert) {
    let calls = 0
    const make = () => {
      calls += 1
      return { label: 'made by hand' }
    }
    const first = service(this.owner, make)
    assert.strictEqual(service(this.owner, make), first)
    assert.strictEqual(first.label, 'made by hand')
    assert.strictEqual(calls, 1)
    await a11yAudit()
  })

  test('in JavaScript it needs a context', async function (assert) {
    assert.throws(
      () => (service as (definition: typeof Counter) => Counter)(Counter),
      /service\(this, Toasts\)/,
    )
    await a11yAudit()
  })

  test('a name looks up a registered service, in templates and JavaScript', async function (assert) {
    this.owner.register('service:test-greeter', Greeter)
    await render(
      <template>
        {{#let (service "test-greeter") as |greeter|}}
          <output data-test-jn="readout" data-test-jn-name="greeting">{{greeter.greeting}}</output>
        {{/let}}
        {{#let (service "router") as |router|}}
          <p data-test-jn="readout" data-test-jn-name="router">
            {{if router.rootURL "the router service"}}
          </p>
        {{/let}}
      </template>,
    )
    assert.strictEqual(new ReadoutHarness('greeting').text, 'hello from a registered service')
    assert.strictEqual(new ReadoutHarness('router').text, 'the router service')

    const router: RouterService = service(this.owner, 'router')
    assert.strictEqual(router, this.owner.lookup('service:router'), 'the one @service injects')
    assert.throws(() => service(this.owner, 'nothing-here'), /no service registered/)
    await a11yAudit()
  })

  module('asyncService', function () {
    test('loads the class once, then shares one instance per owner', async function (assert) {
      let loads = 0
      const loader = async () => {
        loads += 1
        await Promise.resolve()
        return { default: Counter }
      }

      class Cart extends Component {
        get counter() {
          return asyncService(this, loader)
        }

        <template>
          {{#if this.counter.isLoading}}
            <p>Loading…</p>
          {{else if this.counter.resolved}}
            <button
              type="button"
              data-test-jn="increment"
              {{on "click" this.counter.resolved.increment}}
            >
              Add one ({{this.counter.resolved.count}})
            </button>
          {{/if}}
        </template>
      }

      await render(
        <template>
          <Cart />
          <Cart />
        </template>,
      )
      const buttons = IncrementHarness.findAll()
      assert.strictEqual(buttons.length, 2, 'both loaded')
      assert.strictEqual(loads, 1, 'the loader ran once')

      await buttons[0]!.add()
      assert.deepEqual(
        buttons.map(button => button.label),
        ['Add one (1)', 'Add one (1)'],
        'both read the one instance',
      )
      const state = asyncService(this.owner, loader)
      assert.strictEqual(state.resolved, service(this.owner, Counter), 'the same as service()')
      await a11yAudit()
    })

    test('shows the loading state while the class loads', async function (assert) {
      let finish: (value: typeof Counter) => void = () => {}
      const loader = () => new Promise<typeof Counter>(resolve => (finish = resolve))
      const state = asyncService(this.owner, loader)
      assert.true(state.isLoading)
      assert.strictEqual(state.resolved, undefined)
      finish(Counter)
      await settled()
      assert.false(state.isLoading)
      assert.true(state.resolved instanceof Counter)
      await a11yAudit()
    })

    test('a failed load is an error, with the reason', async function (assert) {
      const failure = new Error('offline')
      const loader = () => Promise.reject(failure)
      const state = asyncService(this.owner, loader)
      await settled()
      assert.false(state.isLoading)
      assert.strictEqual(state.error?.original, failure)
      assert.strictEqual(state.error?.reason, 'Promise rejected while waiting to resolve')
      assert.strictEqual(state.resolved, undefined)
      await a11yAudit()
    })

    test('each owner gets its own instance', async function (assert) {
      const loader = () => Promise.resolve(Counter)
      const other = { lookup: () => undefined } as unknown as Owner
      const mine = asyncService(this.owner, loader)
      const theirs = asyncService(other, loader)
      await settled()
      assert.notStrictEqual(mine.resolved, theirs.resolved)
      assert.strictEqual(theirs.resolved?.owner, other)
      destroy(other)
      await a11yAudit()
    })
  })
})
