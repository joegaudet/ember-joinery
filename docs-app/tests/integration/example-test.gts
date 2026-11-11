import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, find, render, select, triggerKeyEvent, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NavigationMenuHarness } from '@ember-joinery/test-support'
import { Example } from 'docs-app/components/example'

const tab = (name: string) => `[data-test-example-tab="${name}"]`

module('Integration | <Example>', function (hooks) {
  setupRenderingTest(hooks)

  test('shows the example live, then its source and its test', async function (assert) {
    await render(<template><Example @name="introduction" @title="A first example" /></template>)

    assert.dom('[data-test-example="introduction"] .example-title').hasText('A first example')
    assert.dom('[role="tab"]').exists({ count: 3 })
    assert.dom(tab('preview')).hasAria('selected', 'true').hasAttribute('tabindex', '0')
    assert.dom('[role="tabpanel"]').hasAria('labelledby', 'example-introduction-tab-preview')
    assert.dom('.example-preview button').hasText('Bold')
    assert.dom('.example-preview').hasAttribute('data-align', 'center')

    await click(tab('template'))
    assert.dom(tab('template')).hasAria('selected', 'true')
    assert.dom(tab('preview')).hasAria('selected', 'false').hasAttribute('tabindex', '-1')
    assert.dom('.example-code pre.shiki').exists('highlighted by Shiki')
    assert.dom('.example-code').includesText('export default class IntroductionExample')

    await click(tab('test'))
    assert.dom('.example-code').includesText("module('Example | introduction'")

    await a11yAudit()
  })

  test('the Template tab also shows the files the example imports, which Copy includes', async function (assert) {
    const copied: string[] = []
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText: async (text: string) => void copied.push(text) },
    })
    try {
      await render(<template><Example @name="load-on-demand" /></template>)
      await click(tab('template'))
      assert.dom('.example-code').includesText("import('./lazy/revenue-summary.gts')")
      assert.dom('.example-file').hasText('lazy/revenue-summary.gts', 'the file, by name')
      assert.dom('.example-code pre.shiki').exists({ count: 2 }, 'and its source')
      assert.dom('.example-code').includesText('const RevenueSummary')

      await click('.example-copy')
      assert.true(copied[0]?.includes('// lazy/revenue-summary.gts'), 'copied with the example')
      assert.true(copied[0]?.includes('const RevenueSummary'))
      await a11yAudit()
    } finally {
      delete (navigator as { clipboard?: unknown }).clipboard
    }
  })

  test('arrow keys, Home and End move between the tabs', async function (assert) {
    await render(<template><Example @name="introduction" /></template>)

    await triggerKeyEvent(tab('preview'), 'keydown', 'ArrowRight')
    assert.dom(tab('template')).hasAria('selected', 'true').isFocused()

    await triggerKeyEvent(tab('template'), 'keydown', 'End')
    assert.dom(tab('test')).hasAria('selected', 'true').isFocused()

    await triggerKeyEvent(tab('test'), 'keydown', 'ArrowRight')
    assert.dom(tab('preview')).hasAria('selected', 'true').isFocused('wraps around')

    await triggerKeyEvent(tab('preview'), 'keydown', 'ArrowLeft')
    assert.dom(tab('test')).hasAria('selected', 'true').isFocused('and back')

    await triggerKeyEvent(tab('test'), 'keydown', 'Home')
    assert.dom(tab('preview')).hasAria('selected', 'true').isFocused()
  })

  test('the copy button copies the file the tab shows', async function (assert) {
    const copied: string[] = []
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText: async (text: string) => void copied.push(text) },
    })
    try {
      await render(<template><Example @name="introduction" /></template>)
      await click(tab('template'))
      await click('.example-copy')
      assert.dom('.example-copy').hasText('Copied')
      assert.dom('.example-copied[role="status"]').hasText('Copied')
      assert.true(copied[0]?.includes('export default class IntroductionExample'))

      await click(tab('test'))
      assert.dom('.example-copy').hasText('Copy', 'a new tab starts over')
      await click('.example-copy')
      assert.true(copied[1]?.includes("module('Example | introduction'"))
      await waitUntil(
        () => document.querySelector('.example-copy')?.textContent?.trim() === 'Copy',
        {
          timeout: 3000,
        },
      )
    } finally {
      // Back to the browser's own, on Navigator.prototype.
      delete (navigator as { clipboard?: unknown }).clipboard
    }
  })

  test("the guide's own styles stop at the preview", async function (assert) {
    await render(
      <template>
        <article class="guide-prose">
          <table data-test-prose><tbody><tr><th>Prose</th><td><code
                  >prose</code></td></tr></tbody></table>
          <a href="#prose" data-test-prose>a link</a>
          <Example @name="introduction" />
        </article>
      </template>,
    )
    // The kinds of element a Table, Typography or Breadcrumb example renders.
    find('.example-preview')!.insertAdjacentHTML(
      'beforeend',
      `<table data-test-stage><tbody><tr><th>Stage</th><td><code>stage</code></td></tr></tbody></table>
       <h2 data-test-stage>A heading</h2>
       <a href="#stage" data-test-stage>a link</a>
       <div data-test-stage-box style="width: 100px; padding: 10px"></div>`,
    )
    const style = (selector: string) => getComputedStyle(find(selector)!)

    // The prose rules apply to the page's own elements…
    assert.strictEqual(style('table[data-test-prose]').display, 'block')
    assert.strictEqual(style('[data-test-prose] th').textTransform, 'uppercase')
    assert.notStrictEqual(style('[data-test-prose] code').backgroundColor, 'rgba(0, 0, 0, 0)')

    // …and not to an example's.
    assert.strictEqual(style('table[data-test-stage]').display, 'table')
    assert.strictEqual(style('[data-test-stage] th').textTransform, 'none')
    assert.strictEqual(style('[data-test-stage] td').paddingTop, '1px', "the browser's own")
    assert.strictEqual(style('[data-test-stage] code').backgroundColor, 'rgba(0, 0, 0, 0)')
    assert.strictEqual(style('h2[data-test-stage]').borderTopWidth, '0px')
    assert.notStrictEqual(
      style('a[data-test-stage]').color,
      style('a[data-test-prose]').color,
      "the guide's link colour stays out",
    )

    // The guide's box-sizing reset covers the guide, the frame and the stage itself, and stops
    // there: inside, a box sizes as Joinery's CSS says, as in an app without Tailwind.
    assert.strictEqual(style('.guide-prose').boxSizing, 'border-box')
    assert.strictEqual(style('.example-bar').boxSizing, 'border-box')
    assert.strictEqual(style('.example-preview').boxSizing, 'border-box')
    assert.strictEqual(style('[data-test-stage-box]').boxSizing, 'content-box')
    assert.strictEqual((find('[data-test-stage-box]') as HTMLElement).offsetWidth, 120)

    // The text styles the page passes down start over, as in upstream's preview.
    const stage = style('.example-preview')
    assert.strictEqual(stage.lineHeight, '24px', 'line-height 1.5')
    assert.strictEqual(stage.fontSize, '16px')
    assert.true(stage.fontFamily.startsWith('Geist'), stage.fontFamily)
  })

  test("Joinery's layer wins over the guide's rules, whatever their specificity", async function (assert) {
    // A rule as joinery.css writes them: zero specificity, in Joinery's layer.
    const sheet = document.createElement('style')
    sheet.textContent = '@layer joinery { :where(.probe) { color: rgb(1, 2, 3); } }'
    document.head.append(sheet)
    try {
      await render(
        <template>
          <article class="guide-prose"><a href="#probe" class="probe">a link</a></article>
          <button type="button" class="intro-toggle probe">a guide class</button>
        </template>,
      )
      assert.strictEqual(getComputedStyle(find('a.probe')!).color, 'rgb(1, 2, 3)')
      assert.strictEqual(getComputedStyle(find('button.probe')!).color, 'rgb(1, 2, 3)')
    } finally {
      sheet.remove()
    }
  })

  test('@dir lays the preview out right to left, and only the preview', async function (assert) {
    await render(<template><Example @name="introduction" @dir="rtl" /></template>)
    assert.dom('.example-preview').hasAttribute('dir', 'rtl')
    assert.strictEqual(getComputedStyle(find('.example-preview button')!).direction, 'rtl')
    assert.strictEqual(getComputedStyle(find('.example-bar')!).direction, 'ltr', 'not the frame')
    await a11yAudit()

    await render(<template><Example @name="introduction" /></template>)
    assert.dom('.example-preview').doesNotHaveAttribute('dir', 'without it, the page decides')
  })

  test('@fullWidth stretches the example across the preview', async function (assert) {
    // Upstream widens the chart demo's preview child (`[&_.preview>div]:w-full`). Centred
    // without it, a card with no width of its own shrinks to its content, and its chart to
    // nothing.
    const svg = '.example-preview [data-slot="chart"] svg.recharts-surface'
    await render(<template><Example @name="chart-demo" /></template>)
    assert.dom('.example-preview').doesNotHaveAttribute('data-full-width')
    assert.dom(svg).doesNotExist()

    await render(<template><Example @name="chart-demo" @fullWidth={{true}} /></template>)
    const preview = find('.example-preview') as HTMLElement
    assert.dom(preview).hasAttribute('data-full-width', 'true')
    const card = find('.example-preview > [data-slot="card"]') as HTMLElement
    const padding = parseFloat(getComputedStyle(preview).paddingLeft) * 2
    assert.strictEqual(
      card.offsetWidth,
      preview.clientWidth - padding,
      'the preview less its padding',
    )
    await waitUntil(() => find(svg))
    assert.dom(svg).exists('the chart draws')
    await a11yAudit()
  })

  test('@previewClass and @overflow give the frame upstream’s preview height and overflow', async function (assert) {
    // The Navigation Menu page's previews, as upstream's previewClassName="h-96" and
    // className="overflow-visible": the viewport hangs below the list without being in the top
    // layer, so a frame that clips cuts its content off.
    await render(<template><Example @name="navigation-menu-demo" /></template>)
    assert.dom('.example').doesNotHaveAttribute('data-overflow')
    assert.strictEqual(getComputedStyle(find('.example')!).overflow, 'hidden', 'clipped')
    assert.strictEqual(getComputedStyle(find('.example-preview')!).height, '288px', 'its 18rem')

    await render(
      <template>
        <Example @name="navigation-menu-demo" @previewClass="h-96" @overflow="visible" />
      </template>,
    )
    const frame = find('.example') as HTMLElement
    const preview = find('.example-preview') as HTMLElement
    assert.dom(frame).hasAttribute('data-overflow', 'visible')
    assert.dom(preview).hasClass('h-96')
    assert.strictEqual(getComputedStyle(preview).height, '384px', 'h-96, as upstream’s')
    assert.strictEqual(getComputedStyle(frame).overflow, 'visible', 'nothing clipped')
    assert.strictEqual(
      getComputedStyle(find('.example-bar')!).borderTopLeftRadius,
      '15px',
      'the corners round themselves',
    )
    assert.strictEqual(getComputedStyle(preview).borderBottomRightRadius, '15px')

    const components = new NavigationMenuHarness().item('Components')
    await components.open()
    const content = components.content!.getBoundingClientRect()
    const box = frame.getBoundingClientRect()
    assert.ok(content.bottom > box.bottom, 'the open content reaches past the frame…')
    const covering = document.elementFromPoint(
      content.left + content.width / 2,
      (box.bottom + content.bottom) / 2,
    )
    assert.ok(components.content!.contains(covering), '…and shows there, over what follows')
    await a11yAudit()
  })

  test('the switchers show the preview in another style, base colour, radius and mode', async function (assert) {
    await render(<template><Example @name="button-default" /></template>)
    const stage = () => find('.example-preview') as HTMLElement
    const button = () => find('.example-preview [data-slot="button"]') as HTMLElement

    assert.dom(stage()).hasAttribute('data-style', 'nova').doesNotHaveClass('dark')
    assert.strictEqual(stage().style.getPropertyValue('--radius'), '0.625rem')
    assert.strictEqual(getComputedStyle(button()).height, '32px', "Nova's h-8")

    await select('[data-test-example-style]', 'lyra')
    assert.dom(stage()).hasAttribute('data-style', 'lyra')
    assert.notStrictEqual(
      getComputedStyle(button()).borderTopLeftRadius,
      '10px',
      "Lyra's own radius, and none of Nova's rules",
    )

    const primary = getComputedStyle(button()).backgroundColor
    await select('[data-test-example-base-color]', 'mauve')
    assert.notStrictEqual(getComputedStyle(button()).backgroundColor, primary, 'mauve tokens')

    await select('[data-test-example-style]', 'nova')
    await select('[data-test-example-radius]', '0')
    assert.strictEqual(stage().style.getPropertyValue('--radius'), '0rem')
    assert.strictEqual(getComputedStyle(button()).borderTopLeftRadius, '0px')

    const light = getComputedStyle(stage()).backgroundColor
    await click('[data-test-example-dark]')
    assert.dom('[data-test-example-dark]').hasAria('pressed', 'true')
    assert.dom(stage()).hasClass('dark')
    assert.notStrictEqual(getComputedStyle(stage()).backgroundColor, light, 'dark tokens')
    await a11yAudit()
  })

  test('the radius switcher scales the radius steps the style sheets use', async function (assert) {
    await render(<template><Example @name="button-size" @align="start" /></template>)
    const radius = (size: string) =>
      getComputedStyle(find(`.example-preview [data-size="${size}"]`)!).borderTopLeftRadius

    // Nova rounds its small sizes to min(var(--radius-md), …), and --radius-md is 0.8 of
    // --radius, set on the preview as joinery.css sets it on :root.
    assert.strictEqual(radius('xs'), '8px', 'min(0.8 × 10px, 10px)')
    assert.strictEqual(radius('sm'), '8px', 'min(0.8 × 10px, 12px)')
    assert.strictEqual(radius('default'), '10px', 'rounded-lg: --radius')

    await select('[data-test-example-radius]', '1')
    assert.strictEqual(radius('xs'), '10px', 'min(12.8px, 10px)')
    assert.strictEqual(radius('sm'), '12px', 'min(12.8px, 12px)')
    assert.strictEqual(radius('default'), '16px')

    await select('[data-test-example-radius]', '0.3')
    assert.strictEqual(radius('xs'), '3.84px', '0.8 × 4.8px')
    await a11yAudit()
  })

  test('the RTL switch lays the preview out right to left, and back', async function (assert) {
    await render(<template><Example @name="button-default" /></template>)
    assert.dom('.example-preview').doesNotHaveAttribute('dir')
    assert.dom('[data-test-example-rtl]').hasAria('pressed', 'false')

    await click('[data-test-example-rtl]')
    assert.dom('.example-preview').hasAttribute('dir', 'rtl')
    assert.dom('[data-test-example-rtl]').hasAria('pressed', 'true')

    await click('[data-test-example-rtl]')
    assert.dom('.example-preview').doesNotHaveAttribute('dir')
    await a11yAudit()

    await render(<template><Example @name="button-rtl" @dir="rtl" /></template>)
    assert.dom('[data-test-example-rtl]').hasAria('pressed', 'true', 'an RTL example starts on')
    await click('[data-test-example-rtl]')
    assert.dom('.example-preview').hasAttribute('dir', 'ltr')
    // Upstream's destructive button is 4.0:1 in Nova (--destructive on bg-destructive/10), under
    // AA's 4.5:1. Joinery keeps upstream's tokens; the stage's opaque background lets axe see it.
    await a11yAudit({
      include: [['#ember-testing']],
      exclude: [['.example-preview [data-variant="destructive"]']],
    })
  })

  test('a width preset shows the preview in a viewport that wide', async function (assert) {
    await render(<template><Example @name="button-demo" @title="Button" /></template>)
    assert.dom('[data-test-example-width="fit"]').hasAria('pressed', 'true')
    assert.dom('iframe').doesNotExist()

    await click('[data-test-example-width="375"]')
    await waitUntil(() => find('iframe')?.contentDocument?.querySelector('[data-slot="button"]'))
    const frame = find('iframe') as HTMLIFrameElement
    assert.dom(frame).hasAttribute('width', '375').hasAttribute('title', 'Button, 375px wide')
    const doc = frame.contentDocument!
    assert.strictEqual(doc.documentElement.clientWidth, 375)
    const button = doc.querySelector('[data-slot="button"]') as HTMLElement
    assert.strictEqual(
      frame.contentWindow!.getComputedStyle(button).height,
      '32px',
      'the style sheets are there',
    )
    assert.dom('[data-test-example-width="375"]').hasAria('pressed', 'true')

    await click('[data-test-example-width="fit"]')
    assert.dom('iframe').doesNotExist()
    assert.dom('.example-preview [data-slot="button"]').exists('back in the page')
    await a11yAudit()
  })

  test('a block shows its screen in a frame of its own, the preview wide', async function (assert) {
    await render(
      <template><Example @name="sidebar-menu" @title="Menu" @block={{true}} /></template>,
    )
    await waitUntil(() =>
      find('iframe')?.contentDocument?.querySelector('[data-slot="sidebar-wrapper"]'),
    )
    const frame = find('iframe') as HTMLIFrameElement
    assert.dom(frame).hasAttribute('title', 'Menu').hasAttribute('data-fill', 'true')
    assert.dom(frame).doesNotHaveAttribute('width', 'as wide as the preview')
    assert.strictEqual(frame.style.height, '600px', 'a fixed height, as a screen has')
    const doc = frame.contentDocument!
    const view = frame.contentWindow!
    const stage = doc.querySelector('.example-preview') as HTMLElement
    assert.dom(stage).hasAttribute('data-block', 'true')
    assert.strictEqual(view.getComputedStyle(stage).paddingTop, '0px', 'nothing around the screen')
    const wrapper = doc.querySelector('[data-slot="sidebar-wrapper"]') as HTMLElement
    assert.strictEqual(
      view.getComputedStyle(wrapper).minHeight,
      `${view.innerHeight}px`,
      "min-h-svh is the frame's height",
    )
    const container = doc.querySelector('[data-slot="sidebar-container"]') as HTMLElement
    assert.strictEqual(container.getBoundingClientRect().top, 0, 'fixed to the frame, not the page')

    await click('[data-test-example-width="375"]')
    await waitUntil(() =>
      find('iframe')?.contentDocument?.querySelector('[data-slot="sidebar-wrapper"]'),
    )
    const narrow = find('iframe') as HTMLIFrameElement
    assert.dom(narrow).hasAttribute('width', '375').hasAttribute('title', 'Menu, 375px wide')
    assert.strictEqual(narrow.style.height, '600px')
    // The provider measures the window it renders in: the frame's, narrower than the breakpoint.
    await waitUntil(() => !narrow.contentDocument?.querySelector('.jn-sidebar'))
    assert
      .dom(narrow.contentDocument!.querySelector('[data-slot="sidebar-wrapper"]'))
      .exists('a sheet on a phone, so no desktop panel')
    await a11yAudit()
  })

  test('@blockHeight frames a Blocks page’s block as ui.shadcn.com/blocks does', async function (assert) {
    await render(
      <template>
        <Example @name="login-01" @title="login-01" @block={{true}} @blockHeight={{930}} />
      </template>,
    )
    await waitUntil(() => find('iframe')?.contentDocument?.querySelector('form'))
    const frame = find('iframe') as HTMLIFrameElement
    assert.strictEqual(frame.style.height, '930px', "the blocks viewer's height, not 600px")
    assert.strictEqual(
      frame.contentWindow!.innerHeight,
      frame.clientHeight,
      'its window, which svh measures, is the frame inside its border',
    )

    await click('[data-test-example-width="375"]')
    await waitUntil(() =>
      (find('iframe[width="375"]') as HTMLIFrameElement | null)?.contentDocument?.querySelector(
        'form',
      ),
    )
    assert.strictEqual((find('iframe') as HTMLIFrameElement).style.height, '930px', 'at any width')
    await a11yAudit()
  })

  test("a form in the frame that submits to nowhere doesn't empty it", async function (assert) {
    await render(<template><Example @name="login-01" @title="Login" @block={{true}} /></template>)
    await waitUntil(() => find('iframe')?.contentDocument?.querySelector('form'))
    const frame = find('iframe') as HTMLIFrameElement
    const doc = frame.contentDocument!
    const form = doc.querySelector('form')!
    for (const input of form.querySelectorAll('input')) input.value = 'm@example.com'
    let prevented = false
    doc.addEventListener('submit', event => (prevented = event.defaultPrevented))
    form.requestSubmit()
    assert.true(prevented, 'the submit stops at the frame')
    assert.strictEqual(frame.contentDocument, doc, 'the frame keeps its page')
    assert.dom(doc.querySelector('[data-slot="card"]')).exists('and the block in it')
    await a11yAudit()
  })

  test('a missing example says so instead of failing the page', async function (assert) {
    await render(<template><Example @name="no-such-example" /></template>)
    assert.dom('.example-missing[role="alert"]').includesText('no-such-example')
    assert.dom('.example-preview').doesNotExist()
  })
})
