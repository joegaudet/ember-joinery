import { SelectHarness } from '@ember-formwright/test-support'

/**
 * A `native-select` field, Joinery's Native Select: Formwright's `SelectHarness` (`select(key)`,
 * `value`, `options`), which drives a native `<select>`.
 */
export class NativeSelectFieldHarness extends SelectHarness {
  static override controls = ['native-select']
}
