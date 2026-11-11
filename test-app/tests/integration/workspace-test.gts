import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import * as primitives from '@ember-joinery/primitives'
import * as ember from '@ember-joinery/ember'
import * as testSupport from '@ember-joinery/test-support'

/** Every cascade layer the page's style sheets declare. */
function declaredLayers(): string[] {
  const layers: string[] = []
  const visit = (rules: CSSRuleList) => {
    for (const rule of Array.from(rules)) {
      if (rule instanceof CSSLayerStatementRule) layers.push(...rule.nameList)
      else if (rule instanceof CSSLayerBlockRule) {
        layers.push(rule.name)
        visit(rule.cssRules)
      }
    }
  }
  for (const sheet of Array.from(document.styleSheets)) visit(sheet.cssRules)
  return layers
}

module('Integration | workspace', function (hooks) {
  setupRenderingTest(hooks)

  test('the packages build and load', function (assert) {
    assert.strictEqual(typeof primitives, 'object', '@ember-joinery/primitives')
    assert.strictEqual(typeof ember, 'object', '@ember-joinery/ember')
    assert.strictEqual(typeof testSupport, 'object', '@ember-joinery/test-support')
  })

  test('joinery.css is built and loaded, declaring the joinery layer', function (assert) {
    assert.true(declaredLayers().includes('joinery'), 'the joinery cascade layer exists')
  })

  test('the anchor-fallback flag reaches the page when the build sets it', function (assert) {
    const forced = import.meta.env.JOINERY_ANCHOR_FALLBACK === '1'
    assert.strictEqual(
      globalThis.JOINERY_ANCHOR_FALLBACK === true,
      forced,
      forced ? 'CSS anchor positioning is forced off' : 'CSS anchor positioning is not forced off',
    )
  })

  test('a rendered template passes the axe audit', async function (assert) {
    await render(
      <template>
        <main>
          <h1>Joinery</h1>
        </main>
      </template>,
    )
    assert.dom('h1').hasText('Joinery')
    await a11yAudit()
  })
})
