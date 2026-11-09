import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Bookmark, Italic } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Icon,
  Toggle,
  asToggle,
  toggleAttributes,
  toggleClasses,
  type ToggleSize,
  type ToggleVariant,
} from '@ember-joinery/ember'
import { ToggleHarness } from '@ember-joinery/test-support'

const VARIANTS: ToggleVariant[] = ['default', 'outline']
const SIZES: ToggleSize[] = ['default', 'sm', 'lg']

const px = (value: string) => Number.parseFloat(value)

/** A colour, resolved by the browser, to compare two. */
function colour(value: string): string {
  const probe = document.createElement('span')
  probe.style.backgroundColor = value
  document.body.append(probe)
  const resolved = getComputedStyle(probe).backgroundColor
  probe.remove()
  return resolved
}

/** An element's classes and attributes (but the test's own `data-case`), to compare two. */
function rendering(element: Element): { classes: string[]; attributes: Record<string, string> } {
  const attributes: Record<string, string> = {}
  for (const { name, value } of element.attributes) {
    if (name !== 'class' && name !== 'data-case') attributes[name] = value
  }
  return { classes: [...element.classList].sort(), attributes }
}

class State {
  @tracked pressed = false
  set = (pressed: boolean) => (this.pressed = pressed)
}

module('Integration | components | toggle', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a toggle button with upstream classes and data attributes', async function (assert) {
    await render(
      <template>
        <Toggle aria-label="Toggle italic">Italic</Toggle>
      </template>,
    )
    const toggle = new ToggleHarness()
    assert.dom(toggle.element).hasTagName('button').hasAttribute('type', 'button')
    assert
      .dom(toggle.element)
      .hasClass('jn-toggle')
      .hasClass('group/toggle')
      .hasClass('jn-toggle-variant-default')
      .hasClass('jn-toggle-size-default')
      .hasAttribute('data-slot', 'toggle')
      .hasAttribute('data-variant', 'default')
      .hasAttribute('data-size', 'default')
      .hasAttribute('aria-pressed', 'false')
      .hasAttribute('data-state', 'off')
    assert.strictEqual(toggle.variant, 'default')
    assert.strictEqual(toggle.size, 'default')
    assert.strictEqual(toggle.label, 'Toggle italic')
    await a11yAudit()
  })

  test('every variant and size renders its classes and data attributes', async function (assert) {
    await render(
      <template>
        {{#each VARIANTS as |variant|}}
          {{#each SIZES as |size|}}
            <Toggle
              @variant={{variant}}
              @size={{size}}
              @name="{{variant}}-{{size}}"
            >{{size}}</Toggle>
          {{/each}}
        {{/each}}
      </template>,
    )
    for (const variant of VARIANTS) {
      for (const size of SIZES) {
        const toggle = new ToggleHarness(`${variant}-${size}`)
        assert.strictEqual(toggle.variant, variant)
        assert.strictEqual(toggle.size, size)
        assert
          .dom(toggle.element)
          .hasClass(`jn-toggle-variant-${variant}`)
          .hasClass(`jn-toggle-size-${size}`)
      }
    }
    await a11yAudit()
  })

  test('its style sheet sizes and colours it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Toggle @name="default">Default</Toggle>
        <Toggle @name="outline" @variant="outline">Outline</Toggle>
        <Toggle @name="sm" @size="sm" @variant="outline">Small<Icon @icon={{Italic}} /></Toggle>
        <Toggle @name="lg" @size="lg" @variant="outline">Large</Toggle>
        <Toggle @name="icon" aria-label="Bookmark"><Icon @icon={{Bookmark}} /></Toggle>
      </template>,
    )
    const style = (name: string) => getComputedStyle(new ToggleHarness(name).element)
    assert.strictEqual(style('default').display, 'inline-flex')
    assert.strictEqual(style('default').height, '32px', 'h-8')
    assert.strictEqual(style('default').minWidth, '32px', 'min-w-8')
    assert.strictEqual(style('default').paddingLeft, '10px', 'px-2.5')
    assert.strictEqual(style('default').fontSize, '14px', 'text-sm')
    assert.strictEqual(style('default').fontWeight, '500', 'font-medium')
    assert.strictEqual(style('default').borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(style('default').backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-transparent')
    assert.strictEqual(style('default').borderTopWidth, '0px')
    assert.strictEqual(style('outline').borderTopWidth, '1px', 'border')
    assert.strictEqual(style('outline').borderTopColor, colour('var(--input)'), 'border-input')
    assert.strictEqual(style('sm').height, '28px', 'h-7')
    assert.strictEqual(style('sm').fontSize, '12.8px', 'text-[0.8rem]')
    assert.strictEqual(
      style('sm').borderTopLeftRadius,
      '8px',
      'rounded-[min(var(--radius-md),12px)]',
    )
    assert.strictEqual(style('lg').height, '36px', 'h-9')
    const small = new ToggleHarness('sm').element.querySelector('svg')!
    assert.strictEqual(getComputedStyle(small).width, '14px', 'an sm icon is size-3.5')
    const icon = new ToggleHarness('icon').element.querySelector('svg')!
    assert.strictEqual(getComputedStyle(icon).width, '16px', 'an icon is size-4')
    assert.strictEqual(style('icon').width, '36px', 'px-2.5 either side of a size-4 icon')
    await a11yAudit()
  })

  test('pressed, it takes the muted background', async function (assert) {
    await render(
      <template>
        {{! The background eases in (transition-all); read where it ends. }}
        <style>
          [data-slot="toggle"] {
            transition: none !important;
          }
        </style>
        <Toggle @name="on" @defaultPressed={{true}}>On</Toggle>
        <Toggle @name="off">Off</Toggle>
      </template>,
    )
    const on = new ToggleHarness('on')
    assert.true(on.isPressed)
    assert.strictEqual(on.state, 'on')
    assert.strictEqual(getComputedStyle(on.element).backgroundColor, colour('var(--muted)'))
    const off = new ToggleHarness('off')
    await off.toggle()
    assert.true(off.isPressed)
    assert.strictEqual(getComputedStyle(off.element).backgroundColor, colour('var(--muted)'))
    await a11yAudit()
  })

  test('controlled: @pressed and @onPressedChange', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Toggle @pressed={{state.pressed}} @onPressedChange={{state.set}}>Bold</Toggle>
      </template>,
    )
    const bold = new ToggleHarness()
    await bold.toggle()
    assert.true(state.pressed)
    state.pressed = false
    await settled()
    assert.false(bold.isPressed)
    await a11yAudit()
  })

  test('disabled: dimmed, and a press does nothing', async function (assert) {
    await render(
      <template>
        <Toggle @disabled={{true}}>Disabled</Toggle>
      </template>,
    )
    const toggle = new ToggleHarness()
    assert.true(toggle.isDisabled)
    assert.strictEqual(getComputedStyle(toggle.element).opacity, '0.5', 'disabled:opacity-50')
    await toggle.toggle().catch(() => undefined)
    assert.false(toggle.isPressed)
    await a11yAudit()
  })

  test('keyboard: a native button in the tab order', async function (assert) {
    await render(
      <template>
        <Toggle>Bold</Toggle>
      </template>,
    )
    const toggle = new ToggleHarness()
    assert.strictEqual(toggle.element.tabIndex, 0)
    await toggle.focus()
    assert.true(toggle.isFocused)
    await a11yAudit()
  })

  test('@as renders another tag with the same classes and attributes', async function (assert) {
    await render(
      <template>
        <Toggle @as="span" @variant="outline" role="button" tabindex="0">Span</Toggle>
      </template>,
    )
    const toggle = new ToggleHarness()
    assert.dom(toggle.element).hasTagName('span').hasClass('jn-toggle-variant-outline')
    await toggle.toggle()
    assert.true(toggle.isPressed)
    await a11yAudit()
  })

  test('the asToggle modifier makes your own element a toggle, with the same look', async function (assert) {
    const state = new State()
    await render(
      <template>
        <button
          type="button"
          data-case="modifier"
          {{asToggle
            pressed=state.pressed
            onPressedChange=state.set
            variant="outline"
            size="sm"
            name="own"
          }}
        >Own</button>
        <Toggle
          @variant="outline"
          @size="sm"
          @name="own-component"
          data-case="component"
        >Own</Toggle>
      </template>,
    )
    const own = new ToggleHarness('own')
    assert.strictEqual(own.variant, 'outline')
    assert.strictEqual(own.size, 'sm')
    assert.strictEqual(getComputedStyle(own.element).height, '28px', 'styled as a toggle')
    assert.false(own.isPressed)
    await own.toggle()
    assert.true(own.isPressed, 'it asked, and the state came back')

    state.pressed = false
    await settled()
    const modified = rendering(document.querySelector('[data-case="modifier"]')!)
    const component = rendering(document.querySelector('[data-case="component"]')!)
    modified.attributes['data-test-jn-name'] = 'own-component'
    assert.deepEqual(modified, component, 'the component and the modifier render the same')
    assert.deepEqual(
      component.classes,
      toggleClasses({ variant: 'outline', size: 'sm' }).split(' ').sort(),
    )
    assert.deepEqual(toggleAttributes({ variant: 'outline' })['data-variant'], 'outline')
    await a11yAudit()
  })

  test('RTL: an icon on the inline start gets the narrower padding on its side', async function (assert) {
    await render(
      <template>
        <Toggle @name="ltr" @variant="outline"><Icon
            @icon={{Bookmark}}
            data-icon="inline-start"
          />Bookmark</Toggle>
        <DirectionProvider @dir="rtl">
          <Toggle @name="rtl" @variant="outline"><Icon
              @icon={{Bookmark}}
              data-icon="inline-start"
            />إشارة مرجعية</Toggle>
        </DirectionProvider>
      </template>,
    )
    const ltr = getComputedStyle(new ToggleHarness('ltr').element)
    const rtl = getComputedStyle(new ToggleHarness('rtl').element)
    // px-2.5 (10px), with has-data-[icon=inline-start]:ps-2 (8px) on the icon's side.
    assert.strictEqual(px(ltr.paddingLeft), 8, 'left to right, the start is on the left')
    assert.strictEqual(px(ltr.paddingRight), 10)
    assert.strictEqual(px(rtl.paddingRight), 8, 'right to left, the start is on the right')
    assert.strictEqual(px(rtl.paddingLeft), 10)
    await a11yAudit()
  })
})
