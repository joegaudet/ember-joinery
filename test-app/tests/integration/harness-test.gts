import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { getRootElement, render, settled } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, attributes, child, selectors } from '@ember-joinery/test-support'
import {
  FxDisclosure,
  FxList,
  FxToggle,
  FxToolbar,
} from 'test-app/tests/fixtures/harness/components'
import {
  FxDisclosureHarness,
  FxListHarness,
  FxToggleHarness,
  FxToolbarHarness,
} from 'test-app/tests/fixtures/harness/harnesses'
import { StandardFormatBar } from 'test-app/tests/fixtures/harness/standard-decorators'

/** A page object, with the legacy decorators the test app compiles with. */
class FormatBar extends FxToolbarHarness {
  static override named = 'format'

  @child(FxToggleHarness, 'bold') declare bold: FxToggleHarness
  @child(FxToggleHarness, { index: 1 }) declare second: FxToggleHarness
  @child(FxDisclosureHarness) declare more: FxDisclosureHarness
}

class ItalicHarness extends FxToggleHarness {
  static override named = 'italic'
}

/** Two toolbars, each with a toggle named "bold", and a disclosure in the first. */
const TwoToolbars = <template>
  <FxToolbar @name="other" @label="Other">
    <FxToggle @name="bold">Other bold</FxToggle>
  </FxToolbar>
  <FxToolbar @name="format" @label="Format">
    <FxToggle @name="bold">Bold</FxToggle>
    <FxToggle @name="italic">Italic</FxToggle>
    <FxDisclosure @name="more" @label="More" />
  </FxToolbar>
</template>

const labels = (harnesses: FxToggleHarness[]) => harnesses.map(toggle => toggle.label)

module('Integration | test-support | Harness', function (hooks) {
  setupRenderingTest(hooks)

  test('it finds its component by data-test-jn, live on every read', async function (assert) {
    class State {
      @tracked shown = true
    }
    const state = new State()
    const toggle = new FxToggleHarness()
    assert.false(toggle.exists, 'a harness can be made before anything renders')

    await render(
      <template>
        {{#if state.shown}}
          <FxToggle>Bold</FxToggle>
        {{/if}}
      </template>,
    )

    assert.true(toggle.exists)
    assert.strictEqual(toggle.element.getAttribute(attributes.component), 'fx-toggle')
    const first = toggle.element
    await toggle.click()
    assert.true(toggle.isPressed, 'subclasses read state through ARIA')

    state.shown = false
    await settled()
    assert.false(toggle.exists, 'exists is false once the component is gone')
    assert.throws(() => toggle.element, /Joinery harness: no fx-toggle found/)

    state.shown = true
    await settled()
    assert.notStrictEqual(toggle.element, first, 'the same harness finds the new element')
    assert.false(toggle.isPressed, 'and reads the new instance')
    await a11yAudit()
  })

  test('it scopes by data-test-jn-name, and static named sets the default', async function (assert) {
    await render(
      <template>
        <FxToggle>Underline</FxToggle>
        <FxToggle @name="bold">Bold</FxToggle>
        <FxToggle @name="italic">Italic</FxToggle>
      </template>,
    )

    assert.strictEqual(new FxToggleHarness().label, 'Underline', 'unnamed: the first instance')
    assert.strictEqual(new FxToggleHarness('italic').label, 'Italic', 'by @name')
    assert.strictEqual(new FxToggleHarness({ name: 'bold' }).label, 'Bold', 'by options')
    assert.strictEqual(new FxToggleHarness({ index: 2 }).label, 'Italic', 'by position')
    assert.strictEqual(new ItalicHarness().label, 'Italic', 'static named is the default name')
    assert.strictEqual(new ItalicHarness('bold').label, 'Bold', 'a name given wins over it')

    assert.deepEqual(labels(FxToggleHarness.findAll()), ['Underline', 'Bold', 'Italic'])
    assert.deepEqual(labels(FxToggleHarness.findAll('bold')), ['Bold'])
    assert.deepEqual(labels(ItalicHarness.findAll()), ['Italic'], 'findAll uses static named too')

    assert.throws(
      () => new FxToggleHarness({ index: 5 }).element,
      /no fx-toggle #6 found \(there are only 3\)/,
    )
    assert.throws(() => new FxToggleHarness('strike').element, /no fx-toggle "strike" found/)
    await a11yAudit()
  })

  test('it checks it is pointed at the component it drives', async function (assert) {
    class ControlHarness extends Harness {
      static override component = ['fx-toggle', 'fx-disclosure']
    }

    await render(
      <template>
        <FxDisclosure @name="more" @label="More" />
        <FxToggle @name="bold">Bold</FxToggle>
        <FxList @name="bold" @items={{array "a"}} />
      </template>,
    )

    assert.throws(
      () => new FxToggleHarness('more').element,
      /Joinery harness: the component named "more" is a "fx-disclosure"; this harness drives "fx-toggle"/,
    )
    assert.throws(
      () => new FxToggleHarness('more').exists,
      /is a "fx-disclosure"/,
      'exists is for absence; a mismatch still fails',
    )
    assert.strictEqual(
      new FxListHarness('bold').element.localName,
      'ul',
      'when two components share a name, it finds the one it drives',
    )
    assert.strictEqual(
      new Harness('more').element.getAttribute(attributes.component),
      'fx-disclosure',
      'the base class drives any component',
    )
    assert.strictEqual(ControlHarness.findAll().length, 2, 'a harness can drive several kinds')
    assert.strictEqual(new ControlHarness('bold').element.localName, 'button')
    assert.throws(
      () => new FxDisclosureHarness('bold').element,
      /the component named "bold" is a "fx-toggle"; this harness drives "fx-disclosure"/,
    )
    await a11yAudit()
  })

  test('@child declares children: created once, kept, and scoped to the parent', async function (assert) {
    await render(TwoToolbars)

    const bar = new FormatBar()
    assert.strictEqual(bar.bold, bar.bold, 'a child is the same object on every read')
    assert.strictEqual(bar.child(FxToggleHarness, 'bold'), bar.bold, 'child() shares the cache')
    assert.notStrictEqual(bar.child(FxToggleHarness, 'italic'), bar.bold)
    assert.true(bar.bold instanceof FxToggleHarness)

    await bar.bold.click()
    assert.true(bar.bold.isPressed, 'it drives the toggle inside its parent')
    const other = new FxToggleHarness({ name: 'bold', within: new FxToolbarHarness('other') })
    assert.false(other.isPressed, 'and not the same-named toggle elsewhere')
    assert.strictEqual(bar.second.label, 'Italic', 'by position inside the parent')
    assert.strictEqual(bar.more.trigger.textContent!.trim(), 'More', 'unnamed: the first one')
    assert.strictEqual(
      String(bar.bold),
      'fx-toggle "bold" in fx-toolbar "format"',
      'it describes itself for error messages',
    )
    await a11yAudit()
  })

  test('@child works as a standard accessor decorator', async function (assert) {
    const accessor = Object.getOwnPropertyDescriptor(StandardFormatBar.prototype, 'bold')
    assert.strictEqual(typeof accessor?.set, 'function', 'compiled as a standard auto-accessor')

    await render(TwoToolbars)

    const bar = new StandardFormatBar()
    assert.strictEqual(bar.bold, bar.bold, 'a child is the same object on every read')
    assert.strictEqual(bar.child(FxToggleHarness, 'bold'), bar.bold, 'child() shares the cache')
    await bar.bold.click()
    assert.true(bar.bold.isPressed)
    assert.false(new FxToggleHarness('bold').isPressed, 'the other toolbar comes first')
    assert.strictEqual(bar.second.label, 'Italic')
    assert.strictEqual(bar.more.trigger.textContent!.trim(), 'More')
    await a11yAudit()
  })

  test('find() makes one-off harnesses, and findAll() one per instance', async function (assert) {
    await render(TwoToolbars)
    const bar = new FormatBar()

    const bold = bar.find(FxToggleHarness, 'bold')
    assert.notStrictEqual(bar.find(FxToggleHarness, 'bold'), bold, 'a new harness each call')
    assert.strictEqual(bold.element, bar.bold.element, 'for the same element')
    assert.strictEqual(bar.find(FxToggleHarness, { index: 1 }).label, 'Italic')
    assert.false(bar.find(FxToggleHarness, 'strike').exists, 'a lookup that finds nothing')

    const all = bar.findAll(FxToggleHarness)
    assert.deepEqual(labels(all), ['Bold', 'Italic'], 'only the instances inside the parent')
    await all[1]!.click()
    assert.true(bar.find(FxToggleHarness, 'italic').isPressed, 'each drives its own instance')
    assert.deepEqual(labels(bar.findAll(FxToggleHarness, 'italic')), ['Italic'])
    assert.strictEqual(FxToggleHarness.findAll().length, 3, 'the static findAll searches the test')
    assert.strictEqual(new FormatBar().findAll(FxListHarness).length, 0)
    await a11yAudit()
  })

  test('parts belong to their own instance, and data-test-jn-value picks one', async function (assert) {
    const hasInner = (item: string) => item === 'b'

    await render(
      <template>
        <FxList @name="outer" @items={{array "a" "b" "c"}} as |item|>
          {{#if (hasInner item)}}
            <FxList @name="inner" @items={{array "b1" "b2"}} />
          {{/if}}
        </FxList>
      </template>,
    )

    const outer = new FxListHarness('outer')
    const inner = outer.find(FxListHarness)
    assert.deepEqual(outer.items, ['a', 'b', 'c'], 'a nested instance keeps its own parts')
    assert.deepEqual(inner.items, ['b1', 'b2'], 'children are found at any depth')
    assert.strictEqual(outer.parts('item').length, 3)
    assert.strictEqual(outer.part('item').getAttribute(attributes.value), 'a', 'the first part')
    assert.strictEqual(outer.part('item', 'c').textContent!.trim(), 'c', 'one part by value')
    assert.strictEqual(outer.queryPart('item', 'b1'), null, "not the nested list's part")
    assert.strictEqual(inner.part('item', 'b1').textContent!.trim(), 'b1')
    assert.strictEqual(new FxListHarness().items.length, 3, 'unnamed: the first in the document')
    assert.throws(
      () => outer.part('item', 'z'),
      /Joinery harness: no "item" part "z" found in fx-list "outer"/,
    )
    assert.throws(() => outer.part('header'), /no "header" part found in fx-list "outer"/)
    await a11yAudit()
  })

  test('it follows owned parts into the top layer', async function (assert) {
    class Menu extends FxDisclosureHarness {
      static override named = 'more'
      @child(FxToggleHarness, 'wrap') declare wrap: FxToggleHarness
    }

    await render(
      <template>
        <FxDisclosure @name="more" @label="More" @layer="popover">
          <FxToggle @name="wrap">Wrap text</FxToggle>
        </FxDisclosure>
      </template>,
    )

    const menu = new Menu()
    assert.false(menu.isOpen)
    assert.false(menu.content.matches(':popover-open'), 'closed, the content is rendered hidden')

    await menu.toggle()
    assert.true(menu.isOpen)
    assert.true(menu.content.matches(':popover-open'), 'open, the content is in the top layer')
    assert.strictEqual(
      menu.content.getAttribute(attributes.owner),
      menu.element.id,
      'and names its root',
    )
    await menu.wrap.click()
    assert.true(menu.wrap.isPressed, 'a child inside the owned part')
    await a11yAudit()
  })

  test('it follows owned parts through portals', async function (assert) {
    class Menu extends FxDisclosureHarness {
      static override named = 'more'
      @child(FxToggleHarness, 'wrap') declare wrap: FxToggleHarness
      @child(FxDisclosureHarness, 'nested') declare nested: FxDisclosureHarness
    }

    await render(
      <template>
        <FxDisclosure @name="more" @label="More" @layer="portal">
          <FxToggle @name="wrap">Wrap text</FxToggle>
          <FxDisclosure @name="nested" @label="Nested" @layer="portal">
            <FxToggle @name="deep">Deep</FxToggle>
          </FxDisclosure>
        </FxDisclosure>
        <FxDisclosure @name="other" @label="Other" />
      </template>,
    )

    const menu = new Menu()
    await menu.toggle()
    const content = menu.content
    assert.strictEqual(content.parentElement, document.body, 'the content is portalled to <body>')
    assert.false(
      (getRootElement() as Element).contains(content),
      'outside the root element tests render into',
    )

    await menu.wrap.click()
    assert.true(menu.wrap.isPressed, 'a child inside the portalled part')
    assert.true(new FxToggleHarness('wrap').isPressed, 'a lookup from the test follows owners too')
    assert.false(
      new FxDisclosureHarness('other').find(FxToggleHarness, 'wrap').exists,
      "another component doesn't see it",
    )

    await menu.nested.toggle()
    assert.true(menu.find(FxToggleHarness, 'deep').exists, 'owners are followed at any depth')
    assert.deepEqual(
      menu.parts('content').map(part => part.id),
      [content.id],
      "the nested disclosure's content is its own part, not the outer one's",
    )
    assert.strictEqual(menu.nested.content.querySelector('button')!.textContent!.trim(), 'Deep')
    await a11yAudit()
  })

  test('a missing parent makes its children missing, with a clear message', async function (assert) {
    await render(TwoToolbars)

    const missing = new FormatBar('nope')
    assert.false(missing.exists)
    assert.false(missing.bold.exists, 'a child of a missing parent is missing too')
    assert.throws(() => missing.bold.element, /no fx-toolbar "nope" found/)
    assert.throws(() => missing.findAll(FxToggleHarness), /no fx-toolbar "nope" found/)
    await a11yAudit()
  })

  test('selectors build the data-test-jn selectors', async function (assert) {
    assert.deepEqual(attributes, {
      component: 'data-test-jn',
      name: 'data-test-jn-name',
      part: 'data-test-jn-part',
      owner: 'data-test-jn-owner',
      value: 'data-test-jn-value',
    })
    assert.strictEqual(selectors.component(), '[data-test-jn]')
    assert.strictEqual(selectors.component('dialog'), '[data-test-jn="dialog"]')
    assert.strictEqual(
      selectors.component('dialog', 'edit-profile'),
      '[data-test-jn="dialog"][data-test-jn-name="edit-profile"]',
    )
    assert.strictEqual(selectors.name('save'), '[data-test-jn-name="save"]')
    assert.strictEqual(selectors.part('trigger'), '[data-test-jn-part="trigger"]')
    assert.strictEqual(selectors.owner('ember12'), '[data-test-jn-owner="ember12"]')
    assert.strictEqual(selectors.value('a"b\\c'), '[data-test-jn-value="a\\"b\\\\c"]')

    const { part } = selectors
    assert.strictEqual(part(), '[data-test-jn-part]', 'the functions work detached')

    const awkward = 'say "hi" \\ bye'
    await render(<template><FxList @name="awkward" @items={{array awkward}} /></template>)
    assert.dom(selectors.value(awkward)).exists('quotes and backslashes are escaped')
    assert.strictEqual(new FxListHarness('awkward').part('item', awkward).localName, 'li')
    await a11yAudit()
  })
})
