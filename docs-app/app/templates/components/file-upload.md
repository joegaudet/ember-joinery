# File Upload

A drop zone to choose files with, the list of chosen files, and an upload queue with a progress
bar for each, for one file or many.

<div class="callout">

**An opt-in add-on.** File Upload is its own package, `@ember-joinery/file-upload`, built on
[ember-file-upload](https://ember-file-upload.pages.dev). Nothing in Joinery's core packages
imports it, so an app that doesn't install it doesn't load ember-file-upload.

</div>

shadcn/ui has no file upload, so this one is drawn from the nearest shadcn parts: the zone is a
dashed box holding Empty's icon, title and description, and each file is an outlined Item with a
preview, its name and size, and a remove Button; an upload adds a Progress bar to its row. It
follows the style, base colour and radius you pick, as they do.

<Example @name="file-upload-demo" @title="File Upload" />

## Installation

File Upload is an add-on, so it comes in its own package, with ember-file-upload as a
dependency and that library's peer, `tracked-built-ins`, beside it:

```bash
pnpm add @ember-joinery/file-upload @ember-joinery/ember tracked-built-ins
```

It ships no CSS of its own: Joinery's `joinery.css` (or any of its styles) styles its parts, as
it does every component. Import that once (see
[Installation](/getting-started/installation.md)), then the component where you use it:

```gts
import { FileUpload } from '@ember-joinery/file-upload'
```

## Usage

```gts
<FileUpload @accept=".pdf" @value={{this.files}} @onValueChange={{this.setFiles}} />
```

The value is always a list (`@value`, `@defaultValue` and `@onValueChange`, controlled or not):
of `File`s, or, with `@upload`, of what each upload resolved to. Without `@multiple` it holds one
file at most, and a new choice replaces it; with it, the files add up. Choose with the file
picker (a press on the zone, or Enter or Space on its input) or drop files on the zone.

`@accept` is passed to the input as `accept`, and the same filter is applied to what is dropped
on the zone and to what the picker hands over (its "All files" choice lets anything through):
`.pdf`, `image/*`, `text/csv`… A file it turns away is named under the zone's prompt. Without
`@multiple`, a drop of several takes the first and names the rest as left out. Each file the
value holds is listed with a preview (an image file shows itself; any other, an icon for its
kind), its name, its kind and size, and a button that removes it.

## Composition

Without a block, `FileUpload` renders its zone, its list and its queue, in that order. With
one, it yields them as parts, to lay out as you like, with its files and uploads:

```text
FileUpload
├── u.Dropzone
├── u.List
└── u.Queue
```

```gts
<FileUpload @multiple={{true}} @upload={{this.upload}} as |u|>
  <u.Dropzone />
  <p>{{u.files.length}} attached</p>
  <u.List />
  <u.Queue />
</FileUpload>
```

## Uploading as files are chosen

Give it `@upload`: it receives each file as ember-file-upload's `UploadFile` and returns a
promise of what the value keeps for it, such as a record, an id or a URL. Until the promise
settles, the file waits in the queue with a Progress bar, which follows `file.progress`; the
library's `file.upload(url)` keeps that up to date. If the promise rejects, the row turns
destructive and shows the error's message, keeps nothing, and can be retried or removed.

```ts
import type { UploadFn } from '@ember-joinery/file-upload'

const upload: UploadFn<Attachment> = async file => {
  const response = await file.upload('/api/attachments')
  return response.json() // e.g. { id: 7, name: 'notes.pdf', size: 1200, url: '…' }
}
```

The list names a value with `@nameOf` (by default a file's name, or a record's `name` or
`label`), sizes it with `@sizeOf` (its `size`), and previews it with `@previewOf` (an image
file's own contents).

<Example @name="file-upload-upload" @title="Upload on choose" />

<div class="callout">

**Submitting while files upload.** The value holds a file only once its upload has resolved.
While any upload runs, the component carries `data-uploading`, its queue is `aria-busy`, and
its block gets `u.isUploading`: disable your submit button while it is true. Without
`@multiple`, a new choice replaces a file still uploading: it leaves ember-file-upload's queue,
and what its upload resolves to is dropped.

</div>

## A zone of your own

`u.Dropzone` takes a block, in place of its icon, prompt and hint. It gets `zone.isDragging`,
which is true while files are dragged over the zone. The block names the zone's file input, so
say what a press on it does. Anything in it is inside the zone's `<label>`, so a press anywhere
opens the file picker: draw a "browse" button with `asButton` on a `<span>`, not a `<button>` of
its own.

<Example @name="file-upload-dropzone" @title="A zone of your own" />

## Disabled

`@disabled` disables the input, ignores drops, hides the remove and Retry buttons and dims the
zone.

<Example @name="file-upload-disabled" @title="Disabled" />

## RTL

Joinery's styles use logical properties, so File Upload lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): each file's media moves to
the right and its buttons to the left, and a progress bar fills from the right. Every string is
an argument, and `@locale` writes the sizes in the language of the page.

<Example @name="file-upload-rtl" @title="RTL" @dir="rtl" />

## API Reference

### FileUpload

| Argument             | Type                                | Default                     | What it does                                                                 |
| -------------------- | ----------------------------------- | --------------------------- | ---------------------------------------------------------------------------- |
| `@multiple`          | `boolean`                           | `false`                     | Whether it takes more than one file; without it, a new choice replaces it    |
| `@accept`            | `string`                            | any                         | Which files to take, as `<input accept>` reads it, for the picker and drops  |
| `@disabled`          | `boolean`                           | `false`                     | Whether it takes no files and removes none                                   |
| `@value`             | `T[]`                               |                             | The files (or upload results), controlled                                    |
| `@defaultValue`      | `T[]`                               | `[]`                        | The files it starts with, uncontrolled                                       |
| `@onValueChange`     | `(value: T[]) => void`              |                             | Called with the new list whenever a file is added or removed                 |
| `@upload`            | `(file: UploadFile) => Promise<T>`  |                             | Uploads each file as it is chosen; the value keeps what it resolves to       |
| `@queue`             | `Queue` (ember-file-upload's)       | its own                     | The queue to put the files in, such as one of the `file-queue` service's     |
| `@nameOf`            | `(value: T) => string`              | a file's or record's `name` | A value's name in the list                                                   |
| `@sizeOf`            | `(value: T) => number \| undefined` | its `size`                  | A value's size in bytes                                                      |
| `@previewOf`         | `(value: T) => string \| undefined` | an image file's contents    | A URL of an image of a value                                                 |
| `@locale`            | `string`                            | the browser's               | The locale sizes are written in                                              |
| `@id`                | `string`                            |                             | The file input's `id`, so a `<FieldLabel for>` names it                      |
| `@label`             | `string`                            |                             | The file input's `aria-label`, in place of the zone's text                   |
| `@required`          | `boolean`                           | `false`                     | Whether a file is required                                                   |
| `@invalid`           | `boolean`                           | `false`                     | `aria-invalid` on the input, and a destructive border on the zone            |
| `@describedBy`       | `string`                            |                             | The input's `aria-describedby`, such as a FieldDescription's id              |
| `@prompt`            | `string`                            | `Choose a file`             | The zone's call to action (`Choose files` with `@multiple`)                  |
| `@hint`              | `string`                            | `or drag and drop here`     | What follows it, while it takes files                                        |
| `@dropLabel`         | `string`                            | `Drop to add`               | What the zone says while files are dragged over it                           |
| `@description`       | `string`                            | `@accept`                   | A line under the hint                                                        |
| `@rejectedLabel`     | `(names: string[]) => string`       | `Not an accepted type: …`   | Names the files a choice or drop turned away, as `@accept` doesn't take them |
| `@leftOutLabel`      | `(names: string[]) => string`       | `One file at a time; …`     | Names the files a drop of several left out, without `@multiple`              |
| `@removeLabel`       | `(name: string) => string`          | `Remove cv.pdf`             | Names a file's remove button                                                 |
| `@retryLabel`        | `(name: string) => string`          | `Retry cv.pdf`              | Names a failed upload's retry button                                         |
| `@progressLabel`     | `(name: string) => string`          | `Uploading cv.pdf`          | Names a file's progress bar                                                  |
| `@uploadFailedLabel` | `string`                            | `Upload failed`             | The error a failed upload shows when it rejects without a message            |
| `@unknownKindLabel`  | `string`                            | `FILE`                      | The kind shown for a file whose name has no extension (`README`)             |
| `@name`              | `string`                            |                             | Its name, for `FileUploadHarness` (`data-test-jn-name`)                      |

`T` is `File` unless `@upload` says otherwise. It takes attributes on its element, `class`
included. `UploadFn<T>` is the type of `@upload`. `acceptsFile(file, accept)`,
`fileKind(name, unknown)` and `formatFileSize(bytes, locale)`, which it filters and labels with,
are exported too.

### The parts

| Part         | What it is                                                                                   |
| ------------ | -------------------------------------------------------------------------------------------- |
| `u.Dropzone` | ember-file-upload's `FileDropzone`: the dashed zone, its hidden input, and its status region |
| `u.List`     | An `ItemGroup` of the value's files, rendered while it holds one                             |
| `u.Queue`    | An `ItemGroup` of the uploads running or failed, rendered while there is one                 |

Each takes attributes, `class` included; `u.Dropzone`'s go on the zone. Its block gets
`{ isDragging, isSupported }`.

| Yield             | What it is                                                                           |
| ----------------- | ------------------------------------------------------------------------------------ |
| `u.files`         | The value's files as the list shows them: `value`, `name`, `kind`, `size`, `preview` |
| `u.uploads`       | The uploads in the queue: `name`, `progress`, `state`, `error`, `file`               |
| `u.isUploading`   | Whether an upload is running                                                         |
| `u.remove(value)` | Takes a value out of the list                                                        |
| `u.clear()`       | Empties the list                                                                     |
| `u.retry(upload)` | Uploads a failed file again (a running one, or any while disabled, it leaves alone)  |
| `u.queue`         | ember-file-upload's queue the files go into                                          |

### Data attributes

| Part   | Attribute           | Value                                                     |
| ------ | ------------------- | --------------------------------------------------------- |
| root   | `class`             | `jn-file-upload`                                          |
| root   | `data-slot`         | `file-upload`                                             |
| root   | `data-multiple`     | present with `@multiple`                                  |
| root   | `data-disabled`     | present while `@disabled`                                 |
| root   | `data-uploading`    | present while files upload                                |
| root   | `data-test-jn`      | `file-upload`                                             |
| zone   | `data-slot`         | `file-upload-dropzone`                                    |
| zone   | `data-dragging`     | present while files are dragged over it                   |
| zone   | `data-invalid`      | present with `@invalid`                                   |
| zone   | `data-test-jn-part` | `dropzone`                                                |
| input  | `data-test-jn-part` | `input`                                                   |
| status | `role`              | `status`, always there; empty until files are turned away |
| status | `data-test-jn-part` | `status` (its messages: `rejected`, `left-out`)           |
| list   | `data-test-jn-part` | `list` (the queue's: `queue`)                             |
| queue  | `aria-busy`         | `true` while files upload                                 |
| a file | `data-slot`         | `item` (an outlined, small Item)                          |
| a file | `data-state`        | `done` in the list; `uploading` or `error` in the queue   |
| a file | `data-test-jn-name` | the file's name                                           |

## Keyboard interactions

| Key              | What it does                                                   |
| ---------------- | -------------------------------------------------------------- |
| `Tab`            | Moves focus to the zone's file input, then each file's buttons |
| `Enter`, `Space` | On the input, opens the file picker; on a button, presses it   |

Drag and drop has no keyboard equivalent, so the file picker is always there as the way to
choose files. Removing a file moves focus to the remove button of the row that takes its place
(or the row before it), and to the file input once the list is empty. Retry takes a failed
row's buttons away while it uploads again, so it moves focus to the Retry button of the next
failed row (or the one before it), and to the file input when none is left. Rows stay put while
other files come and go, so focus is never lost.

## Accessibility

- The zone's text is the accessible name of its file input, after a `<FieldLabel for>`'s;
  `@label` names it instead. The input stays in the tab order, and the zone shows the focus ring
  while it has focus.
- The list and the queue are lists (`role="list"`), and each file a list item. A preview is
  decorative (`alt=""`): the name beside it says what it is.
- Each remove and retry button is named for its file, and each progress bar too, with the
  percentage as its value.
- The files a choice or drop turned away are named in a status region (`role="status"`) that is
  always in the page, empty until then, so screen readers announce what goes in it.
- While files upload, the queue is `aria-busy`; the zone, the list and the status region are
  not, so their changes are announced as they happen.

## Testing

`FileUploadHarness`, from `@ember-joinery/file-upload/test-support`, chooses and drops files,
and reads and removes what the list and the queue show. `select` and `drop` don't wait for
`@upload`; `waitForUploads()` does.

```ts
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'

const attachments = new FileUploadHarness('attachments')
await attachments.select(new File(['%PDF'], 'cv.pdf', { type: 'application/pdf' }))
await attachments.drop(photo)
assert.deepEqual(attachments.uploading, ['cv.pdf', 'photo.png'])
await attachments.waitForUploads()
assert.deepEqual(attachments.files, ['cv.pdf', 'photo.png'])
assert.strictEqual(attachments.file('cv.pdf').details, 'PDF · 184.3 kB')
await attachments.remove('cv.pdf')
```

| Member             | What it is                                                          |
| ------------------ | ------------------------------------------------------------------- |
| `dropzone`         | The zone                                                            |
| `input`            | Its hidden file input                                               |
| `text`             | What the zone says                                                  |
| `label`            | The input's `aria-label`, else the zone's text                      |
| `accept`           | Which files it takes, or `''`                                       |
| `isMultiple`       | Whether it takes more than one                                      |
| `isDisabled`       | Whether it takes none                                               |
| `isDragging`       | Whether files are dragged over it                                   |
| `isFocused`        | Whether its input has focus                                         |
| `isUploading`      | Whether an upload is running (the queue's `aria-busy`)              |
| `status`           | The zone's status region                                            |
| `rejected`         | What it says about the files `@accept` turned away                  |
| `leftOut`          | What it says about the files a drop left out, without `@multiple`   |
| `list`, `queue`    | The list and the queue, or `null` while they hold nothing           |
| `items`            | A `FileUploadItemHarness` for every row, the list's and the queue's |
| `files`            | The names in the list                                               |
| `uploading`        | The names uploading                                                 |
| `failed`           | The names whose upload failed                                       |
| `file(name)`       | The row of the file with this name                                  |
| `select(...files)` | Chooses files, as the file picker does                              |
| `drag(...files)`   | Drags files over the zone                                           |
| `leave()`          | Drags them away again                                               |
| `drop(...files)`   | Drops files on the zone                                             |
| `remove(name)`     | Presses the remove button of that file                              |
| `retry(name)`      | Presses Retry on that failed upload                                 |
| `waitForUploads()` | Waits until nothing is uploading                                    |

`FileUploadItemHarness` extends [`ItemHarness`](/components/item.md) with `fileName`, `state`
(`done`, `uploading` or `error`), `details` (the kind and size, or the error), `preview` and
`hasPreview`, `progress` and `progressBar` (a `ProgressHarness`), `canRemove`, `removeButton`
and `retryButton`, and `remove()` and `retry()`.

## Built on

[ember-file-upload](https://github.com/adopted-ember-addons/ember-file-upload) 10: its
`FileDropzone` and `Queue`, whose `selectFile` modifier takes the file picker's files and whose
`UploadFile` `@upload` receives. Each `FileUpload` makes a queue of its own, so it needs no
service and a test's files never meet another's; `@queue` hands it one of the library's
`file-queue` service's instead, so an app can see every upload in one place.

As ember-file-upload does, a drop takes only files dragged from the desktop, not images dragged
from another page. Its modifier empties the input after each choice, so the same file can be
chosen twice in a row; the input doesn't send the files with a native `<form>`, so keep the
value and send it yourself.

Formwright's `@ember-formwright/file-upload` offers the same as the `file` and `files` controls;
this is the standalone component, for use without a form library. The examples on this page port
Formwright's guide examples for it.
