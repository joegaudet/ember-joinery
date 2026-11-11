import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Bluetooth } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { AlertDialog, Button, Icon, type AlertDialogSize } from '@ember-joinery/ember'
import { AlertDialogHarness, ButtonHarness, pressOutside, tab } from '@ember-joinery/test-support'

/** Ends the entrance animation, so it is measured where it rests. */
function settle(element: Element | null): void {
  for (const animation of element?.getAnimations() ?? []) animation.finish()
}

const SIZES: AlertDialogSize[] = ['default', 'sm']

module('Integration | components | alert-dialog', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's parts, with Cancel and Action as Buttons", async function (assert) {
    await render(
      <template>
        <AlertDialog @name="delete" as |a|>
          <Button @variant="outline" {{a.trigger}}>Show Dialog</Button>
          <a.Content>
            <a.Header>
              <a.Media><Icon @icon={{Bluetooth}} /></a.Media>
              <a.Title>Are you absolutely sure?</a.Title>
              <a.Description>This action cannot be undone.</a.Description>
            </a.Header>
            <a.Footer>
              <a.Cancel @name="cancel">Cancel</a.Cancel>
              <a.Action @name="continue">Continue</a.Action>
            </a.Footer>
          </a.Content>
        </AlertDialog>
      </template>,
    )
    const alert = new AlertDialogHarness('delete')
    assert.dom(alert.element).hasAttribute('data-test-jn', 'alert-dialog')
    assert.dom(alert.trigger).hasAttribute('data-slot', 'alert-dialog-trigger')
    await alert.open()

    assert.strictEqual(alert.role, 'alertdialog')
    assert
      .dom(alert.content)
      .hasClass('jn-alert-dialog-content')
      .hasClass('group/alert-dialog-content')
      .hasAttribute('data-size', 'default')
    assert.dom(alert.overlay).hasClass('jn-alert-dialog-overlay')
    assert
      .dom('[data-slot="alert-dialog-header"]', alert.content!)
      .hasClass('jn-alert-dialog-header')
    assert
      .dom('[data-slot="alert-dialog-footer"]', alert.content!)
      .hasClass('jn-alert-dialog-footer')
    assert.dom('[data-slot="alert-dialog-media"]', alert.content!).hasClass('jn-alert-dialog-media')
    assert.dom(alert.title).hasClass('jn-alert-dialog-title').hasClass('jn-font-heading')
    assert.dom(alert.description).hasClass('jn-alert-dialog-description')

    const cancel = alert.find(ButtonHarness, 'cancel')
    const action = alert.find(ButtonHarness, 'continue')
    assert.strictEqual(cancel.variant, 'outline', 'Cancel is an outline button')
    assert.strictEqual(action.variant, 'default', 'Action is a default one')
    assert
      .dom(action.element)
      .hasClass('jn-alert-dialog-action')
      .hasAttribute('data-slot', 'alert-dialog-action')
    assert
      .dom(cancel.element)
      .hasClass('jn-alert-dialog-cancel')
      .hasAttribute('data-slot', 'alert-dialog-cancel')
    assert.strictEqual(alert.closeButton, null, 'no close button in the corner')
    await a11yAudit()
  })

  test('focus starts on Cancel, Tab stays inside, and Escape closes it', async function (assert) {
    await render(
      <template>
        <AlertDialog as |a|>
          <a.Trigger>Delete</a.Trigger>
          <a.Content>
            <a.Header>
              <a.Title>Delete?</a.Title>
              <a.Description>This cannot be undone.</a.Description>
            </a.Header>
            <a.Footer>
              <a.Cancel>Cancel</a.Cancel>
              <a.Action>Delete</a.Action>
            </a.Footer>
          </a.Content>
        </AlertDialog>
      </template>,
    )
    const alert = new AlertDialogHarness()
    await alert.open()
    assert.dom(alert.cancelButton).isFocused()
    await tab()
    assert.dom(alert.actionButton).isFocused()
    await tab()
    assert.dom(alert.cancelButton).isFocused('Tab goes round')
    await alert.pressEscape()
    assert.false(alert.isOpen)
    assert.dom(alert.trigger).isFocused()
    await a11yAudit()
  })

  test('a press outside keeps it; its buttons close it, and the action runs', async function (assert) {
    let deleted = 0
    const remove = () => deleted++
    await render(
      <template>
        <AlertDialog as |a|>
          <a.Trigger>Delete</a.Trigger>
          <a.Content>
            <a.Header>
              <a.Title>Delete chat?</a.Title>
              <a.Description>This cannot be undone.</a.Description>
            </a.Header>
            <a.Footer>
              <a.Cancel>Cancel</a.Cancel>
              <a.Action @variant="destructive" {{on "click" remove}}>Delete</a.Action>
            </a.Footer>
          </a.Content>
        </AlertDialog>
      </template>,
    )
    const alert = new AlertDialogHarness()
    await alert.open()
    await alert.pressOutside()
    assert.true(alert.isOpen, 'a press on the overlay keeps it')
    await pressOutside()
    assert.true(alert.isOpen)
    assert.dom(alert.actionButton).hasClass('jn-button-variant-destructive')

    await alert.cancel()
    assert.false(alert.isOpen)
    assert.strictEqual(deleted, 0)
    await alert.open()
    await alert.confirm()
    assert.false(alert.isOpen)
    assert.strictEqual(deleted, 1)
    await a11yAudit()
  })

  test('its style sheet sizes it, and @size="sm" narrows it and puts its buttons side by side', async function (assert) {
    await render(
      <template>
        {{#each SIZES as |size|}}
          <AlertDialog @name={{size}} as |a|>
            <a.Trigger>{{size}}</a.Trigger>
            <a.Content @size={{size}}>
              <a.Header>
                <a.Media><Icon @icon={{Bluetooth}} /></a.Media>
                <a.Title>Allow accessory to connect?</a.Title>
                <a.Description>Do you want to allow the USB accessory?</a.Description>
              </a.Header>
              <a.Footer>
                <a.Cancel>Don't allow</a.Cancel>
                <a.Action>Allow</a.Action>
              </a.Footer>
            </a.Content>
          </AlertDialog>
        {{/each}}
      </template>,
    )
    const normal = new AlertDialogHarness('default')
    await normal.open()
    settle(normal.content)
    let style = getComputedStyle(normal.content!)
    assert.strictEqual(style.position, 'fixed')
    assert.strictEqual(style.display, 'grid')
    assert.strictEqual(style.maxWidth, '384px', 'data-[size=default]:sm:max-w-sm')
    assert.strictEqual(style.paddingTop, '16px')
    const header = normal.content!.querySelector('[data-slot="alert-dialog-header"]')!
    assert.strictEqual(getComputedStyle(header).textAlign, 'start', 'at the start, from sm up')
    const media = normal.content!.querySelector('[data-slot="alert-dialog-media"]')!
    assert.strictEqual(getComputedStyle(media).width, '40px', 'size-10')
    assert.strictEqual(
      getComputedStyle(media.querySelector('svg')!).width,
      '24px',
      'its icon: size-6',
    )
    const footer = getComputedStyle(
      normal.content!.querySelector('[data-slot="alert-dialog-footer"]')!,
    )
    assert.strictEqual(footer.display, 'flex')
    assert.strictEqual(footer.flexDirection, 'row')
    assert.strictEqual(footer.justifyContent, 'flex-end')
    await normal.close()

    const small = new AlertDialogHarness('sm')
    await small.open()
    settle(small.content)
    style = getComputedStyle(small.content!)
    assert.dom(small.content).hasAttribute('data-size', 'sm')
    assert.strictEqual(style.maxWidth, '320px', 'data-[size=sm]:max-w-xs')
    const smallHeader = small.content!.querySelector('[data-slot="alert-dialog-header"]')!
    assert.strictEqual(getComputedStyle(smallHeader).textAlign, 'center', 'centred')
    const smallFooter = getComputedStyle(
      small.content!.querySelector('[data-slot="alert-dialog-footer"]')!,
    )
    assert.strictEqual(smallFooter.display, 'grid', 'group-data-[size=sm]:grid')
    assert.strictEqual(
      smallFooter.gridTemplateColumns.split(' ').length,
      2,
      'grid-cols-2: the buttons side by side',
    )
    await a11yAudit()
  })

  test('RTL: the header starts on the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <AlertDialog @defaultOpen={{true}} as |a|>
            <a.Content>
              <a.Header>
                <a.Title>هل أنت متأكد تمامًا؟</a.Title>
                <a.Description>لا يمكن التراجع عن هذا الإجراء.</a.Description>
              </a.Header>
              <a.Footer>
                <a.Cancel>إلغاء</a.Cancel>
                <a.Action>متابعة</a.Action>
              </a.Footer>
            </a.Content>
          </AlertDialog>
        </DirectionProvider>
      </template>,
    )
    const alert = new AlertDialogHarness()
    settle(alert.content)
    const title = alert.title!.getBoundingClientRect()
    const content = alert.content!.getBoundingClientRect()
    assert.ok(
      Math.abs(content.right - 16 - title.right) <= 1,
      'text-start: the title sits against the right padding',
    )
    const [cancel, action] = [alert.cancelButton, alert.actionButton].map(b =>
      b.getBoundingClientRect(),
    )
    assert.ok(cancel!.left > action!.left, 'the footer row runs right to left: Cancel first')
    await a11yAudit()
  })
})
