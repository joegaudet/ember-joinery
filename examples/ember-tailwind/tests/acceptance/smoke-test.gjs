import { module, test } from 'qunit'
import { find, visit } from '@ember/test-helpers'
import { setupApplicationTest } from 'ember-qunit'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import * as ember from '@ember-joinery/ember'
import * as testSupport from '@ember-joinery/test-support'

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

  test('Joinery loads next to Tailwind, under its utilities', async function (assert) {
    await visit('/')

    assert.dom('h1').hasText('Joinery in a Tailwind app')
    assert.strictEqual(typeof ember, 'object', '@ember-joinery/ember imports')
    assert.strictEqual(typeof testSupport, 'object', '@ember-joinery/test-support imports')

    // Tailwind compiled the classes the templates use.
    assert.strictEqual(getComputedStyle(find('h1')).fontWeight, '700', 'font-bold applies')

    // The first declaration of a layer fixes its place: joinery comes first, so it loses to
    // every Tailwind layer, and a utility class on a component overrides Joinery's rules.
    const layers = declaredLayers()
    assert.true(layers.includes('joinery'), 'joinery.css is loaded')
    assert.true(
      layers.indexOf('joinery') < layers.indexOf('utilities'),
      `joinery is declared before utilities: ${layers.join(', ')}`,
    )

    await a11yAudit()
  })
})
