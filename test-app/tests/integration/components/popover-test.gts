import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Popover } from '@ember-joinery/ember'
import { ButtonHarness, PopoverHarness, tab } from '@ember-joinery/test-support'

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

const rect = (element: Element) => element.getBoundingClientRect()

/** The colour a token resolves to, as computed styles report colours. */
function token(name: string): string {
  const probe = document.createElement('div')
  probe.style.setProperty('color', `var(${name})`)
  document.body.append(probe)
  const color = getComputedStyle(probe).color
  probe.remove()
  return color
}

/** Ends the content's entry animation, so its computed style is the resting one. */
function finishAnimations(element: Element) {
  for (const animation of element.getAnimations()) animation.finish()
}

module('Integration | components | popover', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream’s classes and slots, with a Button of your own as the trigger', async function (assert) {
    await render(
      <template>
        <Popover @name="dimensions" as |p|>
          <Button @variant="outline" {{p.trigger}}>Open Popover</Button>
          <p.Content>
            <p.Header>
              <p.Title>Dimensions</p.Title>
              <p.Description>Set the dimensions for the layer.</p.Description>
            </p.Header>
          </p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness('dimensions')
    const button = new ButtonHarness()
    assert.strictEqual(popover.trigger, button.element, 'the Button is the trigger')
    assert
      .dom(popover.trigger)
      .hasAttribute('data-slot', 'button', 'it keeps its own slot, as upstream’s asChild does')
      .hasAttribute('aria-haspopup', 'dialog')
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('type', 'button')

    await popover.open()
    const content = popover.content!
    assert
      .dom(content)
      .hasClass('jn-popover-content')
      .hasAttribute('data-slot', 'popover-content')
      .hasAttribute('data-state', 'open')
      .hasAttribute('data-side', 'bottom')
      .hasAttribute('data-align', 'center')
    assert.dom('[data-slot="popover-header"]', content).hasClass('jn-popover-header')
    assert
      .dom('[data-slot="popover-title"]', content)
      .hasClass('jn-popover-title')
      .hasTagName('div')
    assert
      .dom('[data-slot="popover-description"]', content)
      .hasClass('jn-popover-description')
      .hasTagName('p')
    assert.strictEqual(popover.label, 'Dimensions', 'the Title names it')
    assert.strictEqual(popover.description, 'Set the dimensions for the layer.')
    await a11yAudit()
  })

  test('its style sheet sizes, colours and places it, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 200px; left: 400px">
          <Popover @defaultOpen={{true}} as |p|>
            <p.Trigger>Open</p.Trigger>
            <p.Content>
              <p.Header>
                <p.Title>Dimensions</p.Title>
                <p.Description>Set the dimensions for the layer.</p.Description>
              </p.Header>
            </p.Content>
          </Popover>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    const content = popover.content!
    finishAnimations(content)
    const style = getComputedStyle(content)
    assert.strictEqual(style.width, '288px', 'w-72')
    assert.strictEqual(style.paddingTop, '10px', 'p-2.5')
    assert.strictEqual(style.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.overflow, 'visible', 'not the browser’s popover overflow')
    assert.strictEqual(style.backgroundColor, token('--popover'), 'bg-popover')
    assert.strictEqual(style.color, token('--popover-foreground'), 'text-popover-foreground')
    assert.notStrictEqual(style.boxShadow, 'none', 'shadow-md and its ring')
    assert.strictEqual(px(style.fontSize), 14, 'text-sm')
    assert.ok(style.transformOrigin, 'from Radix’s custom property')
    const title = popover.queryPart('title')!
    assert.strictEqual(getComputedStyle(title).fontWeight, '500', 'font-medium')
    assert.strictEqual(
      getComputedStyle(content.querySelector('p')!).color,
      token('--muted-foreground'),
      'the description is muted',
    )

    const t = rect(popover.trigger)
    const c = rect(content)
    assert.true(Math.abs(c.top - (t.bottom + 4)) <= 1, `4px below its trigger (${c.top})`)
    assert.true(
      Math.abs(c.left + c.width / 2 - (t.left + t.width / 2)) <= 1,
      'centred, as upstream’s default align',
    )
    await a11yAudit()
  })

  test('@align and @side, and right to left', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 200px; left: 400px">
          <DirectionProvider @dir="rtl">
            <Popover @defaultOpen={{true}} as |p|>
              <p.Trigger>فتح</p.Trigger>
              <p.Content @align="start" dir="rtl">المحتوى</p.Content>
            </Popover>
          </DirectionProvider>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    finishAnimations(popover.content!)
    const t = rect(popover.trigger)
    const c = rect(popover.content!)
    assert.true(
      Math.abs(c.right - t.right) <= 1,
      `start is the right edge, right to left (${c.left}–${c.right} vs ${t.left}–${t.right})`,
    )
    assert.strictEqual(popover.align, 'start')
    await a11yAudit()
  })

  test('keyboard: focus moves in, Tab goes round inside, Escape closes it and focus returns', async function (assert) {
    await render(
      <template>
        <Popover as |p|>
          <p.Trigger>Settings</p.Trigger>
          <p.Content aria-label="Settings">
            <button id="one" type="button">One</button>
            <button id="two" type="button">Two</button>
          </p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    await popover.open()
    assert.dom('#one').isFocused()
    await tab()
    await tab()
    assert.dom('#one').isFocused('Tab goes round')
    await popover.pressEscape()
    assert.false(popover.isOpen)
    assert.dom(popover.trigger).isFocused()
    await a11yAudit()
  })

  test('the Trigger part renders upstream’s slot', async function (assert) {
    await render(
      <template>
        <Popover as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Anchor>Anchor</p.Anchor>
          <p.Content>Content</p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    assert.dom(popover.trigger).hasAttribute('data-slot', 'popover-trigger').hasTagName('button')
    assert.dom('[data-slot="popover-anchor"]').exists()
    await a11yAudit()
  })
})
