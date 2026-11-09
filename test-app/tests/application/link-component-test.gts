import { module, test } from 'qunit'
import { setupApplicationTest } from 'test-app/tests/helpers'
import { currentURL, visit } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Link } from '@ember-joinery/primitives/link'
import { LinkHarness, setupRouting } from '@ember-joinery/test-support'

/** The names of the links that are current now (`aria-current`), in document order. */
function current(): string[] {
  return LinkHarness.findAll()
    .filter(link => link.isCurrent)
    .map(link => link.element.getAttribute('data-test-jn-name')!)
}

module('Application | primitives | Link', function (hooks) {
  setupApplicationTest(hooks)

  test('the link to the current route is active, and a click is a transition', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('foo')
      this.route('bar')
    })
    this.owner.register(
      'template:application',
      <template>
        <nav aria-label="Pages">
          <Link @name="foo" @href="/foo">Foo</Link>
          <Link @name="bar" @href="/bar">Bar</Link>
          <Link @name="home" @href="/">Home</Link>
        </nav>
      </template>,
    )
    await visit('/')
    const home = new LinkHarness('home')
    assert.deepEqual(current(), ['home'])
    assert.strictEqual(home.current, 'page')
    assert.dom(home.element).hasAttribute('data-active', 'true')
    assert.dom(new LinkHarness('foo').element).doesNotHaveAttribute('data-active')

    await new LinkHarness('foo').follow()
    assert.strictEqual(currentURL(), '/foo', 'routed, without properLinks')
    assert.deepEqual(current(), ['foo'])
    await new LinkHarness('bar').follow()
    assert.deepEqual(current(), ['bar'])
    await home.follow()
    assert.deepEqual(current(), ['home'])
    await a11yAudit()
  })

  test('@activeOnSubPaths: active below its route too, with aria-current="true"', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('foo', function () {
        this.route('a')
        this.route('b')
      })
    })
    this.owner.register(
      'template:application',
      <template>
        <nav aria-label="Pages">
          <Link @name="a" @href="/foo/a">a</Link>
          <Link @name="b" @href="/foo/b">b</Link>
          <Link @name="foo" @href="/foo">Foo</Link>
          <Link @name="section" @href="/foo" @activeOnSubPaths={{true}}>Foo section</Link>
        </nav>
      </template>,
    )
    await visit('/')
    assert.deepEqual(current(), [])

    await visit('/foo')
    assert.deepEqual(current(), ['foo', 'section'])
    await new LinkHarness('a').follow()
    assert.deepEqual(current(), ['a', 'section'])
    assert.strictEqual(new LinkHarness('a').current, 'page', 'the page itself')
    assert.strictEqual(new LinkHarness('section').current, 'true', 'the section it is in')
    await new LinkHarness('b').follow()
    assert.deepEqual(current(), ['b', 'section'])
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
        <nav aria-label="Pages">
          <Link @name="foo" @href="/some-root/foo">Foo</Link>
          <Link @name="home" @href="/some-root/">Home</Link>
        </nav>
      </template>,
    )
    await visit('/')
    assert.deepEqual(current(), ['home'])
    await new LinkHarness('foo').follow()
    assert.deepEqual(current(), ['foo'])
    await a11yAudit()
  })

  test('@includeActiveQueryParams: all of them, or the ones named', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('foo')
    })
    this.owner.register(
      'template:application',
      <template>
        <nav aria-label="Pages">
          <Link
            @name="one"
            @href="/foo?hello=2&there=3"
            @includeActiveQueryParams={{true}}
          >One</Link>
          <Link
            @name="two"
            @href="/foo?hello=1&there=4"
            @includeActiveQueryParams={{true}}
          >Two</Link>
          <Link
            @name="hello-2"
            @href="/foo?hello=2&there=9"
            @includeActiveQueryParams={{array "hello"}}
          >Hello 2</Link>
          <Link @name="plain" @href="/foo">Plain</Link>
        </nav>
      </template>,
    )
    await visit('/')
    assert.deepEqual(current(), [])

    await new LinkHarness('one').follow()
    assert.deepEqual(current(), ['one', 'hello-2', 'plain'], 'the path alone, for plain')
    await new LinkHarness('two').follow()
    assert.deepEqual(current(), ['two', 'plain'])
    await a11yAudit()
  })

  test('dynamic segments', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('post', { path: '/posts/:id' })
    })
    this.owner.register(
      'template:application',
      <template>
        <nav aria-label="Posts">
          <Link @name="one" @href="/posts/1">One</Link>
          <Link @name="two" @href="/posts/2">Two</Link>
        </nav>
      </template>,
    )
    await visit('/posts/1')
    assert.deepEqual(current(), ['one'])
    await new LinkHarness('two').follow()
    assert.deepEqual(current(), ['two'])
    await a11yAudit()
  })

  test('an @href on another origin is an ExternalLink, never active', async function (assert) {
    setupRouting(this.owner, function () {})
    this.owner.register(
      'template:application',
      <template>
        <nav aria-label="Links">
          <Link @name="mdn" @href="https://developer.mozilla.org" class="ref" as |a|>
            MDN
            {{#if a.isExternal}}<span aria-hidden="true">↗</span>{{/if}}
            {{if a.isActive "active"}}
          </Link>
          <Link @name="home" @href="/" as |a|>
            Home
            {{#if a.isExternal}}<span aria-hidden="true">↗</span>{{/if}}
            {{if a.isActive "(here)"}}
          </Link>
        </nav>
      </template>,
    )
    await visit('/')
    const mdn = new LinkHarness('mdn')
    assert.dom(mdn.element).hasAttribute('data-test-jn', 'link').hasClass('ref')
    assert.true(mdn.opensInNewTab && mdn.isIsolated, 'opens a new tab, isolated')
    assert.strictEqual(mdn.text, 'MDN ↗', 'yields isExternal, and never isActive')
    assert.false(mdn.isCurrent)

    const home = new LinkHarness('home')
    assert.false(home.opensInNewTab)
    assert.strictEqual(home.text, 'Home (here)', 'yields isActive')
    assert.strictEqual(home.href, '/')
    await a11yAudit()
  })
})
