import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { currentRouteName, find, visit } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { exampleNames } from 'docs-app/examples/index'

module('Acceptance | parity route', function (hooks) {
  setupApplicationTest(hooks)

  test('renders one example with no frame and no guide around it', async function (assert) {
    await visit('/parity/introduction')
    assert.strictEqual(currentRouteName(), 'parity')
    assert.dom('[data-parity="introduction"]').exists()
    assert.dom('[data-parity] button').hasText('Bold')
    assert.dom('[data-test-example]').doesNotExist('no example frame')
    assert.dom('.guide-header').doesNotExist('no guide header')
    assert.dom('.guide-sidebar').doesNotExist('no sidebar')
    assert.dom('[data-parity]').hasAttribute('data-align', 'center').hasAttribute('dir', 'ltr')
    // Light unless asked otherwise, whatever the browser prefers.
    assert.dom(document.documentElement).hasClass('light').doesNotHaveClass('dark')
    assert.strictEqual(getComputedStyle(document.documentElement).colorScheme, 'light')
    // The stage starts the text styles over, as upstream's preview does.
    assert.strictEqual(getComputedStyle(find('[data-parity]')!).lineHeight, '24px')
    // The guide's box-sizing reset stops at the stage, so the example sizes as in an app
    // without Tailwind; the stage itself fits the viewport.
    const box = document.createElement('div')
    find('[data-parity]')!.append(box)
    assert.strictEqual(getComputedStyle(box).boxSizing, 'content-box')
    box.remove()
    assert.strictEqual(getComputedStyle(find('[data-parity]')!).boxSizing, 'border-box')
    // Parity pages are screenshots, not documents: the audit skips the page-level rules.
    await a11yAudit({ rules: { region: { enabled: false } } })
  })

  test('theme, dir and align set the page up as the comparison asks', async function (assert) {
    await visit('/parity/introduction?theme=dark&dir=rtl&align=start')
    assert.dom(document.documentElement).hasClass('dark').doesNotHaveClass('light')
    assert.strictEqual(getComputedStyle(document.documentElement).colorScheme, 'dark')
    assert.dom('[data-parity]').hasAttribute('dir', 'rtl').hasAttribute('data-align', 'start')

    await visit('/parity/introduction?theme=light')
    assert.dom(document.documentElement).hasClass('light').doesNotHaveClass('dark')
    assert.strictEqual(getComputedStyle(document.documentElement).colorScheme, 'light')

    await visit('/getting-started/introduction.md')
    assert
      .dom(document.documentElement)
      .doesNotHaveClass('dark', 'leaving the route undoes it')
      .doesNotHaveClass('light')
    assert.strictEqual(
      getComputedStyle(document.documentElement).colorScheme,
      'light dark',
      'the guide follows the browser again',
    )
  })

  test('style and base pick the style and base colour the example shows in', async function (assert) {
    await visit('/parity/button-default')
    const stage = () => find('[data-parity]') as HTMLElement
    const button = () => find('[data-parity] [data-slot="button"]') as HTMLElement
    assert.dom(stage()).hasAttribute('data-style', 'nova', 'Nova by default')
    const neutral = getComputedStyle(button()).backgroundColor
    assert.strictEqual(getComputedStyle(button()).height, '32px', "Nova's h-8")
    assert.strictEqual(getComputedStyle(button()).borderTopLeftRadius, '10px')

    await visit('/parity/button-default?style=lyra')
    assert.dom(stage()).hasAttribute('data-style', 'lyra')
    assert.strictEqual(
      getComputedStyle(button()).borderTopLeftRadius,
      '0px',
      "Lyra's square corners, and none of Nova's rules",
    )

    await visit('/parity/button-default?base=mauve')
    assert.dom(stage()).hasAttribute('data-style', 'nova')
    const mauve = getComputedStyle(button()).backgroundColor
    assert.notStrictEqual(mauve, neutral, 'mauve tokens')

    await visit('/parity/button-default?base=mauve&theme=dark')
    assert.dom(stage()).hasClass('dark')
    assert.notStrictEqual(getComputedStyle(button()).backgroundColor, mauve, "mauve's dark tokens")

    // A new style is a new stage (see the controller's stageKey); the page stays dark.
    await visit('/parity/button-default?base=mauve&theme=dark&style=nova')
    await visit('/parity/button-default?base=mauve&theme=dark&style=lyra')
    assert.dom(stage()).hasAttribute('data-style', 'lyra').hasClass('dark')
    assert.strictEqual(getComputedStyle(button()).borderTopLeftRadius, '0px')
    assert.dom(document.documentElement).hasClass('dark').doesNotHaveClass('light')
    assert.strictEqual(getComputedStyle(document.documentElement).colorScheme, 'dark')
    await a11yAudit({ rules: { region: { enabled: false } } })
  })

  test('fullWidth stretches the example across the stage, so a chart in it has room', async function (assert) {
    const svg = '[data-parity] [data-slot="chart"] svg.recharts-surface'
    await visit('/parity/chart-line-interactive')
    const stage = () => find('[data-parity]') as HTMLElement
    assert.dom(stage()).doesNotHaveAttribute('data-full-width')
    assert
      .dom(svg)
      .doesNotExist('centred, the card shrinks to its content and the chart to nothing')

    await visit('/parity/chart-line-interactive?fullWidth=true')
    assert.dom(stage()).hasAttribute('data-full-width', 'true')
    const card = find('[data-parity] > [data-slot="card"]') as HTMLElement
    const padding = parseFloat(getComputedStyle(stage()).paddingLeft) * 2
    assert.strictEqual(
      card.offsetWidth,
      stage().clientWidth - padding,
      'the stage less its padding',
    )
    assert.dom(svg).exists('and the chart draws')
    await a11yAudit({ rules: { region: { enabled: false } } })
  })

  test('an unknown example says so', async function (assert) {
    await visit('/parity/no-such-example')
    assert.dom('[data-parity-missing="no-such-example"]').exists()
    assert.dom('[data-parity]').doesNotExist()
  })

  test('every example renders on its own', async function (assert) {
    for (const name of exampleNames()) {
      await visit(`/parity/${name}`)
      assert.dom(`[data-parity="${name}"]`).exists(name)
    }
  })
})
