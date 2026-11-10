import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldLabel } from '@ember-joinery/ember'
import { FileUpload, type UploadFn } from '@ember-joinery/file-upload'

interface Attachment {
  id: number
  name: string
  size: number
  url: string
}

let nextId = 1
const tick = () => new Promise(resolve => setTimeout(resolve, 60))

/**
 * Uploads a file and resolves with what to keep. A real one would be
 * `const response = await file.upload('/api/uploads'); return response.json()`, and
 * ember-file-upload keeps `file.progress` up to date. This one pretends.
 */
const upload: UploadFn<Attachment> = async file => {
  for (let progress = 0; progress <= 100; progress += 20) {
    file.progress = progress
    await tick()
  }
  if (file.size > 1_000_000) throw new Error('Too large for this demo (1 MB at most)')
  const id = nextId++
  return { id, name: file.name, size: file.size, url: `/uploads/${id}/${file.name}` }
}

export default class FileUploadUpload extends Component {
  /** What `upload` resolved to, one per file. */
  @tracked attachments: Attachment[] = []

  setAttachments = (attachments: Attachment[]) => (this.attachments = attachments)

  <template>
    <Field class="w-full max-w-md">
      <FieldLabel for="attachments">Attachments</FieldLabel>
      <FileUpload
        @name="attachments"
        @id="attachments"
        @multiple={{true}}
        @upload={{upload}}
        @value={{this.attachments}}
        @onValueChange={{this.setAttachments}}
        @describedBy="attachments-hint"
      />
      <FieldDescription id="attachments-hint">Uploaded as soon as you pick them</FieldDescription>
    </Field>
  </template>
}
