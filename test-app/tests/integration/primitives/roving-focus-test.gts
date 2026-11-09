import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, focus, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { RovingFocusGroup, getFocusIntent } from '@ember-joinery/primitives/roving-focus'
import { RovingFocusGroupHarness, tab } from '@ember-joinery/test-support'

module('Integration | primitives | roving-focus', function (hooks) {
  setupRenderingTest(hooks)

  test('the items share one tab stop: Tab enters on the first, and comes back to the last focused', async function (assert) {
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <RovingFocusGroup
          @name="format"
          @orientation="horizontal"
          role="toolbar"
          aria-label="Format"
          as |group|
        >
          <group.Item @as="button" @tabStopId="bold" type="button">Bold</group.Item>
          <group.Item @as="button" @tabStopId="italic" type="button">Italic</group.Item>
          <group.Item @as="button" @tabStopId="underline" type="button">Underline</group.Item>
        </RovingFocusGroup>
        <button id="after" type="button">After</button>
      </template>,
    )
    const toolbar = new RovingFocusGroupHarness('format')
    assert.deepEqual(toolbar.ids, ['bold', 'italic', 'underline'])
    assert.strictEqual(toolbar.orientation, 'horizontal')
    assert.dom(toolbar.element).hasAttribute('data-slot', 'roving-focus-group')
    assert.strictEqual(toolbar.tabStop, null, 'no item is in the tab order yet')
    assert.true(toolbar.isGroupTabbable, 'the group is, and passes focus on')
    for (const item of toolbar.items)
      assert.dom(item).hasAttribute('data-orientation', 'horizontal')

    await focus('#before')
    await tab()
    assert.strictEqual(toolbar.focused, 'bold', 'Tab enters on the first item')
    assert.strictEqual(toolbar.tabStop, 'bold')

    await toolbar.press('ArrowRight')
    await toolbar.press('ArrowRight')
    assert.strictEqual(toolbar.focused, 'underline')
    assert.strictEqual(toolbar.tabStop, 'underline', 'the tab stop follows focus')

    await tab()
    assert.dom('#after').isFocused('Tab leaves the group')
    await tab({ shift: true })
    assert.strictEqual(toolbar.focused, 'underline', 'and Shift+Tab comes back to the same item')
    await a11yAudit()
  })

  test('Shift+Tab leaves the group in one step', async function (assert) {
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <RovingFocusGroup @name="list" role="toolbar" aria-label="List" as |group|>
          <group.Item @as="button" @tabStopId="a" type="button">A</group.Item>
          <group.Item @as="button" @tabStopId="b" type="button">B</group.Item>
        </RovingFocusGroup>
        <button id="after" type="button">After</button>
      </template>,
    )
    const group = new RovingFocusGroupHarness('list')
    await group.focus('b')
    await tab({ shift: true })
    assert.dom('#before').isFocused('not back to the group, which would send focus on to B')
    assert.true(group.isGroupTabbable, 'the group is back in the tab order once focus has gone')

    await tab()
    assert.strictEqual(group.focused, 'b', 'and Tab returns to the tab stop')
    await a11yAudit()
  })

  test('horizontal: left and right move, Home and End jump, and it stops at the ends', async function (assert) {
    await render(
      <template>
        <RovingFocusGroup
          @name="h"
          @orientation="horizontal"
          role="toolbar"
          aria-label="Horizontal"
          as |group|
        >
          <group.Item @as="button" @tabStopId="a" type="button">A</group.Item>
          <group.Item @as="button" @tabStopId="b" type="button">B</group.Item>
          <group.Item @as="button" @tabStopId="c" type="button">C</group.Item>
        </RovingFocusGroup>
      </template>,
    )
    const group = new RovingFocusGroupHarness('h')
    await group.focus('a')
    await group.press('ArrowRight')
    assert.strictEqual(group.focused, 'b')
    await group.press('ArrowDown')
    assert.strictEqual(group.focused, 'b', 'up and down do nothing across')
    await group.press('ArrowLeft')
    assert.strictEqual(group.focused, 'a')
    await group.press('ArrowLeft')
    assert.strictEqual(group.focused, 'a', 'without @loop, it stops at the first')
    await group.press('End')
    assert.strictEqual(group.focused, 'c')
    await group.press('ArrowRight')
    assert.strictEqual(group.focused, 'c', 'and at the last')
    await group.press('Home')
    assert.strictEqual(group.focused, 'a')
    await group.press('PageDown')
    assert.strictEqual(group.focused, 'c', 'PageDown goes to the last')
    await group.press('PageUp')
    assert.strictEqual(group.focused, 'a', 'PageUp to the first')
    await group.press('ArrowRight', { shiftKey: true })
    assert.strictEqual(group.focused, 'a', 'with a modifier key held, the arrows do nothing')
    await a11yAudit()
  })

  test('vertical, with @loop: up and down move, and wrap round', async function (assert) {
    await render(
      <template>
        <RovingFocusGroup
          @name="v"
          @orientation="vertical"
          @loop={{true}}
          role="toolbar"
          aria-orientation="vertical"
          aria-label="Vertical"
          as |group|
        >
          <group.Item @as="button" @tabStopId="a" type="button">A</group.Item>
          <group.Item @as="button" @tabStopId="b" type="button">B</group.Item>
          <group.Item @as="button" @tabStopId="c" type="button">C</group.Item>
        </RovingFocusGroup>
      </template>,
    )
    const group = new RovingFocusGroupHarness('v')
    await group.focus('a')
    await group.press('ArrowDown')
    assert.strictEqual(group.focused, 'b')
    await group.press('ArrowRight')
    assert.strictEqual(group.focused, 'b', 'left and right do nothing')
    await group.press('ArrowUp')
    await group.press('ArrowUp')
    assert.strictEqual(group.focused, 'c', 'up from the first wraps to the last')
    await group.press('ArrowDown')
    assert.strictEqual(group.focused, 'a', 'down from the last wraps to the first')
    await a11yAudit()
  })

  test('with no orientation, every arrow moves', async function (assert) {
    await render(
      <template>
        <RovingFocusGroup @name="both" role="toolbar" aria-label="Both" as |group|>
          <group.Item @as="button" @tabStopId="a" type="button">A</group.Item>
          <group.Item @as="button" @tabStopId="b" type="button">B</group.Item>
        </RovingFocusGroup>
      </template>,
    )
    const group = new RovingFocusGroupHarness('both')
    assert.strictEqual(group.orientation, undefined)
    await group.focus('a')
    await group.press('ArrowDown')
    assert.strictEqual(group.focused, 'b')
    await group.press('ArrowLeft')
    assert.strictEqual(group.focused, 'a')
    await group.press('ArrowRight')
    assert.strictEqual(group.focused, 'b')
    await group.press('ArrowUp')
    assert.strictEqual(group.focused, 'a')
    await a11yAudit()
  })

  test('right to left, the left arrow moves forward', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <RovingFocusGroup
            @name="rtl"
            @orientation="horizontal"
            role="toolbar"
            aria-label="Right to left"
            as |group|
          >
            <group.Item @as="button" @tabStopId="a" type="button">أ</group.Item>
            <group.Item @as="button" @tabStopId="b" type="button">ب</group.Item>
          </RovingFocusGroup>
        </DirectionProvider>
        <RovingFocusGroup
          @name="explicit"
          @orientation="horizontal"
          @dir="rtl"
          role="toolbar"
          aria-label="Explicit"
          as |group|
        >
          <group.Item @as="button" @tabStopId="a" type="button">A</group.Item>
          <group.Item @as="button" @tabStopId="b" type="button">B</group.Item>
        </RovingFocusGroup>
      </template>,
    )
    const rtl = new RovingFocusGroupHarness('rtl')
    await rtl.focus('a')
    await rtl.press('ArrowLeft')
    assert.strictEqual(rtl.focused, 'b', 'from the document: dir="rtl" around it')
    await rtl.press('ArrowRight')
    assert.strictEqual(rtl.focused, 'a')

    const explicit = new RovingFocusGroupHarness('explicit')
    await explicit.focus('a')
    await explicit.press('ArrowLeft')
    assert.strictEqual(explicit.focused, 'b', 'from @dir')
    await a11yAudit()
  })

  test('items that can’t take focus are passed over, and Tab enters on the active item', async function (assert) {
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <RovingFocusGroup
          @name="tabs"
          @orientation="horizontal"
          role="toolbar"
          aria-label="Tabs"
          as |group|
        >
          <group.Item @as="button" @tabStopId="one" type="button">One</group.Item>
          <group.Item
            @as="button"
            @tabStopId="two"
            @focusable={{false}}
            type="button"
            disabled
          >Two</group.Item>
          <group.Item @as="button" @tabStopId="three" @active={{true}} type="button">
            Three
          </group.Item>
        </RovingFocusGroup>
      </template>,
    )
    const group = new RovingFocusGroupHarness('tabs')
    await focus('#before')
    await tab()
    assert.strictEqual(group.focused, 'three', 'the active item first, as a selected tab')
    await group.press('ArrowLeft')
    assert.strictEqual(group.focused, 'one', 'the disabled item is passed over')
    await a11yAudit()
  })

  test('a group with nothing to focus is out of the tab order', async function (assert) {
    class State {
      @tracked focusable = false
    }
    const state = new State()
    await render(
      <template>
        <RovingFocusGroup @name="empty" role="toolbar" aria-label="Empty" as |group|>
          <group.Item @as="button" @tabStopId="only" @focusable={{state.focusable}} type="button">
            Only
          </group.Item>
        </RovingFocusGroup>
      </template>,
    )
    const group = new RovingFocusGroupHarness('empty')
    assert.false(group.isGroupTabbable)
    state.focusable = true
    await settled()
    assert.true(group.isGroupTabbable, 'until an item can take focus')
    await a11yAudit()
  })

  test('the tab stop can be controlled, or start from a default', async function (assert) {
    class State {
      @tracked current: string | null = 'b'
      changes: (string | null)[] = []
      change = (id: string | null) => this.changes.push(id)
    }
    const state = new State()
    await render(
      <template>
        <RovingFocusGroup
          @name="controlled"
          @currentTabStopId={{state.current}}
          @onCurrentTabStopIdChange={{state.change}}
          role="toolbar"
          aria-label="Controlled"
          as |group|
        >
          <group.Item @as="button" @tabStopId="a" type="button">A</group.Item>
          <group.Item @as="button" @tabStopId="b" type="button">B</group.Item>
        </RovingFocusGroup>
        <RovingFocusGroup
          @name="uncontrolled"
          @defaultCurrentTabStopId="b"
          role="toolbar"
          aria-label="Uncontrolled"
          as |group|
        >
          <group.Item @as="button" @tabStopId="a" type="button">A</group.Item>
          <group.Item @as="button" @tabStopId="b" type="button">B</group.Item>
        </RovingFocusGroup>
      </template>,
    )
    const controlled = new RovingFocusGroupHarness('controlled')
    assert.strictEqual(controlled.tabStop, 'b')
    await controlled.focus('a')
    assert.deepEqual(state.changes, ['a'], 'focus asks for the new tab stop')
    assert.strictEqual(controlled.tabStop, 'b', 'which waits for the caller')
    state.current = 'a'
    await settled()
    assert.strictEqual(controlled.tabStop, 'a')

    const uncontrolled = new RovingFocusGroupHarness('uncontrolled')
    assert.strictEqual(uncontrolled.tabStop, 'b')
    await uncontrolled.focus('a')
    assert.strictEqual(uncontrolled.tabStop, 'a')
    await a11yAudit()
  })

  test('@onEntryFocus can keep focus on the group', async function (assert) {
    const keep = (event: Event) => event.preventDefault()
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <RovingFocusGroup
          @name="kept"
          @onEntryFocus={{keep}}
          role="toolbar"
          aria-label="Kept"
          as |group|
        >
          <group.Item @as="button" @tabStopId="a" type="button">A</group.Item>
        </RovingFocusGroup>
      </template>,
    )
    const group = new RovingFocusGroupHarness('kept')
    await focus('#before')
    await tab()
    assert.dom(group.element).isFocused()
    assert.strictEqual(group.focused, null)
    await a11yAudit()
  })

  test('the yielded modifier makes any element an item, and items yield their tab stop state', async function (assert) {
    await render(
      <template>
        <RovingFocusGroup @name="mixed" role="toolbar" aria-label="Mixed" as |group|>
          <group.Item @as="button" @tabStopId="first" type="button" as |state|>
            First
            <span id="first-state">{{if state.isCurrentTabStop "current"}}
              {{if state.hasTabStop "has"}}</span>
          </group.Item>
          <a id="own" href="#own" {{group.item}}>Own link</a>
          <span id="current">{{group.currentTabStopId}}</span>
        </RovingFocusGroup>
      </template>,
    )
    const group = new RovingFocusGroupHarness('mixed')
    assert.dom('#own').hasAttribute('tabindex', '-1')
    assert.dom('#first-state').hasText('')

    await group.focus('first')
    assert.dom('#first-state').hasText('current has')
    await group.press('ArrowRight')
    assert.dom('#own').isFocused().hasAttribute('tabindex', '0')
    assert.dom('#first-state').hasText('has')
    assert.dom('#current').hasText(/^jn-\d+$/, 'an item without @tabStopId gets an id of its own')
    await a11yAudit()
  })

  test('getFocusIntent reads a key as Radix does', async function (assert) {
    await render(
      <template>
        <p>Keys only.</p>
      </template>,
    )
    const key = (k: string) => ({ key: k })
    assert.strictEqual(getFocusIntent(key('ArrowRight'), 'horizontal', 'ltr'), 'next')
    assert.strictEqual(getFocusIntent(key('ArrowRight'), 'horizontal', 'rtl'), 'prev')
    assert.strictEqual(getFocusIntent(key('ArrowDown'), 'horizontal', 'ltr'), undefined)
    assert.strictEqual(getFocusIntent(key('ArrowDown'), undefined, 'ltr'), 'next')
    assert.strictEqual(getFocusIntent(key('ArrowLeft'), 'vertical', 'ltr'), undefined)
    assert.strictEqual(getFocusIntent(key('Home'), 'vertical', 'ltr'), 'first')
    assert.strictEqual(getFocusIntent(key('PageDown'), 'vertical', 'ltr'), 'last')
    assert.strictEqual(getFocusIntent(key('a'), undefined, 'ltr'), undefined)
    assert.ok(find('p'))
    await a11yAudit()
  })
})
