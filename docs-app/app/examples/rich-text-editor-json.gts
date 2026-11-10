import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import type { JSONContent } from '@tiptap/core'
import { Button, Field, FieldError, FieldLabel } from '@ember-joinery/ember'
import { RichTextEditor, toPlainText, type RichTextValue } from '@ember-joinery/tiptap'

// Formwright's controls-rich-text-json, ported: a comment box with three buttons, stored as
// Tiptap's JSON, that needs some text before it posts.
const TOOLS = ['bold', 'italic', 'bullet-list'] as const

export default class RichTextEditorJson extends Component {
  /** Tiptap's JSON document, or null when empty. */
  @tracked body: JSONContent | null = null
  @tracked submitted = false
  @tracked posted: string[] = []

  /** A comment needs some text. */
  get error(): string | undefined {
    return this.submitted && !toPlainText(this.body) ? 'Write a comment first' : undefined
  }

  setBody = (body: RichTextValue) => (this.body = body as JSONContent | null)

  submit = (event: SubmitEvent) => {
    event.preventDefault()
    this.submitted = true
    if (this.error) return
    this.posted = [...this.posted, toPlainText(this.body)]
    this.body = null
    this.submitted = false
  }

  <template>
    <form class="grid w-full max-w-md gap-4" {{on "submit" this.submit}}>
      <Field @invalid={{if this.error true false}}>
        <FieldLabel for="comment">Comment</FieldLabel>
        <RichTextEditor
          @name="comment"
          @id="comment"
          @output="json"
          @toolbar={{TOOLS}}
          @placeholder="Leave a comment"
          @required={{true}}
          @invalid={{if this.error true false}}
          @describedBy={{if this.error "comment-error"}}
          @value={{this.body}}
          @onValueChange={{this.setBody}}
        />
        {{#if this.error}}
          <FieldError id="comment-error">{{this.error}}</FieldError>
        {{/if}}
      </Field>
      <Button @name="post" type="submit" class="justify-self-end">Comment</Button>
      {{#if this.posted.length}}
        <ul class="text-muted-foreground grid gap-1 text-sm" aria-label="Posted">
          {{#each this.posted as |comment|}}
            <li>{{comment}}</li>
          {{/each}}
        </ul>
      {{/if}}
    </form>
  </template>
}
