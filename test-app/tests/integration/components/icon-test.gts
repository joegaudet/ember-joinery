import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Album, ArrowUp, BadgeAlert, ChartScatter, CirclePlay, Database } from 'lucide'
import { Icon, type IconNode } from '@ember-joinery/ember'
import { IconHarness } from '@ember-joinery/test-support'

const tags = (svg: Element) => [...svg.children].map(child => child.tagName)

module('Integration | components | icon', function (hooks) {
  setupRenderingTest(hooks)

  test('it draws a lucide icon as lucide does, decorative by default', async function (assert) {
    await render(<template><Icon @icon={{ArrowUp}} class="mine" /></template>)
    const icon = new IconHarness()
    const svg = icon.element
    assert.strictEqual(svg.namespaceURI, 'http://www.w3.org/2000/svg')
    assert
      .dom(svg)
      .hasAttribute('width', '24')
      .hasAttribute('height', '24')
      .hasAttribute('viewBox', '0 0 24 24')
      .hasAttribute('fill', 'none')
      .hasAttribute('stroke', 'currentColor')
      .hasAttribute('stroke-width', '2')
      .hasAttribute('stroke-linecap', 'round')
      .hasAttribute('stroke-linejoin', 'round')
      .hasClass('lucide')
      .hasClass('mine')
    assert.deepEqual(tags(svg), ['path', 'path'])
    assert.strictEqual(svg.children[0]!.getAttribute('d'), 'm5 12 7-7 7 7')
    assert.strictEqual(svg.children[0]!.namespaceURI, 'http://www.w3.org/2000/svg')
    assert.true(icon.isDecorative, 'hidden from assistive technology')
    assert.strictEqual(icon.label, null)
    await a11yAudit()
  })

  test('it draws every element lucide uses, with its attributes', async function (assert) {
    await render(
      <template>
        <Icon @icon={{Database}} @name="ellipse" />
        <Icon @icon={{Album}} @name="rect" />
        <Icon @icon={{BadgeAlert}} @name="line" />
        <Icon @icon={{CirclePlay}} @name="polygon" />
        <Icon @icon={{ChartScatter}} @name="circle" />
      </template>,
    )
    const svg = (name: string) => new IconHarness(name).element
    assert.deepEqual(tags(svg('ellipse')), ['ellipse', 'path', 'path'])
    assert.dom(svg('ellipse').children[0]).hasAttribute('rx', '9').hasAttribute('ry', '3')
    assert.deepEqual(tags(svg('rect')), ['rect', 'polyline'])
    assert.dom(svg('rect').children[0]).hasAttribute('rx', '2').hasAttribute('width', '18')
    assert.dom(svg('rect').children[1]).hasAttribute('points')
    assert.ok(tags(svg('line')).includes('line'))
    assert.dom(svg('line').querySelector('line')).hasAttribute('x1').hasAttribute('y2')
    assert.ok(tags(svg('polygon')).includes('polygon'))
    const dot = svg('circle').querySelector('circle')!
    assert.dom(dot).hasAttribute('r').hasAttribute('fill', 'currentColor')
    for (const element of svg('circle').querySelectorAll('*')) {
      assert.false(element.hasAttribute('key'), `no React key on a ${element.tagName}`)
    }
    await a11yAudit()
  })

  test('@size, @color, @strokeWidth and @absoluteStrokeWidth, as lucide-react props', async function (assert) {
    await render(
      <template>
        <Icon @icon={{ArrowUp}} @name="sized" @size={{16}} @color="red" @strokeWidth={{1.5}} />
        <Icon @icon={{ArrowUp}} @name="absolute" @size={{48}} @absoluteStrokeWidth={{true}} />
      </template>,
    )
    assert
      .dom(new IconHarness('sized').element)
      .hasAttribute('width', '16')
      .hasAttribute('height', '16')
      .hasAttribute('stroke', 'red')
      .hasAttribute('stroke-width', '1.5')
    assert.dom(new IconHarness('absolute').element).hasAttribute('stroke-width', '1')
    await a11yAudit()
  })

  test('@label makes a standalone icon an image with a name', async function (assert) {
    await render(<template><Icon @icon={{ArrowUp}} @label="Back to top" /></template>)
    const icon = new IconHarness()
    assert.dom(icon.element).hasAttribute('role', 'img').doesNotHaveAttribute('aria-hidden')
    assert.strictEqual(icon.label, 'Back to top')
    assert.false(icon.isDecorative)
    await a11yAudit()
  })

  test('it takes an icon as its elements alone, as later lucide versions export them', async function (assert) {
    const plus: IconNode = [
      ['path', { d: 'M5 12h14' }],
      ['path', { d: 'M12 5v14' }],
    ]
    await render(<template><Icon @icon={{plus}} /></template>)
    assert.deepEqual(tags(new IconHarness().element), ['path', 'path'])
    await a11yAudit()
  })
})
