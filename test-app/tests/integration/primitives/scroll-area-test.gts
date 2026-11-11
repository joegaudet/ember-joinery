import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  ScrollArea,
  ScrollAreaScrollbar,
  ScrollAreaThumb,
  scrollFromPointer,
  thumbOffset,
  thumbSize,
  type ScrollAreaType,
} from '@ember-joinery/primitives/scroll-area'
import { ScrollAreaHarness } from '@ember-joinery/test-support'

const ITEMS = Array.from({ length: 30 }, (_, i) => `Item ${i + 1}`)
const AREA = 'width: 200px; height: 100px'
// Joinery's primitives have no styles: the tests give the scrollbar and thumb a size.
const BAR = 'display: flex; padding: 1px; width: 10px'
const HBAR = 'display: flex; flex-direction: column; padding: 1px; height: 10px'
const THUMB = 'flex: 1; background: gray'

module('Integration | primitives | scroll-area', function (hooks) {
  setupRenderingTest(hooks)

  test('the viewport scrolls with its own scrollbars hidden, and the area draws its own', async function (assert) {
    await render(
      <template>
        <ScrollArea @name="list" @type="always" style={{AREA}} as |s|>
          <s.Viewport style="height: 100%">
            {{#each ITEMS as |item|}}<div style="height: 20px">{{item}}</div>{{/each}}
          </s.Viewport>
          <s.Scrollbar style={{BAR}} as |bar|><bar.Thumb style={{THUMB}} /></s.Scrollbar>
        </ScrollArea>
      </template>,
    )
    const list = new ScrollAreaHarness('list')
    const viewport = list.viewport
    assert.dom(list.element).hasAttribute('data-slot', 'scroll-area')
    assert.strictEqual(getComputedStyle(list.element).position, 'relative')
    assert.strictEqual(getComputedStyle(viewport).overflowY, 'scroll')
    assert.strictEqual(getComputedStyle(viewport).overflowX, 'hidden', 'no horizontal scrollbar')
    assert.strictEqual(getComputedStyle(viewport).scrollbarWidth, 'none')
    assert.dom(viewport).hasAttribute('tabindex', '0', 'a keyboard can scroll it')
    assert.ok(list.maxScrollTop >= 500, 'the content is taller than the viewport')

    const bar = list.scrollbar()!
    assert
      .dom(bar)
      .hasAttribute('data-orientation', 'vertical')
      .hasAttribute('data-state', 'visible')
    assert.strictEqual(getComputedStyle(bar).position, 'absolute')
    assert.strictEqual(getComputedStyle(bar).right, '0px', 'along the end')
    assert.strictEqual(getComputedStyle(bar).top, '0px')
    const thumb = list.thumb()!
    assert.dom(thumb).hasAttribute('data-state', 'visible')
    const track = bar.clientHeight - 2
    const share = viewport.clientHeight / viewport.scrollHeight
    assert.strictEqual(
      Math.round(list.thumbLength()),
      Math.round(Math.max(track * share, 18)),
      'the thumb shows the share of the content in view',
    )

    await list.scrollTo({ top: list.maxScrollTop / 2 })
    assert.strictEqual(
      Math.round(list.thumbOffset()),
      Math.round((track - list.thumbLength()) / 2),
      'halfway down, halfway along',
    )
    await a11yAudit()
  })

  test('hover: the scrollbar shows while the pointer is over the area, and the hide delay after', async function (assert) {
    await render(
      <template>
        <ScrollArea @name="hover" @scrollHideDelay={{50}} style={{AREA}} as |s|>
          <s.Viewport style="height: 100%">
            {{#each ITEMS as |item|}}<div style="height: 20px">{{item}}</div>{{/each}}
          </s.Viewport>
          <s.Scrollbar style={{BAR}} as |bar|><bar.Thumb style={{THUMB}} /></s.Scrollbar>
        </ScrollArea>
      </template>,
    )
    const area = new ScrollAreaHarness('hover')
    assert.strictEqual(area.scrollbar(), null, 'hidden until the pointer comes')
    assert.strictEqual(getComputedStyle(area.viewport).overflowY, 'scroll', 'it scrolls anyway')
    await area.hover()
    assert.true(area.isScrollbarVisible())
    await area.unhover()
    assert.strictEqual(area.scrollbar(), null, 'gone once the delay is up')
    await a11yAudit()
  })

  test('hover and auto: no scrollbar when the content fits', async function (assert) {
    await render(
      <template>
        <ScrollArea @name="fits" @type="auto" style={{AREA}} as |s|>
          <s.Viewport style="height: 100%"><div>Short</div></s.Viewport>
          <s.Scrollbar style={{BAR}} as |bar|><bar.Thumb style={{THUMB}} /></s.Scrollbar>
        </ScrollArea>
        <ScrollArea @name="long" @type="auto" style={{AREA}} as |s|>
          <s.Viewport style="height: 100%">
            {{#each ITEMS as |item|}}<div style="height: 20px">{{item}}</div>{{/each}}
          </s.Viewport>
          <s.Scrollbar style={{BAR}} as |bar|><bar.Thumb style={{THUMB}} /></s.Scrollbar>
        </ScrollArea>
      </template>,
    )
    const fits = new ScrollAreaHarness('fits')
    await fits.hover()
    assert.strictEqual(fits.scrollbar(), null)
    assert.true(new ScrollAreaHarness('long').isScrollbarVisible(), 'auto shows it without hover')
    await a11yAudit()
  })

  test('scroll: the scrollbar shows while scrolling, and goes once it stops', async function (assert) {
    await render(
      <template>
        <ScrollArea @name="scroll" @type="scroll" @scrollHideDelay={{50}} style={{AREA}} as |s|>
          <s.Viewport style="height: 100%">
            {{#each ITEMS as |item|}}<div style="height: 20px">{{item}}</div>{{/each}}
          </s.Viewport>
          <s.Scrollbar style={{BAR}} as |bar|><bar.Thumb style={{THUMB}} /></s.Scrollbar>
        </ScrollArea>
      </template>,
    )
    const area = new ScrollAreaHarness('scroll')
    assert.strictEqual(area.scrollbar(), null)
    area.viewport.scrollTop = 100
    await new Promise(resolve => requestAnimationFrame(resolve))
    assert.true(area.isScrollbarVisible(), 'shown while scrolling')
    await settled()
    assert.strictEqual(area.scrollbar(), null, 'hidden after the scroll ends and the delay')
    await a11yAudit()
  })

  test('the thumb drags, the track jumps, and the wheel over the scrollbar scrolls', async function (assert) {
    await render(
      <template>
        <ScrollArea @name="drag" @type="always" style={{AREA}} as |s|>
          <s.Viewport style="height: 100%">
            {{#each ITEMS as |item|}}<div style="height: 20px">{{item}}</div>{{/each}}
          </s.Viewport>
          <s.Scrollbar style={{BAR}} as |bar|><bar.Thumb style={{THUMB}} /></s.Scrollbar>
        </ScrollArea>
      </template>,
    )
    const area = new ScrollAreaHarness('drag')
    const track = area.scrollbar()!.clientHeight - 2
    await area.dragThumb('vertical', 20)
    assert.strictEqual(
      Math.round(area.scrollTop),
      Math.round((20 / (track - area.thumbLength())) * area.maxScrollTop),
      'the content moves as far as the thumb, in proportion',
    )
    await area.pressTrack('vertical', 1)
    assert.strictEqual(area.scrollTop, area.maxScrollTop, 'pressed at the end: scrolled to the end')
    await area.scrollTo({ top: 0 })
    assert.true(await area.wheel('vertical', 60), "the page doesn't scroll")
    assert.strictEqual(area.scrollTop, 60)
    await a11yAudit()
  })

  test('two scrollbars and the corner between them', async function (assert) {
    await render(
      <template>
        <ScrollArea @name="both" @type="always" style={{AREA}} as |s|>
          <s.Viewport style="height: 100%">
            <div style="width: 600px">
              {{#each ITEMS as |item|}}<div style="height: 20px">{{item}}</div>{{/each}}
            </div>
          </s.Viewport>
          <s.Scrollbar style={{BAR}} as |bar|><bar.Thumb style={{THUMB}} /></s.Scrollbar>
          <s.Scrollbar @orientation="horizontal" style={{HBAR}} as |bar|>
            <bar.Thumb style={{THUMB}} />
          </s.Scrollbar>
          <s.Corner />
        </ScrollArea>
      </template>,
    )
    const area = new ScrollAreaHarness('both')
    assert.strictEqual(getComputedStyle(area.viewport).overflowX, 'scroll')
    assert.true(area.isScrollbarVisible('horizontal'))
    const corner = area.corner!
    assert.ok(corner, 'the corner is there')
    const vertical = area.scrollbar('vertical')!
    const horizontal = area.scrollbar('horizontal')!
    assert.strictEqual(corner.offsetWidth, vertical.offsetWidth, "the vertical scrollbar's width")
    assert.strictEqual(corner.offsetHeight, horizontal.offsetHeight)
    assert.strictEqual(
      vertical.offsetHeight,
      area.element.clientHeight - horizontal.offsetHeight,
      'the vertical scrollbar stops at the corner',
    )
    assert.strictEqual(
      horizontal.offsetWidth,
      area.element.clientWidth - vertical.offsetWidth,
      'and the horizontal one',
    )
    await area.scrollTo({ left: 200 })
    assert.ok(area.thumbOffset('horizontal') > 0)
    await a11yAudit()
  })

  test('right to left, the vertical scrollbar is on the left, and the horizontal thumb starts on the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <ScrollArea @name="rtl" @type="always" style={{AREA}} as |s|>
            <s.Viewport style="height: 100%">
              <div style="width: 600px">
                {{#each ITEMS as |item|}}<div style="height: 20px">{{item}}</div>{{/each}}
              </div>
            </s.Viewport>
            <s.Scrollbar style={{BAR}} as |bar|><bar.Thumb style={{THUMB}} /></s.Scrollbar>
            <s.Scrollbar @orientation="horizontal" style={{HBAR}} as |bar|>
              <bar.Thumb style={{THUMB}} />
            </s.Scrollbar>
          </ScrollArea>
        </DirectionProvider>
      </template>,
    )
    const area = new ScrollAreaHarness('rtl')
    assert.strictEqual(getComputedStyle(area.scrollbar('vertical')!).left, '0px', 'on the left')
    const bar = area.scrollbar('horizontal')!
    const track = bar.clientWidth - 2
    const length = area.thumbLength('horizontal')
    assert.strictEqual(
      Math.round(area.thumbOffset('horizontal')),
      Math.round(track - length),
      'scrolled to the start, which is the right',
    )
    await area.scrollTo({ left: -area.maxScrollLeft })
    assert.strictEqual(Math.round(area.thumbOffset('horizontal')), 0, 'and the end is on the left')
    await a11yAudit()
  })

  test('a scrollbar on its own finds its area, from inside the viewport', async function (assert) {
    class State {
      @tracked type: ScrollAreaType = 'always'
    }
    const state = new State()
    await render(
      <template>
        <ScrollArea @name="own" @type={{state.type}} style={{AREA}} as |s|>
          <s.Viewport style="height: 100%">
            <div style="width: 600px; height: 20px">Wide</div>
            <ScrollAreaScrollbar @orientation="horizontal" style={{HBAR}}>
              <ScrollAreaThumb style={{THUMB}} />
            </ScrollAreaScrollbar>
          </s.Viewport>
        </ScrollArea>
      </template>,
    )
    const area = new ScrollAreaHarness('own')
    assert.true(area.isScrollbarVisible('horizontal'))
    assert.strictEqual(getComputedStyle(area.viewport).overflowY, 'hidden')
    const bar = area.scrollbar('horizontal')!
    assert.strictEqual(bar.offsetParent, area.element, 'placed against the area, not the content')
    assert.strictEqual(bar.offsetTop + bar.offsetHeight, area.element.clientHeight, 'at its bottom')
    await a11yAudit()
  })

  test('the thumb math, as Radix has it', function (assert) {
    const sizes = {
      content: 400,
      viewport: 100,
      scrollbar: { size: 100, paddingStart: 1, paddingEnd: 1 },
    }
    assert.strictEqual(thumbSize(sizes), 24.5, 'a quarter of the track')
    assert.strictEqual(thumbSize({ ...sizes, content: 10000 }), 18, 'never smaller than 18px')
    assert.strictEqual(thumbOffset(0, sizes), 0)
    assert.strictEqual(thumbOffset(300, sizes), 98 - 24.5, 'at the end of the track')
    assert.strictEqual(
      scrollFromPointer(1 + 24.5 / 2, 0, sizes),
      0,
      'the thumb centred at the start',
    )
    assert.strictEqual(
      thumbOffset(-300, sizes, 'rtl'),
      -(98 - 24.5),
      'right to left, scrolling is negative, and the thumb moves left from the right',
    )
  })
})
