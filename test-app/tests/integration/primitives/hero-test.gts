import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Hero } from '@ember-joinery/primitives/hero'
import { Harness, HeroHarness } from '@ember-joinery/test-support'

class PageHarness extends Harness {
  static override component = 'page'
}

module('Integration | primitives | hero', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a positioned element the size of the viewport', async function (assert) {
    await render(
      <template>
        <Hero @name="landing" class="landing">
          <h1>Joinery</h1>
        </Hero>
      </template>,
    )
    const hero = new HeroHarness('landing')
    assert.dom(hero.element).hasTagName('div').hasClass('landing').hasText('Joinery')
    assert.dom(hero.element).hasAttribute('data-jn-hero')

    const style = getComputedStyle(hero.element)
    assert.strictEqual(style.position, 'relative', 'so what is inside can sit along its edges')
    // The test's container is scaled down, so compare its own CSS size with the viewport's.
    assert.strictEqual(hero.element.offsetWidth, document.documentElement.clientWidth)
    assert.strictEqual(hero.element.offsetHeight, window.innerHeight)
    await a11yAudit()
  })

  test('it uses the dynamic viewport units', async function (assert) {
    await render(
      <template>
        <Hero>Content</Hero>
      </template>,
    )
    const rule = [...document.adoptedStyleSheets]
      .flatMap(sheet => [...sheet.cssRules])
      .map(rule => rule.cssText)
      .join('\n')
    assert.true(rule.includes('100dvw') && rule.includes('100dvh'), 'width and height')
    assert.true(rule.includes('@layer joinery'), 'in the joinery layer')
    await a11yAudit()
  })

  test('app CSS wins over its size', async function (assert) {
    await render(
      <template>
        <style>
          .banner {
            width: 300px;
            height: 120px;
          }
        </style>
        <Hero class="banner">Content</Hero>
      </template>,
    )
    const hero = new HeroHarness()
    assert.strictEqual(hero.element.offsetWidth, 300)
    assert.strictEqual(hero.element.offsetHeight, 120)
    assert.false(hero.fillsViewport)
    await a11yAudit()
  })

  test('the harness reads its size; it is a wrapper, so parts inside belong to the page', async function (assert) {
    await render(
      <template>
        <div data-test-jn="page">
          <Hero>
            <p data-test-jn-part="headline">Big news</p>
          </Hero>
        </div>
      </template>,
    )
    const page = new PageHarness()
    const hero = page.find(HeroHarness)
    assert.dom(page.part('headline')).hasText('Big news')
    assert.true(hero.exists)
    const { width, height } = hero.size
    assert.true(width > 0 && height > 0)
    await a11yAudit()
  })
})
