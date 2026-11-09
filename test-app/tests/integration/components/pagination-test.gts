import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { LinkTo } from '@ember/routing'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ArrowLeft } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Pagination, paginationLinkAttributes, paginationLinkClasses } from '@ember-joinery/ember'
import { PaginationHarness, tab } from '@ember-joinery/test-support'

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/** An element's classes and attributes (but the test's own `data-case` and `href`), to compare two. */
function rendering(element: Element): { classes: string[]; attributes: Record<string, string> } {
  const attributes: Record<string, string> = {}
  for (const { name, value } of element.attributes) {
    if (!['class', 'data-case', 'href', 'id'].includes(name)) attributes[name] = value
  }
  // The part's classes; a router link adds its own (`ember-view`, `active`).
  const classes = [...element.classList].filter(name => /^(jn-|group\/)/.test(name)).sort()
  return { classes, attributes }
}

module('Integration | components | pagination', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream anatomy: a named nav, a list, and links that are Buttons', async function (assert) {
    await render(
      <template>
        <Pagination class="mine" as |p|>
          <p.Content>
            <p.Item><p.Previous href="#1" /></p.Item>
            <p.Item><p.Link href="#1">1</p.Link></p.Item>
            <p.Item><p.Link href="#2" @isActive={{true}}>2</p.Link></p.Item>
            <p.Item><p.Ellipsis /></p.Item>
            <p.Item><p.Next href="#3" /></p.Item>
          </p.Content>
        </Pagination>
      </template>,
    )
    const pagination = new PaginationHarness()
    assert
      .dom(pagination.element)
      .hasTagName('nav')
      .hasClass('jn-pagination')
      .hasClass('mine')
      .hasAttribute('role', 'navigation')
      .hasAttribute('aria-label', 'pagination', "upstream's default")
      .hasAttribute('data-slot', 'pagination')
    assert
      .dom(pagination.part('content'))
      .hasTagName('ul')
      .hasClass('jn-pagination-content')
      .hasAttribute('data-slot', 'pagination-content')
    assert
      .dom(pagination.part('item'))
      .hasTagName('li')
      .hasClass('jn-pagination-item', 'jn-<data-slot>, where upstream gives no class')
      .hasAttribute('data-slot', 'pagination-item')

    const [one, two] = pagination.pageElements
    assert
      .dom(one)
      .hasTagName('a')
      .hasAttribute('href', '#1')
      .hasClass('jn-button')
      .hasClass('group/button')
      .hasClass('jn-button-variant-ghost')
      .hasClass('jn-button-size-icon')
      .hasClass('jn-pagination-link')
      .hasAttribute('data-slot', 'pagination-link')
      .hasAttribute('data-variant', 'ghost')
      .hasAttribute('data-size', 'icon')
      .doesNotHaveAttribute('data-active', 'none without @isActive, as upstream')
      .doesNotHaveAttribute('aria-current')
    assert
      .dom(two)
      .hasClass('jn-button-variant-outline', 'the current page is outlined')
      .hasAttribute('data-variant', 'outline')
      .hasAttribute('data-active', 'true')
      .hasAttribute('aria-current', 'page')

    assert
      .dom(pagination.previous)
      .hasTagName('a')
      .hasClass('jn-pagination-link')
      .hasClass('jn-pagination-previous')
      .hasClass('jn-button-size-default')
      .hasAttribute('aria-label', 'Go to previous page')
      .hasAttribute('data-slot', 'pagination-link')
      .hasText('Previous')
    const previousIcon = pagination.previous.querySelector('svg')!
    assert.dom(previousIcon).hasClass('jn-rtl-flip').hasAttribute('data-icon', 'inline-start')
    assert
      .dom(previousIcon.querySelector('path'))
      .hasAttribute('d', 'm15 18-6-6 6-6', 'chevron-left')
    assert.dom(pagination.previous.querySelector('span')).hasClass('jn-pagination-previous-text')

    assert
      .dom(pagination.next)
      .hasClass('jn-pagination-next')
      .hasAttribute('aria-label', 'Go to next page')
      .hasText('Next')
    const nextIcon = pagination.next.lastElementChild!
    assert
      .dom(nextIcon)
      .hasTagName('svg')
      .hasAttribute('data-icon', 'inline-end')
      .hasClass('jn-rtl-flip')
    assert.dom(pagination.next.querySelector('span')).hasClass('jn-pagination-next-text')

    const ellipsis = pagination.part('ellipsis')
    assert
      .dom(ellipsis)
      .hasTagName('span')
      .hasClass('jn-pagination-ellipsis')
      .hasAttribute('data-slot', 'pagination-ellipsis')
      .hasAttribute('aria-hidden', 'true')
    assert.dom(ellipsis.querySelector('[data-slot="visually-hidden"]')).hasText('More pages')

    assert.deepEqual(pagination.pages, ['1', '2'])
    assert.strictEqual(pagination.current, '2')
    assert.true(pagination.hasEllipsis)
    await a11yAudit()
  })

  test('its style sheet lays it out, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="width: 600px">
          <Pagination as |p|>
            <p.Content>
              <p.Item><p.Previous href="#1" /></p.Item>
              <p.Item><p.Link href="#1">1</p.Link></p.Item>
              <p.Item><p.Link href="#2" @isActive={{true}}>2</p.Link></p.Item>
              <p.Item><p.Ellipsis /></p.Item>
              <p.Item><p.Next href="#3" /></p.Item>
            </p.Content>
          </Pagination>
        </div>
      </template>,
    )
    const pagination = new PaginationHarness()
    const style = (element: Element) => getComputedStyle(element)

    const nav = style(pagination.element)
    assert.strictEqual(nav.display, 'flex')
    assert.strictEqual(nav.justifyContent, 'center', 'justify-center')
    assert.strictEqual(px(nav.width), 600, 'w-full')
    const content = pagination.part('content')
    const navBox = pagination.element.getBoundingClientRect()
    const contentBox = content.getBoundingClientRect()
    assert.ok(
      Math.abs(contentBox.left - navBox.left - (navBox.right - contentBox.right)) < 1,
      'the links are centred',
    )

    assert.strictEqual(style(content).display, 'flex')
    assert.strictEqual(style(content).alignItems, 'center')
    assert.strictEqual(style(content).columnGap, '2px', 'gap-0.5')
    assert.strictEqual(
      style(content).listStyleType,
      'none',
      'no markers, as preflight gives upstream',
    )

    const [one, two] = pagination.pageElements
    assert.strictEqual(style(one!).width, '32px', 'a page link is an icon-sized Button')
    assert.strictEqual(style(one!).height, '32px')
    assert.strictEqual(style(one!).borderTopColor, 'rgba(0, 0, 0, 0)', 'ghost: no border colour')
    assert.notStrictEqual(style(two!).borderTopColor, 'rgba(0, 0, 0, 0)', 'outline: a border')
    assert.strictEqual(style(one!).textDecorationLine, 'none')

    const previous = style(pagination.previous)
    assert.strictEqual(previous.height, '32px', 'size default')
    assert.strictEqual(previous.paddingLeft, '6px', 'ps-1.5!, over the inline-start icon’s ps-2')
    assert.strictEqual(previous.paddingRight, '10px', 'px-2.5')
    const next = style(pagination.next)
    assert.strictEqual(next.paddingRight, '6px', 'pe-1.5!')
    assert.strictEqual(next.paddingLeft, '10px')
    assert.strictEqual(style(pagination.previous.querySelector('svg')!).width, '16px', 'size-4')
    assert.strictEqual(
      style(pagination.previous.querySelector('span')!).display,
      'block',
      'sm:block: the text shows at this width',
    )

    const ellipsis = pagination.part('ellipsis')
    assert.strictEqual(style(ellipsis).width, '32px', 'size-8')
    assert.strictEqual(style(ellipsis).display, 'flex')
    assert.strictEqual(style(ellipsis.querySelector('svg')!).width, '16px')
    await a11yAudit()
  })

  test('the strings, the icons and the sizes are arguments', async function (assert) {
    await render(
      <template>
        <Pagination @label="Pages" as |p|>
          <p.Content>
            <p.Item>
              <p.Previous href="#1" @text="Back" @label="Back a page" @icon={{ArrowLeft}} />
            </p.Item>
            <p.Item><p.Link href="#1" @size="sm">1</p.Link></p.Item>
            <p.Item><p.Ellipsis @label="Skipped pages" /></p.Item>
            <p.Item>
              <p.Next href="#2" @size="lg" @text="Onward" @label="Onward to the next page" />
            </p.Item>
          </p.Content>
        </Pagination>
      </template>,
    )
    const pagination = new PaginationHarness()
    assert.strictEqual(pagination.label, 'Pages')
    assert.dom(pagination.previous).hasText('Back').hasAttribute('aria-label', 'Back a page')
    assert
      .dom(pagination.previous.querySelector('path'))
      .hasAttribute('d', 'm12 19-7-7 7-7', 'arrow-left')
    assert.dom(pagination.page('1')).hasAttribute('data-size', 'sm').hasClass('jn-button-size-sm')
    assert.dom(pagination.next).hasText('Onward').hasAttribute('data-size', 'lg')
    assert
      .dom(pagination.part('ellipsis').querySelector('[data-slot="visually-hidden"]'))
      .hasText('Skipped pages')
    assert.false(pagination.isCurrent('1'))
    assert.strictEqual(pagination.current, null)
    await a11yAudit()
  })

  test('keyboard: the links are in the tab order, the ellipsis is not', async function (assert) {
    await render(
      <template>
        <button type="button" id="before">Before</button>
        <Pagination as |p|>
          <p.Content>
            <p.Item><p.Previous href="#1" /></p.Item>
            <p.Item><p.Link href="#1">1</p.Link></p.Item>
            <p.Item><p.Ellipsis /></p.Item>
            <p.Item><p.Link href="#9" @isActive={{true}}>9</p.Link></p.Item>
            <p.Item><p.Next href="#9" /></p.Item>
          </p.Content>
        </Pagination>
      </template>,
    )
    const pagination = new PaginationHarness()
    document.querySelector<HTMLElement>('#before')!.focus()
    const visited: (string | null)[] = []
    for (let step = 0; step < 4; step++) {
      await tab()
      visited.push(
        document.activeElement!.getAttribute('aria-label') ??
          document.activeElement!.textContent!.trim(),
      )
    }
    assert.deepEqual(visited, ['Go to previous page', '1', '9', 'Go to next page'])
    assert.strictEqual(document.activeElement, pagination.next)
    await a11yAudit()
  })

  test('the link modifiers make a router link a page link, rendering what the components do', async function (assert) {
    ;(this.owner as unknown as { setupRouter(): void }).setupRouter()
    await render(
      <template>
        <Pagination as |p|>
          <p.Content>
            <p.Item>
              <LinkTo @route="index" data-case="modifier" {{p.link isActive=true}}>2</LinkTo>
            </p.Item>
            <p.Item><p.Link href="#2" data-case="component" @isActive={{true}}>2</p.Link></p.Item>
            <p.Item>
              <a href="#1" data-case="modifier" {{p.previous}}>Previous</a>
            </p.Item>
            <p.Item><p.Previous href="#1" data-case="component" /></p.Item>
            <p.Item><a href="#3" data-case="modifier" {{p.next size="sm"}}>Next</a></p.Item>
            <p.Item><p.Next href="#3" data-case="component" @size="sm" /></p.Item>
          </p.Content>
        </Pagination>
      </template>,
    )
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    const components = [...document.querySelectorAll('[data-case="component"]')]
    assert.strictEqual(modifiers.length, 3)
    modifiers.forEach((modified, index) => {
      assert.deepEqual(rendering(modified), rendering(components[index]!), `${index}: the same`)
    })
    const pagination = new PaginationHarness()
    assert.dom(pagination.pageElements[0]).hasAttribute('href', '/')
    assert.strictEqual(pagination.current, '2')

    // And both are what the functions say, for code of your own.
    assert.deepEqual(
      [...components[0]!.classList].sort(),
      paginationLinkClasses('link', { isActive: true }).split(' ').sort(),
    )
    for (const [name, value] of Object.entries(paginationLinkAttributes('next', { size: 'sm' }))) {
      assert.strictEqual(components[2]!.getAttribute(name), value ?? null, name)
    }
    await a11yAudit()
  })

  test('RTL: the links run right to left, the arrows point the other way, and the padding follows', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Pagination as |p|>
            <p.Content>
              <p.Item><p.Previous href="#1" @text="السابق" /></p.Item>
              <p.Item><p.Link href="#1">١</p.Link></p.Item>
              <p.Item><p.Next href="#2" @text="التالي" /></p.Item>
            </p.Content>
          </Pagination>
        </DirectionProvider>
      </template>,
    )
    const pagination = new PaginationHarness()
    const previous = pagination.previous.getBoundingClientRect()
    const next = pagination.next.getBoundingClientRect()
    assert.ok(previous.left > next.left, 'previous is on the right')
    assert.strictEqual(getComputedStyle(pagination.previous.querySelector('svg')!).rotate, '180deg')
    assert.strictEqual(getComputedStyle(pagination.next.querySelector('svg')!).rotate, '180deg')
    assert.strictEqual(
      getComputedStyle(pagination.previous).paddingRight,
      '6px',
      'ps-1.5!: on the right',
    )
    assert.strictEqual(getComputedStyle(pagination.next).paddingLeft, '6px', 'pe-1.5!: on the left')
    const icon = pagination.previous.querySelector('svg')!.getBoundingClientRect()
    assert.ok(
      icon.left > previous.left + previous.width / 2,
      'its arrow is at the inline start, the right',
    )
    await a11yAudit()
  })

  test('the harness follows links and says what is missing', async function (assert) {
    const clicked: string[] = []
    const record = (event: Event) => {
      event.preventDefault()
      clicked.push((event.currentTarget as HTMLElement).getAttribute('href')!)
    }
    await render(
      <template>
        <Pagination @name="results" as |p|>
          <p.Content>
            <p.Item><p.Previous href="#1" {{on "click" record}} /></p.Item>
            <p.Item><p.Link href="#1" {{on "click" record}}>1</p.Link></p.Item>
            <p.Item><p.Link href="#2" @isActive={{true}} {{on "click" record}}>2</p.Link></p.Item>
            <p.Item><p.Link href="#3" {{on "click" record}}>3</p.Link></p.Item>
            <p.Item><p.Next href="#3" {{on "click" record}} /></p.Item>
          </p.Content>
        </Pagination>
      </template>,
    )
    const pagination = new PaginationHarness('results')
    assert.deepEqual(pagination.pages, ['1', '2', '3'])
    assert.true(pagination.isCurrent('2'))
    assert.false(pagination.hasEllipsis)
    await pagination.goTo('3')
    await pagination.goToPrevious()
    await pagination.goToNext()
    assert.deepEqual(clicked, ['#3', '#1', '#3'])
    assert.throws(
      () => pagination.page('7'),
      /no page "7" in pagination "results" \(it has 1, 2, 3\)/,
    )
    await a11yAudit()
  })
})
