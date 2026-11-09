import { module, test } from 'qunit'
import { find, findAll, render, visit } from '@ember/test-helpers'
import { setupApplicationTest, setupRenderingTest } from 'ember-qunit'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import * as ember from '@ember-joinery/ember'
import * as testSupport from '@ember-joinery/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'

/** Every cascade layer the page's style sheets declare, in order. */
function declaredLayers() {
  const layers = []
  const walk = rules => {
    for (const rule of rules) {
      if (rule instanceof CSSLayerStatementRule) layers.push(...rule.nameList)
      else if (rule instanceof CSSLayerBlockRule) {
        layers.push(rule.name)
        walk(rule.cssRules)
      }
    }
  }
  for (const sheet of document.styleSheets) {
    // Cross-origin sheets (a font service, say) can't be read; Joinery's never are.
    let rules
    try {
      rules = sheet.cssRules
    } catch {
      continue
    }
    walk(rules)
  }
  return layers
}

module('Acceptance | smoke', function (hooks) {
  setupApplicationTest(hooks)

  test('Joinery loads next to Tailwind, between its base and its utilities', async function (assert) {
    await visit('/')

    assert.dom('h1').hasText('Joinery in a Tailwind app')
    assert.strictEqual(typeof ember, 'object', '@ember-joinery/ember imports')
    assert.strictEqual(typeof testSupport, 'object', '@ember-joinery/test-support imports')

    // Tailwind compiled the classes the templates use.
    assert.strictEqual(getComputedStyle(find('h1')).fontWeight, '700', 'font-bold applies')

    // The first declaration of a layer fixes its place. Joinery's comes after `base`, so
    // preflight's resets don't undo its rules, and before `utilities`, so a utility class on a
    // component overrides them.
    const layers = declaredLayers()
    const at = name => layers.indexOf(name)
    assert.true(layers.includes('joinery'), 'joinery.css is loaded')
    assert.true(
      at('base') !== -1 && at('base') < at('joinery'),
      `joinery is declared after base: ${layers.join(', ')}`,
    )
    assert.true(
      at('joinery') < at('utilities'),
      `joinery is declared before utilities: ${layers.join(', ')}`,
    )

    await a11yAudit()
  })

  test("tailwind.css maps the tokens, and a utility class overrides a component's style", async function (assert) {
    await visit('/')
    const save = new ButtonHarness('save')
    assert.strictEqual(getComputedStyle(save.element).height, '32px', 'joinery.css styles it')

    // text-muted-foreground is shadcn's token, through tailwind.css's @theme inline.
    const muted = getComputedStyle(document.documentElement).getPropertyValue('--muted-foreground')
    assert.ok(muted.trim().startsWith('oklch'), 'tokens.css is loaded')
    assert.notStrictEqual(
      getComputedStyle(find('main > p')).color,
      'rgb(0, 0, 0)',
      'text-muted-foreground',
    )

    const up = new ButtonHarness('up')
    const radius = Number.parseFloat(getComputedStyle(up.element).borderTopLeftRadius)
    assert.ok(radius > 1000, `rounded-full beats the style's radius (${radius}px)`)
    await a11yAudit()
  })
})

module('Rendering | the cascade', function (hooks) {
  setupRenderingTest(hooks)

  test("preflight doesn't undo Joinery's rules, and utilities override them", async function (assert) {
    // A rule as joinery.css writes them: zero specificity, in Joinery's layer. Preflight sets
    // padding 0, radius 0 and a transparent background on every button, in `base`.
    const style = document.createElement('style')
    style.textContent = `@layer joinery {
      :where(.probe) { padding: 16px; border-radius: 6px; background-color: rgb(10 20 30); }
    }`
    document.head.append(style)
    try {
      await render(
        <template>
          <button type="button" class="probe">Joinery's rule</button>
          <button type="button" class="probe rounded-none p-1">Overridden</button>
        </template>,
      )
      const [plain, overridden] = findAll('button').map(button => getComputedStyle(button))

      assert.strictEqual(plain.paddingTop, '16px', 'padding survives preflight')
      assert.strictEqual(plain.borderTopLeftRadius, '6px', 'radius survives preflight')
      assert.strictEqual(plain.backgroundColor, 'rgb(10, 20, 30)', 'background survives preflight')

      assert.strictEqual(overridden.paddingTop, '4px', 'p-1 overrides the padding')
      assert.strictEqual(overridden.borderTopLeftRadius, '0px', 'rounded-none overrides the radius')
    } finally {
      style.remove()
    }
  })
})
