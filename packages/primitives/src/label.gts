import type { TOC } from '@ember/component/template-only'
import { on } from '@ember/modifier'
import { As, type TagName } from './as.gts'

/** The controls a press on a label leaves alone: they handle their own presses. */
const CONTROLS = 'button, input, select, textarea'

/**
 * Radix Label's one behaviour, as a `mousedown` listener: a double click on the label's own
 * text doesn't select it, so clicking a label quickly (to toggle its checkbox twice, say)
 * doesn't highlight the words. A press on a control inside the label is left alone, as is one a
 * listener before it has already prevented.
 *
 *   <span {{on "mousedown" preventLabelSelection}}>…</span>
 */
export function preventLabelSelection(event: MouseEvent): void {
  const target = event.target
  if (target instanceof Element && target.closest(CONTROLS)) return
  if (!event.defaultPrevented && event.detail > 1) event.preventDefault()
}

export interface LabelSignature {
  Args: {
    /** The tag to render. Default `label`. */
    as?: TagName
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The label's text, and the control itself when the label wraps it. */
    default: []
  }
  Element: HTMLLabelElement
}

/**
 * A label for a control, as Radix's `Label`: a native `<label>`, which names its control and
 * passes it a press, with `preventLabelSelection` so a double click doesn't select its text.
 * Tie it to the control with `for`, or put the control inside it. It has no styles.
 *
 *   <Label for="email">Your email address</Label>
 *   <input id="email" type="email" />
 *
 * Your own `mousedown` listeners run first, and one that calls `preventDefault()` stops it.
 */
export const Label: TOC<LabelSignature> = <template>
  <As
    @as={{@as}}
    @tag="label"
    data-test-jn="label"
    data-test-jn-name={{@name}}
    ...attributes
    {{on "mousedown" preventLabelSelection}}
  >{{yield}}</As>
</template>
