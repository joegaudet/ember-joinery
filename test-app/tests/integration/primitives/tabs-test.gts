import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, focus, render, rerender, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Tabs } from '@ember-joinery/primitives/tabs'
import { TabsHarness, tab } from '@ember-joinery/test-support'

class Values {
  @tracked value = 'b'
  @tracked disabled = false
  @tracked showThird = true
}

module('Integration | primitives | tabs', function (hooks) {
  setupRenderingTest(hooks)

  test('it ties each tab to its panel through ARIA, as Radix does', async function (assert) {
    await render(
      <template>
        <Tabs @name="fruit" @defaultValue="apple" as |t|>
          <t.List aria-label="Fruit">
            <t.Trigger @value="apple">Apple</t.Trigger>
            <t.Trigger @value="banana">Banana</t.Trigger>
          </t.List>
          <t.Content @value="apple">Red</t.Content>
          <t.Content @value="banana">Yellow</t.Content>
        </Tabs>
      </template>,
    )
    const fruit = new TabsHarness('fruit')
    assert.dom(fruit.element).hasAttribute('data-orientation', 'horizontal')
    assert
      .dom(fruit.list)
      .hasAttribute('role', 'tablist')
      .hasAttribute('aria-orientation', 'horizontal')
      .hasAttribute('data-orientation', 'horizontal')
      .hasAttribute('tabindex', '0', 'the list takes the tab stop until a tab has had focus')
    assert.strictEqual(fruit.listLabel, 'Fruit')
    assert.strictEqual(fruit.orientation, 'horizontal')
    assert.deepEqual(fruit.tabValues, ['apple', 'banana'])
    assert.strictEqual(fruit.variant, null, 'the primitive has no variant')

    const apple = fruit.trigger('apple')
    const red = fruit.content('apple')
    assert
      .dom(apple)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('role', 'tab')
      .hasAttribute('aria-selected', 'true')
      .hasAttribute('aria-controls', red.id)
      .hasAttribute('data-state', 'active')
      .hasAttribute('data-orientation', 'horizontal')
      .hasAttribute('tabindex', '-1')
      .doesNotHaveAttribute('data-disabled')
    assert
      .dom(red)
      .hasAttribute('role', 'tabpanel')
      .hasAttribute('aria-labelledby', apple.id)
      .hasAttribute('tabindex', '0', 'a panel with nothing to focus can still be reached')
      .hasAttribute('data-state', 'active')
      .hasAttribute('data-orientation', 'horizontal')
      .doesNotHaveAttribute('hidden')
      .hasText('Red')
    assert
      .dom(fruit.trigger('banana'))
      .hasAttribute('aria-selected', 'false')
      .hasAttribute('data-state', 'inactive')
    assert
      .dom(fruit.content('banana'))
      .hasAttribute('hidden', '', 'the panel stays, so aria-controls names an element')
      .hasAttribute('data-state', 'inactive')
      .hasText('', 'its block renders only while it is selected')
    assert.strictEqual(fruit.selected, 'apple')
    assert.strictEqual(fruit.panelText, 'Red')
    assert.strictEqual(fruit.label('banana'), 'Banana')
    await a11yAudit()
  })

  test('uncontrolled: a click selects a tab and shows its panel', async function (assert) {
    const changes: string[] = []
    const record = (value: string, previous: string) => changes.push(`${previous} → ${value}`)
    await render(
      <template>
        <Tabs @defaultValue="account" @onValueChange={{record}} as |t|>
          <t.List aria-label="Settings">
            <t.Trigger @value="account">Account</t.Trigger>
            <t.Trigger @value="password">Password</t.Trigger>
          </t.List>
          <t.Content @value="account">Make changes to your account here.</t.Content>
          <t.Content @value="password">Change your password here.</t.Content>
        </Tabs>
      </template>,
    )
    const settings = new TabsHarness()
    assert.strictEqual(settings.panelText, 'Make changes to your account here.')
    await settings.select('password')
    assert.strictEqual(settings.selected, 'password')
    assert.true(settings.isShown('password'))
    assert.false(settings.isShown('account'))
    assert.strictEqual(settings.panelText, 'Change your password here.')
    await settings.select('password')
    assert.deepEqual(changes, ['account → password'], 'with the value before, and once')
    await a11yAudit()
  })

  test('controlled: @value decides, and @onValueChange hears what was asked', async function (assert) {
    const state = new Values()
    const asked: string[] = []
    const ask = (value: string) => asked.push(value)
    const accept = (value: string) => (state.value = value)
    await render(
      <template>
        <Tabs @name="ignored" @value={{state.value}} @onValueChange={{ask}} as |t|>
          <t.List aria-label="Ignored">
            <t.Trigger @value="a">A</t.Trigger>
            <t.Trigger @value="b">B</t.Trigger>
          </t.List>
          <t.Content @value="a">Panel A</t.Content>
          <t.Content @value="b">Panel B</t.Content>
        </Tabs>
        <Tabs @name="followed" @value={{state.value}} @onValueChange={{accept}} as |t|>
          <t.List aria-label="Followed">
            <t.Trigger @value="a">A</t.Trigger>
            <t.Trigger @value="b">B</t.Trigger>
          </t.List>
        </Tabs>
      </template>,
    )
    const ignored = new TabsHarness('ignored')
    const followed = new TabsHarness('followed')
    assert.strictEqual(ignored.selected, 'b')
    await ignored.select('a')
    assert.deepEqual(asked, ['a'])
    assert.strictEqual(ignored.selected, 'b', 'it stays where @value puts it')

    await followed.select('a')
    assert.strictEqual(followed.selected, 'a')
    assert.strictEqual(ignored.selected, 'a', 'both follow @value')
    assert.strictEqual(ignored.panelText, 'Panel A')

    state.value = 'b'
    await rerender()
    assert.strictEqual(followed.selected, 'b')
    await a11yAudit()
  })

  test('with no value, the first tab that is not disabled is selected, as in ember-primitives', async function (assert) {
    const state = new Values()
    await render(
      <template>
        <Tabs @name="first" as |t|>
          <t.List aria-label="First">
            <t.Trigger @value="off" @disabled={{true}}>Off</t.Trigger>
            <t.Trigger @value="banana">Banana</t.Trigger>
            <t.Trigger @value="apple">Apple</t.Trigger>
          </t.List>
          <t.Content @value="banana">Yellow</t.Content>
          <t.Content @value="apple">Red</t.Content>
        </Tabs>
        <Tabs @name="none" @defaultValue="" as |t|>
          <t.List aria-label="None">
            <t.Trigger @value="a">A</t.Trigger>
          </t.List>
        </Tabs>
        <Tabs @name="missing" @value="nope" as |t|>
          <t.List aria-label="Missing">
            <t.Trigger @value="a">A</t.Trigger>
          </t.List>
        </Tabs>
        <Tabs @name="later" as |t|>
          <t.List aria-label="Later">
            {{#if state.showThird}}
              <t.Trigger @value="third" @disabled={{state.disabled}}>Third</t.Trigger>
            {{/if}}
            <t.Trigger @value="fourth">Fourth</t.Trigger>
          </t.List>
        </Tabs>
      </template>,
    )
    const first = new TabsHarness('first')
    assert.strictEqual(first.selected, 'banana')
    assert.strictEqual(first.panelText, 'Yellow')
    await first.select('apple')
    assert.strictEqual(first.selected, 'apple', 'until one is chosen')

    assert.strictEqual(new TabsHarness('none').selected, null, "an explicit '' selects none")
    assert.strictEqual(new TabsHarness('missing').selected, null, 'nor does a value no tab has')

    const later = new TabsHarness('later')
    assert.strictEqual(later.selected, 'third')
    state.disabled = true
    await settled()
    assert.strictEqual(later.selected, 'fourth', 'the first tab follows the tabs as they change')
    state.disabled = false
    state.showThird = false
    await settled()
    assert.strictEqual(later.selected, 'fourth')
    state.showThird = true
    await settled()
    assert.strictEqual(later.selected, 'third')
    await a11yAudit()
  })

  test('automatic activation: Tab enters on the selected tab, and the arrows select as they move', async function (assert) {
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <Tabs @defaultValue="b" as |t|>
          <t.List aria-label="Letters">
            <t.Trigger @value="a">A</t.Trigger>
            <t.Trigger @value="b">B</t.Trigger>
            <t.Trigger @value="c">C</t.Trigger>
          </t.List>
          <t.Content @value="a">Panel A</t.Content>
          <t.Content @value="b">Panel B</t.Content>
          <t.Content @value="c">Panel C</t.Content>
        </Tabs>
        <button id="after" type="button">After</button>
      </template>,
    )
    const tabs = new TabsHarness()
    await focus('#before')
    await tab()
    assert.strictEqual(tabs.focused, 'b', 'Tab enters on the selected tab')
    assert.strictEqual(tabs.tabStop, 'b')

    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.focused, 'c')
    assert.strictEqual(tabs.selected, 'c', 'focus selects it')
    assert.strictEqual(tabs.panelText, 'Panel C')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.focused, 'a', 'and wraps round')
    await tabs.press('ArrowLeft')
    assert.strictEqual(tabs.focused, 'c', 'backwards too')
    await tabs.press('Home')
    assert.strictEqual(tabs.selected, 'a')
    await tabs.press('End')
    assert.strictEqual(tabs.selected, 'c')
    await tabs.press('ArrowDown')
    assert.strictEqual(tabs.focused, 'c', 'a horizontal list ignores up and down')

    await tab()
    assert.dom(tabs.content('c')).isFocused('Tab moves on into the panel')
    await tab()
    assert.dom('#after').isFocused()
    await tab({ shift: true })
    await tab({ shift: true })
    assert.strictEqual(tabs.focused, 'c', 'Shift+Tab comes back to the selected tab')
    await a11yAudit()
  })

  test('manual activation: the arrows only move focus; Enter, Space and a click select', async function (assert) {
    await render(
      <template>
        <Tabs @defaultValue="a" @activationMode="manual" as |t|>
          <t.List aria-label="Letters">
            <t.Trigger @value="a">A</t.Trigger>
            <t.Trigger @value="b">B</t.Trigger>
            <t.Trigger @value="c">C</t.Trigger>
          </t.List>
          <t.Content @value="a">Panel A</t.Content>
          <t.Content @value="b">Panel B</t.Content>
          <t.Content @value="c">Panel C</t.Content>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    await tabs.focus('a')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.focused, 'b')
    assert.strictEqual(tabs.selected, 'a', 'focus alone selects nothing')
    assert.strictEqual(tabs.panelText, 'Panel A')
    await tabs.press('Enter')
    assert.strictEqual(tabs.selected, 'b')
    await tabs.press('ArrowRight')
    await tabs.press(' ')
    assert.strictEqual(tabs.selected, 'c', 'Space selects too')
    await tabs.select('a')
    assert.strictEqual(tabs.selected, 'a')
    await a11yAudit()
  })

  test('vertical: up and down move, left and right do nothing', async function (assert) {
    await render(
      <template>
        <Tabs @defaultValue="account" @orientation="vertical" as |t|>
          <t.List aria-label="Settings">
            <t.Trigger @value="account">Account</t.Trigger>
            <t.Trigger @value="password">Password</t.Trigger>
          </t.List>
          <t.Content @value="account">Account settings</t.Content>
          <t.Content @value="password">Password settings</t.Content>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    assert.strictEqual(tabs.orientation, 'vertical')
    assert.dom(tabs.element).hasAttribute('data-orientation', 'vertical')
    assert.dom(tabs.trigger('account')).hasAttribute('data-orientation', 'vertical')
    assert.dom(tabs.content('account')).hasAttribute('data-orientation', 'vertical')
    await tabs.focus('account')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.focused, 'account')
    await tabs.press('ArrowDown')
    assert.strictEqual(tabs.focused, 'password')
    assert.strictEqual(tabs.selected, 'password')
    await tabs.press('ArrowUp')
    assert.strictEqual(tabs.selected, 'account')
    await a11yAudit()
  })

  test('@loop={{false}} on the list stops the arrows at the ends', async function (assert) {
    await render(
      <template>
        <Tabs @defaultValue="a" as |t|>
          <t.List @loop={{false}} aria-label="Letters">
            <t.Trigger @value="a">A</t.Trigger>
            <t.Trigger @value="b">B</t.Trigger>
          </t.List>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    await tabs.focus('a')
    await tabs.press('ArrowLeft')
    assert.strictEqual(tabs.focused, 'a', 'no wrapping back')
    await tabs.press('ArrowRight')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.focused, 'b', 'no wrapping forward')
    await a11yAudit()
  })

  test('right to left, the left arrow moves forward', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Tabs @name="provider" @defaultValue="a" as |t|>
            <t.List aria-label="Provider">
              <t.Trigger @value="a">أ</t.Trigger>
              <t.Trigger @value="b">ب</t.Trigger>
            </t.List>
          </Tabs>
        </DirectionProvider>
        <Tabs @name="own" @dir="rtl" @defaultValue="a" as |t|>
          <t.List aria-label="Own">
            <t.Trigger @value="a">أ</t.Trigger>
            <t.Trigger @value="b">ب</t.Trigger>
          </t.List>
        </Tabs>
      </template>,
    )
    const provider = new TabsHarness('provider')
    await provider.focus('a')
    await provider.press('ArrowLeft')
    assert.strictEqual(provider.selected, 'b', 'from the nearest dir')

    const own = new TabsHarness('own')
    assert.dom(own.element).hasAttribute('dir', 'rtl')
    await own.focus('a')
    await own.press('ArrowLeft')
    assert.strictEqual(own.selected, 'b', 'from @dir')
    await own.press('ArrowRight')
    assert.strictEqual(own.selected, 'a')
    await a11yAudit()
  })

  test('a disabled tab can not be selected, and the arrows pass it by', async function (assert) {
    await render(
      <template>
        <Tabs @defaultValue="home" as |t|>
          <t.List aria-label="Pages">
            <t.Trigger @value="home">Home</t.Trigger>
            <t.Trigger @value="settings" @disabled={{true}}>Disabled</t.Trigger>
            <t.Trigger @value="about">About</t.Trigger>
          </t.List>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    assert.true(tabs.isDisabled('settings'))
    assert.false(tabs.isDisabled('home'))
    assert
      .dom(tabs.trigger('settings'))
      .hasAttribute('disabled')
      .hasAttribute('data-disabled', '')
      .doesNotHaveAttribute('aria-disabled', 'a button has disabled')
    await tabs.select('settings')
    assert.strictEqual(tabs.selected, 'home')
    await tabs.focus('home')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.focused, 'about')
    await a11yAudit()
  })

  test('@forceMount keeps a panel rendered and shown; only data-state says it is inactive', async function (assert) {
    await render(
      <template>
        <Tabs @defaultValue="a" as |t|>
          <t.List aria-label="Letters">
            <t.Trigger @value="a">A</t.Trigger>
            <t.Trigger @value="b">B</t.Trigger>
          </t.List>
          <t.Content @value="a">Panel A</t.Content>
          <t.Content @value="b" @forceMount={{true}}>Panel B</t.Content>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    assert
      .dom(tabs.content('b'))
      .hasText('Panel B')
      .doesNotHaveAttribute('hidden')
      .hasAttribute('data-state', 'inactive')
    assert.true(tabs.isShown('b'))
    await a11yAudit()
  })

  test('the modifiers make parts of your own elements', async function (assert) {
    await render(
      <template>
        <Tabs @defaultValue="one" as |t|>
          <ul aria-label="Steps" {{t.list}}>
            <li role="presentation">
              <button type="button" {{t.trigger value="one"}}>One</button>
            </li>
            <li role="presentation">
              <button {{t.trigger value="two"}}>Two</button>
            </li>
            <li role="presentation">
              <button type="submit" {{t.trigger value="three"}}>Three</button>
            </li>
          </ul>
          <section tabindex="-1" {{t.content value="one"}}>Step one</section>
          <section {{t.content value="two"}}>Step two</section>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    assert.dom(tabs.list).hasTagName('ul').hasAttribute('role', 'tablist')
    assert.deepEqual(tabs.tabValues, ['one', 'two', 'three'])
    assert.dom(tabs.trigger('two')).hasAttribute('type', 'button', 'a button of your own')
    assert.dom(tabs.trigger('three')).hasAttribute('type', 'submit', 'unless it has its own type')
    assert.dom(tabs.content('one')).hasTagName('section').hasAttribute('tabindex', '-1')
    assert.dom(tabs.content('two')).hasAttribute('tabindex', '0').hasAttribute('hidden')
    await tabs.select('two')
    assert.strictEqual(tabs.panelText, 'Step two')
    assert.dom(tabs.content('one')).hasAttribute('hidden')
    await a11yAudit()
  })

  test('link tabs: focus never selects a link, a click does, and a disabled link stays put', async function (assert) {
    // The links point at this page, and nothing should follow them: stop each navigation
    // once the tabs have seen the click.
    const stay = (event: Event) => event.preventDefault()
    document.addEventListener('click', stay)
    try {
      await render(
        <template>
          <Tabs @name="pages" @defaultValue="a" as |t|>
            <t.List aria-label="Pages">
              <t.Trigger @as="a" @value="a" href="#a">A</t.Trigger>
              <t.Trigger @as="a" @value="b" href="#b">B</t.Trigger>
              <t.Trigger @as="a" @value="c" @disabled={{true}} href="#c">C</t.Trigger>
            </t.List>
            <t.Content @value={{t.value}}>Page {{t.value}}</t.Content>
          </Tabs>
        </template>,
      )
      const pages = new TabsHarness('pages')
      assert.true(pages.isLink('a'))
      assert
        .dom(pages.trigger('a'))
        .hasTagName('a')
        .hasAttribute('role', 'tab')
        .doesNotHaveAttribute('type')
      assert
        .dom(pages.trigger('c'))
        .hasAttribute('aria-disabled', 'true', 'a link has no disabled')
        .doesNotHaveAttribute('disabled')
      assert.true(pages.isDisabled('c'))
      assert.strictEqual(pages.panelText, 'Page a', 'one panel for the routed content')

      await pages.focus('a')
      await pages.press('ArrowRight')
      assert.strictEqual(pages.focused, 'b')
      assert.strictEqual(pages.selected, 'a', 'focus alone does not navigate, so selects nothing')

      await pages.select('b')
      assert.strictEqual(pages.selected, 'b', 'the click that follows the link selects it')
      assert.strictEqual(pages.panelText, 'Page b')

      let followed = false
      const follow = (event: Event) => (followed = !event.defaultPrevented)
      pages.trigger('c').addEventListener('click', follow)
      await click(pages.trigger('c'))
      assert.false(followed, 'a disabled link is not followed')
      assert.strictEqual(pages.selected, 'b')
      await a11yAudit()
    } finally {
      document.removeEventListener('click', stay)
    }
  })

  test('tabs nest: each set keeps its own tabs and panels', async function (assert) {
    await render(
      <template>
        <Tabs @name="outer" @defaultValue="fruit" as |outer|>
          <outer.List aria-label="Food">
            <outer.Trigger @value="fruit">Fruit</outer.Trigger>
            <outer.Trigger @value="veg">Vegetables</outer.Trigger>
          </outer.List>
          <outer.Content @value="fruit">
            <Tabs @name="inner" @defaultValue="apple" as |inner|>
              <inner.List aria-label="Fruit">
                <inner.Trigger @value="apple">Apple</inner.Trigger>
                <inner.Trigger @value="pear">Pear</inner.Trigger>
              </inner.List>
              <inner.Content @value="apple">Crisp</inner.Content>
              <inner.Content @value="pear">Soft</inner.Content>
            </Tabs>
          </outer.Content>
          <outer.Content @value="veg">Carrots</outer.Content>
        </Tabs>
      </template>,
    )
    const outer = new TabsHarness('outer')
    const inner = outer.find(TabsHarness, 'inner')
    assert.deepEqual(outer.tabValues, ['fruit', 'veg'], "the inner tabs aren't the outer's")
    assert.deepEqual(inner.tabValues, ['apple', 'pear'])
    await inner.select('pear')
    assert.strictEqual(inner.panelText, 'Soft')
    assert.strictEqual(outer.selected, 'fruit')
    await inner.press('ArrowRight')
    assert.strictEqual(outer.selected, 'fruit', 'the inner arrows stay inside')
    await outer.select('veg')
    assert.false(inner.exists, 'the inner tabs went with their panel')
    assert.strictEqual(outer.panelText, 'Carrots')
    await a11yAudit()
  })

  test('the yield: the value, isSelected and select', async function (assert) {
    await render(
      <template>
        <Tabs @defaultValue="a" as |t|>
          <t.List aria-label="Letters">
            <t.Trigger @value="a">A</t.Trigger>
            <t.Trigger @value="b">B</t.Trigger>
          </t.List>
          <output data-value>{{t.value}} {{if (t.isSelected "b") "is b"}}</output>
          <button id="pick" type="button" {{on "click" (fn t.select "b")}}>Pick B</button>
        </Tabs>
      </template>,
    )
    assert.dom('[data-value]').hasText('a')
    await click('#pick')
    assert.dom('[data-value]').hasText('b is b')
    assert.strictEqual(new TabsHarness().selected, 'b')
    await a11yAudit()
  })
})
