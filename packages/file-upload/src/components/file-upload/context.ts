import type { FileUploadState } from './state.ts'
import type { FileUploadLabels } from './labels.ts'

/**
 * What a `<FileUpload>` hands its parts: its state, its strings, and what its file input takes
 * from the caller. The parts read it live, so they follow the root's arguments.
 */
export interface FileUploadContext {
  readonly state: FileUploadState<any>
  readonly labels: FileUploadLabels
  /** The file input's `id` (`@id`). */
  readonly inputId: string | undefined
  /** The file input's `aria-label` (`@label`). */
  readonly label: string | undefined
  /** Whether the value is invalid (`@invalid`): `aria-invalid` on the input. */
  readonly invalid: boolean | undefined
  /** The input's `aria-describedby` (`@describedBy`). */
  readonly describedBy: string | undefined
  /** Whether a file is required (`@required`). */
  readonly required: boolean | undefined
}
