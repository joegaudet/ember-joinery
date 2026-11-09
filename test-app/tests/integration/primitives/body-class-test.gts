import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { bodyClass } from '@ember-joinery/primitives/body-class'

class State {
  @tracked shown = true
  @tracked classes: string | undefined = 'test-foo'
}

// Tests ported from ember-primitives' (originally ember-set-body-class's).
module('Integration | primitives | body-class', function (hooks) {
  setupRenderingTest(hooks)

  test('sets a class on <body>', async function (assert) {
    assert.dom(document.body).hasNoClass('test-foo')
    await render(<template>{{bodyClass "test-foo"}}</template>)
    assert.dom(document.body).hasClass('test-foo')
    await a11yAudit()
  })

  test("the last test's class didn't bleed into this one", async function (assert) {
    assert.dom(document.body).hasNoClass('test-foo')
    await a11yAudit()
  })

  test('takes the class off when the helper stops rendering', async function (assert) {
    const state = new State()
    await render(
      <template>
        {{#if state.shown}}
          {{bodyClass "test-foo"}}
        {{/if}}
      </template>,
    )
    assert.dom(document.body).hasClass('test-foo')

    state.shown = false
    await settled()
    assert.dom(document.body).hasNoClass('test-foo')

    state.shown = true
    await settled()
    assert.dom(document.body).hasClass('test-foo')
    await a11yAudit()
  })

  test('the classes are reactive, and several at once work', async function (assert) {
    const state = new State()
    await render(<template>{{bodyClass state.classes}}</template>)
    assert.dom(document.body).hasClass('test-foo')

    state.classes = 'test-bar  test-baz'
    await settled()
    assert.dom(document.body).hasNoClass('test-foo').hasClass('test-bar').hasClass('test-baz')

    state.classes = undefined
    await settled()
    assert.dom(document.body).hasNoClass('test-bar').hasNoClass('test-baz')
    await a11yAudit()
  })

  test('a class two helpers ask for stays until neither does', async function (assert) {
    const state = new State()
    await render(
      <template>
        {{bodyClass "test-foo"}}
        {{#if state.shown}}
          {{bodyClass "test-foo"}}
        {{/if}}
      </template>,
    )
    assert.dom(document.body).hasClass('test-foo')
    state.shown = false
    await settled()
    assert.dom(document.body).hasClass('test-foo', 'the other helper still asks for it')
    await a11yAudit()
  })

  module('a class <body> already has', function (hooks) {
    const existing = 'test-body-class-existing'

    hooks.beforeEach(() => document.body.classList.add(existing))
    hooks.afterEach(() => document.body.classList.remove(existing))

    test('is left alone', async function (assert) {
      const state = new State()
      await render(
        <template>
          {{#if state.shown}}
            {{bodyClass existing}}
            {{bodyClass "test-foo"}}
          {{/if}}
        </template>,
      )
      assert.dom(document.body).hasClass(existing).hasClass('test-foo')

      state.shown = false
      await settled()
      assert.dom(document.body).hasNoClass('test-foo')
      assert.dom(document.body).hasClass(existing, "the helper didn't add it, so it stays")
      await a11yAudit()
    })
  })
})
