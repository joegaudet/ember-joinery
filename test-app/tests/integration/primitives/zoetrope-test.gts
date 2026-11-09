/* global ScrollToOptions -- a DOM type, which ESLint's browser globals don't list */
import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Zoetrope } from '@ember-joinery/primitives/zoetrope'
import { ZoetropeHarness, tab } from '@ember-joinery/test-support'

/** A track 400px wide, with items 200px wide and the default 8px gap: two in view at once. */
const Styles = <template>
  <style>
    .track {
      width: 400px;
    }
    .track a {
      display: block;
      width: 200px;
    }
  </style>
</template>

/** 1 to `count`, for that many cards. */
const range = (count: number) => Array.from({ length: count }, (_, i) => i + 1)

/** Records each `scrollBy` call's behavior on the zoetrope's track, and still scrolls. */
function spyOnScrollBy(zoetrope: ZoetropeHarness): string[] {
  const behaviors: string[] = []
  const track = zoetrope.scroller
  const original = track.scrollBy.bind(track)
  track.scrollBy = ((options: ScrollToOptions) => {
    behaviors.push(String(options.behavior))
    original(options)
  }) as typeof track.scrollBy
  return behaviors
}

/**
 * Holds each `scrollBy` on the zoetrope's track for `count` animation frames before it sets
 * off, as a smooth scroll on a busy page can take a while to start.
 */
function holdScrollBy(zoetrope: ZoetropeHarness, count: number): void {
  const track = zoetrope.scroller
  const original = track.scrollBy.bind(track)
  track.scrollBy = ((options: ScrollToOptions) => {
    void (async () => {
      for (let i = 0; i < count; i++) await new Promise(requestAnimationFrame)
      original(options)
    })()
  }) as typeof track.scrollBy
}

/**
 * Makes `matchMedia('(prefers-reduced-motion: reduce)')` match, as a system asking for reduced
 * motion does, until the returned function puts it back.
 */
function preferReducedMotion(): () => void {
  const original = window.matchMedia
  window.matchMedia = ((query: string) => {
    const list = original.call(window, query)
    if (!/prefers-reduced-motion:\s*reduce/.test(query)) return list
    // The list's `matches` is a getter: answer from one of our own on top of it.
    return Object.create(list, { matches: { value: true }, media: { value: query } })
  }) as typeof window.matchMedia
  return () => {
    window.matchMedia = original
  }
}

module('Integration | primitives | zoetrope', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a section with a header, the default controls and a track', async function (assert) {
    await render(
      <template>
        <Styles />
        <Zoetrope @name="cards" class="track" aria-label="Cards">
          <:header><h2>Heading</h2></:header>
          <:content>
            <a href="/cards/1">Card 1</a>
            <a href="/cards/2">Card 2</a>
            <a href="/cards/3">Card 3</a>
          </:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness('cards')

    assert.dom(zoetrope.element).hasTagName('section').hasAttribute('data-jn-zoetrope')
    assert.dom(zoetrope.header).hasText('Heading').hasAttribute('data-jn-zoetrope-header')
    assert.dom(zoetrope.controls).hasAttribute('data-jn-zoetrope-controls')
    assert.dom(zoetrope.scroller).hasAttribute('data-jn-zoetrope-scroller')
    assert.strictEqual(zoetrope.items.length, 3)
    assert.dom(zoetrope.leftButton).hasText('Left').hasAttribute('type', 'button')
    assert.dom(zoetrope.rightButton).hasText('Right')

    const track = getComputedStyle(zoetrope.scroller)
    assert.strictEqual(track.display, 'flex', 'its layout rules apply')
    assert.strictEqual(track.flexWrap, 'nowrap')
    assert.strictEqual(track.overflowX, 'scroll')
    assert.strictEqual(track.scrollSnapType, 'x mandatory')
    assert.strictEqual(
      getComputedStyle(zoetrope.items[0]!).flexShrink,
      '0',
      'items keep their width',
    )
    assert.strictEqual(getComputedStyle(zoetrope.items[0]!).scrollSnapAlign, 'start')
    await a11yAudit()
  })

  test('it counts the items in view', async function (assert) {
    await render(
      <template>
        <Styles />
        <Zoetrope class="track" aria-label="Cards">
          <:content>
            {{#each (range 7) as |n|}}<a href="/cards/{{n}}">Card {{n}}</a>{{/each}}
          </:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    assert.strictEqual(zoetrope.visibleItemCount, 2)
    assert.deepEqual(zoetrope.visibleItems, zoetrope.items.slice(0, 2))
    await a11yAudit()
  })

  test('@gap and @offset set the space between and around the items', async function (assert) {
    await render(
      <template>
        <Zoetrope @gap={{10}} @offset={{40}} aria-label="Cards">
          <:header><h2>Heading</h2></:header>
          <:content>
            <a href="/cards/1">Card</a>
            <a href="/cards/2">Card</a>
          </:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    const track = getComputedStyle(zoetrope.scroller)
    assert.strictEqual(track.columnGap, '10px', 'the gap')
    assert.strictEqual(track.paddingInlineStart, '40px', 'the offset, at the start')
    assert.strictEqual(track.paddingInlineEnd, '40px', 'and at the end')
    assert.strictEqual(track.scrollPaddingInlineStart, '40px', 'where the items snap to')
    assert.strictEqual(getComputedStyle(zoetrope.header!).paddingInlineStart, '40px')
    assert.strictEqual(zoetrope.element.style.getPropertyValue('--zoetrope-gap'), '10px')
    await a11yAudit()
  })

  test('the controls show only when the items overflow', async function (assert) {
    await render(
      <template>
        <Zoetrope @name="short" aria-label="Short">
          <:content>
            <a href="/cards/1">Card</a>
          </:content>
        </Zoetrope>
        <Styles />
        <Zoetrope @name="long" class="track" aria-label="Long">
          <:content>
            <a href="/cards/1">Card</a>
            <a href="/cards/2">Card</a>
            <a href="/cards/3">Card</a>
          </:content>
        </Zoetrope>
      </template>,
    )
    assert.strictEqual(new ZoetropeHarness('short').controls, null, 'nothing to scroll')
    assert.notStrictEqual(new ZoetropeHarness('long').controls, null)
    await a11yAudit()
  })

  test('the buttons scroll a page at a time, and are disabled at their ends', async function (assert) {
    await render(
      <template>
        <Styles />
        <Zoetrope class="track" aria-label="Cards">
          <:header><h2>Header</h2></:header>
          <:content>
            <a href="/cards/1">Card 1</a>
            <a href="/cards/2">Card 2</a>
            <a href="/cards/3">Card 3</a>
          </:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    assert.false(zoetrope.canScrollLeft, 'nothing to the left at the start')
    assert.true(zoetrope.canScrollRight)

    // The default, smooth scrolling: the harness waits for the scroll to end.
    await zoetrope.scrollRight()
    assert.strictEqual(zoetrope.scrolled, 208, 'the second card is at the start')
    assert.true(zoetrope.canScrollLeft)
    assert.true(zoetrope.canScrollRight, 'the third card is still 8px short')

    await zoetrope.scrollRight()
    assert.strictEqual(zoetrope.scrolled, 216, 'as far as it goes')
    assert.false(zoetrope.canScrollRight, 'and that is the end')

    await zoetrope.scrollLeft()
    assert.strictEqual(zoetrope.scrolled, 208, 'a page back: the card before the first in view')
    await zoetrope.scrollLeft()
    assert.strictEqual(zoetrope.scrolled, 0)
    assert.false(zoetrope.canScrollLeft)
    await a11yAudit()
  })

  test('<:controls> takes buttons of your own', async function (assert) {
    await render(
      <template>
        <Styles />
        <Zoetrope class="track" @scrollBehavior="instant" aria-label="Cards">
          <:controls as |z|>
            <div class="my-controls">
              <button
                type="button"
                data-test-jn-part="scroll-left"
                disabled={{z.cannotScrollLeft}}
                {{on "click" z.scrollLeft}}
              >Previous</button>
              <button
                type="button"
                data-test-jn-part="scroll-right"
                disabled={{z.cannotScrollRight}}
                {{on "click" z.scrollRight}}
              >Next</button>
              {{#if z.canScroll}}<span class="can-scroll">More</span>{{/if}}
            </div>
          </:controls>
          <:content>
            {{#each (range 6) as |n|}}<a href="/cards/{{n}}">Card {{n}}</a>{{/each}}
          </:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    assert.dom('.my-controls').exists()
    assert.dom('.can-scroll').exists('given canScroll')
    assert.strictEqual(zoetrope.controls, null, 'no default controls')

    await click('.my-controls button:last-of-type')
    assert.strictEqual(zoetrope.scrolled, 208)
    await click('.my-controls button:first-of-type')
    assert.strictEqual(zoetrope.scrolled, 0)
    assert.false(zoetrope.canScrollLeft, 'the harness drives buttons marked as its parts')
    await zoetrope.scrollRight()
    assert.strictEqual(zoetrope.scrolled, 208)
    await a11yAudit()
  })

  test('Tab moves to the next item and brings it to the start', async function (assert) {
    await render(
      <template>
        <Styles />
        <Zoetrope class="track" @scrollBehavior="instant" aria-label="Cards">
          <:content>
            <a href="/cards/1">Card 1</a>
            <a href="/cards/2">Card 2</a>
            <a href="/cards/3">Card 3</a>
            <a href="/cards/4">Card 4</a>
          </:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    await zoetrope.focusItem(1)
    await tab()
    assert.strictEqual(zoetrope.focusedIndex, 2)
    assert.strictEqual(zoetrope.scrolled, 416, 'the third card is at the start')

    await tab({ shift: true })
    assert.strictEqual(zoetrope.focusedIndex, 1, 'Shift+Tab goes back')
    assert.strictEqual(zoetrope.scrolled, 208)
    await a11yAudit()
  })

  test('Tab never traps the keyboard: an item that can’t take focus leaves Tab to the browser', async function (assert) {
    await render(
      <template>
        <Zoetrope aria-label="Cards">
          <:content>
            <a href="/cards/1" id="first">Card</a>
            <div>Not focusable</div>
            <a href="/cards/2" id="second">Card</a>
            <a href="/cards/3" id="third">Card</a>
          </:content>
        </Zoetrope>
        <button type="button" id="after">After</button>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    const cancelled: boolean[] = []
    const listener = (event: KeyboardEvent) => cancelled.push(event.defaultPrevented)
    document.addEventListener('keydown', listener)

    await zoetrope.focusItem(0)
    await tab()
    assert.dom('#second').isFocused('the browser moved on past the div')
    await tab()
    assert.dom('#third').isFocused('the zoetrope moved to the next item')
    await tab()
    assert.dom('#after').isFocused('past the last item, out of the zoetrope')
    document.removeEventListener('keydown', listener)
    assert.deepEqual(cancelled, [false, true, false])
    await a11yAudit()
  })

  test('Tab inside an item is left to the browser', async function (assert) {
    await render(
      <template>
        <Zoetrope aria-label="Cards">
          <:content>
            <div><button type="button" id="a">A</button><button
                type="button"
                id="b"
              >B</button></div>
            <div><button type="button" id="c">C</button></div>
          </:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    await click('#a')
    await tab()
    assert.dom('#b').isFocused('the next button in the same item')
    assert.strictEqual(zoetrope.scrolled, 0, 'and no scroll')
    await a11yAudit()
  })

  test('it scrolls smoothly by default, as @scrollBehavior says, and instantly for reduced motion', async function (assert) {
    await render(
      <template>
        <Styles />
        <Zoetrope @name="default" class="track" aria-label="Default">
          <:content>{{#each (range 4) as |n|}}<a href="/cards/{{n}}">Card
                {{n}}</a>{{/each}}</:content>
        </Zoetrope>
        <Zoetrope @name="instant" class="track" @scrollBehavior="instant" aria-label="Instant">
          <:content>{{#each (range 4) as |n|}}<a href="/cards/{{n}}">Card
                {{n}}</a>{{/each}}</:content>
        </Zoetrope>
      </template>,
    )
    const smooth = new ZoetropeHarness('default')
    const instant = new ZoetropeHarness('instant')
    const smoothCalls = spyOnScrollBy(smooth)
    const instantCalls = spyOnScrollBy(instant)

    await smooth.scrollRight()
    await instant.scrollRight()
    assert.deepEqual(smoothCalls, ['smooth'])
    assert.deepEqual(instantCalls, ['instant'])

    const restore = preferReducedMotion()
    try {
      await smooth.scrollLeft()
      assert.deepEqual(smoothCalls, ['smooth', 'instant'], 'reduced motion: always instant')
      assert.strictEqual(smooth.scrolled, 0)
    } finally {
      restore()
    }
    await a11yAudit()
  })

  test('a smooth scroll that is slow to set off is waited for, not taken for one that ended', async function (assert) {
    await render(
      <template>
        <Styles />
        <Zoetrope class="track" aria-label="Cards">
          <:content>{{#each (range 4) as |n|}}<a href="/cards/{{n}}">Card
                {{n}}</a>{{/each}}</:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    // Longer than the three still frames that count as the end of a scroll that goes nowhere.
    holdScrollBy(zoetrope, 8)

    await zoetrope.scrollRight()
    assert.strictEqual(zoetrope.scrolled, 208, 'it waited for the scroll to start, then to end')
    assert.true(zoetrope.canScrollLeft)
    await zoetrope.scrollLeft()
    assert.strictEqual(zoetrope.scrolled, 0, 'and back')
    assert.false(zoetrope.canScrollLeft)
    await a11yAudit()
  })

  test('the default buttons’ text can be replaced', async function (assert) {
    await render(
      <template>
        <Styles />
        <Zoetrope
          class="track"
          @scrollLeftLabel="Previous cards"
          @scrollRightLabel="Next cards"
          aria-label="Cards"
        >
          <:content>{{#each (range 4) as |n|}}<a href="/cards/{{n}}">Card
                {{n}}</a>{{/each}}</:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    assert.dom(zoetrope.leftButton).hasText('Previous cards')
    assert.dom(zoetrope.rightButton).hasText('Next cards')
    await a11yAudit()
  })

  test('right to left: the track starts on the right, and left and right keep their sides', async function (assert) {
    await render(
      <template>
        <Styles />
        <DirectionProvider @dir="rtl">
          <Zoetrope class="track" @scrollBehavior="instant" aria-label="بطاقات">
            <:content>
              <a href="/cards/1">بطاقة 1</a>
              <a href="/cards/2">بطاقة 2</a>
              <a href="/cards/3">بطاقة 3</a>
            </:content>
          </Zoetrope>
        </DirectionProvider>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    const [first] = zoetrope.items
    const track = zoetrope.scroller.getBoundingClientRect()
    assert.true(
      Math.abs(first!.getBoundingClientRect().right - track.right) < 1,
      'the first card is at the right',
    )
    assert.strictEqual(
      getComputedStyle(zoetrope.scroller).paddingRight,
      getComputedStyle(zoetrope.scroller).paddingInlineStart,
      'the offset is on the start side',
    )
    assert.false(zoetrope.canScrollRight, 'nothing to the right at the start')
    assert.true(zoetrope.canScrollLeft)

    await zoetrope.scrollLeft()
    assert.strictEqual(zoetrope.scrolled, 208, 'left shows the next cards')
    assert.true(zoetrope.scroller.scrollLeft < 0, 'scrolled towards the left')
    assert.true(zoetrope.canScrollRight)
    await zoetrope.scrollLeft()
    assert.strictEqual(zoetrope.scrolled, 216)
    assert.false(zoetrope.canScrollLeft, 'and that is the end')

    await zoetrope.scrollRight()
    await zoetrope.scrollRight()
    assert.strictEqual(zoetrope.scrolled, 0, 'right goes back')
    assert.false(zoetrope.canScrollRight)
    await a11yAudit()
  })

  test('app CSS wins over its layout rules', async function (assert) {
    await render(
      <template>
        <style>
          .roomy [data-jn-zoetrope-scroller] {
            padding-block: 24px;
          }
        </style>
        <Zoetrope class="roomy" aria-label="Cards">
          <:content><a href="/cards/1">Card</a></:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    assert.strictEqual(getComputedStyle(zoetrope.scroller).paddingTop, '24px')
    await a11yAudit()
  })

  test('the content can change', async function (assert) {
    await render(
      <template>
        <Styles />
        <Zoetrope class="track" aria-label="Cards">
          <:content><a href="/cards/1">Card 1</a></:content>
        </Zoetrope>
      </template>,
    )
    const zoetrope = new ZoetropeHarness()
    assert.strictEqual(zoetrope.controls, null)

    const track = zoetrope.scroller
    for (const n of [2, 3]) {
      const card = document.createElement('a')
      card.href = `#${n}`
      card.textContent = 'Card'
      track.append(card)
    }
    await settled()
    await new Promise(requestAnimationFrame)
    await settled()
    assert.notStrictEqual(zoetrope.controls, null, 'new items that overflow bring the controls')
    await a11yAudit()
  })
})
