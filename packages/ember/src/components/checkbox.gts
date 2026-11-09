import type { TOC } from '@ember/component/template-only'
import { Check } from 'lucide'
import {
  Checkbox as CheckboxPrimitive,
  type CheckboxSignature as CheckboxPrimitiveSignature,
} from '@ember-joinery/primitives/checkbox'
import Icon, { type IconNode } from './icon.gts'

export interface CheckboxSignature {
  Args: CheckboxPrimitiveSignature['Args'] & {
    /** The mark it shows while checked: a `lucide` icon. Default lucide's `check`, upstream's `CheckIcon`. */
    icon?: IconNode
    /**
     * The mark it shows while indeterminate. Default `@icon`, as upstream's shows its check
     * mark then too; lucide's `Minus` is the usual choice.
     */
    indeterminateIcon?: IconNode
  }
  /** A `<button role="checkbox">`, or the tag `@as` names. */
  Element: HTMLButtonElement
}

/** The icon for a state: the indeterminate one while indeterminate, else the check. */
function iconFor(
  isIndeterminate: boolean,
  icon: IconNode | undefined,
  indeterminateIcon: IconNode | undefined,
): IconNode {
  const check = icon ?? Check
  return isIndeterminate ? (indeterminateIcon ?? check) : check
}

/**
 * A control that allows the user to toggle between checked and not checked: shadcn's
 * Checkbox, on the primitives' headless one. Its state is controlled or not, as in Radix, and
 * can be `'indeterminate'`; tie a label to it with `id` and `for`, or put it in one:
 *
 *   <Checkbox id="terms" @checked={{this.terms}} @onCheckedChange={{this.setTerms}} />
 *   <Label for="terms">Accept terms and conditions</Label>
 *
 *   <Checkbox @checked="indeterminate" @indeterminateIcon={{Minus}} aria-label="Select all" />
 *
 * Mark an error with `aria-invalid="true"`. In a form, give it `name` (and `value`, default
 * `on`): a hidden native checkbox beside it submits it, as Radix's does.
 */
const Checkbox: TOC<CheckboxSignature> = <template>
  <CheckboxPrimitive
    @checked={{@checked}}
    @defaultChecked={{@defaultChecked}}
    @onCheckedChange={{@onCheckedChange}}
    @disabled={{@disabled}}
    @required={{@required}}
    @as={{@as}}
    @name={{@name}}
    class="jn-checkbox peer"
    data-slot="checkbox"
    ...attributes
    as |checkbox|
  >
    <checkbox.Indicator class="jn-checkbox-indicator" data-slot="checkbox-indicator">
      <Icon @icon={{iconFor checkbox.isIndeterminate @icon @indeterminateIcon}} />
    </checkbox.Indicator>
  </CheckboxPrimitive>
</template>

export default Checkbox
