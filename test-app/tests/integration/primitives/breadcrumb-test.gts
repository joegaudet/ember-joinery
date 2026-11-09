import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  Breadcrumb,
  BreadcrumbSeparator,
  breadcrumbSeparatorAria,
} from '@ember-joinery/primitives/breadcrumb'
import { BreadcrumbHarness } from '@ember-joinery/test-support'

module('Integration | primitives | breadcrumb', function (hooks) {
  setupRenderingTest(hooks)

  test('it is a named nav around an ordered list, as ember-primitives', async function (assert) {
    await render(
      <template>
        <Breadcrumb class="mine" as |b|>
          <li><a href="#home">Home</a></li>
          <b.Separator>/</b.Separator>
          <li><a href="#docs">Docs</a></li>
          <b.Separator>/</b.Separator>
          <li aria-current="page">Breadcrumb</li>
        </Breadcrumb>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness()
    assert
      .dom(breadcrumb.element)
      .hasTagName('nav')
      .hasClass('mine')
      .hasAttribute('aria-label', 'Breadcrumb', "ember-primitives' default")
      .doesNotHaveAttribute('data-slot', 'no styles, so no slot')
    assert.dom('nav > ol').exists({ count: 1 })
    assert.dom('nav > ol > li').exists({ count: 5 })
    assert.strictEqual(breadcrumb.label, 'Breadcrumb')
    assert.deepEqual(
      breadcrumb.items,
      ['Home', 'Docs', 'Breadcrumb'],
      'the separators are left out',
    )
    assert.deepEqual(breadcrumb.links, ['Home', 'Docs'])
    assert.strictEqual(breadcrumb.current, 'Breadcrumb')
    await a11yAudit()
  })

  test('a separator is a list item assistive technology skips, showing its block', async function (assert) {
    await render(
      <template>
        <Breadcrumb @label="You are here" as |b|>
          <li><a href="#home">Home</a></li>
          <b.Separator class="slash">/</b.Separator>
          <li aria-current="page">Docs</li>
        </Breadcrumb>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness()
    assert.strictEqual(breadcrumb.label, 'You are here', '@label names it')
    const [separator] = breadcrumb.separators
    assert
      .dom(separator)
      .hasTagName('li')
      .hasClass('slash')
      .hasText('/')
      .hasAttribute('role', 'presentation')
      .hasAttribute('aria-hidden', 'true')
    assert.strictEqual(breadcrumb.separators.length, 1)
    await a11yAudit()
  })

  test('the separator stands alone, and its ARIA is a function, for an element of your own', async function (assert) {
    await render(
      <template>
        <nav aria-label="Path" data-test-jn="breadcrumb">
          <ol>
            <li><a href="#home">Home</a></li>
            <BreadcrumbSeparator @as="li">›</BreadcrumbSeparator>
            <li aria-current="page">Docs</li>
          </ol>
        </nav>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness()
    assert.dom(breadcrumb.separators[0]).hasAttribute('aria-hidden', 'true')
    assert.deepEqual(breadcrumb.items, ['Home', 'Docs'])
    assert.deepEqual(breadcrumbSeparatorAria(), { role: 'presentation', 'aria-hidden': 'true' })
    await a11yAudit()
  })

  test('the harness follows a link, and finds the current page', async function (assert) {
    let followed = ''
    const follow = (event: Event) => {
      event.preventDefault()
      followed = (event.currentTarget as HTMLAnchorElement).textContent!.trim()
    }
    await render(
      <template>
        <Breadcrumb @name="path" as |b|>
          <li><a href="#home" {{on "click" follow}}>Home</a></li>
          <b.Separator>/</b.Separator>
          <li><a href="#docs" {{on "click" follow}}>Docs</a></li>
          <b.Separator>/</b.Separator>
          <li><span aria-current="page">Breadcrumb</span></li>
        </Breadcrumb>
      </template>,
    )
    const breadcrumb = new BreadcrumbHarness('path')
    await breadcrumb.clickLink('Docs')
    assert.strictEqual(followed, 'Docs')
    assert.dom(breadcrumb.link('Home')).hasAttribute('href', '#home')
    assert.strictEqual(breadcrumb.current, 'Breadcrumb')
    assert.false(breadcrumb.isCollapsed)
    assert.throws(() => breadcrumb.link('Nowhere'), /no link "Nowhere" in breadcrumb "path"/)
    await a11yAudit()
  })
})
