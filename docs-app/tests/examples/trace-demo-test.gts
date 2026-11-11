import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  BubbleHarness,
  ButtonHarness,
  MessageHarness,
  TraceCollapsibleHarness,
  TraceHarness,
} from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import TraceDemo from 'docs-app/examples/trace-demo'
import { chatTiming } from 'docs-app/examples/trace/scripted-chat'

module('Example | trace-demo', function (hooks) {
  setupRenderingTest(hooks)

  // The stream runs at once here; settled() waits for it either way.
  hooks.beforeEach(() => {
    chatTiming.scale = 0
  })
  hooks.afterEach(() => {
    chatTiming.scale = 1
  })

  test('a reply that reasoned, ran tools and cited sources, replayed', async function (assert) {
    await render(<template><TraceDemo /></template>)
    const [question, reply] = MessageHarness.findAll()
    assert.strictEqual(question!.align, 'end')
    assert.strictEqual(question!.find(BubbleHarness).text, 'Why does pnpm install fail in CI?')

    const trace = reply!.find(TraceHarness)
    assert.deepEqual(trace.titles.slice(0, 5), [
      'Thought for 5s',
      'Ran pnpm --version',
      'Ran git diff --stat HEAD~1 -- package.json pnpm-lock.yaml',
      'Failed to run pnpm install --frozen-lockfile',
      'Used 2 sources',
    ])
    const [thought, version, diff, install, sources] = trace.collapsibles
    assert.false(thought!.isOpen, 'the thought is closed once it is done')
    assert.false(version!.isOpen)
    assert.true(diff!.isOpen, 'the third row starts open, as upstream does')
    assert.true(install!.line.isError)
    await install!.open()
    assert.strictEqual(install!.find(CodeBlockHarness).variant, 'destructive')
    await sources!.open()
    assert.strictEqual(
      sources!.find(TraceHarness).lines[0]!.title,
      'pnpm install | pnpm.io (opens in a new tab)',
    )
    assert.true(reply!.text.includes('Run pnpm install locally and commit the lockfile.'))

    const replay = new ButtonHarness()
    assert.strictEqual(replay.label, 'Replay')
    await replay.click()
    const [, replayed] = MessageHarness.findAll()
    const again = replayed!.find(TraceHarness)
    assert.strictEqual(again.collapsibles.length, 5, 'the reply streams back in, row by row')
    assert.false(
      again.lines.some(line => line.isRunning),
      'and nothing runs once it is done',
    )
    assert.true(new TraceCollapsibleHarness({ within: replayed!, index: 2 }).isOpen)
    await a11yAudit()
  })
})
