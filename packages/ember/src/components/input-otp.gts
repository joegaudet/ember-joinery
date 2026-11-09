import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import {
  InputOTP as InputOTPPrimitive,
  InputOTPSlot as InputOTPSlotPrimitive,
  type InputOTPSignature as InputOTPPrimitiveSignature,
  type OTPSlot,
} from '@ember-joinery/primitives/input-otp'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { Minus } from 'lucide'
import Icon, { type IconNode } from './icon.gts'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../-private/static-part.gts'

export {
  REGEXP_ONLY_CHARS,
  REGEXP_ONLY_DIGITS,
  REGEXP_ONLY_DIGITS_AND_CHARS,
  type OTPSlot,
} from '@ember-joinery/primitives/input-otp'

const GROUP = { class: 'jn-input-otp-group', slot: 'input-otp-group', part: 'group' } as const

/** What a separator renders, for its modifier: upstream's class, `role` and `data-slot`, and its harness's part. */
const SEPARATOR = {
  class: 'jn-input-otp-separator',
  attributes: {
    role: 'separator',
    'data-slot': 'input-otp-separator',
    'data-test-jn-part': 'separator',
  },
} as const

export interface InputOTPSlotSignature {
  Args: {
    /** Which character of the code it shows, from 0. */
    index: number
    /** @internal Bound by `InputOTP`. */
    slots: readonly OTPSlot[]
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Element: HTMLElement
}

/**
 * One character's box, as upstream's `InputOTPSlot`: the character, or, where the next one
 * goes, a blinking caret. `data-active="true"` while the selection is on it; mark an error with
 * `aria-invalid="true"` on it, as upstream's example does.
 */
const InputOTPSlot: TOC<InputOTPSlotSignature> = <template>
  <InputOTPSlotPrimitive
    @as={{@as}}
    @index={{@index}}
    @slots={{@slots}}
    class="jn-input-otp-slot"
    data-slot="input-otp-slot"
    ...attributes
    as |slot|
  >
    {{slot.char}}
    {{#if slot.hasFakeCaret}}
      <div class="jn-input-otp-caret" data-test-jn-part="caret">
        <div class="jn-input-otp-caret-line"></div>
      </div>
    {{/if}}
  </InputOTPSlotPrimitive>
</template>

export interface InputOTPSeparatorSignature {
  Args: {
    /** The icon it draws: one from `lucide`. Default lucide's `minus` (`MinusIcon`). */
    icon?: IconNode
    /** The tag to render instead of `div`. For an element that draws its own, use `otp.separator`. */
    as?: TagName
  }
  Element: HTMLElement
}

/** What goes between groups: a `role="separator"` with a minus sign, as upstream's. */
const InputOTPSeparator: TOC<InputOTPSeparatorSignature> = <template>
  <As
    @as={{@as}}
    class="jn-input-otp-separator"
    role="separator"
    data-slot="input-otp-separator"
    data-test-jn-part="separator"
    ...attributes
  >
    <Icon @icon={{if @icon @icon Minus}} />
  </As>
</template>

/** What an input OTP yields: its parts, and its state. */
export interface InputOTPParts {
  /** A row of slots that touch, with one border around them. */
  Group: ComponentLike<StaticPartSignature>
  /** One character's box: `<otp.Slot @index={{0}} />`. */
  Slot: WithBoundArgs<typeof InputOTPSlot, 'slots'>
  /** What goes between groups. */
  Separator: typeof InputOTPSeparator
  /** Makes your own element a group. */
  group: PartModifier<HTMLElement>
  /** Makes your own element a separator (it draws its own content). */
  separator: PartModifier<HTMLElement>
  /** Each slot's state, one per character. */
  slots: readonly OTPSlot[]
  /** The code now. */
  value: string
  /** Whether the code has all its characters. */
  isComplete: boolean
  /** Whether it has focus. */
  isFocused: boolean
}

const GROUP_PART = staticPart(GROUP)
const GROUP_MODIFIER = staticPartModifier(GROUP)
const SEPARATOR_MODIFIER = part<HTMLElement>(() => SEPARATOR)

function containerClasses(extra: string | undefined): string {
  return extra ? `jn-input-otp-container ${extra}` : 'jn-input-otp-container'
}

export interface InputOTPSignature {
  Args: Omit<InputOTPPrimitiveSignature['Args'], 'containerClass'> & {
    /** Classes for the container around the slots, as upstream's `containerClassName`. */
    containerClass?: string
  }
  Blocks: { default: [InputOTPParts] }
  /**
   * The one native `<input>` that holds the code, laid over the slots, invisible: give it `id`,
   * `name`, `disabled`, `required`, `aria-*` and listeners, as upstream's props go on its input.
   */
  Element: HTMLInputElement
}

/**
 * An accessible one-time password field with copy-paste: shadcn's Input OTP, on the
 * `InputOTP` primitive. One native `<input>` holds the code, so typing, paste, a browser's
 * autofill of a code it was sent, and forms work as on any input; the slots show it:
 *
 *   <InputOTP @maxLength={{6}} @onComplete={{this.verify}} as |otp|>
 *     <otp.Group>
 *       <otp.Slot @index={{0}} />
 *       <otp.Slot @index={{1}} />
 *       <otp.Slot @index={{2}} />
 *     </otp.Group>
 *     <otp.Separator />
 *     <otp.Group>
 *       <otp.Slot @index={{3}} />
 *       <otp.Slot @index={{4}} />
 *       <otp.Slot @index={{5}} />
 *     </otp.Group>
 *   </InputOTP>
 *
 * Its code is controlled or not (`@value`, `@defaultValue`, `@onValueChange`), `@pattern`
 * (`REGEXP_ONLY_DIGITS`) limits what it takes, and `disabled` goes on it as an attribute.
 */
export const InputOTP: TOC<InputOTPSignature> = <template>
  <InputOTPPrimitive
    @maxLength={{@maxLength}}
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @onComplete={{@onComplete}}
    @pattern={{@pattern}}
    @pasteTransformer={{@pasteTransformer}}
    @placeholder={{@placeholder}}
    @autoSubmit={{@autoSubmit}}
    @label={{@label}}
    @textAlign={{@textAlign}}
    @pushPasswordManagerStrategy={{@pushPasswordManagerStrategy}}
    @containerClass={{containerClasses @containerClass}}
    @name={{@name}}
    class="jn-input-otp-input"
    data-slot="input-otp"
    spellcheck="false"
    ...attributes
    as |otp|
  >
    {{yield
      (hash
        Group=GROUP_PART
        Slot=(component InputOTPSlot slots=otp.slots)
        Separator=InputOTPSeparator
        group=GROUP_MODIFIER
        separator=SEPARATOR_MODIFIER
        slots=otp.slots
        value=otp.value
        isComplete=otp.isComplete
        isFocused=otp.isFocused
      )
    }}
  </InputOTPPrimitive>
</template>
