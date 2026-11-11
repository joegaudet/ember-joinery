import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Skeleton } from '@ember-joinery/ember'
import { SkeletonHarness } from '@ember-joinery/test-support'

/** What a CSS colour (`var(--muted)`) computes to here, to compare with a rendered one. */
function color(value: string): string {
  const probe = document.createElement('div')
  probe.style.backgroundColor = value
  getRootElement().append(probe)
  const computed = getComputedStyle(probe).backgroundColor
  probe.remove()
  return computed
}

module('Integration | components | skeleton', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a div with upstream classes and data attributes', async function (assert) {
    await render(<template><Skeleton @name="line" /></template>)
    const line = new SkeletonHarness('line')
    assert
      .dom(line.element)
      .hasTagName('div')
      .hasClass('jn-skeleton')
      .hasAttribute('data-slot', 'skeleton')
      .hasAttribute('data-test-jn', 'skeleton')
      .hasAttribute('data-test-jn-name', 'line')
    await a11yAudit()
  })

  test('its style sheet makes it a pulsing, rounded block in --muted', async function (assert) {
    // An app's own CSS, unlayered: it wins over Joinery's layer, as upstream's size classes do.
    const sheet = document.createElement('style')
    sheet.textContent =
      '.line { width: 250px; height: 16px } .avatar { width: 48px; height: 48px; border-radius: 9999px }'
    document.head.append(sheet)
    try {
      await render(
        <template>
          <Skeleton @name="line" class="line" />
          <Skeleton @name="avatar" class="avatar" />
        </template>,
      )
      const line = new SkeletonHarness('line')
      const style = getComputedStyle(line.element)
      assert.strictEqual(style.backgroundColor, color('var(--muted)'), 'bg-muted')
      assert.strictEqual(style.borderTopLeftRadius, '8px', "rounded-md: the theme's --radius × 0.8")
      assert.strictEqual(style.animationName, 'pulse', 'animate-pulse')
      assert.strictEqual(style.animationIterationCount, 'infinite')
      assert.true(line.isPulsing)
      assert.deepEqual([line.width, line.height], [250, 16], 'your size wins')

      const avatar = new SkeletonHarness('avatar')
      assert.strictEqual(
        getComputedStyle(avatar.element).borderTopLeftRadius,
        '9999px',
        'and your radius',
      )
      assert.strictEqual(SkeletonHarness.findAll().length, 2)
      await a11yAudit()
    } finally {
      sheet.remove()
    }
  })

  test('it takes attributes and @as, and has no size of its own', async function (assert) {
    await render(
      <template>
        <p>Loading <Skeleton @as="span" @name="inline" class="mine" aria-hidden="true" /></p>
        <div style="width: 120px"><Skeleton @name="block" /></div>
      </template>,
    )
    const inline = new SkeletonHarness('inline')
    assert
      .dom(inline.element)
      .hasTagName('span')
      .hasClass('mine')
      .hasAttribute('aria-hidden', 'true')
    const block = new SkeletonHarness('block')
    assert.deepEqual(
      [block.width, block.height],
      [120, 0],
      'as wide as its container, and no taller than its content',
    )
    await a11yAudit()
  })

  test('keyboard and RTL: it takes no focus, and lays out from the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="display: flex; gap: 16px; width: 300px">
            <Skeleton @name="avatar" style="width: 48px; height: 48px" />
            <Skeleton @name="text" style="width: 200px; height: 16px" />
          </div>
        </DirectionProvider>
      </template>,
    )
    const avatar = new SkeletonHarness('avatar')
    const text = new SkeletonHarness('text')
    assert.strictEqual(avatar.element.tabIndex, -1)
    assert.ok(
      avatar.element.getBoundingClientRect().left > text.element.getBoundingClientRect().right,
      'right to left, the first block is on the right',
    )
    await a11yAudit()
  })
})
