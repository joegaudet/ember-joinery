import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { click, focus, render, rerender, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { fn, hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ArrowLeft, ChevronLeft, ChevronRight } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Card, Icon } from '@ember-joinery/ember'
import { ButtonHarness, IconHarness, pressKey } from '@ember-joinery/test-support'
import { Carousel, embla, type CarouselApi, type CarouselPlugin } from '@ember-joinery/carousel'
import { CarouselHarness } from '@ember-joinery/carousel/test-support'

const SLIDES = [1, 2, 3, 4, 5]
const THREE = [1, 2, 3]

/** The tracked state a test changes between renders. */
class State {
  @tracked loop = false
  @tracked count = 3
  @tracked dir: 'ltr' | 'rtl' = 'ltr'
  @tracked plugins: CarouselPlugin[] = []
  api: CarouselApi | undefined
  setApi = (api: CarouselApi) => (this.api = api)
  get slides(): number[] {
    return Array.from({ length: this.count }, (_, index) => index + 1)
  }
}

/** A plugin that records what Embla does with it. */
function recordingPlugin(name = 'recorder') {
  const calls: string[] = []
  const plugin: CarouselPlugin & { calls: string[]; api?: CarouselApi } = {
    name,
    options: { active: true },
    calls,
    init(api) {
      plugin.api = api
      calls.push('init')
    },
    destroy() {
      calls.push('destroy')
    },
  }
  return plugin
}

/** The drawing of a lucide icon: its paths' `d`. */
const pathsOf = (icon: unknown) =>
  ((icon as [string, object, [string, { d?: string }][]])[2] ?? []).map(([, { d }]) => d ?? null)
const drawn = (svg: Element) =>
  [...svg.querySelectorAll('path')].map(path => path.getAttribute('d'))

const rightOf = (element: Element) => element.getBoundingClientRect().right
const leftOf = (element: Element) => element.getBoundingClientRect().left
const topOf = (element: Element) => element.getBoundingClientRect().top

module('Integration | components | carousel', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Carousel style="width: 320px; margin: 0 64px" as |c|>
          <c.Content>
            {{#each SLIDES as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()

    assert
      .dom(carousel.element)
      .hasTagName('div')
      .hasClass('jn-carousel')
      .hasAttribute('role', 'region')
      .hasAttribute('aria-roledescription', 'carousel')
      .hasAttribute('data-slot', 'carousel')
      .hasAttribute('data-orientation', 'horizontal')
      .hasAttribute('data-test-jn', 'carousel')
    assert
      .dom(carousel.content)
      .hasClass('jn-carousel-content')
      .hasAttribute('data-slot', 'carousel-content')
      .hasAttribute('id', /^jn-\d+-content$/)
    assert
      .dom(carousel.container)
      .hasClass('jn-carousel-container')
      .hasAttribute('data-orientation', 'horizontal')
      .doesNotHaveAttribute('data-slot', 'upstream gives the row no slot')
    assert.strictEqual(carousel.container.parentElement, carousel.content, 'the row is inside')
    assert.strictEqual(carousel.slideCount, 5)
    for (const slide of carousel.slides) {
      assert
        .dom(slide)
        .hasClass('jn-carousel-item')
        .hasAttribute('role', 'group')
        .hasAttribute('aria-roledescription', 'slide')
        .hasAttribute('data-slot', 'carousel-item')
        .hasAttribute('data-orientation', 'horizontal')
      assert.strictEqual(slide.parentElement, carousel.container)
    }

    const previous = carousel.find(ButtonHarness, { index: 0 })
    const next = carousel.find(ButtonHarness, { index: 1 })
    assert.strictEqual(previous.element, carousel.previous, 'each button is a Button')
    assert.strictEqual(next.element, carousel.next)
    for (const [button, step] of [
      [previous, 'previous'],
      [next, 'next'],
    ] as const) {
      assert
        .dom(button.element)
        .hasTagName('button')
        .hasAttribute('type', 'button')
        .hasClass('jn-button')
        .hasClass('jn-button-variant-outline')
        .hasClass('jn-button-size-icon-sm')
        .hasClass(`jn-carousel-${step}`)
        .hasAttribute('data-slot', `carousel-${step}`)
        .hasAttribute('data-orientation', 'horizontal')
        .hasAttribute('aria-controls', carousel.content.id)
      assert.strictEqual(button.variant, 'outline')
      assert.strictEqual(button.size, 'icon-sm')
      const icon = button.find(IconHarness).element
      assert.dom(icon).hasClass('jn-rtl-flip')
      assert.deepEqual(
        drawn(icon),
        pathsOf(step === 'previous' ? ChevronLeft : ChevronRight),
        'lucide’s chevron',
      )
    }
    assert.strictEqual(previous.label, 'Previous slide', 'a visually hidden name, as upstream')
    assert.strictEqual(next.label, 'Next slide')
    await a11yAudit()
  })

  test('the style sheet lays it out as upstream does', async function (assert) {
    await render(
      <template>
        <Carousel style="width: 320px; margin: 0 64px" as |c|>
          <c.Content>
            {{#each SLIDES as |n|}}
              <c.Item><div style="height: 100px">Slide {{n}}</div></c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    const root = getComputedStyle(carousel.element)
    assert.strictEqual(root.position, 'relative', 'relative')
    assert.strictEqual(getComputedStyle(carousel.content).overflow, 'hidden', 'overflow-hidden')
    const row = getComputedStyle(carousel.container)
    assert.strictEqual(row.display, 'flex', 'flex')
    assert.strictEqual(row.flexDirection, 'row')
    assert.strictEqual(row.marginLeft, '-16px', '-ml-4, as -ms-4')
    const slide = getComputedStyle(carousel.slides[0]!)
    assert.strictEqual(slide.flexBasis, '100%', 'basis-full')
    assert.strictEqual(slide.flexShrink, '0', 'shrink-0')
    assert.strictEqual(slide.flexGrow, '0', 'grow-0')
    assert.strictEqual(slide.minWidth, '0px', 'min-w-0')
    assert.strictEqual(slide.paddingLeft, '16px', 'pl-4, as ps-4')
    assert.strictEqual(carousel.slides[0]!.offsetWidth, 336, 'the content and the negative margin')

    const previous = getComputedStyle(carousel.previous!)
    assert.strictEqual(previous.position, 'absolute', 'absolute')
    assert.strictEqual(previous.left, '-48px', '-left-12, as -start-12')
    assert.strictEqual(previous.touchAction, 'manipulation')
    assert.strictEqual(previous.width, '28px', 'icon-sm')
    assert.ok(parseFloat(previous.borderTopLeftRadius) > 1000, 'rounded-full, from the style sheet')
    assert.strictEqual(getComputedStyle(carousel.next!).right, '-48px', '-right-12, as -end-12')
    const box = carousel.element.getBoundingClientRect()
    const button = carousel.previous!.getBoundingClientRect()
    assert.ok(
      Math.abs(button.top + button.height / 2 - (box.top + box.height / 2)) < 1,
      'centred beside the slides (inset-y-0 my-auto)',
    )
    await a11yAudit()
  })

  test('the buttons move between the slides, and stop at either end', async function (assert) {
    await render(
      <template>
        <Carousel style="width: 320px; margin: 0 64px" as |c|>
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    await settled()
    assert.deepEqual(carousel.slidesInView, [0], 'the first slide')
    assert.false(carousel.canScrollPrev, 'nothing before the first')
    assert.true(carousel.canScrollNext)

    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [1])
    assert.true(carousel.canScrollPrev)
    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [2], 'the last slide')
    assert.false(carousel.canScrollNext, 'nothing after the last')
    assert.dom(carousel.next!).isDisabled()

    await carousel.scrollPrev()
    assert.deepEqual(carousel.slidesInView, [1])
    assert.strictEqual(carousel.currentSlide, 1)
    await a11yAudit()
  })

  test('the slides are named by their place, unless they have names of their own', async function (assert) {
    const ordinal = (index: number, count: number) => `Photo ${index} of ${count}`
    await render(
      <template>
        <Carousel @name="default" aria-label="default" style="width: 320px" as |c|>
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
        </Carousel>
        <Carousel
          @name="custom"
          aria-label="custom"
          @slideLabel={{ordinal}}
          style="width: 320px"
          as |c|
        >
          <c.Content>
            <c.Item>One</c.Item>
            <c.Item aria-label="The second">Two</c.Item>
            <c.Item aria-labelledby="third">
              <span id="third">Three</span>
            </c.Item>
          </c.Content>
        </Carousel>
      </template>,
    )
    assert.deepEqual(new CarouselHarness('default').slideLabels, ['1 of 3', '2 of 3', '3 of 3'])
    const custom = new CarouselHarness('custom')
    assert.deepEqual(custom.slideLabels, ['Photo 1 of 3', 'The second', ''])
    assert.dom(custom.slides[2]).doesNotHaveAttribute('aria-label', 'labelled by its own text')
    await a11yAudit()
  })

  test('the labels follow slides added and removed', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Carousel style="width: 320px" as |c|>
          <c.Content>
            {{#each state.slides as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    assert.deepEqual(carousel.slideLabels, ['1 of 3', '2 of 3', '3 of 3'])
    state.count = 4
    await settled()
    assert.deepEqual(carousel.slideLabels, ['1 of 4', '2 of 4', '3 of 4', '4 of 4'])
    state.count = 2
    await settled()
    assert.deepEqual(carousel.slideLabels, ['1 of 2', '2 of 2'])
    await a11yAudit()
  })

  test('the arrow keys move between the slides from anywhere inside', async function (assert) {
    await render(
      <template>
        <Carousel style="width: 320px; margin: 0 64px" as |c|>
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item>
                <a href="/slides/{{n}}">Slide {{n}}</a>
                <input aria-label="Caption {{n}}" />
              </c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    assert.true(await carousel.press('ArrowRight'), 'the carousel takes the key')
    assert.dom(carousel.next!).isFocused('focus starts on a button, as after tabbing in')
    assert.deepEqual(carousel.slidesInView, [1])
    await carousel.press('ArrowRight')
    assert.deepEqual(carousel.slidesInView, [2])
    await carousel.press('ArrowLeft')
    assert.deepEqual(carousel.slidesInView, [1])

    await focus(carousel.slides[1]!.querySelector('a')!)
    assert.true(await pressKey('ArrowLeft'), 'from a link in a slide too')
    assert.deepEqual(carousel.slidesInView, [0])

    await focus(carousel.slides[0]!.querySelector('input')!)
    assert.false(await pressKey('ArrowRight'), 'a text field keeps its arrow keys')
    assert.deepEqual(carousel.slidesInView, [0])
    assert.false(await carousel.press('ArrowDown'), 'not the up and down arrows, horizontally')
    await a11yAudit()
  })

  test('tabbing to what is in a slide brings that slide into view', async function (assert) {
    await render(
      <template>
        <Carousel style="width: 320px; margin: 0 64px" as |c|>
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item><a href="/slides/{{n}}">Slide {{n}}</a></c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    const link = carousel.slides[2]!.querySelector('a')!
    // Embla follows focus that comes from the Tab key, as a browser moves it: the key, then the
    // focus at once (the test helpers' tab() settles in between, which is too late for it).
    document.activeElement!.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'Tab', code: 'Tab', bubbles: true }),
    )
    link.focus()
    await settled()
    assert.dom(link).isFocused()
    assert.deepEqual(carousel.slidesInView, [2], 'Embla scrolls to the focused slide')
    assert.strictEqual(carousel.content.scrollLeft, 0, 'and the viewport doesn’t scroll itself')
    assert.false(carousel.canScrollNext, 'the buttons follow')
    await a11yAudit()
  })

  test('right to left, the slides run from the right and the arrows flip', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Carousel style="width: 320px; margin: 0 64px" as |c|>
            <c.Content>
              {{#each THREE as |n|}}
                <c.Item><div style="height: 80px">Slide {{n}}</div></c.Item>
              {{/each}}
            </c.Content>
            <c.Previous />
            <c.Next />
          </Carousel>
        </DirectionProvider>
      </template>,
    )
    const carousel = new CarouselHarness()
    assert.strictEqual(carousel.direction, 'rtl')
    const [first, second] = carousel.slides
    assert.ok(leftOf(second!) < leftOf(first!), 'the second slide waits on the left')
    assert.deepEqual(carousel.slidesInView, [0])
    assert.strictEqual(getComputedStyle(carousel.container).marginRight, '-16px', '-ms-4')
    assert.strictEqual(getComputedStyle(first!).paddingRight, '16px', 'ps-4')
    assert.ok(
      leftOf(carousel.previous!) > rightOf(carousel.content) - 1,
      'the previous button is on the right',
    )
    assert.ok(rightOf(carousel.next!) < leftOf(carousel.content) + 1, 'the next one on the left')
    const arrow = new ButtonHarness({ index: 0 }).find(IconHarness).element
    assert.strictEqual(getComputedStyle(arrow).rotate, '180deg', 'its chevron points right')

    await carousel.press('ArrowLeft')
    assert.deepEqual(carousel.slidesInView, [1], 'the left arrow goes on')
    await carousel.press('ArrowRight')
    assert.deepEqual(carousel.slidesInView, [0], 'the right arrow goes back')
    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [1])
    await a11yAudit()
  })

  test('it follows a change of direction in place', async function (assert) {
    const state = new State()
    await render(
      <template>
        <div dir={{state.dir}}>
          <Carousel style="width: 320px" as |c|>
            <c.Content>
              {{#each THREE as |n|}}
                <c.Item><div style="height: 80px">Slide {{n}}</div></c.Item>
              {{/each}}
            </c.Content>
            <c.Next />
          </Carousel>
        </div>
      </template>,
    )
    const carousel = new CarouselHarness()
    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [1])
    const [first, second] = carousel.slides
    assert.ok(leftOf(second!) > leftOf(first!), 'left to right')

    state.dir = 'rtl'
    await settled()
    assert.strictEqual(carousel.direction, 'rtl')
    assert.ok(leftOf(second!) < leftOf(first!), 'the slides now run from the right')
    assert.deepEqual(carousel.slidesInView, [1], 'and keep their place')
    await a11yAudit()
  })

  test('vertically, the slides stack and the buttons go above and below', async function (assert) {
    await render(
      <template>
        <Carousel
          @orientation="vertical"
          @opts={{hash align="start"}}
          style="width: 320px; margin: 64px 0"
          as |c|
        >
          <c.Content style="height: 200px">
            {{#each SLIDES as |n|}}
              <c.Item style="flex-basis: 50%">Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    assert.strictEqual(carousel.orientation, 'vertical')
    assert.dom(carousel.element).hasAttribute('data-orientation', 'vertical')
    const row = getComputedStyle(carousel.container)
    assert.strictEqual(row.flexDirection, 'column', 'flex-col')
    assert.strictEqual(row.marginTop, '-16px', '-mt-4')
    assert.strictEqual(row.marginLeft, '0px')
    assert.strictEqual(getComputedStyle(carousel.slides[0]!).paddingTop, '16px', 'pt-4')
    assert.strictEqual(getComputedStyle(carousel.slides[0]!).paddingLeft, '0px')
    assert.deepEqual(carousel.slidesInView, [0, 1], 'two at a time, as basis-1/2')

    const previous = getComputedStyle(carousel.previous!)
    assert.strictEqual(previous.top, '-48px', '-top-12')
    assert.strictEqual(previous.rotate, '90deg', 'rotate-90')
    assert.strictEqual(getComputedStyle(carousel.next!).bottom, '-48px', '-bottom-12')
    assert.ok(topOf(carousel.previous!) < topOf(carousel.content), 'previous above')
    assert.ok(topOf(carousel.next!) > carousel.content.getBoundingClientRect().bottom - 1)
    const box = carousel.element.getBoundingClientRect()
    const button = carousel.previous!.getBoundingClientRect()
    assert.ok(
      Math.abs(button.left + button.width / 2 - (box.left + box.width / 2)) < 1,
      'centred (left-1/2 -translate-x-1/2)',
    )

    await carousel.press('ArrowDown')
    assert.deepEqual(carousel.slidesInView, [1, 2], 'the down arrow goes on')
    await carousel.press('ArrowUp')
    assert.deepEqual(carousel.slidesInView, [0, 1])
    await carousel.press('ArrowRight')
    assert.deepEqual(carousel.slidesInView, [1, 2], 'and the right arrow, as upstream')
    await carousel.scrollNext()
    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [3, 4])
    assert.false(carousel.canScrollNext)
    await a11yAudit()
  })

  test('a swipe drags the slides along', async function (assert) {
    await render(
      <template>
        <Carousel @name="across" aria-label="across" style="width: 320px; margin: 0 64px" as |c|>
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item><div style="height: 80px">Slide {{n}}</div></c.Item>
            {{/each}}
          </c.Content>
        </Carousel>
        <Carousel
          @name="down"
          aria-label="down"
          @orientation="vertical"
          style="width: 320px"
          as |c|
        >
          <c.Content style="height: 120px">
            {{#each THREE as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
        </Carousel>
        <DirectionProvider @dir="rtl">
          <Carousel @name="rtl" aria-label="rtl" style="width: 320px" as |c|>
            <c.Content>
              {{#each THREE as |n|}}
                <c.Item><div style="height: 80px">Slide {{n}}</div></c.Item>
              {{/each}}
            </c.Content>
          </Carousel>
        </DirectionProvider>
      </template>,
    )
    for (const name of ['across', 'down', 'rtl']) {
      const carousel = new CarouselHarness(name)
      await carousel.swipe('next')
      assert.deepEqual(carousel.slidesInView, [1], `${name}: swiped on`)
      await carousel.swipe('previous')
      assert.deepEqual(carousel.slidesInView, [0], `${name}: and back`)
    }
    await a11yAudit()
  })

  test('@opts go to Embla: align, loop and the first slide', async function (assert) {
    await render(
      <template>
        <Carousel
          @name="loop"
          aria-label="loop"
          @opts={{hash loop=true}}
          style="width: 320px"
          as |c|
        >
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
        <Carousel
          @name="start"
          aria-label="start"
          @opts={{hash startIndex=2}}
          style="width: 320px"
          as |c|
        >
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
        <Carousel
          @name="align"
          aria-label="align"
          @opts={{hash align="start"}}
          style="width: 320px"
          as |c|
        >
          <c.Content>
            {{#each SLIDES as |n|}}
              <c.Item style="flex-basis: 33.3333%">Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const loop = new CarouselHarness('loop')
    assert.true(loop.canScrollPrev, 'a loop goes back from the first slide')
    await loop.scrollPrev()
    assert.deepEqual(loop.slidesInView, [2], 'to the last')

    const start = new CarouselHarness('start')
    assert.deepEqual(start.slidesInView, [2], 'startIndex')
    assert.false(start.canScrollNext)

    const align = new CarouselHarness('align')
    assert.deepEqual(align.slidesInView, [0, 1, 2], 'three at a time from the start')
    await align.scrollNext()
    assert.deepEqual(align.slidesInView, [1, 2, 3])
    await align.scrollNext()
    assert.deepEqual(align.slidesInView, [2, 3, 4])
    assert.false(align.canScrollNext, 'the snaps stop where the last slide shows')
    await a11yAudit()
  })

  test('changing @opts reinitializes it in place', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Carousel
          @opts={{hash loop=state.loop}}
          @setApi={{state.setApi}}
          style="width: 320px"
          as |c|
        >
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    const api = state.api!
    await carousel.scrollNext()
    await carousel.scrollNext()
    assert.false(carousel.canScrollNext)
    state.loop = true
    await settled()
    assert.strictEqual(state.api, api, 'the same carousel')
    assert.deepEqual(carousel.slidesInView, [2], 'where it was')
    assert.true(carousel.canScrollNext, 'and now it loops')
    await rerender()
    assert.strictEqual(state.api, api)
    await a11yAudit()
  })

  test('@setApi hands over Embla, to drive it and hear its events', async function (assert) {
    const state = new State()
    const selected: number[] = []
    await render(
      <template>
        <Carousel @setApi={{state.setApi}} style="width: 320px" as |c|>
          <c.Content>
            {{#each SLIDES as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    const api = state.api!
    assert.ok(api, 'the API, once the carousel exists')
    assert.strictEqual(api.scrollSnapList().length, 5)
    assert.strictEqual(api.rootNode(), carousel.content, 'Embla’s viewport is the content')
    assert.strictEqual(api.containerNode(), carousel.container)
    assert.deepEqual(api.slideNodes(), carousel.slides)
    api.on('select', () => selected.push(api.selectedScrollSnap()))

    api.scrollTo(3)
    await settled()
    assert.deepEqual(carousel.slidesInView, [3])
    assert.true(carousel.canScrollPrev, 'the buttons follow')
    await carousel.scrollNext()
    assert.deepEqual(selected, [3, 4])
    assert.false(carousel.canScrollNext)
    await a11yAudit()
  })

  test('it yields its state and actions, as upstream’s useCarousel()', async function (assert) {
    await render(
      <template>
        <Carousel style="width: 320px" as |c|>
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
          <p data-test-state>
            {{c.orientation}}
            {{if c.canScrollPrev "back"}}
            {{if c.canScrollNext "on"}}
            {{if c.api "api"}}
          </p>
          <button type="button" data-test-on {{on "click" c.scrollNext}}>On</button>
          <button type="button" data-test-back {{on "click" c.scrollPrev}}>Back</button>
          <button type="button" data-test-last {{on "click" (fn c.scrollTo 2)}}>Last</button>
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    assert.dom('[data-test-state]').hasText('horizontal on api')
    await click('[data-test-on]')
    assert.deepEqual(carousel.slidesInView, [1])
    assert.dom('[data-test-state]').hasText('horizontal back on api')
    await click('[data-test-last]')
    assert.deepEqual(carousel.slidesInView, [2])
    assert.dom('[data-test-state]').hasText('horizontal back api')
    await click('[data-test-back]')
    assert.deepEqual(carousel.slidesInView, [1])
    await a11yAudit()
  })

  test('@plugins go to Embla, and a change of plugins reinitializes it', async function (assert) {
    const state = new State()
    const first = recordingPlugin('first')
    const second = recordingPlugin('second')
    state.plugins = [first]
    await render(
      <template>
        <Carousel @plugins={{state.plugins}} style="width: 320px" as |c|>
          <c.Content>
            {{#each THREE as |n|}}
              <c.Item>Slide {{n}}</c.Item>
            {{/each}}
          </c.Content>
        </Carousel>
      </template>,
    )
    assert.deepEqual(first.calls, ['init'])
    assert.ok(first.api)
    state.plugins = [first]
    await settled()
    assert.deepEqual(first.calls, ['init'], 'the same plugins change nothing')
    state.plugins = [first, second]
    await settled()
    assert.deepEqual(first.calls, ['init', 'destroy', 'init'])
    assert.deepEqual(second.calls, ['init'])
    await a11yAudit()
  })

  test('@as, and attributes and classes on every part', async function (assert) {
    await render(
      <template>
        <Carousel @as="section" @name="list" aria-label="Featured" class="mine" as |c|>
          <c.Content @as="section" class="row" data-test-row>
            <c.Item @as="section" class="slide" data-test-slide>One</c.Item>
            <c.Item @as="section">Two</c.Item>
          </c.Content>
          <c.Previous class="back" @variant="ghost" @size="icon" @label="Back" @name="back" />
          <c.Next @icon={{ArrowLeft}} @label="On" />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness('list')
    assert.dom(carousel.element).hasTagName('section').hasClass('jn-carousel').hasClass('mine')
    assert.strictEqual(carousel.label, 'Featured')
    assert.strictEqual(carousel.roleDescription, 'carousel')
    assert
      .dom(carousel.container)
      .hasTagName('section')
      .hasClass('row')
      .hasAttribute('data-test-row')
    assert
      .dom(carousel.slides[0])
      .hasTagName('section')
      .hasClass('slide')
      .hasClass('jn-carousel-item')
    assert.deepEqual(carousel.slideTexts, ['One', 'Two'])
    const back = new ButtonHarness('back')
    assert.strictEqual(back.variant, 'ghost')
    assert.strictEqual(back.size, 'icon')
    assert.strictEqual(back.label, 'Back')
    assert.dom(back.element).hasClass('back').hasClass('jn-carousel-previous')
    const on = carousel.find(ButtonHarness, { index: 1 })
    assert.strictEqual(on.label, 'On')
    assert.deepEqual(drawn(on.find(IconHarness).element), pathsOf(ArrowLeft), 'its own icon')
    await a11yAudit()
  })

  test('the part modifiers render what the parts do, on elements of your own', async function (assert) {
    await render(
      <template>
        <Carousel @name="parts" aria-label="Parts" style="width: 320px" as |c|>
          <c.Content>
            <c.Item @as="section" data-case>One</c.Item>
            <c.Item @as="section">Two</c.Item>
          </c.Content>
          <c.Previous data-case />
          <c.Next data-case />
        </Carousel>
        <Carousel @name="mine" aria-label="Mine" style="width: 320px" as |c|>
          <c.Content>
            <section {{c.item}}>One</section>
            <section {{c.item}}>Two</section>
          </c.Content>
          <button type="button" {{c.previous}}>
            <Icon @icon={{ArrowLeft}} class="jn-rtl-flip" />
            Back
          </button>
          <button type="button" {{c.next}}>On</button>
        </Carousel>
      </template>,
    )
    const parts = new CarouselHarness('parts')
    const mine = new CarouselHarness('mine')
    const same = (a: Element, b: Element, what: string) => {
      const { attributes: theirs, classes } = rendering(a)
      const { attributes: ours, classes: ourClasses } = rendering(b)
      delete theirs['aria-controls']
      delete ours['aria-controls']
      assert.deepEqual(ourClasses, classes, `${what}: the same classes`)
      assert.deepEqual(ours, theirs, `${what}: the same attributes`)
    }
    same(parts.slides[1]!, mine.slides[1]!, 'item')
    same(parts.previous!, mine.previous!, 'previous')
    same(parts.next!, mine.next!, 'next')
    assert.dom(mine.previous!).hasAttribute('aria-controls', mine.content.id)
    assert.deepEqual(mine.slideLabels, ['1 of 2', '2 of 2'])

    assert.false(mine.canScrollPrev)
    await mine.scrollNext()
    assert.deepEqual(mine.slidesInView, [1], 'the modifier steps on a click')
    assert.true(mine.canScrollPrev)
    assert.false(mine.canScrollNext)
    await mine.scrollPrev()
    assert.deepEqual(mine.slidesInView, [0])
    await a11yAudit()
  })

  test('{{embla}} makes a carousel of markup of your own', async function (assert) {
    const state = new State()
    await render(
      <template>
        <div
          style="width: 240px; overflow: hidden"
          data-test-viewport
          {{embla options=(hash loop=true) onInit=state.setApi}}
        >
          <div style="display: flex">
            {{#each THREE as |n|}}
              <div style="flex: 0 0 100%">Slide {{n}}</div>
            {{/each}}
          </div>
        </div>
      </template>,
    )
    const api = state.api!
    assert.ok(api)
    assert.dom(api.rootNode()).hasAttribute('data-test-viewport')
    assert.strictEqual(api.slideNodes().length, 3)
    assert.true(api.canScrollPrev(), 'with its options')
    api.scrollNext()
    await settled()
    assert.strictEqual(api.selectedScrollSnap(), 1)
    await a11yAudit()
  })

  test('it cleans up when it goes', async function (assert) {
    const state = new State()
    state.count = 0
    await render(
      <template>
        {{#if state.count}}
          <Carousel @setApi={{state.setApi}} style="width: 320px" as |c|>
            <c.Content>
              <c.Item>One</c.Item>
              <c.Item>Two</c.Item>
            </c.Content>
            <c.Next />
          </Carousel>
        {{/if}}
      </template>,
    )
    state.count = 1
    await settled()
    const api = state.api!
    const events: string[] = []
    api.on('destroy', () => events.push('destroy'))
    api.scrollNext()
    state.count = 0
    await settled()
    assert.deepEqual(events, ['destroy'], 'Embla is destroyed')
    assert.false(new CarouselHarness().exists)
    await a11yAudit()
  })

  test('a Card in each slide, as upstream’s examples', async function (assert) {
    await render(
      <template>
        <Carousel style="width: 320px; margin: 0 64px" as |c|>
          <c.Content>
            {{#each SLIDES as |n|}}
              <c.Item>
                <div style="padding: 4px">
                  <Card as |card|>
                    <card.Content>{{n}}</card.Content>
                  </Card>
                </div>
              </c.Item>
            {{/each}}
          </c.Content>
          <c.Previous />
          <c.Next />
        </Carousel>
      </template>,
    )
    const carousel = new CarouselHarness()
    assert.deepEqual(carousel.slideTexts, ['1', '2', '3', '4', '5'])
    await carousel.scrollNext()
    assert.strictEqual(carousel.slideTexts[carousel.currentSlide], '2')
    await a11yAudit()
  })
})
