import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldGroup, FieldLabel, Input } from '@ember-joinery/ember'
import { RichTextEditor, type RichTextValue } from '@ember-joinery/tiptap'

// Formwright's controls-rich-text, ported: a post with a title and a body, stored as HTML.
export default class RichTextEditorDemo extends Component {
  @tracked title = 'Release notes'
  /** Stores HTML. */
  @tracked body: RichTextValue =
    '<h2>What is new</h2>' +
    '<p>Four new controls, each in its <strong>own package</strong>, so you install only ' +
    'what you <em>use</em>:</p>' +
    '<ul><li><p>Date pickers</p></li><li><p>Phone numbers</p></li>' +
    '<li><p>File uploads</p></li><li><p>Rich text</p></li></ul>'

  setTitle = (title: string) => (this.title = title)
  setBody = (body: RichTextValue) => (this.body = body)

  <template>
    <FieldGroup class="w-full max-w-xl">
      <Field>
        <FieldLabel for="post-title">Title</FieldLabel>
        <Input id="post-title" @value={{this.title}} @onValueChange={{this.setTitle}} />
      </Field>
      <Field>
        <FieldLabel for="post-body">Body</FieldLabel>
        <RichTextEditor
          @name="body"
          @id="post-body"
          @value={{this.body}}
          @onValueChange={{this.setBody}}
          @placeholder="Write something"
          @describedBy="post-body-hint"
        />
        <FieldDescription id="post-body-hint">
          Markdown shortcuts work too: ## for a heading, - for a list
        </FieldDescription>
      </Field>
    </FieldGroup>
  </template>
}
