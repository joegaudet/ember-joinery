import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { registerDestructor } from '@ember/destroyable'
import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Consume, Provide } from '@ember-joinery/primitives/dom-context'
import { Harness } from '@ember-joinery/test-support'
import { ReadoutHarness } from 'test-app/tests/fixtures/primitives/readout'

class Counter {
  static destroyed = 0
  @tracked count = 0
  increment = () => (this.count += 1)
  constructor() {
    registerDestructor(this, () => (Counter.destroyed += 1))
  }
}

class Greeting {
  greeting = 'hello'
  name = 'world'
}

class Visibility {
  @tracked shown = true
}

/** A string key leaves the data untyped, so this reads it as a Counter. */
const countOf = (data: unknown) => (data as Counter).count

const ConsumeCount: TOC<{ Args: { name: string } }> = <template>
  <Consume @key="store" as |context|>
    <output data-test-jn="readout" data-test-jn-name={{@name}}>{{countOf context.data}}</output>
  </Consume>
</template>

/** The counter's button: adds one. */
class AddHarness extends Harness {
  static override component = 'add'

  async click(): Promise<void> {
    await click(this.element)
  }
}

/** The text of the readout named `name`. */
const read = (name?: string) => new ReadoutHarness(name).text

module('Integration | primitives | dom-context', function (hooks) {
  setupRenderingTest(hooks)

  hooks.beforeEach(() => {
    Counter.destroyed = 0
  })

  test('a consumer reads the nearest provider of its key', async function (assert) {
    await render(
      <template>
        <Provide @data={{Greeting}}>
          <Consume @key={{Greeting}} as |context|>
            <p data-test-jn="readout">{{context.data.greeting}},
              {{context.data.name}}!</p>
          </Consume>
        </Provide>
      </template>,
    )
    const greeting = new ReadoutHarness()
    assert.strictEqual(greeting.text, 'hello, world!')
    const provider = greeting.element.parentElement!
    assert.strictEqual(provider.tagName, 'DIV', "inside the provider's element")
    assert.strictEqual(provider.style.display, 'contents', 'which adds nothing to the layout')
    await a11yAudit()
  })

  test('the data is reactive, and every consumer shares one instance', async function (assert) {
    await render(
      <template>
        <Provide @data={{Counter}}>
          <Consume @key={{Counter}} as |context|>
            <button type="button" data-test-jn="add" {{on "click" context.data.increment}}>
              Add one
            </button>
            <output data-test-jn="readout" data-test-jn-name="a">{{context.data.count}}</output>
          </Consume>
          <section>
            <Consume @key={{Counter}} as |context|>
              <output data-test-jn="readout" data-test-jn-name="b">{{context.data.count}}</output>
            </Consume>
          </section>
        </Provide>
      </template>,
    )
    const add = new AddHarness()
    await add.click()
    await add.click()
    assert.strictEqual(read('a'), '2')
    assert.strictEqual(read('b'), '2', 'a deeper consumer sees the same instance')
    await a11yAudit()
  })

  test('two providers with the same key are independent; the nearest wins', async function (assert) {
    const outer = Object.assign(new Counter(), { count: 1 })
    const inner = Object.assign(new Counter(), { count: 5 })
    await render(
      <template>
        <Provide @data={{outer}} @key="store">
          <ConsumeCount @name="outer" />
          <Provide @data={{inner}} @key="store">
            <ConsumeCount @name="inner" />
          </Provide>
        </Provide>
      </template>,
    )
    assert.strictEqual(read('outer'), '1')
    assert.strictEqual(read('inner'), '5', 'the nearest provider')
    await a11yAudit()
  })

  test('a function is called once per provider; its instance goes with the provider', async function (assert) {
    let made = 0
    const makeCounter = () => {
      made += 1
      return new Counter()
    }
    const visibility = new Visibility()
    await render(
      <template>
        {{#if visibility.shown}}
          <Provide @data={{makeCounter}}>
            <Consume @key={{makeCounter}} as |context|>
              <output>{{context.data.count}}</output>
            </Consume>
            <Consume @key={{makeCounter}} as |context|>{{context.data.count}}</Consume>
          </Provide>
        {{/if}}
      </template>,
    )
    assert.strictEqual(made, 1)
    visibility.shown = false
    await settled()
    assert.strictEqual(Counter.destroyed, 1, 'destroyed with its provider')
    await a11yAudit()
  })

  test('@element: another tag, or none', async function (assert) {
    await render(
      <template>
        <Provide @data={{Greeting}} @element="section">
          <Consume @key={{Greeting}} as |context|>
            <p data-test-jn="readout" data-test-jn-name="tag">{{context.data.name}}</p>
          </Consume>
        </Provide>
        <Provide @data={{Counter}} @element={{false}}>
          <Consume @key={{Counter}} as |context|>
            <p data-test-jn="readout" data-test-jn-name="none">{{context.data.count}}</p>
          </Consume>
        </Provide>
      </template>,
    )
    const tagged = new ReadoutHarness('tag')
    const none = new ReadoutHarness('none')
    assert.strictEqual(tagged.text, 'world')
    assert.strictEqual(tagged.element.parentElement!.tagName, 'SECTION', 'another tag')
    assert.strictEqual(none.text, '0')
    assert.strictEqual(
      none.element.parentElement,
      tagged.element.parentElement!.parentElement,
      'none: no element of its own',
    )
    await a11yAudit()
  })

  test('reading the data with no provider above throws', async function (assert) {
    let context: { readonly data: Greeting } | undefined
    const keep = (value: { readonly data: Greeting }) => {
      context = value
    }
    await render(
      <template>
        <Consume @key={{Greeting}} as |c|>{{keep c}}</Consume>
      </template>,
    )
    assert.throws(() => context!.data, /found no <Provide> above it/)
    await a11yAudit()
  })
})
