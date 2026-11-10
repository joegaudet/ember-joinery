# @ember-joinery/file-upload

File uploads in shadcn/ui's look for Ember, an opt-in add-on to
[Joinery](https://joegaudet.com/ember-joinery/): a drop zone, the list of chosen files (with
previews, sizes and remove buttons) and an upload queue with a progress bar for each file, on
[ember-file-upload](https://ember-file-upload.pages.dev) 10.

> **Pre-release.** Nothing is published yet; see the
> [repository](https://github.com/joegaudet/ember-joinery#readme).

```bash
npm install @ember-joinery/file-upload @ember-joinery/ember tracked-built-ins
```

ember-file-upload comes with it; `tracked-built-ins` is its peer. Nothing in Joinery's core
packages imports this one, so an app that doesn't install it doesn't load ember-file-upload. It
ships no CSS of its own: `@ember-joinery/ember`'s `joinery.css` (or any of its styles) styles its
parts, as it does every Joinery component. shadcn/ui has no file upload, so it is drawn from the
nearest shadcn parts: Empty for the zone, an outlined Item for each file, with Button and
Progress.

```gts
import { FileUpload } from '@ember-joinery/file-upload'

<template>
  {{! keeps the Files: one, or many with @multiple }}
  <FileUpload @accept=".pdf" @onValueChange={{this.setResume}} />

  {{! uploads each file as it is chosen, and keeps what @upload resolves to }}
  <FileUpload @multiple={{true}} @upload={{this.upload}} @onValueChange={{this.setAttachments}} />
</template>
```

```ts
upload = async (file: UploadFile) => {
  const response = await file.upload('/api/attachments') // ember-file-upload's UploadFile
  return response.json()
}
```

The value is always a list (`@value`, `@defaultValue`, `@onValueChange`): of `File`s, or, with
`@upload`, of what each upload resolved to. Without `@multiple` it holds one at most, and a new
choice replaces it. `@accept` filters the picker and drops alike, and the zone names the files a
drop turned away. Until an upload settles, its file is in the queue with a Progress bar that
follows `file.progress`; a failed one shows its error, with Retry and remove buttons. With a
block, lay out the parts yourself (`u.Dropzone`, `u.List`, `u.Queue`). Every string is an
argument with an English default, and the parts flip right to left.

Its harness, `FileUploadHarness`, is in `@ember-joinery/file-upload/test-support`:

```ts
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'

const attachments = new FileUploadHarness('attachments')
await attachments.select(new File(['%PDF'], 'cv.pdf', { type: 'application/pdf' }))
await attachments.drop(photo)
await attachments.waitForUploads() // select and drop don't wait for @upload
assert.deepEqual(attachments.files, ['cv.pdf', 'photo.png'])
await attachments.remove('cv.pdf')
```

Full documentation: the File Upload page of the guide at
**https://joegaudet.com/ember-joinery/guide/**. Built on
[ember-file-upload](https://github.com/adopted-ember-addons/ember-file-upload) (MIT); design
from [shadcn/ui](https://ui.shadcn.com/) (MIT).
