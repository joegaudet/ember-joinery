import type { TestHooks } from '@ember-joinery/test-support'

/** The clipboard `setupClipboard` puts in place, and what has been written to it. */
export interface TestClipboard {
  /** The text copied last, or `undefined` before anything is. */
  readonly text: string | undefined
  /** Every text copied, in order. */
  readonly writes: readonly string[]
  /** Makes every copy fail from now on, as a browser that refuses one does. */
  refuse(): void
  /** Lets copies through again. */
  allow(): void
}

/**
 * Puts a clipboard of the test's own on `navigator.clipboard` for each test, and the browser's
 * back after it. A test browser's clipboard needs the page focused and a permission granted, so
 * a copy button can't be tested against it; this one records what is copied instead.
 *
 *   module('copying', function (hooks) {
 *     setupRenderingTest(hooks)
 *     const clipboard = setupClipboard(hooks)
 *
 *     test('it copies the code', async function (assert) {
 *       await render(<template><MyCode /></template>)
 *       await new CodeBlockHarness().copy()
 *       assert.strictEqual(clipboard.text, 'pnpm add ai')
 *     })
 *   })
 */
export function setupClipboard(hooks: TestHooks): TestClipboard {
  let writes: string[] = []
  let refusing = false

  const clipboard: TestClipboard = {
    get text() {
      return writes.at(-1)
    },
    get writes() {
      return writes
    },
    refuse() {
      refusing = true
    },
    allow() {
      refusing = false
    },
  }

  const fake = {
    async writeText(text: string): Promise<void> {
      if (refusing) throw new DOMException('Write permission denied.', 'NotAllowedError')
      writes = [...writes, String(text)]
    },
    async readText(): Promise<string> {
      return writes.at(-1) ?? ''
    },
  }

  hooks.beforeEach(() => {
    writes = []
    refusing = false
    Object.defineProperty(navigator, 'clipboard', { configurable: true, value: fake })
  })
  hooks.afterEach(() => {
    // The browser's own is a getter on Navigator.prototype, which shows again.
    delete (navigator as { clipboard?: unknown }).clipboard
  })

  return clipboard
}
