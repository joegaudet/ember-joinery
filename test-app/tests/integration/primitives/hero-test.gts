import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
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

  test('a layered class of yours wins too, once your CSS names the joinery layer first', async function (assert) {
    // A page of its own, without joinery.css: an app on the primitives alone, with Tailwind's
    // layers, named as the guide's Primitives page says.
    const frame = document.createElement('iframe')
    frame.title = 'App'
    frame.style.cssText = 'width: 400px; height: 600px; border: 0'
    getRootElement().append(frame)
    const page = frame.contentDocument!
    const style = page.createElement('style')
    style.textContent = `
      @layer theme, base, joinery, components, utilities;
      @layer utilities { .h-80 { height: 20rem; } }
    `
    page.head.append(style)
    const body = page.body
    try {
      await render(
        <template>
          {{#in-element body}}
            <Hero @name="sized" class="h-80">Sized</Hero>
            <Hero @name="unsized">Unsized</Hero>
          {{/in-element}}
        </template>,
      )
      // Harnesses look in the test's own document, so read the frame's directly.
      const [sized, unsized] = [...body.querySelectorAll<HTMLElement>('[data-jn-hero]')]
      assert.strictEqual(unsized!.offsetHeight, 600, 'the rules are the frame’s')
      assert.strictEqual(sized!.offsetHeight, 320, 'the utility wins')
    } finally {
      frame.remove()
    }
    await a11yAudit()
  })

  test('rendered into an element not in a document yet, it gets its rules once that is', async function (assert) {
    // A shadow root of its own, so no earlier test has brought the rules in.
    const host = document.createElement('div')
    const shadow = host.attachShadow({ mode: 'open' })
    const detached = document.createElement('div')
    await render(
      <template>
        {{host}}
        {{#in-element detached}}<Hero>Content</Hero>{{/in-element}}
      </template>,
    )
    // Harnesses look in the document, which the element isn't in.
    const hero = detached.querySelector('[data-jn-hero]')!
    assert.strictEqual(shadow.adoptedStyleSheets.length, 0)

    shadow.append(detached)
    await new Promise(requestAnimationFrame)
    assert.strictEqual(shadow.adoptedStyleSheets.length, 1, 'adopted where it landed')
    assert.strictEqual(getComputedStyle(hero).position, 'relative')
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
