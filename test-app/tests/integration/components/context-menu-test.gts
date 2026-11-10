import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { render } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ContextMenu } from '@ember-joinery/ember'
import { ContextMenuHarness, pressKey } from '@ember-joinery/test-support'

const px = (value: string) => Number.parseFloat(value)

const rect = (element: Element) => element.getBoundingClientRect()

function token(name: string): string {
  const probe = document.createElement('div')
  probe.style.setProperty('color', `var(${name})`)
  document.body.append(probe)
  const color = getComputedStyle(probe).color
  probe.remove()
  return color
}

function finishAnimations(element: Element) {
  for (const animation of element.getAnimations({ subtree: true })) animation.finish()
}

const Area = <template>
  <style>
    .cm-area {
      position: fixed;
      top: 100px;
      left: 100px;
      display: flex;
      width: 300px;
      height: 150px;
    }
  </style>
</template>

class People {
  @tracked value = 'sam'
  set = (value: string) => (this.value = value)
}

module('Integration | components | context-menu', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream’s classes and slots', async function (assert) {
    await render(
      <template>
        <Area />
        <ContextMenu @name="page" as |c|>
          <c.Trigger class="cm-area">Right click here</c.Trigger>
          <c.Content>
            <c.Group>
              <c.Label>People</c.Label>
              <c.Item>Back <c.Shortcut>⌘[</c.Shortcut></c.Item>
            </c.Group>
            <c.Separator />
            <c.CheckboxItem @checked={{true}}>Show Bookmarks</c.CheckboxItem>
            <c.RadioGroup @value="pedro" as |g|>
              <g.Item @value="pedro">Pedro Duarte</g.Item>
            </c.RadioGroup>
            <c.Sub as |s|>
              <s.Trigger>More Tools</s.Trigger>
              <s.Content><c.Item @variant="destructive">Delete</c.Item></s.Content>
            </c.Sub>
          </c.Content>
        </ContextMenu>
      </template>,
    )
    const menu = new ContextMenuHarness('page')
    assert
      .dom(menu.trigger)
      .hasClass('jn-context-menu-trigger')
      .hasAttribute('data-slot', 'context-menu-trigger')
    assert.strictEqual(getComputedStyle(menu.trigger).userSelect, 'none', 'select-none')

    await menu.open({ x: 150, y: 150 })
    const content = menu.content!
    assert
      .dom(content)
      .hasClass('jn-context-menu-content')
      .hasClass('jn-menu-target')
      .doesNotHaveClass('jn-menu-translucent')
      .hasAttribute('data-slot', 'context-menu-content')
    assert.dom('[data-slot="context-menu-group"]', content).exists()
    assert.dom('[data-slot="context-menu-label"]', content).hasClass('jn-context-menu-label')
    assert
      .dom(menu.item('Back'))
      .hasClass('jn-context-menu-item')
      .hasClass('group/context-menu-item')
      .hasAttribute('data-variant', 'default')
    assert.dom('[data-slot="context-menu-shortcut"]', menu.item('Back')).hasText('⌘[')
    assert.dom('[data-slot="context-menu-separator"]', content).exists()
    assert.dom(menu.item('Show Bookmarks')).hasClass('jn-context-menu-checkbox-item')
    assert
      .dom('.jn-context-menu-item-indicator', menu.item('Show Bookmarks'))
      .doesNotHaveAttribute('data-slot', 'upstream’s context menu gives the span none')
    assert.dom(menu.item('Pedro Duarte')).hasClass('jn-context-menu-radio-item')
    assert.dom('[data-slot="context-menu-radio-group"]', content).exists()
    assert.dom(menu.item('More Tools')).hasClass('jn-context-menu-sub-trigger')
    await a11yAudit()

    const sub = menu.sub('More Tools')
    await sub.open()
    assert
      .dom(sub.content)
      .hasClass('jn-context-menu-sub-content')
      .hasAttribute('data-slot', 'context-menu-sub-content')
    assert.strictEqual(sub.variant('Delete'), 'destructive')
    await a11yAudit()
  })

  test('its modifiers render what its parts do: the trigger, a sub trigger and a radio item', async function (assert) {
    const people = new People()
    await render(
      <template>
        <Area />
        <ContextMenu @name="parts" as |c|>
          <c.Trigger class="cm-area">Right click here</c.Trigger>
        </ContextMenu>
        <ContextMenu @name="modifiers" as |c|>
          <div class="cm-area" data-case="modifier" {{c.trigger}}>Right click here</div>
          <c.Content>
            <c.Sub as |s|>
              <s.Trigger @inset={{true}}>More Tools</s.Trigger>
              <s.Content><c.Item>Save Page...</c.Item></s.Content>
            </c.Sub>
            <c.Sub as |s|>
              <div data-case="modifier" {{s.trigger inset=true}}>Navigate</div>
              <s.Content><c.Item>Back</c.Item></s.Content>
            </c.Sub>
            <c.RadioGroup @value={{people.value}} @onValueChange={{people.set}} as |g|>
              <g.Item @value="pedro" @inset={{true}}>Pedro Duarte</g.Item>
              <div data-case="modifier" {{g.item value="colm" inset=true}}>Colm Tuite</div>
            </c.RadioGroup>
          </c.Content>
        </ContextMenu>
      </template>,
    )
    const parts = new ContextMenuHarness('parts')
    const menu = new ContextMenuHarness('modifiers')
    assert.deepEqual(rendering(menu.trigger), rendering(parts.trigger), 'the trigger')
    assert.strictEqual(getComputedStyle(menu.trigger).userSelect, 'none', 'select-none')

    await menu.open({ x: 150, y: 150 })
    // Each sub trigger has an id, and names its own content, of its own.
    const subTrigger = (label: string) => {
      const { classes, attributes } = rendering(menu.item(label))
      delete attributes['id']
      delete attributes['aria-controls']
      return { classes, attributes }
    }
    assert.deepEqual(subTrigger('Navigate'), subTrigger('More Tools'), 'a sub trigger')
    assert.strictEqual(getComputedStyle(menu.item('Navigate')).display, 'flex', 'styled as one')
    assert.strictEqual(menu.role('Colm Tuite'), 'menuitemradio')
    const radio = rendering(menu.item('Colm Tuite'))
    radio.attributes['data-test-jn-value'] = 'pedro'
    assert.deepEqual(radio, rendering(menu.item('Pedro Duarte')), 'a radio item')
    await a11yAudit()

    await menu.select('Colm Tuite')
    assert.strictEqual(people.value, 'colm', 'it selects as the Item does')
    await a11yAudit()
  })

  test('its style sheet sizes and places it at the pointer, without Tailwind', async function (assert) {
    await render(
      <template>
        <Area />
        <ContextMenu as |c|>
          <c.Trigger class="cm-area">Right click here</c.Trigger>
          <c.Content>
            <c.Item>Back</c.Item>
            <c.Sub as |s|>
              <s.Trigger>More Tools</s.Trigger>
              <s.Content><c.Item>Save Page...</c.Item></s.Content>
            </c.Sub>
          </c.Content>
        </ContextMenu>
      </template>,
    )
    const menu = new ContextMenuHarness()
    await menu.open({ x: 150, y: 120 })
    await menu.sub('More Tools').open()
    const content = menu.content!
    finishAnimations(content)
    const style = getComputedStyle(content)
    assert.strictEqual(style.minWidth, '144px', 'min-w-36')
    assert.strictEqual(style.paddingTop, '4px', 'p-1')
    assert.strictEqual(style.backgroundColor, token('--popover'))
    assert.true(Math.abs(rect(content).left - 152) <= 1, 'to the pointer’s right, 2px off')
    assert.true(Math.abs(rect(content).top - 120) <= 1, 'level with it')
    const item = getComputedStyle(menu.item('Back'))
    assert.strictEqual(px(item.fontSize), 14)
    assert.strictEqual(item.paddingInlineStart, '6px')
    const subContent = menu.sub('More Tools').content!
    finishAnimations(subContent)
    const sub = getComputedStyle(subContent)
    assert.strictEqual(sub.minWidth, '128px', 'min-w-32')
    assert.strictEqual(sub.borderTopWidth, '1px', 'a border, where the dropdown menu’s has a ring')
    await a11yAudit()
  })

  test('the keyboard, and right to left', async function (assert) {
    await render(
      <template>
        <Area />
        <DirectionProvider @dir="rtl">
          <ContextMenu as |c|>
            <c.Trigger class="cm-area">انقر هنا</c.Trigger>
            <c.Content>
              <c.Sub as |s|>
                <s.Trigger>التنقل</s.Trigger>
                <s.Content><c.Item>رجوع</c.Item></s.Content>
              </c.Sub>
              <c.Item>إعادة تحميل</c.Item>
            </c.Content>
          </ContextMenu>
        </DirectionProvider>
      </template>,
    )
    const menu = new ContextMenuHarness()
    await menu.open()
    // Placed by Floating UI (its anchor is the pointer): there at once, not sliding into place,
    // so the submenu below measures it where it stays.
    const content = menu.content!
    assert.strictEqual(getComputedStyle(content).left, content.style.left, 'no slide into place')
    assert.strictEqual(getComputedStyle(content).top, content.style.top)
    await pressKey('ArrowDown')
    assert.strictEqual(menu.highlighted, 'التنقل')
    await pressKey('ArrowLeft')
    const sub = menu.sub('التنقل')
    assert.true(sub.isOpen, 'ArrowLeft opens a submenu right to left')
    assert.strictEqual(sub.highlighted, 'رجوع')
    assert.strictEqual(sub.side, 'left')
    await pressKey('ArrowRight')
    assert.false(sub.isOpen)
    await menu.pressEscape()
    assert.false(menu.isOpen)
    await a11yAudit()
  })
})
