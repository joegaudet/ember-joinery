import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { LinkTo } from '@ember/routing'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Dot, Slash } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Breadcrumb, Icon } from '@ember-joinery/ember'
import { BreadcrumbHarness, IconHarness, tab } from '@ember-joinery/test-support'

/** The colour a token resolves to here, as the browser computes it. */
function token(name: string): string {
  const probe = document.createElement('span')
  probe.style.color = `var(${name})`
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe).color
  probe.remove()
  return value
}

module('Integration | components | breadcrumb', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream anatomy: a named nav, a list of crumbs, and their parts', async function (assert) {
    await render(
      <template>
        <Breadcrumb class="mine" as |b|>
          <b.List>
            <b.Item><b.Link href="#home">Home</b.Link></b.Item>
            <b.Separator />
            <b.Item><b.Ellipsis /></b.Item>
            <b.Separator />
            <b.Item><b.Page>Breadcrumb</b.Page></b.Item>
          </b.List>
        </Breadcrumb>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness()
    assert
      .dom(breadcrumb.element)
      .hasTagName('nav')
      .hasClass('jn-breadcrumb')
      .hasClass('mine')
      .hasAttribute('data-slot', 'breadcrumb')
      .hasAttribute('aria-label', 'breadcrumb', "upstream's default")
    assert
      .dom(breadcrumb.part('list'))
      .hasTagName('ol')
      .hasClass('jn-breadcrumb-list')
      .hasAttribute('data-slot', 'breadcrumb-list')
    assert
      .dom(breadcrumb.part('item'))
      .hasTagName('li')
      .hasClass('jn-breadcrumb-item')
      .hasAttribute('data-slot', 'breadcrumb-item')
    assert
      .dom(breadcrumb.part('link'))
      .hasTagName('a')
      .hasClass('jn-breadcrumb-link')
      .hasAttribute('data-slot', 'breadcrumb-link')
      .hasAttribute('href', '#home')
    assert
      .dom(breadcrumb.part('page'))
      .hasTagName('span')
      .hasClass('jn-breadcrumb-page')
      .hasAttribute('data-slot', 'breadcrumb-page')
      .hasAttribute('role', 'link')
      .hasAttribute('aria-disabled', 'true')
      .hasAttribute('aria-current', 'page')

    const [separator] = breadcrumb.separators
    assert
      .dom(separator)
      .hasTagName('li')
      .hasClass('jn-breadcrumb-separator')
      .hasAttribute('data-slot', 'breadcrumb-separator')
      .hasAttribute('role', 'presentation')
      .hasAttribute('aria-hidden', 'true')
    const chevron = separator!.querySelector('svg')!
    assert.dom(chevron).hasClass('lucide').hasClass('jn-rtl-flip')
    assert
      .dom(chevron.querySelector('path'))
      .hasAttribute('d', 'm9 18 6-6-6-6', "lucide's chevron-right")

    const ellipsis = breadcrumb.part('ellipsis')
    assert
      .dom(ellipsis)
      .hasTagName('span')
      .hasClass('jn-breadcrumb-ellipsis')
      .hasAttribute('data-slot', 'breadcrumb-ellipsis')
      .hasAttribute('role', 'presentation')
      .hasAttribute('aria-hidden', 'true')
    assert.dom(ellipsis.querySelector('svg')).exists("lucide's ellipsis")
    assert.dom(ellipsis.querySelector('[data-slot="visually-hidden"]')).hasText('More')

    assert.deepEqual(breadcrumb.items, ['Home', '', 'Breadcrumb'])
    assert.strictEqual(breadcrumb.current, 'Breadcrumb')
    assert.true(breadcrumb.isCollapsed)
    await a11yAudit()
  })

  test('its style sheet lays it out, without Tailwind', async function (assert) {
    await render(
      <template>
        <Breadcrumb as |b|>
          <b.List>
            <b.Item><b.Link href="#home">Home</b.Link></b.Item>
            <b.Separator />
            <b.Item><b.Ellipsis /></b.Item>
            <b.Separator />
            <b.Item><b.Page>Breadcrumb</b.Page></b.Item>
          </b.List>
        </Breadcrumb>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness()
    const style = (element: Element) => getComputedStyle(element)
    const list = style(breadcrumb.part('list'))
    assert.strictEqual(list.display, 'flex')
    assert.strictEqual(list.flexWrap, 'wrap')
    assert.strictEqual(list.alignItems, 'center')
    assert.strictEqual(list.columnGap, '6px', 'gap-1.5')
    assert.strictEqual(list.fontSize, '14px', 'text-sm')
    assert.strictEqual(list.color, token('--muted-foreground'), 'text-muted-foreground')
    assert.strictEqual(list.listStyleType, 'none', 'no markers, as preflight gives upstream')
    assert.strictEqual(list.paddingLeft, '0px')

    const item = style(breadcrumb.part('item'))
    assert.strictEqual(item.display, 'flex', 'inline-flex, which a flex row makes flex')
    assert.strictEqual(item.alignItems, 'center')
    assert.strictEqual(item.columnGap, '4px', 'gap-1')

    const link = style(breadcrumb.part('link'))
    assert.ok(link.transitionProperty.includes('color'), 'transition-colors')
    assert.strictEqual(link.textDecorationLine, 'none', "a link takes no underline, as preflight's")

    const page = style(breadcrumb.part('page'))
    assert.strictEqual(page.color, token('--foreground'), 'text-foreground')
    assert.strictEqual(page.fontWeight, '400', 'font-normal')

    const chevron = breadcrumb.separators[0]!.querySelector('svg')!
    assert.strictEqual(style(chevron).width, '14px', '[&>svg]:size-3.5')
    assert.strictEqual(style(chevron).height, '14px')

    const ellipsis = breadcrumb.part('ellipsis')
    assert.strictEqual(style(ellipsis).width, '20px', 'size-5')
    assert.strictEqual(style(ellipsis).height, '20px')
    assert.strictEqual(style(ellipsis).display, 'flex')
    assert.strictEqual(style(ellipsis.querySelector('svg')!).width, '16px', '[&>svg]:size-4')
    await a11yAudit()
  })

  test('a separator shows its block or @icon, and the strings are arguments', async function (assert) {
    await render(
      <template>
        <Breadcrumb @label="You are here" as |b|>
          <b.List>
            <b.Item><b.Link href="#home">Home</b.Link></b.Item>
            <b.Separator data-case="block"><Icon @icon={{Dot}} @name="dot" /></b.Separator>
            <b.Item><b.Ellipsis @label="Hidden crumbs" /></b.Item>
            <b.Separator data-case="icon" @icon={{Slash}} />
            <b.Item><b.Link href="#docs">Docs</b.Link></b.Item>
            <b.Separator data-case="text">/</b.Separator>
            <b.Item><b.Page>Breadcrumb</b.Page></b.Item>
          </b.List>
        </Breadcrumb>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness()
    assert.strictEqual(breadcrumb.label, 'You are here')
    const [block, icon, text] = breadcrumb.separators
    assert.true(
      breadcrumb.find(IconHarness, 'dot').isDecorative,
      'its own icon, in place of the chevron',
    )
    assert.strictEqual(block!.querySelectorAll('svg').length, 1, 'only its own icon')
    assert.dom(icon!.querySelector('svg')).hasClass('jn-rtl-flip')
    assert.dom(icon!.querySelector('path')).hasAttribute('d', 'M22 2 2 22', "lucide's slash")
    assert.dom(text).hasText('/')
    assert.dom(text!.querySelector('svg')).doesNotExist()
    assert.strictEqual(
      getComputedStyle(block!.querySelector('svg')!).width,
      '14px',
      'sized as the chevron',
    )
    assert
      .dom(breadcrumb.part('ellipsis').querySelector('[data-slot="visually-hidden"]'))
      .hasText('Hidden crumbs')
    await a11yAudit()
  })

  test('keyboard: the links are in the tab order; the current page and separators are not', async function (assert) {
    await render(
      <template>
        <button type="button" id="before">Before</button>
        <Breadcrumb as |b|>
          <b.List>
            <b.Item><b.Link href="#home">Home</b.Link></b.Item>
            <b.Separator />
            <b.Item><b.Link href="#components">Components</b.Link></b.Item>
            <b.Separator />
            <b.Item><b.Page>Breadcrumb</b.Page></b.Item>
          </b.List>
        </Breadcrumb>
        <button type="button" id="after">After</button>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness()
    document.querySelector<HTMLElement>('#before')!.focus()
    await tab()
    assert.strictEqual(document.activeElement, breadcrumb.link('Home'))
    await tab()
    assert.strictEqual(document.activeElement, breadcrumb.link('Components'))
    await tab()
    assert.strictEqual(document.activeElement!.id, 'after', 'past the page, which goes nowhere')
    await tab({ shift: true })
    assert.strictEqual(document.activeElement, breadcrumb.link('Components'))
    await a11yAudit()
  })

  test('a link takes @as, and the link modifier makes a router link a crumb', async function (assert) {
    ;(this.owner as unknown as { setupRouter(): void }).setupRouter()
    await render(
      <template>
        <Breadcrumb as |b|>
          <b.List>
            <b.Item>
              <LinkTo @route="index" class="mine" {{b.link}}>Home</LinkTo>
            </b.Item>
            <b.Separator />
            <b.Item><b.Link @as="button" type="button">Components</b.Link></b.Item>
            <b.Separator />
            <b.Item><span {{b.page}}>Breadcrumb</span></b.Item>
          </b.List>
        </Breadcrumb>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness()
    const home = breadcrumb.link('Home')
    assert
      .dom(home)
      .hasAttribute('href', '/')
      .hasClass('mine')
      .hasClass('jn-breadcrumb-link')
      .hasAttribute('data-slot', 'breadcrumb-link')
    assert.dom(breadcrumb.parts('link')[1]).hasTagName('button').hasClass('jn-breadcrumb-link')
    const page = breadcrumb.part('page')
    assert.dom(page).hasAttribute('aria-current', 'page').hasAttribute('role', 'link')
    assert.strictEqual(breadcrumb.current, 'Breadcrumb')
    assert.strictEqual(getComputedStyle(page).color, token('--foreground'), 'styled as the page')
    await a11yAudit()
  })

  test('RTL: the crumbs run right to left, and the chevron points left', async function (assert) {
    await render(
      <template>
        <Breadcrumb @name="ltr" @label="Path" as |b|>
          <b.List>
            <b.Item><b.Link href="#home">Home</b.Link></b.Item>
            <b.Separator />
            <b.Item><b.Page>Breadcrumb</b.Page></b.Item>
          </b.List>
        </Breadcrumb>
        <DirectionProvider @dir="rtl">
          <Breadcrumb @name="rtl" @label="المسار" as |b|>
            <b.List>
              <b.Item><b.Link href="#home">الرئيسية</b.Link></b.Item>
              <b.Separator />
              <b.Item><b.Page>مسار التنقل</b.Page></b.Item>
            </b.List>
          </Breadcrumb>
        </DirectionProvider>
      </template>,
    )
    const ltr = new BreadcrumbHarness('ltr')
    const rtl = new BreadcrumbHarness('rtl')
    const [ltrFirst, ltrLast] = ltr.itemElements.map(item => item.getBoundingClientRect())
    const [rtlFirst, rtlLast] = rtl.itemElements.map(item => item.getBoundingClientRect())
    assert.ok(ltrFirst!.left < ltrLast!.left, 'left to right, the first crumb is on the left')
    assert.ok(rtlFirst!.left > rtlLast!.left, 'right to left, it is on the right')

    const rotation = (harness: BreadcrumbHarness) =>
      getComputedStyle(harness.separators[0]!.querySelector('svg')!).rotate
    assert.strictEqual(rotation(ltr), 'none')
    assert.strictEqual(rotation(rtl), '180deg', 'jn-rtl-flip: rtl:rotate-180')
    await a11yAudit()
  })

  test('the harness reads the crumbs, follows a link and says what is missing', async function (assert) {
    let followed = ''
    const follow = (event: Event) => {
      event.preventDefault()
      followed = (event.currentTarget as HTMLAnchorElement).textContent!.trim()
    }
    await render(
      <template>
        <Breadcrumb @name="path" as |b|>
          <b.List>
            <b.Item><b.Link href="#home" {{on "click" follow}}>Home</b.Link></b.Item>
            <b.Separator />
            <b.Item><b.Link href="#components" {{on "click" follow}}>Components</b.Link></b.Item>
            <b.Separator />
            <b.Item><b.Page>Breadcrumb</b.Page></b.Item>
          </b.List>
        </Breadcrumb>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness('path')
    assert.deepEqual(breadcrumb.items, ['Home', 'Components', 'Breadcrumb'])
    assert.deepEqual(breadcrumb.links, ['Home', 'Components'])
    assert.strictEqual(breadcrumb.separators.length, 2)
    assert.false(breadcrumb.isCollapsed)
    await breadcrumb.clickLink('Components')
    assert.strictEqual(followed, 'Components')
    assert.throws(() => breadcrumb.link('Docs'), /no link "Docs" in breadcrumb "path"/)
    await a11yAudit()
  })
})
