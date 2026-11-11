/* global ScrollToOptions -- a DOM type, which ESLint's browser globals don't list */
import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import Component from '@glimmer/component'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Scroller, type ScrollerControls } from '@ember-joinery/primitives/scroller'
import { Harness, ScrollerHarness } from '@ember-joinery/test-support'

/** A box of content twice as wide and several times as tall as the Scroller around it. */
const BigContent = <template>
  <div style="width: 200%; height: 1000px;">Content</div>
</template>

/**
 * The Scroller's functions on buttons outside it, as upstream's demo has them (a button inside
 * would scroll itself into view as it takes focus).
 */
class Demo extends Component {
  controls: ScrollerControls | undefined
  capture = (controls: ScrollerControls) => {
    this.controls = controls
  }
  scroll = (edge: keyof ScrollerControls) => this.controls?.[edge]()

  <template>
    <Scroller @name="demo" style="height: 200px; width: 300px;" as |s|>
      {{this.capture s}}
      <BigContent />
    </Scroller>
    <button type="button" id="left" {{on "click" (fn this.scroll "scrollToLeft")}}>Left</button>
    <button type="button" id="right" {{on "click" (fn this.scroll "scrollToRight")}}>Right</button>
    <button type="button" id="top" {{on "click" (fn this.scroll "scrollToTop")}}>Top</button>
    <button
      type="button"
      id="bottom"
      {{on "click" (fn this.scroll "scrollToBottom")}}
    >Bottom</button>
    <button type="button" id="start" {{on "click" (fn this.scroll "scrollToStart")}}>Start</button>
    <button type="button" id="end" {{on "click" (fn this.scroll "scrollToEnd")}}>End</button>
  </template>
}

class PanelHarness extends Harness {
  static override component = 'panel'
}

/**
 * Holds each `scrollTo` on `element` for `count` animation frames before it sets off, as a
 * smooth scroll on a busy page can take a while to start.
 */
function holdScrollTo(element: HTMLElement, count: number): void {
  const original = element.scrollTo.bind(element)
  element.scrollTo = ((options: ScrollToOptions) => {
    void (async () => {
      for (let i = 0; i < count; i++) await new Promise(requestAnimationFrame)
      original(options)
    })()
  }) as typeof element.scrollTo
}

module('Integration | primitives | scroller', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a scrollable element a keyboard can reach', async function (assert) {
    await render(<template><Demo /></template>)
    const scroller = new ScrollerHarness('demo')

    assert.dom(scroller.element).hasTagName('div').hasAttribute('data-jn-scroller')
    assert.dom(scroller.element).hasAttribute('tabindex', '0')
    assert.true(scroller.isFocusable)
    assert.strictEqual(getComputedStyle(scroller.element).overflow, 'auto', 'it scrolls')
    assert.true(scroller.isAtTop && scroller.isAtLeft, 'it starts at the top left')
    assert.true(scroller.range.top > 0 && scroller.range.left > 0, 'the content overflows')

    await scroller.focus()
    assert.dom(scroller.element).isFocused()
    await a11yAudit() // scrollable-region-focusable: the tabindex lets a keyboard scroll it
  })

  test('each function scrolls to its edge, in the next frame', async function (assert) {
    await render(<template><Demo /></template>)
    const scroller = new ScrollerHarness('demo')
    const { top, left } = scroller.range

    await click('#right')
    assert.deepEqual(scroller.position, { top: 0, left }, 'right')
    await click('#bottom')
    assert.deepEqual(scroller.position, { top, left }, 'bottom, keeping the left')
    assert.true(scroller.isAtBottom && scroller.isAtRight)
    await click('#left')
    assert.deepEqual(scroller.position, { top, left: 0 }, 'left')
    await click('#top')
    assert.deepEqual(scroller.position, { top: 0, left: 0 }, 'top')
    await click('#end')
    assert.true(scroller.isAtRight, 'the end is the right, left to right')
    await click('#start')
    assert.true(scroller.isAtLeft, 'and the start the left')
    await a11yAudit()
  })

  test('a call in each new row follows the content, once it has rendered', async function (assert) {
    class Feed {
      @tracked lines = ['one']
    }
    // Not `log`, which in a template is Ember's own `log` helper.
    const feed = new Feed()
    await render(
      <template>
        <Scroller @name="log" style="height: 60px;" as |s|>
          {{#each feed.lines as |line|}}
            <p style="height: 40px; margin: 0;">{{line}}</p>
            {{! Each row that renders calls it, so a new row scrolls the log down. }}
            {{(s.scrollToBottom)}}
          {{/each}}
        </Scroller>
      </template>,
    )
    const scroller = new ScrollerHarness('log')
    assert.strictEqual(scroller.range.top, 0, 'nothing to scroll yet')

    feed.lines = [...feed.lines, 'two', 'three', 'four']
    await settled()
    assert.true(scroller.range.top > 0)
    assert.true(scroller.isAtBottom, 'it followed the new lines')
    await a11yAudit()
  })

  test('a later call in the same frame wins', async function (assert) {
    await render(<template><Demo /></template>)
    const scroller = new ScrollerHarness('demo')
    const bottom = document.querySelector<HTMLButtonElement>('#bottom')!
    const top = document.querySelector<HTMLButtonElement>('#top')!

    bottom.click()
    top.click()
    await settled()
    assert.true(scroller.isAtTop, 'only the last one ran')
    await a11yAudit()
  })

  test('a smooth scroll that is slow to set off is waited for, not taken for one that ended', async function (assert) {
    await render(
      <template>
        <style>
          [data-test-jn-name="demo"] {
            scroll-behavior: smooth;
          }
        </style>
        <Demo />
      </template>,
    )
    const scroller = new ScrollerHarness('demo')
    assert.strictEqual(getComputedStyle(scroller.element).scrollBehavior, 'smooth')
    // Longer than the three still frames that count as the end of a scroll that goes nowhere.
    holdScrollTo(scroller.element, 8)

    await click('#bottom')
    assert.true(scroller.isAtBottom, 'settled() waited for the scroll to start, then to end')
    await click('#right')
    assert.true(scroller.isAtRight && scroller.isAtBottom)
    await click('#top')
    assert.true(scroller.isAtTop, 'and back')
    await a11yAudit()
  })

  test('right to left: left and right are the sides they name, start and end follow the text', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Demo />
        </DirectionProvider>
      </template>,
    )
    const scroller = new ScrollerHarness('demo')
    assert.true(scroller.isAtRight, 'right to left, it starts at the right')

    await click('#left')
    assert.true(scroller.isAtLeft, 'left')
    assert.strictEqual(scroller.position.left, -scroller.range.left, 'scrollLeft is negative')
    await click('#right')
    assert.true(scroller.isAtRight, 'right')
    await click('#end')
    assert.true(scroller.isAtLeft, 'the end is the left, right to left')
    await click('#start')
    assert.true(scroller.isAtRight, 'and the start the right')
    await a11yAudit()
  })

  test('it is a wrapper: a part inside it belongs to the component around it', async function (assert) {
    await render(
      <template>
        <section data-test-jn="panel" aria-label="Panel">
          <Scroller style="height: 40px;">
            <p data-test-jn-part="body" style="height: 200px;">Body</p>
          </Scroller>
        </section>
      </template>,
    )
    const panel = new PanelHarness()
    assert.dom(panel.part('body')).hasText('Body', 'the panel finds its part in the Scroller')
    const scroller = panel.find(ScrollerHarness)
    assert.true(scroller.exists, 'and the Scroller is inside the panel')
    assert.deepEqual(scroller.parts('body'), [], 'the Scroller has no parts of its own')
    await a11yAudit()
  })

  test('the harness scrolls it as a user would', async function (assert) {
    await render(<template><Demo /></template>)
    const scroller = new ScrollerHarness('demo')

    await scroller.scrollTo({ top: 50 })
    assert.strictEqual(scroller.position.top, 50)
    assert.false(scroller.isAtTop || scroller.isAtBottom)
    await scroller.scrollTo({ top: scroller.range.top, left: scroller.range.left })
    assert.true(scroller.isAtBottom && scroller.isAtRight)
    await a11yAudit()
  })

  test('what is inside keeps its own styles: joinery.css leaves a wrapper’s content alone', async function (assert) {
    await render(
      <template>
        <Scroller style="height: 40px;">
          <p id="inside">Body</p>
        </Scroller>
        <p id="outside">Body</p>
      </template>,
    )
    const inside = getComputedStyle(document.querySelector('#inside')!)
    const outside = getComputedStyle(document.querySelector('#outside')!)
    assert.strictEqual(inside.marginTop, outside.marginTop, 'the paragraph keeps its margin')
    assert.notStrictEqual(inside.marginTop, '0px')
    await a11yAudit()
  })

  test('app CSS wins over its own', async function (assert) {
    await render(
      <template>
        <style>
          .clipped {
            overflow: hidden;
          }
        </style>
        <Scroller class="clipped" style="height: 40px;">
          <p style="height: 200px;">Body</p>
        </Scroller>
      </template>,
    )
    const scroller = new ScrollerHarness()
    assert.strictEqual(getComputedStyle(scroller.element).overflow, 'hidden')
    await a11yAudit()
  })
})
