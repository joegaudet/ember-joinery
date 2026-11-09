/* global ScrollToOptions -- a DOM type, which ESLint's browser globals don't list */
import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ZoetropeHarness } from '@ember-joinery/test-support'
import ZoetropeInstantScroll from 'docs-app/examples/zoetrope-instant-scroll'

module('Example | zoetrope-instant-scroll', function (hooks) {
  setupRenderingTest(hooks)

  test('a click scrolls at once', async function (assert) {
    await render(<template><ZoetropeInstantScroll /></template>)
    const zoetrope = new ZoetropeHarness()
    const track = zoetrope.scroller
    const behaviors: string[] = []
    const scrollBy = track.scrollBy.bind(track)
    track.scrollBy = ((options: ScrollToOptions) => {
      behaviors.push(String(options.behavior))
      scrollBy(options)
      // Instant: it is there before the click is over.
      assert.true(track.scrollLeft > 0, 'already scrolled')
    }) as typeof track.scrollBy

    await click(zoetrope.rightButton!)
    assert.deepEqual(behaviors, ['instant'])
    await a11yAudit()
  })
})
