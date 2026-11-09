import { module, test } from 'qunit'
import { visit } from '@ember/test-helpers'
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

  test('the v2 addons work in a classic ember-cli build', async function (assert) {
    await visit('/')

    assert.dom('h1').hasText('Joinery in a classic app')
    assert.strictEqual(typeof ember, 'object', '@ember-joinery/ember imports')
    assert.strictEqual(typeof testSupport, 'object', '@ember-joinery/test-support imports')
    assert.true(declaredLayers().includes('joinery'), 'joinery.css is bundled and loaded')

    await a11yAudit()
  })
})
