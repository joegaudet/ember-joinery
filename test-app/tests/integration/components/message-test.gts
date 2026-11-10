import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Copy } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Avatar, Bubble, Button, Icon, Message, MessageGroup } from '@ember-joinery/ember'
import {
  AvatarHarness,
  BubbleHarness,
  ButtonHarness,
  MessageGroupHarness,
  MessageHarness,
} from '@ember-joinery/test-support'

// A 1×1 grey PNG, so an avatar renders without the network.
const IMAGE =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNgAAAAAgABSK+kcQAAAABJRU5ErkJggg=='

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

module('Integration | components | message', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Message @name="reply" as |m|>
          <m.Avatar>
            <Avatar as |a|>
              <a.Image @src={{IMAGE}} alt="@rabbit" />
              <a.Fallback>R</a.Fallback>
            </Avatar>
          </m.Avatar>
          <m.Content>
            <m.Header>Olivia</m.Header>
            <Bubble @variant="muted" as |b|>
              <b.Content>I already checked the logs.</b.Content>
            </Bubble>
            <m.Footer>Delivered</m.Footer>
          </m.Content>
        </Message>
      </template>,
    )
    const message = new MessageHarness('reply')
    assert
      .dom(message.element)
      .hasTagName('div')
      .hasClass('jn-message')
      .hasClass('group/message', 'the marker its parts and bubbles look for')
      .hasAttribute('data-slot', 'message')
      .hasAttribute('data-align', 'start', "upstream's default")
      .doesNotHaveAttribute('role', 'a layout, with no role of its own')
    assert
      .dom(message.avatar)
      .hasClass('jn-message-avatar')
      .hasAttribute('data-slot', 'message-avatar')
    assert
      .dom(message.content)
      .hasClass('jn-message-content')
      .hasAttribute('data-slot', 'message-content')
    assert
      .dom(message.header)
      .hasClass('jn-message-header')
      .hasAttribute('data-slot', 'message-header')
    assert
      .dom(message.footer)
      .hasClass('jn-message-footer')
      .hasAttribute('data-slot', 'message-footer')
    assert.strictEqual(message.align, 'start')
    assert.strictEqual(message.headerText, 'Olivia')
    assert.strictEqual(message.footerText, 'Delivered')
    assert.true(message.hasAvatar)
    assert.deepEqual(
      message.bubbles.map(bubble => bubble.text),
      ['I already checked the logs.'],
    )
    const avatar = message.find(AvatarHarness)
    assert.strictEqual(avatar.label, avatar.isLoaded ? '@rabbit' : 'R', 'the avatar inside it')
    assert.ok(message.text.endsWith('Olivia I already checked the logs. Delivered'))
    await a11yAudit()
  })

  test('the style sheet lays out the row, its content, header, footer and avatar', async function (assert) {
    await render(
      <template>
        <div style="width: 384px">
          <Message @name="row" as |m|>
            <m.Avatar>
              <Avatar as |a|>
                <a.Image @src={{IMAGE}} alt="@rabbit" />
                <a.Fallback>R</a.Fallback>
              </Avatar>
            </m.Avatar>
            <m.Content>
              <m.Header>Olivia</m.Header>
              <Bubble @variant="muted" as |b|><b.Content>Hi</b.Content></Bubble>
            </m.Content>
          </Message>
        </div>
      </template>,
    )
    const message = new MessageHarness('row')
    const row = getComputedStyle(message.element)
    assert.strictEqual(row.display, 'flex')
    assert.strictEqual(row.flexDirection, 'row')
    assert.strictEqual(row.columnGap, '8px', 'gap-2')
    assert.strictEqual(row.fontSize, '14px', 'text-sm')
    assert.strictEqual(row.position, 'relative')
    assert.strictEqual(px(row.width), 384, 'w-full')

    const content = getComputedStyle(message.content)
    assert.strictEqual(content.flexDirection, 'column')
    assert.strictEqual(content.rowGap, '10px', 'gap-2.5')
    assert.strictEqual(content.overflowWrap, 'break-word', 'wrap-break-word')

    const header = getComputedStyle(message.header)
    assert.strictEqual(header.fontSize, '12px', 'text-xs')
    assert.strictEqual(header.fontWeight, '500', 'font-medium')
    assert.strictEqual(header.paddingInlineStart, '12px', 'px-3, level with the text')
    assert.notStrictEqual(header.color, content.color, 'text-muted-foreground')

    const avatar = getComputedStyle(message.avatar)
    assert.strictEqual(px(avatar.minWidth), 32, 'min-w-8')
    assert.strictEqual(avatar.alignSelf, 'flex-end', 'at the bottom of the row')
    assert.strictEqual(avatar.flexShrink, '0')
    assert.strictEqual(avatar.overflow, 'hidden')
    assert.strictEqual(avatar.translate, 'none', 'without a footer, it stays put')
    await a11yAudit()
  })

  test('beside a footer, the avatar moves up to stay level with the bubble', async function (assert) {
    await render(
      <template>
        <Message @name="footer" as |m|>
          <m.Avatar>
            <Avatar as |a|>
              <a.Image @src={{IMAGE}} alt="@me" />
              <a.Fallback>ME</a.Fallback>
            </Avatar>
          </m.Avatar>
          <m.Content>
            <Bubble as |b|><b.Content>It's a one-line change.</b.Content></Bubble>
            <m.Footer>Delivered</m.Footer>
          </m.Content>
        </Message>
      </template>,
    )
    const message = new MessageHarness('footer')
    assert.strictEqual(
      getComputedStyle(message.avatar).translate,
      '0px -32px',
      'group-has-data-[slot=message-footer]/message:-translate-y-8',
    )
    const footer = getComputedStyle(message.footer)
    assert.strictEqual(footer.fontSize, '12px', 'text-xs')
    assert.strictEqual(footer.display, 'flex')
    assert.strictEqual(footer.justifyContent, 'normal', 'at the start, on a start row')
    await a11yAudit()
  })

  test('@align="end" puts the avatar, the bubble and the footer at the end of the row', async function (assert) {
    class State {
      @tracked align: 'start' | 'end' = 'end'
    }
    const state = new State()
    await render(
      <template>
        <div style="width: 384px">
          <Message @align={{state.align}} @name="mine" as |m|>
            <m.Avatar>
              <Avatar as |a|>
                <a.Image @src={{IMAGE}} alt="@me" />
                <a.Fallback>ME</a.Fallback>
              </Avatar>
            </m.Avatar>
            <m.Content>
              <m.Header>Me</m.Header>
              <Bubble as |b|><b.Content>Deploying to prod real quick.</b.Content></Bubble>
              <m.Footer>Delivered</m.Footer>
            </m.Content>
          </Message>
        </div>
      </template>,
    )
    const message = new MessageHarness('mine')
    assert.strictEqual(message.align, 'end')
    assert.strictEqual(
      getComputedStyle(message.element).flexDirection,
      'row-reverse',
      'data-[align=end]:flex-row-reverse',
    )
    const row = message.element.getBoundingClientRect()
    const avatar = message.avatar.getBoundingClientRect()
    assert.strictEqual(Math.round(avatar.right), Math.round(row.right), 'the avatar at the end')
    const [bubble] = message.bubbles
    assert.strictEqual(getComputedStyle(bubble!.element).alignSelf, 'flex-end')
    assert.ok(
      Math.round(bubble!.element.getBoundingClientRect().right) <= Math.round(avatar.left),
      'the bubble beside it, at the end of the content',
    )
    assert.strictEqual(
      getComputedStyle(message.footer).justifyContent,
      'flex-end',
      'group-data-[align=end]/message:justify-end',
    )
    assert.strictEqual(getComputedStyle(message.footer).alignSelf, 'flex-end')
    assert.strictEqual(
      getComputedStyle(message.header).alignSelf,
      'flex-end',
      'every part of the content, the header too: *:data-slot:self-end',
    )

    state.align = 'start'
    await settled()
    assert.strictEqual(message.align, 'start', 'the attribute follows')
    assert.strictEqual(getComputedStyle(message.element).flexDirection, 'row')
    assert.strictEqual(
      Math.round(message.avatar.getBoundingClientRect().left),
      Math.round(row.left),
      'the avatar back at the start',
    )
    await a11yAudit()
  })

  test('beside a ghost bubble, the header and footer lose their inset, and footer actions sit in a row', async function (assert) {
    await render(
      <template>
        <Message @name="ghost" as |m|>
          <m.Content>
            <m.Header>Assistant</m.Header>
            <Bubble @variant="ghost" as |b|><b.Content>Assistant text</b.Content></Bubble>
            <m.Footer>Copied</m.Footer>
          </m.Content>
        </Message>
        <Message @name="actions" as |m|>
          <m.Content>
            <Bubble @variant="muted" as |b|><b.Content>Framed text</b.Content></Bubble>
            <m.Footer>
              <Button @variant="outline" @size="icon" aria-label="Copy">
                <Icon @icon={{Copy}} />
              </Button>
              <Button @variant="outline" @size="icon" aria-label="Retry">
                <Icon @icon={{Copy}} />
              </Button>
            </m.Footer>
          </m.Content>
        </Message>
      </template>,
    )
    const ghost = new MessageHarness('ghost')
    assert.strictEqual(
      getComputedStyle(ghost.footer).paddingInlineStart,
      '0px',
      'group-has-data-[variant=ghost]/message:px-0',
    )
    assert.strictEqual(getComputedStyle(ghost.header).paddingInlineStart, '0px')

    const actions = new MessageHarness('actions')
    assert.strictEqual(getComputedStyle(actions.footer).paddingInlineStart, '12px', 'px-3')
    assert.strictEqual(getComputedStyle(actions.footer).alignItems, 'center')
    const [copy, retry] = actions.findAll(ButtonHarness)
    assert.strictEqual(copy!.label, 'Copy')
    assert.strictEqual(
      Math.round(copy!.element.getBoundingClientRect().top),
      Math.round(retry!.element.getBoundingClientRect().top),
      'in one row',
    )
    await a11yAudit()
  })

  test('a group stacks messages closer, and an empty avatar slot keeps them in line', async function (assert) {
    await render(
      <template>
        <MessageGroup @name="thread">
          <Message as |m|>
            <m.Avatar />
            <m.Content>
              <Bubble @variant="muted" as |b|><b.Content>I checked the registry addresses.</b.Content></Bubble>
            </m.Content>
          </Message>
          <Message as |m|>
            <m.Avatar>
              <Avatar as |a|>
                <a.Image @src={{IMAGE}} alt="@avatar" />
                <a.Fallback>CN</a.Fallback>
              </Avatar>
            </m.Avatar>
            <m.Content>
              <Bubble @variant="muted" as |b|><b.Content>The JSON now lives under the UI registry.</b.Content></Bubble>
            </m.Content>
          </Message>
        </MessageGroup>
      </template>,
    )
    const group = new MessageGroupHarness('thread')
    assert
      .dom(group.element)
      .hasClass('jn-message-group')
      .hasAttribute('data-slot', 'message-group')
    const style = getComputedStyle(group.element)
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.flexDirection, 'column')
    assert.strictEqual(style.rowGap, '8px', 'gap-2')

    const [first, second] = group.messages
    assert.strictEqual(group.messages.length, 2)
    assert.true(first!.hasAvatar, 'an empty slot')
    assert.dom(first!.avatar).hasNoText()
    assert.strictEqual(px(getComputedStyle(first!.avatar).width), 32, 'as wide as an avatar')
    assert.strictEqual(
      Math.round(first!.content.getBoundingClientRect().left),
      Math.round(second!.content.getBoundingClientRect().left),
      'both bubbles start at the same place',
    )
    await a11yAudit()
  })

  test('every part takes @as, and its modifier makes your own element the part', async function (assert) {
    await render(
      <template>
        <ol>
          <Message @as="li" @name="item" as |m|>
            <m.Content @as="article">
              <h3 {{m.header}}>Olivia</h3>
              <Bubble @variant="muted" as |b|><b.Content>Hi</b.Content></Bubble>
              <p {{m.footer}}>Read</p>
            </m.Content>
          </Message>
        </ol>
        <MessageGroup @as="section" @name="section" aria-label="Thread" />
      </template>,
    )
    const message = new MessageHarness('item')
    assert.dom(message.element).hasTagName('li').hasClass('jn-message')
    assert.dom(message.content).hasTagName('article').hasClass('jn-message-content')
    assert
      .dom(message.header)
      .hasTagName('h3')
      .hasClass('jn-message-header')
      .hasAttribute('data-slot', 'message-header')
    assert.strictEqual(getComputedStyle(message.header).fontSize, '12px', 'styled as the part')
    assert.dom(message.footer).hasTagName('p').hasClass('jn-message-footer')
    assert.strictEqual(message.footerText, 'Read')
    assert.dom(new MessageGroupHarness('section').element).hasTagName('section')
    await a11yAudit()
  })

  test('RTL: a start row sits on the right, an end row on the left', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="width: 384px">
            <Message @name="theirs" as |m|>
              <m.Avatar>
                <Avatar as |a|>
                  <a.Image @src={{IMAGE}} alt="@rabbit" />
                  <a.Fallback>R</a.Fallback>
                </Avatar>
              </m.Avatar>
              <m.Content>
                <m.Header>أوليفيا</m.Header>
                <Bubble @variant="muted" as |b|><b.Content>لقد راجعت السجلات.</b.Content></Bubble>
              </m.Content>
            </Message>
            <Message @align="end" @name="mine" as |m|>
              <m.Avatar>
                <Avatar as |a|>
                  <a.Image @src={{IMAGE}} alt="@me" />
                  <a.Fallback>ME</a.Fallback>
                </Avatar>
              </m.Avatar>
              <m.Content>
                <Bubble as |b|><b.Content>أرسل التقرير.</b.Content></Bubble>
              </m.Content>
            </Message>
          </div>
        </DirectionProvider>
      </template>,
    )
    const theirs = new MessageHarness('theirs')
    const row = theirs.element.getBoundingClientRect()
    assert.strictEqual(
      Math.round(theirs.avatar.getBoundingClientRect().right),
      Math.round(row.right),
      'the avatar at the start, on the right',
    )
    assert.ok(
      theirs.bubbles[0]!.element.getBoundingClientRect().right <=
        theirs.avatar.getBoundingClientRect().left,
      'the bubble to its left',
    )
    assert.strictEqual(getComputedStyle(theirs.header).paddingRight, '12px', 'px-3 on the right')

    const mine = new MessageHarness('mine')
    assert.strictEqual(
      Math.round(mine.avatar.getBoundingClientRect().left),
      Math.round(mine.element.getBoundingClientRect().left),
      'the end is on the left',
    )
    await a11yAudit()
  })

  test('the harness throws for a missing part, and reads empty text without a header or footer', async function (assert) {
    await render(
      <template>
        <Message @name="bare" as |m|>
          <m.Content>
            <Bubble as |b|><b.Content>Hello</b.Content></Bubble>
          </m.Content>
        </Message>
      </template>,
    )
    const bare = new MessageHarness('bare')
    assert.false(bare.hasAvatar)
    assert.strictEqual(bare.headerText, '')
    assert.strictEqual(bare.footerText, '')
    assert.throws(() => bare.avatar, /no "avatar" part found in message "bare"/)
    assert.throws(() => bare.header, /no "header" part found/)
    assert.throws(() => bare.footer, /no "footer" part found/)
    assert.strictEqual(bare.find(BubbleHarness).text, 'Hello')
    assert.throws(
      () => new BubbleHarness('bare').element,
      /the component named "bare" is a "message"/,
      'a harness checks it is pointed at the right component',
    )
    await a11yAudit()
  })
})
