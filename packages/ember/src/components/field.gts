import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { preventLabelSelection } from '@ember-joinery/primitives/label'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import Label, { labelAttributes, labelClasses, type LabelOptions } from './label.gts'
import Separator from './separator.gts'

/**
 * How a field lays out its label, control and text: `vertical` stacks them, `horizontal` puts
 * them side by side, and `responsive` stacks them until the `<FieldGroup>` around it is at
 * least 28rem wide (a container query), then puts them side by side.
 */
export type FieldOrientation = 'vertical' | 'horizontal' | 'responsive'

/** How a legend is set: `legend` as a section's heading, `label` as a field's label. */
export type FieldLegendVariant = 'legend' | 'label'

/** What both `<Field>` and the `asField` modifier take. */
export interface FieldOptions {
  /** Default `vertical`. */
  orientation?: FieldOrientation
  /**
   * Whether the field is in its error state: `data-invalid="true"`, which turns its text the
   * theme's `--destructive`. Mark the control itself `aria-invalid` too.
   */
  invalid?: boolean
  /**
   * Whether to show the field disabled: `data-disabled="true"`, which dims its labels. It only
   * styles the field; disable the control itself too.
   */
  disabled?: boolean
  /** The field's name, for `FieldHarness` (`data-test-jn-name`). */
  name?: string
}

/** The classes a field renders: upstream's `cn-field` and its orientation's, renamed `jn-`. */
export function fieldClasses({ orientation = 'vertical' }: FieldOptions = {}): string {
  return `jn-field group/field jn-field-orientation-${orientation}`
}

/** The attributes a field renders: its role, upstream's data attributes, and its harness's. */
export interface FieldAttributes {
  role: 'group'
  'data-slot': 'field'
  'data-orientation': FieldOrientation
  /** `true` while `invalid`, otherwise left off. */
  'data-invalid': 'true' | undefined
  /** `true` while `disabled`, otherwise left off. */
  'data-disabled': 'true' | undefined
  'data-test-jn': 'field'
  /** Left off when there is no `name`. */
  'data-test-jn-name': string | undefined
  [attribute: string]: string | undefined
}

/** The attributes a field renders, as upstream's (`role="group"`) and for its harness. */
export function fieldAttributes({
  orientation = 'vertical',
  invalid,
  disabled,
  name,
}: FieldOptions = {}): FieldAttributes {
  return {
    role: 'group',
    'data-slot': 'field',
    'data-orientation': orientation,
    'data-invalid': invalid ? 'true' : undefined,
    'data-disabled': disabled ? 'true' : undefined,
    'data-test-jn': 'field',
    'data-test-jn-name': name,
  }
}

/**
 * Makes any element or component a field, as `<Field>` renders one:
 *
 *   <section {{asField orientation="horizontal"}}>…</section>
 */
export const asField: PartModifier<HTMLElement, FieldOptions> = part<HTMLElement, FieldOptions>(
  options => ({ class: fieldClasses(options), attributes: fieldAttributes(options) }),
)

export interface FieldSignature {
  Args: FieldOptions & {
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: {
    /** The field's label, control, description and error, in the order to show them. */
    default: []
  }
  Element: HTMLElement
}

/**
 * The core wrapper for a single field: shadcn's Field, a `role="group"` that lays out a label,
 * a control, helper text and an error, stacked or side by side (`@orientation`).
 *
 *   <Field>
 *     <FieldLabel for="email">Email</FieldLabel>
 *     <Input id="email" type="email" />
 *     <FieldDescription>We never share your email with anyone.</FieldDescription>
 *   </Field>
 *
 * `@invalid` turns it to its error state (mark the control `aria-invalid` too), and
 * `@disabled` dims it (disable the control too). A caller's `data-invalid="true"` or
 * `data-disabled="true"`, as upstream's examples write them, does the same.
 */
export default class Field extends Component<FieldSignature> {
  get options(): FieldOptions {
    const { orientation, invalid, disabled, name } = this.args
    return { orientation, invalid, disabled, name }
  }

  get classes(): string {
    return fieldClasses(this.options)
  }

  get attributes(): FieldAttributes {
    return fieldAttributes(this.options)
  }

  // Rendered in the template, not by the modifier, so a server-rendered page is styled; a test
  // checks the two render the same attributes.
  <template>
    <As
      @as={{@as}}
      class={{this.classes}}
      role={{get this.attributes "role"}}
      data-slot={{get this.attributes "data-slot"}}
      data-orientation={{get this.attributes "data-orientation"}}
      data-invalid={{get this.attributes "data-invalid"}}
      data-disabled={{get this.attributes "data-disabled"}}
      data-test-jn={{get this.attributes "data-test-jn"}}
      data-test-jn-name={{get this.attributes "data-test-jn-name"}}
      ...attributes
    >{{yield}}</As>
  </template>
}

/** What `<FieldSet>`, `<FieldGroup>` and their modifiers take. */
export interface FieldContainerOptions {
  /** Its name, for its harness (`data-test-jn-name`). */
  name?: string
}

/** The class a field set renders: upstream's `cn-field-set`, renamed. */
export function fieldSetClasses(): string {
  return 'jn-field-set'
}

/** The attributes a field set renders: upstream's `data-slot`, and its harness's. */
export function fieldSetAttributes({ name }: FieldContainerOptions = {}): Record<
  string,
  string | undefined
> {
  return { 'data-slot': 'field-set', 'data-test-jn': 'field-set', 'data-test-jn-name': name }
}

/** Makes your own element a field set, as `<FieldSet>` renders one. */
export const asFieldSet: PartModifier<HTMLElement, FieldContainerOptions> = part<
  HTMLElement,
  FieldContainerOptions
>(options => ({ class: fieldSetClasses(), attributes: fieldSetAttributes(options) }))

export interface FieldSetSignature {
  Args: FieldContainerOptions & {
    /** The tag to render instead of `fieldset`. */
    as?: TagName
  }
  Blocks: {
    /** A `<FieldLegend>`, a `<FieldDescription>`, and the fields, usually in a `<FieldGroup>`. */
    default: []
  }
  Element: HTMLFieldSetElement
}

/**
 * A `<fieldset>` that groups related fields under a legend, with the space between them:
 * shadcn's FieldSet.
 *
 *   <FieldSet>
 *     <FieldLegend>Address Information</FieldLegend>
 *     <FieldDescription>We need your address to deliver your order.</FieldDescription>
 *     <FieldGroup>…</FieldGroup>
 *   </FieldSet>
 */
export const FieldSet: TOC<FieldSetSignature> = <template>
  <As
    @as={{@as}}
    @tag="fieldset"
    class="jn-field-set"
    data-slot="field-set"
    data-test-jn="field-set"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</As>
</template>

/** What `<FieldLegend>` and `asFieldLegend` take. */
export interface FieldLegendOptions {
  /** Default `legend`. `label` sets it as a field's label, for a set of choices. */
  variant?: FieldLegendVariant
}

/** The class a field legend renders: upstream's `cn-field-legend`, renamed. */
export function fieldLegendClasses(): string {
  return 'jn-field-legend'
}

/** The attributes a field legend renders: upstream's, and its harness's part. */
export function fieldLegendAttributes({ variant = 'legend' }: FieldLegendOptions = {}): Record<
  string,
  string
> {
  return { 'data-slot': 'field-legend', 'data-variant': variant, 'data-test-jn-part': 'legend' }
}

/** Makes your own element a field set's legend, as `<FieldLegend>` renders one. */
export const asFieldLegend: PartModifier<HTMLElement, FieldLegendOptions> = part<
  HTMLElement,
  FieldLegendOptions
>(options => ({ class: fieldLegendClasses(), attributes: fieldLegendAttributes(options) }))

export interface FieldLegendSignature {
  Args: FieldLegendOptions & {
    /** The tag to render instead of `legend`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLLegendElement
}

/**
 * A field set's `<legend>`: shadcn's FieldLegend. `@variant="label"` sets it the size of a
 * label, for a set of checkboxes or radios, or a field set inside another.
 */
export const FieldLegend: TOC<FieldLegendSignature> = <template>
  <As
    @as={{@as}}
    @tag="legend"
    class="jn-field-legend"
    data-slot="field-legend"
    data-variant={{if @variant @variant "legend"}}
    data-test-jn-part="legend"
    ...attributes
  >{{yield}}</As>
</template>

/** The classes a field group renders: upstream's `cn-field-group`, renamed, and its marker. */
export function fieldGroupClasses(): string {
  return 'jn-field-group group/field-group'
}

/** The attributes a field group renders: upstream's `data-slot`, and its harness's. */
export function fieldGroupAttributes({ name }: FieldContainerOptions = {}): Record<
  string,
  string | undefined
> {
  return { 'data-slot': 'field-group', 'data-test-jn': 'field-group', 'data-test-jn-name': name }
}

/** Makes your own element a field group, as `<FieldGroup>` renders one. */
export const asFieldGroup: PartModifier<HTMLElement, FieldContainerOptions> = part<
  HTMLElement,
  FieldContainerOptions
>(options => ({ class: fieldGroupClasses(), attributes: fieldGroupAttributes(options) }))

export interface FieldGroupSignature {
  Args: FieldContainerOptions & {
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: {
    /** The fields, and any `<FieldSeparator>` between them. */
    default: []
  }
  Element: HTMLElement
}

/**
 * Stacks fields with the space between them, and is the container that a responsive field's
 * container query measures: shadcn's FieldGroup. Give it `data-slot="checkbox-group"` for a
 * list of checkboxes, as upstream's examples do, to set them closer together.
 */
export const FieldGroup: TOC<FieldGroupSignature> = <template>
  <As
    @as={{@as}}
    class="jn-field-group group/field-group"
    data-slot="field-group"
    data-test-jn="field-group"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</As>
</template>

/** What a field part with nothing to choose renders, always the same. */
interface FieldPartSpec {
  readonly class: string
  readonly slot: string
  readonly part: string
}

const CONTENT: FieldPartSpec = {
  class: 'jn-field-content group/field-content',
  slot: 'field-content',
  part: 'content',
}
const TITLE: FieldPartSpec = { class: 'jn-field-title', slot: 'field-label', part: 'title' }
const DESCRIPTION: FieldPartSpec = {
  class: 'jn-field-description',
  slot: 'field-description',
  part: 'description',
}

function fieldPartModifier(spec: FieldPartSpec): PartModifier<HTMLElement> {
  return part<HTMLElement>(() => ({
    class: spec.class,
    attributes: { 'data-slot': spec.slot, 'data-test-jn-part': spec.part },
  }))
}

/** Makes your own element a field's content, as `<FieldContent>` renders it. */
export const asFieldContent: PartModifier<HTMLElement> = fieldPartModifier(CONTENT)

/** Makes your own element a field's title, as `<FieldTitle>` renders it. */
export const asFieldTitle: PartModifier<HTMLElement> = fieldPartModifier(TITLE)

/** Makes your own element a field's description, as `<FieldDescription>` renders it. */
export const asFieldDescription: PartModifier<HTMLElement> = fieldPartModifier(DESCRIPTION)

export interface FieldPartSignature<E extends Element = HTMLElement> {
  Args: {
    /** The tag to render instead of the part's own. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: E
}

/**
 * A column that keeps a field's label and description together beside its control, in a
 * horizontal field: shadcn's FieldContent. A field with no description doesn't need one.
 */
export const FieldContent: TOC<FieldPartSignature> = <template>
  <As
    @as={{@as}}
    class="jn-field-content group/field-content"
    data-slot="field-content"
    data-test-jn-part="content"
    ...attributes
  >{{yield}}</As>
</template>

/**
 * A title set as a label, for a field whose label isn't a `<label>`, such as a choice card's
 * heading or a slider's: shadcn's FieldTitle.
 */
export const FieldTitle: TOC<FieldPartSignature> = <template>
  <As
    @as={{@as}}
    class="jn-field-title"
    data-slot="field-label"
    data-test-jn-part="title"
    ...attributes
  >{{yield}}</As>
</template>

/**
 * A field's helper text, muted, in a `<p>`: shadcn's FieldDescription. Links in it are
 * underlined. Tie it to the control with `aria-describedby` for assistive technology.
 */
export const FieldDescription: TOC<FieldPartSignature<HTMLParagraphElement>> = <template>
  <As
    @as={{@as}}
    @tag="p"
    class="jn-field-description"
    data-slot="field-description"
    data-test-jn-part="description"
    ...attributes
  >{{yield}}</As>
</template>

/** The classes a field label renders: Label's, then upstream's `cn-field-label` and its markers. */
export function fieldLabelClasses(): string {
  return `${labelClasses()} jn-field-label group/field-label peer/field-label`
}

/** The attributes a field label renders: Label's, with upstream's `data-slot="field-label"`. */
export function fieldLabelAttributes(
  options: LabelOptions = {},
): Record<string, string | undefined> {
  return { ...labelAttributes(options), 'data-slot': 'field-label' }
}

/**
 * Makes your own element or component a field label, as `<FieldLabel>` renders one. On
 * anything but a `<label>`, tie it to its control with `aria-labelledby` on the control.
 */
export const asFieldLabel: PartModifier<HTMLElement, LabelOptions> = part<
  HTMLElement,
  LabelOptions
>(options => ({
  class: fieldLabelClasses(),
  attributes: fieldLabelAttributes(options),
  on: { mousedown: preventLabelSelection },
}))

export interface FieldLabelSignature {
  Args: LabelOptions & {
    /** The tag to render instead of `label`. */
    as?: TagName
  }
  Blocks: {
    /** The label's text, or a whole `<Field>`, which makes it a choice card. */
    default: []
  }
  Element: HTMLLabelElement
}

/**
 * A field's label: shadcn's FieldLabel, a Label styled for a field. Tie it to its
 * control with `for`. Put a whole horizontal `<Field>` inside it to make a choice card: a
 * bordered box that highlights while its checkbox, radio or switch is checked.
 *
 *   <FieldLabel for="name">Full name</FieldLabel>
 */
export const FieldLabel: TOC<FieldLabelSignature> = <template>
  <Label
    @as={{@as}}
    @name={{@name}}
    class="jn-field-label group/field-label peer/field-label"
    data-slot="field-label"
    ...attributes
  >{{yield}}</Label>
</template>

export interface FieldSeparatorSignature {
  Args: {
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: {
    /** Text to show on the line, such as "Or continue with". Upstream's shows none by default. */
    default: []
  }
  Element: HTMLElement
}

/**
 * A line between sections of a field group, with optional text on it: shadcn's
 * FieldSeparator. The line is a decorative Separator.
 *
 *   <FieldSeparator>Or continue with</FieldSeparator>
 */
export const FieldSeparator: TOC<FieldSeparatorSignature> = <template>
  <As
    @as={{@as}}
    class="jn-field-separator"
    data-slot="field-separator"
    data-content={{if (has-block) "true" "false"}}
    data-test-jn-part="separator"
    ...attributes
  >
    <Separator class="jn-field-separator-line" />
    {{#if (has-block)}}
      <span
        class="jn-field-separator-content"
        data-slot="field-separator-content"
        data-test-jn-part="separator-content"
      >{{yield}}</span>
    {{/if}}
  </As>
</template>

/** An error `<FieldError>` shows: anything with a `message`, as validators report them. */
export interface FieldErrorMessage {
  message?: string
}

/**
 * The messages to show for `errors`, as upstream's FieldError picks them: one per distinct
 * `message`, in order. One distinct message is shown as text, several as a list.
 */
export function fieldErrorMessages(
  errors: ReadonlyArray<FieldErrorMessage | undefined> | undefined,
): Array<string | undefined> {
  if (!errors?.length) return []
  const unique = new Map<string | undefined, FieldErrorMessage | undefined>()
  for (const error of errors) unique.set(error?.message, error)
  return [...unique.values()].map(error => error?.message)
}

export interface FieldErrorSignature {
  Args: {
    /**
     * The errors to show, when there is no block: each with a `message`, such as a validator's
     * issues. Repeated messages show once; several show as a list.
     */
    errors?: ReadonlyArray<FieldErrorMessage | undefined>
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: {
    /** The error to show. It wins over `@errors`. */
    default: []
  }
  Element: HTMLElement
}

/**
 * A field's validation message, in the theme's `--destructive`, announced as it appears
 * (`role="alert"`): shadcn's FieldError. Give it the message as its block, or `@errors`, a
 * validator's list. With neither, it renders nothing.
 *
 *   <FieldError>Enter a valid email address.</FieldError>
 *   <FieldError @errors={{this.errors}} />
 */
export class FieldError extends Component<FieldErrorSignature> {
  get messages(): Array<string | undefined> {
    return fieldErrorMessages(this.args.errors)
  }

  /** The one message to show as text, when there is exactly one. */
  get message(): string | undefined {
    const { messages } = this
    return messages.length === 1 ? messages[0] : undefined
  }

  /** The messages to show as a list, when there are several. */
  get list(): string[] | undefined {
    const { messages } = this
    return messages.length > 1
      ? messages.filter((message): message is string => Boolean(message))
      : undefined
  }

  <template>
    {{#if (has-block)}}
      <As
        @as={{@as}}
        role="alert"
        class="jn-field-error"
        data-slot="field-error"
        data-test-jn-part="error"
        ...attributes
      >{{yield}}</As>
    {{else if this.message}}
      <As
        @as={{@as}}
        role="alert"
        class="jn-field-error"
        data-slot="field-error"
        data-test-jn-part="error"
        ...attributes
      >{{this.message}}</As>
    {{else if this.list}}
      <As
        @as={{@as}}
        role="alert"
        class="jn-field-error"
        data-slot="field-error"
        data-test-jn-part="error"
        ...attributes
      >
        <ul class="jn-field-error-list">
          {{#each this.list as |message|}}
            <li>{{message}}</li>
          {{/each}}
        </ul>
      </As>
    {{/if}}
  </template>
}
