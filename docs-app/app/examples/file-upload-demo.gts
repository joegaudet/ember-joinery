import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldGroup, FieldLabel } from '@ember-joinery/ember'
import { FileUpload } from '@ember-joinery/file-upload'

/** A stand-in for a file the user picked earlier. */
const sample = (name: string, bytes: number, type: string) =>
  new File([new Uint8Array(bytes)], name, { type })

/** A stand-in for a picture: an SVG, so its preview has something to show. */
const picture = (name: string, from: string, to: string) =>
  new File(
    [
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><defs><linearGradient id="g" x2="1" y2="1"><stop offset="0" stop-color="${from}"/><stop offset="1" stop-color="${to}"/></linearGradient></defs><rect width="40" height="40" fill="url(#g)"/></svg>`,
    ],
    name,
    { type: 'image/svg+xml' },
  )

export default class FileUploadDemo extends Component {
  /** Without @multiple, the list holds one file at most, and a new choice replaces it. */
  @tracked resume: File[] = [sample('ada-lovelace-cv.pdf', 184_320, 'application/pdf')]
  /** With it, the files add up. */
  @tracked samples: File[] = [
    picture('analytical-engine.svg', '#6366f1', '#ec4899'),
    sample('note-g.pdf', 96_400, 'application/pdf'),
  ]

  setResume = (files: File[]) => (this.resume = files)
  setSamples = (files: File[]) => (this.samples = files)

  <template>
    <FieldGroup class="w-full max-w-md">
      <Field>
        <FieldLabel for="resume">Résumé</FieldLabel>
        <FileUpload
          @name="resume"
          @id="resume"
          @accept=".pdf"
          @value={{this.resume}}
          @onValueChange={{this.setResume}}
          @describedBy="resume-hint"
        />
        <FieldDescription id="resume-hint">A PDF, up to 5 MB</FieldDescription>
      </Field>
      <Field>
        <FieldLabel for="samples">Work samples</FieldLabel>
        <FileUpload
          @name="samples"
          @id="samples"
          @multiple={{true}}
          @accept="image/*,.pdf"
          @value={{this.samples}}
          @onValueChange={{this.setSamples}}
        />
      </Field>
    </FieldGroup>
  </template>
}
