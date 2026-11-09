// Type tests for `@child` as a standard decorator (`experimentalDecorators: false`). The test
// app type-checks with Ember's legacy decorators, so it can't check this signature;
// `pnpm typecheck` runs this program as well.
import { Harness, child } from '../src/index.ts'

class ButtonHarness extends Harness {
  static override component = 'button'

  get label(): string {
    return this.element.textContent ?? ''
  }
}

class Toolbar extends Harness {
  @child(ButtonHarness, 'save') accessor save!: ButtonHarness
  @child(ButtonHarness, { index: 1 }) accessor second!: ButtonHarness

  // @ts-expect-error the property's type has to be the child's harness class
  @child(ButtonHarness) accessor wrong!: string
}

export const label: string = new Toolbar().save.label
