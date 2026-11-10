import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { focus, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Toaster } from '@ember-joinery/ember'
import {
  CardHarness,
  DrawerHarness,
  DropdownMenuHarness,
  InputHarness,
  SelectHarness,
  SidebarHarness,
  TabsHarness,
  ToasterHarness,
  ToggleGroupHarness,
  pressKey,
  sendPointer,
  setupToaster,
} from '@ember-joinery/test-support'
import { ChartHarness } from '@ember-joinery/chart/test-support'
import { DataTableHarness } from '@ember-joinery/data-table/test-support'
import Dashboard01 from 'docs-app/examples/dashboard-01'

/**
 * Two of upstream's colours fall short of the 4.5:1 WCAG AA asks of small text: the avatar's
 * initials, `--muted-foreground` on `--muted` (the Avatar page's Accessibility notes say how an
 * app can darken it), and a selected row's muted text (its type badge, and an unassigned
 * reviewer's placeholder), `--muted-foreground` on the row's `--muted` tint. So the audit runs
 * every rule but colour contrast over the whole example, then colour contrast over all of it
 * but those.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_UPSTREAM_COLOURS = {
  include: [['#ember-testing-container']],
  exclude: [
    ['[data-slot="avatar-fallback"]'],
    ['tr[data-state="selected"] .text-muted-foreground'],
    ['tr[data-state="selected"] [data-slot="select-value"]'],
  ],
  runOnly: ['color-contrast'],
}

/** The block's table, as a page object: its sections, their handles, and its pagination. */
class Sections extends DataTableHarness {
  /** Each row's header, top to bottom. */
  get headers(): string[] {
    return this.column('header')
  }

  /** The drag handle of row `index` on this page. */
  handle(index: number): HTMLButtonElement {
    return this.cell(index, 'drag').querySelector('button')!
  }

  /** The table's live region, which says each step of a drag. */
  get announcement(): string {
    return this.element.querySelector('[aria-live]')?.textContent?.trim() ?? ''
  }

  /** "Page 1 of 7". */
  get pageText(): string {
    const text = [...this.element.querySelectorAll('.text-sm.font-medium')].find(element =>
      element.textContent?.includes('Page'),
    )
    return text?.textContent?.replace(/\s+/g, ' ').trim() ?? ''
  }

  get selectionText(): string {
    const text = [...this.element.querySelectorAll('.text-muted-foreground')].find(element =>
      element.textContent?.includes('row(s) selected'),
    )
    return text?.textContent?.replace(/\s+/g, ' ').trim() ?? ''
  }

  get rowsPerPage(): SelectHarness {
    return this.findAll(SelectHarness).find(select => select.trigger.id === 'rows-per-page')!
  }

  get views(): TabsHarness {
    return new TabsHarness({ within: this })
  }

  /** The drawer each row's header opens. */
  viewer(index: number): DrawerHarness {
    return new DrawerHarness({ within: this.cell(index, 'header') })
  }
}

module('Example | dashboard-01', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a dashboard: an inset sidebar, four section cards, a chart and a table', async function (assert) {
    await render(<template><Dashboard01 /></template>)
    const sidebar = new SidebarHarness()
    assert.strictEqual(sidebar.variant, 'inset')
    assert.strictEqual(sidebar.state, 'expanded')
    assert.deepEqual(sidebar.menuButtonLabels, [
      'Acme Inc.',
      'Quick Create',
      'Dashboard',
      'Lifecycle',
      'Analytics',
      'Projects',
      'Team',
      'Data Library',
      'Reports',
      'Word Assistant',
      'More',
      'Settings',
      'Get Help',
      'Search',
      'CN shadcn m@example.com',
    ])
    assert.deepEqual(sidebar.groupLabels, ['Documents'])
    assert.strictEqual(
      getComputedStyle(sidebar.container!).width,
      '288px',
      '--sidebar-width: calc(var(--spacing) * 72)',
    )
    const header = sidebar.inset!.querySelector('header')!
    assert.strictEqual(header.querySelector('h1')?.textContent, 'Documents')
    assert.strictEqual(getComputedStyle(header).height, '48px', '--header-height')

    const cards = CardHarness.findAll().slice(0, 4)
    assert.deepEqual(
      cards.map(card => [card.description, card.title, card.action.textContent?.trim()]),
      [
        ['Total Revenue', '$1,250.00', '+12.5%'],
        ['New Customers', '1,234', '-20%'],
        ['Active Accounts', '45,678', '+12.5%'],
        ['Growth Rate', '4.5%', '+4.5%'],
      ],
    )

    const chart = new ChartHarness()
    assert.deepEqual(
      chart.series.map(series => [series.key, series.points.length]),
      [
        ['mobile', 91],
        ['desktop', 91],
      ],
      'the last 3 months, stacked',
    )

    const table = new Sections()
    assert.strictEqual(table.rowCount, 10)
    assert.deepEqual(table.headers.slice(0, 3), [
      'Cover page',
      'Table of contents',
      'Executive summary',
    ])
    assert.strictEqual(table.pageText, 'Page 1 of 7')
    assert.deepEqual(table.views.tabValues, [
      'outline',
      'past-performance',
      'key-personnel',
      'focus-documents',
    ])
    assert.strictEqual(table.views.selected, 'outline')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_UPSTREAM_COLOURS)

    await sidebar.toggle()
    assert.strictEqual(sidebar.state, 'collapsed')
    assert.strictEqual(sidebar.collapsible, 'offcanvas', 'it slides off the page')
  })

  test("the chart's range: the last 3 months, 30 days or 7 days", async function (assert) {
    await render(<template><Dashboard01 /></template>)
    const range = new ToggleGroupHarness()
    assert.deepEqual(range.value, ['90d'])
    assert.strictEqual(range.variant, 'outline')
    const chart = new ChartHarness()

    await range.toggle('30d')
    assert.deepEqual(range.value, ['30d'])
    assert.strictEqual(chart.series[0]!.points.length, 31, 'June, and the last day of May')
    await range.toggle('7d')
    assert.strictEqual(chart.series[0]!.points.length, 8, 'June 23 to 30')

    await chart.hover(0)
    // Upstream's labels read each date in the browser's time zone, as these do.
    const first = new Date('2024-06-23').toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    })
    assert.strictEqual(chart.tooltip?.label, first)
    assert.strictEqual(chart.tooltip?.indicator, 'dot')
    assert.deepEqual(chart.tooltip?.names, ['Desktop', 'Mobile'], 'the top of the stack first')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_UPSTREAM_COLOURS)
    await chart.unhover()
  })

  test('rows are selected, paged, and their columns shown or hidden', async function (assert) {
    await render(<template><Dashboard01 /></template>)
    const table = new Sections()
    assert.strictEqual(table.selectionText, '0 of 68 row(s) selected.')
    await table.toggleRow(1)
    assert.true(table.isSelected(1))
    assert.strictEqual(table.selectAll?.state, 'indeterminate')
    await table.toggleAll()
    assert.strictEqual(table.selectionText, '10 of 68 row(s) selected.')

    await table.nextPage()
    assert.strictEqual(table.pageText, 'Page 2 of 7')
    assert.false(table.isSelected(0), 'the next page starts unselected')

    await table.rowsPerPage.open()
    await table.rowsPerPage.select('20')
    assert.strictEqual(table.rowCount, 20)
    assert.strictEqual(table.pageText, 'Page 1 of 4', 'the page that holds the first row shown')

    assert.deepEqual(await table.columnOptions(), ['type', 'status', 'target', 'limit', 'reviewer'])
    await table.viewOptions.select('status')
    assert.false(table.isColumnShown('status'))
    assert.true(table.isColumnShown('type'))
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_UPSTREAM_COLOURS)
  })

  test('the keyboard drags a row to a new place, and says so', async function (assert) {
    await render(<template><Dashboard01 /></template>)
    const table = new Sections()
    const handle = table.handle(0)
    assert.strictEqual(handle.getAttribute('aria-roledescription'), 'sortable')
    const instructions = document.getElementById(handle.getAttribute('aria-describedby')!)
    assert.ok(instructions?.textContent?.startsWith('To pick up a draggable item'))

    await focus(handle)
    await pressKey(' ')
    assert.strictEqual(handle.getAttribute('aria-pressed'), 'true')
    assert.strictEqual(table.row(0).getAttribute('data-dragging'), 'true')
    assert.strictEqual(table.announcement, 'Picked up draggable item 1.')

    await pressKey('ArrowDown')
    await pressKey('ArrowDown')
    assert.strictEqual(table.announcement, 'Draggable item 1 was moved over droppable area 3.')
    assert.notStrictEqual(table.row(0).style.transform, '', 'the row moves down')

    await pressKey(' ')
    assert.deepEqual(table.headers.slice(0, 3), [
      'Table of contents',
      'Executive summary',
      'Cover page',
    ])
    assert.strictEqual(table.announcement, 'Draggable item 1 was dropped over droppable area 3')
    assert.false(table.handle(2).hasAttribute('aria-pressed'))
    assert.dom(table.handle(2)).isFocused('the moved row keeps focus')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_UPSTREAM_COLOURS)

    await pressKey(' ')
    await pressKey('ArrowUp')
    await pressKey('Escape')
    assert.strictEqual(table.announcement, 'Dragging was cancelled. Draggable item 1 was dropped.')
    assert.strictEqual(table.headers[2], 'Cover page', 'Escape puts it back')
  })

  test('a pointer drags a row by its handle', async function (assert) {
    await render(<template><Dashboard01 /></template>)
    const table = new Sections()
    const handle = table.handle(0)
    const row = table.row(0).getBoundingClientRect()
    const x = handle.getBoundingClientRect().left + 2
    const y = row.top + row.height / 2

    await sendPointer(handle, 'pointerdown', { clientX: x, clientY: y })
    assert.strictEqual(table.announcement, 'Picked up draggable item 1.')
    await sendPointer(handle, 'pointermove', { clientX: x, clientY: y + row.height * 1.6 })
    assert.strictEqual(table.announcement, 'Draggable item 1 was moved over droppable area 3.')
    await sendPointer(handle, 'pointerup', { clientX: x, clientY: y + row.height * 1.6 })
    assert.deepEqual(table.headers.slice(0, 3), [
      'Table of contents',
      'Executive summary',
      'Cover page',
    ])
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_UPSTREAM_COLOURS)
  })

  test("a row's header opens its drawer, and its target saves with a toast", async function (assert) {
    await render(
      <template>
        <Dashboard01 />
        <Toaster />
      </template>,
    )
    const table = new Sections()
    const drawer = table.viewer(0)
    await drawer.open()
    await drawer.afterOpening()
    assert.true(drawer.isOpen)
    assert.strictEqual(drawer.direction, 'right', 'beside the page, on a wide screen')
    assert.strictEqual(drawer.title?.textContent?.trim(), 'Cover page')
    const fields = drawer.findAll(InputHarness)
    assert.deepEqual(
      fields.map(field => [field.label, field.value]),
      [
        ['Header', 'Cover page'],
        ['Target', '18'],
        ['Limit', '5'],
      ],
    )
    assert.ok(drawer.find(ChartHarness).series.length, 'its chart')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_UPSTREAM_COLOURS)
    await drawer.close()
    assert.false(drawer.isOpen)

    const target = new InputHarness({ within: table.cell(0, 'target') })
    assert.strictEqual(target.label, 'Target')
    await target.fillIn('20')
    // Enter in the input submits its form; a test's keydown can't, so this submits it as Enter does.
    target.control.form!.requestSubmit()
    const toaster = new ToasterHarness()
    const toast = await toaster.waitForToast('Saving Cover page')
    assert.true(toast.isLoading)
    await toaster.waitForToast('Done')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_UPSTREAM_COLOURS)
  })

  test("a row's actions, and the reviewer it has yet to be assigned", async function (assert) {
    await render(<template><Dashboard01 /></template>)
    const table = new Sections()
    const actions = new DropdownMenuHarness({ within: table.cell(0, 'actions') })
    await actions.open()
    assert.deepEqual(actions.items, ['Edit', 'Make a copy', 'Favorite', 'Delete'])
    await actions.close()

    const unassigned = table.column('reviewer').indexOf('Reviewer Assign reviewer')
    assert.strictEqual(unassigned, 7, 'the eighth section has none yet')
    const reviewer = new SelectHarness({ within: table.cell(unassigned, 'reviewer') })
    assert.strictEqual(reviewer.label, 'Reviewer')
    assert.true(reviewer.isPlaceholder)
    await reviewer.open()
    assert.deepEqual(reviewer.optionTexts, ['Eddie Lake', 'Jamik Tashpulatov'])
    await reviewer.select('Eddie Lake')
    assert.strictEqual(reviewer.valueText, 'Eddie Lake')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_UPSTREAM_COLOURS)
  })
})
