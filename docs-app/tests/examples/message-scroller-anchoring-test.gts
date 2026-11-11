import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  EmptyHarness,
  MessageScrollerHarness,
  ToggleGroupHarness,
} from '@ember-joinery/test-support'
import MessageScrollerAnchoring from 'docs-app/examples/message-scroller-anchoring'

/** Two positions within a pixel: the test container's scale rounds a scroll to its pixels. */
const near = (actual: number, expected: number) => Math.abs(actual - expected) <= 1

/** The button with this accessible name. */
const button = (label: string) => ButtonHarness.findAll().find(button => button.label === label)!

module('Example | message-scroller-anchoring', function (hooks) {
  setupRenderingTest(hooks)

  test('the selected role anchors each new turn near the top', async function (assert) {
    await render(<template><MessageScrollerAnchoring /></template>)
    assert.true(new EmptyHarness().exists)
    const roles = new ToggleGroupHarness()
    assert.deepEqual(roles.value, ['user'])

    for (let i = 0; i < 4; i++) await button('Send Message').click()
    const chat = new MessageScrollerHarness()
    await chat.settle()
    assert.deepEqual(chat.messageIds, [
      'anchor-1-user',
      'anchor-1-assistant',
      'anchor-2-user',
      'anchor-2-assistant',
    ])
    assert.deepEqual(chat.anchorIds, ['anchor-1-user', 'anchor-2-user'])
    const padding = parseFloat(getComputedStyle(chat.content).paddingTop)
    assert.true(near(chat.itemTop('anchor-2-user'), padding + 64))

    await roles.toggle('assistant')
    assert.true(new EmptyHarness().exists, 'switching the role starts over')
    for (let i = 0; i < 4; i++) await button('Send Message').click()
    await chat.settle()
    assert.deepEqual(chat.anchorIds, ['anchor-1-assistant', 'anchor-2-assistant'])

    await button('Reset anchored turns').click()
    assert.true(new EmptyHarness().exists)
    assert.true(button('Reset anchored turns').isDisabled)
    await a11yAudit()
  })
})
