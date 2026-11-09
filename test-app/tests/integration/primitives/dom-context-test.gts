import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { registerDestructor } from '@ember/destroyable'
import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Consume, Provide } from '@ember-joinery/primitives/dom-context'

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

const ConsumeCount: TOC<{ Args: { id: string } }> = <template>
  <Consume @key="store" as |context|>
    <output id={{@id}}>{{countOf context.data}}</output>
  </Consume>
</template>

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
            <p>{{context.data.greeting}},
              {{context.data.name}}!</p>
          </Consume>
        </Provide>
      </template>,
    )
    assert.dom('p').hasText('hello, world!')
    assert.dom('div[style="display: contents;"] p').exists("inside the provider's element")
    await a11yAudit()
  })

  test('the data is reactive, and every consumer shares one instance', async function (assert) {
    await render(
      <template>
        <Provide @data={{Counter}}>
          <Consume @key={{Counter}} as |context|>
            <button type="button" {{on "click" context.data.increment}}>Add one</button>
            <output id="a">{{context.data.count}}</output>
          </Consume>
          <section>
            <Consume @key={{Counter}} as |context|>
              <output id="b">{{context.data.count}}</output>
            </Consume>
          </section>
        </Provide>
      </template>,
    )
    await click('button')
    await click('button')
    assert.dom('#a').hasText('2')
    assert.dom('#b').hasText('2', 'a deeper consumer sees the same instance')
    await a11yAudit()
  })

  test('two providers with the same key are independent; the nearest wins', async function (assert) {
    const outer = Object.assign(new Counter(), { count: 1 })
    const inner = Object.assign(new Counter(), { count: 5 })
    await render(
      <template>
        <Provide @data={{outer}} @key="store">
          <ConsumeCount @id="outer" />
          <Provide @data={{inner}} @key="store">
            <ConsumeCount @id="inner" />
          </Provide>
        </Provide>
      </template>,
    )
    assert.dom('#outer').hasText('1')
    assert.dom('#inner').hasText('5', 'the nearest provider')
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
          <Consume @key={{Greeting}} as |context|><p id="tag">{{context.data.name}}</p></Consume>
        </Provide>
        <Provide @data={{Counter}} @element={{false}}>
          <Consume @key={{Counter}} as |context|><p id="none">{{context.data.count}}</p></Consume>
        </Provide>
      </template>,
    )
    assert.dom('section > #tag').hasText('world')
    assert.dom('#none').hasText('0')
    assert.dom('#none').hasNoAttribute('style')
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
