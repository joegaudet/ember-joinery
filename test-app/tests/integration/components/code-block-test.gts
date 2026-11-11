import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, rerender, settled, waitUntil } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Clipboard, Terminal } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Icon } from '@ember-joinery/ember'
import { ButtonHarness, IconHarness } from '@ember-joinery/test-support'
import {
  CodeBlock,
  configureHighlighter,
  highlightCode,
  highlightedCode,
  loadHighlighter,
  plainLines,
  registerLanguage,
  registeredLanguages,
  type CodeBlockLineVariant,
} from '@ember-joinery/code-block'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

const OUTPUT = `$ pnpm add ai @ai-sdk/react zod
Packages: +14
Done in 2.8s using pnpm v10.18.0`

const JSON_CODE = `{
  "name": "chat",
  "private": true
}`

const TWO_LINES = 'a\nb\n'

/** A small grammar of the test's own, as registerLanguage takes Shiki's. */
const TINY = {
  name: 'tiny',
  scopeName: 'source.tiny',
  patterns: [{ match: '\\bfn\\b', name: 'keyword.control.tiny' }],
  repository: {},
}

/** A theme of the test's own, as configureHighlighter takes Shiki's. */
const theme = (name: string, type: 'light' | 'dark', keyword: string) => ({
  name,
  type,
  fg: type === 'light' ? '#000000' : '#ffffff',
  bg: type === 'light' ? '#ffffff' : '#000000',
  tokenColors: [{ scope: ['storage', 'keyword'], settings: { foreground: keyword } }],
})

module('Integration | components | code-block', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  hooks.afterEach(function () {
    configureHighlighter()
  })

  test('it renders upstream markup: classes, slots and data attributes on every part', async function (assert) {
    await render(
      <template>
        <CodeBlock @name="terminal" as |b|>
          <b.Header>
            <b.Title>Terminal</b.Title>
            <b.Actions><b.CopyButton @value={{OUTPUT}} /></b.Actions>
          </b.Header>
          <b.Content @code={{OUTPUT}} />
          <b.Footer>Footer</b.Footer>
        </CodeBlock>
      </template>,
    )
    const block = new CodeBlockHarness('terminal')

    assert
      .dom(block.element)
      .hasTagName('div')
      .hasClass('jn-code-block')
      .hasClass('group/code-block')
      .hasClass('jn-code-block-variant-default')
      .hasAttribute('data-slot', 'code-block')
      .hasAttribute('data-variant', 'default')
      .hasAttribute('data-size', 'default')
      .hasAttribute('data-test-jn', 'code-block')
      .hasAttribute('data-test-jn-name', 'terminal')
    assert
      .dom(block.header)
      .hasClass('jn-code-block-header')
      .hasAttribute('data-slot', 'code-block-header')
    assert
      .dom(block.part('title'))
      .hasClass('jn-code-block-title')
      .hasAttribute('data-slot', 'code-block-title')
    assert
      .dom(block.actions)
      .hasClass('jn-code-block-actions')
      .hasAttribute('data-slot', 'code-block-actions')
    assert
      .dom(block.footer)
      .hasClass('jn-code-block-footer')
      .hasAttribute('data-slot', 'code-block-footer')
    assert
      .dom(block.content)
      .hasTagName('pre')
      .hasClass('jn-code-block-content')
      .hasAttribute('data-slot', 'code-block-content')
      .hasAttribute('dir', 'ltr', 'code always reads left to right')
      .hasAttribute('tabindex', '0', 'a keyboard can reach it to scroll it')
      .doesNotHaveAttribute('data-wrap')
      .doesNotHaveAttribute('data-numbered')
    assert
      .dom('code', block.content)
      .hasClass('jn-code-block-code')
      .hasAttribute('data-slot', 'code-block-code')
    assert.strictEqual(
      block.content.querySelector('code')!.childNodes.length,
      1,
      'a @code string is one text node, so it stays cheap while it streams',
    )
    assert
      .dom(block.copyButton)
      .hasTagName('button')
      .hasClass('jn-button')
      .hasClass('jn-button-variant-ghost')
      .hasClass('jn-button-size-icon-xs')
      .hasClass('jn-code-block-copy-button')
      .hasAttribute('data-slot', 'code-block-copy-button', "upstream's slot replaces the Button's")

    assert.strictEqual(block.variant, 'default')
    assert.strictEqual(block.size, 'default')
    assert.strictEqual(block.title, 'Terminal')
    assert.strictEqual(block.code, OUTPUT)
    assert.false(block.hasFloatingActions)
    assert.false(block.isHighlighted)
    await a11yAudit()
  })

  test('its style sheet lays it out and sizes it, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="width: 400px">
          <CodeBlock @name="plain" as |b|><b.Content @code="plain" /></CodeBlock>
          <CodeBlock @name="header" as |b|>
            <b.Header><b.Title><Icon @icon={{Terminal}} />Terminal</b.Title></b.Header>
            <b.Content @code="with a header" />
          </CodeBlock>
          <CodeBlock @name="sm" @size="sm" as |b|>
            <b.Header><b.Title>Small</b.Title></b.Header>
            <b.Content @code="small" />
          </CodeBlock>
        </div>
      </template>,
    )
    const style = (element: Element) => getComputedStyle(element)
    const plain = new CodeBlockHarness('plain')
    const header = new CodeBlockHarness('header')
    const sm = new CodeBlockHarness('sm')

    assert.strictEqual(style(plain.element).display, 'flex', 'flex flex-col')
    assert.strictEqual(style(plain.element).flexDirection, 'column')
    assert.strictEqual(style(plain.element).overflow, 'hidden')
    assert.strictEqual(
      style(plain.element).borderTopLeftRadius,
      '10px',
      "rounded-lg: the theme's --radius",
    )
    assert.strictEqual(style(plain.element).borderTopWidth, '1px', "Nova's border")
    assert.strictEqual(style(plain.element).fontSize, '14px', 'text-sm')
    assert.strictEqual(px(style(plain.content).paddingTop), 12, 'p-3')
    assert.strictEqual(px(style(plain.content).paddingLeft), 12)
    assert.strictEqual(style(plain.content).whiteSpace, 'pre', 'long lines scroll')
    assert.strictEqual(style(plain.content).overflowX, 'auto')
    assert.strictEqual(style(plain.content).textAlign, 'start')
    assert.ok(/mono/i.test(style(plain.content).fontFamily), 'font-mono')
    assert.strictEqual(
      style(plain.content.querySelector('code')!).fontFamily,
      style(plain.content).fontFamily,
      "the code element too, not the browser's own monospace",
    )
    assert.strictEqual(px(style(plain.content).lineHeight), 14 * 1.625, 'leading-relaxed')

    assert.strictEqual(px(style(header.content).paddingTop), 8, 'under a header, pt-2')
    assert.strictEqual(px(style(header.header!).paddingTop), 12, "the header's pt-3")
    assert.strictEqual(style(header.part('title')).fontWeight, '500')
    assert.strictEqual(
      style(header.part('title')).textOverflow,
      'ellipsis',
      'a long title truncates',
    )
    const icon = header.find(IconHarness).element
    assert.strictEqual(style(icon).width, '14px', "the title's icon is size-3.5")
    assert.strictEqual(px(style(icon).marginInlineEnd), 6, 'me-1.5')

    assert.strictEqual(style(sm.element).fontSize, '12px', 'sm: text-xs')
    assert.strictEqual(px(style(sm.content).paddingLeft), 10, 'sm: px-2.5')
    assert.strictEqual(px(style(sm.content).paddingTop), 6, 'sm under a header: pt-1.5')
    assert.strictEqual(style(sm.part('title')).fontSize, '12px')
    await a11yAudit()
  })

  test("the code takes the theme's --font-mono, as a shadcn app's does", async function (assert) {
    await render(
      <template>
        <div style="--font-mono: 'Courier New', monospace">
          <CodeBlock as |b|>
            <b.Header><b.Title>Title</b.Title></b.Header>
            <b.Content @code="code" />
          </CodeBlock>
        </div>
      </template>,
    )
    const block = new CodeBlockHarness()
    assert.strictEqual(getComputedStyle(block.content).fontFamily, '"Courier New", monospace')
    assert.strictEqual(
      getComputedStyle(block.content.querySelector('code')!).fontFamily,
      '"Courier New", monospace',
    )
    await a11yAudit()
  })

  test('@variant="destructive" tones the block, its header and its title', async function (assert) {
    await render(
      <template>
        <CodeBlock @name="default" as |b|><b.Content @code="ok" /></CodeBlock>
        <CodeBlock @name="error" @variant="destructive" as |b|>
          <b.Header><b.Title>Error</b.Title></b.Header>
          <b.Content @code="TypeError" @wrap={{true}} />
        </CodeBlock>
      </template>,
    )
    const ok = new CodeBlockHarness('default')
    const error = new CodeBlockHarness('error')
    assert.strictEqual(error.variant, 'destructive')
    assert.dom(error.element).hasClass('jn-code-block-variant-destructive')
    const { color } = getComputedStyle(error.element)
    assert.notStrictEqual(color, getComputedStyle(ok.element).color, 'the text is destructive')
    assert.strictEqual(getComputedStyle(error.part('title')).color, color, 'and so is the title')
    assert.notStrictEqual(
      getComputedStyle(error.element).borderTopColor,
      getComputedStyle(ok.element).borderTopColor,
    )
    await a11yAudit()
  })

  test('@lineNumbers splits a @code string into numbered lines, from @startLine', async function (assert) {
    await render(
      <template>
        <CodeBlock @name="one" as |b|><b.Content
            @code={{JSON_CODE}}
            @lineNumbers={{true}}
          /></CodeBlock>
        <CodeBlock @name="later" as |b|>
          <b.Content @code={{TWO_LINES}} @lineNumbers={{true}} @startLine={{995}} />
        </CodeBlock>
      </template>,
    )
    const one = new CodeBlockHarness('one')
    assert.true(one.isNumbered)
    assert.dom(one.content).hasAttribute('data-numbered', 'true')
    assert.deepEqual(
      one.lines.map(line => line.text),
      JSON_CODE.split('\n'),
    )
    assert.deepEqual(
      one.lines.map(line => line.number),
      [1, 2, 3, 4],
    )
    assert.strictEqual(getComputedStyle(one.content).counterReset, 'line 0')

    const line = one.parts('line')[0]!
    assert
      .dom(line)
      .hasTagName('span')
      .hasClass('jn-code-block-line')
      .hasClass('jn-code-block-line-variant-default')
      .hasAttribute('data-slot', 'code-block-line')
      .hasAttribute('data-variant', 'default')
    assert.dom('[data-slot="code-block-line-content"]', line).hasClass('jn-code-block-line-content')
    const before = getComputedStyle(line, '::before')
    assert.ok(
      before.content.startsWith('counter(line'),
      'the number is a CSS counter, which a selection leaves out',
    )
    assert.ok(/""|''/.test(before.content), 'with empty alt text, so screen readers skip it')
    assert.strictEqual(getComputedStyle(line).display, 'grid', 'a numbered line is a subgrid row')

    const later = new CodeBlockHarness('later')
    assert.strictEqual(later.startLine, 995)
    assert.strictEqual(getComputedStyle(later.content).counterReset, 'line 994')
    assert.deepEqual(
      later.lines.map(l => [l.number, l.text]),
      [
        [995, 'a'],
        [996, 'b'],
      ],
      'a trailing newline adds no line',
    )
    await a11yAudit()
  })

  test('@wrap wraps long lines instead of scrolling', async function (assert) {
    const long = 'Error: '.padEnd(400, 'x ')
    await render(
      <template>
        <div style="width: 300px">
          <CodeBlock @name="scrolls" as |b|><b.Content @code={{long}} /></CodeBlock>
          <CodeBlock @name="wraps" as |b|><b.Content @code={{long}} @wrap={{true}} /></CodeBlock>
        </div>
      </template>,
    )
    const scrolls = new CodeBlockHarness('scrolls')
    const wraps = new CodeBlockHarness('wraps')
    assert.false(scrolls.isWrapped)
    assert.true(wraps.isWrapped)
    assert.dom(wraps.content).hasAttribute('data-wrap', 'true')
    assert.ok(scrolls.content.scrollWidth > scrolls.content.clientWidth, 'it scrolls')
    assert.strictEqual(getComputedStyle(wraps.content).whiteSpace, 'pre-wrap')
    assert.strictEqual(wraps.content.scrollWidth, wraps.content.clientWidth, 'it wraps')
    await a11yAudit()
  })

  test('lines take a variant: highlighted, and a diff marked with + and −', async function (assert) {
    const lines: { code: string; variant: CodeBlockLineVariant }[] = [
      { code: 'same', variant: 'default' },
      { code: 'gone', variant: 'removed' },
      { code: 'new', variant: 'added' },
      { code: '', variant: 'default' },
      { code: 'look', variant: 'highlighted' },
    ]
    await render(
      <template>
        <CodeBlock as |b|>
          <b.Content>
            {{#each lines as |line|}}<b.Line
                @code={{line.code}}
                @variant={{line.variant}}
              />{{/each}}
          </b.Content>
        </CodeBlock>
      </template>,
    )
    const block = new CodeBlockHarness()
    assert.deepEqual(block.removedLines, [1])
    assert.deepEqual(block.addedLines, [2])
    assert.deepEqual(block.highlightedLines, [4])
    assert.deepEqual(
      block.lines.map(line => line.variant),
      lines.map(line => line.variant),
    )
    assert.strictEqual(block.code, 'same\ngone\nnew\n\nlook')

    const [same, gone, added, empty, look] = block.parts('line')
    assert
      .dom(gone)
      .hasClass('jn-code-block-line-variant-removed')
      .hasAttribute('data-variant', 'removed')
    assert.strictEqual(getComputedStyle(added!, '::after').content, '"+"')
    assert.strictEqual(getComputedStyle(gone!, '::after').content, '"−"')
    assert.strictEqual(getComputedStyle(same!, '::after').content, '""', 'no marker')
    assert.notStrictEqual(
      getComputedStyle(look!).backgroundColor,
      getComputedStyle(same!).backgroundColor,
      'a highlighted line is tinted',
    )
    assert.notStrictEqual(
      getComputedStyle(gone!).backgroundColor,
      getComputedStyle(same!).backgroundColor,
    )
    assert.strictEqual(
      empty!.querySelector('[data-slot="code-block-line-content"]')!.textContent,
      '\n',
      'an empty line holds a newline, so a copied selection keeps it',
    )
    assert.strictEqual(px(getComputedStyle(empty!).height), px(getComputedStyle(same!).height))
    await a11yAudit()
  })

  test('the copy button copies its value, says so for two seconds, and announces it', async function (assert) {
    let clicks = 0
    const count = () => clicks++
    await render(
      <template>
        <CodeBlock as |b|>
          <b.Header>
            <b.Title>Terminal</b.Title>
            <b.Actions><b.CopyButton
                @value="pnpm add ai"
                @name="copy"
                {{on "click" count}}
              /></b.Actions>
          </b.Header>
          <b.Content @code="$ pnpm add ai" />
        </CodeBlock>
      </template>,
    )
    const block = new CodeBlockHarness()
    assert.strictEqual(block.copyLabel, 'Copy')
    assert.false(block.isCopied)
    assert.strictEqual(block.status, '')
    assert.true(block.canCopy)
    assert.strictEqual(new ButtonHarness('copy').label, 'Copy', 'it is a Button, named by @name')
    assert.true(new ButtonHarness('copy').find(IconHarness).isDecorative)

    await block.copy()
    assert.strictEqual(clipboard.text, 'pnpm add ai', 'it copied @value, not the shown text')
    assert.strictEqual(clicks, 1, 'a listener of your own runs too')
    assert.true(block.isCopied)
    assert.strictEqual(block.copyLabel, 'Copied')
    assert.strictEqual(block.status, 'Copied', 'the live region announces it')
    assert.dom(block.part('copy-status')).hasAttribute('aria-live', 'polite')
    assert.dom(block.copyButton).hasAttribute('data-copied', 'true')
    await a11yAudit()

    await waitUntil(() => !block.isCopied, { timeout: 3000 })
    assert.strictEqual(block.copyLabel, 'Copy', 'two seconds later, it can copy again')
    assert.strictEqual(block.status, '')
  })

  test('a refused copy leaves the button as it was; a disabled one does nothing', async function (assert) {
    await render(
      <template>
        <CodeBlock @name="refused" as |b|>
          <b.Actions><b.CopyButton @value="one" /></b.Actions>
          <b.Content @code="one" />
        </CodeBlock>
        <CodeBlock @name="off" as |b|>
          <b.Actions><b.CopyButton @value="two" disabled={{true}} /></b.Actions>
          <b.Content @code="two" />
        </CodeBlock>
      </template>,
    )
    clipboard.refuse()
    const refused = new CodeBlockHarness('refused')
    await refused.copy()
    assert.false(refused.isCopied)
    assert.strictEqual(refused.copyLabel, 'Copy')
    clipboard.allow()

    const off = new CodeBlockHarness('off')
    assert.false(off.canCopy)
    await off.copy().catch(() => undefined)
    assert.deepEqual(clipboard.writes, [], 'nothing was copied')
    await a11yAudit()
  })

  test('the copy button takes its labels, icons and look as arguments', async function (assert) {
    await render(
      <template>
        <CodeBlock as |b|>
          <b.Actions>
            <b.CopyButton
              @value="x"
              @copyLabel="Copier"
              @copiedLabel="Copié"
              @copyIcon={{Clipboard}}
              @variant="outline"
              @size="icon-sm"
            />
          </b.Actions>
          <b.Content @code="x" />
        </CodeBlock>
      </template>,
    )
    const block = new CodeBlockHarness()
    assert.strictEqual(block.copyLabel, 'Copier')
    assert
      .dom(block.copyButton)
      .hasClass('jn-button-variant-outline')
      .hasClass('jn-button-size-icon-sm')
    const before = block.copyButton!.querySelector('svg')!.innerHTML
    await block.copy()
    assert.strictEqual(block.copyLabel, 'Copié')
    assert.strictEqual(block.status, 'Copié')
    assert.notStrictEqual(
      block.copyButton!.querySelector('svg')!.innerHTML,
      before,
      'the icon changes',
    )
    await a11yAudit()
  })

  test('floating actions: hidden until the block has focus, and reachable by keyboard', async function (assert) {
    await render(
      <template>
        <CodeBlock as |b|>
          <b.Actions><b.CopyButton @value={{OUTPUT}} /></b.Actions>
          <b.Content @code={{OUTPUT}} />
        </CodeBlock>
      </template>,
    )
    const block = new CodeBlockHarness()
    const actions = block.actions!
    assert.true(block.hasFloatingActions)
    assert.strictEqual(getComputedStyle(actions).position, 'absolute', 'they float at the top end')
    assert.strictEqual(px(getComputedStyle(actions).top), 8, 'top-2')
    const touch = matchMedia('(pointer: coarse)').matches
    if (!touch) {
      assert.strictEqual(getComputedStyle(actions).opacity, '0', 'hidden until hovered or focused')
    }

    await block.focusContent()
    assert.dom(block.content).isFocused('the content takes focus, so a keyboard scrolls it')
    await waitUntil(() => getComputedStyle(actions).opacity === '1', { timeout: 1000 })
    assert.strictEqual(getComputedStyle(actions).opacity, '1', 'focus inside shows them')

    block.copyButton!.focus()
    assert.dom(block.copyButton).isFocused('the button is in the tab order')
    await a11yAudit()
  })

  test('keyboard: the content is a tab stop, unless you take it out', async function (assert) {
    await render(
      <template>
        <CodeBlock @name="stop" as |b|><b.Content @code="a" /></CodeBlock>
        <CodeBlock @name="skip" as |b|><b.Content @code="b" tabindex="-1" /></CodeBlock>
      </template>,
    )
    const stop = new CodeBlockHarness('stop')
    const skip = new CodeBlockHarness('skip')
    assert.strictEqual(stop.content.tabIndex, 0)
    assert.strictEqual(skip.content.tabIndex, -1, 'tabindex="-1" removes the tab stop')
    await stop.focusContent()
    if (stop.content.matches(':focus-visible')) {
      assert.notStrictEqual(
        getComputedStyle(stop.element).boxShadow,
        'none',
        'the block shows a focus ring while its content has keyboard focus',
      )
    } else {
      assert.ok(true, 'this browser gave programmatic focus no focus ring')
    }
    assert.strictEqual(
      getComputedStyle(stop.content).outlineStyle,
      'none',
      'the ring is on the block',
    )
    await a11yAudit()
  })

  test('RTL: the header follows the page, and the code still reads left to right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="width: 400px">
            <CodeBlock as |b|>
              <b.Header>
                <b.Title>الطرفية</b.Title>
                <b.Actions><b.CopyButton @value="pnpm dev" /></b.Actions>
              </b.Header>
              <b.Content @code="pnpm dev" @lineNumbers={{true}} />
            </CodeBlock>
          </div>
        </DirectionProvider>
      </template>,
    )
    const block = new CodeBlockHarness()
    const box = block.element.getBoundingClientRect()
    const title = block.part('title').getBoundingClientRect()
    const actions = block.actions!.getBoundingClientRect()
    assert.ok(
      title.right > actions.right,
      'the title starts on the right, the actions end on the left',
    )
    assert.ok(actions.left - box.left < 20, 'the actions sit at the left, the inline end')
    assert.strictEqual(getComputedStyle(block.content).direction, 'ltr')
    // The code's own text, measured: it starts on the left, after the line number.
    const range = document.createRange()
    range.selectNodeContents(block.content.querySelector('[data-slot="code-block-line-content"]')!)
    const text = range.getBoundingClientRect()
    const content = block.content.getBoundingClientRect()
    assert.ok(text.left - content.left < content.right - text.right, 'the code starts on the left')
    await a11yAudit()
  })

  test('@as and the part modifiers render the parts on other tags and your own elements', async function (assert) {
    await render(
      <template>
        <CodeBlock @as="figure" as |b|>
          <b.Header @as="section">
            <a href="/files/route.ts" {{b.title}}>app/api/chat/route.ts</a>
          </b.Header>
          <b.Content @code="x" />
          <footer {{b.footer}}>end</footer>
        </CodeBlock>
      </template>,
    )
    const block = new CodeBlockHarness()
    assert.dom(block.element).hasTagName('figure')
    assert.dom(block.header).hasTagName('section').hasClass('jn-code-block-header')
    assert
      .dom(block.part('title'))
      .hasTagName('a')
      .hasAttribute('href', '/files/route.ts')
      .hasClass('jn-code-block-title')
      .hasAttribute('data-slot', 'code-block-title')
    assert.strictEqual(block.title, 'app/api/chat/route.ts')
    assert.dom(block.footer).hasTagName('footer').hasClass('jn-code-block-footer')
    await a11yAudit()
  })

  test('highlightedCode highlights with Shiki, light and dark', async function (assert) {
    const code = 'const answer = 42 // the answer'
    await render(
      <template>
        <CodeBlock @name="light" as |b|>
          <b.Content>{{#each (highlightedCode code "ts") as |line|}}<b.Line
                @code={{line}}
              />{{/each}}</b.Content>
        </CodeBlock>
        <div class="dark" style="background: var(--background); color: var(--foreground)">
          <CodeBlock @name="dark" as |b|>
            <b.Content>{{#each (highlightedCode code "typescript") as |line|}}<b.Line
                  @code={{line}}
                />{{/each}}</b.Content>
          </CodeBlock>
        </div>
      </template>,
    )
    const light = new CodeBlockHarness('light')
    const dark = new CodeBlockHarness('dark')
    assert.true(light.isHighlighted, 'render waits for Shiki and the language')
    assert.strictEqual(light.code, code, 'the text is unchanged')
    const tokens = light.tokens(0)
    assert.deepEqual(tokens.map(token => token.text).join(''), code)
    const keyword = tokens.find(token => token.text === 'const')!
    assert.strictEqual(keyword.color, 'rgb(160, 17, 31)', "GitHub light high contrast's keyword")
    const darkKeyword = dark.tokens(0).find(token => token.text === 'const')!
    assert.strictEqual(darkKeyword.color, 'rgb(255, 148, 146)', 'and its dark theme under .dark')
    assert.dom('.jn-code-block-token', light.content).hasAttribute('style', /--shiki-light:#A0111F/)
    await a11yAudit()
  })

  test('a language that is not listed shows plain text; ansi renders terminal colours', async function (assert) {
    const ansi = '\x1b[32m✓\x1b[39m passed\n\x1b[31m✗\x1b[39m failed'
    await render(
      <template>
        <CodeBlock @name="text" as |b|>
          <b.Content>{{#each (highlightedCode "plain words" "text") as |line|}}<b.Line
                @code={{line}}
              />{{/each}}</b.Content>
        </CodeBlock>
        <CodeBlock @name="ansi" as |b|>
          <b.Content>{{#each (highlightedCode ansi "ansi") as |line|}}<b.Line
                @code={{line}}
              />{{/each}}</b.Content>
        </CodeBlock>
      </template>,
    )
    const text = new CodeBlockHarness('text')
    assert.false(text.isHighlighted)
    assert.strictEqual(text.code, 'plain words')

    const terminal = new CodeBlockHarness('ansi')
    assert.true(terminal.isHighlighted)
    assert.strictEqual(terminal.code, '✓ passed\n✗ failed', 'the escape codes are gone')
    const [tick] = terminal.tokens(0)
    const [cross] = terminal.tokens(1)
    assert.strictEqual(tick!.text, '✓')
    assert.notStrictEqual(tick!.color, cross!.color, 'green and red')
    await a11yAudit()
  })

  test('while code streams in, finished lines keep their elements', async function (assert) {
    class Stream {
      @tracked code = 'const a = 1\nconst b'
    }
    const stream = new Stream()
    await render(
      <template>
        <CodeBlock as |b|>
          <b.Content @lineNumbers={{true}}>
            {{#each (highlightedCode stream.code "ts") as |line|}}<b.Line @code={{line}} />{{/each}}
          </b.Content>
        </CodeBlock>
      </template>,
    )
    const block = new CodeBlockHarness()
    assert.strictEqual(block.code, 'const a = 1\nconst b')
    const first = block.parts('line')[0]

    stream.code = 'const a = 1\nconst b = 2\nconst c = "'
    await settled()
    assert.strictEqual(block.code, 'const a = 1\nconst b = 2\nconst c = "')
    assert.strictEqual(block.parts('line')[0], first, 'the first line was not rendered again')
    assert.true(block.isHighlighted)
    assert.deepEqual(
      block.lines.map(line => line.number),
      [1, 2, 3],
    )

    stream.code = 'let x'
    await settled()
    assert.strictEqual(block.code, 'let x', 'new code that does not continue the old starts over')
    await rerender()
    await a11yAudit()
  })

  test('highlightCode, plainLines, registerLanguage and configureHighlighter', async function (assert) {
    const lines = await highlightCode('{"a": 1}\n', 'json')
    assert.strictEqual(lines?.length, 1, 'a trailing newline is ignored')
    assert.ok(lines![0]!.every(token => token.style?.includes('--shiki-light')))
    assert.strictEqual(await highlightCode('x', 'cobol'), null, 'not in the list')
    assert.strictEqual(await loadHighlighter('klingon'), null)
    assert.deepEqual(plainLines('a\n\nb'), [[{ content: 'a' }], [], [{ content: 'b' }]])

    assert.ok(registeredLanguages().includes('ts'))
    assert.notOk(registeredLanguages().includes('rs'))
    registerLanguage('tiny', () => Promise.resolve({ default: [TINY] }), { aliases: ['tn'] })
    assert.ok(registeredLanguages().includes('tn'))
    const tiny = await highlightCode('fn main', 'TN')
    assert.ok(
      tiny?.[0]?.some(token => token.content === 'fn' && token.style),
      'a language of your own, by its alias, in any case',
    )

    configureHighlighter({
      themes: {
        light: theme('mine-light', 'light', '#123456'),
        dark: () => Promise.resolve({ default: theme('mine-dark', 'dark', '#abcdef') }),
      },
    })
    const mine = await highlightCode('const a = 1', 'ts')
    const style = mine![0]!.find(token => token.content === 'const')!.style!
    assert.ok(style.includes('--shiki-light:#123456'), 'your themes, when you give them')
    assert.ok(style.toLowerCase().includes('--shiki-dark:#abcdef'), 'as themes or loaders for them')
    configureHighlighter()
    const again = await highlightCode('const a = 1', 'ts')
    assert.ok(again![0]!.find(token => token.content === 'const')!.style!.includes('#A0111F'))

    await render(
      <template>
        <CodeBlock as |b|>
          <b.Content>{{#each lines as |line|}}<b.Line @code={{line}} />{{/each}}</b.Content>
        </CodeBlock>
      </template>,
    )
    assert.true(new CodeBlockHarness().isHighlighted, 'lines highlighted ahead of time render too')
    await a11yAudit()
  })

  test('the harness reads lines from a block of text, and fails clearly', async function (assert) {
    await render(
      <template>
        <CodeBlock @name="text" as |b|><b.Content @code={{TWO_LINES}} /></CodeBlock>
        <CodeBlock @name="bare" as |b|><b.Content><b.Line>yielded</b.Line></b.Content></CodeBlock>
      </template>,
    )
    const text = new CodeBlockHarness('text')
    assert.deepEqual(text.lines, [
      { text: 'a', variant: 'default', number: null },
      { text: 'b', variant: 'default', number: null },
      { text: '', variant: 'default', number: null },
    ])
    assert.strictEqual(text.title, null, 'no title')
    assert.strictEqual(text.header, null)
    assert.strictEqual(text.copyButton, null)
    assert.throws(() => text.copyLabel, /no "copy-button" part found in code-block "text"/)
    assert.strictEqual(new CodeBlockHarness('bare').code, 'yielded', 'a line with a block')
    assert.throws(() => new CodeBlockHarness('missing').element, /no code-block "missing" found/)
    await a11yAudit()
  })
})
