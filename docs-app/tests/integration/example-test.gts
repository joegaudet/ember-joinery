import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, find, render, triggerKeyEvent, waitUntil } from '@ember/test-helpers'
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
       <a href="#stage" data-test-stage>a link</a>`,
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

  test('a missing example says so instead of failing the page', async function (assert) {
    await render(<template><Example @name="no-such-example" /></template>)
    assert.dom('.example-missing[role="alert"]').includesText('no-such-example')
    assert.dom('.example-preview').doesNotExist()
  })
})
