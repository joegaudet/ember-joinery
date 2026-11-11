import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { HeroHarness } from '@ember-joinery/test-support'
import HeroDemo from 'docs-app/examples/hero-demo'

module('Example | hero-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a hero, sized by its classes to fit the preview', async function (assert) {
    await render(<template><HeroDemo /></template>)
    const hero = new HeroHarness()
    assert.dom(hero.element).containsText('Joinery')
    assert.false(hero.fillsViewport, 'its classes win over the viewport size')
    assert.strictEqual(hero.element.offsetHeight, 320, 'h-80')
    assert.strictEqual(getComputedStyle(hero.element).position, 'relative')
    await a11yAudit()
  })
})
