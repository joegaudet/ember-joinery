import Component from '@glimmer/component'
import type { FieldLayoutSignature, FieldLayoutState } from '@ember-formwright/ember'
import {
  asField,
  asFieldContent,
  asFieldDescription,
  asFieldLabel,
  asFieldLegend,
  asFieldSet,
  type FieldLegendVariant,
  type FieldOrientation,
} from '@ember-joinery/ember'
import { part, type PartModifier } from '@ember-joinery/primitives/part'

/**
 * Makes a Formwright field's error region shadcn's FieldError: `jn-field-error`,
 * `data-slot="field-error"` and `role="alert"`, so it is announced as it appears, as
 * upstream's is. Formwright's region keeps its own id, `aria-live` and `data-test-fw-error`
 * messages. A layout renders it only while the field is invalid (`@field.isInvalid`), as
 * upstream renders FieldError, so an empty region takes no place in the field.
 *
 *   {{#if @field.isInvalid}}<@parts.Errors {{asFieldErrors}} />{{/if}}
 */
export const asFieldErrors: PartModifier<HTMLElement> = part<HTMLElement>(() => ({
  class: 'jn-field-error jn-formwright-errors',
  attributes: { role: 'alert', 'data-slot': 'field-error', 'data-test-jn-part': 'error' },
}))

/** The controls whose field puts them beside their label by default. */
const HORIZONTAL = new Set(['checkbox', 'switch', 'toggle'])

/** The controls that come before their label, as a checkbox does. */
const CONTROL_FIRST = new Set(['checkbox'])

/**
 * What a field's layout may read of the field beyond its state: its hint, when it has one.
 * Formwright's `FieldLayoutState` says nothing of the hint, so this reads the `@hint` of
 * Formwright's own Field component (`field.args.hint`, as Formwright's `Hint` part does):
 * internal to Formwright, not its layout contract. `layout-test.gts` ("a checkbox with a hint
 * …") fails if a Formwright release stops giving it; should Formwright add the hint to
 * `FieldLayoutState`, read it from there instead.
 */
interface FieldWithArgs extends FieldLayoutState {
  readonly args?: { readonly hint?: string }
}

/** What `JoineryFieldLayout` takes, besides the parts and the field Formwright gives it. */
export interface JoineryFieldLayoutOptions {
  /**
   * How the field sets out its label, control, hint and errors, as shadcn's Field's
   * `orientation`: `vertical` stacks them; `horizontal` puts the control beside a column of the
   * label, hint and errors (a `FieldContent`); `responsive` stacks them until the
   * `FieldGroup` around the field is 28rem wide. Default: `horizontal` for a checkbox, a switch
   * and a toggle, `vertical` for the rest. A group control (radio, checkbox-group) is always a
   * `FieldSet`.
   */
  orientation?: FieldOrientation
  /**
   * In a horizontal or responsive field, the control comes before the label rather than after
   * it. Default: `true` for a checkbox, `false` for the rest.
   */
  controlFirst?: boolean
  /**
   * A group control's legend, as FieldLegend's `variant`: `legend` (the default) sets it as a
   * section's heading, `label` as a field's label.
   */
  legend?: FieldLegendVariant
  /**
   * Classes for the field's label (or legend), as upstream's examples give a FieldLabel its
   * own (`font-normal`, for a checkbox's).
   */
  labelClass?: string
}

export interface JoineryFieldLayoutSignature {
  Args: FieldLayoutSignature['Args'] & JoineryFieldLayoutOptions
  Blocks: FieldLayoutSignature['Blocks']
}

/**
 * A Formwright field layout in shadcn's Field anatomy: the field is a `Field` (`role="group"`,
 * `data-slot="field"`, `data-orientation`, `data-invalid`), its label a `FieldLabel`, its hint
 * a `FieldDescription`, its errors a `FieldError`, and a group control's fieldset a
 * `FieldSet` under a `FieldLegend`. Formwright's parts keep their ids, `aria-*` and
 * `data-test-fw-*` attributes, so Formwright's harnesses and Joinery's both read the field.
 *
 * `setupJoineryForms()` makes it every form's default. A field picks another orientation by
 * name (`@layout="joinery-horizontal"`, `"joinery-responsive"`) or with its own arguments:
 *
 *   <f.Field @for="language" @control="select" @layout={{component JoineryFieldLayout orientation="responsive"}} />
 */
export class JoineryFieldLayout extends Component<JoineryFieldLayoutSignature> {
  get field(): FieldWithArgs {
    return this.args.field
  }

  get orientation(): FieldOrientation {
    return (
      this.args.orientation ?? (HORIZONTAL.has(this.field.controlName) ? 'horizontal' : 'vertical')
    )
  }

  get isVertical(): boolean {
    return this.orientation === 'vertical'
  }

  get controlFirst(): boolean {
    return this.args.controlFirst ?? CONTROL_FIRST.has(this.field.controlName)
  }

  get legend(): FieldLegendVariant {
    return this.args.legend ?? 'legend'
  }

  /**
   * Whether a horizontal field keeps its label, hint and errors together in a `FieldContent`:
   * always for a control that comes after its label (a switch, a select), as upstream's
   * examples write them, and for one that comes first (a checkbox) once there is a hint or an
   * error to go under the label.
   */
  get hasContent(): boolean {
    if (!this.controlFirst) return true
    return Boolean(this.field.args?.hint) || this.field.isInvalid
  }

  <template>
    {{#if @field.isGroup}}
      <@parts.Group
        {{asFieldSet}}
        data-invalid={{if @field.isInvalid "true"}}
        data-disabled={{if @field.disabled "true"}}
      >
        <@parts.Label class={{@labelClass}} {{asFieldLegend variant=this.legend}} />
        <@parts.Hint {{asFieldDescription}} />
        <@parts.Control as |control|>{{yield control}}</@parts.Control>
        {{#if @field.isInvalid}}
          <@parts.Errors {{asFieldErrors}} />
        {{/if}}
      </@parts.Group>
    {{else if this.isVertical}}
      <div {{asField orientation="vertical" invalid=@field.isInvalid disabled=@field.disabled}}>
        <@parts.Label class={{@labelClass}} {{asFieldLabel}} />
        <@parts.Control as |control|>{{yield control}}</@parts.Control>
        <@parts.Hint {{asFieldDescription}} />
        {{#if @field.isInvalid}}
          <@parts.Errors {{asFieldErrors}} />
        {{/if}}
      </div>
    {{else}}
      <div
        {{asField orientation=this.orientation invalid=@field.isInvalid disabled=@field.disabled}}
      >
        {{#if this.controlFirst}}
          <@parts.Control as |control|>{{yield control}}</@parts.Control>
        {{/if}}
        {{#if this.hasContent}}
          <div {{asFieldContent}}>
            <@parts.Label class={{@labelClass}} {{asFieldLabel}} />
            <@parts.Hint {{asFieldDescription}} />
            {{#if @field.isInvalid}}
              <@parts.Errors {{asFieldErrors}} />
            {{/if}}
          </div>
        {{else}}
          <@parts.Label class={{@labelClass}} {{asFieldLabel}} />
        {{/if}}
        {{#unless this.controlFirst}}
          <@parts.Control as |control|>{{yield control}}</@parts.Control>
        {{/unless}}
      </div>
    {{/if}}
  </template>
}
