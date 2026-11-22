/**
 * The test hooks a `setup…(hooks)` helper registers on: QUnit's `hooks`, or the same shape
 * around Vitest's `beforeEach` and `afterEach`.
 */
export interface TestHooks {
  /** Runs the callback before each test. */
  beforeEach(callback: () => void | Promise<void>): void
  /** Runs the callback after each test. */
  afterEach(callback: () => void | Promise<void>): void
}
