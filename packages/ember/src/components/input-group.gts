import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { on } from '@ember/modifier'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import type { NativeValueArgs } from '@ember-joinery/primitives/native-value'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import Button, { buttonAttributes, buttonClasses, type ButtonVariant } from './button.gts'
import Input, { inputAttributes, inputClasses, type InputOptions } from './input.gts'
import Textarea, { textareaAttributes, textareaClasses, type TextareaOptions } from './textarea.gts'

/** Where an addon goes: beside the control (`inline-*`) or above or below it (`block-*`). */
export type InputGroupAddonAlign = 'inline-start' | 'inline-end' | 'block-start' | 'block-end'

/** How big a button in an input group is: upstream's four sizes, smaller than Button's. */
export type InputGroupButtonSize = 'xs' | 'sm' | 'icon-xs' | 'icon-sm'

// ----- Addon ---------------------------------------------------------------------------------

/** What an addon takes, as a component and as a modifier. */
export interface InputGroupAddonOptions {
  /** Default `inline-start`. Put the addon after the control in the DOM, whatever its side. */
  align?: InputGroupAddonAlign
}

/** The classes an addon renders: upstream's semantic classes, renamed `jn-`. */
export function inputGroupAddonClasses({
  align = 'inline-start',
}: InputGroupAddonOptions = {}): string {
  return `jn-input-group-addon jn-input-group-addon-align-${align}`
}

/** The attributes an addon renders: upstream's `role`, `data-slot` and `data-align`, and its part. */
export function inputGroupAddonAttributes({
  align = 'inline-start',
}: InputGroupAddonOptions = {}): Record<string, string> {
  return {
    role: 'group',
    'data-slot': 'input-group-addon',
    'data-align': align,
    'data-test-jn-part': 'addon',
  }
}

/**
 * A press on an addon focuses the group's input, as upstream's: anywhere but on a button in
 * it. Upstream looks for an `<input>` only, so a textarea's group leaves focus alone.
 */
function focusControl(event: MouseEvent): void {
  if ((event.target as Element | null)?.closest('button')) return
  const addon = event.currentTarget as HTMLElement
  addon.parentElement?.querySelector('input')?.focus()
}

export interface InputGroupAddonSignature {
  Args: InputGroupAddonOptions & {
    /** The tag to render instead of `div`. For a component of your own, use `g.addon`. */
    as?: TagName
  }
  /** Icons, text, buttons or a `Kbd`. */
  Blocks: { default: [] }
  Element: HTMLElement
}

const InputGroupAddon: TOC<InputGroupAddonSignature> = <template>
  <As
    @as={{@as}}
    class={{inputGroupAddonClasses align=@align}}
    role="group"
    data-slot="input-group-addon"
    data-align={{if @align @align "inline-start"}}
    data-test-jn-part="addon"
    {{on "click" focusControl}}
    ...attributes
  >{{yield}}</As>
</template>

const addonModifier = part<HTMLElement, InputGroupAddonOptions>(options => ({
  class: inputGroupAddonClasses(options),
  attributes: inputGroupAddonAttributes(options),
  on: { click: focusControl },
}))

// ----- Button --------------------------------------------------------------------------------

/** What a button in an input group takes, as a component and as a modifier. */
export interface InputGroupButtonOptions {
  /** Default `ghost`. */
  variant?: ButtonVariant
  /** Default `xs`. */
  size?: InputGroupButtonSize
  /** The button's name, for `ButtonHarness` (`data-test-jn-name`). */
  name?: string
}

/**
 * The classes a button in an input group renders: a Button's, at Button's `default` size (as
 * upstream's, which keeps its own size off the Button), then the group's own.
 */
export function inputGroupButtonClasses({
  variant = 'ghost',
  size = 'xs',
}: InputGroupButtonOptions = {}): string {
  return `${buttonClasses({ variant })} jn-input-group-button jn-input-group-button-size-${size}`
}

/** Its attributes: a Button's, with its own size as `data-size`. */
export function inputGroupButtonAttributes({
  variant = 'ghost',
  size = 'xs',
  name,
}: InputGroupButtonOptions = {}): Record<string, string | undefined> {
  return { ...buttonAttributes({ variant, name }), 'data-size': size }
}

export interface InputGroupButtonSignature {
  Args: InputGroupButtonOptions & {
    /**
     * The tag to render instead of `button`, such as `a` for a link (`<g.Button @as="a">`).
     * For a component of your own, such as `LinkTo`, use `g.button`.
     */
    as?: TagName
  }
  /** Its label, or an icon (name an icon-only button with `aria-label`). */
  Blocks: { default: [] }
  /**
   * A `<button>`, as Joinery's Button (its `type` is `button`, unless you give another), or
   * with `@as="a"`, a link.
   */
  Element: HTMLButtonElement | HTMLAnchorElement
}

class InputGroupButton extends Component<InputGroupButtonSignature> {
  get size(): InputGroupButtonSize {
    return this.args.size ?? 'xs'
  }

  /** `button`, as upstream's, on a `<button>`; another tag has no `type`. */
  get type(): 'button' | undefined {
    const tag = this.args.as
    return !tag || tag === 'button' ? 'button' : undefined
  }

  <template>
    <Button
      @as={{@as}}
      @variant={{if @variant @variant "ghost"}}
      @name={{@name}}
      type={{this.type}}
      class="jn-input-group-button jn-input-group-button-size-{{this.size}}"
      data-size={{this.size}}
      ...attributes
    >{{yield}}</Button>
  </template>
}

const buttonModifier = part<HTMLElement, InputGroupButtonOptions>(options => ({
  class: inputGroupButtonClasses(options),
  attributes: inputGroupButtonAttributes(options),
}))

// ----- Text ----------------------------------------------------------------------------------

export interface InputGroupTextSignature {
  Args: {
    /** The tag to render instead of `span`. */
    as?: TagName
  }
  /** Text, and any icons beside it. */
  Blocks: { default: [] }
  Element: HTMLElement
}

/** Text beside the control: a prefix (`https://`), a unit (`USD`) or a count. */
const InputGroupText: TOC<InputGroupTextSignature> = <template>
  <As
    @as={{@as}}
    @tag="span"
    class="jn-input-group-text"
    data-test-jn-part="text"
    ...attributes
  >{{yield}}</As>
</template>

const textModifier = part<HTMLElement>(() => ({
  class: 'jn-input-group-text',
  attributes: { 'data-test-jn-part': 'text' },
}))

// ----- Input and Textarea --------------------------------------------------------------------

export interface InputGroupInputSignature {
  Args: NativeValueArgs & InputOptions
  /** A native `<input>`, as Joinery's Input. */
  Element: HTMLInputElement
}

/**
 * The group's input: Joinery's Input, with the group's styles, and
 * `data-slot="input-group-control"`, which the group's focus and invalid rings look for.
 */
const InputGroupInput: TOC<InputGroupInputSignature> = <template>
  <Input
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @name={{@name}}
    class="jn-input-group-input"
    data-slot="input-group-control"
    ...attributes
  />
</template>

const inputModifier = part<HTMLInputElement, InputOptions>(options => ({
  class: `${inputClasses()} jn-input-group-input`,
  attributes: { ...inputAttributes(options), 'data-slot': 'input-group-control' },
}))

export interface InputGroupTextareaSignature {
  Args: NativeValueArgs & TextareaOptions
  /** A native `<textarea>`, as Joinery's Textarea. */
  Element: HTMLTextAreaElement
}

/** The group's textarea: Joinery's Textarea, with the group's styles and `data-slot`. */
const InputGroupTextarea: TOC<InputGroupTextareaSignature> = <template>
  <Textarea
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @name={{@name}}
    class="jn-input-group-textarea"
    data-slot="input-group-control"
    ...attributes
  />
</template>

const textareaModifier = part<HTMLTextAreaElement, TextareaOptions>(options => ({
  class: `${textareaClasses()} jn-input-group-textarea`,
  attributes: { ...textareaAttributes(options), 'data-slot': 'input-group-control' },
}))

/**
 * Makes a control of your own the group's (a third-party textarea, say): it adds
 * `data-slot="input-group-control"`, which the group's focus and invalid rings look for, as
 * upstream's "Custom Input" does. Style the control yourself.
 */
const controlModifier = part<HTMLElement>(() => ({
  attributes: { 'data-slot': 'input-group-control' },
}))

// ----- InputGroup ----------------------------------------------------------------------------

/** What an input group yields: its parts, each as a component and as a modifier. */
export interface InputGroupParts {
  /** The group's input: Joinery's Input, styled for the group. */
  Input: ComponentLike<InputGroupInputSignature>
  /** The group's textarea: Joinery's Textarea, styled for the group. */
  Textarea: ComponentLike<InputGroupTextareaSignature>
  /** Icons, text or buttons beside, above or below the control (`@align`). */
  Addon: ComponentLike<InputGroupAddonSignature>
  /** A small button, ghost by default (`@variant`, `@size`). */
  Button: ComponentLike<InputGroupButtonSignature>
  /** Text beside the control. */
  Text: ComponentLike<InputGroupTextSignature>
  /** `<input {{g.input}}>`: makes your own input the group's, styled as `Input`. */
  input: PartModifier<HTMLInputElement, InputOptions>
  /** Makes your own textarea the group's, styled as `Textarea`. */
  textarea: PartModifier<HTMLTextAreaElement, TextareaOptions>
  /** Makes your own control the group's, unstyled: it adds `data-slot="input-group-control"`. */
  control: PartModifier<HTMLElement>
  /** Makes your own element an addon (`{{g.addon align="inline-end"}}`). */
  addon: PartModifier<HTMLElement, InputGroupAddonOptions>
  /** Makes your own element or component a group button. */
  button: PartModifier<HTMLElement, InputGroupButtonOptions>
  /** Makes your own element the group's text. */
  text: PartModifier<HTMLElement>
}

const PARTS: InputGroupParts = {
  Input: InputGroupInput,
  Textarea: InputGroupTextarea,
  Addon: InputGroupAddon,
  Button: InputGroupButton,
  Text: InputGroupText,
  input: inputModifier,
  textarea: textareaModifier,
  control: controlModifier,
  addon: addonModifier,
  button: buttonModifier,
  text: textModifier,
}

export interface InputGroupSignature {
  Args: {
    /** The tag to render instead of `div`. */
    as?: TagName
    /** The group's name, for `InputGroupHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The control first, then its addons, whatever their side (`@align` places them). */
    default: [InputGroupParts]
  }
  Element: HTMLElement
}

/**
 * Add addons, buttons, and helper content to inputs: shadcn's Input Group. A `role="group"`
 * around one control (an input or a textarea) and its addons, drawn as one field, with the
 * control's focus and invalid rings around all of it:
 *
 *   <InputGroup as |g|>
 *     <g.Input placeholder="Search..." />
 *     <g.Addon><Icon @icon={{Search}} /></g.Addon>
 *     <g.Addon @align="inline-end">12 results</g.Addon>
 *   </InputGroup>
 *
 * Put each addon after the control, so focus moves through them in order, and place it with
 * `@align`. A press on an addon (not on a button in it) focuses the input.
 */
const InputGroup: TOC<InputGroupSignature> = <template>
  <As
    @as={{@as}}
    class="group/input-group jn-input-group"
    role="group"
    data-slot="input-group"
    data-test-jn="input-group"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</As>
</template>

export default InputGroup
