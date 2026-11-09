import type { TOC } from '@ember/component/template-only'
import { Label as LabelPrimitive, preventLabelSelection } from '@ember-joinery/primitives/label'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import type { TagName } from '@ember-joinery/primitives/as'

/** What both `<Label>` and the `asLabel` modifier take. */
export interface LabelOptions {
  /** The label's name, for its harness (`data-test-jn-name`). */
  name?: string
}

/** The class a label renders: upstream's `cn-label`, renamed `jn-label`. */
export function labelClasses(): string {
  return 'jn-label'
}

/** The data attributes a label renders: upstream's, and its harness's. */
export interface LabelAttributes {
  'data-slot': 'label'
  'data-test-jn': 'label'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

/** The data attributes a label renders, as upstream's and for its harness. */
export function labelAttributes({ name }: LabelOptions = {}): LabelAttributes {
  return { 'data-slot': 'label', 'data-test-jn': 'label', 'data-test-jn-name': name }
}

/**
 * Makes any element or component a label, as upstream's `asChild` does: the label's class and
 * attributes, and the primitive's `preventLabelSelection` on `mousedown`. On anything but a
 * `<label>`, tie it to its control with `aria-labelledby` on the control.
 *
 *   <span id="volume-label" {{asLabel}}>Volume</span>
 *
 * It isn't named `label`: in a template, a binding by that name would turn every `<label>`
 * element into a call to it.
 */
export const asLabel: PartModifier<HTMLElement, LabelOptions> = part<HTMLElement, LabelOptions>(
  options => ({
    class: labelClasses(),
    attributes: labelAttributes(options),
    on: { mousedown: preventLabelSelection },
  }),
)

export interface LabelSignature {
  Args: LabelOptions & {
    /** The tag to render instead of `label`. */
    as?: TagName
  }
  Blocks: {
    /** The label's text, and the control itself when the label wraps it. */
    default: []
  }
  Element: HTMLLabelElement
}

/**
 * Renders an accessible label associated with a control: shadcn's Label, on the primitives'
 * `Label` (a native `<label>` whose text a double click doesn't select). Tie it to its control
 * with `for`, or put the control inside it. It dims when its control, marked with the `peer`
 * class just before it, is disabled, or when an ancestor marked `group` has
 * `data-disabled="true"`.
 *
 *   <Label for="email">Your email address</Label>
 */
const Label: TOC<LabelSignature> = <template>
  <LabelPrimitive
    @as={{@as}}
    @name={{@name}}
    class="jn-label"
    data-slot="label"
    ...attributes
  >{{yield}}</LabelPrimitive>
</template>

export default Label
