import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { LinkTo } from '@ember/routing'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Bubble, BubbleGroup, Button, Message, type BubbleVariant } from '@ember-joinery/ember'
import {
  BubbleGroupHarness,
  BubbleHarness,
  ButtonHarness,
  MessageHarness,
  tab,
} from '@ember-joinery/test-support'

const VARIANTS: BubbleVariant[] = [
  'default',
  'secondary',
  'muted',
  'tinted',
  'outline',
  'ghost',
  'destructive',
]

/**
 * The audits, but for the destructive bubble's text: upstream draws it `--destructive` on its
 * own 10% tint, under the 4.5:1 WCAG AA asks of its 14px text (the Bubble page's
 * Accessibility notes say so). One audit runs every other rule on it; the other checks the
 * contrast of everything else.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_DESTRUCTIVE_TEXT = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="bubble"][data-variant="destructive"] > [data-slot="bubble-content"]']],
}

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/**
 * How much the test container scales what it shows: a distance measured on the screen
 * (`getBoundingClientRect()`) is this many times its CSS length.
 */
const scaleOf = (element: HTMLElement) =>
  element.getBoundingClientRect().width / element.offsetWidth
const TRANSPARENT = 'rgba(0, 0, 0, 0)'

module('Integration | components | bubble', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Bubble @name="hello" as |b|>
          <b.Content>I checked the registry output and removed the stale route.</b.Content>
          <b.Reactions role="img" aria-label="Reaction: thumbs up"><span>👍</span></b.Reactions>
        </Bubble>
      </template>,
    )
    const bubble = new BubbleHarness('hello')
    assert
      .dom(bubble.element)
      .hasTagName('div')
      .hasClass('jn-bubble')
      .hasClass('group/bubble', 'the marker its content looks for')
      .hasClass('jn-bubble-variant-default')
      .hasAttribute('data-slot', 'bubble')
      .hasAttribute('data-variant', 'default', "upstream's default")
      .hasAttribute('data-align', 'start', "upstream's default")
    assert
      .dom(bubble.content)
      .hasTagName('div')
      .hasClass('jn-bubble-content')
      .hasAttribute('data-slot', 'bubble-content')
    assert
      .dom(bubble.reactions)
      .hasClass('jn-bubble-reactions')
      .hasClass('jn-bubble-reactions-side-bottom', "upstream's default side")
      .hasClass('jn-bubble-reactions-align-end', "upstream's default alignment")
      .hasAttribute('data-slot', 'bubble-reactions')
      .hasAttribute('data-side', 'bottom')
      .hasAttribute('data-align', 'end')
      .hasAttribute('role', 'img', 'your attributes')
    assert.strictEqual(bubble.text, 'I checked the registry output and removed the stale route.')
    assert.strictEqual(bubble.variant, 'default')
    assert.strictEqual(bubble.align, 'start')
    assert.true(bubble.hasReactions)
    assert.strictEqual(bubble.reactionsLabel, 'Reaction: thumbs up')
    assert.strictEqual(bubble.reactionsSide, 'bottom')
    assert.strictEqual(bubble.reactionsAlign, 'end')
    assert.false(bubble.isInteractive)
    await a11yAudit()
  })

  test('every variant renders its classes, and the style sheet styles each', async function (assert) {
    await render(
      <template>
        <div style="width: 400px">
          {{#each VARIANTS as |variant|}}
            <Bubble @variant={{variant}} @name={{variant}} as |b|>
              <b.Content>The {{variant}} bubble.</b.Content>
            </Bubble>
          {{/each}}
        </div>
      </template>,
    )
    const content = (name: string) => getComputedStyle(new BubbleHarness(name).content)
    for (const variant of VARIANTS) {
      const bubble = new BubbleHarness(variant)
      assert.strictEqual(bubble.variant, variant)
      assert.dom(bubble.element).hasClass(`jn-bubble-variant-${variant}`)
    }
    const primary = content('default')
    assert.notStrictEqual(primary.backgroundColor, TRANSPARENT, 'bg-primary')
    assert.notStrictEqual(primary.color, content('muted').color, 'text-primary-foreground')
    assert.notStrictEqual(content('secondary').backgroundColor, TRANSPARENT, 'bg-secondary')
    assert.notStrictEqual(content('muted').backgroundColor, TRANSPARENT, 'bg-muted')
    assert.notStrictEqual(content('tinted').backgroundColor, TRANSPARENT, 'a tint of the primary')
    assert.notStrictEqual(
      content('tinted').backgroundColor,
      primary.backgroundColor,
      'softer than the primary',
    )
    assert.strictEqual(content('outline').borderTopWidth, '1px')
    assert.notStrictEqual(content('outline').borderTopColor, TRANSPARENT, 'border-border')
    assert.strictEqual(content('default').borderTopColor, TRANSPARENT, 'a border, transparent')
    assert.notStrictEqual(content('destructive').backgroundColor, TRANSPARENT, 'a tint of red')
    assert.notStrictEqual(content('destructive').color, content('muted').color, 'text-destructive')

    // Nova's content: rounded-xl, px-3 py-2, text-sm leading-relaxed.
    assert.strictEqual(primary.paddingInlineStart, '12px', 'px-3')
    assert.strictEqual(primary.paddingTop, '8px', 'py-2')
    assert.strictEqual(primary.fontSize, '14px', 'text-sm')
    assert.strictEqual(primary.lineHeight, '22.75px', 'leading-relaxed')
    assert.strictEqual(primary.borderTopLeftRadius, '14px', 'rounded-xl')
    assert.strictEqual(primary.overflow, 'hidden')
    assert.strictEqual(primary.overflowWrap, 'break-word', 'wrap-break-word')

    const ghost = content('ghost')
    assert.strictEqual(ghost.backgroundColor, TRANSPARENT, 'unframed')
    assert.strictEqual(ghost.paddingTop, '0px', 'p-0')
    assert.strictEqual(ghost.borderTopLeftRadius, '0px', 'rounded-none')

    const root = (name: string) => getComputedStyle(new BubbleHarness(name).element)
    assert.strictEqual(root('default').display, 'flex')
    assert.strictEqual(root('default').flexDirection, 'column')
    assert.strictEqual(root('default').rowGap, '4px', 'gap-1')
    assert.strictEqual(root('default').position, 'relative')
    assert.strictEqual(root('default').maxWidth, '80%', 'up to 80% of the row')
    assert.strictEqual(root('ghost').maxWidth, '100%', 'data-[variant=ghost]:max-w-full')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_DESTRUCTIVE_TEXT, { runOnly: ['color-contrast'] })
  })

  test('a bubble sizes to its content, up to 80% of the row', async function (assert) {
    await render(
      <template>
        <div style="width: 400px; display: flex; flex-direction: column">
          <Bubble @name="short" as |b|><b.Content>Hi</b.Content></Bubble>
          <Bubble @name="long" as |b|>
            <b.Content>
              Something went wrong with the build. The libraries are not installed correctly. Try
              running the build again.
            </b.Content>
          </Bubble>
          <Bubble @variant="ghost" @name="ghost" as |b|>
            <b.Content>
              Ghost bubbles are full width and can take the full width of the container, as
              assistant text does.
            </b.Content>
          </Bubble>
        </div>
      </template>,
    )
    const width = (name: string) => new BubbleHarness(name).element.offsetWidth
    assert.ok(width('short') < 60, 'w-fit: as wide as its text')
    assert.strictEqual(Math.round(width('long')), 320, 'max-w-[80%]')
    assert.strictEqual(Math.round(width('ghost')), 400, 'a ghost bubble takes the row')
    await a11yAudit()
  })

  test('@align="end" puts the bubble and its content at the end, and so does the message around it', async function (assert) {
    class State {
      @tracked align: 'start' | 'end' = 'end'
    }
    const state = new State()
    await render(
      <template>
        <div style="width: 400px; display: flex; flex-direction: column">
          <Bubble @align={{state.align}} @name="mine" as |b|><b.Content>Hey there!</b.Content></Bubble>
        </div>
        <div style="width: 400px">
          <Message @align="end" @name="row" as |m|>
            <m.Content>
              <Bubble @name="inside" as |b|><b.Content>Sure.</b.Content></Bubble>
            </m.Content>
          </Message>
        </div>
      </template>,
    )
    const mine = new BubbleHarness('mine')
    assert.strictEqual(mine.align, 'end')
    assert.strictEqual(
      getComputedStyle(mine.element).alignSelf,
      'flex-end',
      'data-[align=end]:self-end',
    )
    assert.strictEqual(
      getComputedStyle(mine.content).alignSelf,
      'flex-end',
      'group-data-[align=end]/bubble:self-end',
    )
    const parent = mine.element.parentElement!.getBoundingClientRect()
    assert.strictEqual(
      Math.round(mine.element.getBoundingClientRect().right),
      Math.round(parent.right),
      'at the end of the row',
    )

    state.align = 'start'
    await settled()
    assert.strictEqual(mine.align, 'start', 'the attribute follows')
    assert.strictEqual(
      Math.round(mine.element.getBoundingClientRect().left),
      Math.round(parent.left),
      'back at the start',
    )

    const inside = new MessageHarness('row').find(BubbleHarness)
    assert.strictEqual(inside.align, 'start', 'its own @align is left alone')
    assert.strictEqual(
      getComputedStyle(inside.element).alignSelf,
      'flex-end',
      "group-data-[align=end]/message:self-end: the message's side wins",
    )
    await a11yAudit()
  })

  test('reactions overlap the bubble edge, at the side and end they are given', async function (assert) {
    await render(
      <template>
        <div
          style="width: 400px; display: flex; flex-direction: column; gap: 48px; padding: 24px 0"
        >
          <Bubble @variant="muted" @name="bottom-end" as |b|>
            <b.Content>Bold. Fine I'll add some tests.</b.Content>
            <b.Reactions role="img" aria-label="Reactions: eyes, rocket"><span>👀</span><span
              >🚀</span></b.Reactions>
          </Bubble>
          <Bubble @variant="muted" @name="top-start" as |b|>
            <b.Content>Tests passed on the first try.</b.Content>
            <b.Reactions @side="top" @align="start" role="img" aria-label="Reactions: party popper">
              <span>🎉</span>
            </b.Reactions>
          </Bubble>
          <Bubble @variant="muted" @name="button" as |b|>
            <b.Content>Are you sure I can run this command?</b.Content>
            <b.Reactions><Button @variant="ghost" @size="xs">Yes, run it</Button></b.Reactions>
          </Bubble>
        </div>
      </template>,
    )
    const bottomEnd = new BubbleHarness('bottom-end')
    const reactions = getComputedStyle(bottomEnd.reactions)
    assert.strictEqual(reactions.position, 'absolute')
    assert.strictEqual(reactions.zIndex, '10', 'z-10')
    assert.strictEqual(reactions.display, 'flex')
    assert.strictEqual(reactions.bottom, '0px', 'bottom-0')
    assert.strictEqual(reactions.insetInlineEnd, '12px', 'end-3')
    assert.ok(px(reactions.borderTopLeftRadius) >= px(reactions.height) / 2, 'rounded-full')
    assert.notStrictEqual(reactions.backgroundColor, TRANSPARENT, 'bg-muted')
    assert.notStrictEqual(reactions.boxShadow, 'none', 'ring-3 ring-card')
    assert.strictEqual(reactions.paddingInlineStart, '6px', 'px-1.5')
    const bubble = bottomEnd.element.getBoundingClientRect()
    const row = bottomEnd.reactions.getBoundingClientRect()
    assert.ok(row.top < bubble.bottom && row.bottom > bubble.bottom, 'over the bottom edge')
    const scale = scaleOf(bottomEnd.element)
    assert.strictEqual(Math.round(row.right), Math.round(bubble.right - 12 * scale), 'at the end')

    const topStart = new BubbleHarness('top-start')
    assert.strictEqual(topStart.reactionsSide, 'top')
    assert.strictEqual(topStart.reactionsAlign, 'start')
    assert
      .dom(topStart.reactions)
      .hasClass('jn-bubble-reactions-side-top')
      .hasClass('jn-bubble-reactions-align-start')
    const top = topStart.reactions.getBoundingClientRect()
    const edge = topStart.element.getBoundingClientRect()
    assert.ok(top.top < edge.top && top.bottom > edge.top, 'over the top edge')
    assert.strictEqual(Math.round(top.left), Math.round(edge.left + 12 * scale), 'start-3')

    const withButton = new BubbleHarness('button')
    assert.strictEqual(
      getComputedStyle(withButton.reactions).paddingTop,
      '0px',
      'has-[button]:p-0: the button brings its own',
    )
    assert.strictEqual(withButton.reactionsLabel, 'Yes, run it', 'without a label, its text')
    assert.strictEqual(withButton.find(ButtonHarness).label, 'Yes, run it')
    await a11yAudit()
  })

  test('content as a button: in the tab order, a focus ring, and a click', async function (assert) {
    let clicks = 0
    const reply = () => clicks++
    await render(
      <template>
        <Button @name="before">Before</Button>
        <Bubble @variant="tinted" @align="end" @name="reply" as |b|>
          <b.Content @as="button" type="button" {{on "click" reply}}>I forgot my password</b.Content>
        </Bubble>
      </template>,
    )
    const bubble = new BubbleHarness('reply')
    assert.dom(bubble.content).hasTagName('button').hasClass('jn-bubble-content')
    assert.true(bubble.isInteractive)
    const style = getComputedStyle(bubble.content)
    assert.strictEqual(style.textAlign, 'start', '[button]:text-start, not centred')
    assert.strictEqual(style.outlineStyle, 'none', '[button,a]:outline-none: the ring replaces it')
    assert.ok(style.transitionProperty.includes('color'), '[button,a]:transition-colors')
    assert.strictEqual(style.fontSize, '14px', 'the bubble text, not the browser button font')

    await new ButtonHarness('before').focus()
    await tab()
    assert.true(bubble.isFocused, 'Tab reaches it')
    if (bubble.content.matches(':focus-visible')) {
      assert.notStrictEqual(
        getComputedStyle(bubble.content).boxShadow,
        'none',
        '[button,a]:focus-visible:ring-3',
      )
    } else {
      assert.ok(true, 'this browser gave programmatic focus no focus ring')
    }
    assert.ok(
      bubble.content instanceof HTMLButtonElement,
      'a native <button>: the browser presses it on Enter and Space',
    )
    await bubble.click()
    assert.strictEqual(clicks, 1)
    await a11yAudit()
  })

  test('the content modifier makes your own element or component the content', async function (assert) {
    ;(this.owner as unknown as { setupRouter(): void }).setupRouter()
    await render(
      <template>
        <Bubble @variant="muted" @name="link" as |b|>
          <LinkTo @route="index" class="mine" {{b.content}}>Open the dashboard</LinkTo>
        </Bubble>
        <Bubble @variant="muted" @name="reactions" as |b|>
          <b.Content>Hi</b.Content>
          <ul {{b.reactions side="top" align="start"}} aria-label="Reactions">
            <li>👍</li>
          </ul>
        </Bubble>
      </template>,
    )
    const link = new BubbleHarness('link')
    assert
      .dom(link.content)
      .hasTagName('a')
      .hasAttribute('href', '/')
      .hasClass('mine')
      .hasClass('jn-bubble-content')
      .hasAttribute('data-slot', 'bubble-content')
    assert.true(link.isInteractive)
    assert.strictEqual(link.text, 'Open the dashboard')
    assert.notStrictEqual(
      getComputedStyle(link.content).backgroundColor,
      TRANSPARENT,
      "the variant's background reaches it",
    )
    const reactions = new BubbleHarness('reactions')
    assert.dom(reactions.reactions).hasTagName('ul').hasAttribute('data-side', 'top')
    assert.strictEqual(reactions.reactionsAlign, 'start')
    assert.strictEqual(getComputedStyle(reactions.reactions).position, 'absolute')
    await a11yAudit()
  })

  test('a group stacks bubbles closer, each on its own side', async function (assert) {
    await render(
      <template>
        <BubbleGroup @name="mine">
          <Bubble @align="end" as |b|><b.Content>You tell me!</b.Content></Bubble>
          <Bubble @align="end" as |b|><b.Content>It worked yesterday. You broke it!</b.Content></Bubble>
          <Bubble @align="end" as |b|><b.Content>Find the bug and fix it.</b.Content></Bubble>
        </BubbleGroup>
      </template>,
    )
    const group = new BubbleGroupHarness('mine')
    assert.dom(group.element).hasClass('jn-bubble-group').hasAttribute('data-slot', 'bubble-group')
    const style = getComputedStyle(group.element)
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.flexDirection, 'column')
    assert.strictEqual(style.rowGap, '8px', 'gap-2')
    assert.deepEqual(
      group.bubbles.map(bubble => bubble.text),
      ['You tell me!', 'It worked yesterday. You broke it!', 'Find the bug and fix it.'],
    )
    assert.true(group.bubbles.every(bubble => bubble.align === 'end'))
    await a11yAudit()
  })

  test('every part takes @as', async function (assert) {
    await render(
      <template>
        <BubbleGroup @as="section" @name="section" aria-label="Thread">
          <Bubble @as="article" @name="article" as |b|>
            <b.Content @as="p">Hello</b.Content>
            <b.Reactions @as="span">👍</b.Reactions>
          </Bubble>
        </BubbleGroup>
      </template>,
    )
    assert.dom(new BubbleGroupHarness('section').element).hasTagName('section')
    const bubble = new BubbleHarness('article')
    assert.dom(bubble.element).hasTagName('article').hasClass('jn-bubble')
    assert.dom(bubble.content).hasTagName('p').hasClass('jn-bubble-content')
    assert.dom(bubble.reactions).hasTagName('span').hasClass('jn-bubble-reactions')
    assert.strictEqual(getComputedStyle(bubble.reactions).display, 'flex')
    await a11yAudit()
  })

  test('RTL: an end bubble sits on the left, and its reactions at its left end', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="width: 400px; display: flex; flex-direction: column; gap: 48px">
            <Bubble @variant="muted" @name="start" as |b|>
              <b.Content>مرحبًا! هل تريد رؤية فقاعات الدردشة؟</b.Content>
            </Bubble>
            <Bubble @align="end" @name="end" as |b|>
              <b.Content>بالتأكيد.</b.Content>
              <b.Reactions role="img" aria-label="تفاعل: إعجاب"><span>👍</span></b.Reactions>
            </Bubble>
          </div>
        </DirectionProvider>
      </template>,
    )
    const start = new BubbleHarness('start')
    const row = start.element.parentElement!.getBoundingClientRect()
    assert.strictEqual(
      Math.round(start.element.getBoundingClientRect().right),
      Math.round(row.right),
      'the start is on the right',
    )
    const end = new BubbleHarness('end')
    const bubble = end.element.getBoundingClientRect()
    assert.strictEqual(Math.round(bubble.left), Math.round(row.left), 'the end is on the left')
    assert.strictEqual(
      Math.round(end.reactions.getBoundingClientRect().left),
      Math.round(bubble.left + 12 * scaleOf(end.element)),
      'end-3: the reactions at the left',
    )
    await a11yAudit()
  })

  test('the harness throws for a missing part, and reads no reactions as empty', async function (assert) {
    await render(
      <template>
        <Bubble @name="bare" as |b|><b.Content>Hello</b.Content></Bubble>
      </template>,
    )
    const bare = new BubbleHarness('bare')
    assert.false(bare.hasReactions)
    assert.strictEqual(bare.reactionsLabel, '')
    assert.strictEqual(bare.reactionsSide, null)
    assert.strictEqual(bare.reactionsAlign, null)
    assert.false(bare.isFocused)
    assert.throws(() => bare.reactions, /no "reactions" part found in bubble "bare"/)
    await a11yAudit()
  })
})
