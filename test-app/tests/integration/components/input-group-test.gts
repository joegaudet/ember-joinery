import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { finishTransitions, shadowReach } from 'test-app/tests/helpers/shadow'
import { click, render, rerender, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Copy, Search } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Icon,
  InputGroup,
  Kbd,
  inputGroupAddonAttributes,
  inputGroupAddonClasses,
  inputGroupButtonAttributes,
  inputGroupButtonClasses,
} from '@ember-joinery/ember'
import {
  ButtonHarness,
  InputGroupHarness,
  InputHarness,
  TextareaHarness,
  tab,
} from '@ember-joinery/test-support'

const px = (value: string) => Number.parseFloat(value)

/** The audit, but for Kbd's keys, whose upstream colours fall short of AA (see the Kbd page). */
const BUT_THE_KEYS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="kbd"]']],
}

module('Integration | components | input-group', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's group, control, addons and text, with their classes and data attributes", async function (assert) {
    await render(
      <template>
        <InputGroup @name="search" as |g|>
          <g.Input @name="query" placeholder="Search..." />
          <g.Addon><Icon @icon={{Search}} /></g.Addon>
          <g.Addon @align="inline-end"><g.Text>12 results</g.Text></g.Addon>
        </InputGroup>
      </template>,
    )
    const search = new InputGroupHarness('search')
    assert
      .dom(search.element)
      .hasTagName('div')
      .hasClass('jn-input-group')
      .hasClass('group/input-group', 'the marker its parts look for')
      .hasAttribute('role', 'group')
      .hasAttribute('data-slot', 'input-group')
    assert
      .dom(search.control)
      .hasTagName('input')
      .hasClass('jn-input')
      .hasClass('jn-input-group-input')
      .hasAttribute('data-slot', 'input-group-control')
      .hasAttribute('placeholder', 'Search...')
    assert.strictEqual(
      new InputHarness('query').element,
      search.control,
      'an Input, for its harness',
    )
    assert.deepEqual(search.aligns, ['inline-start', 'inline-end'])
    assert
      .dom(search.addon())
      .hasClass('jn-input-group-addon')
      .hasClass('jn-input-group-addon-align-inline-start')
      .hasAttribute('role', 'group')
      .hasAttribute('data-slot', 'input-group-addon')
      .hasAttribute('data-align', 'inline-start')
    assert.dom(search.addon('inline-end')).hasClass('jn-input-group-addon-align-inline-end')
    assert.deepEqual(search.texts, ['12 results'])
    assert.dom('.jn-input-group-text').hasTagName('span').doesNotHaveAttribute('data-slot')
    assert.strictEqual(search.addonText('inline-end'), '12 results')
    assert.strictEqual(search.icons.length, 1)
    assert.strictEqual(search.label, 'Search...')
    await a11yAudit()
  })

  test('its style sheet draws one field around the control and its addons', async function (assert) {
    await render(
      <template>
        <div style="width: 320px">
          <InputGroup @name="search" as |g|>
            <g.Input placeholder="Search..." />
            <g.Addon><Icon @icon={{Search}} /></g.Addon>
            <g.Addon @align="inline-end">12 results</g.Addon>
          </InputGroup>
        </div>
      </template>,
    )
    const search = new InputGroupHarness('search')
    const group = getComputedStyle(search.element)
    assert.strictEqual(group.display, 'flex')
    assert.strictEqual(group.height, '32px', 'h-8')
    assert.strictEqual(group.width, '320px', 'w-full')
    assert.strictEqual(group.borderTopWidth, '1px')
    assert.strictEqual(group.borderTopLeftRadius, '10px', "rounded-lg: the theme's --radius")

    const control = getComputedStyle(search.control)
    assert.strictEqual(control.borderTopWidth, '0px', 'the control has no border of its own')
    assert.strictEqual(shadowReach(search.control), 0, 'nor a shadow')
    assert.strictEqual(control.backgroundColor, 'rgba(0, 0, 0, 0)')
    assert.strictEqual(control.flexGrow, '1', 'flex-1')
    assert.strictEqual(control.paddingLeft, '6px', 'ps-1.5 beside an inline-start addon')
    assert.strictEqual(control.paddingRight, '6px', 'pe-1.5 beside an inline-end addon')

    const start = search.addon('inline-start')
    const end = search.addon('inline-end')
    assert.ok(Number(getComputedStyle(start).order) < 0, 'order-first, though it comes after')
    assert.ok(Number(getComputedStyle(end).order) > 0, 'order-last')
    assert.ok(start.getBoundingClientRect().right <= search.control.getBoundingClientRect().left)
    assert.strictEqual(getComputedStyle(start).paddingLeft, '8px', 'ps-2')
    assert.strictEqual(getComputedStyle(end).paddingRight, '8px', 'pe-2')
    assert.strictEqual(getComputedStyle(start).fontSize, '14px', 'text-sm')
    assert.strictEqual(getComputedStyle(search.icons[0]!).width, '16px', 'its icon is size-4')
    assert.strictEqual(getComputedStyle(start).cursor, 'text')

    assert.strictEqual(shadowReach(search.element), 0)
    const border = group.borderTopColor
    await search.focus()
    assert.strictEqual(
      shadowReach(search.element),
      3,
      "the control's focus rings the group: ring-3",
    )
    assert.notStrictEqual(finishTransitions(search.element).borderTopColor, border, 'border-ring')
    await a11yAudit()
  })

  test('block addons stack the group, above and below a textarea', async function (assert) {
    await render(
      <template>
        <InputGroup @name="comment" as |g|>
          <g.Textarea @name="body" placeholder="Write a comment..." />
          <g.Addon @align="block-end">
            <g.Text>0/280</g.Text>
            <g.Button @variant="default" @size="sm" class="ml-auto">Post</g.Button>
          </g.Addon>
          <g.Addon @align="block-start"><g.Text>script.js</g.Text></g.Addon>
        </InputGroup>
      </template>,
    )
    const comment = new InputGroupHarness('comment')
    assert.dom(comment.control).hasTagName('textarea').hasClass('jn-input-group-textarea')
    assert.strictEqual(new TextareaHarness('body').element, comment.control)
    const group = getComputedStyle(comment.element)
    assert.strictEqual(group.flexDirection, 'column', 'has-[>[data-align=block-*]]:flex-col')
    assert.notStrictEqual(group.height, '32px', 'h-auto')
    const textarea = getComputedStyle(comment.control)
    assert.strictEqual(textarea.resize, 'none', 'resize-none')
    assert.strictEqual(textarea.paddingTop, '8px', 'py-2')
    const top = comment.addon('block-start').getBoundingClientRect()
    const bottom = comment.addon('block-end').getBoundingClientRect()
    const box = comment.control.getBoundingClientRect()
    assert.ok(top.bottom <= box.top, 'block-start: above')
    assert.ok(bottom.top >= box.bottom, 'block-end: below')
    assert.strictEqual(getComputedStyle(comment.addon('block-end')).justifyContent, 'flex-start')
    assert.strictEqual(Math.round(bottom.width), Math.round(box.width), 'w-full')

    await click(comment.addon('block-start'))
    assert.false(comment.isFocused, "upstream's addon focuses an input, not a textarea")
    await a11yAudit()
  })

  test('a press on an addon focuses the input, but not on a button in it', async function (assert) {
    let copies = 0
    const copy = () => copies++
    await render(
      <template>
        <InputGroup @name="url" as |g|>
          <g.Input placeholder="https://x.com/shadcn" readonly />
          <g.Addon @align="inline-end">
            <g.Text>Copy</g.Text>
            <g.Button @size="icon-xs" @name="copy" aria-label="Copy" {{on "click" copy}}>
              <Icon @icon={{Copy}} />
            </g.Button>
          </g.Addon>
        </InputGroup>
      </template>,
    )
    const url = new InputGroupHarness('url')
    const button = new ButtonHarness('copy')
    await button.click()
    assert.strictEqual(copies, 1)
    assert.false(url.isFocused, 'the button keeps its press')
    await click(url.part('text'))
    assert.true(url.isFocused, 'the addon focuses the input')
    await a11yAudit()
  })

  test("the group's buttons: ghost and xs, on a Button at its default size", async function (assert) {
    await render(
      <template>
        <InputGroup as |g|>
          <g.Input aria-label="Query" />
          <g.Addon @align="inline-end">
            <g.Button @name="xs">Search</g.Button>
            <g.Button @name="icon-xs" @size="icon-xs" aria-label="Copy">
              <Icon @icon={{Copy}} />
            </g.Button>
            <g.Button @name="icon-sm" @size="icon-sm" @variant="secondary" aria-label="Copy">
              <Icon @icon={{Copy}} />
            </g.Button>
            <g.Button @name="sm" @size="sm" type="submit">Go</g.Button>
          </g.Addon>
        </InputGroup>
      </template>,
    )
    const xs = new ButtonHarness('xs')
    assert
      .dom(xs.element)
      .hasClass('jn-button')
      .hasClass('jn-button-variant-ghost')
      .hasClass('jn-button-size-default', "upstream's keeps its size off the Button")
      .hasClass('jn-input-group-button')
      .hasClass('jn-input-group-button-size-xs')
      .hasAttribute('data-size', 'xs')
      .hasAttribute('data-variant', 'ghost')
      .hasAttribute('type', 'button')
    assert.strictEqual(getComputedStyle(xs.element).height, '24px', 'h-6')
    assert.strictEqual(getComputedStyle(xs.element).paddingLeft, '6px', 'px-1.5')
    assert.strictEqual(getComputedStyle(xs.element).display, 'flex', 'flex, over inline-flex')
    assert.strictEqual(shadowReach(xs.element), 0, 'shadow-none')

    const iconXs = getComputedStyle(new ButtonHarness('icon-xs').element)
    assert.strictEqual(iconXs.width, '24px', 'size-6')
    assert.strictEqual(iconXs.paddingLeft, '0px', 'p-0')
    const iconSm = new ButtonHarness('icon-sm')
    assert.strictEqual(getComputedStyle(iconSm.element).width, '32px', 'size-8')
    assert.strictEqual(iconSm.variant, 'secondary')
    const sm = new ButtonHarness('sm')
    assert.dom(sm.element).hasAttribute('type', 'submit', 'its own type wins')
    assert.strictEqual(getComputedStyle(sm.element).height, '32px', "Nova has no sm rule: Button's")
    await a11yAudit()
  })

  test('aria-invalid and disabled on the control style the whole group', async function (assert) {
    await render(
      <template>
        <InputGroup @name="plain" as |g|><g.Input aria-label="Plain" /></InputGroup>
        <InputGroup @name="invalid" as |g|>
          <g.Input aria-label="Invalid" aria-invalid="true" />
        </InputGroup>
        <InputGroup @name="disabled" as |g|>
          <g.Input aria-label="Disabled" disabled />
          <g.Addon><Icon @icon={{Search}} /></g.Addon>
        </InputGroup>
      </template>,
    )
    const plain = getComputedStyle(new InputGroupHarness('plain').element)
    const invalid = new InputGroupHarness('invalid')
    assert.true(invalid.isInvalid)
    const ringed = getComputedStyle(invalid.element)
    assert.notStrictEqual(ringed.borderTopColor, plain.borderTopColor, 'a destructive border')
    assert.strictEqual(shadowReach(invalid.element), 3, 'and ring')
    assert.strictEqual(shadowReach(invalid.control), 0, 'around the group, not the input')

    const disabled = new InputGroupHarness('disabled')
    assert.true(disabled.isDisabled)
    assert.strictEqual(getComputedStyle(disabled.element).opacity, '0.5', 'has-disabled:opacity-50')
    await a11yAudit()
  })

  test('controlled and uncontrolled, as its Input and Textarea', async function (assert) {
    class State {
      @tracked query = 'ada'
    }
    const state = new State()
    const setQuery = (value: string) => (state.query = value.toLowerCase())
    await render(
      <template>
        <InputGroup @name="theirs" as |g|>
          <g.Input @value={{state.query}} @onValueChange={{setQuery}} aria-label="Query" />
        </InputGroup>
        <InputGroup @name="own" as |g|>
          <g.Textarea @defaultValue="Draft" aria-label="Notes" />
        </InputGroup>
      </template>,
    )
    const theirs = new InputGroupHarness('theirs')
    await theirs.fillIn('GRACE')
    assert.strictEqual(theirs.value, 'grace')
    state.query = 'linus'
    await settled()
    assert.strictEqual(theirs.value, 'linus')
    const own = new InputGroupHarness('own')
    assert.strictEqual(own.value, 'Draft')
    await own.typeIn('!')
    assert.strictEqual(own.value, 'Draft!')
    await a11yAudit()
  })

  test('the keyboard: focus moves from the control through its addons, in DOM order', async function (assert) {
    await render(
      <template>
        <InputGroup as |g|>
          <g.Input aria-label="Query" />
          <g.Addon><g.Button @name="first">One</g.Button></g.Addon>
          <g.Addon @align="inline-end"><g.Button @name="second">Two</g.Button></g.Addon>
        </InputGroup>
      </template>,
    )
    const group = new InputGroupHarness()
    await group.focus()
    await tab()
    assert.dom(new ButtonHarness('first').element).isFocused('the inline-start addon, after')
    await tab()
    assert.dom(new ButtonHarness('second').element).isFocused()
    await a11yAudit()
  })

  test('its modifiers make your own elements its parts, the same as its components', async function (assert) {
    await render(
      <template>
        <InputGroup as |g|>
          <g.Input @name="a" aria-label="A" data-case="input-component" />
          <g.Addon @align="inline-end" data-case="addon-component">
            <g.Text data-case="text-component">x</g.Text>
            <g.Button @size="icon-xs" @name="b" data-case="button-component">b</g.Button>
          </g.Addon>
        </InputGroup>
        <InputGroup as |g|>
          <input aria-label="A" data-case="input-modifier" {{g.input name="a"}} />
          <div data-case="addon-modifier" {{g.addon align="inline-end"}}>
            <span data-case="text-modifier" {{g.text}}>x</span>
            <button
              type="button"
              data-case="button-modifier"
              {{g.button size="icon-xs" name="b"}}
            >b</button>
          </div>
        </InputGroup>
        <InputGroup @name="custom" as |g|>
          <textarea aria-label="Custom" class="custom" {{g.control}}></textarea>
          <g.Addon @align="block-end">Submit</g.Addon>
        </InputGroup>
      </template>,
    )
    for (const name of ['input', 'addon', 'text', 'button']) {
      const [component] = document.querySelectorAll(`[data-case="${name}-component"]`)
      const [modifier] = document.querySelectorAll(`[data-case="${name}-modifier"]`)
      assert.deepEqual(rendering(component!), rendering(modifier!), name)
    }
    // Not `addon` or `button`: a local by an element's name turns the template's into a call.
    const [addonElement] = document.querySelectorAll('[data-case="addon-component"]')
    assert.deepEqual(
      [...addonElement!.classList].sort(),
      inputGroupAddonClasses({ align: 'inline-end' }).split(' ').sort(),
    )
    for (const [name, value] of Object.entries(
      inputGroupAddonAttributes({ align: 'inline-end' }),
    )) {
      assert.strictEqual(addonElement!.getAttribute(name), value, name)
    }
    const [buttonElement] = document.querySelectorAll('[data-case="button-component"]')
    assert.deepEqual(
      [...buttonElement!.classList].sort(),
      inputGroupButtonClasses({ size: 'icon-xs' }).split(' ').sort(),
    )
    const attributes = inputGroupButtonAttributes({ size: 'icon-xs', name: 'b' })
    for (const [name, value] of Object.entries(attributes)) {
      assert.strictEqual(buttonElement!.getAttribute(name), value ?? null, name)
    }
    const custom = new InputGroupHarness('custom')
    assert.dom(custom.control).hasClass('custom').hasAttribute('data-slot', 'input-group-control')
    await custom.focus()
    assert.strictEqual(shadowReach(custom.element), 3, 'a custom control rings it too')
    await rerender()
    await a11yAudit()
  })

  test('RTL: inline-start is on the right, and the padding follows', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <InputGroup as |g|>
            <g.Input placeholder="بحث..." />
            <g.Addon><Icon @icon={{Search}} /></g.Addon>
            <g.Addon @align="inline-end"><Kbd>⌘K</Kbd></g.Addon>
          </InputGroup>
        </DirectionProvider>
      </template>,
    )
    const group = new InputGroupHarness()
    const start = group.addon('inline-start').getBoundingClientRect()
    const control = group.control.getBoundingClientRect()
    const end = group.addon('inline-end').getBoundingClientRect()
    assert.ok(start.left >= control.right, 'inline-start: on the right')
    assert.ok(end.right <= control.left, 'inline-end: on the left')
    assert.strictEqual(getComputedStyle(group.addon('inline-start')).paddingRight, '8px', 'ps-2')
    assert.strictEqual(px(getComputedStyle(group.control).paddingRight), 6, 'ps-1.5')
    await a11yAudit(BUT_THE_KEYS)
  })
})
