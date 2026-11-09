import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Sheet, type SheetSide } from '@ember-joinery/ember'
import { ButtonHarness, DialogHarness, SheetHarness, tab } from '@ember-joinery/test-support'

const SIDES: SheetSide[] = ['top', 'right', 'bottom', 'left']

/** Ends the entrance animation, so the sheet is measured where it rests. */
function settle(element: Element | null): void {
  for (const animation of element?.getAnimations() ?? []) animation.finish()
}

module('Integration | components | sheet', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's parts, as sheet-*", async function (assert) {
    await render(
      <template>
        <Sheet @name="profile" as |s|>
          <Button @variant="outline" {{s.trigger}}>Open</Button>
          <s.Content>
            <s.Header>
              <s.Title>Edit profile</s.Title>
              <s.Description>Make changes to your profile here.</s.Description>
            </s.Header>
            <s.Footer>
              <Button @name="save">Save changes</Button>
              <Button @variant="outline" {{s.close}}>Close</Button>
            </s.Footer>
          </s.Content>
        </Sheet>
      </template>,
    )
    const sheet = new SheetHarness('profile')
    assert.dom(sheet.element).hasAttribute('data-test-jn', 'sheet')
    assert.dom(sheet.trigger).hasAttribute('data-slot', 'sheet-trigger')
    await sheet.open()

    assert
      .dom(sheet.content)
      .hasClass('jn-sheet-content')
      .hasAttribute('data-slot', 'sheet-content')
    assert.dom(sheet.content).hasAttribute('data-side', 'right', 'right by default')
    assert.strictEqual(sheet.side, 'right')
    assert
      .dom(sheet.overlay)
      .hasClass('jn-sheet-overlay')
      .hasAttribute('data-slot', 'sheet-overlay')
    assert.dom('[data-slot="sheet-header"]', sheet.content!).hasClass('jn-sheet-header')
    assert.dom('[data-slot="sheet-footer"]', sheet.content!).hasClass('jn-sheet-footer')
    assert.dom(sheet.title).hasClass('jn-sheet-title').hasClass('jn-font-heading')
    assert.dom(sheet.title).hasAttribute('data-slot', 'sheet-title')
    assert.dom(sheet.description).hasClass('jn-sheet-description')
    assert
      .dom(sheet.closeButton)
      .hasClass('jn-sheet-close')
      .hasAttribute('data-slot', 'sheet-close')
    assert.strictEqual(sheet.label, 'Edit profile')
    assert.true(sheet.isModal)
    assert.strictEqual(sheet.find(ButtonHarness, 'save').label, 'Save changes')
    assert.throws(
      () => new DialogHarness('profile').element,
      /is a "sheet"; this harness drives "dialog"/,
      'a DialogHarness says it is pointed at a sheet',
    )
    await a11yAudit()
  })

  test('each side puts it against that edge of the screen', async function (assert) {
    await render(
      <template>
        {{#each SIDES as |side|}}
          <Sheet @name={{side}} as |s|>
            <s.Trigger>{{side}}</s.Trigger>
            <s.Content @side={{side}}>
              <s.Header><s.Title>{{side}}</s.Title></s.Header>
            </s.Content>
          </Sheet>
        {{/each}}
      </template>,
    )
    const width = window.innerWidth
    const height = window.innerHeight
    for (const side of SIDES) {
      const sheet = new SheetHarness(side)
      await sheet.open()
      settle(sheet.content)
      const rect = sheet.content!.getBoundingClientRect()
      assert.strictEqual(sheet.side, side)
      if (side === 'right' || side === 'left') {
        assert.strictEqual(rect.height, height, `${side}: full height`)
        assert.strictEqual(rect.width, 384, `${side}: w-3/4, up to sm:max-w-sm`)
        if (side === 'right') assert.strictEqual(rect.right, width, 'against the right edge')
        else assert.strictEqual(rect.left, 0, 'against the left edge')
        const border = getComputedStyle(sheet.content!)
        assert.strictEqual(
          side === 'right' ? border.borderLeftWidth : border.borderRightWidth,
          '1px',
          `${side}: a border on its inner edge`,
        )
      } else {
        assert.strictEqual(rect.width, width, `${side}: full width`)
        if (side === 'top') assert.strictEqual(rect.top, 0, 'against the top')
        else assert.strictEqual(rect.bottom, height, 'against the bottom')
      }
      await sheet.close()
      assert.false(sheet.isOpen)
    }
    await a11yAudit()
  })

  test('its style sheet lays it out as a column, without Tailwind', async function (assert) {
    await render(
      <template>
        <Sheet @defaultOpen={{true}} as |s|>
          <s.Content>
            <s.Header>
              <s.Title>Title</s.Title>
              <s.Description>Description</s.Description>
            </s.Header>
            <s.Footer><Button>Save</Button></s.Footer>
          </s.Content>
        </Sheet>
      </template>,
    )
    const sheet = new SheetHarness()
    settle(sheet.content)
    const style = getComputedStyle(sheet.content!)
    assert.strictEqual(style.position, 'fixed')
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.flexDirection, 'column')
    assert.strictEqual(style.gap, '16px', 'gap-4')
    assert.notStrictEqual(style.boxShadow, 'none', 'shadow-lg')
    const header = getComputedStyle(sheet.content!.querySelector('[data-slot="sheet-header"]')!)
    assert.strictEqual(header.paddingTop, '16px', 'p-4')
    assert.strictEqual(header.display, 'flex')
    const footer = sheet.content!.querySelector('[data-slot="sheet-footer"]')!
    assert.strictEqual(
      Math.round(footer.getBoundingClientRect().bottom),
      window.innerHeight,
      'mt-auto: the footer sits at the bottom',
    )
    const close = getComputedStyle(sheet.closeButton!)
    assert.strictEqual(close.top, '12px', 'top-3')
    assert.strictEqual(close.right, '12px', 'end-3')
    assert.strictEqual(getComputedStyle(sheet.title!).fontSize, '16px')
    await a11yAudit()
  })

  test('keyboard and focus, and @showCloseButton', async function (assert) {
    await render(
      <template>
        <Sheet as |s|>
          <Button @variant="outline" {{s.trigger}}>Open Sheet</Button>
          <s.Content @showCloseButton={{false}}>
            <s.Header>
              <s.Title>No Close Button</s.Title>
              <s.Description>Click outside to close.</s.Description>
            </s.Header>
            <s.Footer>
              <Button @name="first">First</Button>
              <Button @name="second">Second</Button>
            </s.Footer>
          </s.Content>
        </Sheet>
      </template>,
    )
    const sheet = new SheetHarness()
    await sheet.open()
    assert.strictEqual(sheet.closeButton, null)
    assert.true(sheet.find(ButtonHarness, 'first').isFocused)
    await tab()
    await tab()
    assert.true(sheet.find(ButtonHarness, 'first').isFocused, 'Tab goes round inside')
    await sheet.pressOutside()
    assert.false(sheet.isOpen, 'a press outside closes it')
    assert.dom(sheet.trigger).isFocused()
    await a11yAudit()
  })

  test('RTL: a left sheet stays on the left, its close button at its start', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Sheet @defaultOpen={{true}} as |s|>
            <s.Content @side="left">
              <s.Header><s.Title>تعديل الملف الشخصي</s.Title></s.Header>
            </s.Content>
          </Sheet>
        </DirectionProvider>
      </template>,
    )
    const sheet = new SheetHarness()
    settle(sheet.content)
    assert.strictEqual(sheet.content!.getBoundingClientRect().left, 0, 'the side is physical')
    assert.strictEqual(getComputedStyle(sheet.closeButton!).left, '12px', 'end-3, on the left')
    assert.strictEqual(
      getComputedStyle(sheet.content!).borderLeftWidth,
      '1px',
      "border-e: its inline end, as upstream's right-to-left build has it",
    )
    await a11yAudit()
  })
})
