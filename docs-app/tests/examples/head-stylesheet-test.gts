import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import HeadStylesheet from 'docs-app/examples/head-stylesheet'

class ContrastHarness extends Harness {
  static component = 'contrast'

  get isOn() {
    return this.part('toggle').getAttribute('aria-pressed') === 'true'
  }

  get outlined() {
    return getComputedStyle(this.part('text')).outlineStyle === 'solid'
  }

  async toggle() {
    await click(this.part('toggle'))
  }
}

const stylesheet = () => document.head.querySelector('style[data-test-head-stylesheet]')

module('Example | head-stylesheet', function (hooks) {
  setupRenderingTest(hooks)

  test('the stylesheet is in <head> while it is wanted', async function (assert) {
    await render(<template><HeadStylesheet /></template>)
    const contrast = new ContrastHarness()
    assert.false(contrast.isOn)
    assert.notOk(stylesheet())
    assert.false(contrast.outlined)

    await contrast.toggle()
    assert.true(contrast.isOn)
    assert.ok(stylesheet(), 'in <head>')
    assert.true(contrast.outlined, 'and styling the page')

    await contrast.toggle()
    assert.notOk(stylesheet(), 'gone again')
    assert.false(contrast.outlined)
    await a11yAudit()
  })
})
