import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import { ChevronDown } from 'lucide'
import { nativeValue, type NativeValueArgs } from '@ember-joinery/primitives/native-value'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import Icon, { type IconNode } from './icon.gts'

/** How big a native select is. */
export type NativeSelectSize = 'sm' | 'default'

function sizeOf(size: NativeSelectSize | undefined): NativeSelectSize {
  return size ?? 'default'
}

const OPTION_CLASS = 'jn-native-select-option'
const OPT_GROUP_CLASS = 'jn-native-select-optgroup'

export interface NativeSelectOptionSignature {
  Args: {
    /** The option's value: the select's `@value` when it is chosen. */
    value: string
  }
  Blocks: {
    /** The text it shows. */
    default: []
  }
  /** A native `<option>`: give it `disabled` as an attribute. */
  Element: HTMLOptionElement
}

/** One choice in the select: a native `<option>`. */
const Option: TOC<NativeSelectOptionSignature> = <template>
  <option
    class={{OPTION_CLASS}}
    value={{@value}}
    data-slot="native-select-option"
    data-test-jn-part="option"
    data-test-jn-value={{@value}}
    ...attributes
  >{{yield}}</option>
</template>

export interface NativeSelectOptGroupSignature {
  Blocks: {
    /** Its options. */
    default: []
  }
  /** A native `<optgroup>`: give it its `label`, and `disabled` for the whole group. */
  Element: HTMLOptGroupElement
}

/** A group of options under a heading: a native `<optgroup>`, named by its `label`. */
const OptGroup: TOC<NativeSelectOptGroupSignature> = <template>
  <optgroup
    class={{OPT_GROUP_CLASS}}
    data-slot="native-select-optgroup"
    data-test-jn-part="group"
    ...attributes
  >{{yield}}</optgroup>
</template>

/** What a native select yields: its parts, each as a component and as a modifier. */
export interface NativeSelectParts {
  /** An option: `<s.Option @value="todo">Todo</s.Option>`. */
  Option: ComponentLike<NativeSelectOptionSignature>
  /** A group of options: `<s.OptGroup label="Engineering">…</s.OptGroup>`. */
  OptGroup: ComponentLike<NativeSelectOptGroupSignature>
  /** `<option value="todo" {{s.option value="todo"}}>`: makes your own `<option>` an option. */
  option: PartModifier<HTMLOptionElement, { value?: string }>
  /** `<optgroup {{s.optGroup}}>`: makes your own `<optgroup>` a group. */
  optGroup: PartModifier<HTMLOptGroupElement>
}

const PARTS: NativeSelectParts = {
  Option,
  OptGroup,
  option: part<HTMLOptionElement, { value?: string }>(({ value }) => ({
    class: OPTION_CLASS,
    attributes: {
      'data-slot': 'native-select-option',
      'data-test-jn-part': 'option',
      'data-test-jn-value': value,
    },
  })),
  optGroup: part<HTMLOptGroupElement>(() => ({
    class: OPT_GROUP_CLASS,
    attributes: { 'data-slot': 'native-select-optgroup', 'data-test-jn-part': 'group' },
  })),
}

export interface NativeSelectSignature {
  Args: NativeValueArgs & {
    /** Default `default`; `sm` is a shorter one. */
    size?: NativeSelectSize
    /**
     * The icon it shows at its end: one from `lucide`. Default lucide's `chevron-down`,
     * upstream's `ChevronDownIcon`.
     */
    icon?: IconNode
    /** The select's name, for its harness (`data-test-jn-name`). Its form field name is `name`. */
    name?: string
  }
  Blocks: {
    /** Its options and groups, from the parts it yields. */
    default: [NativeSelectParts]
  }
  /**
   * The native `<select>`: `id`, `name`, `disabled`, `required`, `aria-invalid` and listeners
   * go on it, and so does `class`. The wrapper around it, which holds the icon, takes none.
   */
  Element: HTMLSelectElement
}

/**
 * A styled native HTML select: shadcn's Native Select. It renders the browser's own `<select>`,
 * with its own menu (the one phones show), in a wrapper that draws a chevron at its end. Its
 * value is controlled or not, as in Radix, and it yields its `Option` and `OptGroup` parts:
 *
 *   <NativeSelect @value={{this.status}} @onValueChange={{this.setStatus}} as |s|>
 *     <s.Option @value="">Select status</s.Option>
 *     <s.Option @value="todo">Todo</s.Option>
 *   </NativeSelect>
 *
 * Attributes go on the `<select>` (upstream's `className` goes on the wrapper, but an Ember
 * component has one `...attributes`). For a select with custom styling, animation or rich
 * options, use Select.
 *
 * The icon keeps `jn-size-own`: upstream's registry build gives it its style rule's `size-4`,
 * which the style sheets' `svg:not([class*='size-'])` rules look for, so a container's icon
 * size leaves it alone, as upstream's.
 */
const NativeSelect: TOC<NativeSelectSignature> = <template>
  <div
    class="jn-native-select-wrapper group/native-select"
    data-slot="native-select-wrapper"
    data-size={{sizeOf @size}}
    data-test-jn="native-select"
    data-test-jn-name={{@name}}
  >
    <select
      class="jn-native-select"
      data-slot="native-select"
      data-size={{sizeOf @size}}
      data-test-jn-part="select"
      {{nativeValue value=@value defaultValue=@defaultValue onValueChange=@onValueChange}}
      ...attributes
    >{{yield PARTS}}</select>
    <Icon
      @icon={{if @icon @icon ChevronDown}}
      class="jn-native-select-icon jn-size-own"
      aria-hidden="true"
      data-slot="native-select-icon"
      data-test-jn-part="icon"
    />
  </div>
</template>

export default NativeSelect
