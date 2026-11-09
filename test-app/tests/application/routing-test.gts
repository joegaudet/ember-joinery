import { module, test } from 'qunit'
import { setupApplicationTest, setupRenderingTest } from 'test-app/tests/helpers'
import { currentRouteName, currentURL, render, visit } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { qp } from '@ember-joinery/primitives/qp'
import { getRouter, setupRouting } from '@ember-joinery/test-support'
import { ReadoutHarness } from 'test-app/tests/fixtures/primitives/readout'

module('Application | test-support | setupRouting', function (hooks) {
  setupApplicationTest(hooks)

  test("gives a test its own routes, in place of the app's", async function (assert) {
    const router = setupRouting(this.owner, function () {
      this.route('settings', function () {
        this.route('profile')
      })
    })
    this.owner.register('template:application', <template>{{outlet}}</template>)
    this.owner.register(
      'template:settings/profile',
      <template>
        <h1 data-test-jn="readout" data-test-jn-name="heading">Profile</h1>
      </template>,
    )
    await visit('/settings/profile')
    assert.strictEqual(currentURL(), '/settings/profile')
    assert.strictEqual(currentRouteName(), 'settings.profile')
    assert.strictEqual(router, getRouter(this.owner), 'it returns the router service')
    assert.strictEqual(router.currentRouteName, 'settings.profile')
    assert.strictEqual(new ReadoutHarness('heading').text, 'Profile', "the route's template")
    await a11yAudit()
  })

  test('a rootURL', async function (assert) {
    const router = setupRouting(this.owner, function () {}, { rootURL: '/the-root/' })
    await visit('/')
    assert.strictEqual(router.rootURL, '/the-root/')
    assert.strictEqual(router.urlFor('index'), '/the-root/')
    await a11yAudit()
  })

  test('the rootURL must be a path', async function (assert) {
    assert.throws(
      () => setupRouting(this.owner, function () {}, { rootURL: 'the-root/' }),
      /must start with "\/"/,
    )
    await a11yAudit()
  })
})

module('Rendering | test-support | setupRouting', function (hooks) {
  setupRenderingTest(hooks)

  test('starts a router in a rendering test, for what reads the URL', async function (assert) {
    const router = setupRouting(this.owner, function () {
      this.route('shop')
    })
    await router.transitionTo('/shop?color=red')
    await render(
      <template>
        <output data-test-jn="readout">{{qp "color"}}</output>
      </template>,
    )
    assert.strictEqual(new ReadoutHarness().text, 'red')
    assert.strictEqual(router.currentRouteName, 'shop')
    await a11yAudit()
  })
})
