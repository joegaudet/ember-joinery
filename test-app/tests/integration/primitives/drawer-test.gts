import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, rerender, settled, waitUntil } from '@ember/test-helpers'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Drawer, type SnapPoint } from '@ember-joinery/primitives/drawer'
import {
  DialogHarness,
  DrawerHarness,
  pressEscape,
  pressOutside,
  tab,
} from '@ember-joinery/test-support'

/** Lays a headless drawer out against its edge, as an app's own CSS would. */
const PanelStyles = <template>
  <style>
    .panel {
      position: fixed;
      margin: 0;
      padding: 0;
      border: 0;
      background: white;
      color: black;
    }
    .panel[data-vaul-drawer-direction="bottom"] {
      inset: auto 0 0 0;
      height: 300px;
    }
    .panel[data-vaul-drawer-direction="top"] {
      inset: 0 0 auto 0;
      height: 300px;
    }
    .panel[data-vaul-drawer-direction="left"] {
      inset-block: 0;
      inset-inline: 0 auto;
      width: 300px;
    }
    .panel[data-vaul-drawer-direction="right"] {
      inset-block: 0;
      inset-inline: auto 0;
      width: 300px;
    }
    .panel.tall {
      height: 100vh;
    }
    .shade {
      position: fixed;
      inset: 0;
      background: rgb(0 0 0 / 0.4);
    }
    .scroller {
      height: 100px;
      overflow: auto;
    }
    .scroller > div {
      height: 400px;
    }
  </style>
</template>

class State {
  @tracked open = false
  @tracked snapPoint: SnapPoint | null = 0.25
  changes: unknown[] = []
  setOpen = (open: boolean) => {
    this.changes.push(open)
    this.open = open
  }
  setSnapPoint = (snapPoint: SnapPoint | null) => {
    this.changes.push(snapPoint)
    this.snapPoint = snapPoint
  }
}

const wait = (ms: number) => new Promise<void>(resolve => setTimeout(resolve, ms))

/** The `scale()` an element's inline transform starts with, or `NaN`. */
function scaleOf(element: HTMLElement): number {
  return Number(/^scale\(([\d.]+)\)/.exec(element.style.transform)?.[1] ?? NaN)
}

module('Integration | primitives | drawer', function (hooks) {
  setupRenderingTest(hooks)

  test("closed, it renders its trigger, as a Dialog's, and no box of its own", async function (assert) {
    await render(
      <template>
        <Drawer @name="goal" as |d|>
          <d.Trigger>Open Drawer</d.Trigger>
          <d.Overlay />
          <d.Content><d.Title>Move Goal</d.Title></d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness('goal')
    assert.strictEqual(getComputedStyle(drawer.element).display, 'contents', 'no box')
    assert.dom(drawer.element).hasAttribute('data-test-jn', 'drawer')
    assert
      .dom(drawer.trigger)
      .hasTagName('button')
      .hasAttribute('aria-haspopup', 'dialog')
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('data-slot', 'drawer-trigger')
    assert.false(drawer.isOpen)
    assert.strictEqual(drawer.content, null)
    assert.throws(
      () => new DialogHarness('goal').element,
      /is a "drawer"; this harness drives "dialog"/,
      'a DialogHarness says it is pointed at a drawer',
    )
    await a11yAudit()
  })

  test("open, its content is a modal dialog in the top layer, with vaul's attributes", async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer @name="goal" as |d|>
          <d.Trigger>Open Drawer</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel">
            <d.Handle />
            <d.Title>Move Goal</d.Title>
            <d.Description>Set your daily activity goal.</d.Description>
            <button type="button">Submit</button>
            <d.Close>Cancel</d.Close>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness('goal')
    await drawer.open()

    assert.true(drawer.isOpen)
    assert.true(drawer.isModal)
    assert.true(drawer.isInTopLayer)
    assert.strictEqual(drawer.role, 'dialog')
    assert.strictEqual(drawer.label, 'Move Goal')
    assert.strictEqual(drawer.descriptionText, 'Set your daily activity goal.')
    assert
      .dom(drawer.content)
      .hasAttribute('data-slot', 'drawer-content')
      .hasAttribute('data-vaul-drawer', '')
      .hasAttribute('data-vaul-drawer-direction', 'bottom', 'from the bottom by default')
      .hasAttribute('data-vaul-snap-points', 'false')
      .hasAttribute('data-vaul-delayed-snap-points', 'false')
      .hasAttribute('data-vaul-animate', 'true')
      .hasAttribute('data-state', 'open')
      .doesNotHaveAttribute('data-snap-point', 'no snap points')
    assert.strictEqual(drawer.direction, 'bottom')
    assert
      .dom(drawer.overlay)
      .hasAttribute('data-slot', 'drawer-overlay')
      .hasAttribute('data-vaul-overlay', '')
      .hasAttribute('data-vaul-snap-points-overlay', 'true')
    assert
      .dom(drawer.handle)
      .hasAttribute('data-vaul-handle', '')
      .hasAttribute('aria-hidden', 'true')
      .hasAttribute('data-vaul-drawer-visible', 'true')
    assert.dom('[data-vaul-handle-hitarea]', drawer.handle!).exists()
    assert
      .dom(drawer.content)
      .hasStyle({ animationName: 'slideFromBottom' }, "vaul's CSS slides it in")
    assert.dom(drawer.content).isFocused('focus goes to the drawer itself, as vaul leaves it')
    await tab()
    assert.dom('button', drawer.content!).isFocused('Tab goes on to its first button')
    await a11yAudit()

    await click(drawer.part('close'))
    assert.false(drawer.isOpen, 'its Close closes it')
    assert.strictEqual(drawer.content, null, 'gone once it has slid out')
    assert.dom(drawer.trigger).isFocused('focus is back on the trigger')
    await a11yAudit()
  })

  test('@autoFocus moves focus to its first focusable element, as a Dialog does', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer @autoFocus={{true}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content class="panel">
            <d.Title>Profile</d.Title>
            <input aria-label="Name" />
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    assert.dom('input', drawer.content!).isFocused()
    await a11yAudit()
  })

  test('Escape and a press on the overlay close it; @open and @onOpenChange control it', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PanelStyles />
        <Drawer @open={{state.open}} @onOpenChange={{state.setOpen}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel"><d.Title>Controlled</d.Title></d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    assert.deepEqual(state.changes, [true])
    await drawer.pressEscape()
    assert.false(drawer.isOpen, 'Escape closes it')
    await drawer.open()
    await drawer.pressOutside()
    assert.false(drawer.isOpen, 'a press on the overlay closes it')
    assert.deepEqual(state.changes, [true, false, true, false])

    state.open = true
    await settled()
    assert.true(drawer.isOpen, 'and @open opens it')
    await a11yAudit()
  })

  test('@dismissible={{false}}: nothing of its own closes it, but you can', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer @dismissible={{false}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel">
            <d.Title>Stays</d.Title>
            <d.Close>Close</d.Close>
            <button type="button" data-done {{on "click" (fn d.setOpen false)}}>Done</button>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.afterOpening()
    await drawer.pressEscape()
    assert.true(drawer.isOpen, 'not Escape')
    await drawer.pressOutside()
    assert.true(drawer.isOpen, 'not a press outside')
    await click(drawer.part('close'))
    assert.true(drawer.isOpen, 'not its Close')
    await drawer.drag(250)
    assert.true(drawer.isOpen, 'not a drag')
    assert.strictEqual(drawer.offset, 0, "and it doesn't move")
    await click('[data-done]')
    assert.false(drawer.isOpen, 'setOpen closes it')
    await a11yAudit()
  })

  test('a drag down moves it with the pointer, and a long one closes it', async function (assert) {
    const drags: number[] = []
    const releases: boolean[] = []
    const onDrag = (_: PointerEvent, percentage: number) => drags.push(percentage)
    const onRelease = (_: PointerEvent, open: boolean) => releases.push(open)
    await render(
      <template>
        <PanelStyles />
        <Drawer @onDrag={{onDrag}} @onRelease={{onRelease}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel"><d.Title>Drag me</d.Title></d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.afterOpening()

    await drawer.drag(40)
    assert.true(drawer.isOpen, 'a short, slow drag leaves it open')
    assert.deepEqual(releases, [true])
    assert.ok(drags.length > 0, 'onDrag heard it')
    assert.ok(
      Math.abs(drags.at(-1)! - 40 / 300) < 0.01,
      'with how far toward closed (40 of its 300px)',
    )
    drawer.finishAnimations()
    assert.strictEqual(drawer.offset, 0, 'and it springs back')
    assert.dom(drawer.overlay).hasStyle({ opacity: '1' })

    await drawer.drag(120)
    assert.false(drawer.isOpen, 'past a quarter of its height, it closes')
    assert.deepEqual(releases, [true, false])
    assert.strictEqual(drawer.content, null)
    await a11yAudit()
  })

  test('while dragged it follows the pointer, fades its overlay, and has vaul-dragging', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel"><d.Title>Drag me</d.Title></d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.afterOpening()
    const content = drawer.content!
    const rect = content.getBoundingClientRect()
    const init = (y: number) => ({
      bubbles: true,
      clientX: rect.left + 10,
      clientY: y,
      pointerId: 1,
      pointerType: 'mouse',
      isPrimary: true,
    })
    content.dispatchEvent(new PointerEvent('pointerdown', init(rect.top + 10)))
    content.dispatchEvent(new PointerEvent('pointermove', init(rect.top + 40)))
    content.dispatchEvent(new PointerEvent('pointermove', init(rect.top + 70)))
    await settled()
    assert.true(drawer.isDragging)
    assert.dom(content).hasClass('vaul-dragging')
    assert.strictEqual(drawer.offset, 60, 'moved down with the pointer')
    assert.dom(drawer.overlay).hasStyle({ opacity: String(1 - 60 / 300) })
    content.dispatchEvent(new PointerEvent('pointerup', init(rect.top + 70)))
    await settled()
    assert.false(drawer.isDragging)
    assert.dom(content).doesNotHaveClass('vaul-dragging')
    await a11yAudit()
  })

  test('a fast flick closes it, and a drag the other way springs back', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content class="panel"><d.Title>Flick me</d.Title></d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.afterOpening()
    await drawer.drag(-60)
    assert.true(drawer.isOpen, 'dragged up, it stays open')
    drawer.finishAnimations()
    assert.strictEqual(drawer.offset, 0)

    await drawer.swipe(40)
    assert.false(drawer.isOpen, 'a flick, short but fast, closes it')
    await a11yAudit()
  })

  test('for a moment after it opens, a drawer from the bottom lets its content scroll instead', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer @defaultOpen={{true}} as |d|>
          <d.Content class="panel"><d.Title>Just opened</d.Title></d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    assert.dom(drawer.content).hasAttribute('data-vaul-animate', 'false', 'no slide in')
    await drawer.drag(200, { duration: 200 })
    assert.true(drawer.isOpen, 'too soon to drag')
    await a11yAudit()
  })

  test('each direction drags toward its own edge', async function (assert) {
    const DIRECTIONS = ['top', 'right', 'left'] as const
    await render(
      <template>
        <PanelStyles />
        {{#each DIRECTIONS as |direction|}}
          <Drawer @name={{direction}} @direction={{direction}} as |d|>
            <d.Trigger>{{direction}}</d.Trigger>
            <d.Content class="panel"><d.Title>{{direction}}</d.Title></d.Content>
          </Drawer>
        {{/each}}
      </template>,
    )
    for (const direction of DIRECTIONS) {
      const drawer = new DrawerHarness(direction)
      await drawer.open()
      await drawer.afterOpening()
      assert.strictEqual(drawer.direction, direction)
      assert.dom(drawer.content).hasStyle({
        animationName: `slideFrom${direction[0]!.toUpperCase()}${direction.slice(1)}`,
      })
      await drawer.drag(40)
      assert.true(drawer.isOpen, `${direction}: a short drag leaves it`)
      await drawer.drag(120)
      assert.false(drawer.isOpen, `${direction}: a long one toward its edge closes it`)
    }
    await a11yAudit()
  })

  test('RTL: a left drawer is at the inline start, on the right, and drags right to close', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <DirectionProvider @dir="rtl">
          <Drawer @direction="left" as |d|>
            <d.Trigger>فتح</d.Trigger>
            <d.Content class="panel"><d.Title>الدرج</d.Title></d.Content>
          </Drawer>
        </DirectionProvider>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    assert
      .dom(drawer.content)
      .hasStyle({ animationName: 'slideFromRight' }, 'it slides in from the right')
    await drawer.afterOpening()
    assert.strictEqual(drawer.side, 'right')
    assert.strictEqual(
      Math.round(drawer.content!.getBoundingClientRect().right),
      window.innerWidth,
      'against the right edge',
    )
    await drawer.drag(40)
    assert.true(drawer.isOpen)
    assert.ok(drawer.offset >= 0, 'it went right, not left')
    await drawer.drag(120)
    assert.false(drawer.isOpen, 'dragged right, it closes')
    await a11yAudit()
  })

  test('snap points: it rests at the first, moves to others, and fades its overlay in at the last', async function (assert) {
    const state = new State()
    const SNAP_POINTS = [0.25, '200px', 1]
    await render(
      <template>
        <PanelStyles />
        <Drawer
          @snapPoints={{SNAP_POINTS}}
          @activeSnapPoint={{state.snapPoint}}
          @onActiveSnapPointChange={{state.setSnapPoint}}
          as |d|
        >
          <d.Trigger>Open</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel tall">
            <d.Handle />
            <d.Title>Snap</d.Title>
            <button type="button" data-middle {{on "click" (fn d.setActiveSnapPoint "200px")}}>
              200px
            </button>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    const height = window.innerHeight
    await drawer.open()
    assert.dom(drawer.content).hasAttribute('data-vaul-snap-points', 'true')
    await waitUntil(() => drawer.content!.getAttribute('data-vaul-delayed-snap-points') === 'true')
    assert.strictEqual(drawer.activeSnapPoint, '0.25')
    assert.strictEqual(
      drawer.content!.style.getPropertyValue('--snap-point-height'),
      `${height - 0.25 * height}px`,
      'its first snap point, a quarter of the screen up',
    )
    drawer.finishAnimations()
    assert.strictEqual(Math.round(drawer.offset), Math.round(height * 0.75))
    assert
      .dom(drawer.overlay)
      .hasAttribute('data-vaul-snap-points-overlay', 'false', 'no overlay below the last')

    await click('[data-middle]')
    assert.strictEqual(state.snapPoint, '200px')
    assert.strictEqual(drawer.activeSnapPoint, '200px')
    drawer.finishAnimations()
    assert.strictEqual(Math.round(drawer.offset), height - 200, '200px of it showing')

    await drawer.tapHandle()
    assert.strictEqual(drawer.activeSnapPoint, '1', 'a tap on the handle goes to the next')
    drawer.finishAnimations()
    assert.strictEqual(drawer.offset, 0, 'all of it')
    assert.dom(drawer.overlay).hasAttribute('data-vaul-snap-points-overlay', 'true')
    assert.dom(drawer.overlay).hasStyle({ opacity: '1' }, 'the overlay, from the last on')

    state.snapPoint = 0.25
    await settled()
    drawer.finishAnimations()
    assert.strictEqual(
      Math.round(drawer.offset),
      Math.round(height * 0.75),
      '@activeSnapPoint moves it',
    )
    await a11yAudit()
  })

  test('snap points: a slow drag lets go at the nearest, and the handle closes it after the last', async function (assert) {
    const SNAP_POINTS = [0.5, 1]
    await render(
      <template>
        <PanelStyles />
        <Drawer @snapPoints={{SNAP_POINTS}} @defaultActiveSnapPoint={{1}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel tall">
            <d.Handle />
            <d.Title>Snap</d.Title>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    const height = window.innerHeight
    await drawer.open()
    await drawer.afterOpening()
    assert.strictEqual(drawer.activeSnapPoint, '1')

    await drawer.drag(height * 0.4, { duration: 1500 })
    assert.true(drawer.isOpen)
    assert.strictEqual(drawer.activeSnapPoint, '0.5', 'nearer half way than all the way up')
    drawer.finishAnimations()
    assert.strictEqual(Math.round(drawer.offset), Math.round(height / 2))

    await drawer.tapHandle()
    assert.strictEqual(drawer.activeSnapPoint, '1')
    await drawer.tapHandle()
    assert.false(drawer.isOpen, 'a tap at the last snap point closes it')
    await waitUntil(() => drawer.content === null)
    await a11yAudit()
  })

  test('@closeThreshold: how much of it a slow drag must hide to close it', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer @closeThreshold={{0.5}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content class="panel"><d.Title>Half</d.Title></d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.afterOpening()
    await drawer.drag(120, { duration: 900 })
    assert.true(drawer.isOpen, '120px of 300px is under half')
    await drawer.drag(170, { duration: 900 })
    assert.false(drawer.isOpen, '170px is over half')
    await a11yAudit()
  })

  test('@fadeFromIndex and @snapToSequentialPoint', async function (assert) {
    const SNAP_POINTS = [0.25, 0.5, 1]
    await render(
      <template>
        <PanelStyles />
        <Drawer
          @name="fade"
          @snapPoints={{SNAP_POINTS}}
          @fadeFromIndex={{1}}
          @defaultActiveSnapPoint={{1}}
          as |d|
        >
          <d.Trigger>Fade</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel tall">
            <d.Title>Fade</d.Title>
            <button type="button" data-quarter {{on "click" (fn d.setActiveSnapPoint 0.25)}}>
              A quarter
            </button>
            <button type="button" data-half {{on "click" (fn d.setActiveSnapPoint 0.5)}}>
              Half
            </button>
          </d.Content>
        </Drawer>
        <Drawer
          @name="sequential"
          @snapPoints={{SNAP_POINTS}}
          @snapToSequentialPoint={{true}}
          @defaultActiveSnapPoint={{1}}
          as |d|
        >
          <d.Trigger>Sequential</d.Trigger>
          <d.Content class="panel tall"><d.Title>Sequential</d.Title></d.Content>
        </Drawer>
      </template>,
    )
    const fade = new DrawerHarness('fade')
    await fade.open()
    await click('[data-quarter]')
    assert.dom(fade.overlay).hasAttribute('data-vaul-snap-points-overlay', 'false')
    await click('[data-half]')
    assert
      .dom(fade.overlay)
      .hasAttribute('data-vaul-snap-points-overlay', 'true', 'the overlay from the second on')
    await fade.pressEscape()

    const sequential = new DrawerHarness('sequential')
    await sequential.open()
    await sequential.afterOpening()
    await sequential.swipe(300)
    assert.true(sequential.isOpen, "a fast swipe doesn't close it")
    assert.strictEqual(sequential.activeSnapPoint, '0.5', 'it goes to the next snap point down')
    await a11yAudit()
  })

  test('the Handle: @preventCycle, and a long press, are not taps', async function (assert) {
    const SNAP_POINTS = [0.5, 1]
    await render(
      <template>
        <PanelStyles />
        <Drawer @snapPoints={{SNAP_POINTS}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content class="panel tall">
            <d.Handle @preventCycle={{true}} />
            <d.Title>Handle</d.Title>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.tapHandle()
    assert.strictEqual(drawer.activeSnapPoint, '0.5', '@preventCycle: it stays')
    await a11yAudit()
  })

  test('@handleOnly: only the handle drags it', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer @direction="right" @handleOnly={{true}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content class="panel">
            <d.Title>Handle only</d.Title>
            <d.Handle />
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.afterOpening()
    await drawer.drag(150)
    assert.true(drawer.isOpen, 'a drag on the content does nothing')
    assert.strictEqual(drawer.offset, 0)
    await drawer.drag(150, { from: drawer.handle! })
    assert.false(drawer.isOpen, 'a drag on the handle closes it')
    await a11yAudit()
  })

  test('data-vaul-no-drag, and content that has scrolled, stop a drag', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content class="panel">
            <d.Title>Scrolling</d.Title>
            <div data-vaul-no-drag data-slider>A slider</div>
            <div class="scroller" data-scroller tabindex="0"><div>Long</div></div>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await drawer.afterOpening()
    await drawer.drag(200, { from: drawer.content!.querySelector('[data-slider]')! })
    assert.true(drawer.isOpen, 'not from data-vaul-no-drag')

    const scroller = drawer.content!.querySelector<HTMLElement>('[data-scroller]')!
    scroller.scrollTop = 50
    await drawer.drag(200, { from: scroller })
    assert.true(drawer.isOpen, 'not while its content is scrolled down')
    scroller.scrollTop = 0
    await wait(120)
    await drawer.drag(200, { from: scroller })
    assert.false(drawer.isOpen, 'scrolled back to the top, it drags')
    await a11yAudit()
  })

  test('@shouldScaleBackground scales the wrapper back while it is open', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <div data-vaul-drawer-wrapper data-wrapper>
          <Drawer @shouldScaleBackground={{true}} as |d|>
            <d.Trigger>Open</d.Trigger>
            <d.Overlay class="shade" />
            <d.Content class="panel"><d.Title>Scaled</d.Title></d.Content>
          </Drawer>
        </div>
      </template>,
    )
    const drawer = new DrawerHarness()
    const wrapper = document.querySelector<HTMLElement>('[data-wrapper]')!
    const body = document.body.style.background
    await drawer.open()
    const scale = (window.innerWidth - 26) / window.innerWidth
    assert.ok(Math.abs(scaleOf(wrapper) - scale) < 1e-5, 'scaled back by 26px')
    assert.strictEqual(wrapper.style.borderRadius, '8px')
    assert.strictEqual(wrapper.style.transformOrigin, 'center top')
    assert.strictEqual(document.body.style.backgroundColor, 'black', 'on black')

    await drawer.pressEscape()
    assert.strictEqual(wrapper.style.transform, '', 'back as it was')
    assert.strictEqual(wrapper.style.borderRadius, '')
    await wait(510)
    assert.strictEqual(document.body.style.background, body, "and so is the body's background")
    await a11yAudit()
  })

  test('@setBackgroundColorOnScale={{false}} leaves the body alone', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <div data-vaul-drawer-wrapper data-wrapper>
          <Drawer @shouldScaleBackground={{true}} @setBackgroundColorOnScale={{false}} as |d|>
            <d.Trigger>Open</d.Trigger>
            <d.Content class="panel"><d.Title>Scaled</d.Title></d.Content>
          </Drawer>
        </div>
      </template>,
    )
    const drawer = new DrawerHarness()
    const background = document.body.style.backgroundColor
    await drawer.open()
    assert.ok(scaleOf(document.querySelector<HTMLElement>('[data-wrapper]')!) < 1, 'scaled')
    assert.strictEqual(document.body.style.backgroundColor, background, 'but not on black')
    await drawer.pressEscape()
    await a11yAudit()
  })

  test('a nested drawer steps its parent back while it is open', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer @name="outer" as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel">
            <d.Title>Outer</d.Title>
            <d.Nested @name="inner" as |n|>
              <n.Trigger>More</n.Trigger>
              <n.Overlay class="shade" />
              <n.Content class="panel"><n.Title>Inner</n.Title></n.Content>
            </d.Nested>
          </d.Content>
        </Drawer>
      </template>,
    )
    const outer = new DrawerHarness('outer')
    const inner = new DrawerHarness('inner')
    await outer.open()
    await outer.afterOpening()
    await inner.open()
    const scale = (window.innerWidth - 16) / window.innerWidth
    assert.ok(Math.abs(scaleOf(outer.content!) - scale) < 1e-5, 'the outer one is scaled back')
    assert.ok(outer.content!.style.transform.endsWith('translate3d(0px, -16px, 0px)'), 'and up')
    assert.true(inner.isOpen)
    await pressEscape()
    assert.false(inner.isOpen, 'Escape closes the inner one')
    assert.true(outer.isOpen, 'and leaves the outer one')
    outer.finishAnimations()
    const matrix = new DOMMatrixReadOnly(getComputedStyle(outer.content!).transform)
    assert.strictEqual(matrix.a, 1, 'which comes forward again, at full size')
    assert.strictEqual(outer.offset, 0, 'and back in place')
    await a11yAudit()
  })

  test('@modal={{false}}: no overlay, and a press outside leaves it open', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <button type="button" data-outside>Outside</button>
        <Drawer @modal={{false}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Overlay class="shade" />
          <d.Content class="panel"><d.Title>Non-modal</d.Title></d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    assert.false(drawer.isModal)
    assert.strictEqual(drawer.overlay, null)
    await pressOutside(document.querySelector('[data-outside]')!)
    assert.true(drawer.isOpen, 'still open')
    assert.dom('[data-outside]').doesNotHaveAttribute('inert', 'the page is usable')
    await drawer.pressEscape()
    assert.false(drawer.isOpen, 'Escape still closes it')
    await a11yAudit()
  })

  test("ember-primitives' Drawer: onClose hears a form's returnValue, and onAnimationEnd the end", async function (assert) {
    const closed: string[] = []
    const ended: boolean[] = []
    const onClose = (value: string) => closed.push(value)
    const onAnimationEnd = (open: boolean) => ended.push(open)
    await render(
      <template>
        <PanelStyles />
        <Drawer @onClose={{onClose}} @onAnimationEnd={{onAnimationEnd}} as |d|>
          <d.Trigger>Open</d.Trigger>
          <d.Content class="panel">
            <d.Title>Confirm</d.Title>
            <form method="dialog">
              <button type="submit" value="confirmed">Confirm</button>
            </form>
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    await drawer.open()
    await waitUntil(() => ended.length === 1, { timeout: 2000 })
    assert.deepEqual(ended, [true], 'opened')
    await click('button[type="submit"]')
    assert.false(drawer.isOpen)
    assert.deepEqual(closed, ['confirmed'])
    await waitUntil(() => ended.length === 2, { timeout: 2000 })
    assert.deepEqual(ended, [true, false], 'closed')
    await a11yAudit()
  })

  test('with an input focused, a smaller visual viewport resizes it to stay in view', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer @defaultOpen={{true}} as |d|>
          <d.Content class="panel">
            <d.Title>Keyboard</d.Title>
            <input aria-label="Name" />
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    const viewport = window.visualViewport
    if (!viewport) {
      assert.ok(true, 'no visual viewport in this browser')
      return
    }
    drawer.content!.querySelector('input')!.focus()
    viewport.dispatchEvent(new Event('resize'))
    assert.strictEqual(drawer.content!.style.height, '300px', 'its height is kept')
    assert.strictEqual(drawer.content!.style.bottom, '0px', 'above the (absent) keyboard')
    await rerender()
    await a11yAudit()
  })

  test('@repositionInputs={{false}} leaves it to the browser', async function (assert) {
    await render(
      <template>
        <PanelStyles />
        <Drawer @defaultOpen={{true}} @repositionInputs={{false}} as |d|>
          <d.Content class="panel">
            <d.Title>Keyboard</d.Title>
            <input aria-label="Name" />
          </d.Content>
        </Drawer>
      </template>,
    )
    const drawer = new DrawerHarness()
    drawer.content!.querySelector('input')!.focus()
    window.visualViewport?.dispatchEvent(new Event('resize'))
    assert.strictEqual(drawer.content!.style.height, '', 'its height is its own')
    assert.strictEqual(drawer.content!.style.bottom, '')
    await a11yAudit()
  })
})
