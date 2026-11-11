import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import BodyClassLockScroll from 'docs-app/examples/body-class-lock-scroll'

class ScrollLockHarness extends Harness {
  static component = 'scroll-lock'

  get status() {
    return this.part('status').textContent!.replace(/\s+/g, ' ').trim()
  }

  async toggle() {
    await click(this.part('toggle'))
  }
}

module('Example | body-class-lock-scroll', function (hooks) {
  setupRenderingTest(hooks)

  test('the class is on <body> while the lock is', async function (assert) {
    await render(<template><BodyClassLockScroll /></template>)
    const lock = new ScrollLockHarness()
    assert.dom(document.body).doesNotHaveClass('scroll-locked')

    await lock.toggle()
    assert.dom(document.body).hasClass('scroll-locked')
    assert.strictEqual(getComputedStyle(document.body).overflow, 'hidden')
    assert.strictEqual(lock.status, "The page can't scroll.")

    await lock.toggle()
    assert.dom(document.body).doesNotHaveClass('scroll-locked')
    assert.strictEqual(lock.status, 'The page scrolls.')
    await a11yAudit()
  })
})
