import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { findAll, render, settled } from '@ember/test-helpers'
import { renderSettled } from '@ember/renderer'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { IncrementalEach } from '@ember-joinery/primitives/incremental-each'
import { Harness } from '@ember-joinery/test-support'

/** The list the tests render into: a `<ul>` whose rows are its `row` parts. */
class ListHarness extends Harness {
  static override component = 'list'

  get rows(): string[] {
    return this.parts('row').map(row => row.textContent!.trim())
  }

  get count(): number {
    return this.parts('row').length
  }
}

const range = (count: number, prefix = 'item') =>
  Array.from({ length: count }, (_, i) => `${prefix}-${i}`)

module('Integration | primitives | incremental-each', function (hooks) {
  setupRenderingTest(hooks)

  test('every item is rendered across the batches by the time the test settles', async function (assert) {
    const items = range(25)
    await render(
      <template>
        <ul data-test-jn="list">
          <IncrementalEach @items={{items}} @batchSize={{10}} as |item|>
            <li data-test-jn-part="row">{{item}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    const list = new ListHarness()
    assert.strictEqual(list.count, 25)
    assert.deepEqual(list.rows, items, 'in order')
    assert.strictEqual(findAll('ul > *').length, 25, 'and nothing of its own around them')
    await a11yAudit()
  })

  test('batches are 50 items by default', async function (assert) {
    const items = range(60)
    render(
      <template>
        {{! Inline, so 60 rows fit the test's container. }}
        <p data-test-jn="list">
          <IncrementalEach @items={{items}} as |item|>
            <span data-test-jn-part="row">{{item}}</span>
          </IncrementalEach>
        </p>
      </template>,
    )
    await renderSettled()
    const list = new ListHarness()
    assert.strictEqual(list.count, 50, 'the first batch')
    await settled()
    assert.strictEqual(list.count, 60)
    await a11yAudit()
  })

  test('it yields each item and its index', async function (assert) {
    const items = ['a', 'b', 'c']
    await render(
      <template>
        <ul data-test-jn="list">
          <IncrementalEach @items={{items}} @batchSize={{2}} as |item index|>
            <li data-test-jn-part="row">{{index}}: {{item}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    assert.deepEqual(new ListHarness().rows, ['0: a', '1: b', '2: c'])
    await a11yAudit()
  })

  test('an empty collection renders nothing', async function (assert) {
    const items: string[] = []
    await render(
      <template>
        <div data-test-jn="list">
          <IncrementalEach @items={{items}} as |item|>
            <p data-test-jn-part="row">{{item}}</p>
          </IncrementalEach>
        </div>
      </template>,
    )
    assert.strictEqual(new ListHarness().count, 0)
    await a11yAudit()
  })

  test('@initial="sync" (the default) puts the first batch in the first paint', async function (assert) {
    const items = range(25)
    render(
      <template>
        <ul data-test-jn="list">
          <IncrementalEach @items={{items}} @batchSize={{10}} as |item|>
            <li data-test-jn-part="row">{{item}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    await renderSettled()
    const list = new ListHarness()
    assert.strictEqual(list.count, 10, 'the first batch, at once')
    await settled()
    assert.strictEqual(list.count, 25, 'the rest fill in')
    await a11yAudit()
  })

  test('@initial="lazy" leaves the first paint empty', async function (assert) {
    const items = range(25)
    render(
      <template>
        <ul data-test-jn="list">
          <IncrementalEach @items={{items}} @batchSize={{10}} @initial="lazy" as |item|>
            <li data-test-jn-part="row">{{item}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    await renderSettled()
    const list = new ListHarness()
    assert.strictEqual(list.count, 0, 'nothing in the first paint')
    await settled()
    assert.strictEqual(list.count, 25)
    await a11yAudit()
  })

  test('new @items start again from the first batch', async function (assert) {
    class State {
      @tracked items = range(3, 'a')
    }
    const state = new State()
    await render(
      <template>
        <ul data-test-jn="list">
          <IncrementalEach @items={{state.items}} @batchSize={{2}} as |item|>
            <li data-test-jn-part="row">{{item}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    const list = new ListHarness()
    assert.strictEqual(list.count, 3)

    state.items = range(5, 'b')
    await renderSettled()
    assert.deepEqual(list.rows, ['b-0', 'b-1'], 'the new first batch at once, and nothing old')
    await settled()
    assert.deepEqual(list.rows, range(5, 'b'))
    await a11yAudit()
  })

  test('replacing @items again before a batch lands ends on the last collection', async function (assert) {
    class State {
      @tracked items = range(5, 'a')
    }
    const state = new State()
    await render(
      <template>
        <ul data-test-jn="list">
          <IncrementalEach @items={{state.items}} @batchSize={{2}} as |item|>
            <li data-test-jn-part="row">{{item}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    state.items = range(3, 'b')
    await renderSettled()
    state.items = range(4, 'c')
    await settled()
    assert.deepEqual(new ListHarness().rows, range(4, 'c'))
    await a11yAudit()
  })

  test('a change to one item re-renders that item only', async function (assert) {
    class Row {
      @tracked label: string
      constructor(label: string) {
        this.label = label
      }
    }
    const rows = [new Row('A'), new Row('B'), new Row('C')]
    const trace = (label: string) => assert.step(`render:${label}`)
    await render(
      <template>
        <ul data-test-jn="list">
          <IncrementalEach @items={{rows}} @batchSize={{10}} as |row|>
            {{trace row.label}}
            <li data-test-jn-part="row">{{row.label}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    assert.verifySteps(['render:A', 'render:B', 'render:C'])
    rows[1]!.label = 'B-changed'
    await settled()
    assert.verifySteps(['render:B-changed'])
    assert.deepEqual(new ListHarness().rows, ['A', 'B-changed', 'C'])
    await a11yAudit()
  })

  test('@onDone is called once the last batch is in, and again for new @items', async function (assert) {
    class State {
      @tracked items = range(25, 'a')
    }
    const state = new State()
    const onDone = () => assert.step(`done:${state.items[0]}:${new ListHarness().count}`)
    await render(
      <template>
        <ul data-test-jn="list">
          <IncrementalEach @items={{state.items}} @batchSize={{10}} @onDone={{onDone}} as |item|>
            <li data-test-jn-part="row">{{item}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    assert.verifySteps(['done:a-0:25'], 'once, with every row in')

    state.items = range(2, 'b')
    await settled()
    assert.verifySteps(['done:b-0:2'], 'again for the new collection')

    const first = range(3, 'c')
    state.items = first
    await settled()
    state.items = range(3, 'd')
    await settled()
    state.items = first
    await settled()
    assert.verifySteps(['done:c-0:3', 'done:d-0:3', 'done:c-0:3'], 'even for one shown before')
    await a11yAudit()
  })

  test('@onDone isn’t called for an empty collection', async function (assert) {
    const items: string[] = []
    const onDone = () => assert.step('done')
    await render(
      <template>
        <ul data-test-jn="list">
          <IncrementalEach @items={{items}} @onDone={{onDone}} as |item|>
            <li data-test-jn-part="row">{{item}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    assert.verifySteps([])
    await a11yAudit()
  })

  test('the parts it renders belong to the component around it', async function (assert) {
    const items = range(3)
    await render(
      <template>
        <ul data-test-jn="list" data-test-jn-name="outer">
          <IncrementalEach @items={{items}} @batchSize={{1}} as |item|>
            <li data-test-jn-part="row">{{item}}</li>
          </IncrementalEach>
        </ul>
      </template>,
    )
    assert.deepEqual(new ListHarness('outer').rows, items)
    await a11yAudit()
  })
})
