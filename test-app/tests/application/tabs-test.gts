import { module, test } from 'qunit'
import { setupApplicationTest } from 'test-app/tests/helpers'
import { currentURL, visit } from '@ember/test-helpers'
import { LinkTo } from '@ember/routing'
import Component from '@glimmer/component'
import { service } from '@ember/service'
import type RouterService from '@ember/routing/router-service'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Tabs } from '@ember-joinery/primitives/tabs'
import { TabsHarness, setupRouting } from '@ember-joinery/test-support'

/** Link tabs, as an app writes them: each a LinkTo, the selection the current route. */
class SettingsNav extends Component<{ Blocks: { default: [] } }> {
  @service declare router: RouterService

  get current(): string {
    return this.router.currentRouteName ?? ''
  }

  <template>
    <Tabs @name="settings" @value={{this.current}} as |t|>
      <t.List aria-label="Settings">
        <LinkTo @route="profile" {{t.trigger value="profile"}}>Profile</LinkTo>
        <LinkTo @route="billing" {{t.trigger value="billing"}}>Billing</LinkTo>
      </t.List>
      <t.Content @value={{t.value}}>{{yield}}</t.Content>
    </Tabs>
  </template>
}

module('Application | primitives | tabs', function (hooks) {
  setupApplicationTest(hooks)

  test('link tabs follow the route: a click navigates, and the selection comes back from the URL', async function (assert) {
    setupRouting(this.owner, function () {
      this.route('profile')
      this.route('billing')
    })
    this.owner.register(
      'template:application',
      <template>
        <SettingsNav>{{outlet}}</SettingsNav>
      </template>,
    )
    this.owner.register('template:profile', <template>Your profile</template>)
    this.owner.register('template:billing', <template>Your plan</template>)

    await visit('/profile')
    const settings = new TabsHarness('settings')
    assert.true(settings.isLink('profile'))
    assert.dom(settings.trigger('profile')).hasAttribute('href', '/profile')
    assert.strictEqual(settings.selected, 'profile')
    assert.strictEqual(settings.panelText, 'Your profile', 'the outlet, in the one panel')

    await settings.focus('profile')
    await settings.press('ArrowRight')
    assert.strictEqual(settings.focused, 'billing')
    assert.strictEqual(currentURL(), '/profile', 'moving focus does not navigate')
    assert.strictEqual(settings.selected, 'profile')

    await settings.select('billing')
    assert.strictEqual(currentURL(), '/billing')
    assert.strictEqual(settings.selected, 'billing', 'from the route')
    assert.strictEqual(settings.panelText, 'Your plan')

    await visit('/profile')
    assert.strictEqual(settings.selected, 'profile', 'and back, as the URL changes')
    await a11yAudit()
  })
})
