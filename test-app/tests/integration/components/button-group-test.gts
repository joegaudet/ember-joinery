import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Minus, Plus } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, ButtonGroup, Icon, buttonGroupClasses } from '@ember-joinery/ember'
import { ButtonGroupHarness, ButtonHarness, tab } from '@ember-joinery/test-support'

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/** An element's four corner radii, in pixels: start-start, start-end, end-start, end-end. */
function corners(element: Element) {
  const style = getComputedStyle(element)
  return {
    topLeft: px(style.borderTopLeftRadius),
    topRight: px(style.borderTopRightRadius),
    bottomLeft: px(style.borderBottomLeftRadius),
    bottomRight: px(style.borderBottomRightRadius),
  }
}

module('Integration | components | button-group', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a group with upstream classes and data attributes', async function (assert) {
    await render(
      <template>
        <ButtonGroup aria-label="Actions" as |g|>
          <Button @variant="secondary">Copy</Button>
          <g.Separator />
          <Button @variant="secondary">Paste</Button>
        </ButtonGroup>
      </template>,
    )
    const group = new ButtonGroupHarness()
    assert
      .dom(group.element)
      .hasTagName('div')
      .hasAttribute('role', 'group')
      .hasClass('jn-button-group')
      .hasClass('group/button-group')
      .hasClass('jn-button-group-orientation-horizontal')
      .hasAttribute('data-slot', 'button-group')
      .hasAttribute('data-orientation', 'horizontal')
    assert.strictEqual(group.role, 'group')
    assert.strictEqual(group.label, 'Actions')
    assert.strictEqual(group.orientation, 'horizontal')
    assert.deepEqual(
      group.buttons.map(button => button.label),
      ['Copy', 'Paste'],
    )
    const [line] = group.separators
    assert
      .dom(line)
      .hasClass('jn-button-group-separator')
      .hasAttribute('data-slot', 'button-group-separator')
      .hasAttribute('data-orientation', 'vertical', 'vertical by default, between buttons')
      .hasAttribute('role', 'none', 'decorative, as upstream')
    assert.deepEqual(buttonGroupClasses().split(' '), [
      'jn-button-group',
      'group/button-group',
      'jn-button-group-orientation-horizontal',
    ])
    await a11yAudit()
  })

  test('horizontal: the buttons join, inner corners square and shared borders one line', async function (assert) {
    await render(
      <template>
        <ButtonGroup aria-label="Pages">
          <Button @variant="outline" @name="first">One</Button>
          <Button @variant="outline" @name="middle">Two</Button>
          <Button @variant="outline" @name="last">Three</Button>
        </ButtonGroup>
      </template>,
    )
    const first = corners(new ButtonHarness('first').element)
    const middle = corners(new ButtonHarness('middle').element)
    const last = corners(new ButtonHarness('last').element)
    assert.strictEqual(first.topLeft, 10, 'the first keeps its start corners')
    assert.strictEqual(first.topRight, 0, 'and squares its end')
    assert.deepEqual(Object.values(middle), [0, 0, 0, 0], 'the middle is square')
    assert.strictEqual(last.topLeft, 0)
    assert.strictEqual(last.bottomRight, 10, 'the last keeps its end corners (rounded-e-lg!)')

    const style = (name: string) => getComputedStyle(new ButtonHarness(name).element)
    assert.strictEqual(style('first').borderLeftWidth, '1px')
    assert.strictEqual(style('middle').borderLeftWidth, '0px', 'border-s-0: one line between')
    assert.strictEqual(style('last').borderLeftWidth, '0px')
    const group = getComputedStyle(new ButtonGroupHarness().element)
    assert.strictEqual(group.display, 'flex')
    assert.strictEqual(group.alignItems, 'stretch')
    assert.ok(
      px(group.width) < new ButtonGroupHarness().element.parentElement!.clientWidth,
      'w-fit: as wide as its buttons',
    )
    await a11yAudit()
  })

  test('vertical: a column, joined top to bottom', async function (assert) {
    await render(
      <template>
        <ButtonGroup @orientation="vertical" aria-label="Media controls" @name="v">
          <Button @variant="outline" @size="icon" @name="plus" aria-label="Add">
            <Icon @icon={{Plus}} />
          </Button>
          <Button @variant="outline" @size="icon" @name="minus" aria-label="Remove">
            <Icon @icon={{Minus}} />
          </Button>
        </ButtonGroup>
      </template>,
    )
    const group = new ButtonGroupHarness('v')
    assert.strictEqual(group.orientation, 'vertical')
    assert.dom(group.element).hasClass('jn-button-group-orientation-vertical')
    assert.strictEqual(getComputedStyle(group.element).flexDirection, 'column')
    const plus = corners(new ButtonHarness('plus').element)
    const minus = corners(new ButtonHarness('minus').element)
    assert.strictEqual(plus.topLeft, 10)
    assert.strictEqual(plus.bottomLeft, 0, 'the top button squares its bottom')
    assert.strictEqual(minus.topRight, 0, 'the bottom one its top')
    assert.strictEqual(minus.bottomRight, 10)
    assert.strictEqual(getComputedStyle(new ButtonHarness('minus').element).borderTopWidth, '0px')
    await a11yAudit()
  })

  test('nested groups sit apart, with a gap', async function (assert) {
    await render(
      <template>
        <ButtonGroup aria-label="Mail" @name="outer">
          <ButtonGroup @name="a">
            <Button @variant="outline">Archive</Button>
            <Button @variant="outline">Report</Button>
          </ButtonGroup>
          <ButtonGroup @name="b">
            <Button @variant="outline">Snooze</Button>
          </ButtonGroup>
        </ButtonGroup>
      </template>,
    )
    const outer = new ButtonGroupHarness('outer')
    assert.strictEqual(getComputedStyle(outer.element).columnGap, '8px', 'gap-2')
    assert.strictEqual(outer.groups.length, 2)
    assert.strictEqual(outer.buttons.length, 3, 'the buttons of nested groups too')
    assert.strictEqual(new ButtonGroupHarness('a').buttons.length, 2)
    await a11yAudit()
  })

  test('the separator draws a 1px line in the input colour, and can be semantic', async function (assert) {
    await render(
      <template>
        <ButtonGroup aria-label="Clipboard" @name="h" as |g|>
          <Button @variant="secondary" @size="sm">Copy</Button>
          <g.Separator />
          <Button @variant="secondary" @size="sm">Paste</Button>
        </ButtonGroup>
        <ButtonGroup @orientation="vertical" aria-label="Stack" @name="v" as |g|>
          <Button @variant="secondary">Up</Button>
          <g.Separator @orientation="horizontal" @decorative={{false}} />
          <Button @variant="secondary">Down</Button>
          <span {{g.separator orientation="vertical" decorative=false}}></span>
        </ButtonGroup>
      </template>,
    )
    const [vertical] = new ButtonGroupHarness('h').separators
    const style = getComputedStyle(vertical!)
    assert.strictEqual(style.width, '1px', 'data-vertical:w-px')
    assert.strictEqual(
      px(style.height),
      px(getComputedStyle(new ButtonGroupHarness('h').buttons[0]!.element).height) - 2,
      'as tall as the buttons (self-stretch), less data-vertical:my-px',
    )
    const probe = document.createElement('div')
    probe.style.backgroundColor = 'var(--input)'
    vertical!.parentElement!.append(probe)
    assert.strictEqual(style.backgroundColor, getComputedStyle(probe).backgroundColor, 'bg-input')
    probe.remove()

    const [horizontal, own] = new ButtonGroupHarness('v').separators
    assert
      .dom(horizontal)
      .hasAttribute('role', 'separator')
      .hasAttribute('data-orientation', 'horizontal')
      .doesNotHaveAttribute('aria-orientation', "horizontal is the role's default")
    assert.strictEqual(getComputedStyle(horizontal!).height, '1px', 'data-horizontal:h-px')
    assert
      .dom(own)
      .hasClass('jn-button-group-separator')
      .hasAttribute('role', 'separator')
      .hasAttribute('aria-orientation', 'vertical')
    await a11yAudit()
  })

  test('text sits on a muted tile, as a div, a label or your own element', async function (assert) {
    await render(
      <template>
        <ButtonGroup aria-label="URL" @name="url" as |g|>
          <g.Text>https://</g.Text>
          <Button @variant="outline">Go</Button>
        </ButtonGroup>
        <ButtonGroup @name="label" as |g|>
          <g.Text @as="label" for="name">Name</g.Text>
          <input id="name" />
        </ButtonGroup>
        <ButtonGroup aria-label="Own" @name="own" as |g|>
          <span {{g.text}}>Own</span>
        </ButtonGroup>
      </template>,
    )
    const url = new ButtonGroupHarness('url')
    assert.deepEqual(url.texts, ['https://'])
    const text = url.part('text')
    assert.dom(text).hasTagName('div').hasClass('jn-button-group-text')
    assert.dom(text).doesNotHaveAttribute('data-slot', "upstream's has none")
    const style = getComputedStyle(text)
    assert.notStrictEqual(style.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-muted')
    assert.strictEqual(style.borderTopWidth, '1px')
    assert.strictEqual(style.fontWeight, '500')
    assert.strictEqual(style.paddingLeft, '10px', 'px-2.5')
    assert.strictEqual(corners(text).topRight, 0, 'joined to the button after it')

    assert.dom(new ButtonGroupHarness('label').part('text')).hasTagName('label')
    assert.deepEqual(new ButtonGroupHarness('own').texts, ['Own'])
    assert.dom(new ButtonGroupHarness('own').part('text')).hasClass('jn-button-group-text')
    await a11yAudit()
  })

  test('keyboard: Tab moves through the buttons, as the group has no keys of its own', async function (assert) {
    await render(
      <template>
        <ButtonGroup aria-label="Actions">
          <Button @name="one">One</Button>
          <Button @name="two">Two</Button>
        </ButtonGroup>
        <Button @name="after">After</Button>
      </template>,
    )
    await new ButtonHarness('one').focus()
    await tab()
    assert.true(new ButtonHarness('two').isFocused)
    await tab()
    assert.true(new ButtonHarness('after').isFocused, 'and out of the group')
    await tab({ shift: true })
    assert.true(new ButtonHarness('two').isFocused)
    const focused = getComputedStyle(new ButtonHarness('two').element)
    assert.strictEqual(focused.position, 'relative', 'a focused button rises (relative, z-10)')
    await a11yAudit()
  })

  test('RTL: the group joins from the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <ButtonGroup aria-label="Actions">
            <Button @variant="outline" @name="first">أرشفة</Button>
            <Button @variant="outline" @name="last">تقرير</Button>
          </ButtonGroup>
        </DirectionProvider>
      </template>,
    )
    const first = new ButtonHarness('first').element
    const last = new ButtonHarness('last').element
    assert.ok(
      first.getBoundingClientRect().left > last.getBoundingClientRect().left,
      'the first on the right',
    )
    assert.strictEqual(corners(first).topRight, 10, 'its start corners, on the right, stay round')
    assert.strictEqual(corners(first).topLeft, 0)
    assert.strictEqual(corners(last).topLeft, 10, 'the last rounds its end, on the left')
    assert.strictEqual(getComputedStyle(last).borderRightWidth, '0px', 'border-s-0 on the right')
    await a11yAudit()
  })

  test('the harness reads aria-labelledby, and the name it was given', async function (assert) {
    await render(
      <template>
        <span id="caption">Text formatting</span>
        <ButtonGroup aria-labelledby="caption" @name="formatting">
          <Button>Bold</Button>
        </ButtonGroup>
        <ButtonGroup @name="unnamed"><Button>Solo</Button></ButtonGroup>
      </template>,
    )
    assert.strictEqual(new ButtonGroupHarness('formatting').label, 'Text formatting')
    assert.strictEqual(new ButtonGroupHarness('unnamed').label, '')
    assert.deepEqual(new ButtonGroupHarness('unnamed').separators, [])
    assert.throws(() => new ButtonGroupHarness('missing').element, /no button-group "missing"/)
    await a11yAudit()
  })
})
