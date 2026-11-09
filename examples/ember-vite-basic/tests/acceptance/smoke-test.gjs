import { module, test } from 'qunit'
import { visit } from '@ember/test-helpers'
import { setupApplicationTest } from 'ember-qunit'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import * as ember from '@ember-joinery/ember'
import * as testSupport from '@ember-joinery/test-support'
import { ButtonHarness, IconHarness } from '@ember-joinery/test-support'

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

  test('Joinery loads in a Vite (Embroider) app', async function (assert) {
    await visit('/')

    assert.dom('h1').hasText('Joinery in a Vite app')
    assert.strictEqual(typeof ember, 'object', '@ember-joinery/ember imports')
    assert.strictEqual(typeof testSupport, 'object', '@ember-joinery/test-support imports')
    assert.true(declaredLayers().includes('joinery'), 'joinery.css is loaded')

    await a11yAudit()
  })

  test('a Joinery Button renders and works here, styled by joinery.css', async function (assert) {
    await visit('/')
    const save = new ButtonHarness('save')
    assert.dom(save.element).hasTagName('button').hasClass('jn-button')
    assert.strictEqual(save.variant, 'outline')
    assert.strictEqual(getComputedStyle(save.element).height, '32px', "Nova's h-8")
    assert.strictEqual(
      getComputedStyle(save.element).borderTopLeftRadius,
      '10px',
      "tokens.css's --radius",
    )
    let clicked = false
    save.element.addEventListener('click', () => (clicked = true), { once: true })
    await save.click()
    assert.true(clicked)

    const up = new ButtonHarness('up')
    assert.strictEqual(up.label, 'Back to top')
    assert.true(up.find(IconHarness).isDecorative, 'its lucide icon')
    assert.strictEqual(up.find(IconHarness).element.namespaceURI, 'http://www.w3.org/2000/svg')
    await a11yAudit()
  })
})
