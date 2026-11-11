import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { focus, render, waitUntil } from '@ember/test-helpers'
import { htmlSafe } from '@ember/template'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Table } from '@ember-joinery/ember'
import { TableHarness } from '@ember-joinery/test-support'

const INVOICES = [
  { invoice: 'INV001', status: 'Paid', method: 'Credit Card', amount: '$250.00' },
  { invoice: 'INV002', status: 'Pending', method: 'PayPal', amount: '$150.00' },
  { invoice: 'INV003', status: 'Unpaid', method: 'Bank Transfer', amount: '$350.00' },
]

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/** The colour a token resolves to here, as the browser computes it. */
function token(name: string, property: 'color' | 'backgroundColor' = 'color'): string {
  const probe = document.createElement('span')
  probe.style[property] = `var(${name})`
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe)[property]
  probe.remove()
  return value
}

module('Integration | components | table', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream anatomy: a container, the table and its parts', async function (assert) {
    await render(
      <template>
        <Table class="mine" @name="invoices" as |t|>
          <t.Caption>A list of your recent invoices.</t.Caption>
          <t.Header>
            <t.Row>
              <t.Head>Invoice</t.Head>
              <t.Head>Amount</t.Head>
            </t.Row>
          </t.Header>
          <t.Body>
            <t.Row>
              <t.Cell>INV001</t.Cell>
              <t.Cell>$250.00</t.Cell>
            </t.Row>
          </t.Body>
          <t.Footer>
            <t.Row>
              <t.Cell>Total</t.Cell>
              <t.Cell>$250.00</t.Cell>
            </t.Row>
          </t.Footer>
        </Table>
      </template>,
    )
    const table = new TableHarness('invoices')
    assert
      .dom(table.container)
      .hasTagName('div')
      .hasClass('jn-table-container')
      .hasAttribute('data-slot', 'table-container')
    assert
      .dom(table.element)
      .hasTagName('table')
      .hasClass('jn-table')
      .hasClass('mine', 'attributes go on the table, as upstream')
      .hasAttribute('data-slot', 'table')
    const parts: [string, string, string][] = [
      ['caption', 'caption', 'table-caption'],
      ['header', 'thead', 'table-header'],
      ['body', 'tbody', 'table-body'],
      ['footer', 'tfoot', 'table-footer'],
      ['row', 'tr', 'table-row'],
      ['head', 'th', 'table-head'],
      ['cell', 'td', 'table-cell'],
    ]
    for (const [part, tag, slot] of parts) {
      assert
        .dom(table.part(part))
        .hasTagName(tag)
        .hasClass(`jn-${slot}`)
        .hasAttribute('data-slot', slot)
    }
    assert.strictEqual(table.caption, 'A list of your recent invoices.')
    assert.deepEqual(table.columns, ['Invoice', 'Amount'])
    assert.deepEqual(table.rows, [['INV001', '$250.00']])
    assert.deepEqual(table.footer, [['Total', '$250.00']])
    await a11yAudit()
  })

  test('its style sheet lays it out, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="width: 480px">
          <Table as |t|>
            <t.Caption>Invoices</t.Caption>
            <t.Header>
              <t.Row><t.Head>Invoice</t.Head><t.Head>Amount</t.Head></t.Row>
            </t.Header>
            <t.Body>
              {{#each INVOICES as |invoice|}}
                <t.Row><t.Cell>{{invoice.invoice}}</t.Cell><t.Cell
                  >{{invoice.amount}}</t.Cell></t.Row>
              {{/each}}
            </t.Body>
            <t.Footer>
              <t.Row><t.Cell>Total</t.Cell><t.Cell>$750.00</t.Cell></t.Row>
            </t.Footer>
          </Table>
        </div>
      </template>,
    )
    const table = new TableHarness()
    const style = (element: Element) => getComputedStyle(element)

    assert.strictEqual(style(table.container).overflowX, 'auto', 'overflow-x-auto')
    assert.strictEqual(style(table.container).position, 'relative')
    assert.strictEqual(px(style(table.element).width), 480, 'w-full')
    assert.strictEqual(style(table.element).captionSide, 'bottom', 'caption-bottom')
    assert.strictEqual(style(table.element).fontSize, '14px', 'text-sm')
    assert.strictEqual(
      style(table.element).borderCollapse,
      'collapse',
      "its borders collapse, as preflight gives upstream's",
    )

    const head = table.part('head')
    assert.strictEqual(style(head).height, '40px', 'h-10')
    assert.strictEqual(style(head).paddingLeft, '8px', 'px-2')
    assert.strictEqual(style(head).paddingTop, '0px')
    assert.strictEqual(style(head).fontWeight, '500', 'font-medium')
    assert.strictEqual(style(head).textAlign, 'start', 'text-start: logical')
    assert.strictEqual(style(head).whiteSpace, 'nowrap')
    assert.strictEqual(style(head).color, token('--foreground'), 'text-foreground')

    const cell = table.cell(0, 0)
    assert.strictEqual(style(cell).paddingTop, '8px', 'p-2')
    assert.strictEqual(style(cell).verticalAlign, 'middle')

    const [first, , last] = table.rowElements
    assert.strictEqual(style(first!).borderBottomWidth, '1px', 'border-b')
    assert.strictEqual(
      style(first!).borderBottomColor,
      token('--border'),
      'in the theme’s --border',
    )
    assert.strictEqual(style(last!).borderBottomWidth, '0px', "the body's last row has none")
    const headerRow = table.table.tHead!.rows[0]!
    assert.strictEqual(style(headerRow).borderBottomWidth, '1px', "the header's row has one")

    const footer = table.part('footer')
    assert.strictEqual(style(footer).borderTopWidth, '1px', 'border-t')
    assert.strictEqual(style(footer).fontWeight, '500', 'font-medium')
    assert.notStrictEqual(style(footer).backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-muted/50')
    const footerRow = table.table.tFoot!.rows[0]!
    assert.strictEqual(style(footerRow).borderBottomWidth, '0px', "the footer's last row has none")

    const caption = table.part('caption')
    assert.strictEqual(style(caption).marginTop, '16px', 'mt-4')
    assert.strictEqual(style(caption).color, token('--muted-foreground'), 'text-muted-foreground')
    assert.ok(
      caption.getBoundingClientRect().top >=
        table.rowElements.at(-1)!.getBoundingClientRect().bottom,
      'the caption is under the table',
    )
    await a11yAudit()
  })

  test('a selected row, and one whose row expands, are shaded', async function (assert) {
    await render(
      <template>
        <Table as |t|>
          <t.Header><t.Row><t.Head>Name</t.Head><t.Head>More</t.Head></t.Row></t.Header>
          <t.Body>
            <t.Row data-case="plain"><t.Cell>Plain</t.Cell><t.Cell>—</t.Cell></t.Row>
            <t.Row data-case="selected" data-state="selected">
              <t.Cell>Selected</t.Cell><t.Cell>—</t.Cell>
            </t.Row>
            <t.Row data-case="expanded">
              <t.Cell>Expanded</t.Cell>
              <t.Cell><button type="button" aria-expanded="true">Less</button></t.Cell>
            </t.Row>
          </t.Body>
        </Table>
      </template>,
    )
    const background = (name: string) =>
      getComputedStyle(document.querySelector(`[data-case="${name}"]`)!).backgroundColor
    assert.strictEqual(background('plain'), 'rgba(0, 0, 0, 0)')
    assert.strictEqual(background('selected'), token('--muted', 'backgroundColor'), 'bg-muted')
    assert.notStrictEqual(
      background('expanded'),
      'rgba(0, 0, 0, 0)',
      'has-aria-expanded:bg-muted/50',
    )
    assert.notStrictEqual(background('expanded'), background('selected'), 'at half strength')
    await a11yAudit()
  })

  test('a wide table scrolls sideways in its container, which the keyboard can then reach', async function (assert) {
    class Width {
      @tracked value = 200
    }
    const width = new Width()
    const box = (value: number) => htmlSafe(`width: ${value}px`)
    await render(
      <template>
        <div style={{box width.value}}>
          <Table @name="plain" as |t|>
            <t.Header>
              <t.Row>
                <t.Head>Invoice number</t.Head>
                <t.Head>Payment status</t.Head>
                <t.Head>Payment method</t.Head>
              </t.Row>
            </t.Header>
            <t.Body>
              <t.Row><t.Cell>INV001</t.Cell><t.Cell>Paid</t.Cell><t.Cell>Credit Card</t.Cell></t.Row>
            </t.Body>
          </Table>
        </div>
        <div style="width: 200px">
          <Table @name="linked" as |t|>
            <t.Header>
              <t.Row><t.Head>Invoice number</t.Head><t.Head>Payment status</t.Head></t.Row>
            </t.Header>
            <t.Body>
              <t.Row><t.Cell><a href="#inv001">INV001</a></t.Cell><t.Cell>Paid</t.Cell></t.Row>
            </t.Body>
          </Table>
        </div>
      </template>,
    )
    const { container } = new TableHarness('plain')
    assert.strictEqual(container.clientWidth, 200)
    assert.ok(
      container.scrollWidth > container.clientWidth,
      'the cells keep to one line, and scroll',
    )
    await waitUntil(() => container.getAttribute('tabindex') === '0')
    assert.strictEqual(container.tabIndex, 0, 'with nothing inside to focus, it is a tab stop')
    await focus(container)
    assert.strictEqual(document.activeElement, container)

    const linked = new TableHarness('linked').container
    assert.ok(linked.scrollWidth > linked.clientWidth)
    assert.dom(linked).doesNotHaveAttribute('tabindex', 'its link takes focus, and scrolls it')

    width.value = 900
    await waitUntil(() => !container.hasAttribute('tabindex'))
    assert.strictEqual(container.scrollWidth, container.clientWidth, 'wide enough: no scrolling')
    assert.dom(container).doesNotHaveAttribute('tabindex', 'and no tab stop')
    await a11yAudit()
  })

  test('a part takes @as, and the modifiers make your own elements parts', async function (assert) {
    await render(
      <template>
        <Table as |t|>
          <t.Header><t.Row><t.Head>Name</t.Head><t.Head>Price</t.Head></t.Row></t.Header>
          <t.Body>
            <t.Row>
              <t.Cell @as="th" scope="row">Wireless Mouse</t.Cell>
              <t.Cell>$29.99</t.Cell>
            </t.Row>
            <tr class="own" {{t.row}}>
              <td {{t.cell}}>USB-C Hub</td>
              <td {{t.cell}}>$49.99</td>
            </tr>
          </t.Body>
        </Table>
      </template>,
    )
    const table = new TableHarness()
    const rowHead = table.cell(0, 0)
    assert
      .dom(rowHead)
      .hasTagName('th')
      .hasAttribute('scope', 'row')
      .hasClass('jn-table-cell')
      .hasAttribute('data-slot', 'table-cell')

    const own = table.row(1)
    assert
      .dom(own)
      .hasClass('own')
      .hasClass('jn-table-row')
      .hasAttribute('data-slot', 'table-row')
      .hasAttribute('data-test-jn-part', 'row')
    assert.dom(table.cell(1, 'Price')).hasClass('jn-table-cell').hasText('$49.99')
    assert.strictEqual(getComputedStyle(table.cell(1, 1)).paddingTop, '8px', 'styled as a cell')
    assert.deepEqual(table.column('Name'), ['Wireless Mouse', 'USB-C Hub'])
    await a11yAudit()
  })

  test('RTL: the first column is on the right, and a checkbox cell drops its end padding there', async function (assert) {
    await render(
      <template>
        <Table @name="ltr" as |t|>
          <t.Header><t.Row><t.Head>Select</t.Head><t.Head>Name</t.Head></t.Row></t.Header>
          <t.Body>
            <t.Row>
              <t.Cell><button
                  type="button"
                  role="checkbox"
                  aria-checked="false"
                  aria-label="Select"
                ></button></t.Cell>
              <t.Cell>Ada</t.Cell>
            </t.Row>
          </t.Body>
        </Table>
        <DirectionProvider @dir="rtl">
          <Table @name="rtl" as |t|>
            <t.Header><t.Row><t.Head>تحديد</t.Head><t.Head>الاسم</t.Head></t.Row></t.Header>
            <t.Body>
              <t.Row>
                <t.Cell><button
                    type="button"
                    role="checkbox"
                    aria-checked="false"
                    aria-label="تحديد"
                  ></button></t.Cell>
                <t.Cell>آدا</t.Cell>
              </t.Row>
            </t.Body>
          </Table>
        </DirectionProvider>
      </template>,
    )
    const ltr = new TableHarness('ltr')
    const rtl = new TableHarness('rtl')
    const edges = (harness: TableHarness) => ({
      table: harness.element.getBoundingClientRect(),
      first: harness.cell(0, 0).getBoundingClientRect(),
    })
    const left = edges(ltr)
    const right = edges(rtl)
    assert.ok(Math.abs(left.first.left - left.table.left) < 1, 'left to right, it is on the left')
    assert.ok(Math.abs(right.first.right - right.table.right) < 1, 'right to left, on the right')

    // [&:has([role=checkbox])]:pe-0: the cell's end padding goes, on the end's side.
    const ltrCell = getComputedStyle(ltr.cell(0, 0))
    const rtlCell = getComputedStyle(rtl.cell(0, 0))
    assert.strictEqual(ltrCell.paddingRight, '0px')
    assert.strictEqual(ltrCell.paddingLeft, '8px')
    assert.strictEqual(rtlCell.paddingLeft, '0px')
    assert.strictEqual(rtlCell.paddingRight, '8px')
    const rtlHead = rtl.part('head')
    assert.ok(
      Math.abs(rtlHead.getBoundingClientRect().right - right.first.right) < 1,
      "a header cell's text starts on the right (text-start)",
    )
    await a11yAudit()
  })

  test('the harness reads cells by row and column, and says what is missing', async function (assert) {
    await render(
      <template>
        <Table @name="invoices" as |t|>
          <t.Header>
            <t.Row>
              <t.Head>Invoice</t.Head><t.Head>Status</t.Head><t.Head>Method</t.Head>
              <t.Head>Amount</t.Head>
            </t.Row>
          </t.Header>
          <t.Body>
            {{#each INVOICES as |invoice|}}
              <t.Row>
                <t.Cell>{{invoice.invoice}}</t.Cell>
                <t.Cell>{{invoice.status}}</t.Cell>
                <t.Cell>{{invoice.method}}</t.Cell>
                <t.Cell>{{invoice.amount}}</t.Cell>
              </t.Row>
            {{/each}}
          </t.Body>
          <t.Footer>
            <t.Row><t.Cell colspan="3">Total</t.Cell><t.Cell>$750.00</t.Cell></t.Row>
          </t.Footer>
        </Table>
      </template>,
    )
    const table = new TableHarness('invoices')
    assert.strictEqual(table.rowCount, 3)
    assert.deepEqual(table.column('Status'), ['Paid', 'Pending', 'Unpaid'])
    assert.dom(table.cell(2, 'Amount')).hasText('$350.00')
    assert.dom(table.cell(1, 2)).hasText('PayPal')
    assert.deepEqual(table.footer, [['Total', '$750.00']], 'a spanning cell counts once')
    assert.strictEqual(table.caption, null)
    assert.throws(() => table.row(5), /no row 5 in table "invoices" \(it has 3\)/)
    assert.throws(() => table.cell(0, 'Due'), /no column "Due" in table "invoices"/)
    await a11yAudit()
  })
})
