import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { IconHarness, SwitchHarness } from '@ember-joinery/test-support'
import SwitchThumb from 'docs-app/examples/switch-thumb'

module('Example | switch-thumb', function (hooks) {
  setupRenderingTest(hooks)

  test('the thumb shows a sun, and a moon once it is on', async function (assert) {
    await render(<template><SwitchThumb /></template>)
    const darkMode = new SwitchHarness()
    const icon = () => darkMode.find(IconHarness)
    const drawing = () => icon().element.querySelector('path')!.getAttribute('d')

    assert.strictEqual(darkMode.label, 'Dark mode')
    assert.ok(darkMode.thumb!.contains(icon().element), 'the icon is inside the thumb')
    assert.true(icon().isDecorative)
    const sun = drawing()
    assert.strictEqual(getComputedStyle(icon().element).width, '12px', 'size-3')

    await darkMode.toggle()
    assert.true(darkMode.isChecked)
    assert.notStrictEqual(drawing(), sun, 'a different icon')
    assert.strictEqual(drawing(), 'M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z', "lucide's moon")
    await a11yAudit()
  })
})
