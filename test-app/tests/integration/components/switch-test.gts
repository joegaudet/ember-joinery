import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Moon, Sun } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Icon, Switch, type SwitchSize } from '@ember-joinery/ember'
import { IconHarness, SwitchHarness, pressKey, tab } from '@ember-joinery/test-support'

/** A colour as the browser resolves it, for comparing with a token. */
function resolved(color: string): string {
  const probe = document.createElement('span')
  probe.style.color = color
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe).color
  probe.remove()
  return value
}

/**
 * How far the thumb has slid from the inline start of its track, once its slide
 * (`transition-transform`) has finished: positive to the right, negative to the left.
 */
function offsetOf(thumb: HTMLElement): number {
  for (const animation of thumb.getAnimations()) animation.finish()
  const track = thumb.parentElement!
  const box = track.getBoundingClientRect()
  const border = Number.parseFloat(getComputedStyle(track).borderLeftWidth)
  const rect = thumb.getBoundingClientRect()
  // The test runner shows its container scaled down; the rects are in the page's pixels.
  const scale = box.width / track.offsetWidth
  const offset =
    getComputedStyle(track).direction === 'rtl'
      ? rect.right - (box.right - border * scale)
      : rect.left - (box.left + border * scale)
  return Math.round(offset / scale)
}

/** Whether a radius is `rounded-full`'s, which the browser clamps to some huge length. */
const isFull = (radius: string) => Number.parseFloat(radius) > 1000

const SIZES: SwitchSize[] = ['default', 'sm']

module('Integration | components | switch', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's classes, slots and size", async function (assert) {
    await render(
      <template>
        <Switch @name="airplane" id="airplane-mode" />
        <label for="airplane-mode">Airplane Mode</label>
        {{#each SIZES as |size|}}
          <Switch @name={{size}} @size={{size}} aria-label={{size}} />
        {{/each}}
      </template>,
    )
    const airplane = new SwitchHarness('airplane')
    assert
      .dom(airplane.element)
      .hasTagName('button')
      .hasClass('jn-switch')
      .hasClass('peer')
      .hasClass('group/switch')
      .hasAttribute('data-slot', 'switch')
      .hasAttribute('data-size', 'default')
      .hasAttribute('role', 'switch')
      .hasAttribute('data-state', 'unchecked')
    assert
      .dom(airplane.thumb)
      .hasClass('jn-switch-thumb')
      .hasAttribute('data-slot', 'switch-thumb')
      .hasAttribute('data-state', 'unchecked')
    assert.strictEqual(airplane.label, 'Airplane Mode')
    for (const size of SIZES) assert.strictEqual(new SwitchHarness(size).size, size)
    await a11yAudit()
  })

  test('its style sheet sizes it, colours it and slides the thumb, without Tailwind', async function (assert) {
    await render(
      <template>
        <Switch @name="default" aria-label="Default" />
        <Switch @name="sm" @size="sm" aria-label="Small" />
        <Switch @name="on" @defaultChecked={{true}} aria-label="On" />
        <Switch @name="disabled" @disabled={{true}} aria-label="Disabled" />
      </template>,
    )
    const harness = (name: string) => new SwitchHarness(name)
    const style = (name: string) => getComputedStyle(harness(name).element)
    assert.strictEqual(style('default').width, '32px', 'data-[size=default]:w-[32px]')
    assert.strictEqual(
      Math.round(Number.parseFloat(style('default').height) * 10) / 10,
      18.4,
      'data-[size=default]:h-[18.4px]',
    )
    assert.true(isFull(style('default').borderTopLeftRadius), 'rounded-full')
    assert.strictEqual(style('default').display, 'inline-flex')
    assert.strictEqual(style('default').backgroundColor, resolved('var(--input)'))
    assert.strictEqual(style('sm').width, '24px')
    assert.strictEqual(style('sm').height, '14px')
    assert.strictEqual(style('on').backgroundColor, resolved('var(--primary)'))
    assert.strictEqual(style('disabled').opacity, '0.5', 'data-disabled:opacity-50')
    assert.strictEqual(style('disabled').cursor, 'not-allowed')

    const thumb = (name: string) => getComputedStyle(harness(name).thumb!)
    assert.strictEqual(thumb('default').width, '16px', 'size-4 in a default switch')
    assert.strictEqual(thumb('sm').width, '12px', 'size-3 in a small one')
    assert.strictEqual(thumb('default').backgroundColor, resolved('var(--background)'))
    assert.strictEqual(thumb('default').pointerEvents, 'none')
    assert.strictEqual(offsetOf(harness('default').thumb!), 0, 'unchecked, at the start')
    assert.strictEqual(offsetOf(harness('on').thumb!), 14, 'checked: 100% - 2px along')

    await harness('sm').toggle()
    assert.strictEqual(offsetOf(harness('sm').thumb!), 10, 'a small one slides less')
    await a11yAudit()
  })

  test('RTL: the thumb slides the other way', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Switch @name="rtl" @defaultChecked={{true}} aria-label="المشاركة عبر الأجهزة" />
          <Switch @name="rtl-sm" @size="sm" aria-label="صغير" />
        </DirectionProvider>
      </template>,
    )
    const rtl = new SwitchHarness('rtl')
    assert.strictEqual(offsetOf(rtl.thumb!), -14, 'checked, it moves left')
    const box = rtl.element.getBoundingClientRect()
    const thumb = rtl.thumb!.getBoundingClientRect()
    assert.ok(thumb.left - box.left < 3, 'to the left end')

    const small = new SwitchHarness('rtl-sm')
    const start = small.thumb!.getBoundingClientRect()
    const end = small.element.getBoundingClientRect()
    assert.ok(end.right - start.right < 3, 'unchecked, it sits at the right, the inline start')
    await small.toggle()
    assert.strictEqual(offsetOf(small.thumb!), -10)
    await a11yAudit()
  })

  test('controlled and uncontrolled', async function (assert) {
    class State {
      @tracked on = false
    }
    const state = new State()
    const change = (checked: boolean) => (state.on = checked)
    await render(
      <template>
        <Switch @name="mine" @defaultChecked={{true}} aria-label="Mine" />
        <Switch
          @name="theirs"
          @checked={{state.on}}
          @onCheckedChange={{change}}
          aria-label="Theirs"
        />
      </template>,
    )
    const mine = new SwitchHarness('mine')
    await mine.toggle()
    assert.false(mine.isChecked)
    const theirs = new SwitchHarness('theirs')
    await theirs.toggle()
    assert.true(state.on)
    assert.true(theirs.isChecked)
    state.on = false
    await settled()
    assert.false(theirs.isChecked)
    await a11yAudit()
  })

  test('its block renders inside the thumb, with the state', async function (assert) {
    await render(
      <template>
        <Switch @name="theme" aria-label="Dark mode" as |s|>
          <Icon @icon={{if s.isChecked Moon Sun}} @name={{if s.isChecked "moon" "sun"}} />
        </Switch>
      </template>,
    )
    const theme = new SwitchHarness('theme')
    assert.true(theme.find(IconHarness, 'sun').exists)
    assert.ok(theme.thumb!.contains(theme.find(IconHarness, 'sun').element), 'inside the thumb')
    await theme.toggle()
    assert.true(theme.find(IconHarness, 'moon').exists)
    await a11yAudit()
  })

  test('keyboard: Tab reaches it, and a disabled one is passed over', async function (assert) {
    await render(
      <template>
        <Switch @name="first" aria-label="First" />
        <Switch @name="off" @disabled={{true}} aria-label="Off" />
        <Switch @name="last" aria-label="Last" />
      </template>,
    )
    await tab()
    assert.true(new SwitchHarness('first').isFocused)
    assert.false(await pressKey(' '), 'Space is left to the native button, which clicks')
    await tab()
    assert.true(new SwitchHarness('last').isFocused)
    await a11yAudit()
  })

  test('in a form, @as, aria-invalid and the harness', async function (assert) {
    await render(
      <template>
        <form id="settings">
          <Switch
            @name="terms"
            name="terms"
            aria-invalid="true"
            @required={{true}}
            aria-label="Terms"
          />
        </form>
        <Switch @name="span" @as="span" tabindex="0" aria-label="Span" />
      </template>,
    )

    const terms = new SwitchHarness('terms')
    assert.true(terms.isInvalid)
    assert.true(terms.isRequired)
    assert.strictEqual(
      getComputedStyle(terms.element).borderTopColor,
      resolved('var(--destructive)'),
      'aria-invalid:border-destructive',
    )
    assert.dom(terms.input).hasAttribute('name', 'terms')
    await click(terms.element)
    assert.true(terms.input!.checked)

    const span = new SwitchHarness('span')
    assert.dom(span.element).hasTagName('span').hasClass('jn-switch')
    await span.check()
    assert.true(span.isChecked)
    await span.uncheck()
    assert.false(span.isChecked)
    await span.focus()
    assert.true(span.isFocused)
    await span.blur()
    await a11yAudit()
  })
})
