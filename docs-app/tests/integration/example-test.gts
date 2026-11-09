import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, find, render, select, triggerKeyEvent, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
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

  test('the RTL switch lays the preview out right to left, and back', async function (assert) {
    await render(<template><Example @name="button-default" /></template>)
    assert.dom('.example-preview').doesNotHaveAttribute('dir')
    assert.dom('[data-test-example-rtl]').hasAria('pressed', 'false')

    await click('[data-test-example-rtl]')
    assert.dom('.example-preview').hasAttribute('dir', 'rtl')
    assert.dom('[data-test-example-rtl]').hasAria('pressed', 'true')

    await click('[data-test-example-rtl]')
    assert.dom('.example-preview').doesNotHaveAttribute('dir')

    await render(<template><Example @name="button-rtl" @dir="rtl" /></template>)
    assert.dom('[data-test-example-rtl]').hasAria('pressed', 'true', 'an RTL example starts on')
    await click('[data-test-example-rtl]')
    assert.dom('.example-preview').hasAttribute('dir', 'ltr')
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

  test('a missing example says so instead of failing the page', async function (assert) {
    await render(<template><Example @name="no-such-example" /></template>)
    assert.dom('.example-missing[role="alert"]').includesText('no-such-example')
    assert.dom('.example-preview').doesNotExist()
  })
})
