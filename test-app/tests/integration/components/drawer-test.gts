import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Drawer, type DrawerDirection } from '@ember-joinery/ember'
import { ButtonHarness, DialogHarness, DrawerHarness, tab } from '@ember-joinery/test-support'

const DIRECTIONS: DrawerDirection[] = ['top', 'right', 'bottom', 'left']
const SNAP_POINTS = [0.5, 1]

module('Integration | components | drawer', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's parts, as drawer-*", async function (assert) {
    await render(
      <template>
        <Drawer @name="goal" as |d|>
          <Button @variant="outline" {{d.trigger}}>Open Drawer</Button>
          <d.Content>
            <d.Header>
              <d.Title>Move Goal</d.Title>
              <d.Description>Set your daily activity goal.</d.Description>
            </d.Header>
            <d.Footer>
              <Button @name="submit">Submit</Button>
              <Button @variant="outline" {{d.close}}>Cancel</Button>
            </d.Footer>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness('goal')
    assert.dom(drawer.element).hasAttribute('data-test-jn', 'drawer')
    assert.dom(drawer.trigger).hasAttribute('data-slot', 'drawer-trigger')
    assert.strictEqual(new ButtonHarness({ within: drawer }).text, 'Open Drawer')
    await drawer.open()

    assert
      .dom(drawer.content)
      .hasClass('jn-drawer-content')
      .hasClass('group/drawer-content')
      .hasAttribute('data-slot', 'drawer-content')
      .hasAttribute('data-vaul-drawer-direction', 'bottom')
    assert.strictEqual(drawer.direction, 'bottom')
    assert
      .dom(drawer.overlay)
      .hasClass('jn-drawer-overlay')
      .hasAttribute('data-slot', 'drawer-overlay')
    assert.dom(drawer.handle).hasClass('jn-drawer-handle')
    assert.strictEqual(drawer.content!.firstElementChild, drawer.handle, 'the handle comes first')
    assert.dom('[data-slot="drawer-header"]', drawer.content!).hasClass('jn-drawer-header')
    assert.dom('[data-slot="drawer-footer"]', drawer.content!).hasClass('jn-drawer-footer')
    assert.dom(drawer.title).hasClass('jn-drawer-title').hasClass('jn-font-heading')
    assert.dom(drawer.title).hasAttribute('data-slot', 'drawer-title')
    assert.dom(drawer.description).hasClass('jn-drawer-description')
    assert.dom(drawer.description).hasAttribute('data-slot', 'drawer-description')
    assert.strictEqual(drawer.closeButton, null, 'no close button in the corner, as upstream')
    assert.strictEqual(drawer.label, 'Move Goal')
    assert.true(drawer.isModal)
    assert.strictEqual(drawer.find(ButtonHarness, 'submit').label, 'Submit')
    assert.throws(
      () => new DialogHarness('goal').element,
      /is a "drawer"; this harness drives "dialog"/,
    )
    await a11yAudit()
  })

  test('its style sheet and vaul’s lay it out and slide it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Drawer @defaultOpen={{true}} as |d|>
          <d.Content>
            <d.Header>
              <d.Title>Title</d.Title>
              <d.Description>Description</d.Description>
            </d.Header>
            <d.Footer><Button>Submit</Button></d.Footer>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    drawer.finishAnimations()
    const content = drawer.content!
    const style = getComputedStyle(content)
    assert.strictEqual(style.position, 'fixed')
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.flexDirection, 'column')
    assert.strictEqual(style.borderTopWidth, '1px', 'border-t')
    assert.strictEqual(style.borderTopLeftRadius, style.borderTopRightRadius, 'rounded-t-xl')
    assert.notStrictEqual(style.borderTopLeftRadius, '0px')
    assert.strictEqual(style.borderBottomLeftRadius, '0px')
    assert.strictEqual(style.touchAction, 'none', "vaul's: the drawer takes the finger")
    assert.ok(style.transitionDuration.includes('0.5s'), "vaul's transition")
    const rect = content.getBoundingClientRect()
    assert.strictEqual(Math.round(rect.bottom), window.innerHeight, 'against the bottom')
    assert.strictEqual(Math.round(rect.width), window.innerWidth, 'full width')
    assert.ok(rect.height <= window.innerHeight * 0.8 + 1, 'max-h-[80vh]')

    const handle = getComputedStyle(drawer.handle!)
    assert.strictEqual(handle.display, 'block', 'the handle shows, on a bottom drawer')
    assert.strictEqual(handle.width, '100px')
    assert.strictEqual(handle.height, '4px')
    const header = getComputedStyle(content.querySelector('[data-slot="drawer-header"]')!)
    assert.strictEqual(header.textAlign, 'center', 'centred, on a bottom drawer')
    assert.strictEqual(header.paddingTop, '16px', 'p-4')
    const footer = getComputedStyle(content.querySelector('[data-slot="drawer-footer"]')!)
    assert.strictEqual(footer.flexDirection, 'column')
    assert.strictEqual(footer.gap, '8px', 'gap-2')
    assert.strictEqual(getComputedStyle(drawer.title!).fontSize, '16px', 'text-base')
    assert.strictEqual(getComputedStyle(drawer.description!).fontSize, '14px', 'text-sm')
    const overlay = getComputedStyle(drawer.overlay!)
    assert.strictEqual(overlay.position, 'fixed')
    assert.strictEqual(overlay.top, '0px')
    assert.notStrictEqual(overlay.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-black/10')
    await a11yAudit()
  })

  test('each direction puts it against that edge, with its border and corners inside', async function (assert) {
    await render(
      <template>
        {{#each DIRECTIONS as |direction|}}
          <Drawer @name={{direction}} @direction={{direction}} as |d|>
            <d.Trigger>{{direction}}</d.Trigger>
            <d.Content>
              <d.Header><d.Title>{{direction}}</d.Title></d.Header>
            </d.Content>
          </Drawer>
        {{/each}}
      </template>,
    )
    const width = window.innerWidth
    const height = window.innerHeight
    for (const direction of DIRECTIONS) {
      const drawer = new DrawerHarness(direction)
      await drawer.open()
      assert
        .dom(drawer.content)
        .hasStyle(
          { animationName: `slideFrom${direction[0]!.toUpperCase()}${direction.slice(1)}` },
          `${direction}: slides in from its edge`,
        )
      drawer.finishAnimations()
      const rect = drawer.content!.getBoundingClientRect()
      const style = getComputedStyle(drawer.content!)
      const handle = getComputedStyle(drawer.handle!).display
      assert.strictEqual(handle, direction === 'bottom' ? 'block' : 'none', `${direction}: handle`)
      if (direction === 'left' || direction === 'right') {
        assert.strictEqual(Math.round(rect.height), height, `${direction}: full height`)
        assert.strictEqual(Math.round(rect.width), 384, `${direction}: w-3/4, up to sm:max-w-sm`)
        if (direction === 'right') assert.strictEqual(Math.round(rect.right), width)
        else assert.strictEqual(rect.left, 0)
        const inner = direction === 'right' ? style.borderLeftWidth : style.borderRightWidth
        assert.strictEqual(inner, '1px', `${direction}: a border on its inner edge`)
      } else {
        assert.strictEqual(Math.round(rect.width), width, `${direction}: full width`)
        if (direction === 'top') {
          assert.strictEqual(rect.top, 0)
          assert.strictEqual(style.borderBottomWidth, '1px')
        } else {
          assert.strictEqual(Math.round(rect.bottom), height)
        }
        const header = drawer.content!.querySelector('[data-slot="drawer-header"]')!
        assert.strictEqual(getComputedStyle(header).textAlign, 'center', `${direction}: centred`)
      }
      await drawer.close()
      assert.false(drawer.isOpen)
    }
    await a11yAudit()
  })

  test('keyboard and focus: in to the drawer, round inside, out with Escape', async function (assert) {
    await render(
      <template>
        <Drawer as |d|>
          <Button @variant="outline" {{d.trigger}}>Open Drawer</Button>
          <d.Content>
            <d.Header><d.Title>Move Goal</d.Title></d.Header>
            <d.Footer>
              <Button @name="submit">Submit</Button>
              <Button @name="cancel" @variant="outline" {{d.close}}>Cancel</Button>
            </d.Footer>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    assert.dom(drawer.trigger).hasTagName('button', 'a native button: Enter and Space press it')
    await drawer.open()
    assert.true(drawer.isOpen)
    assert.dom(drawer.content).isFocused('focus is on the drawer')
    await tab()
    assert.true(drawer.find(ButtonHarness, 'submit').isFocused)
    await tab()
    assert.true(drawer.find(ButtonHarness, 'cancel').isFocused)
    await tab()
    assert.true(drawer.find(ButtonHarness, 'submit').isFocused, 'Tab goes round inside')
    await drawer.pressEscape()
    assert.false(drawer.isOpen, 'Escape closes it')
    assert.dom(drawer.trigger).isFocused('back on the trigger')
    await a11yAudit()
  })

  test('a drag down past a quarter closes it, as the user expects of a sheet on a phone', async function (assert) {
    await render(
      <template>
        <Drawer as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content>
            <d.Header><d.Title>Drag</d.Title></d.Header>
            <d.Footer><Button>Submit</Button></d.Footer>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.afterOpening()
    const height = drawer.content!.getBoundingClientRect().height
    await drawer.drag(height * 0.15)
    assert.true(drawer.isOpen, 'a little: it springs back')
    await drawer.drag(height * 0.5)
    assert.false(drawer.isOpen, 'half of it: it closes')
    await a11yAudit()
  })

  test('RTL: a left drawer is at the inline start, on the right, its border inside', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Drawer @direction="left" @defaultOpen={{true}} as |d|>
            <d.Content>
              <d.Header>
                <d.Title>نقل الهدف</d.Title>
                <d.Description>حدد هدف نشاطك اليومي.</d.Description>
              </d.Header>
            </d.Content>
          </Drawer>
        </DirectionProvider>
      </template>,
    )
    const drawer = new DrawerHarness()
    drawer.finishAnimations()
    const rect = drawer.content!.getBoundingClientRect()
    assert.strictEqual(Math.round(rect.right), window.innerWidth, 'start-0: on the right')
    assert.strictEqual(drawer.side, 'right')
    assert.strictEqual(
      getComputedStyle(drawer.content!).borderLeftWidth,
      '1px',
      "border-e: its inline end, as upstream's right-to-left build has it",
    )
    const header = drawer.content!.querySelector('[data-slot="drawer-header"]')!
    assert.strictEqual(getComputedStyle(header).textAlign, 'start')
    assert.strictEqual(getComputedStyle(header).direction, 'rtl')
    await a11yAudit()
  })

  test('RTL: it slides in and out from the edge it is on', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Drawer @direction="right" as |d|>
            <d.Trigger>فتح</d.Trigger>
            <d.Content><d.Header><d.Title>الدرج</d.Title></d.Header></d.Content>
          </Drawer>
        </DirectionProvider>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    assert.dom(drawer.content).hasStyle({ animationName: 'slideFromLeft' })
    drawer.finishAnimations()
    assert.strictEqual(drawer.content!.getBoundingClientRect().left, 0, 'end-0: on the left')
    await a11yAudit()
  })

  test('snap points, and a nested drawer, through the styled one', async function (assert) {
    await render(
      <template>
        <Drawer @name="outer" @snapPoints={{SNAP_POINTS}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content class="h-full">
            <d.Header><d.Title>Outer</d.Title></d.Header>
            <d.Nested @name="inner" as |n|>
              <Button {{n.trigger}}>More</Button>
              <n.Content><n.Header><n.Title>Inner</n.Title></n.Header></n.Content>
            </d.Nested>
          </d.Content>
        </Drawer>
      </template>,
    )
    const outer = new DrawerHarness('outer')
    await outer.open()
    assert.strictEqual(outer.activeSnapPoint, '0.5')
    assert.dom(outer.content).hasAttribute('data-vaul-snap-points', 'true')
    const inner = new DrawerHarness('inner')
    await inner.open()
    assert.true(inner.isOpen)
    assert.dom(inner.content).hasClass('jn-drawer-content', 'styled as the outer one')
    assert.ok(outer.content!.style.transform.startsWith('scale('), 'the outer one steps back')
    await inner.pressEscape()
    assert.false(inner.isOpen)
    assert.true(outer.isOpen)
    await a11yAudit()
  })
})
