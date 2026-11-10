import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { File, Trash } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Icon, Menubar } from '@ember-joinery/ember'
import { MenubarHarness, pressKey } from '@ember-joinery/test-support'

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

const rect = (element: Element) => element.getBoundingClientRect()

/** The colour a token resolves to, as computed styles report colours. */
function token(name: string): string {
  const probe = document.createElement('div')
  probe.style.setProperty('color', `var(${name})`)
  document.body.append(probe)
  const color = getComputedStyle(probe).color
  probe.remove()
  return color
}

/** Ends the content's entry animation, so its computed style is the resting one. */
function finishAnimations(element: Element) {
  for (const animation of element.getAnimations({ subtree: true })) animation.finish()
}

class State {
  @tracked bookmarks = false
  @tracked person = 'benoit'
  setBookmarks = (checked: boolean) => (this.bookmarks = checked)
  setPerson = (person: string) => (this.person = person)
}

module('Integration | components | menubar', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream’s classes and slots', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Menubar @name="app" as |bar|>
          <bar.Menu as |m|>
            <m.Trigger>File</m.Trigger>
            <m.Content>
              <m.Group>
                <m.Label>Tabs</m.Label>
                <m.Item>New Tab <m.Shortcut>⌘T</m.Shortcut></m.Item>
              </m.Group>
              <m.Separator />
              <m.CheckboxItem
                @checked={{state.bookmarks}}
                @onCheckedChange={{state.setBookmarks}}
              >Bookmarks Bar</m.CheckboxItem>
              <m.RadioGroup @value={{state.person}} @onValueChange={{state.setPerson}} as |g|>
                <g.Item @value="andy">Andy</g.Item>
                <g.Item @value="benoit">Benoit</g.Item>
              </m.RadioGroup>
              <m.Sub as |s|>
                <s.Trigger>Share</s.Trigger>
                <m.Portal>
                  <s.Content><m.Item>Email link</m.Item></s.Content>
                </m.Portal>
              </m.Sub>
              <m.Item @variant="destructive">Delete</m.Item>
            </m.Content>
          </bar.Menu>
        </Menubar>
      </template>,
    )
    const menubar = new MenubarHarness('app')
    assert.dom(menubar.element).hasClass('jn-menubar').hasAttribute('data-slot', 'menubar')
    const file = menubar.menu('File')
    assert
      .dom(file.trigger)
      .hasClass('jn-menubar-trigger')
      .hasAttribute('data-slot', 'menubar-trigger')
    await file.open()
    const content = file.content!
    assert
      .dom(content)
      .hasClass('jn-menubar-content')
      .hasClass('jn-menu-target')
      .doesNotHaveClass('jn-menu-translucent', 'shadcn’s default menu colour drops it')
      .hasAttribute('data-slot', 'menubar-content')
      .hasAttribute('data-side', 'bottom')
      .hasAttribute('data-align', 'start')
    assert.dom('[data-slot="menubar-group"]', content).hasAttribute('role', 'group')
    assert.dom('[data-slot="menubar-label"]', content).hasClass('jn-menubar-label')
    assert
      .dom(file.item('New Tab'))
      .hasClass('jn-menubar-item')
      .hasClass('group/menubar-item')
      .hasAttribute('data-slot', 'menubar-item')
      .hasAttribute('data-variant', 'default')
    assert
      .dom('[data-slot="menubar-shortcut"]', file.item('New Tab'))
      .hasClass('jn-menubar-shortcut')
    assert.strictEqual(file.shortcut('New Tab'), '⌘T')
    assert.dom('[data-slot="menubar-separator"]', content).hasClass('jn-menubar-separator')
    assert
      .dom(file.item('Bookmarks Bar'))
      .hasClass('jn-menubar-checkbox-item')
      .hasAttribute('data-slot', 'menubar-checkbox-item')
    assert
      .dom('.jn-menubar-checkbox-item-indicator', file.item('Bookmarks Bar'))
      .doesNotHaveAttribute('data-slot', 'as upstream’s, its indicator has no slot')
    assert.dom('[data-slot="menubar-radio-group"]', content).exists()
    assert.dom(file.item('Benoit')).hasClass('jn-menubar-radio-item')
    assert.dom('.jn-menubar-radio-item-indicator svg', file.item('Benoit')).exists()
    assert
      .dom(file.item('Share'))
      .hasClass('jn-menubar-sub-trigger')
      .hasAttribute('data-slot', 'menubar-sub-trigger')
    assert
      .dom('svg.jn-rtl-flip', file.item('Share'))
      .hasClass('jn-size-4', 'upstream sizes the menubar’s chevron with a class')
    assert.strictEqual(file.variant('Delete'), 'destructive')
    await a11yAudit()

    const share = file.sub('Share')
    await share.open()
    assert
      .dom(share.content)
      .hasClass('jn-menubar-sub-content')
      .hasClass('jn-menu-target')
      .hasAttribute('data-slot', 'menubar-sub-content')
    await a11yAudit()
  })

  test('its style sheet sizes, colours and places it, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 100px; left: 200px">
          <Menubar @defaultValue="file" as |bar|>
            <bar.Menu @value="file" as |m|>
              <m.Trigger>File</m.Trigger>
              <m.Content>
                <m.Label>Files</m.Label>
                <m.Item><Icon @icon={{File}} />New File<m.Shortcut>⌘N</m.Shortcut></m.Item>
                <m.Item @inset={{true}}>Reload</m.Item>
                <m.Item @disabled={{true}}>Force Reload</m.Item>
                <m.Separator />
                <m.CheckboxItem @checked={{true}}>Full URLs</m.CheckboxItem>
                <m.Sub as |s|>
                  <s.Trigger>Share</s.Trigger>
                  <s.Content><m.Item>Email link</m.Item></s.Content>
                </m.Sub>
                <m.Item @variant="destructive"><Icon @icon={{Trash}} />Delete</m.Item>
              </m.Content>
            </bar.Menu>
            <bar.Menu as |m|>
              <m.Trigger>Edit</m.Trigger>
              <m.Content><m.Item>Undo</m.Item></m.Content>
            </bar.Menu>
          </Menubar>
        </div>
      </template>,
    )
    const menubar = new MenubarHarness()
    const bar = getComputedStyle(menubar.element)
    assert.strictEqual(bar.display, 'flex', 'flex')
    assert.strictEqual(bar.alignItems, 'center', 'items-center')
    assert.strictEqual(bar.height, '32px', 'h-8')
    assert.strictEqual(bar.paddingTop, '3px', 'p-[3px]')
    assert.strictEqual(bar.borderTopWidth, '1px', 'border')
    assert.strictEqual(bar.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(bar.columnGap, '2px', 'gap-0.5')

    const file = menubar.menu('File')
    const trigger = getComputedStyle(file.trigger)
    assert.strictEqual(trigger.paddingInlineStart, '6px', 'px-1.5')
    assert.strictEqual(trigger.paddingTop, '2px', 'py-[2px]')
    assert.strictEqual(px(trigger.fontSize), 14, 'text-sm')
    assert.strictEqual(trigger.fontWeight, '500', 'font-medium')
    assert.strictEqual(trigger.userSelect, 'none', 'select-none')
    assert.strictEqual(trigger.backgroundColor, token('--muted'), 'aria-expanded:bg-muted')

    const content = file.content!
    finishAnimations(content)
    const style = getComputedStyle(content)
    assert.strictEqual(style.minWidth, '144px', 'min-w-36')
    assert.strictEqual(style.paddingTop, '4px', 'p-1')
    assert.strictEqual(style.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(style.backgroundColor, token('--popover'), 'bg-popover')
    assert.notStrictEqual(style.boxShadow, 'none', 'shadow-md and its ring')
    assert.strictEqual(style.overflow, 'hidden')
    const t = rect(file.trigger)
    const c = rect(content)
    assert.true(Math.abs(c.top - (t.bottom + 8)) <= 1, `8px below its trigger (${c.top})`)
    assert.true(Math.abs(c.left - (t.left - 4)) <= 1, `4px before its start (${c.left})`)

    const label = getComputedStyle(content.querySelector('[data-slot="menubar-label"]')!)
    assert.strictEqual(px(label.fontSize), 14, 'the label is text-sm')
    assert.strictEqual(label.fontWeight, '500', 'font-medium')

    const item = getComputedStyle(file.item('New File'))
    assert.strictEqual(item.display, 'flex')
    assert.strictEqual(item.paddingInlineStart, '6px', 'px-1.5')
    assert.strictEqual(item.paddingTop, '4px', 'py-1')
    assert.strictEqual(item.columnGap, '6px', 'gap-1.5')
    assert.strictEqual(item.borderTopLeftRadius, '8px', 'rounded-md')
    assert.strictEqual(
      getComputedStyle(file.item('New File').querySelector('svg')!).width,
      '16px',
      'its icon is size-4',
    )
    assert.strictEqual(getComputedStyle(file.item('Reload')).paddingInlineStart, '28px', 'ps-7')
    assert.strictEqual(getComputedStyle(file.item('Force Reload')).opacity, '0.5')
    const shortcut = file.item('New File').querySelector('[data-slot="menubar-shortcut"]')!
    assert.strictEqual(px(getComputedStyle(shortcut).fontSize), 12, 'text-xs')
    assert.true(
      Math.abs(rect(shortcut).right - (rect(file.item('New File')).right - 6)) <= 1,
      'at the item’s end (ms-auto)',
    )
    const separator = getComputedStyle(content.querySelector('[data-slot="menubar-separator"]')!)
    assert.strictEqual(separator.height, '1px')
    assert.strictEqual(separator.marginTop, '4px', 'my-1')
    assert.strictEqual(separator.backgroundColor, token('--border'))

    const checkbox = file.item('Full URLs')
    assert.strictEqual(getComputedStyle(checkbox).paddingInlineStart, '28px', 'ps-7')
    const indicator = checkbox.querySelector<HTMLElement>('.jn-menubar-checkbox-item-indicator')!
    assert.strictEqual(getComputedStyle(indicator).position, 'absolute')
    assert.true(
      Math.abs(rect(indicator).left - (rect(checkbox).left + 6)) <= 1,
      'the check at the start: start-1.5',
    )
    assert.strictEqual(rect(indicator).width, 16, 'size-4')

    assert.strictEqual(getComputedStyle(file.item('Delete')).color, token('--destructive'))
    const chevron = file.item('Share').querySelector('svg.jn-rtl-flip')!
    assert.strictEqual(rect(chevron).width, 16, 'size-4')
    assert.true(
      Math.abs(rect(chevron).right - (rect(file.item('Share')).right - 6)) <= 1,
      'the chevron at the end (ms-auto)',
    )
    await file.sub('Share').open()
    const sub = file.sub('Share').content!
    finishAnimations(sub)
    assert.strictEqual(getComputedStyle(sub).minWidth, '128px', 'min-w-32')
    await a11yAudit()
  })

  test('the keyboard, with upstream’s look for the focused item', async function (assert) {
    await render(
      <template>
        <Menubar as |bar|>
          <bar.Menu as |m|>
            <m.Trigger>File</m.Trigger>
            <m.Content>
              <m.Item>New Tab <m.Shortcut>⌘T</m.Shortcut></m.Item>
              <m.Item>New Window</m.Item>
            </m.Content>
          </bar.Menu>
          <bar.Menu as |m|>
            <m.Trigger>Edit</m.Trigger>
            <m.Content><m.Item>Undo</m.Item></m.Content>
          </bar.Menu>
        </Menubar>
      </template>,
    )
    const menubar = new MenubarHarness()
    const file = menubar.menu('File')
    await file.openWithKeyboard()
    assert.strictEqual(file.highlighted, 'New Tab')
    const item = file.item('New Tab')
    assert.strictEqual(getComputedStyle(item).backgroundColor, token('--accent'), 'focus:bg-accent')
    assert.strictEqual(
      getComputedStyle(item.querySelector('[data-slot="menubar-shortcut"]')!).color,
      token('--accent-foreground'),
      'its shortcut turns too',
    )
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.openMenu, 'Edit')
    await menubar.pressEscape()
    assert.dom(menubar.trigger('Edit')).isFocused()
    await a11yAudit()
  })

  test('right to left: the content lines up with the trigger’s right, and the chevron turns', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 100px; left: 400px">
          <DirectionProvider @dir="rtl">
            <Menubar @defaultValue="file" as |bar|>
              <bar.Menu @value="file" as |m|>
                <m.Trigger>ملف</m.Trigger>
                <m.Content>
                  <m.Item @inset={{true}}>إعادة تحميل</m.Item>
                  <m.CheckboxItem @checked={{true}}>عناوين URL الكاملة</m.CheckboxItem>
                  <m.Sub as |s|>
                    <s.Trigger>مشاركة</s.Trigger>
                    <s.Content><m.Item>الرسائل</m.Item></s.Content>
                  </m.Sub>
                </m.Content>
              </bar.Menu>
            </Menubar>
          </DirectionProvider>
        </div>
      </template>,
    )
    const file = new MenubarHarness().menu('ملف')
    const content = file.content!
    finishAnimations(content)
    assert.true(
      Math.abs(rect(content).right - (rect(file.trigger).right + 4)) <= 1,
      'its start is the right edge, 4px past the trigger’s',
    )
    assert.strictEqual(getComputedStyle(file.item('إعادة تحميل')).paddingRight, '28px', 'ps-7')
    const checkbox = file.item('عناوين URL الكاملة')
    const indicator = checkbox.querySelector('.jn-menubar-checkbox-item-indicator')!
    assert.true(
      Math.abs(rect(indicator).right - (rect(checkbox).right - 6)) <= 1,
      'the check on the right',
    )
    const chevron = file.item('مشاركة').querySelector('svg.jn-rtl-flip')!
    assert.strictEqual(getComputedStyle(chevron).rotate, '180deg', 'the chevron points left')
    await a11yAudit()
  })

  test('the trigger and item modifiers style your own elements', async function (assert) {
    await render(
      <template>
        <Menubar as |bar|>
          <bar.Menu as |m|>
            <button type="button" {{m.trigger}}>Mine</button>
            <m.Content>
              <a href="#somewhere" {{m.item inset=true}}>A link</a>
            </m.Content>
          </bar.Menu>
        </Menubar>
      </template>,
    )
    const mine = new MenubarHarness().menu('Mine')
    assert
      .dom(mine.trigger)
      .hasClass('jn-menubar-trigger')
      .hasAttribute('data-slot', 'menubar-trigger')
    await mine.open()
    assert
      .dom(mine.item('A link'))
      .hasClass('jn-menubar-item')
      .hasAttribute('data-slot', 'menubar-item')
      .hasAttribute('data-inset', 'true')
    await a11yAudit()
  })

  test('@as renders a part as another element, styled the same', async function (assert) {
    await render(
      <template>
        <Menubar @as="span" as |bar|>
          <bar.Menu as |m|>
            <m.Trigger @as="span">File</m.Trigger>
            <m.Content>
              <m.Group @as="section">
                <m.Label @as="span">Tabs</m.Label>
                <m.Item @as="span">New Tab</m.Item>
              </m.Group>
              <m.Separator @as="span" />
              <m.CheckboxItem @as="span" @checked={{true}}>Bookmarks Bar</m.CheckboxItem>
            </m.Content>
          </bar.Menu>
        </Menubar>
      </template>,
    )
    const menubar = new MenubarHarness()
    assert
      .dom(menubar.element)
      .hasTagName('span')
      .hasClass('jn-menubar')
      .hasAttribute('role', 'menubar')
    assert.strictEqual(getComputedStyle(menubar.element).height, '32px', 'h-8')
    const file = menubar.menu('File')
    assert
      .dom(file.trigger)
      .hasTagName('span')
      .hasClass('jn-menubar-trigger')
      .hasAttribute('data-slot', 'menubar-trigger')
      .hasAttribute('role', 'menuitem')
    assert.strictEqual(getComputedStyle(file.trigger).paddingInlineStart, '6px', 'px-1.5')
    await a11yAudit()

    await file.open()
    const content = file.content!
    assert.dom('section[data-slot="menubar-group"]', content).exists()
    assert.dom('span[data-slot="menubar-label"]', content).hasText('Tabs')
    assert
      .dom(file.item('New Tab'))
      .hasTagName('span')
      .hasClass('jn-menubar-item')
      .hasAttribute('data-slot', 'menubar-item')
      .hasAttribute('role', 'menuitem')
    assert.dom('span[data-slot="menubar-separator"]', content).hasAttribute('role', 'separator')
    assert
      .dom(file.item('Bookmarks Bar'))
      .hasTagName('span')
      .hasAttribute('data-slot', 'menubar-checkbox-item')
      .hasAttribute('aria-checked', 'true')
    await a11yAudit()
  })
})
