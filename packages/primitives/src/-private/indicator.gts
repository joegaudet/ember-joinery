import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'
import { As, type TagName } from '../as.gts'
import { Presence } from '../presence.gts'

/**
 * `pointer-events: none`, as Radix puts on its indicators, so a click on the mark reaches the
 * control. Set through the CSSOM: a strict Content Security Policy blocks a `style` attribute.
 */
const passThrough = modifier((element: HTMLElement) => {
  element.style.setProperty('pointer-events', 'none')
})

export interface IndicatorSignature {
  Args: {
    /** Keep it rendered while the control is unchecked too, to animate it yourself. */
    forceMount?: boolean
    /** The tag to render. Default `span`. */
    as?: TagName
    /** @internal Bound by the control: whether it shows. */
    present: boolean
    /** @internal Bound by the control: its `data-state`. */
    state: string
    /** @internal Bound by the control. */
    disabled?: boolean
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * The mark inside a checkbox or a radio: Radix's `Checkbox.Indicator` and
 * `RadioGroup.Indicator`. It renders while the control is checked (or indeterminate), and
 * stays through an exit animation keyed on its `data-state`, as Radix's `Presence` does.
 */
export const Indicator: TOC<IndicatorSignature> = <template>
  <Presence @present={{@present}} @forceMount={{@forceMount}} as |presence|>
    <As
      @as={{@as}}
      @tag="span"
      data-state={{@state}}
      data-disabled={{if @disabled ""}}
      data-test-jn-part="indicator"
      ...attributes
      {{presence.ref}}
      {{passThrough}}
    >{{yield}}</As>
  </Presence>
</template>
