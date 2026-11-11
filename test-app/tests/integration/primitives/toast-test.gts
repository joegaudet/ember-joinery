import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, focus, render, settled, triggerEvent, waitUntil } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import type Owner from '@ember/owner'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import type { TOC } from '@ember/component/template-only'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { dismissable } from '@ember-joinery/primitives/dismiss'
import { topLayer } from '@ember-joinery/primitives/layer'
import {
  Toaster,
  toast,
  toastOwner,
  toastsFor,
  type CustomToastSignature,
} from '@ember-joinery/primitives/toast'
import {
  ToastHarness,
  ToasterHarness,
  isInTopLayer,
  press,
  pressEscape,
  setupColorScheme,
  setupToaster,
} from '@ember-joinery/test-support'

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

module('Integration | primitives | toast', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a toast renders in a live region, with sonner markup and data attributes', async function (assert) {
    await render(<template><Toaster /></template>)
    const toaster = new ToasterHarness()
    assert.dom(toaster.element).hasTagName('section')
    assert
      .dom(toaster.element)
      .hasAttribute('aria-label', 'Notifications alt+T')
      .hasAttribute('aria-live', 'polite')
      .hasAttribute('aria-relevant', 'additions text')
      .hasAttribute('aria-atomic', 'false')
      .hasAttribute('tabindex', '-1')
    assert.strictEqual(toaster.lists.length, 0, 'no list until there is a toast')

    const id = toast('Event has been created')
    await settled()

    assert.strictEqual(typeof id, 'number')
    assert.deepEqual(toaster.positions, ['bottom-right'], 'sonner shows toasts bottom right')
    const [list] = toaster.lists
    assert
      .dom(list)
      .hasTagName('ol')
      .hasAttribute('data-sonner-toaster', 'true')
      .hasAttribute('data-sonner-theme', 'light')
      .hasAttribute('data-y-position', 'bottom')
      .hasAttribute('data-x-position', 'right')
      .hasAttribute('dir', 'ltr')
    assert.strictEqual(list!.style.getPropertyValue('--width'), '356px')
    assert.strictEqual(list!.style.getPropertyValue('--gap'), '14px')
    assert.strictEqual(list!.style.getPropertyValue('--offset-bottom'), '24px')
    assert.strictEqual(list!.style.getPropertyValue('--mobile-offset-left'), '16px')

    const item = toaster.toast()
    assert.strictEqual(item.id, String(id))
    assert.strictEqual(item.title, 'Event has been created')
    assert.strictEqual(item.description, null)
    assert.strictEqual(item.type, null, 'a plain toast has no type')
    assert.strictEqual(item.position, 'bottom-right')
    assert.true(item.isMounted, 'it has come in')
    assert.true(item.isFront)
    assert.true(item.isVisible)
    assert.true(item.isStyled)
    assert.true(item.isDismissible)
    assert.false(item.isExpanded)
    assert.strictEqual(item.icon, null, 'a plain toast has no icon')
    assert
      .dom(item.element)
      .hasTagName('li')
      .hasAttribute('data-sonner-toast', '')
      .hasAttribute('tabindex', '0')
      .hasAttribute('data-index', '0')
      .doesNotHaveAttribute('data-rich-colors', 'unset, as sonner leaves it')
    assert.strictEqual(item.element.style.getPropertyValue('--z-index'), '1')
    await a11yAudit()
  })

  test('the list is in the top layer, and counts as inside every dismissable layer', async function (assert) {
    class State {
      @tracked open = true
    }
    const state = new State()
    const close = () => (state.open = false)
    await render(
      <template>
        {{#if state.open}}
          <div {{topLayer}} {{dismissable onDismiss=close}} data-test-layer>A popover</div>
        {{/if}}
        <Toaster />
      </template>,
    )
    toast('Saved', { action: { label: 'Undo', onClick: () => {} } })
    await settled()
    const toaster = new ToasterHarness()
    assert.true(isInTopLayer(toaster.lists[0]), 'above everything, dialogs included')

    await press(toaster.toast().element)
    assert.true(state.open, 'pressing a toast closes no layer')
    await a11yAudit()
  })

  test('each type has its own icon; loading has the spinner', async function (assert) {
    await render(<template><Toaster /></template>)
    toast.success('Event has been created')
    toast.info('Be at the area 10 minutes before the event time')
    toast.warning('Event start time cannot be earlier than 8am')
    toast.error('Event has not been created')
    toast.loading('Loading...')
    toast.message('A message')
    await settled()

    const toaster = new ToasterHarness()
    assert.deepEqual(
      toaster.toasts.map(each => each.type),
      [null, 'loading', 'error', 'warning', 'info', 'success'],
      'newest first',
    )
    for (const each of toaster.toasts.slice(2)) {
      assert.dom(each.icon!.querySelector('svg')).exists(`${each.type} has sonner's icon`)
    }
    const loading = toaster.toast({ index: 1 })
    assert.true(loading.isLoading)
    assert
      .dom(loading.icon!.querySelector('.sonner-loading-wrapper'))
      .hasAttribute('data-visible', 'true')
    assert.dom('.sonner-loading-bar', loading.icon!).exists({ count: 12 })
    await a11yAudit()
  })

  test('a description, an action and a cancel button', async function (assert) {
    const calls: string[] = []
    await render(<template><Toaster /></template>)
    toast('Event has been created', {
      description: 'Sunday, December 03, 2023 at 9:00 AM',
      action: { label: 'Undo', onClick: () => calls.push('undo') },
      cancel: { label: 'Cancel', onClick: () => calls.push('cancel') },
    })
    await settled()

    const item = new ToasterHarness().toast()
    assert.strictEqual(item.description, 'Sunday, December 03, 2023 at 9:00 AM')
    assert
      .dom(item.action)
      .hasText('Undo')
      .hasAttribute('data-button', 'true')
      .hasAttribute('data-action', 'true')
    assert.dom(item.cancel).hasText('Cancel').hasAttribute('data-cancel', 'true')
    await a11yAudit()

    await item.clickAction()
    assert.deepEqual(calls, ['undo'])
    assert.false(item.exists, 'the action closed it')

    toast('Again', { cancel: { label: 'Cancel', onClick: () => calls.push('cancel') } })
    await settled()
    await new ToasterHarness().toast().clickCancel()
    assert.deepEqual(calls, ['undo', 'cancel'])
    assert.strictEqual(new ToasterHarness().count, 0, 'the cancel button closed it')
  })

  test("an action that prevents the event's default keeps the toast", async function (assert) {
    await render(<template><Toaster /></template>)
    toast('Kept', { action: { label: 'Keep', onClick: event => event.preventDefault() } })
    await settled()
    const item = new ToasterHarness().toast()
    await item.clickAction()
    assert.true(item.exists)
    assert.false(item.isRemoved)
    await a11yAudit()
  })

  test('the close button, from the Toaster or the toast, closes it and calls onDismiss', async function (assert) {
    const dismissed: string[] = []
    await render(<template><Toaster @closeButton={{true}} /></template>)
    toast('Closable', { onDismiss: t => dismissed.push(String(t.title)) })
    toast('Not closable', { closeButton: false })
    await settled()
    const toaster = new ToasterHarness()
    const [without, closable] = toaster.toasts
    assert.strictEqual(without!.closeButton, null, "the toast's closeButton wins")
    assert
      .dom(closable!.closeButton)
      .hasAttribute('aria-label', 'Close toast')
      .hasAttribute('data-close-button', 'true')
    await a11yAudit()

    await closable!.close()
    assert.deepEqual(dismissed, ['Closable'])
    assert.deepEqual(toaster.titles, ['Not closable'])
  })

  test('toast.dismiss() closes one toast, or all of them', async function (assert) {
    const dismissed: unknown[] = []
    await render(<template><Toaster /></template>)
    const first = toast('First', { onDismiss: t => dismissed.push(t.id) })
    toast('Second')
    toast('Third')
    await settled()
    const toaster = new ToasterHarness()
    assert.strictEqual(toaster.count, 3)

    toast.dismiss(first)
    await settled()
    assert.deepEqual(dismissed, [first], 'onDismiss ran')
    assert.deepEqual(toaster.titles, ['Third', 'Second'])
    assert.deepEqual(
      toast.getToasts().map(t => t.title),
      ['Second', 'Third'],
      'getToasts leaves out the dismissed',
    )
    assert.strictEqual(toast.getHistory().length, 3)

    toast.dismiss()
    await settled()
    assert.strictEqual(toaster.count, 0)
    assert.strictEqual(toaster.lists.length, 0, 'the list goes with the last toast')
    await a11yAudit()
  })

  test('a toast with the same id updates in place', async function (assert) {
    await render(<template><Toaster /></template>)
    toast.loading('Uploading…', { id: 'upload' })
    await settled()
    const item = new ToastHarness('upload')
    assert.true(item.isLoading)

    toast.success('Uploaded', { id: 'upload' })
    await settled()
    assert.strictEqual(new ToasterHarness().count, 1)
    assert.strictEqual(item.title, 'Uploaded')
    assert.strictEqual(item.type, 'success')
    await a11yAudit()
  })

  test('toast.promise() shows loading, then success from the result', async function (assert) {
    let resolve!: (value: { name: string }) => void
    const finished: string[] = []
    await render(<template><Toaster /></template>)
    const result = toast.promise(new Promise<{ name: string }>(r => (resolve = r)), {
      loading: 'Loading...',
      success: data => `${data.name} has been created`,
      error: 'Error',
      finally: () => void finished.push('finally'),
    })
    await settled()
    const toaster = new ToasterHarness()
    const item = toaster.toast()
    assert.true(item.isLoading)
    assert.true(item.isPromise)
    assert.strictEqual(item.title, 'Loading...')
    assert.strictEqual(item.id, String(result.id))

    resolve({ name: 'Event' })
    await waitUntil(() => item.type === 'success')
    assert.strictEqual(item.title, 'Event has been created')
    assert.deepEqual(await result.unwrap(), { name: 'Event' })
    assert.deepEqual(finished, ['finally'])
    assert.strictEqual(toaster.count, 1, 'the outcome replaced the loading toast')
    await a11yAudit()
  })

  test('toast.promise() shows the error, for a rejection, an Error or a failed Response', async function (assert) {
    await render(<template><Toaster /></template>)
    const rejected = toast.promise(Promise.reject(new Error('nope')), {
      loading: 'Loading...',
      error: (error: unknown) => `Failed: ${(error as Error).message}`,
    })
    toast.promise(Promise.resolve(new Error('as a value')), { loading: 'Two', error: 'Error' })
    toast.promise(Promise.resolve({ ok: false, status: 500 }), {
      loading: 'Three',
      error: (message: unknown) => String(message),
      description: 'It failed',
    })
    await assert.rejects(rejected.unwrap(), /nope/)
    const toaster = new ToasterHarness()
    await waitUntil(() => toaster.toasts.every(each => each.type === 'error'))
    assert.deepEqual(toaster.titles, ['HTTP error! status: 500', 'Error', 'Failed: nope'])
    assert.strictEqual(toaster.toast().description, 'It failed')
    await a11yAudit()
  })

  test('toast.dismiss() takes what toast.promise() returns, and closes nothing for a non-id', async function (assert) {
    await render(<template><Toaster /></template>)
    const pending = toast.promise(new Promise(() => {}), { loading: 'Waiting' })
    toast('Stays')
    await settled()
    const toaster = new ToasterHarness()
    assert.strictEqual(toaster.count, 2)

    // sonner code that keeps toast.promise()'s result as the id.
    const id = toast.dismiss(pending)
    await settled()
    assert.strictEqual(id, pending.id)
    assert.deepEqual(toaster.titles, ['Stays'], 'the promise toast closed')

    // Not an id: it closes nothing (not every toast, as no id would), and Ember's debug build
    // warns (joinery.toast.dismiss-id). The test app runs Ember's production build, without it.
    toast.dismiss({ id: 1 } as never)
    await settled()
    assert.deepEqual(toaster.titles, ['Stays'], 'a value that is not an id closes nothing')
    await a11yAudit()
  })

  test('a promise with nothing to show for its outcome takes the loading toast away', async function (assert) {
    await render(<template><Toaster /></template>)
    toast.promise(Promise.resolve('done'), { loading: 'Working' })
    const toaster = new ToasterHarness()
    await waitUntil(() => toaster.count === 0 && toaster.lists.length === 0)
    assert.strictEqual(toaster.count, 0)
    await a11yAudit()
  })

  test('the stack: newest in front, three visible, collapsed until hovered', async function (assert) {
    await render(<template><Toaster /></template>)
    for (const title of ['One', 'Two', 'Three', 'Four']) toast(title)
    await settled()
    const toaster = new ToasterHarness()
    const [front, second, third, fourth] = toaster.toasts
    assert.deepEqual(toaster.titles, ['Four', 'Three', 'Two', 'One'])
    assert.true(front!.isFront)
    assert.false(second!.isFront)
    assert.true(third!.isVisible)
    assert.false(fourth!.isVisible, 'only three show')
    assert.strictEqual(front!.element.style.getPropertyValue('--z-index'), '4')
    assert.strictEqual(fourth!.element.style.getPropertyValue('--z-index'), '1')
    assert.false(toaster.isExpanded)
    assert.strictEqual(
      toaster.lists[0]!.style.getPropertyValue('--front-toast-height'),
      getComputedStyle(front!.element).height,
    )
    // sonner's CSS animates the height; read it once that is done.
    await Promise.all(second!.element.getAnimations().map(animation => animation.finished))
    assert.strictEqual(
      getComputedStyle(second!.element).height,
      getComputedStyle(front!.element).height,
      'a collapsed toast takes the front one’s height',
    )
    const offset = (item: ToastHarness) =>
      Number.parseFloat(item.element.style.getPropertyValue('--offset'))
    assert.strictEqual(offset(front!), 0)
    const height = front!.element.getBoundingClientRect().height
    assert.strictEqual(offset(second!), height + 14, 'below the front one, one gap apart')

    await toaster.hover()
    assert.true(toaster.isExpanded, 'hovering expands it')
    await toaster.unhover()
    assert.false(toaster.isExpanded)
    await a11yAudit()
  })

  test('@expand shows the stack expanded, and @visibleToasts how many show', async function (assert) {
    await render(<template><Toaster @expand={{true}} @visibleToasts={{2}} @gap={{8}} /></template>)
    toast('One')
    toast('Two')
    toast('Three')
    await settled()
    const toaster = new ToasterHarness()
    assert.true(toaster.isExpanded)
    assert.deepEqual(
      toaster.toasts.map(each => each.isVisible),
      [true, true, false],
    )
    assert.strictEqual(toaster.lists[0]!.style.getPropertyValue('--gap'), '8px')
    assert.strictEqual(toaster.toast().element.style.getPropertyValue('--initial-height'), 'auto')
    await a11yAudit()
  })

  test('a toast closes itself after its duration, unless hovered', async function (assert) {
    const closed: unknown[] = []
    await render(<template><Toaster @duration={{150}} /></template>)
    toast('Short', { onAutoClose: t => closed.push(t.title) })
    toast('Forever', { duration: Infinity })
    await settled()
    const toaster = new ToasterHarness()
    await toaster.hover()
    await sleep(300)
    assert.strictEqual(toaster.count, 2, 'hovering pauses the timers')

    await toaster.unhover()
    await waitUntil(() => toaster.count === 1, { timeout: 2000 })
    await settled()
    assert.deepEqual(closed, ['Short'])
    assert.deepEqual(toaster.titles, ['Forever'], 'duration: Infinity stays')
    await a11yAudit()
  })

  test('a loading toast has no timer', async function (assert) {
    await render(<template><Toaster @duration={{50}} /></template>)
    toast.loading('Loading...')
    await sleep(200)
    assert.strictEqual(new ToasterHarness().count, 1)
    await a11yAudit()
  })

  test('swiping a toast towards its side dismisses it; a short slow swipe springs back', async function (assert) {
    const dismissed: unknown[] = []
    await render(<template><Toaster /></template>)
    toast('Swipe me', { onDismiss: t => dismissed.push(t.title) })
    await settled()
    const toaster = new ToasterHarness()
    const item = toaster.toast()

    await item.swipe('right', { distance: 20, duration: 400 })
    assert.true(item.exists, 'too short and too slow')
    assert.false(item.isRemoved)
    assert.strictEqual(
      item.element.style.getPropertyValue('--swipe-amount-x'),
      '0px',
      'back in place',
    )

    await item.swipe('right')
    assert.deepEqual(dismissed, ['Swipe me'])
    assert.strictEqual(toaster.count, 0)
    await a11yAudit()
  })

  test('a swipe away from its sides is dampened; a toast that is not dismissible stays', async function (assert) {
    await render(<template><Toaster /></template>)
    toast('Stays', { dismissible: false })
    await settled()
    const item = new ToasterHarness().toast()
    assert.false(item.isDismissible)
    await item.swipe('right')
    assert.true(item.exists, 'not dismissible')

    toast.dismiss(item.id)
    toast('Bottom right')
    await settled()
    const other = new ToasterHarness().toast()
    const element = other.element
    await triggerEvent(element, 'pointerdown', {
      clientX: 100,
      clientY: 100,
      button: 0,
      pointerId: 1,
    })
    await triggerEvent(element, 'pointermove', { clientX: 100, clientY: 40, pointerId: 1 })
    await triggerEvent(element, 'pointermove', { clientX: 100, clientY: 20, pointerId: 1 })
    const amount = Number.parseFloat(element.style.getPropertyValue('--swipe-amount-y'))
    assert.true(amount < 0 && amount > -80, `up, against its sides, follows less (${amount}px)`)
    assert.dom(element).hasAttribute('data-swiping', 'true')
    await triggerEvent(element, 'pointerup', { pointerId: 1 })
    await a11yAudit()
  })

  test('the hotkey expands the stack and focuses it; Escape collapses it', async function (assert) {
    await render(
      <template>
        <button type="button" data-test-before>Before</button>
        <Toaster />
      </template>,
    )
    toast('One')
    toast('Two')
    await settled()
    const toaster = new ToasterHarness()
    await focus('[data-test-before]')

    await toaster.pressHotkey()
    assert.true(toaster.isExpanded)
    assert.dom(toaster.lists[0]).isFocused()

    await pressEscape()
    assert.false(toaster.isExpanded)
    await a11yAudit()
  })

  test('a custom @hotkey and @containerAriaLabel name the region', async function (assert) {
    const keys = ['metaKey', 'KeyJ']
    await render(<template><Toaster @hotkey={{keys}} @containerAriaLabel="Alerts" /></template>)
    toast('One')
    toast('Two')
    await settled()
    const toaster = new ToasterHarness()
    assert.strictEqual(toaster.label, 'Alerts meta+J')
    await toaster.pressHotkey()
    assert.false(toaster.isExpanded, 'Alt+T does nothing')
    await toaster.pressHotkey(keys)
    assert.true(toaster.isExpanded)
    await a11yAudit()
  })

  test('focus in a toast expands the stack and pauses it; leaving gives focus back', async function (assert) {
    await render(
      <template>
        <button type="button" data-test-before>Before</button>
        <Toaster @duration={{150}} />
      </template>,
    )
    toast('One')
    toast('Two')
    await settled()
    const toaster = new ToasterHarness()
    await focus('[data-test-before]')
    await toaster.toast().focus()
    assert.true(toaster.isExpanded, 'a keyboard user sees the whole stack')
    await sleep(300)
    assert.strictEqual(toaster.count, 2, 'and the timers wait')

    await focus(toaster.toast({ index: 1 }).element)
    assert.true(toaster.isExpanded, 'moving between toasts keeps it')

    const outside = document.createElement('button')
    document.querySelector('#ember-testing')!.append(outside)
    await focus(outside)
    assert.dom('[data-test-before]').isFocused('focus goes back where it was')
    assert.false(toaster.isExpanded)
    outside.remove()
    await a11yAudit()
  })

  test('keyboard focus holds the stack open when the pointer leaves', async function (assert) {
    await render(<template><Toaster /></template>)
    toast('One')
    toast('Two')
    await settled()
    const toaster = new ToasterHarness()
    await toaster.hover()
    await toaster.toast().focus()
    await toaster.unhover()
    assert.true(toaster.isExpanded, 'a keyboard user still sees the whole stack')
    await a11yAudit()
  })

  test('a press focuses a toast but holds nothing: the pointer leaving collapses it, as in sonner', async function (assert) {
    await render(<template><Toaster @duration={{150}} /></template>)
    toast('One')
    toast('Two')
    await settled()
    const toaster = new ToasterHarness()
    await toaster.hover()
    await press(toaster.toast().element)
    assert.dom(toaster.toast().element).isFocused('pressing the toast focused it')
    assert.true(toaster.isExpanded, 'still expanded under the pointer')

    await toaster.unhover()
    assert.false(toaster.isExpanded, 'the pointer leaving collapses it, focus or not')
    await waitUntil(() => toaster.count === 0, { timeout: 2000 })
    assert.strictEqual(toaster.count, 0, 'and the timers ran again')
    await a11yAudit()
  })

  test('positions: the Toaster’s, and a list for each position a toast asks for', async function (assert) {
    await render(<template><Toaster @position="top-center" /></template>)
    toast('Default')
    toast('Top left', { position: 'top-left' })
    toast('Bottom right', { position: 'bottom-right' })
    await settled()
    const toaster = new ToasterHarness()
    assert.deepEqual(
      toaster.positions,
      ['top-center', 'bottom-right', 'top-left'],
      "its own first, then the toasts', newest first",
    )
    assert.deepEqual(
      toaster.toasts.map(each => `${each.title}: ${each.position}`),
      ['Default: top-center', 'Bottom right: bottom-right', 'Top left: top-left'],
    )
    const [topCenter] = toaster.lists
    assert
      .dom(topCenter)
      .hasAttribute('data-y-position', 'top')
      .hasAttribute('data-x-position', 'center')
    assert.strictEqual(getComputedStyle(topCenter!).position, 'fixed')
    assert.strictEqual(getComputedStyle(topCenter!).top, '24px', "sonner's offset from the top")
    await a11yAudit()
  })

  test('@offset and @mobileOffset, as one length or per side', async function (assert) {
    const offset = { top: 10, left: '2rem' }
    await render(<template><Toaster @offset={{offset}} @mobileOffset={{8}} /></template>)
    toast('Offset')
    await settled()
    const [list] = new ToasterHarness().lists
    assert.strictEqual(list!.style.getPropertyValue('--offset-top'), '10px')
    assert.strictEqual(list!.style.getPropertyValue('--offset-left'), '2rem')
    assert.strictEqual(list!.style.getPropertyValue('--offset-bottom'), '24px', 'the rest default')
    assert.strictEqual(list!.style.getPropertyValue('--mobile-offset-right'), '8px')
    await a11yAudit()
  })

  test('@theme: light by default, or dark', async function (assert) {
    class State {
      @tracked theme: 'light' | 'dark' | undefined
    }
    const state = new State()
    await render(<template><Toaster @theme={{state.theme}} /></template>)
    toast('Themed')
    await settled()
    const toaster = new ToasterHarness()
    assert.strictEqual(toaster.theme, 'light')
    state.theme = 'dark'
    await settled()
    assert.strictEqual(toaster.theme, 'dark')
    await a11yAudit()
  })

  test('richColors, invert and unstyled', async function (assert) {
    await render(<template><Toaster @richColors={{true}} @invert={{true}} /></template>)
    toast.success('Rich')
    toast('Plain', { richColors: false, unstyled: true })
    await settled()
    const [plain, rich] = new ToasterHarness().toasts
    assert.true(rich!.hasRichColors)
    assert.true(rich!.isInverted)
    assert.false(plain!.hasRichColors, "the toast's own setting wins")
    assert.false(plain!.isStyled)
    await a11yAudit()
  })

  test('classNames, className and styles go on the parts', async function (assert) {
    const options = {
      className: 'from-options',
      classNames: { toast: 'my-toast', title: 'my-title', success: 'my-success' },
      style: { '--my-var': '1' },
    }
    const style = { '--normal-border': 'blue' }
    await render(
      <template><Toaster @toastOptions={{options}} @style={{style}} class="my-list" /></template>,
    )
    toast.success('Styled', {
      className: 'own',
      descriptionClassName: 'own-description',
      description: 'With a description',
      style: { marginTop: '2px' },
    })
    await settled()
    const toaster = new ToasterHarness()
    const item = toaster.toast()
    assert
      .dom(item.element)
      .hasClass('from-options')
      .hasClass('own')
      .hasClass('my-toast')
      .hasClass('my-success')
    assert.dom(item.part('title')).hasClass('my-title')
    assert.dom(item.part('description')).hasClass('own-description')
    assert.strictEqual(item.element.style.getPropertyValue('--my-var'), '1')
    assert.strictEqual(item.element.style.getPropertyValue('margin-top'), '2px', 'camelCase works')
    assert.dom(toaster.lists[0]).hasClass('my-list', 'attributes go on each list')
    assert.strictEqual(toaster.lists[0]!.style.getPropertyValue('--normal-border'), 'blue')
    await a11yAudit()
  })

  test('a component as the title, description, icon or action, and a custom toast', async function (assert) {
    const Title: TOC<object> = <template>
      <strong data-test-title>Bold</strong>
    </template>
    const Icon: TOC<object> = <template>
      <span data-test-icon>★</span>
    </template>
    const Action: TOC<object> = <template>
      <button type="button" data-test-action>Mine</button>
    </template>
    const Custom: TOC<CustomToastSignature> = <template>
      <div data-test-custom>Custom
        {{@id}}
        <button type="button" {{on "click" @dismiss}}>Dismiss</button></div>
    </template>
    await render(<template><Toaster /></template>)
    toast(Title, { description: Title, icon: Icon, action: Action })
    toast.custom(Custom, { id: 'custom' })
    await settled()

    const toaster = new ToasterHarness()
    const custom = new ToastHarness('custom')
    assert.false(custom.isStyled, 'a custom toast is unstyled')
    assert.dom('[data-test-custom]', custom.element).hasText('Custom custom Dismiss')

    const item = toaster.toast({ index: 1 })
    assert.dom('[data-test-title]', item.part('title')).exists()
    assert.dom('[data-test-title]', item.part('description')).exists()
    assert.dom('[data-test-icon]', item.icon!).exists()
    assert.dom('[data-test-action]', item.element).exists()
    await a11yAudit()

    await click(custom.element.querySelector('button')!)
    assert.false(custom.exists, '@dismiss closes it')
  })

  test('@icons replace the types’ icons; null hides one', async function (assert) {
    const Mine: TOC<object> = <template>
      <span data-test-mine>!</span>
    </template>
    const icons = { success: Mine, error: null }
    await render(<template><Toaster @icons={{icons}} /></template>)
    toast.success('Mine')
    toast.error('None')
    await settled()
    const [none, mine] = new ToasterHarness().toasts
    assert.dom('[data-test-mine]', mine!.icon!).exists()
    assert.strictEqual(none!.icon, null)
    await a11yAudit()
  })

  test('@id: a Toaster shows only the toasts for it', async function (assert) {
    await render(
      <template>
        <Toaster @name="main" />
        {{! Two regions on a page need two names. }}
        <Toaster @name="side" @id="side" @position="top-left" @containerAriaLabel="Side" />
      </template>,
    )
    toast('Main')
    toast('Side', { toasterId: 'side' })
    await settled()
    assert.deepEqual(new ToasterHarness('main').titles, ['Main'])
    assert.deepEqual(new ToasterHarness('side').titles, ['Side'])
    await a11yAudit()
  })

  test('RTL: the lists take the direction where the Toaster is, or @dir', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl"><Toaster @name="inside" /></DirectionProvider>
        <Toaster @name="explicit" @id="explicit" @dir="rtl" @containerAriaLabel="Explicit" />
      </template>,
    )
    toast('مرحبا')
    toast('Explicit', { toasterId: 'explicit' })
    await settled()
    assert.strictEqual(new ToasterHarness('inside').listStates[0]!.dir, 'rtl')
    assert.strictEqual(new ToasterHarness('explicit').listStates[0]!.dir, 'rtl')
    const item = new ToasterHarness('inside').toast()
    assert.strictEqual(
      getComputedStyle(item.element).getPropertyValue('--toast-button-margin-end').trim(),
      'auto',
      "sonner's right-to-left margins",
    )
    await a11yAudit()
  })

  test('toasts belong to the owner: toastsFor(), and toast() before a Toaster renders', async function (assert) {
    assert.strictEqual(toastOwner(), this.owner, 'setupToaster points toast() at the test')
    toast('Made early')
    assert.deepEqual(
      toast.getToasts().map(t => t.title),
      ['Made early'],
      'getToasts() has it at once',
    )
    assert.deepEqual(toastsFor(this.owner).toasts, [], 'the Toasters get it a microtask later')
    await settled()
    assert.deepEqual(
      toastsFor(this.owner).toasts.map(t => t.title),
      ['Made early'],
    )
    await render(<template><Toaster /></template>)
    assert.deepEqual(new ToasterHarness().titles, ['Made early'], 'it shows once a Toaster renders')
    toastsFor(this.owner).info('From the owner')
    await settled()
    assert.deepEqual(new ToasterHarness().titles, ['From the owner', 'Made early'])
    await a11yAudit()
  })

  test('toast() can be called while rendering, after the Toaster has read its toasts', async function (assert) {
    // As upstream's manual install puts <Toaster /> before the page: the Toaster renders first,
    // then a component further down makes a toast as it is created.
    class Welcome extends Component {
      constructor(owner: Owner, args: object) {
        super(owner, args)
        toast('Welcome back')
      }
      get greeting() {
        toast.info('From a getter')
        return 'Hello'
      }
      <template>
        <p>{{this.greeting}}</p>
      </template>
    }
    await render(
      <template>
        <Toaster />
        <Welcome />
      </template>,
    )
    assert.deepEqual(new ToasterHarness().titles, ['From a getter', 'Welcome back'])
    await a11yAudit()
  })

  test('a button can make a toast in a template, with fn', async function (assert) {
    await render(
      <template>
        <button type="button" {{on "click" (fn toast "Clicked" undefined)}}>Toast</button>
        <Toaster />
      </template>,
    )
    await click('button')
    assert.deepEqual(new ToasterHarness().titles, ['Clicked'])
    await a11yAudit()
  })
})

module('Integration | primitives | toast, without setupToaster', function (hooks) {
  setupRenderingTest(hooks)

  test('a rendered Toaster binds toast() to its owner, until it goes', async function (assert) {
    class State {
      @tracked shown = true
    }
    const state = new State()
    await render(<template>{{#if state.shown}}<Toaster />{{/if}}</template>)
    assert.strictEqual(toastOwner(), this.owner)
    toast('Hello')
    await settled()
    assert.deepEqual(new ToasterHarness().titles, ['Hello'])
    state.shown = false
    await settled()
    assert.strictEqual(toastOwner(), undefined, 'no Toaster, no owner')
    await a11yAudit()
  })

  test('the previous test’s toasts are gone', async function (assert) {
    await render(<template><Toaster /></template>)
    assert.deepEqual(toastsFor(this.owner).toasts, [], 'each owner starts with none')
    assert.strictEqual(new ToasterHarness().count, 0)
    await a11yAudit()
  })
})

module('Integration | primitives | toast, system theme', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)
  const scheme = setupColorScheme(hooks, { system: 'dark' })

  test('@theme="system" follows the system, and its changes', async function (assert) {
    await render(<template><Toaster @theme="system" /></template>)
    toast('Themed')
    await settled()
    const toaster = new ToasterHarness()
    assert.strictEqual(toaster.theme, 'dark')
    scheme.setSystem('light')
    await settled()
    assert.strictEqual(toaster.theme, 'light')
    await a11yAudit()
  })
})
