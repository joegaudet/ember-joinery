import { module, test } from 'qunit'
import { setupApplicationTest } from 'test-app/tests/helpers'
import { click, currentURL, find, visit } from '@ember/test-helpers'
import Controller from '@ember/controller'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { castToBoolean, qp, withQP } from '@ember-joinery/primitives/qp'
import { setupProperLinks } from '@ember-joinery/primitives/proper-links'
import { getRouter, setupRouting } from '@ember-joinery/test-support'

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
        <output>{{qp "color"}}</output>
      </template>,
    )
    this.owner.register(
      'controller:application',
      class extends Controller {
        queryParams = ['color']
      },
    )

    await visit('/')
    assert.dom('output').hasText('')
    await visit('/?color=red')
    assert.dom('output').hasText('red')
    await visit('/?color=blue')
    assert.dom('output').hasText('blue')
    await visit('/')
    assert.dom('output').hasText('', 'gone with the param')
    await a11yAudit()
  })

  test('qp sees query params no controller declares', async function (assert) {
    this.owner.register(
      'template:application',
      <template>
        <output>{{qp "color"}}</output>
      </template>,
    )
    await visit('/shop?color=green')
    assert.dom('output').hasText('green')
    await a11yAudit()
  })

  test('withQP sets (or removes) a param on the current URL', async function (assert) {
    this.owner.register(
      'template:application',
      <template>
        <a id="set" href={{withQP "color" "red"}}>Red</a>
        <a id="replace" href={{withQP "size" 2}}>Size 2</a>
        <a id="remove" href={{withQP "size" null}}>Any size</a>
      </template>,
    )
    await visit('/shop?size=1')
    const href = (selector: string) => new URL(find(selector)!.getAttribute('href')!)
    assert.strictEqual(href('#set').pathname, '/shop')
    assert.strictEqual(href('#set').search, '?size=1&color=red', 'added to the others')
    assert.strictEqual(href('#replace').search, '?size=2', 'replaced')
    assert.strictEqual(href('#remove').search, '', 'removed')
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
        <a href={{withQP "view" "grid"}}>Grid</a>
        <output>{{qp "view"}}</output>
      </template>,
    )
    await visit('/')
    assert.strictEqual(new URL(find('a')!.getAttribute('href')!).pathname, '/store/')
    await click('a')
    assert.strictEqual(currentURL(), '/?view=grid', 'a transition, not a page load')
    assert.dom('output').hasText('grid')
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
        <output>{{if (castToBoolean (qp "debug")) "debugging" "not debugging"}}</output>
      </template>,
    )
    await visit('/?debug=1')
    assert.dom('output').hasText('debugging')
    await visit('/?debug=0')
    assert.dom('output').hasText('not debugging')
    await a11yAudit()
  })
})
