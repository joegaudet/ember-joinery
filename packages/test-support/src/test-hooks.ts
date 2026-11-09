/**
 * The test hooks a `setup…(hooks)` helper registers on: QUnit's `hooks`, or the same shape
 * around Vitest's `beforeEach` and `afterEach`.
 */
export interface TestHooks {
  beforeEach(callback: () => void | Promise<void>): void
  afterEach(callback: () => void | Promise<void>): void
}
