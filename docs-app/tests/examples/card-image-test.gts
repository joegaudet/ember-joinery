import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness, ButtonHarness, CardHarness, child } from '@ember-joinery/test-support'
import CardImage from 'docs-app/examples/card-image'

/** The event card: a page object, with its badge and button declared. */
class EventCard extends CardHarness {
  @child(BadgeHarness) declare badge: BadgeHarness
  @child(ButtonHarness) declare view: ButtonHarness

  /** The cover image. */
  get cover(): HTMLImageElement {
    return this.element.querySelector('img')!
  }
}

module('Example | card-image', function (hooks) {
  setupRenderingTest(hooks)

  test('a cover image above the header, with a badge in its action', async function (assert) {
    await render(<template><CardImage /></template>)
    const card = new EventCard()
    assert.strictEqual(card.title, 'Design systems meetup')
    assert.strictEqual(
      card.description,
      'A practical talk on component APIs, accessibility, and shipping faster.',
    )

    const cover = card.cover
    assert.dom(cover).hasAttribute('alt', 'Event cover')
    assert.strictEqual(getComputedStyle(card.element).paddingTop, '0px', 'pt-0')
    assert.strictEqual(cover.offsetTop, 0, 'at the top of the card')
    assert.strictEqual(cover.offsetWidth, card.element.clientWidth, 'as wide as the card')
    assert.strictEqual(cover.offsetHeight, Math.round((cover.offsetWidth * 9) / 16), '16:9')
    assert.ok(cover.offsetTop < card.header.offsetTop, 'before the header')

    assert.true(card.action.contains(card.badge.element), "the badge is the header's action")
    assert.strictEqual(card.badge.text, 'Featured')
    assert.strictEqual(card.badge.variant, 'secondary')

    assert.strictEqual(card.view.label, 'View Event')
    assert.strictEqual(card.view.element.offsetWidth, card.footer.clientWidth - 32, 'w-full')
    await a11yAudit()
  })
})
