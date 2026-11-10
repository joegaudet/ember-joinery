import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ArrowUpRight, ChevronRight, ChevronsDown, FileText, Search, Terminal } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import {
  Icon,
  Trace,
  TraceCollapsible,
  TraceDescription,
  TraceIcon,
  TraceLine,
  TraceTitle,
  type TraceLineStatus,
} from '@ember-joinery/ember'
import {
  TraceCollapsibleHarness,
  TraceHarness,
  TraceLineHarness,
  tab,
} from '@ember-joinery/test-support'

const STATUSES: TraceLineStatus[] = ['error', 'running', 'pending']

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

module('Integration | components | trace', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Trace @name="steps">
          <TraceLine @name="search" as |l|>
            <l.Icon><Icon @icon={{Search}} /></l.Icon>
            <l.Title>Searched for useChat</l.Title>
            <l.Description>8 results</l.Description>
          </TraceLine>
        </Trace>
      </template>,
    )
    const trace = new TraceHarness('steps')
    assert
      .dom(trace.element)
      .hasTagName('div')
      .hasClass('jn-trace')
      .hasAttribute('data-slot', 'trace')
      .doesNotHaveAttribute(
        'role',
        'it adds no role: each line takes its semantics from its wrapper',
      )
    const line = new TraceLineHarness('search')
    assert
      .dom(line.element)
      .hasTagName('span', 'a span: not a button, not a tab stop')
      .hasClass('jn-trace-line')
      .hasAttribute('data-slot', 'trace-line')
      .doesNotHaveAttribute('data-status', 'none for work that is done')
      .doesNotHaveAttribute('tabindex')
    const [icon] = line.icons
    assert
      .dom(icon)
      .hasTagName('span')
      .hasClass('jn-trace-icon')
      .hasAttribute('data-slot', 'trace-icon')
      .hasAttribute('aria-hidden', 'true', 'decoration: the title is the name')
    assert
      .dom(line.titleElement)
      .hasTagName('span')
      .hasClass('jn-trace-title')
      .hasAttribute('data-slot', 'trace-title')
    assert
      .dom(line.part('description'))
      .hasTagName('span')
      .hasClass('jn-trace-description')
      .hasAttribute('data-slot', 'trace-description')
    assert.strictEqual(line.title, 'Searched for useChat')
    assert.strictEqual(line.description, '8 results')
    assert.true(line.hasDescription)
    assert.strictEqual(line.text, 'Searched for useChat 8 results')
    assert.strictEqual(line.status, null)
    assert.strictEqual(line.control, null, 'a line on its own reads as text')
    assert.deepEqual(trace.titles, ['Searched for useChat'])
    await a11yAudit()
  })

  test('the style sheet styles it: a muted row, its icon at 16px, a title that truncates', async function (assert) {
    await render(
      <template>
        <p data-test-text>Body text</p>
        <div style="width: 240px">
          <Trace>
            <TraceLine @name="edit" as |l|>
              <l.Icon><Icon @icon={{FileText}} /></l.Icon>
              <l.Title>Edited components/settings/notification-preferences-form.tsx</l.Title>
              <l.Description>+48 −12</l.Description>
            </TraceLine>
          </Trace>
        </div>
      </template>,
    )
    const trace = new TraceHarness()
    const list = getComputedStyle(trace.element)
    assert.strictEqual(list.display, 'flex')
    assert.strictEqual(list.flexDirection, 'column')
    assert.strictEqual(list.rowGap, '8px', 'gap-2')

    const line = new TraceLineHarness('edit')
    const style = getComputedStyle(line.element)
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.alignItems, 'center')
    assert.strictEqual(style.columnGap, '8px', 'gap-2')
    assert.strictEqual(style.fontSize, '14px', 'text-sm')
    assert.notStrictEqual(
      style.color,
      getComputedStyle(document.querySelector('[data-test-text]')!).color,
      'text-muted-foreground',
    )
    const icon = getComputedStyle(line.icons[0]!)
    assert.strictEqual(px(icon.width), 16, 'size-4')
    assert.strictEqual(icon.flexShrink, '0')
    assert.strictEqual(getComputedStyle(line.icons[0]!.querySelector('svg')!).width, '16px')

    const title = getComputedStyle(line.titleElement)
    assert.strictEqual(title.overflow, 'hidden', 'truncate')
    assert.strictEqual(title.textOverflow, 'ellipsis')
    assert.strictEqual(title.whiteSpace, 'nowrap')
    assert.ok(
      line.titleElement.scrollWidth > line.titleElement.clientWidth,
      'a long title is cut off',
    )
    const description = getComputedStyle(line.part('description'))
    assert.strictEqual(description.flexShrink, '0', "the description doesn't truncate")
    assert.strictEqual(description.fontVariantNumeric, 'tabular-nums')
    assert.ok(
      line.element.getBoundingClientRect().width <= 240,
      'the line fits its container (max-w-full)',
    )
    await a11yAudit()
  })

  test('each status colours or dims the line, and a running title shimmers', async function (assert) {
    await render(
      <template>
        <Trace>
          <TraceLine @name="done" as |l|><l.Title>Ran pnpm install</l.Title></TraceLine>
          {{#each STATUSES as |status|}}
            <TraceLine @status={{status}} @name={{status}} as |l|>
              <l.Title>A {{status}} step</l.Title>
            </TraceLine>
          {{/each}}
        </Trace>
      </template>,
    )
    const done = new TraceLineHarness('done')
    const error = new TraceLineHarness('error')
    const running = new TraceLineHarness('running')
    const pending = new TraceLineHarness('pending')
    assert.true(error.isError)
    assert.true(running.isRunning)
    assert.true(pending.isPending)
    assert.dom(error.element).hasAttribute('data-status', 'error')

    assert.notStrictEqual(
      getComputedStyle(error.element).color,
      getComputedStyle(done.element).color,
      'error: text-destructive',
    )
    assert.strictEqual(getComputedStyle(pending.element).opacity, '0.6', 'pending: opacity-60')
    assert.strictEqual(getComputedStyle(done.element).opacity, '1')

    const shimmer = getComputedStyle(running.titleElement)
    assert.notStrictEqual(shimmer.backgroundImage, 'none', 'running: the title shimmers')
    assert.strictEqual(shimmer.backgroundClip, 'text')
    assert.strictEqual(getComputedStyle(done.titleElement).backgroundImage, 'none')
    await a11yAudit()
  })

  test('the parts render alone, and as modifiers on your own elements', async function (assert) {
    await render(
      <template>
        <TraceLine @name="own" as |l|>
          <TraceIcon><Icon @icon={{Search}} /></TraceIcon>
          <TraceTitle>Searched for minimumReleaseAge</TraceTitle>
          <TraceDescription>2 results</TraceDescription>
          <em {{l.title}}>emphasised</em>
        </TraceLine>
      </template>,
    )
    const line = new TraceLineHarness('own')
    assert.strictEqual(line.parts('title').length, 2)
    assert.dom(line.parts('title')[1]).hasTagName('em').hasClass('jn-trace-title')
    assert.dom(line.parts('title')[1]).hasAttribute('data-slot', 'trace-title')
    assert.strictEqual(line.description, '2 results')
    assert.dom(line.icons[0]).hasAttribute('aria-hidden', 'true')
    await a11yAudit()
  })

  test('a link or a trigger around a line is styled by the trace, and is the tab stop', async function (assert) {
    await render(
      <template>
        <Trace>
          <a href="#docs">
            <TraceLine @name="docs" as |l|>
              <l.Icon><Icon @icon={{FileText}} /></l.Icon>
              <l.Title>Read apps/v4/lib/docs.ts</l.Title>
              <l.Icon><Icon @icon={{ChevronRight}} /></l.Icon>
            </TraceLine>
          </a>
          <a href="https://docs.astro.build" target="_blank" rel="noreferrer">
            <TraceLine @name="astro" as |l|>
              <l.Title>
                Install Astro
                <VisuallyHidden>(opens in a new tab)</VisuallyHidden>
              </l.Title>
              <l.Icon><Icon @icon={{ArrowUpRight}} /></l.Icon>
            </TraceLine>
          </a>
        </Trace>
      </template>,
    )
    const docs = new TraceLineHarness('docs')
    const astro = new TraceLineHarness('astro')
    assert.true(docs.isLink)
    assert.strictEqual(docs.href, '#docs')
    assert.false(docs.opensInNewTab)
    assert.true(astro.opensInNewTab)
    assert.strictEqual(astro.title, 'Install Astro (opens in a new tab)')

    const link = getComputedStyle(docs.control!)
    assert.strictEqual(link.display, 'flex', 'the trace lays out what wraps a line')
    assert.strictEqual(link.borderRadius, '8px', 'rounded-md, for the focus ring')
    assert.strictEqual(link.textDecorationLine, 'none', 'no underline, as under preflight')
    assert.ok(docs.control!.getBoundingClientRect().width < 300, 'w-fit: as wide as its line')
    assert.strictEqual(getComputedStyle(docs.element).cursor, 'pointer', 'in a link: a pointer')

    const indicator = docs.icons[1]!
    assert.strictEqual(
      px(getComputedStyle(indicator).marginInlineStart),
      -4,
      'an icon after the title sits closer: -ms-1',
    )

    await tab()
    assert.dom(docs.control).isFocused('Tab reaches the link, not the line')
    assert.notStrictEqual(
      getComputedStyle(docs.control!).boxShadow,
      'none',
      'with a focus ring (focus-visible:ring-3)',
    )
    await a11yAudit()
  })

  test('a collapsible row: closed by default, opened and closed by its trigger', async function (assert) {
    await render(
      <template>
        <TraceCollapsible @name="node" as |c|>
          <c.Trigger>
            <TraceLine as |l|>
              <l.Icon><Icon @icon={{Terminal}} /></l.Icon>
              <l.Title>Ran node --version</l.Title>
            </TraceLine>
          </c.Trigger>
          <c.Content>v24.18.0</c.Content>
        </TraceCollapsible>
      </template>,
    )
    const row = new TraceCollapsibleHarness('node')
    assert
      .dom(row.element)
      .hasClass('jn-trace-collapsible')
      .hasAttribute('data-slot', 'trace-collapsible')
      .hasAttribute('data-state', 'closed')
    assert
      .dom(row.trigger)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasClass('jn-trace-collapsible-trigger')
      .hasClass('group/trace-collapsible-trigger')
      .hasAttribute('data-slot', 'trace-collapsible-trigger')
      .hasAttribute('aria-expanded', 'false')
    assert
      .dom(row.indicator)
      .hasClass('jn-trace-icon')
      .hasAttribute('data-slot', 'trace-icon')
      .hasAttribute('aria-hidden', 'true')
    assert.dom(row.content).hasClass('jn-trace-collapsible-content').hasAttribute('hidden')
    assert.dom(row.content).hasAttribute('data-slot', 'trace-collapsible-content')
    assert.true(row.controlsContent)
    assert.strictEqual(row.label, 'Ran node --version', 'named by its line')
    assert.strictEqual(row.line.title, 'Ran node --version')
    assert.strictEqual(row.text, '')
    assert.false(row.isOpen)

    await row.open()
    assert.true(row.isOpen)
    assert.strictEqual(row.text, 'v24.18.0')
    assert.dom(row.element).hasAttribute('data-state', 'open')
    const inner = row.content.querySelector('[data-slot="trace-collapsible-content-inner"]')!
    assert.dom(inner).hasClass('jn-trace-collapsible-content-inner')
    assert.true(row.line.control === row.trigger, "the line's control is the trigger")

    await row.close()
    assert.false(row.isOpen)
    await settled()
    assert.false(row.isShown, 'hidden again once its exit is done')
    await a11yAudit()
  })

  test('the row follows the disclosure pattern from the keyboard', async function (assert) {
    // The trigger is a native <button>: Tab reaches it, and Enter and Space press it, as the
    // browser does for any button (a test presses it with a click, which is what they send).
    await render(
      <template>
        <TraceCollapsible @name="node" as |c|>
          <c.Trigger>
            <TraceLine as |l|><l.Title>Ran node --version</l.Title></TraceLine>
          </c.Trigger>
          <c.Content>v24.18.0</c.Content>
        </TraceCollapsible>
      </template>,
    )
    const row = new TraceCollapsibleHarness('node')
    await tab()
    assert.dom(row.trigger).isFocused('Tab reaches the trigger')
    assert.strictEqual(row.trigger.localName, 'button', 'a native button')
    await row.toggle()
    assert.true(row.isOpen, 'pressing it opens the row')
    assert.dom(row.trigger).isFocused('focus stays on the trigger')
    await row.toggle()
    assert.false(row.isOpen, 'and pressing it again closes it')
    await tab()
    assert.dom(row.trigger).isNotFocused('the closed content holds no tab stop')
    await a11yAudit()
  })

  test('the style sheet styles the row: a muted trigger, a turning chevron, indented content', async function (assert) {
    await render(
      <template>
        <p data-test-text>Body text</p>
        <TraceCollapsible @name="node" @defaultOpen={{true}} as |c|>
          <c.Trigger>
            <TraceLine as |l|><l.Title>Ran node --version</l.Title></TraceLine>
          </c.Trigger>
          <c.Content>v24.18.0</c.Content>
        </TraceCollapsible>
      </template>,
    )
    const row = new TraceCollapsibleHarness('node')
    // The chevron turns with a transition; read where it ends up.
    row.indicator.style.transitionDuration = '0s'
    const trigger = getComputedStyle(row.trigger)
    assert.strictEqual(trigger.display, 'flex')
    assert.strictEqual(trigger.columnGap, '4px', 'gap-1')
    assert.strictEqual(trigger.borderRadius, '8px', 'rounded-md')
    assert.strictEqual(trigger.cursor, 'pointer')
    assert.strictEqual(trigger.backgroundColor, 'rgba(0, 0, 0, 0)', 'no button background')
    assert.strictEqual(trigger.borderTopWidth, '0px', 'no button border')
    assert.strictEqual(trigger.paddingTop, '0px', 'no button padding')
    assert.notStrictEqual(
      trigger.color,
      getComputedStyle(document.querySelector('[data-test-text]')!).color,
      'text-muted-foreground',
    )
    assert.true(row.isOpen, '@defaultOpen starts it open')
    assert.strictEqual(
      getComputedStyle(row.indicator).rotate,
      '90deg',
      'the chevron turns a quarter while open',
    )
    const inner = getComputedStyle(row.content.firstElementChild!)
    assert.strictEqual(inner.borderInlineStartWidth, '1px', 'border-s')
    assert.strictEqual(inner.paddingInlineStart, '16px', 'ps-4')
    assert.strictEqual(inner.marginInlineStart, '7px', 'ms-[calc(--spacing(2)-1px)]')
    assert.strictEqual(inner.marginTop, '8px', 'mt-2')
    assert.strictEqual(getComputedStyle(row.content).overflow, 'hidden')

    await row.close()
    await settled()
    assert.strictEqual(getComputedStyle(row.indicator).rotate, 'none', 'and back')
    await a11yAudit()
  })

  test('controlled: @open and @onOpenChange, and a row that errors colours its trigger', async function (assert) {
    class State {
      @tracked open = false
      changes: boolean[] = []
      onOpenChange = (open: boolean) => {
        this.changes.push(open)
        this.open = open
      }
    }
    const state = new State()
    await render(
      <template>
        <TraceCollapsible
          @name="lint"
          @open={{state.open}}
          @onOpenChange={{state.onOpenChange}}
          as |c|
        >
          <c.Trigger>
            <TraceLine @status="error" as |l|><l.Title>Failed to run pnpm lint</l.Title></TraceLine>
          </c.Trigger>
          <c.Content>2 problems</c.Content>
        </TraceCollapsible>
        <p data-test-text>Body text</p>
      </template>,
    )
    const row = new TraceCollapsibleHarness('lint')
    assert.false(row.isOpen)
    state.open = true
    await settled()
    assert.true(row.isOpen, 'the caller opens it')
    await row.toggle()
    assert.deepEqual(state.changes, [false], 'the trigger asks to close it')
    assert.false(row.isOpen)
    assert.true(row.line.isError)
    assert.notStrictEqual(
      getComputedStyle(row.trigger).color,
      getComputedStyle(document.querySelector('[data-test-text]')!).color,
      'has-[[data-status=error]]:text-destructive',
    )
    await a11yAudit()
  })

  test('the chevron can be replaced', async function (assert) {
    await render(
      <template>
        <TraceCollapsible @name="row" as |c|>
          <c.Trigger @icon={{ChevronsDown}}>
            <TraceLine as |l|><l.Title>Thought</l.Title></TraceLine>
          </c.Trigger>
          <c.Content>Checked the lockfile.</c.Content>
        </TraceCollapsible>
      </template>,
    )
    const row = new TraceCollapsibleHarness('row')
    assert.dom(row.indicator.querySelector('svg')).hasClass('lucide')
    assert.strictEqual(row.indicator.querySelectorAll('svg path').length, 2, 'chevrons-down')
    await a11yAudit()
  })

  test('nested rows: the harness finds every line and row, in order', async function (assert) {
    await render(
      <template>
        <TraceCollapsible @name="turn" @defaultOpen={{true}} as |c|>
          <c.Trigger>
            <TraceLine @status="running" as |l|><l.Title>Looking into the slow deploy</l.Title></TraceLine>
          </c.Trigger>
          <c.Content>
            <Trace @name="steps">
              <TraceCollapsible @name="search" as |s|>
                <s.Trigger>
                  <TraceLine as |l|><l.Title>Searched for the build log</l.Title></TraceLine>
                </s.Trigger>
                <s.Content>vercel.com</s.Content>
              </TraceCollapsible>
              <a href="#deploys">
                <TraceLine as |l|><l.Title>Read the last twelve deploys</l.Title></TraceLine>
              </a>
            </Trace>
          </c.Content>
        </TraceCollapsible>
      </template>,
    )
    const steps = new TraceHarness('steps')
    assert.deepEqual(steps.titles, ['Searched for the build log', 'Read the last twelve deploys'])
    assert.strictEqual(steps.collapsibles.length, 1)
    assert.strictEqual(steps.collapsible('search').line.title, 'Searched for the build log')
    assert.true(steps.line({ index: 1 }).isLink)
    const turn = new TraceCollapsibleHarness('turn')
    assert.true(turn.line.isRunning)
    assert.strictEqual(
      turn.line.title,
      'Looking into the slow deploy',
      'its own line, not a nested one',
    )
    await steps.collapsible('search').open()
    assert.strictEqual(steps.collapsible('search').text, 'vercel.com')
    await a11yAudit()
  })

  test('right to left, the content indents from the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div dir="rtl" style="width: 320px">
            <TraceCollapsible @name="row" @defaultOpen={{true}} as |c|>
              <c.Trigger>
                <TraceLine as |l|>
                  <l.Icon><Icon @icon={{Terminal}} /></l.Icon>
                  <l.Title>شغّل node --version</l.Title>
                </TraceLine>
              </c.Trigger>
              <c.Content>v24.18.0</c.Content>
            </TraceCollapsible>
          </div>
        </DirectionProvider>
      </template>,
    )
    const row = new TraceCollapsibleHarness('row')
    const inner = getComputedStyle(row.content.firstElementChild!)
    assert.strictEqual(inner.borderRightWidth, '1px', 'the border on the right')
    assert.strictEqual(inner.borderLeftWidth, '0px')
    assert.strictEqual(inner.paddingRight, '16px')
    const icon = row.line.icons[0]!.getBoundingClientRect()
    const title = row.line.titleElement.getBoundingClientRect()
    assert.ok(icon.left > title.left, 'the icon starts the line, on the right')
    assert.strictEqual(getComputedStyle(row.trigger).textAlign, 'start')
    await a11yAudit()
  })

  test('a running title stays still when the reader prefers less motion', async function (assert) {
    // `motion-reduce:shimmer-none` can't be toggled from a test, so check the rule is there.
    await render(
      <template>
        <TraceLine @status="running" @name="build" as |l|><l.Title>Running pnpm build</l.Title></TraceLine>
      </template>,
    )
    const line = new TraceLineHarness('build')
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const animation = getComputedStyle(line.titleElement).animationName
    assert.strictEqual(animation === 'none', reduce, 'it animates unless motion is reduced')
    assert.strictEqual(line.title, 'Running pnpm build', 'the title still says what is happening')
    await a11yAudit()
  })
})
