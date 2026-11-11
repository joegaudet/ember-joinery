import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Tooltip, TooltipProvider } from '@ember-joinery/ember'
import { TooltipHarness } from '@ember-joinery/test-support'

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

function finishAnimations(element: Element) {
  for (const animation of element.getAnimations({ subtree: true })) animation.finish()
}

module('Integration | components | tooltip', function (hooks) {
  setupRenderingTest(hooks)

  test('it opens at once on hover, with upstream’s classes, slots and arrow', async function (assert) {
    await render(
      <template>
        <Tooltip as |t|>
          <Button @variant="outline" {{t.trigger}}>Hover</Button>
          <t.Content><p>Add to library</p></t.Content>
        </Tooltip>
      </template>,
    )
    const tooltip = new TooltipHarness()
    assert
      .dom(tooltip.trigger)
      .hasAttribute('data-slot', 'button')
      .hasAttribute('data-state', 'closed')

    const started = performance.now()
    await tooltip.hover()
    assert.true(performance.now() - started < 300, 'no delay, as upstream’s provider')
    assert.true(tooltip.isOpen)
    assert.strictEqual(tooltip.state, 'delayed-open', 'its delay was 0')
    assert.strictEqual(tooltip.description, 'Add to library')
    const content = tooltip.content!
    assert
      .dom(content)
      .hasClass('jn-tooltip-content')
      .hasAttribute('data-slot', 'tooltip-content')
      .hasAttribute('data-side', 'top')
      .hasAttribute('role', 'tooltip')
    assert.dom('svg', tooltip.arrow!).hasClass('jn-tooltip-arrow')
    await a11yAudit()

    await tooltip.unhover()
    assert.false(tooltip.isOpen)
    await a11yAudit()
  })

  test('its style sheet colours and places it, and its arrow, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 300px; left: 400px">
          <Tooltip @defaultOpen={{true}} as |t|>
            <t.Trigger>Hover</t.Trigger>
            <t.Content>Add to library</t.Content>
          </Tooltip>
        </div>
      </template>,
    )
    const tooltip = new TooltipHarness()
    const content = tooltip.content!
    finishAnimations(content)
    const style = getComputedStyle(content)
    assert.strictEqual(style.backgroundColor, token('--foreground'), 'bg-foreground')
    assert.strictEqual(style.color, token('--background'), 'text-background')
    assert.strictEqual(style.fontSize, '12px', 'text-xs')
    assert.strictEqual(style.paddingLeft, '12px', 'px-3')
    assert.strictEqual(style.borderTopLeftRadius, getComputedStyle(content).borderTopRightRadius)
    assert.strictEqual(style.overflow, 'visible', 'so the arrow shows')

    const svg = tooltip.arrow!.querySelector('svg')!
    const arrow = getComputedStyle(svg)
    assert.strictEqual(arrow.width, '10px', 'size-2.5')
    assert.strictEqual(arrow.rotate, '45deg', 'a square turned to a point')
    assert.strictEqual(arrow.backgroundColor, token('--foreground'))

    const t = rect(tooltip.trigger)
    const c = rect(content)
    assert.true(
      Math.abs(c.bottom - (t.top - 10)) <= 1,
      `above, the arrow’s height off (${c.bottom} vs ${t.top})`,
    )
    await a11yAudit()
  })

  test('keyboard: focus opens it, Escape and blur close it', async function (assert) {
    await render(
      <template>
        <Tooltip as |t|>
          <Button {{t.trigger}}>Save</Button>
          <t.Content>Save Changes</t.Content>
        </Tooltip>
      </template>,
    )
    const tooltip = new TooltipHarness()
    await tooltip.focus()
    assert.strictEqual(tooltip.state, 'instant-open')
    await tooltip.pressEscape()
    assert.false(tooltip.isOpen, 'Escape')
    await tooltip.blur()
    await tooltip.focus()
    assert.true(tooltip.isOpen)
    await tooltip.blur()
    assert.false(tooltip.isOpen, 'blur')
    await a11yAudit()
  })

  test('a provider sets a delay for the tooltips inside it', async function (assert) {
    await render(
      <template>
        <TooltipProvider @delayDuration={{80}}>
          <Tooltip as |t|>
            <t.Trigger>Hover</t.Trigger>
            <t.Content>Delayed</t.Content>
          </Tooltip>
        </TooltipProvider>
      </template>,
    )
    const tooltip = new TooltipHarness()
    assert.dom(tooltip.trigger).hasAttribute('data-slot', 'tooltip-trigger')
    const started = performance.now()
    await tooltip.hover()
    assert.true(performance.now() - started >= 75, 'the provider’s delay')
    assert.true(tooltip.isOpen)
    await a11yAudit()
  })

  test('each side, right to left too', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 300px; left: 400px">
          <DirectionProvider @dir="rtl">
            <Tooltip @defaultOpen={{true}} as |t|>
              <t.Trigger>يسار</t.Trigger>
              <t.Content @side="left">إضافة إلى المكتبة</t.Content>
            </Tooltip>
          </DirectionProvider>
        </div>
      </template>,
    )
    const tooltip = new TooltipHarness()
    finishAnimations(tooltip.content!)
    assert.strictEqual(tooltip.side, 'left', 'a physical side, as Radix’s')
    assert.true(rect(tooltip.content!).right <= rect(tooltip.trigger).left, 'on the left')
    await a11yAudit()
  })
})
