import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CardHarness, child } from '@ember-joinery/test-support'
import CardEdgeToEdge from 'docs-app/examples/card-edge-to-edge'

/** The terms card: a page object, with its footer's buttons declared by position. */
class TermsCard extends CardHarness {
  @child(ButtonHarness, { index: 0 }) declare decline: ButtonHarness
  @child(ButtonHarness, { index: 1 }) declare accept: ButtonHarness

  /** The terms, the content's scrolling region. */
  get terms(): HTMLElement {
    return this.content.firstElementChild as HTMLElement
  }
}

module('Example | card-edge-to-edge', function (hooks) {
  setupRenderingTest(hooks)

  test('the terms run edge to edge, and scroll, above the footer', async function (assert) {
    await render(<template><CardEdgeToEdge /></template>)
    const card = new TermsCard()
    assert.strictEqual(card.title, 'Terms of Service')

    const terms = card.terms
    assert.strictEqual(terms.offsetWidth, card.element.clientWidth, 'as wide as the card')
    assert.strictEqual(getComputedStyle(terms).paddingLeft, '16px', 'aligned with the inset')
    assert.strictEqual(getComputedStyle(terms).overflowY, 'scroll')
    assert.ok(terms.scrollHeight > terms.clientHeight, 'it scrolls')
    assert.strictEqual(terms.tabIndex, 0, 'a keyboard can scroll it')
    assert.strictEqual(
      getComputedStyle(card.content).marginBottom,
      '-16px',
      'no section gap before the footer',
    )

    assert.strictEqual(card.decline.label, 'Decline')
    assert.strictEqual(card.decline.variant, 'outline')
    assert.strictEqual(card.accept.label, 'Accept')
    assert.strictEqual(card.accept.variant, 'default')
    assert.strictEqual(getComputedStyle(card.footer).justifyContent, 'flex-end')
    await a11yAudit()
  })
})
