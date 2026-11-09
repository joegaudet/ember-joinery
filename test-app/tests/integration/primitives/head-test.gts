import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InHead } from '@ember-joinery/primitives/head'

class State {
  @tracked shown = false
  @tracked description = 'the first description'
}

module('Integration | primitives | head', function (hooks) {
  setupRenderingTest(hooks)

  test('renders its block into <head>, after what is there', async function (assert) {
    const before = document.head.lastElementChild
    await render(
      <template>
        <p>The page</p>
        <InHead>
          <meta name="test-in-head" content="hello" />
        </InHead>
      </template>,
    )
    // (Not named `meta`: a local of that name would be what `<meta>` renders.)
    const tag = document.head.querySelector('meta[name="test-in-head"]')
    assert.ok(tag, 'the meta tag is in <head>')
    assert.strictEqual(tag?.previousElementSibling, before, 'after what was there')
    assert.dom('meta').doesNotExist('nothing renders where InHead is')
    await a11yAudit()
  })

  test('takes its block out of <head> when it stops rendering', async function (assert) {
    const state = new State()
    await render(
      <template>
        {{#if state.shown}}
          <InHead>
            <meta name="test-in-head" content={{state.description}} />
          </InHead>
        {{/if}}
      </template>,
    )
    const findMeta = () => document.head.querySelector('meta[name="test-in-head"]')
    assert.notOk(findMeta(), 'not there before it renders')

    state.shown = true
    await settled()
    assert.strictEqual(findMeta()?.getAttribute('content'), 'the first description')

    state.description = 'a second description'
    await settled()
    assert.strictEqual(findMeta()?.getAttribute('content'), 'a second description', 'it updates')

    state.shown = false
    await settled()
    assert.notOk(findMeta(), 'gone with the block')
    await a11yAudit()
  })

  test('applies a stylesheet to the page while it renders', async function (assert) {
    const state = new State()
    state.shown = true
    await render(
      <template>
        <p class="test-in-head-styled">Styled from the head</p>
        {{#if state.shown}}
          <InHead>
            <style>
              .test-in-head-styled {
                letter-spacing: 3px;
              }
            </style>
          </InHead>
        {{/if}}
      </template>,
    )
    const paragraph = document.querySelector('.test-in-head-styled')!
    assert.strictEqual(getComputedStyle(paragraph).letterSpacing, '3px')
    state.shown = false
    await settled()
    assert.notStrictEqual(getComputedStyle(paragraph).letterSpacing, '3px', 'and stops')
    await a11yAudit()
  })
})
