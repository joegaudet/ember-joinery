import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import type { TOC } from '@ember/component/template-only'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { TOASTER_ICONS, TOASTER_STYLE, Toaster, toast, toastsFor } from '@ember-joinery/ember'
import { IconHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'

/** The colour a token resolves to, as the browser computes a background in it. */
function token(name: string): string {
  const probe = document.createElement('div')
  probe.style.background = `var(${name})`
  document.querySelector('#ember-testing')!.append(probe)
  const color = getComputedStyle(probe).backgroundColor
  probe.remove()
  return color
}

/** Waits for an element's CSS transitions (sonner animates its toasts in) to finish. */
async function transitioned(element: Element): Promise<void> {
  await Promise.all(element.getAnimations().map(animation => animation.finished))
}

module('Integration | components | toaster', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  hooks.afterEach(function () {
    document.documentElement.classList.remove('dark')
  })

  test('it renders upstream’s Toaster: its classes, icons and tokens', async function (assert) {
    await render(<template><Toaster /></template>)
    toast.success('Event has been created')
    await settled()
    const toaster = new ToasterHarness()
    const [list] = toaster.lists
    assert.dom(list).hasClass('toaster').hasClass('group')
    for (const [name, value] of Object.entries(TOASTER_STYLE)) {
      assert.strictEqual(list!.style.getPropertyValue(name), value, `${name} is ${value}`)
    }
    const item = toaster.toast()
    assert.dom(item.element).hasClass('jn-toast', "upstream's cn-toast")
    const icon = item.icon!.querySelector('svg')!
    assert.dom(icon).hasClass('lucide').hasClass('jn-toaster-icon').hasClass('jn-size-4')
    assert.true(new IconHarness({ within: item.icon! }).isDecorative, 'hidden from screen readers')
    assert.dom('circle', icon).exists("lucide's circle-check")
    await a11yAudit()
  })

  test('its CSS: a popover’s colours and the theme’s radius, sized and laid out as sonner’s', async function (assert) {
    await render(<template><Toaster /></template>)
    toast('Event has been created', {
      description: 'Sunday, December 03, 2023 at 9:00 AM',
      action: { label: 'Undo', onClick: () => {} },
    })
    await settled()
    const toaster = new ToasterHarness()
    const item = toaster.toast()
    await transitioned(item.element)
    const style = getComputedStyle(item.element)

    assert.strictEqual(style.backgroundColor, token('--popover'), '--normal-bg is --popover')
    assert.strictEqual(style.color, token('--popover-foreground'))
    assert.strictEqual(style.borderTopColor, token('--border'))
    assert.strictEqual(style.borderTopLeftRadius, '10px', "sonner's --border-radius: --radius")
    assert.strictEqual(style.width, '356px')
    assert.strictEqual(style.paddingTop, '16px')
    assert.strictEqual(style.fontSize, '13px')
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.opacity, '1', 'it has come in')
    assert.strictEqual(
      getComputedStyle(item.part('description')).color,
      'rgb(63, 63, 63)',
      "sonner's description colour, in light",
    )
    const action = getComputedStyle(item.action!)
    assert.strictEqual(action.height, '24px')
    assert.strictEqual(action.backgroundColor, token('--popover-foreground'), 'inverted colours')

    const list = getComputedStyle(toaster.lists[0]!)
    const box = toaster.lists[0]!.getBoundingClientRect()
    const viewport = document.documentElement
    assert.strictEqual(list.position, 'fixed')
    assert.strictEqual(viewport.clientWidth - box.right, 24, '24px from the right')
    assert.strictEqual(
      viewport.clientHeight - box.bottom,
      24,
      "and the bottom: the popover's inset is undone",
    )
    assert.strictEqual(box.width, 356)
    assert.strictEqual(list.borderTopWidth, '0px')
    assert.strictEqual(list.backgroundColor, 'rgba(0, 0, 0, 0)')
    assert.strictEqual(list.overflow, 'visible')
    await a11yAudit()
  })

  test('the icons are size-4, and the loading one turns', async function (assert) {
    await render(<template><Toaster /></template>)
    toast.error('Event has not been created')
    toast.loading('Loading...')
    await settled()
    const [loading, error] = new ToasterHarness().toasts
    const errorIcon = error!.icon!.querySelector('svg')!
    assert.strictEqual(getComputedStyle(errorIcon).width, '16px')
    assert.strictEqual(getComputedStyle(errorIcon).height, '16px')
    const spinner = loading!.icon!.querySelector('svg')!
    assert.dom(spinner).hasClass('jn-toaster-icon-loading')
    assert.dom(loading!.icon!.querySelector('.sonner-loader')).hasAttribute('data-visible', 'true')
    assert.notStrictEqual(getComputedStyle(spinner).animationName, 'none', 'animate-spin')
    await a11yAudit()
  })

  test('its theme follows the page: dark while <html> has .dark, unless @theme says', async function (assert) {
    await render(
      <template>
        <Toaster @name="page" />
        <Toaster @name="light" @id="light" @theme="light" @containerAriaLabel="Light" />
      </template>,
    )
    toast('Page')
    toast('Light', { toasterId: 'light' })
    await settled()
    const page = new ToasterHarness('page')
    assert.strictEqual(page.theme, 'light')

    document.documentElement.classList.add('dark')
    await waitUntil(() => page.theme === 'dark')
    assert.strictEqual(page.theme, 'dark')
    assert.strictEqual(new ToasterHarness('light').theme, 'light', '@theme wins')
    await a11yAudit()
  })

  test('rich colours colour a toast by its type', async function (assert) {
    await render(<template><Toaster @richColors={{true}} /></template>)
    toast.success('Event has been created')
    await settled()
    const item = new ToasterHarness().toast()
    await transitioned(item.element)
    assert.true(item.hasRichColors)
    assert.strictEqual(
      getComputedStyle(item.element).backgroundColor,
      'rgb(236, 253, 243)',
      "sonner's --success-bg, hsl(143, 85%, 96%)",
    )
    // sonner's success text on its success background is 4.3:1, under AA's 4.5:1 for its 13px
    // text; the guide's Accessibility section says so, and how to change it.
    await a11yAudit({ rules: { 'color-contrast': { enabled: false } } })
  })

  test('@icons, @style and @toastOptions.classNames add to upstream’s', async function (assert) {
    const Star: TOC<object> = <template>
      <span data-test-star>★</span>
    </template>
    const icons = { success: Star }
    const style = { '--width': '320px' }
    const options = { classNames: { toast: 'mine' } }
    await render(
      <template><Toaster @icons={{icons}} @style={{style}} @toastOptions={{options}} /></template>,
    )
    toast.success('Mine')
    toast.error('Upstream’s')
    await settled()
    const toaster = new ToasterHarness()
    const [error, success] = toaster.toasts
    assert.dom('[data-test-star]', success!.icon!).exists('the success icon is replaced')
    assert.dom(error!.icon!.querySelector('svg')).hasClass('jn-toaster-icon', 'the rest stay')
    assert.dom(success!.element).hasClass('jn-toast').hasClass('mine')
    const list = toaster.lists[0]!
    assert.strictEqual(list.style.getPropertyValue('--width'), '320px')
    assert.strictEqual(list.style.getPropertyValue('--normal-bg'), 'var(--popover)')
    assert.strictEqual(Object.keys(TOASTER_ICONS).length, 5, 'the defaults are exported')
    await a11yAudit()
  })

  test('RTL: sonner’s margins flip where the Toaster is right to left', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl"><Toaster /></DirectionProvider>
      </template>,
    )
    toast('تم إنشاء الحدث', { action: { label: 'تراجع', onClick: () => {} } })
    await settled()
    const toaster = new ToasterHarness()
    assert.strictEqual(toaster.listStates[0]!.dir, 'rtl')
    const box = toaster.toast().element.getBoundingClientRect()
    const action = toaster.toast().action!.getBoundingClientRect()
    assert.true(
      action.left - box.left < box.right - action.right,
      'the action sits at the end of the line, on the left',
    )
    await a11yAudit()
  })

  test('toast and toastsFor come from @ember-joinery/ember too', async function (assert) {
    await render(<template><Toaster /></template>)
    toastsFor(this.owner).warning('From the owner')
    await settled()
    assert.deepEqual(new ToasterHarness().titles, ['From the owner'])
    assert.strictEqual(new ToasterHarness().toast().type, 'warning')
    await a11yAudit()
  })
})
