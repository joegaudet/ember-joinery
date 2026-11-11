import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { VisuallyHidden, visuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import { Harness } from '@ember-joinery/test-support'

/** Whether an element is hidden from sight: clipped to a 1px box taken out of the flow. */
function isVisuallyHidden(element: Element): boolean {
  const style = getComputedStyle(element)
  const box = element.getBoundingClientRect()
  return (
    style.position === 'absolute' &&
    style.overflow === 'hidden' &&
    style.clip === 'rect(0px, 0px, 0px, 0px)' &&
    box.width <= 1 &&
    box.height <= 1
  )
}

class CloseButton extends Harness {
  static override component = 'close-button'
}

module('Integration | primitives | visually-hidden', function (hooks) {
  setupRenderingTest(hooks)

  test('VisuallyHidden hides its content from sight, not from screen readers', async function (assert) {
    await render(
      <template>
        <button type="button" id="close">
          <span aria-hidden="true">×</span>
          <VisuallyHidden class="label">Close</VisuallyHidden>
        </button>
      </template>,
    )
    const label = find('[data-slot="visually-hidden"]')!
    assert.dom(label).hasTagName('span').hasClass('label').hasText('Close')
    assert.true(isVisuallyHidden(label))
    assert.dom('#close').hasText('× Close')
    await a11yAudit() // the button has the hidden label as its accessible name
  })

  test('@as renders another tag', async function (assert) {
    await render(
      <template>
        <VisuallyHidden @as="h2">Settings</VisuallyHidden>
      </template>,
    )
    assert.dom('h2').hasText('Settings')
    assert.true(isVisuallyHidden(find('h2')!))
    await a11yAudit()
  })

  test('the modifier hides any element, and puts its styles back', async function (assert) {
    class State {
      @tracked hidden = true
    }
    const state = new State()
    await render(
      <template>
        <label for="q" style="color: red; margin: 4px" {{(if state.hidden visuallyHidden)}}>
          Search
        </label>
        <input id="q" type="search" />
      </template>,
    )
    const hidden = find('label') as HTMLElement
    assert.true(isVisuallyHidden(hidden))
    assert.strictEqual(hidden.style.color, 'red', 'its other styles stay')
    assert.strictEqual(hidden.style.margin, '-1px')
    await a11yAudit()

    state.hidden = false
    await settled()
    assert.strictEqual(find('label'), hidden, 'the same element')
    assert.false(isVisuallyHidden(hidden))
    assert.strictEqual(hidden.style.margin, '4px', 'the style it replaced is back')
    assert.strictEqual(hidden.style.position, '', 'and the ones it added are gone')
  })

  test('parts inside it still belong to the component around it', async function (assert) {
    await render(
      <template>
        <button type="button" data-test-jn="close-button">
          <VisuallyHidden data-test-jn-part="label">Close</VisuallyHidden>
        </button>
      </template>,
    )
    assert.dom(new CloseButton().part('label')).hasText('Close')
    await a11yAudit()
  })
})
