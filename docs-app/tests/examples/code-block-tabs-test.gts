import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TabsHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'
import CodeBlockTabs from 'docs-app/examples/code-block-tabs'

/** Each tab's file: its tab's label, the block's title, and its first line. */
const FILES = {
  route: ['route.ts', 'app/api/chat/route.ts', 'import { streamText } from "ai"'],
  chat: ['chat.tsx', 'components/chat.tsx', '"use client"'],
  env: ['.env.local', '.env.local', 'AI_GATEWAY_API_KEY=your-api-key'],
} as const

module('Example | code-block-tabs', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  test('each tab shows its own file, highlighted and numbered, with its own copy button', async function (assert) {
    await render(<template><CodeBlockTabs /></template>)
    const tabs = new TabsHarness()
    assert.deepEqual(tabs.tabValues, ['route', 'chat', 'env'])
    assert.deepEqual(
      tabs.tabValues.map(value => tabs.label(value)),
      ['route.ts', 'chat.tsx', '.env.local'],
      "the tabs show each file's name",
    )
    assert.strictEqual(tabs.selected, 'route')
    assert.strictEqual(CodeBlockHarness.findAll().length, 1, 'only the selected file renders')

    for (const [value, [, title, firstLine]] of Object.entries(FILES)) {
      await tabs.select(value)
      assert.strictEqual(tabs.selected, value)
      const block = new CodeBlockHarness({ within: tabs.panel! })
      assert.strictEqual(block.title, title, `${value}: its title`)
      assert.strictEqual(block.lines[0]!.text, firstLine, `${value}: its code`)
      assert.true(block.isNumbered, `${value}: numbered`)
      assert.true(block.isHighlighted, `${value}: Shiki has coloured it`)

      await block.copy()
      assert.strictEqual(clipboard.text, block.code, `${value}: Copy copies this file`)
      assert.strictEqual(block.status, 'Copied')
    }
    await a11yAudit()
  })

  test('the arrow keys move between the files', async function (assert) {
    await render(<template><CodeBlockTabs /></template>)
    const tabs = new TabsHarness()
    await tabs.focus('route')
    await tabs.press('ArrowRight')
    assert.strictEqual(tabs.selected, 'chat')
    await tabs.press('End')
    assert.strictEqual(tabs.selected, 'env')
    assert.strictEqual(new CodeBlockHarness({ within: tabs.panel! }).title, '.env.local')
    await a11yAudit()
  })
})
