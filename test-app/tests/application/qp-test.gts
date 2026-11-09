import { module, test } from 'qunit'
import { setupApplicationTest } from 'test-app/tests/helpers'
import { currentURL, visit } from '@ember/test-helpers'
import Controller from '@ember/controller'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { castToBoolean, qp, withQP } from '@ember-joinery/primitives/qp'
import { setupProperLinks } from '@ember-joinery/primitives/proper-links'
import { getRouter, setupRouting } from '@ember-joinery/test-support'
import { LinksHarness } from 'test-app/tests/fixtures/primitives/links'
import { ReadoutHarness } from 'test-app/tests/fixtures/primitives/readout'

/** Where a link goes, as a URL. */
const urlOf = (link: HTMLAnchorElement) => new URL(link.getAttribute('href')!)

module('Application | primitives | qp', function (hooks) {
  setupApplicationTest(hooks)

  hooks.beforeEach(function () {
    setupRouting(this.owner, function () {
      this.route('shop')
    })
  })

  test('qp reads the current query param, and follows the URL', async function (assert) {
    this.owner.register(
      'template:application',
      <template>
        <output data-test-jn="readout">{{qp "color"}}</output>
      </template>,
    )
    this.owner.register(
      'controller:application',
      class extends Controller {
        queryParams = ['color']
      },
    )

    const color = new ReadoutHarness()
    await visit('/')
    assert.strictEqual(color.text, '')
    await visit('/?color=red')
    assert.strictEqual(color.text, 'red')
    await visit('/?color=blue')
    assert.strictEqual(color.text, 'blue')
    await visit('/')
    assert.strictEqual(color.text, '', 'gone with the param')
    await a11yAudit()
  })

  test('qp sees query params no controller declares', async function (assert) {
    this.owner.register(
      'template:application',
      <template>
        <output data-test-jn="readout">{{qp "color"}}</output>
      </template>,
    )
    await visit('/shop?color=green')
    assert.strictEqual(new ReadoutHarness().text, 'green')
    await a11yAudit()
  })

  test('withQP sets (or removes) a param on the current URL', async function (assert) {
    this.owner.register(
      'template:application',
      <template>
        <nav aria-label="Filters" data-test-jn="links">
          <a href={{withQP "color" "red"}} data-test-jn-part="link" data-test-jn-value="set">Red</a>
          <a href={{withQP "size" 2}} data-test-jn-part="link" data-test-jn-value="replace">
            Size 2
          </a>
          <a href={{withQP "size" null}} data-test-jn-part="link" data-test-jn-value="remove">
            Any size
          </a>
        </nav>
      </template>,
    )
    await visit('/shop?size=1')
    const links = new LinksHarness()
    assert.strictEqual(urlOf(links.link('set')).pathname, '/shop')
    assert.strictEqual(urlOf(links.link('set')).search, '?size=1&color=red', 'added to the others')
    assert.strictEqual(urlOf(links.link('replace')).search, '?size=2', 'replaced')
    assert.strictEqual(urlOf(links.link('remove')).search, '', 'removed')
    await a11yAudit()
  })

  test("withQP's links are the app's, under its rootURL, and route with properLinks", async function (assert) {
    setupRouting(this.owner, () => {}, { rootURL: '/store/' })
    setupProperLinks(this.owner)
    // A transition keeps a query param only where a controller declares it.
    this.owner.register(
      'controller:application',
      class extends Controller {
        queryParams = ['view']
      },
    )
    this.owner.register(
      'template:application',
      <template>
        <nav aria-label="Views" data-test-jn="links">
          <a href={{withQP "view" "grid"}} data-test-jn-part="link" data-test-jn-value="grid">
            Grid
          </a>
        </nav>
        <output data-test-jn="readout">{{qp "view"}}</output>
      </template>,
    )
    await visit('/')
    const links = new LinksHarness()
    assert.strictEqual(urlOf(links.link('grid')).pathname, '/store/')
    await links.follow('grid')
    assert.strictEqual(currentURL(), '/?view=grid', 'a transition, not a page load')
    assert.strictEqual(new ReadoutHarness().text, 'grid')
    assert.strictEqual(getRouter(this.owner).rootURL, '/store/')
    await a11yAudit()
  })

  test('castToBoolean', async function (assert) {
    for (const value of [
      undefined,
      null,
      '',
      '0',
      'false',
      'f',
      'off',
      'no',
      'null',
      'undefined',
    ]) {
      assert.false(castToBoolean(value), `${String(value)} is false`)
    }
    assert.false(castToBoolean('FALSE'), 'in any case')
    for (const value of ['1', 'true', 'yes', 'on', 'anything']) {
      assert.true(castToBoolean(value), `${value} is true`)
    }
    this.owner.register(
      'template:application',
      <template>
        <output data-test-jn="readout">
          {{if (castToBoolean (qp "debug")) "debugging" "not debugging"}}
        </output>
      </template>,
    )
    const debug = new ReadoutHarness()
    await visit('/?debug=1')
    assert.strictEqual(debug.text, 'debugging')
    await visit('/?debug=0')
    assert.strictEqual(debug.text, 'not debugging')
    await a11yAudit()
  })
})
