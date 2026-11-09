// A page object written with standard decorators (`accessor`), where the rest of the suite
// uses the legacy ones Ember apps compile with (`declare`). babel.config.mjs compiles this one
// file with @babel/plugin-proposal-decorators in place of decorator-transforms.
import { child } from '@ember-joinery/test-support'
import { FxDisclosureHarness, FxToggleHarness, FxToolbarHarness } from './harnesses.ts'

export class StandardFormatBar extends FxToolbarHarness {
  static override named = 'format'

  @child(FxToggleHarness, 'bold') accessor bold!: FxToggleHarness
  @child(FxToggleHarness, { index: 1 }) accessor second!: FxToggleHarness
  @child(FxDisclosureHarness) accessor more!: FxDisclosureHarness
}
