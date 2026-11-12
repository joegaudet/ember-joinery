import type { Message } from '@ember-joinery/primitives/i18n'

/**
 * Every string `@ember-joinery/file-upload` shows or announces itself, in English, for a
 * translation catalog. An argument (`@prompt`, `@removeLabel`) still beats each one.
 */
export const messages = {
  promptMultiple: { id: 'joinery.file-upload.promptMultiple', message: 'Choose files' },
  prompt: { id: 'joinery.file-upload.prompt', message: 'Choose a file' },
  hint: {
    id: 'joinery.file-upload.hint',
    message: 'or drag and drop here',
    description: 'Follows the prompt, "Choose files", where the browser can drag and drop.',
  },
  dropLabel: { id: 'joinery.file-upload.dropLabel', message: 'Drop to add' },
  rejected: {
    id: 'joinery.file-upload.rejected',
    message: 'Not an accepted type: {names}',
    description: '{names} is the files turned away, joined with commas.',
  },
  leftOut: {
    id: 'joinery.file-upload.leftOut',
    message: 'One file at a time; left out: {names}',
    description: '{names} is the files left out, joined with commas.',
  },
  remove: { id: 'joinery.file-upload.remove', message: 'Remove {name}' },
  retry: { id: 'joinery.file-upload.retry', message: 'Retry {name}' },
  progress: { id: 'joinery.file-upload.progress', message: 'Uploading {name}' },
  uploadFailed: { id: 'joinery.file-upload.uploadFailed', message: 'Upload failed' },
  unknownKind: {
    id: 'joinery.file-upload.unknownKind',
    message: 'FILE',
    description: "A file's kind when its name has no extension (otherwise PDF, PNG and so on).",
  },
} satisfies Record<string, Message>
