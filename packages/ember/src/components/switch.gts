import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import {
  Switch as SwitchPrimitive,
  type SwitchSignature as SwitchPrimitiveSignature,
} from '@ember-joinery/primitives/switch'

/** How big a switch is: shadcn's two sizes. */
export type SwitchSize = 'default' | 'sm'

export interface SwitchSignature {
  Args: SwitchPrimitiveSignature['Args'] & {
    /** Default `default`. */
    size?: SwitchSize
  }
  Blocks: {
    /**
     * What the thumb shows, if anything, such as an icon: it renders inside the thumb, with the
     * switch's state.
     */
    default: [thumb: { isChecked: boolean }]
  }
  /** A `<button role="switch">`, or the tag `@as` names. */
  Element: HTMLButtonElement
}

/**
 * A control that allows the user to toggle between checked and not checked: shadcn's Switch,
 * on the primitives' headless one. Its state is controlled or not, as in Radix; tie a label to
 * it with `id` and `for`, or put it in one:
 *
 *   <Switch id="airplane-mode" @checked={{this.on}} @onCheckedChange={{this.setOn}} />
 *   <Label for="airplane-mode">Airplane Mode</Label>
 *
 * Its block renders inside the thumb, so the thumb can show an icon:
 *
 *   <Switch aria-label="Dark mode" as |s|>
 *     <Icon @icon={{if s.isChecked Moon Sun}} />
 *   </Switch>
 *
 * Mark an error with `aria-invalid="true"`. In a form, give it `name` (and `value`, default
 * `on`): a hidden native checkbox beside it submits it, as Radix's does.
 */
const Switch: TOC<SwitchSignature> = <template>
  <SwitchPrimitive
    @checked={{@checked}}
    @defaultChecked={{@defaultChecked}}
    @onCheckedChange={{@onCheckedChange}}
    @disabled={{@disabled}}
    @required={{@required}}
    @as={{@as}}
    @name={{@name}}
    class="jn-switch peer group/switch"
    data-slot="switch"
    data-size={{if @size @size "default"}}
    ...attributes
    as |control|
  >
    <control.Thumb class="jn-switch-thumb" data-slot="switch-thumb">
      {{yield (hash isChecked=control.isChecked)}}
    </control.Thumb>
  </SwitchPrimitive>
</template>

export default Switch
