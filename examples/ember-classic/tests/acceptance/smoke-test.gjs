import { module, test } from 'qunit'
import { click, visit } from '@ember/test-helpers'
import { setupApplicationTest } from 'ember-qunit'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import * as ember from '@ember-joinery/ember'
import * as testSupport from '@ember-joinery/test-support'
import {
  ButtonHarness,
  Harness,
  IconHarness,
  KeyComboHarness,
  isInTopLayer,
  placementOf,
  pressEscape,
} from '@ember-joinery/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'

/** The app's disclosure, built on the primitives. */
class DisclosureHarness extends Harness {
  static component = 'disclosure'

  get trigger() {
    return this.part('trigger')
  }

  get content() {
    return this.queryPart('content')
  }

  async toggle() {
    await click(this.trigger)
  }
}

/** The app's popover, on the layering primitives. */
class TipHarness extends Harness {
  static component = 'tip'

  get trigger() {
    return this.part('trigger')
  }

  get content() {
    return this.queryPart('content')
  }

  async open() {
    await click(this.trigger)
  }
}

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

  test('the primitives work in a classic ember-cli build', async function (assert) {
    await visit('/')
    assert.deepEqual(new KeyComboHarness('search').keys, ['Ctrl', 'K'])

    const disclosure = new DisclosureHarness()
    assert.dom(disclosure.trigger).hasTagName('button').hasAria('expanded', 'false')
    assert.strictEqual(disclosure.content, null)

    await disclosure.toggle()
    assert.dom(disclosure.trigger).hasAria('expanded', 'true')
    assert.dom(disclosure.content).hasText('The primitives work here too.')
    assert.dom(disclosure.trigger).hasAria('controls', disclosure.content.id)

    await disclosure.toggle()
    assert.strictEqual(disclosure.content, null, 'Presence let it go')
    await a11yAudit()
  })

  test('the layering primitives work in a classic ember-cli build', async function (assert) {
    await visit('/')
    const tip = new TipHarness()
    await tip.open()
    assert.true(isInTopLayer(tip.content), 'in the top layer')
    assert.strictEqual(placementOf(tip.content).side, 'bottom', 'anchored below its button')

    await pressEscape()
    assert.strictEqual(tip.content, null, 'Escape closed it')
    await a11yAudit()
  })

  test('a Joinery Button renders and works in a classic build, styled by joinery.css', async function (assert) {
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

  module('an add-on', function (hooks) {
    const clipboard = setupClipboard(hooks)

    test('a Code Block from @ember-joinery/code-block, with Shiki loaded on demand', async function (assert) {
      await visit('/')
      const block = new CodeBlockHarness('install')
      assert.strictEqual(block.code, 'pnpm add @ember-joinery/code-block')
      assert.true(block.isHighlighted, 'ember-auto-import split out Shiki and the bash grammar')
      assert.strictEqual(getComputedStyle(block.element).borderTopLeftRadius, '10px')
      await block.copy()
      assert.strictEqual(clipboard.text, 'pnpm add @ember-joinery/code-block')
      await a11yAudit()
    })
  })
})
