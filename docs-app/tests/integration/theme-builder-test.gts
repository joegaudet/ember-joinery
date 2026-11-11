import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, findAll, render, triggerEvent, waitFor, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  InputHarness,
  NativeSelectHarness,
  SwitchHarness,
  scrollIntoView,
} from '@ember-joinery/test-support'
import { ThemeBuilder } from 'docs-app/components/theme-builder'

const demo = (name: string) => `[data-test-theme-demo="${name}"]`
const stageOf = (name: string) => find(`${demo(name)} .tb-demo-stage`) as HTMLElement

/** The builder's controls, by the `@name` each is given. */
class Builder {
  style = new NativeSelectHarness('style')
  baseColor = new NativeSelectHarness('base-color')
  radius = new NativeSelectHarness('radius')
  dark = new SwitchHarness('dark')
  copy = new ButtonHarness('copy-css')
  reset = new ButtonHarness('reset')
  token = (name: string) => new InputHarness(name)
  get css() {
    return find('[data-test-theme-css]')!.textContent!
  }
}

/**
 * Renders the builder, and scrolls to the Button page's demo, as a reader would: each demo
 * renders as it nears the viewport.
 */
async function renderBuilder() {
  await render(<template><ThemeBuilder /></template>)
  await waitFor(demo('button-demo'), { timeout: 10000 })
  await scrollIntoView(demo('button-demo'))
  await waitFor(`${demo('button-demo')} [data-slot="button"]`, { timeout: 10000 })
}

module('Integration | <ThemeBuilder>', function (hooks) {
  setupRenderingTest(hooks)

  test("every component page's demo, in the style and colours picked", async function (assert) {
    await renderBuilder()
    const builder = new Builder()
    const demos = findAll('[data-test-theme-demo]').map(each =>
      each.getAttribute('data-test-theme-demo'),
    )
    assert.true(demos.length > 60, `${demos.length} demos`)
    assert.true(demos.includes('dialog-demo') && demos.includes('chart-demo'))
    assert.false(demos.includes('sidebar-demo'), 'a block needs a frame of its own')
    assert.dom(`${demo('button-demo')} a`).hasAttribute('href', /components\/button\.md$/)

    assert.strictEqual(builder.style.value, 'nova')
    assert.dom(stageOf('button-demo')).hasAttribute('data-style', 'nova')
    await builder.style.select('lyra')
    assert.dom(stageOf('button-demo')).hasAttribute('data-style', 'lyra')
    assert.true(builder.css.includes("import '@ember-joinery/ember/styles/lyra.css'"))

    const primary = builder.token('--primary')
    const neutral = primary.value
    await builder.baseColor.select('mauve')
    assert.notStrictEqual(primary.value, neutral, "the base colour's tokens")
    assert.true(stageOf('button-demo').style.getPropertyValue('--primary').includes(primary.value))

    await builder.radius.select('1')
    assert.strictEqual(stageOf('button-demo').style.getPropertyValue('--radius'), '1rem')
    await a11yAudit()
  })

  test('edit a token: every demo takes it, and the CSS has it', async function (assert) {
    await renderBuilder()
    const builder = new Builder()
    await scrollIntoView(demo('badge-demo'))
    await waitFor(`${demo('badge-demo')} [data-slot="badge"]`, { timeout: 10000 })
    const badge = () => find(`${demo('badge-demo')} [data-slot="badge"][data-variant="default"]`)!

    await builder.token('--primary').fillIn('oklch(0.6 0.2 30)')
    // The badge's colours transition, so wait for it to land on the new token.
    const lands = (color: string) =>
      waitUntil(() => getComputedStyle(badge()).backgroundColor === color, { timeout: 3000 })
    await lands('oklch(0.6 0.2 30)')
    assert.strictEqual(getComputedStyle(badge()).backgroundColor, 'oklch(0.6 0.2 30)')
    assert.true(builder.css.includes(':root {\n  --radius: 0.625rem;'))
    assert.true(builder.css.includes('  --primary: oklch(0.6 0.2 30);'))
    assert.false(builder.reset.isDisabled)

    await builder.token('--primary').fillIn('oklch(0.6 0.2')
    assert.true(builder.token('--primary').isInvalid, 'a half-typed colour is marked')
    await lands('oklch(0.205 0 0)')
    assert.strictEqual(
      getComputedStyle(badge()).backgroundColor,
      'oklch(0.205 0 0)',
      "and isn't applied: Neutral's is back",
    )

    // The swatch picks a colour as the browser's colour input does, and writes it as OKLCH.
    const swatch = find(
      '[data-test-theme-token="--primary"] input[type="color"]',
    ) as HTMLInputElement
    swatch.value = '#ff0000'
    await triggerEvent(swatch, 'input')
    assert.strictEqual(builder.token('--primary').value, 'oklch(0.628 0.258 29.234)')
    assert.false(builder.token('--primary').isInvalid)

    await builder.reset.click()
    assert.true(builder.reset.isDisabled, 'nothing left to reset')
    assert.false(builder.css.includes('29.234'))
    await a11yAudit()
  })

  test('dark mode: the dark tokens, edited apart from the light ones', async function (assert) {
    await renderBuilder()
    const builder = new Builder()
    const lightBackground = builder.token('--background').value
    await builder.dark.click()
    assert.true(builder.dark.isChecked)
    assert.dom(stageOf('button-demo')).hasClass('dark')
    assert.notStrictEqual(builder.token('--background').value, lightBackground)

    await builder.token('--background').fillIn('oklch(0.2 0.02 260)')
    const css = builder.css
    assert.true(css.includes('.dark {\n  --background: oklch(0.2 0.02 260);'), 'the dark block')
    assert.true(css.includes(`:root {\n  --radius: 0.625rem;\n  --background: ${lightBackground};`))

    await builder.dark.click()
    assert.strictEqual(builder.token('--background').value, lightBackground, 'light is as it was')
    await a11yAudit()
  })

  test('Copy CSS puts the theme on the clipboard', async function (assert) {
    const copied: string[] = []
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText: async (text: string) => void copied.push(text) },
    })
    try {
      await renderBuilder()
      const builder = new Builder()
      await builder.token('--ring').fillIn('oklch(0.7 0.15 150)')
      await builder.copy.click()
      await waitUntil(() => copied.length)
      assert.strictEqual(copied[0], builder.css)
      assert.true(copied[0]!.includes('--ring: oklch(0.7 0.15 150);'))
      assert.strictEqual(builder.copy.text, 'Copied')
      await a11yAudit()
    } finally {
      delete (navigator as { clipboard?: unknown }).clipboard
    }
  })
})
