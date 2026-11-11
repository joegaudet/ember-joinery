import {
  File as FileIcon,
  FileArchive,
  FileAudio,
  FileImage,
  FileSpreadsheet,
  FileText,
  FileVideo,
} from 'lucide'
import type { IconNode } from '@ember-joinery/ember/components/icon'

/** The strings a `<FileUpload>` shows, each an argument with an English default. */
export interface FileUploadLabels {
  /** The drop zone's call to action. */
  prompt: string
  /** What follows it where the browser can drag and drop. */
  hint: string
  /** What the zone says while files are dragged over it. */
  dropLabel: string
  /** A line under the hint, such as which files it takes. */
  description: string | undefined
  /** Names the files a choice or drop turned away, as `@accept` doesn't take them. */
  rejectedLabel: (names: string[]) => string
  /** Names the files a drop of several left out, without `@multiple`. */
  leftOutLabel: (names: string[]) => string
  /** Names a file's remove button. */
  removeLabel: (name: string) => string
  /** Names a failed upload's retry button. */
  retryLabel: (name: string) => string
  /** Names a file's progress bar while it uploads. */
  progressLabel: (name: string) => string
}

const ARCHIVES = new Set(['zip', 'gz', 'tgz', 'tar', 'rar', '7z', 'bz2', 'xz'])
const SHEETS = new Set(['csv', 'tsv', 'xls', 'xlsx', 'ods', 'numbers'])
const TEXTS = new Set(['pdf', 'txt', 'md', 'doc', 'docx', 'odt', 'rtf', 'pages'])
const IMAGES = new Set(['png', 'jpg', 'jpeg', 'gif', 'webp', 'avif', 'svg', 'heic', 'bmp', 'tiff'])
const VIDEOS = new Set(['mp4', 'mov', 'webm', 'mkv', 'avi', 'm4v'])
const AUDIO = new Set(['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'])

/** The lucide icon for a file, from its MIME type when it has one, else its extension. */
export function fileIcon(name: string, type = ''): IconNode {
  const extension = name.includes('.') ? name.split('.').pop()!.toLowerCase() : ''
  if (type.startsWith('image/') || IMAGES.has(extension)) return FileImage
  if (type.startsWith('video/') || VIDEOS.has(extension)) return FileVideo
  if (type.startsWith('audio/') || AUDIO.has(extension)) return FileAudio
  if (ARCHIVES.has(extension)) return FileArchive
  if (SHEETS.has(extension) || type === 'text/csv') return FileSpreadsheet
  if (TEXTS.has(extension) || type.startsWith('text/') || type === 'application/pdf')
    return FileText
  return FileIcon
}
