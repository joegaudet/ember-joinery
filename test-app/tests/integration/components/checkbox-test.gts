import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Minus, X } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Checkbox } from '@ember-joinery/ember'
import type { CheckedState } from '@ember-joinery/primitives/checkbox'
import { CheckboxHarness, IconHarness, pressKey, tab } from '@ember-joinery/test-support'

/** A colour as the browser resolves it, for comparing with a token. */
function resolved(color: string): string {
  const probe = document.createElement('span')
  probe.style.color = color
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe).color
  probe.remove()
  return value
}

module('Integration | components | checkbox', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's classes and slots, and its mark only while checked", async function (assert) {
    await render(
      <template>
        <Checkbox @name="terms" id="terms" />
        <label for="terms">Accept terms and conditions</label>
        <Checkbox @name="news" @defaultChecked={{true}} aria-label="Newsletter" />
      </template>,
    )
    const terms = new CheckboxHarness('terms')
    assert
      .dom(terms.element)
      .hasTagName('button')
      .hasClass('jn-checkbox')
      .hasClass('peer', "the marker upstream's labels look for")
      .hasAttribute('data-slot', 'checkbox')
      .hasAttribute('role', 'checkbox')
      .hasAttribute('data-state', 'unchecked')
      .hasAttribute('data-test-jn', 'checkbox')
    assert.strictEqual(terms.indicator, null)
    assert.strictEqual(terms.label, 'Accept terms and conditions')

    const news = new CheckboxHarness('news')
    assert
      .dom(news.indicator)
      .hasClass('jn-checkbox-indicator')
      .hasAttribute('data-slot', 'checkbox-indicator')
      .hasAttribute('data-state', 'checked')
    const check = news.find(IconHarness)
    assert.true(check.isDecorative, 'the check mark is hidden from assistive technology')
    assert.dom(check.element).hasClass('lucide')
    await a11yAudit()
  })

  test('its style sheet sizes and colours it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Checkbox @name="off" aria-label="Off" />
        <Checkbox @name="on" @defaultChecked={{true}} aria-label="On" />
        <Checkbox @name="invalid" aria-invalid="true" aria-label="Invalid" />
        <Checkbox @name="disabled" @disabled={{true}} aria-label="Disabled" />
      </template>,
    )
    const style = (name: string) => getComputedStyle(new CheckboxHarness(name).element)
    const off = style('off')
    assert.strictEqual(off.width, '16px', 'size-4')
    assert.strictEqual(off.height, '16px')
    assert.strictEqual(off.boxSizing, 'border-box')
    assert.strictEqual(off.borderTopWidth, '1px')
    assert.strictEqual(off.borderTopLeftRadius, '4px', 'rounded-[4px]')
    assert.strictEqual(off.borderTopColor, resolved('var(--input)'), 'border-input')
    assert.strictEqual(off.position, 'relative')
    assert.strictEqual(off.flexShrink, '0')

    const on = style('on')
    assert.strictEqual(on.backgroundColor, resolved('var(--primary)'), 'data-checked:bg-primary')
    assert.strictEqual(on.borderTopColor, resolved('var(--primary)'))
    assert.strictEqual(on.color, resolved('var(--primary-foreground)'))
    const svg = new CheckboxHarness('on').indicator!.querySelector('svg')!
    assert.strictEqual(getComputedStyle(svg).width, '14px', '[&>svg]:size-3.5')

    assert.strictEqual(
      style('invalid').borderTopColor,
      resolved('var(--destructive)'),
      'aria-invalid:border-destructive',
    )
    assert.strictEqual(style('disabled').opacity, '0.5', 'disabled:opacity-50')
    assert.strictEqual(style('disabled').cursor, 'not-allowed')

    const hitArea = getComputedStyle(new CheckboxHarness('off').element, '::after')
    assert.strictEqual(hitArea.position, 'absolute', 'a larger target, after:absolute')
    assert.strictEqual(hitArea.left, '-12px', 'after:-inset-x-3')
    assert.strictEqual(hitArea.top, '-8px', 'after:-inset-y-2')
    await a11yAudit()
  })

  test('controlled, uncontrolled and indeterminate, with icons of your own', async function (assert) {
    class State {
      @tracked checked: CheckedState = 'indeterminate'
    }
    const state = new State()
    const change = (checked: CheckedState) => (state.checked = checked)
    await render(
      <template>
        <Checkbox
          @name="all"
          @checked={{state.checked}}
          @onCheckedChange={{change}}
          @indeterminateIcon={{Minus}}
          aria-label="Select all"
        />
        <Checkbox @name="own" @icon={{X}} @defaultChecked={{true}} aria-label="Own" />
      </template>,
    )
    const all = new CheckboxHarness('all')
    assert.true(all.isIndeterminate)
    const mark = () => all.indicator!.querySelector('svg path')!.getAttribute('d')
    assert.strictEqual(mark(), 'M5 12h14', "lucide's minus, while indeterminate")
    await all.click()
    assert.strictEqual(state.checked, true)
    assert.strictEqual(mark(), 'M20 6 9 17l-5-5', "lucide's check, once checked")
    await all.uncheck()
    assert.false(all.isChecked)

    const own = new CheckboxHarness('own')
    assert.strictEqual(own.indicator!.querySelectorAll('svg path').length, 2, "lucide's x")
    await own.toggle()
    assert.false(own.isChecked)
    await a11yAudit()
  })

  test('without @indeterminateIcon, it shows the check while indeterminate, as upstream', async function (assert) {
    await render(<template><Checkbox @checked="indeterminate" aria-label="Some" /></template>)
    const some = new CheckboxHarness()
    assert.dom(some.element).hasAttribute('aria-checked', 'mixed')
    assert
      .dom(some.indicator!.querySelector('path'))
      .hasAttribute('d', 'M20 6 9 17l-5-5', "upstream's CheckIcon")
    assert.notStrictEqual(
      getComputedStyle(some.element).backgroundColor,
      resolved('var(--primary)'),
      'data-checked styles only the checked state',
    )
    await a11yAudit()
  })

  test('keyboard: Tab reaches it, Enter is cancelled, and a disabled one is passed over', async function (assert) {
    await render(
      <template>
        <Checkbox @name="first" aria-label="First" />
        <Checkbox @name="off" @disabled={{true}} aria-label="Off" />
        <Checkbox @name="last" aria-label="Last" />
      </template>,
    )
    await tab()
    assert.true(new CheckboxHarness('first').isFocused)
    assert.true(await pressKey('Enter'))
    assert.false(new CheckboxHarness('first').isChecked)
    await tab()
    assert.true(new CheckboxHarness('last').isFocused)
    await a11yAudit()
  })

  test('in a form, name and value go to a hidden checkbox', async function (assert) {
    await render(
      <template>
        <form id="prefs">
          <Checkbox @name="disks" name="hard-disks" @defaultChecked={{true}} aria-label="Disks" />
        </form>
      </template>,
    )

    const disks = new CheckboxHarness('disks')
    assert.dom(disks.input).hasAttribute('name', 'hard-disks')
    const formElement = document.querySelector<HTMLFormElement>('#prefs')!
    assert.deepEqual([...new FormData(formElement).entries()], [['hard-disks', 'on']])
    await click(disks.element)
    assert.deepEqual([...new FormData(formElement).entries()], [])
    await a11yAudit()
  })

  test('RTL: it sits at the inline start of its row, and its mark stays centred', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="display: flex; gap: 8px; width: 200px">
            <Checkbox @name="rtl" id="rtl" @defaultChecked={{true}} />
            <label for="rtl">قبول الشروط والأحكام</label>
          </div>
        </DirectionProvider>
      </template>,
    )
    const box = new CheckboxHarness('rtl')
    const row = box.element.parentElement!.getBoundingClientRect()
    const rect = box.element.getBoundingClientRect()
    assert.strictEqual(Math.round(rect.right), Math.round(row.right), 'on the right')
    const mark = box.indicator!.querySelector('svg')!.getBoundingClientRect()
    assert.strictEqual(
      Math.round(mark.left + mark.width / 2),
      Math.round(rect.left + rect.width / 2),
      'the check is centred',
    )
    assert.strictEqual(box.label, 'قبول الشروط والأحكام')
    await a11yAudit()
  })

  test('@as, attributes and the harness', async function (assert) {
    await render(
      <template>
        <Checkbox
          @name="span"
          @as="span"
          tabindex="0"
          class="mine"
          aria-label="Span"
          @required={{true}}
        />
      </template>,
    )
    const span = new CheckboxHarness('span')
    assert.dom(span.element).hasTagName('span').hasClass('mine').hasClass('jn-checkbox')
    assert.true(span.isRequired)
    assert.false(span.isInvalid)
    assert.false(span.isDisabled)
    await span.focus()
    assert.true(span.isFocused)
    await span.blur()
    assert.false(span.isFocused)
    await span.check()
    assert.true(span.isChecked)
    await span.check()
    assert.true(span.isChecked, 'check() leaves a checked box alone')
    assert.throws(() => new CheckboxHarness('missing').element, /no checkbox "missing" found/)
    await a11yAudit()
  })
})
