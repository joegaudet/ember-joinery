import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { render } from '@ember/test-helpers'
import { LinkTo } from '@ember/routing'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Card, type CardSize } from '@ember-joinery/ember'
import { ButtonHarness, CardHarness } from '@ember-joinery/test-support'

const SIZES: CardSize[] = ['default', 'sm']

// A 1×1 grey PNG, so an image renders without the network.
const IMAGE =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNgAAAAAgABSK+kcQAAAABJRU5ErkJggg=='

module('Integration | components | card', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Card as |c|>
          <c.Header>
            <c.Title>Card Title</c.Title>
            <c.Description>Card Description</c.Description>
            <c.Action>Card Action</c.Action>
          </c.Header>
          <c.Content>
            <p>Card Content</p>
          </c.Content>
          <c.Footer>
            <p>Card Footer</p>
          </c.Footer>
        </Card>
      </template>,
    )
    const card = new CardHarness()

    assert
      .dom(card.element)
      .hasTagName('div')
      .hasClass('jn-card')
      .hasClass('group/card', 'the marker its parts look for')
      .hasAttribute('data-slot', 'card')
      .hasAttribute('data-size', 'default')
      .hasAttribute('data-test-jn', 'card')
    assert
      .dom(card.header)
      .hasClass('jn-card-header')
      .hasClass('group/card-header')
      .hasAttribute('data-slot', 'card-header')
    assert
      .dom(card.part('title'))
      .hasClass('jn-card-title')
      .hasClass('jn-font-heading', 'the heading font, as upstream marks it')
      .hasAttribute('data-slot', 'card-title')
    assert
      .dom(card.part('description'))
      .hasClass('jn-card-description')
      .hasAttribute('data-slot', 'card-description')
    assert.dom(card.action).hasClass('jn-card-action').hasAttribute('data-slot', 'card-action')
    assert.dom(card.content).hasClass('jn-card-content').hasAttribute('data-slot', 'card-content')
    assert.dom(card.footer).hasClass('jn-card-footer').hasAttribute('data-slot', 'card-footer')
    assert.strictEqual(card.title, 'Card Title')
    assert.strictEqual(card.description, 'Card Description')
    assert.strictEqual(card.size, 'default')
    await a11yAudit()
  })

  test('every size renders its data attribute, and sm is tighter', async function (assert) {
    await render(
      <template>
        {{#each SIZES as |size|}}
          <Card @size={{size}} @name={{size}} as |c|>
            <c.Header><c.Title>{{size}}</c.Title></c.Header>
            <c.Content>Content</c.Content>
          </Card>
        {{/each}}
      </template>,
    )
    for (const size of SIZES) {
      assert.strictEqual(new CardHarness(size).size, size)
    }
    const normal = new CardHarness('default')
    const small = new CardHarness('sm')
    assert.strictEqual(getComputedStyle(normal.element).paddingTop, '16px', '--card-spacing: 4')
    assert.strictEqual(getComputedStyle(small.element).paddingTop, '12px', '--card-spacing: 3')
    assert.strictEqual(getComputedStyle(normal.element).rowGap, '16px')
    assert.strictEqual(getComputedStyle(small.element).rowGap, '12px')
    assert.strictEqual(getComputedStyle(normal.content).paddingLeft, '16px')
    assert.strictEqual(getComputedStyle(small.content).paddingLeft, '12px')
    assert.strictEqual(getComputedStyle(normal.part('title')).fontSize, '16px', 'text-base')
    assert.strictEqual(getComputedStyle(small.part('title')).fontSize, '14px', 'text-sm in sm')
    await a11yAudit()
  })

  test('its style sheet lays it out, without Tailwind', async function (assert) {
    await render(
      <template>
        <Card @name="full" as |c|>
          <c.Header>
            <c.Title>Login to your account</c.Title>
            <c.Description>Enter your email below</c.Description>
            <c.Action><Button @variant="link">Sign Up</Button></c.Action>
          </c.Header>
          <c.Content>Content</c.Content>
          <c.Footer><Button>Login</Button></c.Footer>
        </Card>
        <Card @name="image" as |c|>
          <img src={{IMAGE}} alt="Event cover" width="320" height="180" />
          <c.Header><c.Title>With an image</c.Title></c.Header>
        </Card>
      </template>,
    )
    const card = new CardHarness('full')
    const style = getComputedStyle(card.element)
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.flexDirection, 'column')
    assert.strictEqual(style.boxSizing, 'border-box')
    assert.strictEqual(style.overflow, 'hidden')
    assert.strictEqual(style.fontSize, '14px', 'text-sm')
    assert.strictEqual(style.borderTopLeftRadius, '14px', 'rounded-xl')
    assert.notStrictEqual(style.boxShadow, 'none', 'ring-1')
    assert.strictEqual(style.paddingTop, '16px', 'py-(--card-spacing)')
    assert.strictEqual(style.paddingBottom, '0px', 'none under a footer')

    const header = getComputedStyle(card.header)
    assert.strictEqual(header.display, 'grid')
    assert.strictEqual(header.paddingLeft, '16px', 'px-(--card-spacing)')
    assert.strictEqual(header.rowGap, '4px', 'gap-1')
    assert.strictEqual(header.containerType, 'inline-size', '@container/card-header')
    assert.strictEqual(
      header.gridTemplateColumns.split(' ').length,
      2,
      'an action takes a second column',
    )
    const action = getComputedStyle(card.action)
    assert.strictEqual(action.gridColumnStart, '2')
    assert.strictEqual(action.gridRowStart, '1')
    assert.strictEqual(action.justifySelf, 'flex-end', 'justify-self-end')
    assert.strictEqual(getComputedStyle(card.part('title')).fontWeight, '500', 'font-medium')
    assert.notStrictEqual(
      getComputedStyle(card.part('description')).color,
      getComputedStyle(card.part('title')).color,
      'the description is muted',
    )

    const footer = getComputedStyle(card.footer)
    assert.strictEqual(footer.display, 'flex')
    assert.strictEqual(footer.alignItems, 'center')
    assert.strictEqual(footer.borderTopWidth, '1px', 'border-t')
    assert.strictEqual(footer.paddingTop, '16px', 'p-(--card-spacing)')
    assert.notStrictEqual(footer.backgroundColor, style.backgroundColor, 'bg-muted/50')

    const image = new CardHarness('image')
    assert.strictEqual(
      getComputedStyle(image.element).paddingTop,
      '0px',
      'an image first goes to the top edge',
    )
    // Not named `img`: a binding by that name would turn the template's <img> into a call to it.
    const cover = getComputedStyle(image.element.querySelector('img')!)
    assert.strictEqual(cover.borderTopLeftRadius, '14px', 'rounded-t-xl on the image')
    assert.strictEqual(cover.display, 'block')
    await a11yAudit()
  })

  test('--card-spacing sets its spacing, and @as and a class go on any part', async function (assert) {
    await render(
      <template>
        <Card @as="section" @name="profile" class="mine" style="--card-spacing: 24px" as |c|>
          <c.Header @as="header">
            <c.Title @as="h2" class="title">Profile</c.Title>
            <c.Description @as="p">Your public profile.</c.Description>
          </c.Header>
          <c.Content @as="article">Content</c.Content>
          <c.Footer @as="footer" aria-label="Actions">Footer</c.Footer>
        </Card>
      </template>,
    )
    const card = new CardHarness('profile')
    assert.dom(card.element).hasTagName('section').hasClass('mine').hasClass('jn-card')
    assert.dom(card.header).hasTagName('header')
    assert.dom(card.part('title')).hasTagName('h2').hasClass('title').hasClass('jn-card-title')
    assert.dom(card.part('description')).hasTagName('p')
    assert.dom(card.content).hasTagName('article')
    assert.dom(card.footer).hasTagName('footer').hasAttribute('aria-label', 'Actions')
    assert.strictEqual(getComputedStyle(card.element).paddingTop, '24px')
    assert.strictEqual(getComputedStyle(card.element).rowGap, '24px')
    assert.strictEqual(getComputedStyle(card.content).paddingLeft, '24px')
    assert.strictEqual(getComputedStyle(card.footer).paddingTop, '24px')
    assert.strictEqual(getComputedStyle(card.part('title')).marginTop, '0px', 'no h2 margin')
    await a11yAudit()
  })

  test('keyboard: a card takes no focus; what is inside it keeps its own', async function (assert) {
    await render(
      <template>
        <Card as |c|>
          <c.Header><c.Title>Card</c.Title></c.Header>
          <c.Footer><Button @name="go">Go</Button></c.Footer>
        </Card>
      </template>,
    )
    const card = new CardHarness()
    assert.strictEqual(card.element.tabIndex, -1, 'not in the tab order')
    const go = card.find(ButtonHarness, 'go')
    await go.focus()
    assert.true(go.isFocused)
    await a11yAudit()
  })

  test('the part modifiers make your own elements and components its parts', async function (assert) {
    ;(this.owner as unknown as { setupRouter(): void }).setupRouter()
    await render(
      <template>
        <Card @name="components" as |c|>
          <c.Header data-case="component">
            <c.Title data-case="component">Title</c.Title>
            <c.Description data-case="component">Description</c.Description>
            <c.Action data-case="component">Action</c.Action>
          </c.Header>
          <c.Content data-case="component">Content</c.Content>
          <c.Footer data-case="component">Footer</c.Footer>
        </Card>
        <Card @name="modifiers" as |c|>
          <div data-case="modifier" {{c.header}}>
            <div data-case="modifier" {{c.title}}>Title</div>
            <div data-case="modifier" {{c.description}}>Description</div>
            <div data-case="modifier" {{c.action}}>Action</div>
          </div>
          <div data-case="modifier" {{c.content}}>Content</div>
          <div data-case="modifier" {{c.footer}}>Footer</div>
        </Card>
        <Card @name="link" as |c|>
          <c.Header>
            <LinkTo @route="index" {{c.title}}>Home</LinkTo>
          </c.Header>
        </Card>
      </template>,
    )
    const components = [...document.querySelectorAll('[data-case="component"]')]
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    assert.strictEqual(components.length, 6)
    components.forEach((component, index) => {
      assert.deepEqual(
        rendering(modifiers[index]!),
        rendering(component),
        `part ${index}: the same`,
      )
    })
    const modified = new CardHarness('modifiers')
    assert.strictEqual(modified.title, 'Title', 'the harness finds them')
    assert.strictEqual(getComputedStyle(modified.header).display, 'grid', 'styled as a header')

    const link = new CardHarness('link')
    assert
      .dom(link.part('title'))
      .hasTagName('a')
      .hasAttribute('href', '/')
      .hasClass('jn-card-title')
    assert.strictEqual(link.title, 'Home')
    await a11yAudit()
  })

  test('RTL: the action sits at the inline end, on the left', async function (assert) {
    await render(
      <template>
        <Card @name="ltr" as |c|>
          <c.Header>
            <c.Title>Login to your account</c.Title>
            <c.Action><Button @variant="link">Sign Up</Button></c.Action>
          </c.Header>
        </Card>
        <DirectionProvider @dir="rtl">
          <Card @name="rtl" as |c|>
            <c.Header>
              <c.Title>تسجيل الدخول إلى حسابك</c.Title>
              <c.Action><Button @variant="link">إنشاء حساب</Button></c.Action>
            </c.Header>
          </Card>
        </DirectionProvider>
      </template>,
    )
    const left = (element: Element) => element.getBoundingClientRect().left
    const ltr = new CardHarness('ltr')
    const rtl = new CardHarness('rtl')
    assert.ok(left(ltr.action) > left(ltr.part('title')), 'left to right, the action is right')
    assert.ok(left(rtl.action) < left(rtl.part('title')), 'right to left, the action is left')
    // The test container is scaled down, so a rendered box is measured against the card's.
    const scale = rtl.element.getBoundingClientRect().width / rtl.element.offsetWidth
    assert.strictEqual(
      Math.round((left(rtl.action) - left(rtl.element)) / scale),
      16,
      'at the inline end, inside the inset',
    )
    await a11yAudit()
  })

  test('the harness reads a card without parts, and fails clearly', async function (assert) {
    await render(
      <template>
        <Card @name="bare">Just text</Card>
      </template>,
    )
    const bare = new CardHarness('bare')
    assert.strictEqual(bare.title, '', 'no title')
    assert.strictEqual(bare.description, '')
    assert.strictEqual(bare.text, 'Just text')
    assert.throws(() => bare.footer, /no "footer" part found in card "bare"/)
    assert.throws(() => new CardHarness('missing').element, /no card "missing" found/)
    await a11yAudit()
  })
})
