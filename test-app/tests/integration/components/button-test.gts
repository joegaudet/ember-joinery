import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { render, rerender, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { LinkTo } from '@ember/routing'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ArrowRight, Plus } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Button,
  Icon,
  asButton,
  buttonAttributes,
  buttonClasses,
  type ButtonSize,
  type ButtonVariant,
} from '@ember-joinery/ember'
import { ButtonHarness } from '@ember-joinery/test-support'

const VARIANTS: ButtonVariant[] = [
  'default',
  'outline',
  'secondary',
  'ghost',
  'destructive',
  'link',
]
const SIZES: ButtonSize[] = ['default', 'xs', 'sm', 'lg', 'icon', 'icon-xs', 'icon-sm', 'icon-lg']

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

module('Integration | components | button', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a native button with upstream classes and data attributes', async function (assert) {
    await render(
      <template>
        <Button>Button</Button>
      </template>,
    )
    const harness = new ButtonHarness()

    assert.dom(harness.element).hasTagName('button').hasText('Button')
    assert
      .dom(harness.element)
      .hasClass('jn-button')
      .hasClass('group/button')
      .hasClass('jn-button-variant-default')
      .hasClass('jn-button-size-default')
      .hasAttribute('data-slot', 'button')
      .hasAttribute('data-variant', 'default')
      .hasAttribute('data-size', 'default')
      .doesNotHaveAttribute('type', 'it leaves type to the caller, as upstream')
    assert.strictEqual(harness.variant, 'default')
    assert.strictEqual(harness.size, 'default')
    assert.strictEqual(harness.label, 'Button')
    await a11yAudit()
  })

  test('every variant and size renders its classes and data attributes', async function (assert) {
    await render(
      <template>
        {{#each VARIANTS as |variant|}}
          <Button @variant={{variant}} @name={{variant}}>{{variant}}</Button>
        {{/each}}
        {{#each SIZES as |size|}}
          <Button @size={{size}} @name="size-{{size}}" aria-label={{size}}>{{size}}</Button>
        {{/each}}
      </template>,
    )
    for (const variant of VARIANTS) {
      const harness = new ButtonHarness(variant)
      assert.strictEqual(harness.variant, variant)
      assert.dom(harness.element).hasClass(`jn-button-variant-${variant}`)
    }
    for (const size of SIZES) {
      const harness = new ButtonHarness(`size-${size}`)
      assert.strictEqual(harness.size, size)
      assert.dom(harness.element).hasClass(`jn-button-size-${size}`)
    }
    assert.strictEqual(ButtonHarness.findAll().length, VARIANTS.length + SIZES.length)
    await a11yAudit()
  })

  test('its style sheet sizes and colours it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Button @name="default">Default</Button>
        <Button @name="outline" @variant="outline">Outline</Button>
        <Button @name="icon" @size="icon" aria-label="Add"><Icon @icon={{Plus}} /></Button>
        <Button @name="sm" @size="sm">Small</Button>
      </template>,
    )
    const style = (name: string) => getComputedStyle(new ButtonHarness(name).element)

    assert.strictEqual(style('default').height, '32px', 'h-8, border included')
    assert.strictEqual(style('default').boxSizing, 'border-box')
    assert.strictEqual(style('default').display, 'inline-flex')
    assert.strictEqual(style('default').fontWeight, '500')
    assert.strictEqual(style('default').fontSize, '14px', 'text-sm')
    assert.strictEqual(
      style('default').fontFamily,
      getComputedStyle(document.body).fontFamily,
      "it takes the page's font, as preflight gives upstream's",
    )
    assert.strictEqual(style('default').borderTopWidth, '1px')
    assert.strictEqual(
      style('default').borderTopLeftRadius,
      '10px',
      "rounded-lg: the theme's --radius",
    )
    assert.notStrictEqual(
      style('default').backgroundColor,
      style('outline').backgroundColor,
      'the variants differ',
    )
    assert.strictEqual(style('icon').width, '32px', 'size-8')
    assert.strictEqual(style('icon').height, '32px')
    const svg = new ButtonHarness('icon').element.querySelector('svg')!
    assert.strictEqual(
      getComputedStyle(svg).width,
      '16px',
      'an icon without a size- class is size-4',
    )
    assert.strictEqual(style('sm').height, '28px', 'h-7')
    await a11yAudit()
  })

  test('it takes attributes and listeners, and a disabled button ignores clicks', async function (assert) {
    let clicks = 0
    const count = () => clicks++
    await render(
      <template>
        <Button @name="save" type="submit" class="mine" {{on "click" count}}>Save</Button>
        <Button @name="off" disabled {{on "click" count}}>Off</Button>
      </template>,
    )
    const save = new ButtonHarness('save')
    assert.dom(save.element).hasAttribute('type', 'submit').hasClass('mine').hasClass('jn-button')

    await save.click()
    assert.strictEqual(clicks, 1, 'the listener ran')

    const off = new ButtonHarness('off')
    assert.true(off.isDisabled)
    assert.false(save.isDisabled)
    await off.click().catch(() => undefined)
    assert.strictEqual(clicks, 1, 'the disabled button ignored the click')
    assert.strictEqual(getComputedStyle(off.element).opacity, '0.5', 'disabled:opacity-50')
    await a11yAudit()
  })

  test('keyboard: it is a native button in the tab order, so Enter and Space activate it', async function (assert) {
    await render(
      <template>
        <Button @name="first">First</Button>
        <Button @name="second" disabled>Second</Button>
      </template>,
    )
    const first = new ButtonHarness('first')
    assert.strictEqual(first.element.tabIndex, 0, 'in the tab order')
    assert.ok(
      first.element instanceof HTMLButtonElement,
      'a native <button>: the browser activates it on Enter and Space (APG Button)',
    )
    await first.focus()
    assert.true(first.isFocused)
    await first.blur()
    assert.false(first.isFocused)

    const second = new ButtonHarness('second')
    second.element.focus()
    assert.false(second.isFocused, 'a disabled button takes no focus')
    await a11yAudit()
  })

  test('@as renders another tag with the same classes and attributes', async function (assert) {
    await render(
      <template>
        <Button @as="a" @variant="outline" href="/login">Login</Button>
      </template>,
    )
    const harness = new ButtonHarness()
    assert.dom(harness.element).hasTagName('a').hasAttribute('href', '/login').hasText('Login')
    assert.dom(harness.element).hasClass('jn-button-variant-outline')
    assert.strictEqual(harness.variant, 'outline')
    assert.strictEqual(
      getComputedStyle(harness.element).textDecorationLine,
      'none',
      "a link takes no underline, as preflight gives upstream's",
    )
    await a11yAudit()
  })

  test('the asButton modifier makes any element a button, and follows its arguments', async function (assert) {
    class State {
      @tracked variant: ButtonVariant = 'default'
    }
    const state = new State()
    await render(
      <template>
        <a href="/docs" {{asButton variant=state.variant size="sm" name="docs"}}>Docs</a>
      </template>,
    )
    const docs = new ButtonHarness('docs')
    assert.dom(docs.element).hasTagName('a').hasClass('jn-button').hasClass('jn-button-size-sm')
    assert.strictEqual(docs.variant, 'default')
    assert.strictEqual(docs.size, 'sm')
    assert.strictEqual(getComputedStyle(docs.element).height, '28px', 'styled as a button')

    state.variant = 'outline'
    await settled()
    assert.strictEqual(docs.variant, 'outline', 'the attributes follow')
    assert
      .dom(docs.element)
      .hasClass('jn-button-variant-outline')
      .doesNotHaveClass('jn-button-variant-default')
    await rerender()
    await a11yAudit()
  })

  test('the component and the modifier render the same classes and attributes', async function (assert) {
    const cases = VARIANTS.flatMap(variant => SIZES.map(size => ({ variant, size })))
    await render(
      <template>
        {{#each cases as |c|}}
          <Button
            @variant={{c.variant}}
            @size={{c.size}}
            @name="x"
            aria-label="x"
            data-case="component"
          />
          <button
            type="button"
            aria-label="x"
            data-case="modifier"
            {{asButton variant=c.variant size=c.size name="x"}}
          ></button>
        {{/each}}
        <Button aria-label="x" data-case="component" />
        <button type="button" aria-label="x" data-case="modifier" {{asButton}}></button>
      </template>,
    )
    const components = [...document.querySelectorAll('[data-case="component"]')]
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    assert.strictEqual(components.length, cases.length + 1)
    components.forEach((component, index) => {
      const modified = rendering(modifiers[index]!)
      // The component leaves type to the caller; this button sets its own.
      delete modified.attributes['type']
      assert.deepEqual(rendering(component), modified, `${index}: the same`)
    })

    // And both are what the functions say, for code of your own.
    const [first] = components
    assert.deepEqual(
      rendering(first!).classes,
      buttonClasses({ variant: 'default', size: 'default' }).split(' ').sort(),
    )
    for (const [name, value] of Object.entries(
      buttonAttributes({ variant: 'default', size: 'default', name: 'x' }),
    )) {
      assert.strictEqual(first!.getAttribute(name), value ?? null, name)
    }
    assert.dom(components.at(-1)).doesNotHaveAttribute('data-test-jn-name', 'none without a name')
    await a11yAudit()
  })

  test('<LinkTo {{asButton}}> is a link that looks like a button', async function (assert) {
    ;(this.owner as unknown as { setupRouter(): void }).setupRouter()
    await render(
      <template>
        <LinkTo @route="index" class="mine" {{asButton variant="outline" size="sm" name="home"}}>
          Home
        </LinkTo>
      </template>,
    )
    const home = new ButtonHarness('home')
    assert.dom(home.element).hasTagName('a').hasAttribute('href', '/').hasText('Home')
    assert
      .dom(home.element)
      .hasClass('jn-button')
      .hasClass('jn-button-variant-outline')
      .hasClass('jn-button-size-sm')
      .hasClass('mine', "the element's own classes stay")
      .hasAttribute('data-slot', 'button')
    assert.strictEqual(home.variant, 'outline')
    assert.strictEqual(home.size, 'sm')
    assert.strictEqual(home.label, 'Home')
    const style = getComputedStyle(home.element)
    assert.strictEqual(style.height, '28px', 'h-7')
    assert.strictEqual(style.display, 'inline-flex')
    assert.strictEqual(style.textDecorationLine, 'none')
    await a11yAudit()
  })

  test('RTL: an icon on the inline end gets the narrower padding on its side', async function (assert) {
    await render(
      <template>
        <Button @name="ltr" @variant="outline">Submit
          <Icon @icon={{ArrowRight}} data-icon="inline-end" /></Button>
        <DirectionProvider @dir="rtl">
          <Button @name="rtl" @variant="outline">إرسال
            <Icon @icon={{ArrowRight}} data-icon="inline-end" /></Button>
        </DirectionProvider>
      </template>,
    )
    const ltr = getComputedStyle(new ButtonHarness('ltr').element)
    const rtl = getComputedStyle(new ButtonHarness('rtl').element)
    // px-2.5 (10px), with has-data-[icon=inline-end]:pe-2 (8px) on the icon's side.
    assert.strictEqual(px(ltr.paddingRight), 8, 'left to right, the end is on the right')
    assert.strictEqual(px(ltr.paddingLeft), 10)
    assert.strictEqual(px(rtl.paddingLeft), 8, 'right to left, the end is on the left')
    assert.strictEqual(px(rtl.paddingRight), 10)
    await a11yAudit()
  })

  test('the harness reads its name, pressed state and disabled link', async function (assert) {
    await render(
      <template>
        <span id="caption">Go to the files</span>
        <Button @name="icon" @size="icon" aria-label="Add"><Icon @icon={{Plus}} /></Button>
        <Button @name="labelled" aria-labelledby="caption">Go</Button>
        <Button @name="toggle" aria-pressed="true">Bold</Button>
        <Button @name="link" @as="a" href="#" aria-disabled="true">Link</Button>
      </template>,
    )
    assert.strictEqual(new ButtonHarness('icon').label, 'Add')
    assert.strictEqual(new ButtonHarness('icon').text, '')
    assert.strictEqual(new ButtonHarness('labelled').label, 'Go to the files')
    assert.true(new ButtonHarness('toggle').isPressed)
    assert.strictEqual(new ButtonHarness('icon').isPressed, undefined)
    assert.true(new ButtonHarness('link').isDisabled)
    assert.throws(() => new ButtonHarness('missing').element, /no button "missing" found/)
    await a11yAudit()
  })
})
