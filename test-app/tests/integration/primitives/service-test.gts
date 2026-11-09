import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, findAll, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { destroy, registerDestructor } from '@ember/destroyable'
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import type Owner from '@ember/owner'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { service } from '@ember-joinery/primitives/service'

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
    <button type="button" {{on "click" this.counter.increment}}>Add one</button>
  </template>
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
          <output>{{counter.count}}</output>
        {{/let}}
      </template>,
    )
    assert.dom('output').hasText('0')

    await click('button')
    await click(findAll('button')[1]!)
    assert.dom('output').hasText('2', 'both buttons and the template use the same counter')
    assert.strictEqual(Counter.made, 1, 'made once')

    const shared = service(this.owner, Counter)
    assert.strictEqual(shared.count, 2, 'the owner itself works as the context')
    assert.strictEqual(shared.owner, this.owner, 'the class is constructed with the owner')
    await a11yAudit()
  })

  test('each test gets its own instance', function (assert) {
    assert.strictEqual(service(this.owner, Counter).count, 0, 'nothing carried over')
    assert.strictEqual(Counter.made, 1)
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
  })

  test('a function makes the instance itself, once per owner', function (assert) {
    let calls = 0
    const make = () => {
      calls += 1
      return { label: 'made by hand' }
    }
    const first = service(this.owner, make)
    assert.strictEqual(service(this.owner, make), first)
    assert.strictEqual(first.label, 'made by hand')
    assert.strictEqual(calls, 1)
  })

  test('in JavaScript it needs a context', function (assert) {
    assert.throws(
      () => (service as (definition: typeof Counter) => Counter)(Counter),
      /service\(this, Toasts\)/,
    )
  })
})
