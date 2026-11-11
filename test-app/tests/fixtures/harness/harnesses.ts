// Harnesses for the fixture components in ./components.gts, written the way a component's
// harness is: a `static component`, getters that read state through ARIA, and actions that
// drive it like a user.
import { click } from '@ember/test-helpers'
import { Harness } from '@ember-joinery/test-support'

export class FxToggleHarness extends Harness {
  static override component = 'fx-toggle'

  get label(): string {
    return this.element.textContent!.trim()
  }

  get isPressed(): boolean {
    return this.element.getAttribute('aria-pressed') === 'true'
  }

  async click(): Promise<void> {
    await click(this.element)
  }
}

export class FxToolbarHarness extends Harness {
  static override component = 'fx-toolbar'
}

export class FxListHarness extends Harness {
  static override component = 'fx-list'

  get items(): string[] {
    return this.values('item')
  }
}

export class FxDisclosureHarness extends Harness {
  static override component = 'fx-disclosure'

  get trigger(): HTMLButtonElement {
    return this.part<HTMLButtonElement>('trigger')
  }

  get content(): HTMLElement {
    return this.part('content')
  }

  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  async toggle(): Promise<void> {
    await click(this.trigger)
  }
}
