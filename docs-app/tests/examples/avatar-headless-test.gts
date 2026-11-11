import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AvatarHarness } from '@ember-joinery/test-support'
import AvatarHeadless from 'docs-app/examples/avatar-headless'

module('Example | avatar-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('an image, a broken one with a delayed fallback, and the status yielded', async function (assert) {
    // render() waits for the images, and for the fallback's 600ms delay.
    await render(<template><AvatarHeadless /></template>)
    const [github, broken, shadcn] = AvatarHarness.findAll()
    assert.strictEqual(github!.size, null, 'headless: no size, no styles of its own')
    assert.true(github!.isLoaded || github!.isError)
    assert.strictEqual(
      github!.label,
      github!.isLoaded ? 'GitHub profile picture of NullVoxPopuli' : 'NVP',
    )

    assert.true(broken!.isError, 'a broken URL fails')
    assert.dom(broken!.element).hasAttribute('data-error')
    assert.strictEqual(broken!.fallbackText, 'NVP', 'shown after its delay')

    assert.strictEqual(shadcn!.label, shadcn!.isLoaded ? '@shadcn' : 'CN', 'its own @src')
    await a11yAudit()
  })
})
