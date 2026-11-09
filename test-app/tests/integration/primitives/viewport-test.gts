import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render, settled } from '@ember/test-helpers'
import { destroy } from '@ember/destroyable'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InViewport, viewport, type InViewportMode } from '@ember-joinery/primitives/viewport'
import { scrollIntoView, waitForObservers } from '@ember-joinery/test-support'

/** A scrolling box, with the slot below the fold and a marker at each end. */
const Scroller: TOC<{ Blocks: { default: [] } }> = <template>
  <div id="scroller" tabindex="0" aria-label="Scrolling box" style="height: 120px; overflow: auto;">
    <p id="top">The top</p>
    <div style="height: 600px;">Scroll down</div>
    {{yield}}
    <p id="bottom">The bottom</p>
    <div style="height: 600px;"></div>
  </div>
</template>

module('Integration | primitives | viewport', function (hooks) {
  setupRenderingTest(hooks)

  module('InViewport', function () {
    test('renders an empty placeholder, with its attributes, until it scrolls in', async function (assert) {
      await render(
        <template>
          <Scroller>
            <InViewport class="slot" data-test-slot>
              <p class="content">Expensive content</p>
            </InViewport>
          </Scroller>
        </template>,
      )
      assert.dom('div.slot[data-test-slot]').exists('a div, with the attributes')
      assert.dom('.content').doesNotExist('not rendered below the fold')

      await scrollIntoView('#bottom')
      assert.dom('.slot .content').hasText('Expensive content', 'rendered inside it')

      await scrollIntoView('#top')
      assert.dom('.content').exists('and it stays')
      await a11yAudit()
    })

    test('@mode="replace" renders the block in place of the placeholder', async function (assert) {
      const mode: InViewportMode = 'replace'
      await render(
        <template>
          <Scroller>
            <InViewport @mode={{mode}} class="slot">
              <p class="content">Replaced</p>
            </InViewport>
          </Scroller>
        </template>,
      )
      assert.dom('.slot').exists()
      await scrollIntoView('#bottom')
      assert.dom('.slot').doesNotExist('the placeholder went')
      assert.dom('#scroller > .content').hasText('Replaced')
      await a11yAudit()
    })

    test('@tagName, and content already in view renders at once', async function (assert) {
      await render(
        <template>
          <InViewport @tagName="section" aria-label="Visible">
            <p class="content">In view</p>
          </InViewport>
        </template>,
      )
      find('section')!.scrollIntoView()
      await settled() // the observer's first report is waited for
      assert.dom('section[aria-label="Visible"] .content').hasText('In view')
      await a11yAudit()
    })

    test('@rootMargin renders it before it scrolls in', async function (assert) {
      await render(
        <template>
          <div style="height: 100px; overflow: auto;" tabindex="0" aria-label="Box" id="box">
            <div style="height: 100px;" id="first">First</div>
            <InViewport @rootMargin="5000px" class="slot">
              <p class="content">Early</p>
            </InViewport>
          </div>
        </template>,
      )
      await scrollIntoView('#first')
      assert.dom('.content').exists('within the margin counts')
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
          <div id="target" style="height: 50px;">Watched</div>
        </template>,
      )
      const target = find('#target') as HTMLElement
      target.scrollIntoView()
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
          <div id="box" style="height: 100px; overflow: auto;" tabindex="0" aria-label="Box">
            <div style="height: 100px;"></div>
            <div id="target" style="height: 100px;">Half and whole</div>
            <div style="height: 300px;"></div>
          </div>
        </template>,
      )
      find('#box')!.scrollIntoView()
      const ratios: number[] = []
      viewport(this.owner).observe(
        find('#target')!,
        entry => ratios.push(Math.round(entry.intersectionRatio * 2) / 2),
        { threshold: [0, 0.5, 1] },
      )
      await settled()
      find('#box')!.scrollTop = 50
      await waitForObservers()
      find('#box')!.scrollTop = 100
      await waitForObservers()
      assert.deepEqual(ratios, [0, 0.5, 1])
      await a11yAudit()
    })

    test('the observers are disconnected with the owner', async function (assert) {
      await render(
        <template>
          <div id="target" style="height: 50px;">Watched</div>
        </template>,
      )
      const target = find('#target') as HTMLElement
      target.scrollIntoView()
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
