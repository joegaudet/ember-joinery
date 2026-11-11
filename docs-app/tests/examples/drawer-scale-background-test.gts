import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DrawerHarness } from '@ember-joinery/test-support'
import DrawerScaleBackground from 'docs-app/examples/drawer-scale-background'

module('Example | drawer-scale-background', function (hooks) {
  setupRenderingTest(hooks)

  test('the page behind scales back while it is open', async function (assert) {
    await render(<template><DrawerScaleBackground /></template>)
    const page = document.querySelector<HTMLElement>('[data-vaul-drawer-wrapper]')!
    const drawer = new DrawerHarness()
    const body = document.body.style.backgroundColor
    await drawer.open()
    const scale = Number(/^scale\(([\d.]+)\)/.exec(page.style.transform)?.[1])
    assert.ok(scale > 0.9 && scale < 1, 'scaled back')
    assert.strictEqual(page.style.borderRadius, '8px', 'with rounded corners')
    assert.strictEqual(document.body.style.backgroundColor, body, 'and the body left alone')
    await a11yAudit()

    await drawer.pressEscape()
    assert.strictEqual(page.style.transform, '', 'as it was, once it closes')
    await a11yAudit()
  })
})
