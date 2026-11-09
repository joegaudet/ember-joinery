import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render, triggerKeyEvent, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Example } from 'docs-app/components/example'

const tab = (name: string) => `[data-test-example-tab="${name}"]`

module('Integration | <Example>', function (hooks) {
  setupRenderingTest(hooks)

  test('shows the example live, then its source and its test', async function (assert) {
    await render(<template><Example @name="introduction" @title="A first example" /></template>)

    assert.dom('[data-test-example="introduction"] .example-title').hasText('A first example')
    assert.dom('[role="tab"]').exists({ count: 3 })
    assert.dom(tab('preview')).hasAria('selected', 'true').hasAttribute('tabindex', '0')
    assert.dom('[role="tabpanel"]').hasAria('labelledby', 'example-introduction-tab-preview')
    assert.dom('.example-preview button').hasText('Bold')
    assert.dom('.example-preview').hasAttribute('data-align', 'center')

    await click(tab('template'))
    assert.dom(tab('template')).hasAria('selected', 'true')
    assert.dom(tab('preview')).hasAria('selected', 'false').hasAttribute('tabindex', '-1')
    assert.dom('.example-code pre.shiki').exists('highlighted by Shiki')
    assert.dom('.example-code').includesText('export default class IntroductionExample')

    await click(tab('test'))
    assert.dom('.example-code').includesText("module('Example | introduction'")

    await a11yAudit()
  })

  test('arrow keys, Home and End move between the tabs', async function (assert) {
    await render(<template><Example @name="introduction" /></template>)

    await triggerKeyEvent(tab('preview'), 'keydown', 'ArrowRight')
    assert.dom(tab('template')).hasAria('selected', 'true').isFocused()

    await triggerKeyEvent(tab('template'), 'keydown', 'End')
    assert.dom(tab('test')).hasAria('selected', 'true').isFocused()

    await triggerKeyEvent(tab('test'), 'keydown', 'ArrowRight')
    assert.dom(tab('preview')).hasAria('selected', 'true').isFocused('wraps around')

    await triggerKeyEvent(tab('preview'), 'keydown', 'ArrowLeft')
    assert.dom(tab('test')).hasAria('selected', 'true').isFocused('and back')

    await triggerKeyEvent(tab('test'), 'keydown', 'Home')
    assert.dom(tab('preview')).hasAria('selected', 'true').isFocused()
  })

  test('the copy button copies the file the tab shows', async function (assert) {
    const copied: string[] = []
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText: async (text: string) => void copied.push(text) },
    })
    try {
      await render(<template><Example @name="introduction" /></template>)
      await click(tab('template'))
      await click('.example-copy')
      assert.dom('.example-copy').hasText('Copied')
      assert.dom('.example-copied[role="status"]').hasText('Copied')
      assert.true(copied[0]?.includes('export default class IntroductionExample'))

      await click(tab('test'))
      assert.dom('.example-copy').hasText('Copy', 'a new tab starts over')
      await click('.example-copy')
      assert.true(copied[1]?.includes("module('Example | introduction'"))
      await waitUntil(
        () => document.querySelector('.example-copy')?.textContent?.trim() === 'Copy',
        {
          timeout: 3000,
        },
      )
    } finally {
      // Back to the browser's own, on Navigator.prototype.
      delete (navigator as { clipboard?: unknown }).clipboard
    }
  })

  test('a missing example says so instead of failing the page', async function (assert) {
    await render(<template><Example @name="no-such-example" /></template>)
    assert.dom('.example-missing[role="alert"]').includesText('no-such-example')
    assert.dom('.example-preview').doesNotExist()
  })
})
