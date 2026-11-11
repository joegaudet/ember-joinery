import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import type { ControlSignature } from '@ember-formwright/ember'
import { textareaClasses, type InputGroupParts } from '@ember-joinery/ember'

export interface TextareaControlSignature {
  Args: ControlSignature<string>['Args'] & {
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
 */
export class TextareaControl extends Component<TextareaControlSignature> {
  get classes(): string {
    return this.args.group ? `${textareaClasses()} jn-input-group-textarea` : textareaClasses()
  }

  get slot(): string {
    return this.args.group ? 'input-group-control' : 'textarea'
  }

  onInput = (event: Event): void => this.args.onChange((event.target as HTMLTextAreaElement).value)

  <template>
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
  </template>
}
