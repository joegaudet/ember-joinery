import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Command } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Icon, Kbd, KbdGroup } from '@ember-joinery/ember'
import {
  ButtonHarness,
  IconHarness,
  KbdGroupHarness,
  KbdHarness,
} from '@ember-joinery/test-support'

/**
 * The audit, but for the contrast of the keys' own text: upstream's Kbd draws
 * `--muted-foreground` on `--muted`, 4.34:1 in the default theme, under the 4.5:1 WCAG AA asks
 * of its 12px text (the Kbd page's Accessibility notes say how an app can darken it). Everything
 * around the keys is audited.
 */
const BUT_THE_KEYS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="kbd"]']],
}

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/** What a CSS colour (`var(--muted)`) computes to here, to compare with a rendered one. */
function color(value: string, property: 'color' | 'backgroundColor' = 'backgroundColor'): string {
  const probe = document.createElement('div')
  probe.style[property] = value
  getRootElement().append(probe)
  const computed = getComputedStyle(probe)[property]
  probe.remove()
  return computed
}

module('Integration | components | kbd', function (hooks) {
  setupRenderingTest(hooks)

  test('Kbd and KbdGroup render kbd elements with upstream classes and data attributes', async function (assert) {
    await render(
      <template>
        <KbdGroup @name="bold">
          <Kbd @name="ctrl">Ctrl</Kbd>
          <span>+</span>
          <Kbd>B</Kbd>
        </KbdGroup>
      </template>,
    )
    const ctrl = new KbdHarness('ctrl')
    assert
      .dom(ctrl.element)
      .hasTagName('kbd')
      .hasClass('jn-kbd')
      .hasAttribute('data-slot', 'kbd')
      .hasAttribute('data-test-jn', 'kbd')
    assert.strictEqual(ctrl.label, 'Ctrl')

    const bold = new KbdGroupHarness('bold')
    assert
      .dom(bold.element)
      .hasTagName('kbd', 'a <kbd> of <kbd>s: one input of several keys')
      .hasClass('jn-kbd-group')
      .hasAttribute('data-slot', 'kbd-group')
      .hasAttribute('data-test-jn', 'kbd-group')
    assert.deepEqual(bold.keys, ['Ctrl', 'B'])
    assert.strictEqual(bold.label, 'Ctrl + B')
    assert.strictEqual(bold.kbds.length, 2)
    await a11yAudit(BUT_THE_KEYS)
  })

  test('its style sheet sizes and colours it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Kbd @name="key">K</Kbd>
        <KbdGroup @name="group">
          <Kbd @name="word">Ctrl</Kbd>
          <Kbd @name="icon"><Icon @icon={{Command}} /></Kbd>
        </KbdGroup>
      </template>,
    )
    const key = getComputedStyle(new KbdHarness('key').element)
    assert.strictEqual(key.display, 'inline-flex')
    assert.strictEqual(key.height, '20px', 'h-5')
    assert.strictEqual(key.minWidth, '20px', 'min-w-5')
    assert.strictEqual(key.width, '20px', 'w-fit, no narrower than min-w-5')
    assert.strictEqual(px(key.paddingLeft), 4, 'px-1')
    assert.strictEqual(key.fontSize, '12px', 'text-xs')
    assert.strictEqual(key.fontWeight, '500', 'font-medium')
    assert.ok(/ui-sans-serif|system-ui|sans-serif/.test(key.fontFamily), 'font-sans')
    assert.strictEqual(key.fontStyle, 'normal')
    assert.strictEqual(key.borderTopLeftRadius, '6px', "rounded-sm: the theme's --radius × 0.6")
    assert.strictEqual(key.backgroundColor, color('var(--muted)'), 'bg-muted')
    assert.strictEqual(key.color, color('var(--muted-foreground)', 'color'))
    assert.strictEqual(key.pointerEvents, 'none')
    assert.strictEqual(key.userSelect, 'none')
    assert.ok(px(getComputedStyle(new KbdHarness('word').element).width) > 20, 'w-fit grows')

    const icon = new KbdHarness('icon').find(IconHarness).element
    assert.strictEqual(
      getComputedStyle(icon).width,
      '12px',
      'an svg without a size- class is size-3',
    )

    const group = getComputedStyle(new KbdGroupHarness('group').element)
    assert.strictEqual(group.display, 'inline-flex')
    assert.strictEqual(group.alignItems, 'center')
    assert.strictEqual(group.columnGap, '4px', 'gap-1')
    await a11yAudit(BUT_THE_KEYS)
  })

  test('it takes attributes, and @as renders another tag', async function (assert) {
    await render(
      <template>
        <Kbd @name="mine" class="mine" title="Escape">Esc</Kbd>
        <Kbd @name="span" @as="span">Tab</Kbd>
        <KbdGroup @name="group" @as="span"><Kbd>A</Kbd></KbdGroup>
      </template>,
    )
    assert
      .dom(new KbdHarness('mine').element)
      .hasClass('mine')
      .hasClass('jn-kbd')
      .hasAttribute('title', 'Escape')
    assert.dom(new KbdHarness('span').element).hasTagName('span').hasClass('jn-kbd')
    assert.dom(new KbdGroupHarness('group').element).hasTagName('span').hasClass('jn-kbd-group')
    await a11yAudit(BUT_THE_KEYS)
  })

  test('keyboard: keys are shown, not used, so they take no focus or presses', async function (assert) {
    await render(
      <template>
        <Kbd @name="key">K</Kbd>
      </template>,
    )
    const key = new KbdHarness('key').element
    assert.strictEqual(key.tabIndex, -1, 'not in the tab order')
    assert.strictEqual(
      getComputedStyle(key).pointerEvents,
      'none',
      'a press goes to what is under it',
    )
    await a11yAudit(BUT_THE_KEYS)
  })

  test('in a Button, it takes an icon’s side, and right to left the inline end is the left', async function (assert) {
    await render(
      <template>
        <Button @name="ltr" @variant="outline">Accept
          <Kbd data-icon="inline-end">⏎</Kbd></Button>
        <DirectionProvider @dir="rtl">
          <Button @name="rtl" @variant="outline">قبول
            <Kbd data-icon="inline-end">⏎</Kbd></Button>
          <KbdGroup @name="rtl-group"><Kbd>Ctrl</Kbd><Kbd>B</Kbd></KbdGroup>
        </DirectionProvider>
      </template>,
    )
    for (const [name, onTheRight] of [
      ['ltr', true],
      ['rtl', false],
    ] as const) {
      const button = new ButtonHarness(name)
      const box = button.element.getBoundingClientRect()
      const kbd = button.find(KbdHarness).element.getBoundingClientRect()
      assert.strictEqual(kbd.left > box.left + box.width / 2, onTheRight, `${name}: the key's side`)
    }
    // has-data-[icon=inline-end]:pe-2 puts the narrower padding beside the key.
    assert.strictEqual(px(getComputedStyle(new ButtonHarness('ltr').element).paddingRight), 8)
    assert.strictEqual(px(getComputedStyle(new ButtonHarness('rtl').element).paddingLeft), 8)

    const [ctrl, b] = new KbdGroupHarness('rtl-group').kbds
    assert.ok(
      ctrl!.element.getBoundingClientRect().left > b!.element.getBoundingClientRect().left,
      'right to left, the first key is on the right',
    )
    await a11yAudit(BUT_THE_KEYS)
  })
})
