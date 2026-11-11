import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, HoverCard } from '@ember-joinery/ember'
import { ButtonHarness, HoverCardHarness } from '@ember-joinery/test-support'

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
  for (const animation of element.getAnimations()) animation.finish()
}

module('Integration | components | hover-card', function (hooks) {
  setupRenderingTest(hooks)

  test('it opens on hover after its delay, with upstream’s classes and slots', async function (assert) {
    await render(
      <template>
        <HoverCard @openDelay={{10}} @closeDelay={{100}} as |h|>
          <Button @variant="link" {{h.trigger}}>Hover Here</Button>
          <h.Content class="flex w-64 flex-col gap-0.5">
            <div>@nextjs</div>
            <div>The React Framework – created and maintained by @vercel.</div>
          </h.Content>
        </HoverCard>
      </template>,
    )
    const card = new HoverCardHarness()
    assert.strictEqual(card.trigger, new ButtonHarness().element, 'the Button is the trigger')
    assert
      .dom(card.trigger)
      .hasAttribute('data-slot', 'button')
      .hasAttribute('data-state', 'closed')

    await card.hover()
    assert.true(card.isOpen)
    assert
      .dom(card.content)
      .hasClass('jn-hover-card-content')
      .hasAttribute('data-slot', 'hover-card-content')
      .hasAttribute('data-state', 'open')
      .hasAttribute('data-side', 'bottom')
    await a11yAudit()

    await card.unhover()
    assert.false(card.isOpen)
    await a11yAudit()
  })

  test('its style sheet sizes, colours and places it, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 200px; left: 400px">
          <HoverCard @defaultOpen={{true}} as |h|>
            <h.Trigger href="#nextjs">@nextjs</h.Trigger>
            <h.Content>The React Framework</h.Content>
          </HoverCard>
        </div>
      </template>,
    )
    const card = new HoverCardHarness()
    const content = card.content!
    finishAnimations(content)
    const style = getComputedStyle(content)
    assert.strictEqual(style.width, '256px', 'w-64')
    assert.strictEqual(style.paddingTop, '10px', 'p-2.5')
    assert.strictEqual(style.backgroundColor, token('--popover'), 'bg-popover')
    assert.strictEqual(style.color, token('--popover-foreground'))
    assert.strictEqual(style.overflow, 'visible')
    assert.dom(card.trigger).hasTagName('a').hasAttribute('data-slot', 'hover-card-trigger')

    const t = rect(card.trigger)
    const c = rect(content)
    assert.true(Math.abs(c.top - (t.bottom + 4)) <= 1, `4px below its trigger (${c.top})`)
    await a11yAudit()
  })

  test('keyboard: focus opens it and blur closes it, after their delays', async function (assert) {
    await render(
      <template>
        <HoverCard @openDelay={{10}} @closeDelay={{10}} as |h|>
          <h.Trigger href="#nextjs">@nextjs</h.Trigger>
          <h.Content>The React Framework</h.Content>
        </HoverCard>
      </template>,
    )
    const card = new HoverCardHarness()
    await card.focus()
    assert.true(card.isOpen)
    await card.pressEscape()
    assert.false(card.isOpen, 'Escape')
    await card.blur()
    await card.focus()
    await card.blur()
    assert.false(card.isOpen, 'blur')
    await a11yAudit()
  })

  test('each side, right to left too', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 300px; left: 500px">
          <DirectionProvider @dir="rtl">
            <HoverCard @defaultOpen={{true}} as |h|>
              <h.Trigger href="#headphones">يمين</h.Trigger>
              <h.Content @side="right" dir="rtl">سماعات لاسلكية</h.Content>
            </HoverCard>
          </DirectionProvider>
        </div>
      </template>,
    )
    const card = new HoverCardHarness()
    finishAnimations(card.content!)
    assert.strictEqual(card.side, 'right')
    assert.true(rect(card.content!).left >= rect(card.trigger).right, 'on the right')
    await a11yAudit()
  })
})
