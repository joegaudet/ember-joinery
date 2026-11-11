import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Loader, LoaderCircle, Plus, type IconNode } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Icon, Spinner } from '@ember-joinery/ember'
import { ButtonHarness, IconHarness, SpinnerHarness } from '@ember-joinery/test-support'

/** The `d` of every path an icon draws, to tell one icon from another. */
function paths(element: Element): string[] {
  return [...element.querySelectorAll('path')].map(path => path.getAttribute('d') ?? '')
}

/** The paths a lucide icon is drawn with. */
function lucidePaths(icon: IconNode): string[] {
  return (icon[2] ?? [])
    .filter(([tag]) => tag === 'path')
    .map(([, attributes]) => String(attributes['d']))
}

module('Integration | components | spinner', function (hooks) {
  setupRenderingTest(hooks)

  test('it is a turning loader-circle with the status role', async function (assert) {
    await render(
      <template>
        <Spinner />
        <Spinner @name="saving" @label="Saving" data-icon="inline-start" />
      </template>,
    )
    const spinner = new SpinnerHarness()
    assert.strictEqual(spinner.role, 'status')
    assert.strictEqual(spinner.label, 'Loading', 'an English default')
    assert
      .dom(spinner.element)
      .hasTagName('svg')
      .hasClass('jn-spinner')
      .hasClass('lucide')
      .hasClass('jn-size-4', "the size- marker upstream's svg:not([class*='size-']) rules look for")
      .hasAttribute('data-slot', 'spinner')
      .hasAttribute('data-test-jn', 'spinner')
      .doesNotHaveAttribute('aria-hidden')
    assert.deepEqual(paths(spinner.element), lucidePaths(LoaderCircle), "lucide's loader-circle")
    const style = getComputedStyle(spinner.element)
    assert.strictEqual(style.width, '16px', 'size-4')
    assert.strictEqual(style.height, '16px', 'size-4')
    assert.ok(style.animationName.includes('spin'), 'animate-spin')
    assert.notStrictEqual(style.animationDuration, '0s')

    const saving = new SpinnerHarness('saving')
    assert.strictEqual(saving.label, 'Saving')
    assert.dom(saving.element).hasAttribute('data-icon', 'inline-start')
    await a11yAudit()
  })

  test('@icon turns another icon, and a class sizes it', async function (assert) {
    // An app's own CSS, unlayered: it wins over Joinery's layer, as upstream's size-* classes do.
    const sheet = document.createElement('style')
    sheet.textContent = '.spinner-large { width: 32px; height: 32px; }'
    document.head.append(sheet)
    try {
      await render(
        <template>
          <Spinner @name="loader" @icon={{Loader}} />
          <Spinner @name="large" class="spinner-large" />
        </template>,
      )
      const loader = new SpinnerHarness('loader')
      assert.deepEqual(paths(loader.element), lucidePaths(Loader), "lucide's loader")
      assert.strictEqual(loader.role, 'status')
      assert.strictEqual(loader.label, 'Loading')
      assert.dom(loader.element).hasClass('jn-spinner').hasAttribute('data-slot', 'spinner')
      assert.ok(getComputedStyle(loader.element).animationName.includes('spin'))

      const large = new SpinnerHarness('large').element
      assert.dom(large).hasClass('spinner-large').hasClass('jn-spinner')
      assert.strictEqual(getComputedStyle(large).width, '32px')
      assert.strictEqual(getComputedStyle(large).height, '32px')
      await a11yAudit()
    } finally {
      sheet.remove()
    }
  })

  test("it keeps its own size in a small Button, which sizes only icons that don't have one", async function (assert) {
    await render(
      <template>
        <Button @name="xs" @size="xs" disabled><Spinner />Saving</Button>
        <Button @name="icon" @size="xs" aria-label="Add"><Icon @icon={{Plus}} /></Button>
      </template>,
    )
    const spinner = new ButtonHarness('xs').find(SpinnerHarness).element
    assert.strictEqual(getComputedStyle(spinner).width, '16px', 'size-4, as upstream')
    const icon = new ButtonHarness('icon').find(IconHarness).element
    assert.strictEqual(getComputedStyle(icon).width, '12px', "xs's size-3 for an icon")
    await a11yAudit()
  })

  test('in a Button, it takes the inline-start side, and right to left that is the right', async function (assert) {
    await render(
      <template>
        <Button @name="ltr" disabled><Spinner data-icon="inline-start" />Saving</Button>
        <DirectionProvider @dir="rtl">
          <Button @name="rtl" disabled><Spinner data-icon="inline-start" />جاري الحفظ</Button>
        </DirectionProvider>
      </template>,
    )
    for (const [name, onTheLeft] of [
      ['ltr', true],
      ['rtl', false],
    ] as const) {
      const button = new ButtonHarness(name)
      const box = button.element.getBoundingClientRect()
      const spinner = button.find(SpinnerHarness).element.getBoundingClientRect()
      assert.strictEqual(spinner.left < box.left + box.width / 2, onTheLeft, `${name}: its side`)
      assert.strictEqual(getComputedStyle(button.find(SpinnerHarness).element).width, '16px')
    }
    // The narrower padding goes on the spinner's side (has-data-[icon=inline-start]:ps-2).
    assert.strictEqual(getComputedStyle(new ButtonHarness('ltr').element).paddingLeft, '8px')
    assert.strictEqual(getComputedStyle(new ButtonHarness('rtl').element).paddingRight, '8px')
    await a11yAudit()
  })
})
