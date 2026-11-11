import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import Component from '@glimmer/component'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { load } from '@ember-joinery/primitives/load'
import { ReadoutHarness } from 'test-app/tests/fixtures/primitives/readout'

const Hi = <template>hi</template>

class Named extends Component<{ Args: { name: string } }> {
  get greeting() {
    return `hello ${this.args.name}`
  }

  <template>{{this.greeting}}</template>
}

function rootHTML(): string {
  return (getRootElement() as Element).innerHTML.trim()
}

module('Integration | primitives | load', function (hooks) {
  setupRenderingTest(hooks)

  // The four cases ember-primitives tests, as it does.
  test('a component: success at once, no loading state', async function (assert) {
    const Loader = load(Hi)
    const step = (message: string) => assert.step(message)
    await render(
      <template>
        <Loader>
          <:loading>{{step "loading"}}</:loading>
          <:error>{{step "error"}}</:error>
          <:success as |Loaded|>{{step "success"}}<Loaded /></:success>
        </Loader>
      </template>,
    )
    assert.verifySteps(['success'])
    assert.strictEqual(rootHTML(), 'hi', 'no elements of its own')
    await a11yAudit()
  })

  test('a function returning a component', async function (assert) {
    const Loader = load(() => Hi)
    const step = (message: string) => assert.step(message)
    await render(
      <template>
        <Loader>
          <:loading>{{step "loading"}}</:loading>
          <:success as |Loaded|>{{step "success"}}<Loaded /></:success>
        </Loader>
      </template>,
    )
    assert.verifySteps(['success'])
    assert.strictEqual(rootHTML(), 'hi')
    await a11yAudit()
  })

  test('a resolved promise shows the loading block first', async function (assert) {
    const Loader = load(() => Promise.resolve(Hi))
    const step = (message: string) => assert.step(message)
    await render(
      <template>
        <Loader>
          <:loading>{{step "loading"}}</:loading>
          <:success as |Loaded|>{{step "success"}}<Loaded /></:success>
        </Loader>
      </template>,
    )
    assert.verifySteps(['loading', 'success'])
    assert.strictEqual(rootHTML(), 'hi')
    await a11yAudit()
  })

  test('an async function', async function (assert) {
    const Loader = load(async () => {
      await Promise.resolve()
      return Hi
    })
    await render(
      <template>
        <Loader>
          <:loading>loading</:loading>
          <:success as |Loaded|><Loaded /></:success>
        </Loader>
      </template>,
    )
    assert.strictEqual(rootHTML(), 'hi')
    await a11yAudit()
  })

  test('an import(): the module stands for its default export', async function (assert) {
    const Greeting = load<{ Args: { name?: string } }>(
      () => import('test-app/tests/fixtures/primitives/lazy-greeting'),
    )
    await render(
      <template>
        <Greeting>
          <:loading>Loading…</:loading>
          <:success as |LazyGreeting|><LazyGreeting @name="Ada" /></:success>
        </Greeting>
      </template>,
    )
    assert.strictEqual(new ReadoutHarness('greeting').text, 'Hello, Ada')
    await a11yAudit()
  })

  test('without a success block, the loaded component renders on its own', async function (assert) {
    const Greeting = load(() => import('test-app/tests/fixtures/primitives/lazy-greeting'))
    await render(<template><Greeting /></template>)
    assert.strictEqual(new ReadoutHarness('greeting').text, 'Hello, stranger')
    await a11yAudit()
  })

  test('a class component is the value, not a function to call', async function (assert) {
    const Loader = load<{ Args: { name: string } }>(Named)
    await render(
      <template>
        <Loader>
          <:error as |error|>{{error.reason}}</:error>
          <:success as |Loaded|><Loaded @name="class" /></:success>
        </Loader>
      </template>,
    )
    assert.strictEqual(rootHTML(), 'hello class')
    await a11yAudit()
  })

  test('a rejected promise yields the error', async function (assert) {
    const failure = new Error('the chunk did not load')
    const Loader = load(() => Promise.reject(failure))
    let seen: unknown
    const capture = (original: unknown) => {
      seen = original
    }
    await render(
      <template>
        <Loader>
          <:error as |error|>
            <p role="alert" data-test-jn="readout" data-test-jn-name="error">{{error.reason}}</p>
            {{capture error.original}}
          </:error>
        </Loader>
      </template>,
    )
    const error = new ReadoutHarness('error')
    assert.strictEqual(error.text, 'Promise rejected while waiting to resolve')
    assert.strictEqual(error.element.getAttribute('role'), 'alert')
    assert.strictEqual(seen, failure, 'with what it rejected with')
    await a11yAudit()
  })

  test('a function that throws yields the error', async function (assert) {
    const Loader = load(() => {
      throw new Error('broken')
    })
    await render(
      <template>
        <Loader>
          <:error as |error|>
            <p role="alert" data-test-jn="readout" data-test-jn-name="error">{{error.reason}}</p>
          </:error>
        </Loader>
      </template>,
    )
    assert.strictEqual(new ReadoutHarness('error').text, 'Passed function threw an exception')
    await a11yAudit()
  })

  test('the function runs once, on the first render, and the result is kept', async function (assert) {
    let calls = 0
    const Loader = load(() => {
      calls += 1
      return Promise.resolve(Hi)
    })
    assert.strictEqual(calls, 0, 'nothing loads until it renders')
    await render(
      <template>
        <Loader />
        <Loader />
      </template>,
    )
    assert.strictEqual(calls, 1)
    assert.dom().hasText('hi hi')

    await render(
      <template>
        <Loader><:loading>loading</:loading></Loader>
      </template>,
    )
    assert.strictEqual(rootHTML(), 'hi', 'a later render shows it at once')
    assert.strictEqual(calls, 1)
    await a11yAudit()
  })
})
