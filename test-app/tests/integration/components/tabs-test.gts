import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { type Rendering, rendering as renderingOf } from 'test-app/tests/helpers/rendering'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AppWindow, Code } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Icon, Tabs, tabsListAttributes, tabsListClasses } from '@ember-joinery/ember'
import { TabsHarness, tab } from '@ember-joinery/test-support'

const px = (value: string) => Number.parseFloat(value)

/** A colour, resolved by the browser, to compare two. */
function colour(value: string): string {
  const probe = document.createElement('span')
  probe.style.backgroundColor = value
  document.body.append(probe)
  const resolved = getComputedStyle(probe).backgroundColor
  probe.remove()
  return resolved
}

/** Whether a computed `box-shadow` draws nothing: `none`, or only transparent shadows. */
function noShadow(shadow: string): boolean {
  if (shadow === 'none') return true
  return shadow.split(/,(?![^(]*\))/).every(one => /rgba\(\d+, \d+, \d+, 0\)/.test(one))
}

/**
 * What a part renders, to compare two: the shared rendering()'s (which leaves out what Ember adds
 * before 7.1), less what names the part itself, its id, its panel and its value.
 */
function rendering(element: Element): Rendering {
  const { classes, attributes } = renderingOf(element)
  for (const name of ['id', 'aria-controls', 'data-test-jn-value']) delete attributes[name]
  return { classes, attributes }
}

module('Integration | components | tabs', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Tabs @name="settings" @defaultValue="account" as |t|>
          <t.List aria-label="Settings">
            <t.Trigger @value="account">Account</t.Trigger>
            <t.Trigger @value="password">Password</t.Trigger>
          </t.List>
          <t.Content @value="account">Make changes to your account here.</t.Content>
          <t.Content @value="password">Change your password here.</t.Content>
        </Tabs>
      </template>,
    )
    const settings = new TabsHarness('settings')
    assert
      .dom(settings.element)
      .hasClass('jn-tabs')
      .hasClass('group/tabs')
      .hasAttribute('data-slot', 'tabs')
      .hasAttribute('data-orientation', 'horizontal')
    assert
      .dom(settings.list)
      .hasClass('jn-tabs-list')
      .hasClass('group/tabs-list')
      .hasClass('jn-tabs-list-variant-default')
      .hasAttribute('data-slot', 'tabs-list')
      .hasAttribute('data-variant', 'default')
      .hasAttribute('role', 'tablist')
    assert.strictEqual(settings.variant, 'default')
    for (const trigger of settings.triggers) {
      assert
        .dom(trigger)
        .hasClass('jn-tabs-trigger')
        .hasAttribute('data-slot', 'tabs-trigger')
        .hasAttribute('role', 'tab')
        .hasAttribute('type', 'button')
    }
    assert
      .dom(settings.content('account'))
      .hasClass('jn-tabs-content')
      .hasAttribute('data-slot', 'tabs-content')
      .hasAttribute('role', 'tabpanel')
    assert.strictEqual(settings.selected, 'account')
    assert.strictEqual(settings.panelText, 'Make changes to your account here.')
    await settings.select('password')
    assert.strictEqual(settings.panelText, 'Change your password here.')
    await a11yAudit()
  })

  test('its style sheet lays it out and raises the selected tab, without Tailwind', async function (assert) {
    await render(
      <template>
        {{! The colours ease in (transition-all); read where they end. }}
        <style>
          [data-slot="tabs-trigger"] {
            transition: none !important;
          }
        </style>
        <Tabs @defaultValue="overview" as |t|>
          <t.List aria-label="Dashboard">
            <t.Trigger @value="overview">Overview</t.Trigger>
            <t.Trigger @value="analytics">Analytics</t.Trigger>
          </t.List>
          <t.Content @value="overview">Overview</t.Content>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    const root = getComputedStyle(tabs.element)
    assert.strictEqual(root.display, 'flex')
    assert.strictEqual(root.flexDirection, 'column', 'data-horizontal:flex-col')
    assert.strictEqual(root.rowGap, '8px', 'gap-2')

    const list = getComputedStyle(tabs.list)
    // inline-flex, which a flex item computes as flex; w-fit keeps it to its tabs.
    assert.strictEqual(list.display, 'flex')
    assert.ok(
      tabs.list.getBoundingClientRect().width < tabs.element.getBoundingClientRect().width,
      'w-fit',
    )
    assert.strictEqual(list.height, '32px', 'group-data-horizontal/tabs:h-8')
    assert.strictEqual(list.paddingTop, '3px', 'p-[3px]')
    assert.strictEqual(list.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(list.backgroundColor, colour('var(--muted)'), 'bg-muted')
    assert.strictEqual(list.color, colour('var(--muted-foreground)'))

    const active = getComputedStyle(tabs.trigger('overview'))
    const inactive = getComputedStyle(tabs.trigger('analytics'))
    assert.strictEqual(active.height, '25px', 'h-[calc(100%-1px)] of the list inside its padding')
    assert.strictEqual(active.fontSize, '14px', 'text-sm')
    assert.strictEqual(active.fontWeight, '500', 'font-medium')
    assert.strictEqual(active.paddingLeft, '6px', 'px-1.5')
    assert.strictEqual(active.borderTopLeftRadius, '8px', 'rounded-md')
    assert.strictEqual(
      active.backgroundColor,
      colour('var(--background)'),
      'data-active:bg-background',
    )
    assert.notStrictEqual(active.boxShadow, 'none', 'data-active:shadow-sm')
    assert.strictEqual(active.color, colour('var(--foreground)'))
    assert.strictEqual(inactive.backgroundColor, colour('transparent'))
    assert.true(noShadow(inactive.boxShadow))
    assert.strictEqual(getComputedStyle(tabs.content('overview')).fontSize, '14px', 'text-sm')
    await a11yAudit()
  })

  test('@variant="line" on the list: no bar, and a line under the selected tab', async function (assert) {
    await render(
      <template>
        <style>
          [data-slot="tabs-trigger"],
          [data-slot="tabs-trigger"]::after {
            transition: none !important;
          }
        </style>
        <Tabs @defaultValue="overview" as |t|>
          <t.List @variant="line" aria-label="Dashboard">
            <t.Trigger @value="overview">Overview</t.Trigger>
            <t.Trigger @value="analytics">Analytics</t.Trigger>
          </t.List>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    assert.strictEqual(tabs.variant, 'line')
    assert.dom(tabs.list).hasClass('jn-tabs-list-variant-line')
    const list = getComputedStyle(tabs.list)
    assert.strictEqual(list.backgroundColor, colour('transparent'), 'bg-transparent')
    assert.strictEqual(list.borderTopLeftRadius, '0px', 'data-[variant=line]:rounded-none')
    assert.strictEqual(list.columnGap, '4px', 'gap-1')

    const active = tabs.trigger('overview')
    assert.strictEqual(getComputedStyle(active).backgroundColor, colour('transparent'))
    assert.true(noShadow(getComputedStyle(active).boxShadow), 'no shadow on a line')
    const line = getComputedStyle(active, '::after')
    assert.strictEqual(line.opacity, '1', 'the line shows under the selected tab')
    assert.strictEqual(line.height, '2px', 'h-0.5')
    assert.strictEqual(line.bottom, '-5px')
    assert.strictEqual(line.backgroundColor, colour('var(--foreground)'))
    assert.strictEqual(getComputedStyle(tabs.trigger('analytics'), '::after').opacity, '0')
    await a11yAudit()
  })

  test('vertical: the list stacks beside the panels, and up and down move between tabs', async function (assert) {
    await render(
      <template>
        <style>
          [data-slot="tabs-trigger"]::after {
            transition: none !important;
          }
        </style>
        <Tabs @name="ltr" @defaultValue="account" @orientation="vertical" as |t|>
          <t.List @variant="line" aria-label="Settings">
            <t.Trigger @value="account">Account</t.Trigger>
            <t.Trigger @value="notifications">Notifications</t.Trigger>
          </t.List>
          <t.Content @value="account">Account</t.Content>
        </Tabs>
        <DirectionProvider @dir="rtl">
          <Tabs @name="rtl" @defaultValue="account" @orientation="vertical" as |t|>
            <t.List @variant="line" aria-label="الإعدادات">
              <t.Trigger @value="account">الحساب</t.Trigger>
              <t.Trigger @value="notifications">الإشعارات</t.Trigger>
            </t.List>
          </Tabs>
        </DirectionProvider>
      </template>,
    )
    const ltr = new TabsHarness('ltr')
    assert.strictEqual(ltr.orientation, 'vertical')
    assert.strictEqual(getComputedStyle(ltr.element).flexDirection, 'row', 'no flex-col')
    const list = getComputedStyle(ltr.list)
    assert.strictEqual(list.flexDirection, 'column', 'group-data-vertical/tabs:flex-col')
    const [account, notifications] = ltr.triggers
    assert.strictEqual(
      account!.getBoundingClientRect().width,
      notifications!.getBoundingClientRect().width,
      'w-full: every tab as wide as the list',
    )
    assert.strictEqual(getComputedStyle(account!).justifyContent, 'flex-start')
    const line = getComputedStyle(account!, '::after')
    assert.strictEqual(line.width, '2px', 'w-0.5: the line runs down the side')
    assert.strictEqual(line.right, '-4px', '-end-1: on the inline end')

    const rtl = new TabsHarness('rtl')
    assert.strictEqual(
      getComputedStyle(rtl.trigger('account'), '::after').left,
      '-4px',
      'right to left, the inline end is on the left',
    )

    await ltr.focus('account')
    await ltr.press('ArrowDown')
    assert.strictEqual(ltr.selected, 'notifications')
    await a11yAudit()
  })

  test('disabled and icons: a disabled tab is dimmed, and an icon sizes itself', async function (assert) {
    await render(
      <template>
        <Tabs @defaultValue="preview" as |t|>
          <t.List aria-label="View">
            <t.Trigger @value="preview"><Icon @icon={{AppWindow}} /> Preview</t.Trigger>
            <t.Trigger @value="code"><Icon @icon={{Code}} /> Code</t.Trigger>
            <t.Trigger @value="off" @disabled={{true}}>Disabled</t.Trigger>
          </t.List>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    assert.true(tabs.isDisabled('off'))
    assert.strictEqual(getComputedStyle(tabs.trigger('off')).opacity, '0.5', 'disabled:opacity-50')
    assert.strictEqual(getComputedStyle(tabs.trigger('off')).pointerEvents, 'none')
    const icon = tabs.trigger('preview').querySelector('svg')!
    assert.strictEqual(getComputedStyle(icon).width, '16px', 'size-4')
    assert.strictEqual(getComputedStyle(tabs.trigger('preview')).columnGap, '6px', 'gap-1.5')
    assert.strictEqual(tabs.label('code'), 'Code')
    await a11yAudit()
  })

  test('the modifiers render what the components do, on your own elements', async function (assert) {
    await render(
      <template>
        <Tabs @defaultValue="a" as |t|>
          <t.List @variant="line" aria-label="Components" data-case="component">
            <t.Trigger @value="a" data-case="component">A</t.Trigger>
          </t.List>
          <div aria-label="Modifiers" data-case="modifier" {{t.list variant="line"}}>
            <button type="button" data-case="modifier" {{t.trigger value="b"}}>B</button>
          </div>
          <t.Content @value="a" data-case="component">Panel A</t.Content>
          <div data-case="modifier" {{t.content value="b"}}>Panel B</div>
        </Tabs>
      </template>,
    )
    const tabs = new TabsHarness()
    const [componentList, modifierList] = tabs.parts('list')
    assert.deepEqual(
      rendering(modifierList!).classes,
      rendering(componentList!).classes,
      'the same list classes',
    )
    const listAttributes = (element: Element) => {
      const { attributes } = rendering(element)
      delete attributes['aria-label']
      return attributes
    }
    assert.deepEqual(listAttributes(modifierList!), listAttributes(componentList!))
    assert.deepEqual(rendering(tabs.trigger('b')).classes, rendering(tabs.trigger('a')).classes)
    const triggerAttributes = (value: string) => {
      const { attributes } = rendering(tabs.trigger(value))
      delete attributes['aria-selected']
      delete attributes['data-state']
      return attributes
    }
    assert.deepEqual(triggerAttributes('b'), triggerAttributes('a'))
    assert.deepEqual(rendering(tabs.content('b')).classes, rendering(tabs.content('a')).classes)
    assert.deepEqual(
      tabsListClasses({ variant: 'line' }).split(' ').sort(),
      rendering(componentList!).classes,
      'tabsListClasses() is what the list renders',
    )
    assert.deepEqual(tabsListAttributes({ variant: 'line' }), {
      'data-slot': 'tabs-list',
      'data-variant': 'line',
    })
    await a11yAudit()
  })

  test('link tabs look like the others', async function (assert) {
    const stay = (event: Event) => event.preventDefault()
    document.addEventListener('click', stay)
    try {
      await render(
        <template>
          <Tabs @defaultValue="overview" as |t|>
            <t.List aria-label="Pages">
              <t.Trigger @as="a" @value="overview" href="#overview">Overview</t.Trigger>
              <t.Trigger @as="a" @value="reports" href="#reports">Reports</t.Trigger>
            </t.List>
          </Tabs>
        </template>,
      )
      const tabs = new TabsHarness()
      assert.true(tabs.isLink('overview'))
      assert.dom(tabs.trigger('overview')).hasClass('jn-tabs-trigger').doesNotHaveAttribute('type')
      const style = getComputedStyle(tabs.trigger('overview'))
      assert.strictEqual(style.display, 'flex', 'inline-flex, in the flex list')
      assert.strictEqual(style.textDecorationLine, 'none')
      assert.strictEqual(style.height, '25px')
      await tabs.select('reports')
      assert.strictEqual(tabs.selected, 'reports')
      await a11yAudit()
    } finally {
      document.removeEventListener('click', stay)
    }
  })

  test('RTL: the tabs run right to left, and the left arrow moves forward', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Tabs @defaultValue="overview" as |t|>
            <t.List aria-label="لوحة التحكم">
              <t.Trigger @value="overview">نظرة عامة</t.Trigger>
              <t.Trigger @value="analytics">التحليلات</t.Trigger>
            </t.List>
          </Tabs>
        </DirectionProvider>
      </template>,
    )
    const tabs = new TabsHarness()
    const [overview, analytics] = tabs.triggers
    assert.ok(
      px(String(overview!.getBoundingClientRect().left)) >
        px(String(analytics!.getBoundingClientRect().left)),
      'the first tab is on the right',
    )
    await tab()
    assert.strictEqual(tabs.focused, 'overview')
    await tabs.press('ArrowLeft')
    assert.strictEqual(tabs.selected, 'analytics')
    await a11yAudit()
  })
})
