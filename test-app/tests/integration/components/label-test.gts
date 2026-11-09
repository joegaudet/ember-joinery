import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { find, render, rerender, triggerEvent } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Label, asLabel, labelAttributes, labelClasses } from '@ember-joinery/ember'
import { LabelHarness } from '@ember-joinery/test-support'

module('Integration | components | label', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a native label with upstream classes and data attributes', async function (assert) {
    await render(
      <template>
        <Label @name="email" for="email">Your email address</Label>
        <input id="email" type="email" />
      </template>,
    )
    const email = new LabelHarness('email')
    assert
      .dom(email.element)
      .hasTagName('label')
      .hasClass('jn-label')
      .hasAttribute('data-slot', 'label')
      .hasAttribute('data-test-jn', 'label')
      .hasAttribute('data-test-jn-name', 'email')
      .hasAttribute('for', 'email')
    assert.strictEqual(email.text, 'Your email address')
    assert.strictEqual(email.control, find('#email'))
    await a11yAudit()
  })

  test('its style sheet sets it in a small, medium line, without Tailwind', async function (assert) {
    await render(
      <template>
        <Label @name="terms" for="terms"><span>✓</span> Accept terms</Label>
        <input id="terms" type="checkbox" />
      </template>,
    )
    const style = getComputedStyle(new LabelHarness('terms').element)
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.alignItems, 'center')
    assert.strictEqual(style.columnGap, '8px', 'gap-2')
    assert.strictEqual(style.fontSize, '14px', 'text-sm')
    assert.strictEqual(style.lineHeight, '14px', 'leading-none')
    assert.strictEqual(style.fontWeight, '500', 'font-medium')
    assert.strictEqual(style.userSelect, 'none', 'select-none')
    assert.strictEqual(style.opacity, '1')
    await a11yAudit()
  })

  test('it dims beside a disabled peer, and inside a disabled group', async function (assert) {
    await render(
      <template>
        <div>
          <input id="off" type="checkbox" class="peer" disabled />
          <Label @name="peer" for="off">Disabled peer</Label>
        </div>
        <div>
          <input id="on" type="checkbox" class="peer" />
          <Label @name="enabled" for="on">Enabled peer</Label>
        </div>
        <div class="group" data-disabled="true">
          <Label @name="group" for="grouped">In a disabled group</Label>
          <input id="grouped" type="checkbox" disabled />
        </div>
      </template>,
    )
    const peer = new LabelHarness('peer')
    assert.true(peer.isControlDisabled)
    assert.strictEqual(getComputedStyle(peer.element).opacity, '0.5', 'peer-disabled:opacity-50')
    assert.strictEqual(
      getComputedStyle(peer.element).cursor,
      'not-allowed',
      'peer-disabled:cursor-not-allowed',
    )
    assert.strictEqual(getComputedStyle(new LabelHarness('enabled').element).opacity, '1')
    const group = getComputedStyle(new LabelHarness('group').element)
    assert.strictEqual(group.opacity, '0.5', 'group-data-[disabled=true]:opacity-50')
    assert.strictEqual(
      group.pointerEvents,
      'none',
      'group-data-[disabled=true]:pointer-events-none',
    )
    await a11yAudit()
  })

  test('a click focuses or toggles its control, and a double click selects no text', async function (assert) {
    const prevented: boolean[] = []
    const record = (event: MouseEvent) => prevented.push(event.defaultPrevented)
    await render(
      <template>
        <div {{on "mousedown" record}}>
          <input id="accept" type="checkbox" />
          <Label @name="accept" for="accept">Accept terms and conditions</Label>
          <Label @name="name" for="name">Name</Label>
          <input id="name" />
        </div>
      </template>,
    )
    const accept = new LabelHarness('accept')
    await accept.click()
    assert.dom('#accept').isChecked()
    await accept.click()
    assert.dom('#accept').isNotChecked()
    await new LabelHarness('name').click()
    assert.dom('#name').isFocused()

    prevented.length = 0
    await triggerEvent(accept.element, 'mousedown', { detail: 2 })
    assert.deepEqual(prevented, [true], 'the second press of a double click selects no text')
    await a11yAudit()
  })

  test('@as and the asLabel modifier render the same classes and attributes', async function (assert) {
    const prevented: boolean[] = []
    const record = (event: MouseEvent) => prevented.push(event.defaultPrevented)
    await render(
      <template>
        <div {{on "mousedown" record}}>
          <Label @name="x" data-case="component">Volume</Label>
          <label data-case="modifier" {{asLabel name="x"}}>Volume</label>
          <Label @as="span" @name="span" id="volume">Volume</Label>
          <span id="by-modifier" {{asLabel name="modified"}}>Volume</span>
          <div role="slider" aria-labelledby="volume" aria-valuenow="5" tabindex="0"></div>
          <div role="slider" aria-labelledby="by-modifier" aria-valuenow="5" tabindex="0"></div>
        </div>
      </template>,
    )
    const component = find('[data-case="component"]')!
    const modified = find('[data-case="modifier"]')!
    assert.deepEqual(rendering(component), rendering(modified))
    assert.deepEqual(rendering(component).classes, labelClasses().split(' ').sort())
    for (const [name, value] of Object.entries(labelAttributes({ name: 'x' }))) {
      assert.strictEqual(component.getAttribute(name), value ?? null, name)
    }
    assert.dom(new LabelHarness('span').element).hasTagName('span').hasClass('jn-label')
    const byModifier = new LabelHarness('modified')
    assert.strictEqual(getComputedStyle(byModifier.element).fontSize, '14px', 'styled as a label')
    await triggerEvent(byModifier.element, 'mousedown', { detail: 2 })
    assert.deepEqual(prevented, [true], 'with the primitive’s double-click behaviour')
    await rerender()
    await a11yAudit()
  })

  test('RTL: it lays out from the right, beside its control', async function (assert) {
    await render(
      <template>
        <div class="row" style="display: flex; gap: 8px">
          <input id="ltr" type="checkbox" />
          <Label @name="ltr" for="ltr">Accept terms and conditions</Label>
        </div>
        <DirectionProvider @dir="rtl">
          <div style="display: flex; gap: 8px">
            <input id="rtl" type="checkbox" />
            <Label @name="rtl" for="rtl">قبول الشروط والأحكام</Label>
          </div>
        </DirectionProvider>
      </template>,
    )
    const ltr = new LabelHarness('ltr')
    const rtl = new LabelHarness('rtl')
    assert.ok(
      ltr.element.getBoundingClientRect().left > ltr.control!.getBoundingClientRect().left,
      'left to right, the label follows its checkbox on the right',
    )
    assert.ok(
      rtl.element.getBoundingClientRect().right < rtl.control!.getBoundingClientRect().left,
      'right to left, it is on the left',
    )
    assert.strictEqual(getComputedStyle(rtl.element).direction, 'rtl')
    await a11yAudit()
  })
})
