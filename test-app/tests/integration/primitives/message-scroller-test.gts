import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { render } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { htmlSafe } from '@ember/template'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  MessageScrollerProvider,
  type MessageScrollerApi,
  type MessageScrollerDefaultScrollPosition,
} from '@ember-joinery/primitives/message-scroller'
import { MessageScrollerHarness } from '@ember-joinery/test-support'

/** A transcript row: a fixed height, so the geometry is exact. */
class Row {
  @tracked height: number
  constructor(
    readonly id: string,
    height: number,
    readonly anchor = false,
  ) {
    this.height = height
  }
  get style() {
    return htmlSafe(`height: ${this.height}px`)
  }
}

/** The rows and every argument of the provider and the viewport, for a test to change. */
class Transcript {
  @tracked rows: Row[]
  @tracked autoScroll: boolean | undefined
  @tracked defaultScrollPosition: MessageScrollerDefaultScrollPosition | undefined
  @tracked scrollEdgeThreshold: number | undefined
  @tracked scrollMargin: number | undefined
  @tracked preserveScrollOnPrepend: boolean | undefined
  /** Whether a `Visibility` is rendered, watching where the reader is. */
  @tracked watching = false
  /** The content's block padding, in pixels. */
  padding = 0
  /** What the provider yields, once it has rendered. */
  api: MessageScrollerApi | undefined
  constructor(rows: Row[] = []) {
    this.rows = rows
  }
  get contentStyle() {
    return htmlSafe(
      `display: flex; flex-direction: column; gap: ${GAP}px; padding: ${this.padding}px 0`,
    )
  }
  append(...rows: Row[]) {
    this.rows = [...this.rows, ...rows]
  }
  prepend(...rows: Row[]) {
    this.rows = [...rows, ...this.rows]
  }
  row(id: string) {
    return this.rows.find(row => row.id === id)!
  }
  /** What the provider yields. Throws before it has rendered. */
  get scroller(): MessageScrollerApi {
    if (!this.api) throw new Error('the provider has not rendered')
    return this.api
  }
}

const capture = (transcript: Transcript, api: MessageScrollerApi) => void (transcript.api = api)

/** A user's turn (an anchor) and the reply after it. */
const turn = (n: number, reply: number) => [new Row(`u${n}`, 60, true), new Row(`a${n}`, reply)]

/** Rows with no anchor among them. */
const plain = (...ids: string[]) => ids.map(id => new Row(id, 200))

const GAP = 24
const PEEK = 64
const EMPTY = { currentAnchorId: null, visibleMessageIds: [] }

/**
 * The headless parts, with no styles but what the test sets inline: a 300px viewport, its rows
 * 24px apart. The browser's own scroll anchoring is off (`overflow-anchor: none`), so the
 * tests see the scroller's.
 */
function renderTranscript(transcript: Transcript) {
  return render(
    <template>
      <div style="height: 300px; width: 320px">
        <MessageScrollerProvider
          @autoScroll={{transcript.autoScroll}}
          @defaultScrollPosition={{transcript.defaultScrollPosition}}
          @scrollEdgeThreshold={{transcript.scrollEdgeThreshold}}
          @scrollMargin={{transcript.scrollMargin}}
          as |s|
        >
          {{capture transcript s}}
          {{#if transcript.watching}}
            <s.Visibility />
          {{/if}}
          <s.Root @name="chat" style="position: relative; height: 100%; overflow: hidden">
            <s.Viewport
              @preserveScrollOnPrepend={{transcript.preserveScrollOnPrepend}}
              style="height: 100%; overflow-y: auto; overflow-anchor: none"
            >
              <s.Content style={{transcript.contentStyle}}>
                {{#each transcript.rows key="id" as |row|}}
                  <s.Item @messageId={{row.id}} @scrollAnchor={{row.anchor}} style={{row.style}}>
                    {{row.id}}
                  </s.Item>
                {{/each}}
              </s.Content>
            </s.Viewport>
            <s.Button />
          </s.Root>
        </MessageScrollerProvider>
      </div>
    </template>,
  )
}

module('Integration | primitives | message-scroller', function (hooks) {
  setupRenderingTest(hooks)

  module('the provider', function () {
    test('it renders no element of its own, and its parts carry ARIA and no styles', async function (assert) {
      const transcript = new Transcript([...turn(1, 100)])
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.strictEqual(chat.element.parentElement?.style.height, '300px', 'the root is its child')
      assert.dom(chat.element).doesNotHaveAttribute('data-slot')
      // Before 7.1, Ember gives an element rendered through `As` `ember-view`; rendering() leaves
      // that out.
      assert.deepEqual(rendering(chat.element).classes, [], 'no classes')
      assert
        .dom(chat.viewport)
        .hasAttribute('role', 'region')
        .hasAttribute('aria-label', 'Messages')
        .hasAttribute('tabindex', '0')
      assert
        .dom(chat.content)
        .hasAttribute('role', 'log')
        .hasAttribute('aria-relevant', 'additions')
      assert.dom(chat.item('u1')).hasAttribute('data-scroll-anchor', 'true')
      assert.dom(chat.button()).hasTagName('button').hasAttribute('type', 'button')
      assert.dom(chat.button()).hasText('Scroll to end')
      await a11yAudit()
    })

    test('@autoScroll turned on at the end follows the reply, and turned off stops', async function (assert) {
      const transcript = new Transcript([new Row('u1', 60, true), new Row('a1', 400)])
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.true(chat.isAtEnd)

      transcript.row('a1').height = 500
      await chat.settle()
      const top = chat.scrollTop
      assert.false(chat.isAtEnd, 'without it, a growing reply is not followed')

      transcript.autoScroll = true
      await chat.settle()
      assert.strictEqual(chat.scrollTop, top, 'turned on away from the end, it yanks no one down')

      await chat.scrollTo(chat.maxScrollTop)
      transcript.row('a1').height = 700
      await chat.settle()
      assert.true(chat.isAtEnd, 'at the end, it follows')
      assert.false(chat.canScrollToEnd, 'and says there is nothing below')

      transcript.autoScroll = false
      await chat.settle()
      transcript.row('a1').height = 900
      await chat.settle()
      assert.false(chat.isAtEnd, 'turned off, it lets the reply grow past the edge')
      // As upstream's, the end reads as reached until the reader scrolls: it was following.
      await chat.scrollBy(-40)
      assert.true(chat.canScrollToEnd)
      assert.true(chat.isButtonActive())
      await a11yAudit()
    })

    test('@autoScroll turned on while resting at the end follows from there', async function (assert) {
      const transcript = new Transcript([new Row('u1', 60, true), new Row('a1', 400)])
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.true(chat.isAtEnd)
      transcript.autoScroll = true
      await chat.settle()
      transcript.row('a1').height = 600
      await chat.settle()
      assert.true(chat.isAtEnd)
      await a11yAudit()
    })

    test('@defaultScrollPosition changed after the render applies the new position, without hiding', async function (assert) {
      const transcript = new Transcript([...turn(1, 200), ...turn(2, 400)])
      transcript.defaultScrollPosition = 'start'
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.true(chat.isAtStart)

      transcript.defaultScrollPosition = 'end'
      assert.false(chat.isPendingScroll, 'the hold is for the first render only')
      await chat.settle()
      assert.true(chat.isAtEnd)
      assert.false(chat.isPendingScroll)

      transcript.defaultScrollPosition = 'last-anchor'
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK)

      transcript.defaultScrollPosition = 'start'
      await chat.settle()
      assert.true(chat.isAtStart)
      await a11yAudit()
    })

    test('"last-anchor" goes by the last row marked @scrollAnchor, not the last row', async function (assert) {
      const transcript = new Transcript([...turn(1, 200), ...turn(2, 400), new Row('n1', 100)])
      transcript.defaultScrollPosition = 'last-anchor'
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK)
      await a11yAudit()
    })

    test('"last-anchor" with no anchor, and a short transcript, open at the end', async function (assert) {
      const transcript = new Transcript(plain('m1', 'm2', 'm3'))
      transcript.defaultScrollPosition = 'last-anchor'
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.true(chat.maxScrollTop > 0)
      assert.true(chat.isAtEnd, 'no anchor: the end')
      assert.false(chat.isPendingScroll)
      await a11yAudit()
    })

    test('@scrollEdgeThreshold: a gap this small at either edge does not count', async function (assert) {
      // 320px of rows in a 300px viewport: 20px to scroll.
      const transcript = new Transcript([new Row('m1', 148), new Row('m2', 148)])
      transcript.defaultScrollPosition = 'start'
      transcript.scrollEdgeThreshold = 30
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.strictEqual(chat.maxScrollTop, 20)
      assert.deepEqual(chat.scrollable, { start: false, end: false }, 'at the top')
      assert.false(chat.isButtonActive(), 'so the button stays out of the way')
      await chat.scrollTo(10)
      assert.deepEqual(chat.scrollable, { start: false, end: false }, 'in the middle')
      await chat.scrollTo(20)
      assert.deepEqual(chat.scrollable, { start: false, end: false }, 'at the bottom')
      await a11yAudit()
    })

    test('the default threshold, 8px: past it, an edge counts', async function (assert) {
      const transcript = new Transcript([new Row('m1', 148), new Row('m2', 148)])
      transcript.defaultScrollPosition = 'start'
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.deepEqual(chat.scrollable, { start: false, end: true })
      await chat.scrollTo(10)
      assert.deepEqual(chat.scrollable, { start: true, end: true }, '10px from each edge')
      await chat.scrollTo(14)
      assert.deepEqual(chat.scrollable, { start: true, end: false }, 'within 8px of the end')
      await a11yAudit()
    })

    test('@scrollMargin: jumps and anchored turns land that far from the top', async function (assert) {
      const transcript = new Transcript([...turn(1, 300), ...turn(2, 300), ...turn(3, 300)])
      transcript.defaultScrollPosition = 'start'
      transcript.scrollMargin = 20
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.true(transcript.scroller.scrollToMessage('u2'))
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), 20, "the provider's margin")
      transcript.scroller.scrollToMessage('u2', { scrollMargin: 4 })
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), 4, 'a command can override it')

      await chat.scrollTo(chat.maxScrollTop)
      transcript.append(new Row('u4', 60, true))
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u4')), 20 + PEEK, 'a new turn: margin, then peek')
      await a11yAudit()
    })

    test('data-autoscrolling marks a jump to the end while it runs', async function (assert) {
      const transcript = new Transcript([...turn(1, 300), ...turn(2, 300)])
      transcript.defaultScrollPosition = 'start'
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.false(chat.isAutoscrolling)

      assert.true(transcript.scroller.scrollToEnd({ behavior: 'smooth' }))
      assert.true(chat.isAutoscrolling, 'on the root as the scroll sets off')
      assert.dom(chat.viewport).hasAttribute('data-autoscrolling', '', 'and on the viewport')
      await chat.settle()
      assert.true(chat.isAtEnd)
      assert.false(chat.isAutoscrolling, 'gone once it lands')
      assert.dom(chat.viewport).doesNotHaveAttribute('data-autoscrolling')

      assert.true(transcript.scroller.scrollToStart({ behavior: 'auto' }))
      assert.false(chat.isAutoscrolling, 'a jump to the start is not one')
      await chat.settle()
      assert.true(chat.isAtStart)
      await a11yAudit()
    })
  })

  module('rows', function () {
    test('a row that becomes an anchor in place, the count unchanged, is placed as a new turn', async function (assert) {
      const transcript = new Transcript([new Row('m1', 400), new Row('placeholder', 80)])
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.true(chat.isAtEnd)
      transcript.rows = [transcript.row('m1'), new Row('m2', 40, true)]
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('m2')), PEEK)
      await a11yAudit()
    })

    test('of several rows appended, the first anchor among them is the one placed', async function (assert) {
      const transcript = new Transcript([...turn(1, 400)])
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      transcript.append(new Row('a1-more', 40), ...turn(2, 40), ...turn(3, 40))
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK)
      await a11yAudit()
    })

    test('with @autoScroll following the end, a batch of turns keeps following', async function (assert) {
      const transcript = new Transcript([...turn(1, 400)])
      transcript.autoScroll = true
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      transcript.append(...turn(2, 200), ...turn(3, 200))
      await chat.settle()
      assert.true(chat.isAtEnd, 'not pulled back to the first of them')
      await a11yAudit()
    })

    test('the room made below an anchored turn is no "more below"', async function (assert) {
      const transcript = new Transcript([...turn(1, 400)])
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      transcript.append(new Row('u2', 60, true))
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK)
      assert.true(chat.scrollTop + 300 > chat.item('u2').offsetTop + 60, 'a spacer below the turn')
      assert.false(chat.canScrollToEnd, 'but no row is hidden below')
      assert.false(chat.isButtonActive())
      await a11yAudit()
    })

    test('history prepended keeps the reader in place, with the browser not helping', async function (assert) {
      const transcript = new Transcript(plain('m3', 'm4', 'm5', 'm6'))
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      await chat.scrollTo(150)
      const before = chat.itemTop('m4')
      transcript.prepend(...plain('m1', 'm2'))
      await chat.settle()
      assert.deepEqual(chat.messageIds.slice(0, 2), ['m1', 'm2'])
      assert.true(Math.abs(chat.itemTop('m4') - before) <= 1, 'm4 stayed where it was')
      await a11yAudit()
    })

    test('@preserveScrollOnPrepend={{false}} leaves the scroll position alone', async function (assert) {
      const transcript = new Transcript(plain('m3', 'm4', 'm5', 'm6'))
      transcript.preserveScrollOnPrepend = false
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      await chat.scrollTo(150)
      const before = chat.itemTop('m4')
      transcript.prepend(...plain('m1', 'm2'))
      await chat.settle()
      assert.strictEqual(chat.scrollTop, 150, 'the same scrollTop')
      assert.strictEqual(
        Math.round(chat.itemTop('m4') - before),
        2 * (200 + GAP),
        'so the rows moved down by what came above them',
      )
      await a11yAudit()
    })
  })

  module('scrollToMessage and the content padding', function () {
    // The content has 16px of block padding: a target lines up inside it, as upstream's does.
    const PADDING = 16

    async function setup() {
      const transcript = new Transcript([...turn(1, 300), ...turn(2, 300), ...turn(3, 300)])
      transcript.defaultScrollPosition = 'start'
      transcript.padding = PADDING
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      return { transcript, chat }
    }

    test('align start: the padding, then the margin, above the row', async function (assert) {
      const { transcript, chat } = await setup()
      transcript.scroller.scrollToMessage('u2')
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), PADDING)
      transcript.scroller.scrollToMessage('u2', { scrollMargin: 8 })
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), PADDING + 8)
      await a11yAudit()
    })

    test('align center: in the middle of the viewport inside its padding', async function (assert) {
      const { transcript, chat } = await setup()
      transcript.scroller.scrollToMessage('u2', { align: 'center' })
      await chat.settle()
      const inset = 300 - 2 * PADDING
      assert.strictEqual(Math.round(chat.itemTop('u2')), PADDING + (inset - 60) / 2)
      await a11yAudit()
    })

    test('align end: its bottom the padding above the viewport bottom', async function (assert) {
      const { transcript, chat } = await setup()
      transcript.scroller.scrollToMessage('u2', { align: 'end' })
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), 300 - PADDING - 60)
      await a11yAudit()
    })

    test('align nearest: a row in view stays put, one out of view comes to the nearer edge', async function (assert) {
      const { transcript, chat } = await setup()
      transcript.scroller.scrollToMessage('u1', { align: 'nearest' })
      await chat.settle()
      assert.true(chat.isAtStart, 'u1 is in view already')

      transcript.scroller.scrollToMessage('a1', { align: 'nearest' })
      await chat.settle()
      assert.strictEqual(
        Math.round(chat.itemTop('a1')),
        300 - PADDING - 300,
        'a1 runs past the bottom: its bottom comes up to the padding',
      )

      transcript.scroller.scrollToMessage('u3', { align: 'nearest' })
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u3')), 300 - PADDING - 60, 'below: to the bottom')

      transcript.scroller.scrollToMessage('u1', { align: 'nearest' })
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u1')), PADDING, 'above: to the top')
      await a11yAudit()
    })

    test('the end counts the bottom padding', async function (assert) {
      const { transcript, chat } = await setup()
      transcript.scroller.scrollToEnd()
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('a3') + 300), 300 - PADDING, 'a3 ends 16px up')
      assert.false(chat.canScrollToEnd)
      await a11yAudit()
    })
  })

  module('visibility', function () {
    test('Visibility tracks the reader only while one is rendered', async function (assert) {
      const transcript = new Transcript([...turn(1, 300), ...turn(2, 300), ...turn(3, 300)])
      transcript.defaultScrollPosition = 'start'
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.deepEqual(transcript.scroller.state.visibility, EMPTY, 'nothing watches yet')

      transcript.watching = true
      await chat.settle()
      assert.deepEqual(transcript.scroller.state.visibility, {
        currentAnchorId: 'u1',
        visibleMessageIds: ['u1', 'a1'],
      })

      transcript.watching = false
      await chat.settle()
      assert.deepEqual(transcript.scroller.state.visibility, EMPTY, 'none rendered: cleared')
      await chat.scrollTo(chat.item('u2').offsetTop - PEEK)
      assert.deepEqual(transcript.scroller.state.visibility, EMPTY, 'and no longer tracked')
      await a11yAudit()
    })

    test('observeVisibility() tracks until the last watcher stops', async function (assert) {
      const transcript = new Transcript([...turn(1, 300), ...turn(2, 300), ...turn(3, 300)])
      transcript.defaultScrollPosition = 'start'
      await renderTranscript(transcript)
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      const { state } = transcript.scroller
      const stopFirst = state.observeVisibility()
      const stopSecond = state.observeVisibility()
      await chat.settle()
      assert.strictEqual(state.visibility.currentAnchorId, 'u1')

      stopFirst()
      stopFirst()
      await chat.scrollTo(chat.item('u2').offsetTop - PEEK)
      assert.strictEqual(state.visibility.currentAnchorId, 'u2', 'one still watches')

      stopSecond()
      await chat.settle()
      assert.deepEqual(state.visibility, EMPTY, 'the last one stopped')
      await chat.scrollTo(chat.item('u3').offsetTop - PEEK)
      assert.deepEqual(state.visibility, EMPTY)
      await a11yAudit()
    })
  })

  module('the parts', function () {
    test('@as renders each part as another tag, and the scroller still works', async function (assert) {
      const transcript = new Transcript([...turn(1, 300), ...turn(2, 300)])
      let api: MessageScrollerApi | undefined
      const keep = (s: MessageScrollerApi) => void (api = s)
      await render(
        <template>
          <div style="height: 300px; width: 320px">
            <MessageScrollerProvider @defaultScrollPosition="start" as |s|>
              {{keep s}}
              <s.Root @as="section" @name="chat" style="position: relative; height: 100%">
                <s.Viewport @as="section" style="height: 100%; overflow-y: auto">
                  <s.Content @as="section" style="display: flex; flex-direction: column; gap: 24px">
                    {{#each transcript.rows key="id" as |row|}}
                      <s.Item
                        @as="article"
                        @messageId={{row.id}}
                        @scrollAnchor={{row.anchor}}
                        style={{row.style}}
                      >{{row.id}}</s.Item>
                    {{/each}}
                  </s.Content>
                </s.Viewport>
                <s.Button @as="div" role="button" tabindex="0" @behavior="auto" />
              </s.Root>
            </MessageScrollerProvider>
          </div>
        </template>,
      )
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      assert.dom(chat.element).hasTagName('section')
      assert.dom(chat.viewport).hasTagName('section').hasAttribute('role', 'region')
      assert.dom(chat.content).hasTagName('section').hasAttribute('role', 'log')
      assert.dom(chat.item('u1')).hasTagName('article')
      assert.dom(chat.button()).hasTagName('div').hasAttribute('tabindex', '0')
      assert.true(api!.scrollToMessage('u2'))
      await chat.settle()
      assert.strictEqual(Math.round(chat.itemTop('u2')), 0)
      await chat.clickButton()
      assert.true(chat.isAtEnd)
      assert.dom(chat.button()).hasAttribute('tabindex', '-1').hasAttribute('inert')
      await a11yAudit()
    })

    test('the button runs a click listener of yours first, and preventDefault() stops its scroll', async function (assert) {
      const transcript = new Transcript([...turn(1, 300), ...turn(2, 300)])
      const clicks: string[] = []
      const take = (event: MouseEvent) => {
        clicks.push('yours')
        if (clicks.length === 1) event.preventDefault()
      }
      await render(
        <template>
          <div style="height: 300px; width: 320px">
            <MessageScrollerProvider @defaultScrollPosition="start" as |s|>
              <s.Root @name="chat" style="position: relative; height: 100%">
                <s.Viewport style="height: 100%; overflow-y: auto">
                  <s.Content style="display: flex; flex-direction: column; gap: 24px">
                    {{#each transcript.rows key="id" as |row|}}
                      <s.Item @messageId={{row.id}} style={{row.style}}>{{row.id}}</s.Item>
                    {{/each}}
                  </s.Content>
                </s.Viewport>
                <s.Button @behavior="auto" {{on "click" take}} />
              </s.Root>
            </MessageScrollerProvider>
          </div>
        </template>,
      )
      const chat = new MessageScrollerHarness('chat')
      await chat.settle()
      await chat.clickButton()
      assert.deepEqual(clicks, ['yours'])
      assert.true(chat.isAtStart, 'prevented: it did not scroll')
      assert.true(chat.isButtonActive())
      await chat.clickButton()
      assert.deepEqual(clicks, ['yours', 'yours'])
      assert.true(chat.isAtEnd, 'not prevented: it scrolled')
      await a11yAudit()
    })
  })
})
