import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import type { ControlSignature, LengthArgs } from '@ember-formwright/ember'
import { InputGroup, textareaClasses, type InputGroupParts } from '@ember-joinery/ember'

export interface TextareaControlSignature {
  Args: ControlSignature<string>['Args'] &
    LengthArgs & {
      /**
       * The parts an `<InputGroup>` yields, to render as the group's textarea (`g.Textarea`)
       * inside it, with a count or buttons in an addon beside it.
       */
      group?: InputGroupParts
      /**
       * Its `rows`. An argument, since a field's `Control` takes only global attributes: give
       * it here, as upstream's examples do (`rows={6}`).
       */
      rows?: number
      /** Its `autocomplete`, as the Input control's. */
      autocomplete?: string
    }
  Element: HTMLTextAreaElement
}

/**
 * Joinery's Textarea as a Formwright control, `@control="textarea"`. In an `<InputGroup>`,
 * give it the group's parts (`@group`) to render as the group's textarea:
 *
 *   <f.Field @for="bio" @control="textarea" @label="Bio" as |field|>
 *     <InputGroup as |g|>
 *       <field.Control @group={{g}} @rows={{6}} />
 *       <g.Addon @align="block-end"><g.Text>{{field.value.length}}/100</g.Text></g.Addon>
 *     </InputGroup>
 *   </f.Field>
 *
 * The field's `@showCount` does the same for you, as Formwright's own textarea shows a count: the
 * textarea goes in an Input Group with its length (and `@maxLength`) in an addon below it,
 * announced politely as it changes (`data-test-fw-count`, as Formwright's). With `@group`, the
 * group is yours, and so is any count.
 */
export class TextareaControl extends Component<TextareaControlSignature> {
  /** Whether it renders its own Input Group, for the field's `@showCount`. */
  get counts(): boolean {
    return Boolean(this.args.showCount) && !this.args.group
  }

  get inGroup(): boolean {
    return Boolean(this.args.group) || this.counts
  }

  get classes(): string {
    return this.inGroup ? `${textareaClasses()} jn-input-group-textarea` : textareaClasses()
  }

  get slot(): string {
    return this.inGroup ? 'input-group-control' : 'textarea'
  }

  get length(): number {
    return (this.args.value ?? '').length
  }

  onInput = (event: Event): void => this.args.onChange((event.target as HTMLTextAreaElement).value)

  <template>
    {{#if this.counts}}
      <InputGroup as |g|>
        <textarea
          id={{@id}}
          name={{@name}}
          class={{this.classes}}
          value={{@value}}
          placeholder={{@placeholder}}
          disabled={{@disabled}}
          readonly={{@readonly}}
          required={{@required}}
          aria-invalid={{if @invalid "true"}}
          aria-describedby={{@describedBy}}
          maxlength={{@maxLength}}
          rows={{@rows}}
          autocomplete={{@autocomplete}}
          data-slot={{this.slot}}
          data-test-jn="textarea"
          data-test-fw-control={{@type}}
          ...attributes
          {{on "input" this.onInput}}
        ></textarea>
        <g.Addon @align="block-end">
          <g.Text class="tabular-nums" aria-live="polite" data-test-fw-count>
            {{this.length}}{{#if @maxLength}} / {{@maxLength}}{{/if}}
          </g.Text>
        </g.Addon>
      </InputGroup>
    {{else}}
      <textarea
        id={{@id}}
        name={{@name}}
        class={{this.classes}}
        value={{@value}}
        placeholder={{@placeholder}}
        disabled={{@disabled}}
        readonly={{@readonly}}
        required={{@required}}
        aria-invalid={{if @invalid "true"}}
        aria-describedby={{@describedBy}}
        maxlength={{@maxLength}}
        rows={{@rows}}
        autocomplete={{@autocomplete}}
        data-slot={{this.slot}}
        data-test-jn="textarea"
        data-test-fw-control={{@type}}
        ...attributes
        {{on "input" this.onInput}}
      ></textarea>
    {{/if}}
  </template>
}
