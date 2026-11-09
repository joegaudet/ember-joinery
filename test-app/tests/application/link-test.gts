import { module, test } from 'qunit'
import { setupApplicationTest } from 'test-app/tests/helpers'
import { click, currentURL, findAll, visit } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  dynamicSegments,
  isActiveLink,
  isExternalLink,
  link,
} from '@ember-joinery/primitives/link-helper'
import { getRouter, setupRouting } from '@ember-joinery/test-support'

/**
 * A link as a design system would write one on the helper: active state on `aria-current`
 * and `data-active`, the click routed, and a mark on external links.
 */
const NavLink: TOC<{
  Element: HTMLAnchorElement
  Args: { href: string; activeOnSubPaths?: boolean; includeActiveQueryParams?: boolean | string[] }
  Blocks: { default: [] }
}> = <template>
  {{#let
    (link
      @href activeOnSubPaths=@activeOnSubPaths includeActiveQueryParams=@includeActiveQueryParams
    )
    as |l|
  }}
    <a
      href={{@href}}
      aria-current={{if l.isActive "page"}}
      data-active={{if l.isActive "true"}}
      data-external={{if l.isExternal "true"}}
      {{on "click" l.handleClick}}
      ...attributes
    >{{yield}}</a>
  {{/let}}
</template>

function activeTexts(): string[] {
  return findAll('[data-active]').map(element => element.textContent!.trim())
}

module('Application | primitives | link', function (hooks) {
  setupApplicationTest(hooks)

  test('isActive follows the current route, and handleClick routes the click', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('foo')
      this.route('bar')
    })
    this.owner.register(
      'template:application',
      <template>
        <nav aria-label="Pages">
          <NavLink @href="/foo">Foo</NavLink>
          <NavLink @href="/bar">Bar</NavLink>
          <NavLink @href="/">Home</NavLink>
        </nav>
      </template>,
    )
    await visit('/')
    assert.deepEqual(activeTexts(), ['Home'])
    assert.dom('[aria-current="page"]').hasText('Home')

    await click('a[href="/foo"]')
    assert.strictEqual(currentURL(), '/foo', 'the click was a transition')
    assert.deepEqual(activeTexts(), ['Foo'])

    await click('a[href="/bar"]')
    assert.deepEqual(activeTexts(), ['Bar'])
    await a11yAudit()
  })

  test('activeOnSubPaths', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('foo', function () {
        this.route('a')
        this.route('b')
      })
    })
    this.owner.register(
      'template:application',
      <template>
        <NavLink @href="/foo/a">a</NavLink>
        <NavLink @href="/foo/b">b</NavLink>
        <NavLink @href="/foo">Foo</NavLink>
        <NavLink @href="/foo" @activeOnSubPaths={{true}} id="section">Foo section</NavLink>
      </template>,
    )
    await visit('/')
    assert.deepEqual(activeTexts(), [])

    await visit('/foo')
    assert.deepEqual(activeTexts(), ['Foo', 'Foo section'])
    await visit('/foo/a')
    assert.deepEqual(activeTexts(), ['a', 'Foo section'], 'the section is active below it')
    await visit('/foo/b')
    assert.deepEqual(activeTexts(), ['b', 'Foo section'])
    await a11yAudit()
  })

  test('dynamic segments', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('post', { path: '/posts/:id' })
    })
    this.owner.register(
      'template:application',
      <template>
        <NavLink @href="/posts/1">One</NavLink>
        <NavLink @href="/posts/2">Two</NavLink>
      </template>,
    )
    await visit('/posts/1')
    assert.deepEqual(activeTexts(), ['One'])
    await click('a[href="/posts/2"]')
    assert.deepEqual(activeTexts(), ['Two'])
    await a11yAudit()
  })

  test('with a rootURL', async function (assert) {
    setupRouting(
      this.owner,
      function () {
        this.route('foo')
      },
      { rootURL: '/some-root/' },
    )
    this.owner.register(
      'template:application',
      <template>
        <NavLink @href="/some-root/foo">Foo</NavLink>
        <NavLink @href="/some-root/">Home</NavLink>
        <NavLink @href="/elsewhere">Outside the app</NavLink>
      </template>,
    )
    await visit('/')
    assert.deepEqual(activeTexts(), ['Home'])
    await click('a[href="/some-root/foo"]')
    assert.strictEqual(currentURL(), '/foo')
    assert.deepEqual(activeTexts(), ['Foo'])
    await a11yAudit()
  })

  test('query params: all of them, or the ones named', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('foo')
    })
    this.owner.register(
      'template:application',
      <template>
        <NavLink @href="/foo?hello=2&there=3" @includeActiveQueryParams={{true}}>All 2 3</NavLink>
        <NavLink @href="/foo?hello=1&there=4" @includeActiveQueryParams={{true}}>All 1 4</NavLink>
        <NavLink @href="/foo?hello=2&there=9" @includeActiveQueryParams={{array "hello"}}>Hello 2</NavLink>
        <NavLink @href="/foo?hello=9">Path only</NavLink>
      </template>,
    )
    await visit('/foo?hello=2&there=3')
    assert.deepEqual(activeTexts(), ['All 2 3', 'Hello 2', 'Path only'])
    await visit('/foo?hello=1&there=4')
    assert.deepEqual(activeTexts(), ['All 1 4', 'Path only'])
    await visit('/foo?hello=2')
    assert.deepEqual(activeTexts(), ['Hello 2', 'Path only'], 'all of them must match')
    await a11yAudit()
  })

  test('external links are marked, and never active', async function (assert) {
    setupRouting(this.owner, function () {})
    this.owner.register(
      'template:application',
      <template>
        <NavLink @href="https://developer.mozilla.org">MDN</NavLink>
        <NavLink @href="/">Home</NavLink>
      </template>,
    )
    await visit('/')
    assert.dom('[data-external]').hasText('MDN')
    assert.deepEqual(activeTexts(), ['Home'])

    assert.true(isExternalLink('https://developer.mozilla.org/en-US/'))
    assert.false(isExternalLink(`${location.origin}/foo`), 'the same origin')
    assert.false(isExternalLink('/foo'))
    assert.false(isExternalLink('#top'))
    assert.false(isExternalLink('?tab=2'))
    assert.false(isExternalLink(''))
    await a11yAudit()
  })

  test('in JavaScript: isActiveLink and dynamicSegments', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('forum', { path: '/forum/:forum_id' }, function () {
        this.route('post', { path: '/post/:post_id' })
      })
    })
    this.owner.register('template:application', <template>{{outlet}}</template>)
    await visit('/forum/7/post/42?sort=new')
    const router = getRouter(this.owner)

    assert.true(isActiveLink(router, '/forum/7/post/42'), 'the path decides, query params aside')
    assert.false(isActiveLink(router, '/forum/7/post/43'))
    assert.false(isActiveLink(router, '/forum/7'), 'not a parent route')
    assert.true(isActiveLink(router, '/forum/7', false, true), 'unless sub-paths count')
    assert.true(isActiveLink(router, '/forum/7/post/42?sort=new', true))
    assert.false(isActiveLink(router, '/forum/7/post/42?sort=old', true), 'the params must match')
    assert.false(isActiveLink(router, 'https://example.com/forum/7/post/42'), 'never external')

    const info = router.recognize('/forum/7/post/42')
    assert.deepEqual(dynamicSegments(info), ['7', '42'], 'outermost route first')
    assert.deepEqual(dynamicSegments(null), [])
    await a11yAudit()
  })
})
