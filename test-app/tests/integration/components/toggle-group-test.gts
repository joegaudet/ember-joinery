import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Bold, Italic } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Icon,
  ToggleGroup,
  toggleGroupItemAttributes,
  toggleGroupItemClasses,
} from '@ember-joinery/ember'
import { ToggleGroupHarness, tab } from '@ember-joinery/test-support'

const px = (value: string) => Number.parseFloat(value)

/** A colour, resolved by the browser, to compare two. */
function colour(value: string): string {
  const probe = document.createElement('span')
  probe.style.backgroundColor = value
  document.body.append(probe)
  const resolved = getComputedStyle(probe).backgroundColor
  probe.remove()
  return resolved
}

/** An element's classes and attributes (but the test's own `data-case`), to compare two. */
function rendering(element: Element): { classes: string[]; attributes: Record<string, string> } {
  const attributes: Record<string, string> = {}
  for (const { name, value } of element.attributes) {
    if (name !== 'class' && name !== 'data-case') attributes[name] = value
  }
  return { classes: [...element.classList].sort(), attributes }
}

module('Integration | components | toggle-group', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on the group and its items', async function (assert) {
    await render(
      <template>
        <ToggleGroup @type="multiple" @variant="outline" @name="format" aria-label="Format" as |g|>
          <g.Item @value="bold" aria-label="Toggle bold"><Icon @icon={{Bold}} /></g.Item>
          <g.Item @value="italic" aria-label="Toggle italic"><Icon @icon={{Italic}} /></g.Item>
        </ToggleGroup>
        <ToggleGroup @type="single" @name="plain" aria-label="Plain" as |g|>
          <g.Item @value="a" @variant="outline" @size="sm">A</g.Item>
        </ToggleGroup>
      </template>,
    )
    const format = new ToggleGroupHarness('format')
    assert
      .dom(format.element)
      .hasClass('jn-toggle-group')
      .hasClass('group/toggle-group')
      .hasAttribute('role', 'group')
      .hasAttribute('data-slot', 'toggle-group')
      .hasAttribute('data-variant', 'outline')
      .doesNotHaveAttribute('data-size', 'only the arguments given, as upstream')
      .hasAttribute('data-spacing', '2')
      .hasAttribute('data-orientation', 'horizontal')
    assert.strictEqual(format.variant, 'outline')
    assert.strictEqual(format.spacing, 2)
    for (const item of format.items) {
      assert
        .dom(item)
        .hasClass('jn-toggle-group-item')
        .hasClass('jn-toggle')
        .hasClass('group/toggle')
        .hasClass('jn-toggle-variant-outline', "the group's variant")
        .hasClass('jn-toggle-size-default')
        .hasAttribute('data-slot', 'toggle-group-item')
        .hasAttribute('data-variant', 'outline')
        .hasAttribute('data-size', 'default')
        .hasAttribute('data-spacing', '2')
        .hasAttribute('type', 'button')
    }
    assert.strictEqual(format.label('bold'), 'Toggle bold')

    const plain = new ToggleGroupHarness('plain')
    assert.dom(plain.element).doesNotHaveAttribute('data-variant')
    assert
      .dom(plain.item('a'))
      .hasAttribute('data-variant', 'outline', "without the group's, the item's own")
      .hasAttribute('data-size', 'sm')
    await a11yAudit()
  })

  test('its style sheet lays it out and sizes its items, without Tailwind', async function (assert) {
    await render(
      <template>
        <ToggleGroup @type="single" @variant="outline" @name="spaced" aria-label="Spaced" as |g|>
          <g.Item @value="top">Top</g.Item>
          <g.Item @value="bottom">Bottom</g.Item>
        </ToggleGroup>
        <ToggleGroup
          @type="single"
          @size="sm"
          @spacing={{1}}
          @name="small"
          aria-label="Small"
          as |g|
        >
          <g.Item @value="top">Top</g.Item>
        </ToggleGroup>
      </template>,
    )
    const spaced = new ToggleGroupHarness('spaced')
    const root = getComputedStyle(spaced.element)
    assert.strictEqual(root.display, 'flex')
    assert.strictEqual(root.flexDirection, 'row')
    assert.strictEqual(root.columnGap, '8px', 'gap-[--spacing(var(--gap))], with @spacing 2')
    assert.strictEqual(root.borderTopLeftRadius, '10px', 'rounded-lg')
    const item = getComputedStyle(spaced.item('top'))
    assert.strictEqual(item.height, '32px', 'a toggle: h-8')
    assert.strictEqual(item.borderTopWidth, '1px', 'outline')
    assert.strictEqual(item.borderTopLeftRadius, '10px', 'each item its own corners')
    assert.strictEqual(item.flexShrink, '0')

    const small = new ToggleGroupHarness('small')
    assert.strictEqual(getComputedStyle(small.element).columnGap, '4px', '@spacing 1')
    assert.strictEqual(
      getComputedStyle(small.element).borderTopLeftRadius,
      '8px',
      'data-[size=sm]:rounded-[min(var(--radius-md),10px)]',
    )
    assert.strictEqual(getComputedStyle(small.item('top')).height, '28px', 'the group size: h-7')
    await a11yAudit()
  })

  test('@spacing={{0}} joins the items: inner corners square, one border between', async function (assert) {
    await render(
      <template>
        <ToggleGroup @type="multiple" @variant="outline" @spacing={{0}} aria-label="Joined" as |g|>
          <g.Item @value="a">A</g.Item>
          <g.Item @value="b">B</g.Item>
          <g.Item @value="c">C</g.Item>
        </ToggleGroup>
      </template>,
    )
    const group = new ToggleGroupHarness()
    assert.strictEqual(getComputedStyle(group.element).columnGap, '0px')
    const [first, middle, last] = group.items.map(item => getComputedStyle(item))
    assert.strictEqual(first!.borderTopLeftRadius, '10px', 'the first keeps its start corners')
    assert.strictEqual(first!.borderTopRightRadius, '0px')
    assert.strictEqual(middle!.borderTopLeftRadius, '0px', 'rounded-none')
    assert.strictEqual(middle!.borderLeftWidth, '0px', 'border-s-0: no double border')
    assert.strictEqual(middle!.paddingLeft, '8px', 'px-2')
    assert.strictEqual(first!.borderLeftWidth, '1px', 'the first keeps its start border')
    assert.strictEqual(last!.borderTopRightRadius, '10px', 'the last keeps its end corners')
    await a11yAudit()
  })

  test('vertical: the items stack and stretch, and up and down move focus', async function (assert) {
    await render(
      <template>
        <ToggleGroup
          @type="multiple"
          @orientation="vertical"
          @spacing={{1}}
          @defaultValue={{array "bold" "italic"}}
          aria-label="Format"
          as |g|
        >
          <g.Item @value="bold" aria-label="Toggle bold"><Icon @icon={{Bold}} /></g.Item>
          <g.Item @value="italic" aria-label="Toggle italic"><Icon @icon={{Italic}} /></g.Item>
        </ToggleGroup>
      </template>,
    )
    const group = new ToggleGroupHarness()
    assert.strictEqual(group.orientation, 'vertical')
    const root = getComputedStyle(group.element)
    assert.strictEqual(root.flexDirection, 'column', 'data-vertical:flex-col')
    assert.strictEqual(root.alignItems, 'stretch', 'data-vertical:items-stretch')
    assert.strictEqual(root.rowGap, '4px')
    assert.deepEqual(group.value, ['bold', 'italic'])
    await tab()
    assert.strictEqual(group.focused, 'bold')
    await group.press('ArrowDown')
    assert.strictEqual(group.focused, 'italic')
    await group.press('ArrowRight')
    assert.strictEqual(group.focused, 'italic', 'a vertical group ignores left and right')
    await a11yAudit()
  })

  test('pressing items, single and multiple, and the pressed background', async function (assert) {
    await render(
      <template>
        {{! The background eases in (transition-all); read where it ends. }}
        <style>
          [data-slot="toggle-group-item"] {
            transition: none !important;
          }
        </style>
        <ToggleGroup @type="single" @defaultValue="all" @name="single" aria-label="Show" as |g|>
          <g.Item @value="all">All</g.Item>
          <g.Item @value="missed">Missed</g.Item>
        </ToggleGroup>
        <ToggleGroup @type="multiple" @name="multiple" aria-label="Format" as |g|>
          <g.Item @value="bold">Bold</g.Item>
          <g.Item @value="italic">Italic</g.Item>
        </ToggleGroup>
      </template>,
    )
    const single = new ToggleGroupHarness('single')
    assert.strictEqual(single.type, 'single')
    assert.strictEqual(
      getComputedStyle(single.item('all')).backgroundColor,
      colour('var(--muted)'),
      'data-[state=on]:bg-muted',
    )
    await single.toggle('missed')
    assert.deepEqual(single.value, ['missed'])

    const multiple = new ToggleGroupHarness('multiple')
    await multiple.toggle('bold')
    await multiple.toggle('italic')
    assert.deepEqual(multiple.value, ['bold', 'italic'])
    await a11yAudit()
  })

  test('disabled: every item dimmed and out of reach', async function (assert) {
    await render(
      <template>
        <ToggleGroup @type="multiple" @disabled={{true}} aria-label="Format" as |g|>
          <g.Item @value="bold">Bold</g.Item>
        </ToggleGroup>
      </template>,
    )
    const group = new ToggleGroupHarness()
    assert.true(group.isDisabled())
    assert.strictEqual(getComputedStyle(group.item('bold')).opacity, '0.5')
    await group.toggle('bold').catch(() => undefined)
    assert.deepEqual(group.value, [])
    await a11yAudit()
  })

  test('g.item renders the same as g.Item, on an element of your own', async function (assert) {
    await render(
      <template>
        <ToggleGroup @type="multiple" @variant="outline" @size="lg" aria-label="Format" as |g|>
          <g.Item @value="bold" data-case="component">Bold</g.Item>
          <button type="button" data-case="modifier" {{g.item value="italic"}}>Italic</button>
        </ToggleGroup>
      </template>,
    )
    const group = new ToggleGroupHarness()
    const component = rendering(group.item('bold'))
    const modified = rendering(group.item('italic'))
    modified.attributes['data-test-jn-value'] = 'bold'
    assert.deepEqual(modified, component)
    assert.deepEqual(
      component.classes,
      toggleGroupItemClasses({ variant: 'outline', size: 'lg' }).split(' ').sort(),
    )
    assert.strictEqual(
      toggleGroupItemAttributes({ variant: 'outline', size: 'lg', spacing: 2 })['data-size'],
      'lg',
    )
    await group.toggle('italic')
    assert.deepEqual(group.value, ['italic'])
    await a11yAudit()
  })

  test('RTL: joined items square off the corners on their own sides', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <ToggleGroup @type="single" @variant="outline" @spacing={{0}} aria-label="عرض" as |g|>
            <g.Item @value="list">قائمة</g.Item>
            <g.Item @value="grid">شبكة</g.Item>
          </ToggleGroup>
        </DirectionProvider>
      </template>,
    )
    const group = new ToggleGroupHarness()
    const [first, second] = group.items.map(item => getComputedStyle(item))
    assert.strictEqual(first!.borderTopRightRadius, '10px', 'the first is on the right')
    assert.strictEqual(first!.borderTopLeftRadius, '0px')
    assert.strictEqual(px(second!.borderRightWidth), 0, 'the second has no start border')
    assert.strictEqual(second!.borderTopLeftRadius, '10px')
    const [a, b] = group.items.map(item => item.getBoundingClientRect())
    assert.true(a!.left > b!.left, 'the items run right to left')
    await group.focus('list')
    await group.press('ArrowLeft')
    assert.strictEqual(group.focused, 'grid', 'the left arrow moves forward')
    await a11yAudit()
  })
})
