import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ScrollArea, ScrollBar } from '@ember-joinery/ember'
import { ScrollAreaHarness } from '@ember-joinery/test-support'

const TAGS = Array.from({ length: 50 }).map((_, i, a) => `v1.2.0-beta.${a.length - i}`)

module('Integration | components | scroll-area', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's slots and classes on Joinery's scroll area", async function (assert) {
    await render(
      <template>
        <ScrollArea @name="tags" style="height: 288px; width: 192px">
          <div style="padding: 16px">
            {{#each TAGS as |tag|}}<div>{{tag}}</div>{{/each}}
          </div>
        </ScrollArea>
      </template>,
    )
    const tags = new ScrollAreaHarness('tags')
    assert.dom(tags.element).hasClass('jn-scroll-area').hasAttribute('data-slot', 'scroll-area')
    assert
      .dom(tags.viewport)
      .hasClass('jn-scroll-area-viewport')
      .hasAttribute('data-slot', 'scroll-area-viewport')
    assert.strictEqual(getComputedStyle(tags.element).position, 'relative')
    assert.strictEqual(getComputedStyle(tags.viewport).height, '288px', 'size-full')
    assert.strictEqual(getComputedStyle(tags.viewport).overflowY, 'scroll')
    assert.strictEqual(tags.scrollbar(), null, 'the scrollbar waits for the pointer')

    await tags.hover()
    const bar = tags.scrollbar()!
    assert
      .dom(bar)
      .hasClass('jn-scroll-area-scrollbar')
      .hasAttribute('data-slot', 'scroll-area-scrollbar')
      .hasAttribute('data-orientation', 'vertical')
    assert
      .dom(tags.thumb()!)
      .hasClass('jn-scroll-area-thumb')
      .hasAttribute('data-slot', 'scroll-area-thumb')
    await a11yAudit()
  })

  test('its style sheet draws the scrollbar: 10px wide, with a round thumb', async function (assert) {
    await render(
      <template>
        <ScrollArea @name="tags" @type="always" style="height: 288px; width: 192px">
          {{#each TAGS as |tag|}}<div>{{tag}}</div>{{/each}}
        </ScrollArea>
      </template>,
    )
    const tags = new ScrollAreaHarness('tags')
    const bar = getComputedStyle(tags.scrollbar()!)
    assert.strictEqual(bar.width, '10px', 'data-vertical:w-2.5')
    assert.strictEqual(bar.height, '288px', 'data-vertical:h-full')
    assert.strictEqual(bar.display, 'flex')
    assert.strictEqual(bar.paddingTop, '1px', 'p-px')
    assert.strictEqual(bar.borderLeftWidth, '1px', 'data-vertical:border-s')
    assert.strictEqual(bar.borderLeftColor, 'rgba(0, 0, 0, 0)', 'transparent')
    assert.strictEqual(bar.touchAction, 'none')
    const thumb = getComputedStyle(tags.thumb()!)
    assert.ok(parseFloat(thumb.borderTopLeftRadius) > 1000, 'rounded-full')
    assert.notStrictEqual(thumb.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-border')
    assert.strictEqual(thumb.position, 'relative')
    await a11yAudit()
  })

  test('scrolling moves the thumb, and dragging the thumb scrolls', async function (assert) {
    await render(
      <template>
        <ScrollArea @name="tags" @type="always" style="height: 288px; width: 192px">
          {{#each TAGS as |tag|}}<div style="height: 20px">{{tag}}</div>{{/each}}
        </ScrollArea>
      </template>,
    )
    const tags = new ScrollAreaHarness('tags')
    assert.strictEqual(tags.thumbOffset(), 0)
    await tags.scrollTo({ top: tags.maxScrollTop })
    const track = tags.scrollbar()!.clientHeight - 2
    assert.strictEqual(Math.round(tags.thumbOffset()), Math.round(track - tags.thumbLength()))
    await tags.dragThumb('vertical', -1000)
    assert.strictEqual(tags.scrollTop, 0, 'dragged back to the top')
    await a11yAudit()
  })

  test('a horizontal ScrollBar inside it scrolls across: 10px high, along the bottom', async function (assert) {
    await render(
      <template>
        <ScrollArea @name="works" @type="always" style="width: 384px; white-space: nowrap">
          <div style="display: flex; width: max-content; gap: 16px; padding: 16px">
            {{#each TAGS as |tag|}}<span>{{tag}}</span>{{/each}}
          </div>
          <ScrollBar @orientation="horizontal" />
        </ScrollArea>
      </template>,
    )
    const works = new ScrollAreaHarness('works')
    assert.strictEqual(getComputedStyle(works.viewport).overflowX, 'scroll')
    const bar = works.scrollbar('horizontal')!
    assert.dom(bar).hasAttribute('data-orientation', 'horizontal')
    const style = getComputedStyle(bar)
    assert.strictEqual(style.height, '10px', 'data-horizontal:h-2.5')
    assert.strictEqual(style.flexDirection, 'column', 'data-horizontal:flex-col')
    assert.strictEqual(style.borderTopWidth, '1px', 'data-horizontal:border-t')
    assert.strictEqual(
      bar.offsetTop + bar.offsetHeight,
      works.element.clientHeight,
      'at the bottom',
    )
    await works.scrollTo({ left: 100 })
    assert.ok(works.thumbOffset('horizontal') > 0, 'the thumb follows')
    await a11yAudit()
  })

  test('right to left, the scrollbar is on the left, with its border on its inline start', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <ScrollArea @name="tags" @type="always" style="height: 288px; width: 192px">
            <h4>العلامات</h4>
            {{#each TAGS as |tag|}}<div>{{tag}}</div>{{/each}}
          </ScrollArea>
        </DirectionProvider>
      </template>,
    )
    const tags = new ScrollAreaHarness('tags')
    const bar = tags.scrollbar()!
    assert.strictEqual(bar.offsetLeft, 0, 'on the left')
    const style = getComputedStyle(bar)
    assert.strictEqual(style.borderRightWidth, '1px', 'border-s is on the right, right to left')
    assert.strictEqual(style.borderLeftWidth, '0px')
    await a11yAudit()
  })
})
