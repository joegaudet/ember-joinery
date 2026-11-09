import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, find, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { As, type TagName } from '@ember-joinery/primitives/as'

module('Integration | primitives | as', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders @tag, with the attributes, modifiers and block given', async function (assert) {
    let clicks = 0
    const count = () => (clicks += 1)
    await render(
      <template>
        <As @tag="button" type="button" class="go" {{on "click" count}}>Go</As>
      </template>,
    )
    assert.dom('button.go').hasAttribute('type', 'button').hasText('Go')
    await click('button')
    assert.strictEqual(clicks, 1, 'modifiers reach the element')
    await a11yAudit()
  })

  test('@as renders another tag in place of @tag', async function (assert) {
    await render(
      <template>
        <As @as="a" @tag="button" title="Details">Details</As>
        <As @tag="a" href="#more">More</As>
        <As @as="h2" @tag="div">Heading</As>
        <As id="plain">Plain</As>
      </template>,
    )
    assert.dom('a[title]').hasText('Details', '@as wins over @tag')
    assert.dom('button').doesNotExist()
    assert.dom('a[href]').hasText('More')
    assert.dom('h2').hasText('Heading')
    assert.dom('#plain').hasTagName('div', 'a div without either').hasText('Plain')
    await a11yAudit()
  })

  test('changing @as swaps the element, keeping the block', async function (assert) {
    class State {
      @tracked tag: TagName = 'span'
    }
    const state = new State()
    await render(
      <template>
        <As @as={{state.tag}} id="swap">Content</As>
      </template>,
    )
    assert.strictEqual(find('#swap')!.localName, 'span')

    state.tag = 'strong'
    await settled()
    assert.strictEqual(find('#swap')!.localName, 'strong')
    assert.dom('#swap').hasText('Content')
  })
})
