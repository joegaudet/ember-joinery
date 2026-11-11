import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { StickyFooter } from '@ember-joinery/primitives/sticky-footer'
import { Harness, StickyFooterHarness } from '@ember-joinery/test-support'

class Content {
  @tracked paragraphs = 1
}

const range = (count: number) => Array.from({ length: count }, (_, i) => i + 1)

class AppHarness extends Harness {
  static override component = 'app'
}

module('Integration | primitives | sticky-footer', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders the content and the footer, each in its own element', async function (assert) {
    await render(
      <template>
        <StickyFooter @name="page">
          <:content>the content</:content>
          <:footer>the footer</:footer>
        </StickyFooter>
      </template>,
    )
    const layout = new StickyFooterHarness('page')
    assert.dom(layout.element).hasAttribute('data-jn-sticky-footer')
    assert.dom(layout.content).hasText('the content').hasAttribute('data-jn-sticky-footer-content')
    assert.dom(layout.footer).hasText('the footer').hasAttribute('data-jn-sticky-footer-footer')
    assert
      .dom(layout.content.parentElement)
      .hasAttribute('data-jn-sticky-footer-container', '', 'both in the grid')
    await a11yAudit()
  })

  test('the footer is at the bottom with little content, and below the content with a lot', async function (assert) {
    const content = new Content()
    await render(
      <template>
        <div style="height: 200px;">
          <StickyFooter>
            <:content>
              <main>
                {{#each (range content.paragraphs)}}
                  <p style="height: 60px; margin: 0;">A paragraph</p>
                {{/each}}
              </main>
            </:content>
            <:footer><footer style="height: 30px;">This is the footer</footer></:footer>
          </StickyFooter>
        </div>
      </template>,
    )
    const layout = new StickyFooterHarness()
    const wrapper = getComputedStyle(layout.element)
    assert.strictEqual(wrapper.overflowY, 'auto', 'the wrapper scrolls')
    assert.strictEqual(layout.element.offsetHeight, 200, 'and fills its parent')
    assert.strictEqual(getComputedStyle(layout.content.parentElement!).display, 'grid')

    assert.false(layout.overflows)
    assert.true(layout.isFooterAtBottom, 'little content: the footer is at the bottom')

    content.paragraphs = 6
    await settled()
    assert.true(layout.overflows, 'a lot of content: it scrolls')
    assert.false(layout.isFooterVisible, 'the footer is below the content, out of view')

    await layout.scrollToEnd()
    assert.true(layout.isFooterVisible)
    assert.true(layout.isFooterAtBottom, 'and comes into view at the end')

    await layout.scrollToTop()
    content.paragraphs = 1
    await settled()
    assert.true(layout.isFooterAtBottom, 'back at the bottom')
    await a11yAudit()
  })

  test('it is a wrapper: parts inside it belong to the component around it', async function (assert) {
    await render(
      <template>
        <div data-test-jn="app">
          <StickyFooter>
            <:content><p data-test-jn-part="body">Body</p></:content>
            <:footer><p data-test-jn-part="credits">Credits</p></:footer>
          </StickyFooter>
        </div>
      </template>,
    )
    const app = new AppHarness()
    assert.dom(app.part('body')).hasText('Body')
    assert.dom(app.part('credits')).hasText('Credits')
    assert.true(app.find(StickyFooterHarness).exists)
    await a11yAudit()
  })

  test('app CSS wins over its rules', async function (assert) {
    await render(
      <template>
        <style>
          .hidden-overflow {
            overflow: hidden;
          }
        </style>
        <StickyFooter class="hidden-overflow">
          <:content>content</:content>
          <:footer>footer</:footer>
        </StickyFooter>
      </template>,
    )
    const layout = new StickyFooterHarness()
    assert.strictEqual(getComputedStyle(layout.element).overflowY, 'hidden')
    await a11yAudit()
  })
})
