import { module, test } from 'qunit'
import { setupApplicationTest } from 'test-app/tests/helpers'
import { click, currentURL, triggerEvent, visit } from '@ember/test-helpers'
import EmberRouter from '@ember/routing/router'
import Route from '@ember/routing/route'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  getAnchor,
  properLinks,
  setupProperLinks,
  shouldHandle,
} from '@ember-joinery/primitives/proper-links'
import { getRouter, setupRouting, type RouteMap } from '@ember-joinery/test-support'

const Links = <template>
  <nav aria-label="Pages">
    <a href="/foo">Foo</a>
    <a href="/foo/bar">Foo bar</a>
    <a href="/bar">Bar</a>
    <a href="/bar" target="_blank" id="new-tab">Bar in a new tab</a>
    <a href="/bar" download id="download">Download bar</a>
    <a href="/legacy/page" id="legacy">A server page</a>
    <a href="#main" id="hash">Skip to the content</a>
    <a href="/foo"><span id="nested">Foo, from a span</span></a>
  </nav>
  <main id="main">Content</main>
</template>

const map: RouteMap = function () {
  this.route('foo', function () {
    this.route('bar')
  })
  this.route('bar')
}

/** Stops the click a test expects the router to leave alone, so the browser doesn't follow it. */
function stopDefault(event: Event) {
  event.preventDefault()
}

module('Application | primitives | proper-links', function (hooks) {
  setupApplicationTest(hooks)

  hooks.beforeEach(function () {
    this.owner.register('template:application', Links)
  })

  test('plain links to the app are transitions', async function (assert) {
    setupRouting(this.owner, map)
    setupProperLinks(this.owner)
    await visit('/')
    assert.strictEqual(currentURL(), '/')

    await click('a[href="/foo"]')
    assert.strictEqual(currentURL(), '/foo')
    await click('a[href="/foo/bar"]')
    assert.strictEqual(currentURL(), '/foo/bar', 'nested routes')
    await click('#nested')
    assert.strictEqual(currentURL(), '/foo', 'from an element inside the link')
    await a11yAudit()
  })

  test('links the browser should keep are left to it', async function (assert) {
    setupRouting(this.owner, map)
    setupProperLinks(this.owner, { ignore: ['/legacy'] })
    await visit('/foo')
    document.addEventListener('click', stopDefault)
    try {
      for (const selector of ['#new-tab', '#download', '#legacy', '#hash']) {
        await click(selector)
        assert.strictEqual(currentURL(), '/foo', `${selector} is the browser's`)
      }
      await triggerEvent('a[href="/bar"]', 'click', { metaKey: true, button: 0 })
      assert.strictEqual(currentURL(), '/foo', 'a Cmd-click opens a tab')
      await triggerEvent('a[href="/bar"]', 'click', { button: 1 })
      assert.strictEqual(currentURL(), '/foo', 'so does a middle click')
    } finally {
      document.removeEventListener('click', stopDefault)
    }
    await a11yAudit()
  })

  test('the router decorator does the same for the whole app', async function (assert) {
    @properLinks
    class Router extends EmberRouter {
      override location = 'none'
      override rootURL = '/'
    }
    Router.map(map)
    const registry = this.owner as typeof this.owner & { unregister(name: string): void }
    registry.unregister('router:main')
    this.owner.register('router:main', Router)

    await visit('/')
    await click('a[href="/bar"]')
    assert.strictEqual(currentURL(), '/bar')
    await a11yAudit()
  })

  test('with options, and with a rootURL', async function (assert) {
    const Decorated = properLinks({ ignore: [/^\/app\/legacy/] })(
      class extends EmberRouter {
        override location = 'none'
        override rootURL = '/app/'
      },
    )
    Decorated.map(map)
    const registry = this.owner as typeof this.owner & { unregister(name: string): void }
    registry.unregister('router:main')
    this.owner.register('router:main', Decorated)
    this.owner.register(
      'template:application',
      <template>
        <a href="/app/foo">Foo</a>
        <a href="/app/legacy/page" id="legacy">Legacy</a>
        <a href="/elsewhere" id="outside">Outside the app</a>
      </template>,
    )

    await visit('/')
    await click('a[href="/app/foo"]')
    assert.strictEqual(currentURL(), '/foo', 'the app path, without the rootURL')
    document.addEventListener('click', stopDefault)
    try {
      await click('#legacy')
      assert.strictEqual(currentURL(), '/foo', 'ignored')
      await click('#outside')
      assert.strictEqual(currentURL(), '/foo', 'outside the rootURL')
    } finally {
      document.removeEventListener('click', stopDefault)
    }
    await a11yAudit()
  })

  test('query params and unknown paths', async function (assert) {
    setupRouting(this.owner, map)
    setupProperLinks(this.owner)
    this.owner.register(
      'route:foo',
      class extends Route {
        queryParams = { greeting: { refreshModel: true } }
      },
    )
    this.owner.register(
      'template:application',
      <template>
        <a href="/foo?greeting=hello%20there" id="hello">Hello</a>
        <a href="/nowhere" id="nowhere">Nowhere</a>
      </template>,
    )
    await visit('/')
    await click('#hello')
    assert.strictEqual(currentURL(), '/foo?greeting=hello%20there')

    document.addEventListener('click', stopDefault)
    try {
      await click('#nowhere')
      assert.strictEqual(currentURL(), '/foo?greeting=hello%20there', 'no route: the browser')
    } finally {
      document.removeEventListener('click', stopDefault)
    }
    assert.ok(getRouter(this.owner), 'the router service')
    await a11yAudit()
  })

  test('shouldHandle: links to the current page', async function (assert) {
    const check = (expected: boolean, from: string, to: string) => {
      const here = new URL(from, 'https://example.com')
      const anchor = document.createElement('a')
      anchor.href = new URL(to, here).href
      assert.strictEqual(
        shouldHandle(here.href, anchor, new MouseEvent('click')),
        expected,
        `${from} → ${to}`,
      )
    }
    check(false, '/foo', '/foo#bar')
    check(false, '/foo', '#bar')
    check(false, '/foo#bar', '/foo#other')
    check(true, '/foo', '/abc#xyz')
    check(true, '/foo#bar', '/abc#xyz')
    check(true, '/foo#bar', '/foo')
    check(false, '/foo', 'https://elsewhere.example/foo')
    assert.false(shouldHandle('https://example.com/', undefined, new MouseEvent('click')))
    await a11yAudit()
  })

  test('getAnchor finds the link around what was clicked', async function (assert) {
    const anchor = document.createElement('a')
    anchor.href = '/foo'
    const icon = document.createElement('span')
    anchor.append(icon)
    document.body.append(anchor)
    let found: HTMLAnchorElement | undefined
    const listener = (event: Event) => {
      found = getAnchor(event)
      event.preventDefault() // a synthetic click on a link still follows it
    }
    document.body.addEventListener('click', listener)
    icon.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
    document.body.removeEventListener('click', listener)
    anchor.remove()
    assert.strictEqual(found, anchor)
    await a11yAudit()
  })
})
