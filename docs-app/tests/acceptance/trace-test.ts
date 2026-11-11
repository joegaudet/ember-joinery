import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { find, visit, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'

/**
 * Trace's chat examples hold their messages in a column of upstream's utilities,
 * `min-h-72 … py-6`, which isn't a Joinery part. On ui.shadcn.com preflight sizes it
 * `border-box`, so its 288px take the padding in; the guide gives those examples, and no others,
 * that sizing (examples.css), on the parity route and in the frame alike, keyed on the stage's
 * own `data-parity` or `data-example`.
 */
module('Acceptance | trace examples', function (hooks) {
  setupApplicationTest(hooks)

  test("on the parity route, the chat's column is 288px tall, padding included", async function (assert) {
    for (const name of ['trace-thinking', 'trace-tool-calls']) {
      await visit(`/parity/${name}`)
      await waitUntil(() => find(`[data-parity="${name}"] > div`))
      const column = find(`[data-parity="${name}"] > div`) as HTMLElement
      assert.strictEqual(getComputedStyle(column).boxSizing, 'border-box', name)
      assert.strictEqual(column.offsetHeight, 288, `${name}: min-h-72, as upstream's`)
    }
    await a11yAudit({ rules: { region: { enabled: false } } })
  })

  test("in the guide's frame, the stage names its example", async function (assert) {
    await visit('/components/trace.md')
    await waitUntil(() => find('[data-example="trace-tool-calls"] > div'))
    for (const name of ['trace-demo', 'trace-thinking', 'trace-tool-calls']) {
      const column = find(`[data-example="${name}"] > div`) as HTMLElement
      assert.strictEqual(getComputedStyle(column).boxSizing, 'border-box', name)
    }
    assert.strictEqual(
      getComputedStyle(find('[data-example="trace-open"] > div')!).boxSizing,
      'content-box',
      'every other example shows Joinery as an app without Tailwind does',
    )
    await a11yAudit()
  })
})
