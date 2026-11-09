import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Button, DirectionProvider, getDirection, isRTL } from '@ember-joinery/ember'
import { ButtonHarness } from '@ember-joinery/test-support'

module('Integration | components | direction', function (hooks) {
  setupRenderingTest(hooks)

  test("shadcn's DirectionProvider sets the direction inside it, by @direction or @dir", async function (assert) {
    await render(
      <template>
        <DirectionProvider @direction="rtl">
          <Button @name="inside">زر</Button>
        </DirectionProvider>
        <DirectionProvider @dir="rtl" @direction="ltr">
          <Button @name="wins">Button</Button>
        </DirectionProvider>
        <Button @name="outside">Button</Button>
      </template>,
    )
    const inside = new ButtonHarness('inside').element
    assert.strictEqual(getDirection(inside), 'rtl', "getDirection is upstream's useDirection")
    assert.true(isRTL(inside))
    assert.strictEqual(getComputedStyle(inside).direction, 'rtl')
    assert.strictEqual(getDirection(new ButtonHarness('wins').element), 'ltr', '@direction wins')
    assert.strictEqual(getDirection(new ButtonHarness('outside').element), 'ltr')
    assert
      .dom(inside.parentElement!)
      .hasAttribute('data-slot', 'direction-provider')
      .hasAttribute('dir', 'rtl')
    assert.strictEqual(getComputedStyle(inside.parentElement!).display, 'contents', 'no box')
    await a11yAudit()
  })
})
