import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { destroy } from '@ember/destroyable'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InViewport, viewport, type InViewportMode } from '@ember-joinery/primitives/viewport'
import { Harness, scrollIntoView, waitForObservers } from '@ember-joinery/test-support'
import { BoxHarness } from 'test-app/tests/fixtures/primitives/box'

/** A scrolling box, with the slot below the fold and a marker at each end. */
const Scroller: TOC<{ Blocks: { default: [] } }> = <template>
  <div
    data-test-jn="scroller"
    tabindex="0"
    aria-label="Scrolling box"
    style="height: 120px; overflow: auto;"
  >
    <p data-test-jn-part="top">The top</p>
    <div style="height: 600px;">Scroll down</div>
    {{yield}}
    <p data-test-jn-part="bottom">The bottom</p>
    <div style="height: 600px;"></div>
  </div>
</template>

/**
 * The scrolling box: InViewport's element is its `placeholder` part, and what InViewport holds
 * is its `content` part (InViewport is transparent, so its parts are the box's).
 */
class ScrollerHarness extends Harness {
  static override component = 'scroller'

  get placeholder(): HTMLElement | null {
    return this.queryPart('placeholder')
  }

  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  async scrollToBottom(): Promise<void> {
    await scrollIntoView(this.part('bottom'))
  }

  async scrollToTop(): Promise<void> {
    await scrollIntoView(this.part('top'))
  }
}

module('Integration | primitives | viewport', function (hooks) {
  setupRenderingTest(hooks)

  module('InViewport', function () {
    test('renders an empty placeholder, with its attributes, until it scrolls in', async function (assert) {
      await render(
        <template>
          <Scroller>
            <InViewport class="slot" data-test-jn-part="placeholder">
              <p data-test-jn-part="content">Expensive content</p>
            </InViewport>
          </Scroller>
        </template>,
      )
      const scroller = new ScrollerHarness()
      assert.strictEqual(scroller.placeholder?.tagName, 'DIV', 'a div')
      assert.true(scroller.placeholder!.classList.contains('slot'), 'with the attributes')
      assert.strictEqual(scroller.content, null, 'not rendered below the fold')

      await scroller.scrollToBottom()
      assert.strictEqual(scroller.content?.textContent, 'Expensive content')
      assert.true(scroller.placeholder!.contains(scroller.content), 'rendered inside it')

      await scroller.scrollToTop()
      assert.notStrictEqual(scroller.content, null, 'and it stays')
      await a11yAudit()
    })

    test('@mode="replace" renders the block in place of the placeholder', async function (assert) {
      const mode: InViewportMode = 'replace'
      await render(
        <template>
          <Scroller>
            <InViewport @mode={{mode}} data-test-jn-part="placeholder">
              <p data-test-jn-part="content">Replaced</p>
            </InViewport>
          </Scroller>
        </template>,
      )
      const scroller = new ScrollerHarness()
      assert.notStrictEqual(scroller.placeholder, null)
      await scroller.scrollToBottom()
      assert.strictEqual(scroller.placeholder, null, 'the placeholder went')
      assert.strictEqual(scroller.content?.textContent, 'Replaced')
      assert.strictEqual(scroller.content?.parentElement, scroller.element, 'in its place')
      await a11yAudit()
    })

    test('@tagName, and content already in view renders at once', async function (assert) {
      await render(
        <template>
          <div data-test-jn="box">
            <InViewport @tagName="section" aria-label="Visible" data-test-jn-part="placeholder">
              <p data-test-jn-part="content">In view</p>
            </InViewport>
          </div>
        </template>,
      )
      const box = new BoxHarness()
      await box.scrollIntoView()
      const section = box.part('placeholder')
      assert.strictEqual(section.tagName, 'SECTION')
      assert.strictEqual(section.getAttribute('aria-label'), 'Visible')
      assert.strictEqual(box.part('content').parentElement, section, 'inside it')
      await a11yAudit()
    })

    test('@rootMargin renders it before it scrolls in', async function (assert) {
      await render(
        <template>
          <div
            data-test-jn="box"
            style="height: 100px; overflow: auto;"
            tabindex="0"
            aria-label="Box"
          >
            <div style="height: 100px;">First</div>
            <InViewport @rootMargin="5000px">
              <p data-test-jn-part="content">Early</p>
            </InViewport>
          </div>
        </template>,
      )
      const box = new BoxHarness()
      await box.scrollIntoView()
      assert.notStrictEqual(box.queryPart('content'), null, 'within the margin counts')
      await a11yAudit()
    })
  })

  module('viewport()', function () {
    test('shares one observer per owner, and calls back with entries', async function (assert) {
      class Context {
        constructor(public owner: object) {}
      }
      const observers = viewport(new Context(this.owner))
      assert.strictEqual(observers, viewport(this.owner), 'one per owner')

      await render(
        <template>
          <div data-test-jn="box" style="height: 50px;">Watched</div>
        </template>,
      )
      const box = new BoxHarness()
      await box.scrollIntoView()
      const target = box.element
      const entries: IntersectionObserverEntry[] = []
      const record = (entry: IntersectionObserverEntry) => entries.push(entry)
      observers.observe(target, record)
      await settled()
      assert.strictEqual(entries.length, 1, 'one entry at the start')
      assert.strictEqual(entries[0]!.target, target)
      assert.true(entries[0]!.isIntersecting)

      const other: IntersectionObserverEntry[] = []
      const recordOther = (entry: IntersectionObserverEntry) => other.push(entry)
      observers.observe(target, recordOther)
      await waitForObservers()
      assert.strictEqual(other.length, 1, 'a second callback hears where the element is now')
      assert.true(other[0]!.isIntersecting)
      assert.strictEqual(entries.length, 1, 'and the first hears nothing new')

      observers.unobserve(target, record)
      observers.unobserve(target, recordOther)
      const before = entries.length
      target.style.marginTop = '5000px'
      await waitForObservers()
      assert.strictEqual(entries.length, before, 'nothing after unobserve')
      target.style.marginTop = ''
      await a11yAudit()
    })

    test('options: a threshold reports each step', async function (assert) {
      await render(
        <template>
          <div
            data-test-jn="box"
            data-test-jn-name="scroller"
            style="height: 100px; overflow: auto;"
            tabindex="0"
            aria-label="Box"
          >
            <div style="height: 100px;"></div>
            <div data-test-jn="box" data-test-jn-name="target" style="height: 100px;">
              Half and whole
            </div>
            <div style="height: 300px;"></div>
          </div>
        </template>,
      )
      const scroller = new BoxHarness('scroller')
      await scroller.scrollIntoView()
      const ratios: number[] = []
      viewport(this.owner).observe(
        new BoxHarness('target').element,
        entry => ratios.push(Math.round(entry.intersectionRatio * 2) / 2),
        { threshold: [0, 0.5, 1] },
      )
      await settled()
      await scroller.scrollTo(50)
      await scroller.scrollTo(100)
      assert.deepEqual(ratios, [0, 0.5, 1])
      await a11yAudit()
    })

    test('the observers are disconnected with the owner', async function (assert) {
      await render(
        <template>
          <div data-test-jn="box" style="height: 50px;">Watched</div>
        </template>,
      )
      const box = new BoxHarness()
      await box.scrollIntoView()
      const target = box.element
      const owner = { lookup: () => undefined }
      let calls = 0
      viewport(owner).observe(target, () => (calls += 1))
      await settled()
      assert.strictEqual(calls, 1)

      destroy(owner)
      await settled()
      target.style.marginTop = '5000px'
      await waitForObservers()
      assert.strictEqual(calls, 1, 'nothing once the owner is gone')
      target.style.marginTop = ''
      await a11yAudit()
    })
  })
})
