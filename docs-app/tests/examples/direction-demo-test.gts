import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { getDirection } from '@ember-joinery/ember'
import { ButtonHarness } from '@ember-joinery/test-support'
import DirectionDemo from 'docs-app/examples/direction-demo'

module('Example | direction-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('everything inside the provider lays out right to left', async function (assert) {
    await render(<template><DirectionDemo /></template>)
    const [signUp, login, google] = ButtonHarness.findAll()
    assert.strictEqual(signUp!.label, 'إنشاء حساب')
    assert.strictEqual(signUp!.variant, 'link')
    assert.strictEqual(login!.label, 'تسجيل الدخول')
    assert.strictEqual(google!.variant, 'outline')
    assert.strictEqual(getDirection(login!.element), 'rtl', 'read where it matters')

    const header = signUp!.element.parentElement!
    const title = header.firstElementChild as HTMLElement
    assert.true(
      signUp!.element.offsetLeft < title.offsetLeft,
      'ms-auto puts the link at the inline end: the left',
    )
    await a11yAudit()
  })
})
