import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { destroy, isDestroyed, registerDestructor } from '@ember/destroyable'
import { getOwner, setOwner } from '@ember/owner'
import { service as injected } from '@ember/service'
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import type Owner from '@ember/owner'
import type RouterService from '@ember/routing/router-service'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { createStore, findOwner, isOwner } from '@ember-joinery/primitives/store'
import { service } from '@ember-joinery/primitives/service'
import { Harness } from '@ember-joinery/test-support'

/** A counter's own state: one per Counter component. */
class Tally {
  static made = 0
  static destroyed = 0

  @tracked count = 0
  @injected declare router: RouterService
  owner: Owner

  constructor(owner: Owner) {
    Tally.made += 1
    this.owner = owner
    registerDestructor(this, () => (Tally.destroyed += 1))
  }

  add = () => (this.count += 1)
}

class Counter extends Component<{ Args: { name: string } }> {
  get tally() {
    return createStore(this, Tally)
  }

  <template>
    <div data-test-jn="counter" data-test-jn-name={{@name}}>
      <button type="button" data-test-jn-part="add" {{on "click" this.tally.add}}>Add one</button>
      <output data-test-jn-part="count">{{this.tally.count}}</output>
    </div>
  </template>
}

class CounterHarness extends Harness {
  static override component = 'counter'

  get count() {
    return Number(this.part('count').textContent)
  }

  async add() {
    await click(this.part('add'))
  }
}

class Visibility {
  @tracked shown = true
}

module('Integration | primitives | store', function (hooks) {
  setupRenderingTest(hooks)

  hooks.beforeEach(function () {
    Tally.made = 0
    Tally.destroyed = 0
  })

  test('each context gets its own instance, and keeps it', async function (assert) {
    await render(
      <template>
        <Counter @name="first" />
        <Counter @name="second" />
      </template>,
    )
    const first = new CounterHarness('first')
    const second = new CounterHarness('second')

    await first.add()
    await first.add()
    await second.add()
    assert.strictEqual(first.count, 2, 'the first counter has its own tally')
    assert.strictEqual(second.count, 1, 'and so does the second')
    assert.strictEqual(Tally.made, 2, 'one per component, however often it is read')
    await a11yAudit()
  })

  test('the instance is destroyed with its context', async function (assert) {
    const visibility = new Visibility()
    await render(
      <template>
        {{#if visibility.shown}}
          <Counter @name="only" />
        {{/if}}
      </template>,
    )
    assert.strictEqual(Tally.destroyed, 0)
    visibility.shown = false
    await settled()
    assert.strictEqual(Tally.destroyed, 1, 'its destructor ran when the component went')
    await a11yAudit()
  })

  test('the class is constructed with the owner, so services are injected', async function (assert) {
    const context = {}
    const owner = this.owner
    setOwner(context, owner) // any object can be a context once it has an owner

    const tally = createStore(context, Tally)
    assert.strictEqual(tally.owner, owner)
    assert.strictEqual(getOwner(tally), owner, 'the instance has the owner too')
    assert.strictEqual(tally.router, owner.lookup('service:router'), '@service works in it')
    assert.strictEqual(createStore(context, Tally), tally, 'the same instance, every time')
    await a11yAudit()
  })

  test('the owner itself is a context: what service() uses', async function (assert) {
    const fromStore = createStore(this.owner, Tally)
    assert.strictEqual(service(this.owner, Tally), fromStore, 'one instance per owner')
    await a11yAudit()
  })

  test('a function makes the instance itself, once per context', async function (assert) {
    let calls = 0
    const make = () => {
      calls += 1
      return { label: `draft ${calls}` }
    }
    const a = { owner: this.owner }
    const b = { owner: this.owner }
    assert.strictEqual(createStore(a, make).label, 'draft 1')
    assert.strictEqual(createStore(a, make).label, 'draft 1', 'kept')
    assert.strictEqual(createStore(b, make).label, 'draft 2', 'another context, another one')
    assert.strictEqual(calls, 2)
    await a11yAudit()
  })

  test('destroying a plain context destroys what it holds', async function (assert) {
    const context = { owner: this.owner }
    createStore(context, Tally)
    destroy(context)
    await settled()
    assert.strictEqual(Tally.destroyed, 1)
    await a11yAudit()
  })

  test('any object is a context, with an owner or without: made when first asked for', async function (assert) {
    class Demo {
      two = 2
      made: unknown[]
      constructor(...args: unknown[]) {
        this.made = args
        assert.step('created')
      }
    }
    // A class of your own, with no owner: as ember-primitives' own test has it.
    class Host {
      get foo() {
        return createStore(this, Demo)
      }
    }

    const host = new Host()
    assert.verifySteps([], 'nothing is made until it is asked for')
    assert.strictEqual(host.foo.two, 2)
    assert.strictEqual(host.foo, host.foo, 'the same instance each time')
    assert.verifySteps(['created'])
    assert.deepEqual(host.foo.made, [], 'constructed with nothing, as there is no owner')
    assert.strictEqual(getOwner(host.foo), undefined, 'and given none')

    const demo = host.foo
    destroy(host)
    await settled()
    assert.true(isDestroyed(demo), 'destroyed with its context')
    await a11yAudit()
  })

  test('a context must be an object', async function (assert) {
    assert.throws(
      () => createStore('text' as unknown as object, Tally),
      /createStore\(\) needs an object/,
    )
    await a11yAudit()
  })

  test('findOwner and isOwner', async function (assert) {
    const owner = this.owner
    assert.true(isOwner(owner))
    assert.true(isOwner({ lookup() {} }), 'lookup() is all an owner needs')
    assert.false(isOwner({}))
    assert.false(isOwner(null))
    assert.strictEqual(findOwner(owner), owner, 'an owner is its own')
    assert.strictEqual(findOwner(this), owner, "the test context's owner")
    assert.strictEqual(findOwner({ owner }), owner, 'an owner property')
    assert.strictEqual(findOwner({}), undefined)
    assert.strictEqual(findOwner('text'), undefined)
    await a11yAudit()
  })
})
