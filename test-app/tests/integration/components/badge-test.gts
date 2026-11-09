import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { getRootElement, render, rerender, settled } from '@ember/test-helpers'
import { LinkTo } from '@ember/routing'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ArrowUpRight, BadgeCheck, Bookmark } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Badge,
  Icon,
  Spinner,
  asBadge,
  badgeAttributes,
  badgeClasses,
  type BadgeVariant,
} from '@ember-joinery/ember'
import { BadgeHarness, IconHarness, SpinnerHarness } from '@ember-joinery/test-support'

const VARIANTS: BadgeVariant[] = ['default', 'secondary', 'destructive', 'outline', 'ghost', 'link']

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/** What a CSS colour (`var(--primary)`) computes to here, to compare with a rendered one. */
function color(value: string, property: 'color' | 'backgroundColor' = 'backgroundColor'): string {
  const probe = document.createElement('div')
  probe.style[property] = value
  getRootElement().append(probe)
  const computed = getComputedStyle(probe)[property]
  probe.remove()
  return computed
}

module('Integration | components | badge', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a span with upstream classes and data attributes', async function (assert) {
    await render(
      <template>
        <Badge>Badge</Badge>
      </template>,
    )
    const badge = new BadgeHarness()
    assert
      .dom(badge.element)
      .hasTagName('span')
      .hasText('Badge')
      .hasClass('jn-badge')
      .hasClass('group/badge')
      .hasClass('jn-badge-variant-default')
      .hasAttribute('data-slot', 'badge')
      .hasAttribute('data-variant', 'default')
      .hasAttribute('data-test-jn', 'badge')
      .doesNotHaveAttribute('data-test-jn-name', 'none without @name')
    assert.strictEqual(badge.text, 'Badge')
    assert.strictEqual(badge.variant, 'default')
    assert.false(badge.isLink)
    assert.strictEqual(badge.href, null)
    await a11yAudit()
  })

  test('every variant renders its class and data attribute, and looks its own', async function (assert) {
    await render(
      <template>
        {{#each VARIANTS as |variant|}}
          <Badge @variant={{variant}} @name={{variant}}>{{variant}}</Badge>
        {{/each}}
      </template>,
    )
    const backgrounds = new Set<string>()
    for (const variant of VARIANTS) {
      const badge = new BadgeHarness(variant)
      assert.strictEqual(badge.variant, variant)
      assert.dom(badge.element).hasClass(`jn-badge-variant-${variant}`)
      backgrounds.add(`${getComputedStyle(badge.element).backgroundColor}`)
    }
    const style = (name: string) => getComputedStyle(new BadgeHarness(name).element)
    assert.strictEqual(style('default').backgroundColor, color('var(--primary)'), 'bg-primary')
    assert.strictEqual(style('default').color, color('var(--primary-foreground)', 'color'))
    assert.strictEqual(style('secondary').backgroundColor, color('var(--secondary)'))
    assert.strictEqual(style('outline').borderTopColor, color('var(--border)', 'color'))
    assert.strictEqual(style('destructive').color, color('var(--destructive)', 'color'))
    assert.strictEqual(style('ghost').backgroundColor, 'rgba(0, 0, 0, 0)', 'no fill until hover')
    assert.strictEqual(style('link').color, color('var(--primary)', 'color'))
    assert.ok(backgrounds.size >= 4, 'the variants differ')
    assert.strictEqual(BadgeHarness.findAll().length, VARIANTS.length)
    await a11yAudit()
  })

  test('its style sheet sizes it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Badge @name="plain">Badge</Badge>
        <Badge @name="icon" @variant="secondary">
          <Icon @icon={{BadgeCheck}} data-icon="inline-start" />
          Verified
        </Badge>
        <Badge @name="spinner" @variant="secondary">
          Generating
          <Spinner data-icon="inline-end" />
        </Badge>
      </template>,
    )
    const plain = getComputedStyle(new BadgeHarness('plain').element)
    assert.strictEqual(plain.display, 'inline-flex')
    assert.strictEqual(plain.height, '20px', 'h-5, border included')
    assert.strictEqual(plain.boxSizing, 'border-box')
    assert.strictEqual(plain.fontSize, '12px', 'text-xs')
    assert.strictEqual(plain.fontWeight, '500', 'font-medium')
    assert.strictEqual(plain.whiteSpace, 'nowrap')
    assert.strictEqual(plain.overflow, 'hidden')
    assert.strictEqual(plain.borderTopWidth, '1px')
    assert.strictEqual(plain.borderTopColor, 'rgba(0, 0, 0, 0)', 'border-transparent')
    assert.strictEqual(px(plain.paddingLeft), 8, 'px-2')
    assert.strictEqual(px(plain.paddingRight), 8)
    assert.strictEqual(plain.borderTopLeftRadius, '26px', "rounded-4xl: the theme's --radius × 2.6")

    const icon = new BadgeHarness('icon')
    const svg = icon.find(IconHarness).element
    assert.strictEqual(getComputedStyle(svg).width, '12px', '[&>svg]:size-3!')
    assert.strictEqual(getComputedStyle(svg).pointerEvents, 'none')
    assert.strictEqual(getComputedStyle(icon.element).columnGap, '4px', 'gap-1')
    assert.strictEqual(
      px(getComputedStyle(icon.element).paddingLeft),
      6,
      'has-data-[icon=inline-start]:ps-1.5',
    )

    const spinner = new BadgeHarness('spinner').find(SpinnerHarness).element
    assert.strictEqual(
      getComputedStyle(spinner).width,
      '12px',
      "the badge's size-3! beats the spinner's own size-4, as upstream's",
    )
    assert.strictEqual(
      px(getComputedStyle(new BadgeHarness('spinner').element).paddingRight),
      6,
      'has-data-[icon=inline-end]:pe-1.5',
    )
    await a11yAudit()
  })

  test('it takes attributes, and an app class adds to its own', async function (assert) {
    await render(
      <template>
        <Badge @name="mine" class="mine" title="Mine" aria-label="Mine">Mine</Badge>
      </template>,
    )
    const badge = new BadgeHarness('mine')
    assert
      .dom(badge.element)
      .hasClass('mine')
      .hasClass('jn-badge')
      .hasAttribute('title', 'Mine')
      .hasAttribute('data-test-jn-name', 'mine')
    await a11yAudit()
  })

  test('keyboard: a badge is not focusable, and a link badge is a link in the tab order', async function (assert) {
    await render(
      <template>
        <Badge @name="plain">Plain</Badge>
        <Badge @name="link" @as="a" href="#link">Open Link
          <Icon @icon={{ArrowUpRight}} data-icon="inline-end" /></Badge>
      </template>,
    )
    const plain = new BadgeHarness('plain')
    assert.strictEqual(plain.element.tabIndex, -1, 'a span takes no focus')

    const link = new BadgeHarness('link')
    assert.dom(link.element).hasTagName('a').hasAttribute('href', '#link')
    assert.true(link.isLink)
    assert.strictEqual(link.href, '#link')
    assert.strictEqual(link.element.tabIndex, 0, 'in the tab order: Enter follows it')
    await link.focus()
    assert.true(link.isFocused)
    assert.strictEqual(
      getComputedStyle(link.element).textDecorationLine,
      'none',
      "a link takes no underline, as preflight gives upstream's",
    )
    await link.blur()
    assert.false(link.isFocused)
    await a11yAudit()
  })

  test('the asBadge modifier makes any element a badge, and follows its arguments', async function (assert) {
    class State {
      @tracked variant: BadgeVariant = 'default'
    }
    const state = new State()
    await render(
      <template>
        <a href="#docs" {{asBadge variant=state.variant name="docs"}}>Docs</a>
      </template>,
    )
    const docs = new BadgeHarness('docs')
    assert.dom(docs.element).hasTagName('a').hasClass('jn-badge').hasClass('group/badge')
    assert.strictEqual(docs.variant, 'default')
    assert.strictEqual(getComputedStyle(docs.element).height, '20px', 'styled as a badge')

    state.variant = 'outline'
    await settled()
    assert.strictEqual(docs.variant, 'outline', 'the attributes follow')
    assert
      .dom(docs.element)
      .hasClass('jn-badge-variant-outline')
      .doesNotHaveClass('jn-badge-variant-default')
    await rerender()
    await a11yAudit()
  })

  test('the component and the modifier render the same classes and attributes', async function (assert) {
    await render(
      <template>
        {{#each VARIANTS as |variant|}}
          <Badge @variant={{variant}} @name="x" data-case="component">x</Badge>
          <span data-case="modifier" {{asBadge variant=variant name="x"}}>x</span>
        {{/each}}
        <Badge data-case="component">x</Badge>
        <span data-case="modifier" {{asBadge}}>x</span>
      </template>,
    )
    const components = [...document.querySelectorAll('[data-case="component"]')]
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    assert.strictEqual(components.length, VARIANTS.length + 1)
    components.forEach((component, index) => {
      assert.deepEqual(rendering(component), rendering(modifiers[index]!), `${index}: the same`)
    })
    const [first] = components
    assert.deepEqual(rendering(first!).classes, badgeClasses().split(' ').sort())
    for (const [name, value] of Object.entries(badgeAttributes({ name: 'x' }))) {
      assert.strictEqual(first!.getAttribute(name), value ?? null, name)
    }
    await a11yAudit()
  })

  test('<LinkTo {{asBadge}}> is a link that looks like a badge', async function (assert) {
    ;(this.owner as unknown as { setupRouter(): void }).setupRouter()
    await render(
      <template>
        <LinkTo @route="index" class="mine" {{asBadge variant="secondary" name="home"}}>
          Home
        </LinkTo>
      </template>,
    )
    const home = new BadgeHarness('home')
    assert.dom(home.element).hasTagName('a').hasAttribute('href', '/').hasClass('mine')
    assert.strictEqual(home.variant, 'secondary')
    assert.true(home.isLink)
    assert.strictEqual(getComputedStyle(home.element).display, 'inline-flex')
    await a11yAudit()
  })

  test('RTL: the narrower padding goes on the icon’s side, and the icon on the inline end', async function (assert) {
    await render(
      <template>
        <Badge @name="ltr" @variant="outline">Bookmark
          <Icon @icon={{Bookmark}} data-icon="inline-end" /></Badge>
        <DirectionProvider @dir="rtl">
          <Badge @name="rtl" @variant="outline">إشارة مرجعية
            <Icon @icon={{Bookmark}} data-icon="inline-end" /></Badge>
        </DirectionProvider>
      </template>,
    )
    for (const [name, onTheRight] of [
      ['ltr', true],
      ['rtl', false],
    ] as const) {
      const badge = new BadgeHarness(name)
      const box = badge.element.getBoundingClientRect()
      const icon = badge.find(IconHarness).element.getBoundingClientRect()
      assert.strictEqual(
        icon.left > box.left + box.width / 2,
        onTheRight,
        `${name}: the icon's side`,
      )
    }
    const ltr = getComputedStyle(new BadgeHarness('ltr').element)
    const rtl = getComputedStyle(new BadgeHarness('rtl').element)
    assert.deepEqual([px(ltr.paddingLeft), px(ltr.paddingRight)], [8, 6])
    assert.deepEqual([px(rtl.paddingLeft), px(rtl.paddingRight)], [6, 8])
    await a11yAudit()
  })
})
