import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import {
  RadioGroup as RadioGroupPrimitive,
  type RadioGroupSignature as RadioGroupPrimitiveSignature,
  type RadioGroupItemSignature as RadioGroupItemPrimitiveSignature,
} from '@ember-joinery/primitives/radio-group'

/** The headless item the group yields, which the styled one renders. */
type PrimitiveItem = RadioGroupPrimitiveSignature['Blocks']['default'][0]['Item']

export interface RadioGroupItemSignature {
  Args: Omit<RadioGroupItemPrimitiveSignature['Args'], 'group'> & {
    /** @internal Bound by the group. */
    item: PrimitiveItem
  }
  /** A `<button role="radio">`, or the tag `@as` names. */
  Element: HTMLButtonElement
}

/** One choice: shadcn's `RadioGroupItem`, a ring with a dot while chosen. */
const RadioGroupItem: TOC<RadioGroupItemSignature> = <template>
  <@item
    @value={{@value}}
    @disabled={{@disabled}}
    @as={{@as}}
    class="jn-radio-group-item group/radio-group-item peer"
    data-slot="radio-group-item"
    ...attributes
    as |item|
  >
    <item.Indicator class="jn-radio-group-indicator" data-slot="radio-group-indicator">
      <span class="jn-radio-group-indicator-icon"></span>
    </item.Indicator>
  </@item>
</template>

export interface RadioGroupSignature {
  Args: RadioGroupPrimitiveSignature['Args']
  Blocks: {
    default: [
      group: {
        /** One choice: `<group.Item @value="comfortable" id="r2" />`. */
        Item: WithBoundArgs<typeof RadioGroupItem, 'item'>
        /** The chosen item's value, or `null`. */
        value: string | null
      },
    ]
  }
  Element: HTMLDivElement
}

/**
 * A set of checkable buttons, known as radio buttons, where no more than one of the buttons can
 * be checked at a time: shadcn's RadioGroup, on the primitives' headless one. It yields its
 * items, and its value is controlled or not, as in Radix:
 *
 *   <RadioGroup @defaultValue="option-one" as |group|>
 *     <div class="flex items-center gap-3">
 *       <group.Item @value="option-one" id="option-one" />
 *       <Label for="option-one">Option One</Label>
 *     </div>
 *   </RadioGroup>
 *
 * Mark an item's error with `aria-invalid="true"` on it. In a form, give the group
 * `@formName`: each item renders a hidden native radio beside it under that name, as Radix's
 * does, so the form submits the choice.
 */
const RadioGroup: TOC<RadioGroupSignature> = <template>
  <RadioGroupPrimitive
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @disabled={{@disabled}}
    @required={{@required}}
    @orientation={{@orientation}}
    @dir={{@dir}}
    @loop={{@loop}}
    @formName={{@formName}}
    @as={{@as}}
    @name={{@name}}
    class="jn-radio-group"
    data-slot="radio-group"
    ...attributes
    as |group|
  >
    {{yield (hash Item=(component RadioGroupItem item=group.Item) value=group.value)}}
  </RadioGroupPrimitive>
</template>

export default RadioGroup
