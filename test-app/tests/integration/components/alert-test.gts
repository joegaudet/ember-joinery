import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CircleCheck, Info } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Alert, Button, Icon, type AlertVariant } from '@ember-joinery/ember'
import { AlertHarness, ButtonHarness } from '@ember-joinery/test-support'

const VARIANTS: AlertVariant[] = ['default', 'destructive']

/**
 * The audit, but for a destructive alert's description: upstream's colour for it, 90% of
 * `--destructive` on `--card`, measures 4.49:1 in the default theme, a hair under WCAG AA's 4.5:1
 * for small text. Joinery keeps upstream's style sheets as they are, so the guide's Accessibility
 * section says how to give it the full colour; every other element is audited.
 */
const DESTRUCTIVE_DESCRIPTION = '[data-variant="destructive"] > [data-slot="alert-description"]'
const auditButDestructiveDescription = () =>
  a11yAudit({ include: [['#ember-testing-container']], exclude: [[DESTRUCTIVE_DESCRIPTION]] })

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

module('Integration | components | alert', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Alert as |a|>
          <Icon @icon={{Info}} />
          <a.Title>Heads up!</a.Title>
          <a.Description>
            You can add components and dependencies to your app using the cli.
          </a.Description>
          <a.Action><Button @variant="outline">Enable</Button></a.Action>
        </Alert>
      </template>,
    )
    const alert = new AlertHarness()

    assert
      .dom(alert.element)
      .hasTagName('div')
      .hasClass('jn-alert')
      .hasClass('group/alert', 'the marker the title rule looks for')
      .hasClass('jn-alert-variant-default')
      .hasAttribute('data-slot', 'alert')
      .hasAttribute('role', 'alert')
      .hasAttribute('data-variant', 'default')
      .hasAttribute('data-test-jn', 'alert')
    assert
      .dom(alert.part('title'))
      .hasClass('jn-alert-title')
      .hasAttribute('data-slot', 'alert-title')
    assert
      .dom(alert.part('description'))
      .hasClass('jn-alert-description')
      .hasAttribute('data-slot', 'alert-description')
    assert
      .dom(alert.part('action'))
      .hasClass('jn-alert-action')
      .hasAttribute('data-slot', 'alert-action')
    assert.strictEqual(alert.title, 'Heads up!')
    assert.strictEqual(
      alert.description,
      'You can add components and dependencies to your app using the cli.',
    )
    assert.strictEqual(alert.variant, 'default')
    assert.strictEqual(alert.role, 'alert')
    assert.true(alert.hasIcon)
    assert.strictEqual(alert.find(ButtonHarness).label, 'Enable')
    await a11yAudit()
  })

  test('every variant renders its class and data attribute', async function (assert) {
    await render(
      <template>
        {{#each VARIANTS as |variant|}}
          <Alert @variant={{variant}} @name={{variant}} as |a|>
            <a.Title>{{variant}}</a.Title>
          </Alert>
        {{/each}}
      </template>,
    )
    for (const variant of VARIANTS) {
      const alert = new AlertHarness(variant)
      assert.strictEqual(alert.variant, variant)
      assert.dom(alert.element).hasClass(`jn-alert-variant-${variant}`)
    }
    assert.strictEqual(AlertHarness.findAll().length, VARIANTS.length)
    await a11yAudit()
  })

  test('its style sheet lays it out and colours it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Alert @name="plain" as |a|>
          <a.Title>Plain</a.Title>
          <a.Description>No icon, no action.</a.Description>
        </Alert>
        <Alert @name="icon" as |a|>
          <Icon @icon={{CircleCheck}} />
          <a.Title>With an icon</a.Title>
          <a.Description>The icon takes the first column.</a.Description>
        </Alert>
        <Alert @name="destructive" @variant="destructive" as |a|>
          <a.Title>Destructive</a.Title>
          <a.Description>In the destructive colour.</a.Description>
        </Alert>
        <Alert @name="action" as |a|>
          <a.Title>With an action</a.Title>
          <a.Action><Button @size="xs">Enable</Button></a.Action>
        </Alert>
      </template>,
    )
    const plain = new AlertHarness('plain')
    const style = getComputedStyle(plain.element)
    assert.strictEqual(style.display, 'grid')
    assert.strictEqual(style.boxSizing, 'border-box')
    assert.strictEqual(style.borderTopWidth, '1px', 'border')
    assert.strictEqual(style.borderTopStyle, 'solid')
    assert.strictEqual(style.borderTopLeftRadius, '10px', "rounded-lg: the theme's --radius")
    assert.strictEqual(style.paddingLeft, '10px', 'px-2.5')
    assert.strictEqual(style.paddingTop, '8px', 'py-2')
    assert.strictEqual(style.fontSize, '14px', 'text-sm')
    assert.strictEqual(style.position, 'relative')
    assert.strictEqual(style.rowGap, '2px', 'gap-0.5')
    assert.strictEqual(getComputedStyle(plain.part('title')).fontWeight, '500', 'font-medium')
    assert.notStrictEqual(
      getComputedStyle(plain.part('description')).color,
      getComputedStyle(plain.part('title')).color,
      'the description is muted',
    )

    const icon = new AlertHarness('icon')
    const columns = getComputedStyle(icon.element).gridTemplateColumns.split(' ')
    assert.strictEqual(columns.length, 2, 'an icon makes two columns')
    assert.strictEqual(columns[0], '16px', 'the icon, size-4')
    assert.strictEqual(getComputedStyle(icon.element).columnGap, '8px', 'gap-x-2')
    const svg = icon.element.querySelector('svg')!
    assert.strictEqual(getComputedStyle(svg).width, '16px')
    assert.strictEqual(getComputedStyle(icon.part('title')).gridColumnStart, '2', 'col-start-2')

    const destructive = new AlertHarness('destructive')
    assert.notStrictEqual(
      getComputedStyle(destructive.element).color,
      style.color,
      'the destructive text colour',
    )

    const action = new AlertHarness('action')
    assert.strictEqual(
      getComputedStyle(action.element).paddingRight,
      '72px',
      'pe-18 leaves room for the action',
    )
    const box = getComputedStyle(action.part('action'))
    assert.strictEqual(box.position, 'absolute')
    assert.strictEqual(box.top, '8px', 'top-2')
    assert.strictEqual(box.right, '8px', 'end-2')
    await auditButDestructiveDescription()
  })

  test('it takes attributes, a class and @as on every part', async function (assert) {
    await render(
      <template>
        <Alert @as="section" @name="notice" class="mine" role="status" aria-live="polite" as |a|>
          <a.Title @as="h2" class="title">Saved</a.Title>
          <a.Description @as="p" id="saved-description">Your changes are saved.</a.Description>
          <a.Action @as="span">Undo</a.Action>
        </Alert>
      </template>,
    )
    const alert = new AlertHarness('notice')
    assert
      .dom(alert.element)
      .hasTagName('section')
      .hasClass('mine')
      .hasClass('jn-alert')
      .hasAttribute('role', 'status', "the caller's attributes win")
      .hasAttribute('aria-live', 'polite')
    assert.strictEqual(alert.role, 'status')
    assert.dom(alert.part('title')).hasTagName('h2').hasClass('title').hasClass('jn-alert-title')
    assert
      .dom(alert.part('description'))
      .hasTagName('p')
      .hasAttribute('id', 'saved-description')
      .hasClass('jn-alert-description')
    assert.dom(alert.part('action')).hasTagName('span')
    assert.strictEqual(alert.title, 'Saved')
    await a11yAudit()
  })

  test('keyboard: an alert takes no focus of its own; its action is in the tab order', async function (assert) {
    // The APG alert pattern: an alert doesn't move focus or need a key, so it interrupts no one.
    await render(
      <template>
        <Alert as |a|>
          <a.Title>Dark mode is now available</a.Title>
          <a.Action><Button @name="enable">Enable</Button></a.Action>
        </Alert>
      </template>,
    )
    const alert = new AlertHarness()
    assert.strictEqual(alert.element.tabIndex, -1, 'not in the tab order')
    assert.notStrictEqual(document.activeElement, alert.element, "rendering it doesn't take focus")
    const enable = new ButtonHarness('enable')
    assert.strictEqual(enable.element.tabIndex, 0)
    await enable.focus()
    assert.true(enable.isFocused)
    await a11yAudit()
  })

  test('the part modifiers make your own elements its parts, as the components do', async function (assert) {
    await render(
      <template>
        <Alert @name="components" as |a|>
          <a.Title data-case="component">Title</a.Title>
          <a.Description data-case="component">Description</a.Description>
          <a.Action data-case="component">Action</a.Action>
        </Alert>
        <Alert @name="modifiers" as |a|>
          <div data-case="modifier" {{a.title}}>Title</div>
          <div data-case="modifier" {{a.description}}>Description</div>
          <div data-case="modifier" {{a.action}}>Action</div>
        </Alert>
      </template>,
    )
    const components = [...document.querySelectorAll('[data-case="component"]')]
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    assert.strictEqual(components.length, 3)
    components.forEach((component, index) => {
      assert.deepEqual(
        rendering(modifiers[index]!),
        rendering(component),
        `part ${index}: the same`,
      )
    })
    const alert = new AlertHarness('modifiers')
    assert.strictEqual(alert.title, 'Title', 'the harness finds them')
    assert.strictEqual(alert.description, 'Description')
    assert.strictEqual(getComputedStyle(alert.part('title')).fontWeight, '500', 'styled as a title')
    await a11yAudit()
  })

  test('RTL: the icon, the text and the action change sides', async function (assert) {
    await render(
      <template>
        <Alert @name="ltr" as |a|>
          <Icon @icon={{CircleCheck}} />
          <a.Title>Payment successful</a.Title>
          <a.Action><Button @size="xs">View</Button></a.Action>
        </Alert>
        <DirectionProvider @dir="rtl">
          <Alert @name="rtl" as |a|>
            <Icon @icon={{CircleCheck}} />
            <a.Title>تم الدفع بنجاح</a.Title>
            <a.Action><Button @size="xs">عرض</Button></a.Action>
          </Alert>
        </DirectionProvider>
      </template>,
    )
    const ltr = new AlertHarness('ltr')
    const rtl = new AlertHarness('rtl')
    const left = (element: Element) => element.getBoundingClientRect().left

    assert.ok(
      left(ltr.element.querySelector('svg')!) < left(ltr.part('title')),
      'left to right, the icon is left of the title',
    )
    assert.ok(
      left(rtl.element.querySelector('svg')!) > left(rtl.part('title')),
      'right to left, the icon is right of the title',
    )
    assert.strictEqual(px(getComputedStyle(ltr.element).paddingRight), 72, 'pe-18 on the right')
    assert.strictEqual(px(getComputedStyle(rtl.element).paddingLeft), 72, 'pe-18 on the left')
    assert.strictEqual(px(getComputedStyle(rtl.element).paddingRight), 10)
    const action = getComputedStyle(rtl.part('action'))
    assert.strictEqual(action.left, '8px', 'end-2: right to left, the action sits on the left')
    assert.strictEqual(getComputedStyle(rtl.element).textAlign, 'start')
    await a11yAudit()
  })

  test('the harness reads an alert without a title, an icon or a description', async function (assert) {
    await render(
      <template>
        <Alert @name="bare">Just text</Alert>
      </template>,
    )
    const bare = new AlertHarness('bare')
    assert.strictEqual(bare.title, '', 'no title')
    assert.strictEqual(bare.description, '')
    assert.false(bare.hasIcon)
    assert.strictEqual(bare.text, 'Just text')
    assert.throws(() => new AlertHarness('missing').element, /no alert "missing" found/)
    await a11yAudit()
  })
})
