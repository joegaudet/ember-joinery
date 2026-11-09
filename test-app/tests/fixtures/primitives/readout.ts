import { Harness } from '@ember-joinery/test-support'

/**
 * A value a test shows, to read back: `<output data-test-jn="readout">`, named with
 * `data-test-jn-name` when there are several.
 *
 *   <output data-test-jn="readout" data-test-jn-name="count">{{this.count}}</output>
 *
 *   new ReadoutHarness('count').text // '2'
 */
export class ReadoutHarness extends Harness {
  static override component = 'readout'

  /** The text as it reads on screen, the template's line breaks collapsed. */
  get text(): string {
    return this.element.textContent!.replace(/\s+/g, ' ').trim()
  }
}
