import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { htmlSafe } from '@ember/template'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  MessageScrollerConsumer,
  MessageScrollerProvider as HeadlessProvider,
  messageScrollerButton,
  type MessageScrollerDefaultScrollPosition,
  type MessageScrollerScrollAlign,
  type MessageScrollerScrollOptions,
} from '@ember-joinery/primitives/message-scroller'
import { MessageScrollerItem, MessageScrollerProvider } from '@ember-joinery/ember'
import { ButtonHarness, MessageScrollerHarness, tab } from '@ember-joinery/test-support'

/** The commands the provider yields. */
interface Commands {
  scrollToMessage: (messageId: string, options?: MessageScrollerScrollOptions) => boolean
}

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

/** The rows, and the provider's arguments, for a test to change. */
class Transcript {
  @tracked rows: Row[]
  @tracked autoScroll = false
  @tracked defaultScrollPosition: MessageScrollerDefaultScrollPosition | undefined
  @tracked peek: number | undefined
  constructor(rows: Row[] = []) {
    this.rows = rows
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
}

const join = (ids: string[]) => ids.join(',')
const jump = (scroller: Commands, messageId: string) => void scroller.scrollToMessage(messageId)

/** A user's turn (an anchor) and the reply after it. */
const turn = (n: number, reply: number) => [new Row(`u${n}`, 60, true), new Row(`a${n}`, reply)]

// The rows are 24px apart in Nova (gap-6), in a 300px viewport.
const GAP = 24
const PEEK = 64

function renderTranscript(transcript: Transcript) {
  return render(
    <template>
      <div style="height: 300px; width: 320px">
        <MessageScrollerProvider
          @autoScroll={{transcript.autoScroll}}
          @defaultScrollPosition={{transcript.defaultScrollPosition}}
          @scrollPreviousItemPeek={{transcript.peek}}
          as |s|
        >
          <s.Root @name="chat">
            <s.Viewport>
              <s.Content>
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

module('Integration | components | message-scroller', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and attributes on every part, and the style sheet styles them', async function (assert) {
    await renderTranscript(new Transcript([...turn(1, 100)]))
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert
      .dom(chat.element)
      .hasClass('jn-message-scroller')
      .hasClass('group/message-scroller')
      .hasAttribute('data-slot', 'message-scroller')
    assert
      .dom(chat.viewport)
      .hasClass('jn-message-scroller-viewport')
      .hasAttribute('data-slot', 'message-scroller-viewport')
      .hasAttribute('role', 'region')
      .hasAttribute('aria-label', 'Messages')
      .hasAttribute('tabindex', '0')
    assert
      .dom(chat.content)
      .hasClass('jn-message-scroller-content')
      .hasAttribute('data-slot', 'message-scroller-content')
      .hasAttribute('role', 'log')
      .hasAttribute('aria-relevant', 'additions')
    const spacer = chat.content.querySelector('[data-message-scroller-spacer]')!
    assert.dom(spacer).hasAttribute('aria-hidden', 'true').hasAttribute('hidden')
    assert
      .dom(chat.item('u1'))
      .hasClass('jn-message-scroller-item')
      .hasAttribute('data-slot', 'message-scroller-item')
      .hasAttribute('data-message-id', 'u1')
      .hasAttribute('data-scroll-anchor', 'true')
    assert.dom(chat.item('a1')).hasAttribute('data-scroll-anchor', 'false')
    assert.deepEqual(chat.messageIds, ['u1', 'a1'])
    assert.deepEqual(chat.anchorIds, ['u1'])
    assert.strictEqual(chat.label, 'Messages')

    const button = new ButtonHarness({ within: chat })
    assert
      .dom(button.element)
      .hasClass('jn-message-scroller-button')
      .hasAttribute('data-slot', 'message-scroller-button')
      .hasAttribute('data-direction', 'end')
      .hasAttribute('type', 'button')
    assert.strictEqual(button.variant, 'secondary', "upstream's default")
    assert.strictEqual(button.size, 'icon-sm')
    assert.strictEqual(button.label, 'Scroll to end')

    const root = getComputedStyle(chat.element)
    assert.strictEqual(root.display, 'flex')
    assert.strictEqual(root.flexDirection, 'column')
    assert.strictEqual(root.overflow, 'hidden')
    assert.strictEqual(root.position, 'relative')
    assert.strictEqual(root.height, '300px', 'size-full: it fills its parent')
    const viewport = getComputedStyle(chat.viewport)
    assert.strictEqual(viewport.overflowY, 'auto')
    assert.strictEqual(viewport.overscrollBehaviorY, 'contain')
    assert.strictEqual(viewport.scrollbarWidth, 'thin')
    assert.strictEqual(viewport.scrollbarGutter, 'stable')
    const content = getComputedStyle(chat.content)
    assert.strictEqual(content.display, 'flex')
    assert.strictEqual(content.rowGap, `${GAP}px`, "Nova's gap-6")
    const item = getComputedStyle(chat.item('u1'))
    assert.strictEqual(item.contentVisibility, 'auto', 'a row far out of view skips its rendering')
    assert.strictEqual(item.flexShrink, '0')
    await a11yAudit()
  })

  test('a saved transcript opens at the end, hidden until it gets there', async function (assert) {
    const transcript = new Transcript([...turn(1, 200), ...turn(2, 400)])
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.true(chat.isAtEnd, 'the default, end')
    assert.false(chat.isPendingScroll, 'shown once it is there')
    assert.true(chat.canScrollToStart)
    assert.false(chat.canScrollToEnd)
    assert.false(chat.isButtonActive(), 'nothing below: the button is out of the way')
    assert.dom(chat.button()).hasAttribute('inert').hasAttribute('tabindex', '-1')
    assert.strictEqual(getComputedStyle(chat.button()).pointerEvents, 'none', 'and faded out')
    await a11yAudit()
  })

  test('@defaultScrollPosition="start" opens at the top, with nothing to hide', async function (assert) {
    const transcript = new Transcript([...turn(1, 200), ...turn(2, 400)])
    transcript.defaultScrollPosition = 'start'
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    assert.false(chat.isPendingScroll, 'start needs no hold')
    await chat.settle()
    assert.true(chat.isAtStart)
    assert.true(chat.canScrollToEnd)
    assert.true(chat.isButtonActive())
    assert.dom(chat.button()).doesNotHaveAttribute('inert').doesNotHaveAttribute('tabindex')
    await a11yAudit()
  })

  test('@defaultScrollPosition="last-anchor" opens at the last turn, with the previous one peeking', async function (assert) {
    const transcript = new Transcript([...turn(1, 200), ...turn(2, 400)])
    transcript.defaultScrollPosition = 'last-anchor'
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK, 'the last turn, 64px down')
    assert.true(chat.isItemVisible('a1'), 'the previous reply peeks above it')
    assert.false(chat.isAtEnd)
    assert.true(chat.canScrollToEnd)
    await a11yAudit()
  })

  test('"last-anchor" opens at the end when the last turn fits, or there is no anchor', async function (assert) {
    const transcript = new Transcript([...turn(1, 400), ...turn(2, 100)])
    transcript.defaultScrollPosition = 'last-anchor'
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.true(chat.isAtEnd, 'the last turn fits: it opens at the end')

    transcript.rows = []
    await settled()
    transcript.rows = [new Row('m1', 400), new Row('m2', 400)]
    await chat.settle()
    assert.deepEqual(chat.messageIds, ['m1', 'm2'])
    await a11yAudit()
  })

  test('an empty transcript is shown at once', async function (assert) {
    await renderTranscript(new Transcript())
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.false(chat.isPendingScroll)
    assert.deepEqual(chat.scrollable, { start: false, end: false })
    assert.false(chat.isButtonActive())
    await a11yAudit()
  })

  test('the button scrolls to the end, and steps out of the way', async function (assert) {
    const transcript = new Transcript([...turn(1, 200), ...turn(2, 400)])
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    await chat.scrollTo(0)
    assert.true(chat.canScrollToEnd, 'more below')
    assert.true(chat.isButtonActive())
    const button = new ButtonHarness({ within: chat })
    await button.focus()
    await chat.clickButton()
    assert.true(chat.isAtEnd, 'it scrolled to the end')
    assert.false(button.isFocused, 'it gave up focus, as it goes inert')
    assert.false(chat.isButtonActive())
    assert.false(chat.canScrollToEnd)
    await a11yAudit()
  })

  test('a new anchored turn settles near the top, with room below it for the reply', async function (assert) {
    const transcript = new Transcript([...turn(1, 400)])
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.true(chat.isAtEnd)

    transcript.append(new Row('u2', 60, true))
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK, 'the new turn, 64px down')
    assert.true(chat.isItemVisible('a1'), 'with the previous reply peeking above')
    const spacer = chat.content.querySelector<HTMLElement>('[data-message-scroller-spacer]')!
    assert.false(spacer.hidden, 'a spacer makes the room')

    transcript.append(new Row('a2', 100))
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK, 'the reply arriving moves nothing')

    transcript.row('a2').height = 600
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK, 'nor does it growing past the edge')
    assert.true(spacer.hidden, 'the reply took up the room')
    assert.true(chat.canScrollToEnd)
    await a11yAudit()
  })

  test('@scrollPreviousItemPeek sets how much of the previous turn stays in view', async function (assert) {
    const transcript = new Transcript([...turn(1, 400)])
    transcript.peek = 120
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    transcript.append(new Row('u2', 60, true))
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), 120)
    await a11yAudit()
  })

  test('@autoScroll follows a streamed reply at the end, until the reader scrolls away', async function (assert) {
    const transcript = new Transcript([new Row('u1', 60, true), new Row('a1', 100)])
    transcript.autoScroll = true
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()

    transcript.row('a1').height = 500
    await chat.settle()
    assert.true(chat.isAtEnd, 'it follows the reply as it grows')
    assert.false(chat.canScrollToEnd, 'and says there is nothing below while it follows')

    await chat.scrollBy(-120)
    const top = chat.scrollTop
    transcript.row('a1').height = 700
    await chat.settle()
    assert.strictEqual(chat.scrollTop, top, 'scrolled away: the stream leaves the reader alone')
    assert.true(chat.canScrollToEnd)
    assert.true(chat.isButtonActive())

    await chat.clickButton()
    assert.true(chat.isAtEnd)
    transcript.row('a1').height = 900
    await chat.settle()
    assert.true(chat.isAtEnd, 'the button follows the end again')
    await a11yAudit()
  })

  test('@autoScroll: a scroll key releases following too', async function (assert) {
    const transcript = new Transcript([new Row('u1', 60, true), new Row('a1', 500)])
    transcript.autoScroll = true
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.true(chat.isAtEnd)
    await chat.focus()
    await chat.pressKey('PageUp')
    const top = chat.scrollTop
    assert.true(top < chat.maxScrollTop, 'PageUp scrolled up')
    transcript.row('a1').height = 800
    await chat.settle()
    assert.strictEqual(chat.scrollTop, top, 'and the stream left it there')
    await chat.pressKey('End')
    assert.true(chat.isAtEnd)
    await a11yAudit()
  })

  test('@autoScroll with an anchored turn: it holds the turn, then follows once the reply fills the view', async function (assert) {
    const transcript = new Transcript([...turn(1, 400)])
    transcript.autoScroll = true
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    transcript.append(new Row('u2', 60, true), new Row('a2', 20))
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK, 'the new turn is held near the top')
    transcript.row('a2').height = 100
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), PEEK, 'still held as the reply streams')
    transcript.row('a2').height = 700
    await chat.settle()
    assert.true(chat.isAtEnd, 'the reply filled the view: it follows the end')
    transcript.row('a2').height = 900
    await chat.settle()
    assert.true(chat.isAtEnd)
    await a11yAudit()
  })

  test('history prepended above keeps the reader on the row they were reading', async function (assert) {
    const transcript = new Transcript([...turn(3, 200), ...turn(4, 300)])
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    await chat.scrollTo(150)
    const [first] = chat.visibleIds
    const before = chat.itemTop(first!)
    transcript.prepend(...turn(1, 300), ...turn(2, 300))
    await chat.settle()
    assert.deepEqual(chat.messageIds.slice(0, 2), ['u1', 'a1'])
    assert.true(Math.abs(chat.itemTop(first!) - before) <= 1, `${first} stayed where it was`)
    await a11yAudit()
  })

  test('scrollToMessage lines a row up, and the commands say whether they could', async function (assert) {
    const transcript = new Transcript([...turn(1, 300), ...turn(2, 300), ...turn(3, 300)])
    let jump: (id: string, align?: MessageScrollerScrollAlign, margin?: number) => boolean
    const capture = (s: Commands) => {
      jump = (id, align = 'start', scrollMargin) => s.scrollToMessage(id, { align, scrollMargin })
    }
    await render(
      <template>
        <div style="height: 300px; width: 320px">
          <MessageScrollerProvider as |s|>
            {{capture s}}
            <s.Root @name="chat">
              <s.Viewport>
                <s.Content>
                  {{#each transcript.rows key="id" as |row|}}
                    <s.Item @messageId={{row.id}} @scrollAnchor={{row.anchor}} style={{row.style}}>
                      {{row.id}}
                    </s.Item>
                  {{/each}}
                </s.Content>
              </s.Viewport>
            </s.Root>
          </MessageScrollerProvider>
        </div>
      </template>,
    )
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.true(jump!('u2'))
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), 0, 'align start')
    jump!('u2', 'start', 24)
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), 24, 'with a margin')
    jump!('u2', 'center')
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), (300 - 60) / 2, 'align center')
    jump!('a2', 'end')
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('a2')), 0, 'align end: its bottom at the bottom')
    jump!('a2', 'nearest')
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('a2')), 0, 'nearest: in view, it stays put')
    assert.false(jump!('missing'), 'a row that is not there')
    await a11yAudit()
  })

  test('scrollToMessage before any row has rendered waits for it', async function (assert) {
    const transcript = new Transcript()
    let api: Commands | undefined
    const capture = (s: Commands) => void (api = s)
    await render(
      <template>
        <div style="height: 300px; width: 320px">
          <MessageScrollerProvider as |s|>
            {{capture s}}
            <s.Root @name="chat">
              <s.Viewport>
                <s.Content>
                  {{#each transcript.rows key="id" as |row|}}
                    <s.Item @messageId={{row.id}} @scrollAnchor={{row.anchor}} style={{row.style}}>
                      {{row.id}}
                    </s.Item>
                  {{/each}}
                </s.Content>
              </s.Viewport>
            </s.Root>
          </MessageScrollerProvider>
        </div>
      </template>,
    )
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.true(api!.scrollToMessage('u2'), 'queued')
    transcript.rows = [...turn(1, 300), ...turn(2, 300), ...turn(3, 300)]
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), 0, 'the permalink landed once the row came')
    await a11yAudit()
  })

  test('the provider yields the scroll state, and Visibility tracks where the reader is', async function (assert) {
    const transcript = new Transcript([...turn(1, 300), ...turn(2, 300), ...turn(3, 300)])
    await render(
      <template>
        <div style="height: 300px; width: 320px">
          <MessageScrollerProvider @defaultScrollPosition="start" as |s|>
            <p data-test-state>{{if s.scrollable.start "up"}} {{if s.scrollable.end "down"}}</p>
            <s.Visibility as |v|>
              <p data-test-current>{{v.currentAnchorId}}</p>
              <p data-test-visible>{{join v.visibleMessageIds}}</p>
            </s.Visibility>
            <s.Root @name="chat">
              <s.Viewport>
                <s.Content>
                  {{#each transcript.rows key="id" as |row|}}
                    <s.Item @messageId={{row.id}} @scrollAnchor={{row.anchor}} style={{row.style}}>
                      {{row.id}}
                    </s.Item>
                  {{/each}}
                </s.Content>
              </s.Viewport>
            </s.Root>
          </MessageScrollerProvider>
        </div>
      </template>,
    )
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.dom('[data-test-state]').hasText('down')
    assert.dom('[data-test-current]').hasText('u1')
    assert.dom('[data-test-visible]').hasText('u1,a1')
    await chat.scrollTo(chat.item('u2').offsetTop - PEEK)
    assert.dom('[data-test-state]').hasText('up down')
    assert.dom('[data-test-current]').hasText('u2', 'the turn at the reading line')
    await chat.scrollTo(chat.maxScrollTop)
    assert.dom('[data-test-state]').hasText('up')
    assert.dom('[data-test-current]').hasText('u3')
    await a11yAudit()
  })

  test('the viewport is in the tab order, and the button joins it only when it has somewhere to go', async function (assert) {
    const transcript = new Transcript([...turn(1, 200), ...turn(2, 400)])
    await renderTranscript(transcript)
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    await tab()
    assert.dom(chat.viewport).isFocused('the viewport takes focus, so a keyboard can scroll it')
    await tab()
    assert.dom(chat.button()).isNotFocused('an inactive button is no stop')
    await chat.scrollTo(0)
    await chat.focus()
    await tab()
    assert.dom(chat.button()).isFocused('active, it is one')
    await a11yAudit()
  })

  test('@direction="start": the button scrolls to the top, and its arrow points up', async function (assert) {
    const transcript = new Transcript([...turn(1, 200), ...turn(2, 400)])
    await render(
      <template>
        <div style="height: 300px; width: 320px">
          <MessageScrollerProvider as |s|>
            <s.Root @name="chat">
              <s.Viewport>
                <s.Content>
                  {{#each transcript.rows key="id" as |row|}}
                    <s.Item @messageId={{row.id}} style={{row.style}}>{{row.id}}</s.Item>
                  {{/each}}
                </s.Content>
              </s.Viewport>
              <s.Button @direction="start" />
            </s.Root>
          </MessageScrollerProvider>
        </div>
      </template>,
    )
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    const button = new ButtonHarness({ within: chat })
    assert.strictEqual(button.label, 'Scroll to start')
    assert.dom(chat.button('start')).hasAttribute('data-direction', 'start')
    assert.true(chat.isButtonActive('start'))
    const svg = getComputedStyle(chat.button('start').querySelector('svg')!)
    assert.notStrictEqual(svg.rotate === 'none' ? svg.transform : svg.rotate, 'none', 'rotate-180')
    await chat.clickButton('start')
    assert.true(chat.isAtStart)
    assert.false(chat.isButtonActive('start'))
    await a11yAudit()
  })

  test('RTL: the button stays in the middle', async function (assert) {
    const transcript = new Transcript([...turn(1, 200), ...turn(2, 400)])
    transcript.defaultScrollPosition = 'start'
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="height: 300px; width: 320px">
            <MessageScrollerProvider @defaultScrollPosition="start" as |s|>
              <s.Root @name="chat">
                <s.Viewport @label="الرسائل">
                  <s.Content>
                    {{#each transcript.rows key="id" as |row|}}
                      <s.Item @messageId={{row.id}} style={{row.style}}>{{row.id}}</s.Item>
                    {{/each}}
                  </s.Content>
                </s.Viewport>
                <s.Button @label="انتقل إلى الأحدث" />
              </s.Root>
            </MessageScrollerProvider>
          </div>
        </DirectionProvider>
      </template>,
    )
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert.strictEqual(chat.label, 'الرسائل')
    const frame = chat.element.getBoundingClientRect()
    const button = chat.button().getBoundingClientRect()
    const middle = (box: DOMRect) => box.left + box.width / 2
    assert.true(Math.abs(middle(button) - middle(frame)) < 1, 'centred, right to left too')
    assert.strictEqual(new ButtonHarness({ within: chat }).label, 'انتقل إلى الأحدث')
    await a11yAudit()
  })

  test('the parts on their own find the provider, and the headless ones are unstyled', async function (assert) {
    const transcript = new Transcript([...turn(1, 200), ...turn(2, 400)])
    await render(
      <template>
        <div style="height: 300px; width: 320px">
          <HeadlessProvider @defaultScrollPosition="start" as |s|>
            <s.Root @name="chat" style="position: relative; height: 100%; overflow: hidden">
              <s.Viewport style="height: 100%; overflow-y: auto">
                <s.Content style="display: flex; flex-direction: column; gap: 24px">
                  {{#each transcript.rows key="id" as |row|}}
                    <MessageScrollerItem
                      @messageId={{row.id}}
                      @scrollAnchor={{row.anchor}}
                      style={{row.style}}
                    >{{row.id}}</MessageScrollerItem>
                  {{/each}}
                </s.Content>
              </s.Viewport>
              <s.Button />
              <MessageScrollerConsumer as |api|>
                <button
                  type="button"
                  data-test-own
                  {{messageScrollerButton scroller=api.state behavior="auto"}}
                >Jump to latest</button>
                <button type="button" data-test-jump {{on "click" (fn jump api "u2")}}>
                  Jump to the second turn
                </button>
              </MessageScrollerConsumer>
            </s.Root>
          </HeadlessProvider>
        </div>
      </template>,
    )
    const chat = new MessageScrollerHarness('chat')
    await chat.settle()
    assert
      .dom(chat.element)
      .doesNotHaveClass('jn-message-scroller')
      .doesNotHaveAttribute('data-slot')
    assert
      .dom(chat.item('u1'))
      .hasClass('jn-message-scroller-item', 'the styled item, inside the headless provider')
    const [headless] = chat.parts('button')
    assert.dom(headless).hasText('Scroll to end', 'the headless button shows its label')
    assert
      .dom('[data-test-own]')
      .hasAttribute('data-active', 'true')
      .hasAttribute('data-direction', 'end')
    await settled()
    ;(document.querySelector('[data-test-jump]') as HTMLElement).click()
    await chat.settle()
    assert.strictEqual(Math.round(chat.itemTop('u2')), 0)
    ;(document.querySelector('[data-test-own]') as HTMLElement).click()
    await chat.settle()
    assert.true(chat.isAtEnd, 'your own element as the button')
    assert.dom('[data-test-own]').hasAttribute('data-active', 'false').hasAttribute('inert')
    await a11yAudit()
  })
})
