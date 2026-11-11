import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, focus, render, rerender, settled, triggerEvent } from '@ember/test-helpers'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Queue, type UploadFile } from 'ember-file-upload'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { FieldDescription, FieldLabel, Field } from '@ember-joinery/ember'
import { IconHarness, tab, tabOrder } from '@ember-joinery/test-support'
import { FileUpload, acceptsFile, fileKind, formatFileSize } from '@ember-joinery/file-upload'
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'

/** A colour as the browser resolves it, for comparing with a token. */
function resolved(color: string): string {
  const probe = document.createElement('span')
  probe.style.color = color
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe).color
  probe.remove()
  return value
}

/** Whether a URL still loads: a revoked object URL doesn't. */
async function loads(url: string): Promise<boolean> {
  try {
    await (await fetch(url)).blob()
    return true
  } catch {
    return false
  }
}

/** Waits for the zone's colour transitions (`transition-colors`) to end. */
async function transitioned(element: Element): Promise<void> {
  await Promise.all(element.getAnimations().map(animation => animation.finished))
}

const file = (name: string, bytes: number, type: string) =>
  new File([new Uint8Array(bytes)], name, { type })

// A 1×1 PNG, so a preview has a real image to show.
const PNG = Uint8Array.from(
  atob(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  ),
  c => c.charCodeAt(0),
)
const photo = () => new File([PNG], 'photo.png', { type: 'image/png' })

/** An upload the test settles by hand, moving its progress as it likes. */
class Uploads {
  pending = new Map<
    string,
    { file: UploadFile; resolve: (v: unknown) => void; reject: (e: unknown) => void }
  >()

  upload = (upload: UploadFile): Promise<unknown> =>
    new Promise((resolve, reject) => {
      this.pending.set(upload.name, { file: upload, resolve, reject })
    })

  async progress(name: string, progress: number): Promise<void> {
    this.pending.get(name)!.file.progress = progress
    await settled()
  }

  async resolve(name: string, value: unknown): Promise<void> {
    this.pending.get(name)!.resolve(value)
    this.pending.delete(name)
    await settled()
  }

  async reject(name: string, error: unknown): Promise<void> {
    this.pending.get(name)!.reject(error)
    this.pending.delete(name)
    await settled()
  }
}

module('Integration | components | file-upload', function (hooks) {
  setupRenderingTest(hooks)

  test('a dashed drop zone in Empty’s look, around a visually hidden file input', async function (assert) {
    await render(<template><FileUpload @name="resume" @accept=".pdf" /></template>)
    const upload = new FileUploadHarness('resume')

    assert
      .dom(upload.element)
      .hasClass('jn-file-upload')
      .hasAttribute('data-slot', 'file-upload')
      .doesNotHaveAttribute('data-multiple')
      .doesNotHaveAttribute('aria-busy')
    assert
      .dom(upload.dropzone)
      .hasClass('jn-file-upload-dropzone')
      .hasAttribute('data-slot', 'file-upload-dropzone')
    const zone = getComputedStyle(upload.dropzone)
    assert.strictEqual(zone.borderTopStyle, 'dashed')
    assert.strictEqual(zone.borderTopWidth, '1px')
    assert.strictEqual(zone.borderTopColor, resolved('var(--input)'))
    assert.strictEqual(zone.borderTopLeftRadius, '10px', 'rounded-lg')
    const label = upload.dropzone.querySelector('label')!
    assert.strictEqual(getComputedStyle(label).paddingTop, '24px', 'p-6')
    assert.strictEqual(getComputedStyle(label).cursor, 'pointer')

    const media = upload.dropzone.querySelector<HTMLElement>(
      '[data-slot="file-upload-dropzone-media"]',
    )!
    const box = getComputedStyle(media)
    assert.strictEqual(box.width, '32px', "Empty's icon media: Nova's size-8")
    assert.strictEqual(box.backgroundColor, resolved('var(--muted)'))
    assert.true(upload.find(IconHarness).isDecorative)
    const title = upload.dropzone.querySelector('[data-slot="file-upload-dropzone-title"]')!
    assert.strictEqual(getComputedStyle(title).fontWeight, '500', "Empty's title")
    assert.notStrictEqual(
      getComputedStyle(title).color,
      resolved('var(--muted-foreground)'),
      'the title in the text colour, the hint muted',
    )
    const hint = upload.dropzone.querySelector('[data-slot="file-upload-dropzone-hint"]')!
    assert.strictEqual(getComputedStyle(hint).color, resolved('var(--muted-foreground)'))

    assert.strictEqual(upload.text, 'Choose a file or drag and drop here .pdf')
    assert.strictEqual(upload.input.type, 'file')
    assert.strictEqual(upload.accept, '.pdf')
    assert.false(upload.isMultiple)
    assert.false(upload.isDisabled)
    const input = getComputedStyle(upload.input)
    assert.strictEqual(input.position, 'absolute', 'sr-only')
    assert.strictEqual(input.width, '1px')
    assert.strictEqual(upload.list, null, 'no list while there is nothing in it')
    assert.strictEqual(upload.queue, null)
    assert
      .dom(upload.status)
      .hasAttribute('role', 'status')
      .hasText('', 'a live region already there, so what goes in it is announced')
    assert.strictEqual(upload.status.getBoundingClientRect().height, 0, 'empty, it takes no room')
    assert.strictEqual(upload.rejected, undefined)
    await a11yAudit()
  })

  test('acceptsFile, fileKind and formatFileSize, which it filters and labels with', async function (assert) {
    const pdf = file('CV.PDF', 1, 'application/pdf')
    assert.true(acceptsFile(pdf, '.pdf'))
    assert.true(acceptsFile(pdf, 'image/*, application/pdf'))
    assert.false(acceptsFile(pdf, 'image/*'))
    assert.true(acceptsFile(pdf, ''), 'an empty list takes every file')
    assert.true(acceptsFile(photo(), 'image/*'))
    assert.strictEqual(fileKind('archive.tar.gz'), 'GZ')
    assert.strictEqual(fileKind('README'), 'FILE')
    assert.strictEqual(fileKind('.env'), 'FILE')
    assert.strictEqual(fileKind('README', 'ملف'), 'ملف', 'the word for no extension is an argument')
    assert.strictEqual(formatFileSize(920), '920 bytes')
    assert.strictEqual(formatFileSize(184_320), '184.3 kB')
    assert.strictEqual(formatFileSize(1_240_000), '1.2 MB')
    assert.strictEqual(formatFileSize(1_240_000, 'de'), '1,2 MB')
    await render(<template><FileUpload @accept="image/*, application/pdf" /></template>)
    assert.strictEqual(new FileUploadHarness().accept, 'image/*, application/pdf')
    await a11yAudit()
  })

  test('one file: a choice is listed as an Item, and the next replaces it', async function (assert) {
    const changes: string[][] = []
    const change = (files: File[]) => changes.push(files.map(f => f.name))
    await render(<template><FileUpload @name="resume" @onValueChange={{change}} /></template>)
    const upload = new FileUploadHarness('resume')

    await upload.select(file('cv.pdf', 184_320, 'application/pdf'))
    assert.deepEqual(upload.files, ['cv.pdf'])
    assert.deepEqual(changes, [['cv.pdf']])
    const cv = upload.file('cv.pdf')
    assert.strictEqual(cv.state, 'done')
    assert.strictEqual(cv.details, 'PDF · 184.3 kB')
    assert.strictEqual(cv.variant, 'outline')
    assert.strictEqual(cv.size, 'sm')
    assert.false(cv.hasPreview, 'a PDF shows an icon')
    assert.strictEqual(cv.mediaVariant, 'image', "the media is the Item's image box")
    assert.dom(cv.element).hasAttribute('role', 'listitem')
    assert.dom(upload.list!).hasAttribute('role', 'list').hasClass('jn-item-group')
    assert.strictEqual(cv.removeButton.label, 'Remove cv.pdf')
    assert.strictEqual(getComputedStyle(cv.media).backgroundColor, resolved('var(--muted)'))

    await upload.select(file('cv-2026.pdf', 2_400_000, 'application/pdf'))
    assert.deepEqual(upload.files, ['cv-2026.pdf'], 'a new choice replaces the file')
    assert.strictEqual(upload.file('cv-2026.pdf').details, 'PDF · 2.4 MB')
    assert.deepEqual(changes, [['cv.pdf'], ['cv-2026.pdf']])
    await a11yAudit()
  })

  test('many files: choices and drops add up, and @accept turns files away', async function (assert) {
    await render(
      <template><FileUpload @name="samples" @multiple={{true}} @accept="image/*,.pdf" /></template>,
    )
    const upload = new FileUploadHarness('samples')
    assert.true(upload.isMultiple)
    assert.dom(upload.element).hasAttribute('data-multiple')
    assert.strictEqual(upload.text, 'Choose files or drag and drop here image/*,.pdf')

    await upload.select(file('note-g.pdf', 96_400, 'application/pdf'))
    await upload.drop(photo(), file('setup.exe', 10, 'application/x-msdownload'))
    assert.deepEqual(upload.files, ['note-g.pdf', 'photo.png'])
    assert.strictEqual(upload.rejected, 'Not an accepted type: setup.exe')
    assert.true(upload.status.contains(upload.queryPart('rejected')), 'in the status region')
    assert.strictEqual(
      getComputedStyle(upload.queryPart('rejected')!).color,
      resolved('var(--destructive)'),
    )
    assert.strictEqual(
      getComputedStyle(upload.status).paddingBottom,
      '20px',
      'pb-5, with a message',
    )

    const preview = upload.file('photo.png')
    assert.true(preview.hasPreview, 'an image shows a preview of itself')
    assert.true(preview.preview!.startsWith('blob:'))
    assert.dom(preview.media.querySelector('img')!).hasAttribute('alt', '')

    await upload.select(file('sketch.svg', 400, 'image/svg+xml'))
    assert.deepEqual(upload.files, ['note-g.pdf', 'photo.png', 'sketch.svg'])
    assert.strictEqual(upload.rejected, undefined, 'a choice clears the last drop’s message')
    await a11yAudit()
  })

  test('the file picker’s “All files” lets anything through, so a choice is filtered and named too', async function (assert) {
    await render(<template><FileUpload @multiple={{true}} @accept=".pdf" /></template>)
    const upload = new FileUploadHarness()
    await upload.select(file('cv.pdf', 10, 'application/pdf'), file('setup.exe', 10, ''))
    assert.deepEqual(upload.files, ['cv.pdf'])
    assert.strictEqual(upload.rejected, 'Not an accepted type: setup.exe')
    await upload.select(file('notes.pdf', 10, 'application/pdf'))
    assert.strictEqual(upload.rejected, undefined, 'the next choice starts afresh')
    await a11yAudit()
  })

  test('one file: a drop or choice of several takes the first, and names the rest as left out', async function (assert) {
    await render(<template><FileUpload @name="resume" @accept=".pdf" /></template>)
    const upload = new FileUploadHarness('resume')
    await upload.drop(
      file('a.pdf', 10, 'application/pdf'),
      file('b.pdf', 10, 'application/pdf'),
      file('c.pdf', 10, 'application/pdf'),
    )
    assert.deepEqual(upload.files, ['a.pdf'])
    assert.strictEqual(upload.leftOut, 'One file at a time; left out: b.pdf, c.pdf')
    assert.strictEqual(upload.rejected, undefined)
    assert.true(upload.status.contains(upload.queryPart('left-out')), 'in the status region')

    await upload.drop(file('setup.exe', 10, ''), file('d.pdf', 10, 'application/pdf'))
    assert.deepEqual(upload.files, ['a.pdf'], 'the first is turned away, so nothing is taken')
    assert.strictEqual(upload.rejected, 'Not an accepted type: setup.exe')
    assert.strictEqual(upload.leftOut, 'One file at a time; left out: d.pdf')

    // A picker without `multiple` gives one file; a script (or a test) can still give several.
    await triggerEvent(upload.input, 'change', {
      files: [file('e.pdf', 10, 'application/pdf'), file('f.pdf', 10, 'application/pdf')],
    })
    assert.deepEqual(upload.files, ['e.pdf'])
    assert.strictEqual(upload.leftOut, 'One file at a time; left out: f.pdf')
    assert.strictEqual(upload.rejected, undefined)
    await a11yAudit()
  })

  test('dragging files over the zone turns it --primary and says so', async function (assert) {
    await render(<template><FileUpload @multiple={{true}} /></template>)
    const upload = new FileUploadHarness()
    await upload.drag(photo())
    assert.true(upload.isDragging)
    assert.strictEqual(upload.text, 'Drop to add')
    await transitioned(upload.dropzone)
    assert.strictEqual(getComputedStyle(upload.dropzone).borderTopColor, resolved('var(--primary)'))
    await upload.leave()
    assert.false(upload.isDragging)
    assert.strictEqual(upload.text, 'Choose files or drag and drop here')
    await upload.drag(photo())
    await upload.drop(photo())
    assert.false(upload.isDragging, 'a drop ends the drag')
    assert.deepEqual(upload.files, ['photo.png'])
    await a11yAudit()
  })

  test('controlled and uncontrolled', async function (assert) {
    class State {
      @tracked files: File[] = [file('a.txt', 10, 'text/plain')]
    }
    const state = new State()
    const heard: string[][] = []
    const keep = (files: File[]) => {
      heard.push(files.map(f => f.name))
      state.files = files
    }
    const ignore = (files: File[]) => heard.push(files.map(f => f.name))
    const start = [file('b.txt', 10, 'text/plain')]
    await render(
      <template>
        <FileUpload
          @name="controlled"
          @multiple={{true}}
          @value={{state.files}}
          @onValueChange={{keep}}
        />
        <FileUpload
          @name="refused"
          @multiple={{true}}
          @value={{state.files}}
          @onValueChange={{ignore}}
        />
        <FileUpload @name="uncontrolled" @multiple={{true}} @defaultValue={{start}} />
      </template>,
    )
    const controlled = new FileUploadHarness('controlled')
    const refused = new FileUploadHarness('refused')
    const uncontrolled = new FileUploadHarness('uncontrolled')
    assert.deepEqual(controlled.files, ['a.txt'])
    assert.deepEqual(uncontrolled.files, ['b.txt'])

    await refused.select(file('c.txt', 10, 'text/plain'))
    assert.deepEqual(heard, [['a.txt', 'c.txt']])
    assert.deepEqual(refused.files, ['a.txt'], 'controlled: it shows @value, whatever it heard')

    await controlled.select(file('d.txt', 10, 'text/plain'))
    assert.deepEqual(controlled.files, ['a.txt', 'd.txt'])
    assert.deepEqual(refused.files, ['a.txt', 'd.txt'], 'both follow the shared value')
    state.files = []
    await rerender()
    assert.deepEqual(controlled.files, [])

    await uncontrolled.remove('b.txt')
    assert.deepEqual(uncontrolled.files, [])
    await a11yAudit()
  })

  test('removing a file moves focus to the row that takes its place, then to the input', async function (assert) {
    const start = [
      file('one.txt', 1, 'text/plain'),
      file('two.txt', 2, 'text/plain'),
      file('three.txt', 3, 'text/plain'),
    ]
    await render(<template><FileUpload @multiple={{true}} @defaultValue={{start}} /></template>)
    const upload = new FileUploadHarness()

    await upload.remove('two.txt')
    assert.deepEqual(upload.files, ['one.txt', 'three.txt'])
    assert.dom(upload.file('three.txt').removeButton.element).isFocused()
    await upload.remove('three.txt')
    assert.dom(upload.file('one.txt').removeButton.element).isFocused('the row before, at the end')
    await upload.remove('one.txt')
    assert.true(upload.isFocused, 'the input, once the list is empty')
    await a11yAudit()
  })

  test('Tab reaches the input, which rings the zone, then each remove button', async function (assert) {
    const start = [file('one.txt', 1, 'text/plain'), file('two.txt', 2, 'text/plain')]
    await render(<template><FileUpload @multiple={{true}} @defaultValue={{start}} /></template>)
    const upload = new FileUploadHarness()
    assert.deepEqual(
      tabOrder(upload.element),
      [
        upload.input,
        upload.file('one.txt').removeButton.element,
        upload.file('two.txt').removeButton.element,
      ],
      'the input, then the remove buttons in order',
    )
    await tab()
    assert.true(upload.isFocused)
    await transitioned(upload.dropzone)
    const focused = getComputedStyle(upload.dropzone)
    assert.notStrictEqual(focused.boxShadow, 'none', 'has-[:focus-visible]:ring-3')
    assert.strictEqual(focused.borderTopColor, resolved('var(--ring)'))
    await tab()
    assert.dom(upload.file('one.txt').removeButton.element).isFocused()
    await a11yAudit()
  })

  test('@upload: each file is queued with a Progress bar, then listed as what it resolved to', async function (assert) {
    const uploads = new Uploads()
    const values: unknown[][] = []
    const change = (value: unknown[]) => values.push(value)
    await render(
      <template>
        <FileUpload
          @name="attachments"
          @multiple={{true}}
          @upload={{uploads.upload}}
          @onValueChange={{change}}
        />
      </template>,
    )
    const upload = new FileUploadHarness('attachments')

    await upload.select(file('notes.txt', 1_200, 'text/plain'), photo())
    assert.deepEqual(upload.uploading, ['notes.txt', 'photo.png'])
    assert.deepEqual(upload.files, [])
    assert.true(upload.isUploading)
    assert.dom(upload.element).hasAttribute('data-uploading').doesNotHaveAttribute('aria-busy')
    assert.dom(upload.queue!).hasAttribute('aria-busy', 'true', 'the queue is busy, not the whole')
    const notes = upload.file('notes.txt')
    assert.strictEqual(notes.state, 'uploading')
    assert.strictEqual(notes.details, 'TXT · 1.2 kB')
    assert.strictEqual(notes.progress, 0)
    assert.strictEqual(notes.progressBar.label, 'Uploading notes.txt')
    assert.false(notes.canRemove, 'an upload runs to its end')
    assert.true(upload.file('photo.png').hasPreview, 'an image previews while it uploads')
    assert.dom(upload.queue!).hasAttribute('role', 'list')
    await a11yAudit()

    await uploads.progress('notes.txt', 40)
    assert.strictEqual(notes.progress, 40)
    assert.strictEqual(notes.progressBar.valueText, '40%')
    const bar = notes.progressBar.element.getBoundingClientRect()
    const row = notes.element.getBoundingClientRect()
    assert.true(bar.width > row.width * 0.8, 'the bar runs across the foot of the row')

    await uploads.resolve('notes.txt', { id: 7, name: 'notes.txt', size: 1_200 })
    assert.deepEqual(upload.files, ['notes.txt'], 'listed as the record it resolved to')
    assert.deepEqual(upload.uploading, ['photo.png'])
    assert.deepEqual(values, [[{ id: 7, name: 'notes.txt', size: 1_200 }]])
    assert.strictEqual(upload.file('notes.txt').details, 'TXT · 1.2 kB')

    await uploads.resolve('photo.png', { id: 8, name: 'photo.png' })
    assert.deepEqual(upload.files, ['notes.txt', 'photo.png'])
    assert.false(upload.isUploading)
    assert.dom(upload.element).doesNotHaveAttribute('data-uploading')
    assert.strictEqual(upload.queue, null)
    assert.strictEqual(upload.file('photo.png').details, 'PNG', 'a record with no size')
    await a11yAudit()
  })

  test('a failed upload shows its error, and can be retried or removed', async function (assert) {
    const uploads = new Uploads()
    await render(<template><FileUpload @multiple={{true}} @upload={{uploads.upload}} /></template>)
    const upload = new FileUploadHarness()
    await upload.select(file('huge.mov', 2_000_000, 'video/quicktime'), file('b.txt', 2, ''))
    await uploads.reject('huge.mov', new Error('Too large for this demo'))
    await uploads.reject('b.txt', undefined)
    assert.deepEqual(upload.failed, ['huge.mov', 'b.txt'])
    assert.false(upload.isUploading)
    const huge = upload.file('huge.mov')
    assert.strictEqual(huge.state, 'error')
    assert.strictEqual(huge.details, 'Too large for this demo')
    assert.strictEqual(upload.file('b.txt').details, 'Upload failed', 'without a message')
    assert.strictEqual(huge.retryButton.label, 'Retry huge.mov')
    assert.strictEqual(huge.removeButton.label, 'Remove huge.mov')
    assert.strictEqual(huge.progress, null)
    assert.strictEqual(
      getComputedStyle(huge.part('description')).color,
      resolved('var(--destructive)'),
      'in --destructive',
    )
    await a11yAudit()

    await focus(huge.retryButton.element)
    await upload.retry('huge.mov')
    assert.deepEqual(upload.uploading, ['huge.mov'], 'uploading again')
    assert.false(huge.canRemove, 'its buttons go while it uploads')
    assert
      .dom(upload.file('b.txt').retryButton.element)
      .isFocused('so focus moves to the next row’s Retry, not to <body>')
    await uploads.resolve('huge.mov', file('huge.mov', 2_000_000, 'video/quicktime'))
    assert.deepEqual(upload.files, ['huge.mov'])

    await upload.remove('b.txt')
    assert.deepEqual(upload.failed, [])
    assert
      .dom(upload.file('huge.mov').removeButton.element)
      .isFocused('focus moves to a remove button that is left')
    await a11yAudit()
  })

  test('Retry moves focus to the nearest failed row’s Retry, then to the input', async function (assert) {
    const uploads = new Uploads()
    await render(<template><FileUpload @multiple={{true}} @upload={{uploads.upload}} /></template>)
    const upload = new FileUploadHarness()
    await upload.select(
      file('a.txt', 1, 'text/plain'),
      file('b.txt', 1, 'text/plain'),
      file('c.txt', 1, 'text/plain'),
    )
    for (const name of ['a.txt', 'b.txt', 'c.txt']) await uploads.reject(name, 'Offline')
    assert.deepEqual(upload.failed, ['a.txt', 'b.txt', 'c.txt'])

    await focus(upload.file('b.txt').retryButton.element)
    await upload.retry('b.txt')
    assert.dom(upload.file('c.txt').retryButton.element).isFocused('the row after it')
    await upload.retry('c.txt')
    assert.dom(upload.file('a.txt').retryButton.element).isFocused('the row before it, at the end')
    await upload.retry('a.txt')
    assert.deepEqual(upload.uploading, ['a.txt', 'b.txt', 'c.txt'])
    assert.true(upload.isFocused, 'the input, once no row has a button')
    await a11yAudit()
  })

  test('a row stays put while others change, so its focus and its preview do', async function (assert) {
    const uploads = new Uploads()
    const start = [photo()]
    await render(
      <template>
        <FileUpload @multiple={{true}} @defaultValue={{start}} @upload={{uploads.upload}} />
      </template>,
    )
    const upload = new FileUploadHarness()
    const row = upload.file('photo.png').element
    const image = upload.file('photo.png').media.querySelector('img')!
    const remove = upload.file('photo.png').removeButton.element
    await focus(remove)
    await upload.select(file('notes.txt', 10, 'text/plain'))
    await uploads.resolve('notes.txt', file('notes.txt', 10, 'text/plain'))
    assert.deepEqual(upload.files, ['photo.png', 'notes.txt'])
    assert.strictEqual(upload.file('photo.png').element, row, 'the same row')
    assert.strictEqual(upload.file('photo.png').media.querySelector('img'), image, 'and image')
    assert.dom(remove).isFocused('focus stays on its remove button')
    await a11yAudit()
  })

  test('@disabled: the input is disabled, drops are ignored and nothing can be removed', async function (assert) {
    const start = [file('cv.pdf', 10, 'application/pdf')]
    await render(<template><FileUpload @disabled={{true}} @defaultValue={{start}} /></template>)
    const upload = new FileUploadHarness()
    assert.true(upload.isDisabled)
    assert.dom(upload.element).hasAttribute('data-disabled')
    assert.strictEqual(getComputedStyle(upload.dropzone).opacity, '0.5')
    assert.false(upload.file('cv.pdf').canRemove)
    await upload.drag(photo())
    assert.false(upload.isDragging)
    await upload.drop(photo())
    assert.deepEqual(upload.files, ['cv.pdf'])
    assert.strictEqual(upload.rejected, undefined)
    await a11yAudit()
  })

  test('@disabled: a failed upload shows neither Retry nor remove, and u.retry does nothing', async function (assert) {
    class State {
      @tracked disabled = false
    }
    const state = new State()
    const uploads = new Uploads()
    await render(
      <template>
        <FileUpload @upload={{uploads.upload}} @disabled={{state.disabled}} as |u|>
          <u.Dropzone />
          <u.Queue />
          {{#each u.uploads as |entry|}}
            <button type="button" data-test-retry {{on "click" (fn u.retry entry)}}>Again</button>
          {{/each}}
        </FileUpload>
      </template>,
    )
    const upload = new FileUploadHarness()
    await upload.select(file('cv.pdf', 10, 'application/pdf'))
    await uploads.reject('cv.pdf', 'Offline')
    assert.true(upload.file('cv.pdf').canRemove)
    state.disabled = true
    await rerender()
    const cv = upload.file('cv.pdf')
    assert.false(cv.canRemove, 'no remove button')
    assert.false(cv.retryButton.exists, 'and no Retry')
    await click('[data-test-retry]')
    assert.deepEqual(upload.failed, ['cv.pdf'], 'still failed: a disabled upload retries nothing')
    await a11yAudit()
  })

  test('in a Field: @id, @invalid and @describedBy reach the input', async function (assert) {
    await render(
      <template>
        <Field @invalid={{true}}>
          <FieldLabel for="resume-input">Résumé</FieldLabel>
          <FileUpload
            @id="resume-input"
            @label="Résumé"
            @invalid={{true}}
            @required={{true}}
            @describedBy="resume-hint"
          />
          <FieldDescription id="resume-hint">A PDF, up to 5 MB.</FieldDescription>
        </Field>
      </template>,
    )
    const upload = new FileUploadHarness()
    assert
      .dom(upload.input)
      .hasAttribute('id', 'resume-input')
      .hasAttribute('aria-label', 'Résumé')
      .hasAttribute('aria-invalid', 'true')
      .hasAttribute('aria-describedby', 'resume-hint')
      .isRequired()
    assert.strictEqual(upload.label, 'Résumé', "@label names it, not the zone's text")
    assert.dom(upload.dropzone).hasAttribute('data-invalid')
    assert.strictEqual(
      getComputedStyle(upload.dropzone).borderTopColor,
      resolved('var(--destructive)'),
    )
    await a11yAudit()
  })

  test('the yielded u.remove, u.retry and u.isUploading', async function (assert) {
    const uploads = new Uploads()
    const start = [file('kept.txt', 1, 'text/plain')]
    await render(
      <template>
        <FileUpload @multiple={{true}} @upload={{uploads.upload}} @defaultValue={{start}} as |u|>
          <u.Dropzone />
          <u.List />
          <u.Queue />
          <p data-test-busy>{{if u.isUploading "Uploading…" "Idle"}}</p>
          {{#each u.files as |entry|}}
            <button type="button" data-test-drop {{on "click" (fn u.remove entry.value)}}>
              Drop
              {{entry.name}}
            </button>
          {{/each}}
          {{#each u.uploads as |entry|}}
            <button type="button" data-test-again {{on "click" (fn u.retry entry)}}>
              Again
              {{entry.name}}
            </button>
          {{/each}}
        </FileUpload>
      </template>,
    )
    const upload = new FileUploadHarness()
    assert.dom('[data-test-busy]').hasText('Idle')
    await click('[data-test-drop]')
    assert.deepEqual(upload.files, [], 'u.remove takes a value out')

    await upload.select(file('notes.txt', 1, 'text/plain'))
    assert.dom('[data-test-busy]').hasText('Uploading…')
    await click('[data-test-again]')
    assert.deepEqual(upload.uploading, ['notes.txt'], 'u.retry leaves a running upload alone')
    await uploads.reject('notes.txt', 'Offline')
    assert.dom('[data-test-busy]').hasText('Idle')
    await click('[data-test-again]')
    assert.deepEqual(upload.uploading, ['notes.txt'], 'and sends a failed one again')
    assert.dom('[data-test-again]').isFocused('focus stays on a button that is still there')
    await uploads.resolve('notes.txt', 'notes.txt')
    assert.deepEqual(upload.files, ['notes.txt'])
    await a11yAudit()
  })

  test('one file, with @upload: a new choice replaces the one uploading, which leaves the queue', async function (assert) {
    const uploads = new Uploads()
    const queue = new Queue({ name: 'resume', fileQueue: undefined as never })
    const values: unknown[][] = []
    const change = (value: unknown[]) => values.push(value)
    await render(
      <template>
        <FileUpload @queue={{queue}} @upload={{uploads.upload}} @onValueChange={{change}} />
      </template>,
    )
    const upload = new FileUploadHarness()
    await upload.select(photo())
    const preview = upload.file('photo.png').preview!
    assert.true(await loads(preview))
    assert.deepEqual(
      queue.files.map(f => f.name),
      ['photo.png'],
    )

    await upload.select(file('cv.pdf', 10, 'application/pdf'))
    assert.deepEqual(upload.uploading, ['cv.pdf'], 'the new file replaces it')
    assert.deepEqual(
      queue.files.map(f => f.name),
      ['cv.pdf'],
      "and the old one leaves ember-file-upload's queue",
    )
    assert.false(await loads(preview), 'its preview is revoked')

    await uploads.resolve('photo.png', 'photo.png')
    assert.deepEqual(values, [], 'what the replaced upload resolves to is dropped')
    assert.deepEqual(upload.uploading, ['cv.pdf'])
    await uploads.resolve('cv.pdf', 'cv.pdf')
    assert.deepEqual(upload.files, ['cv.pdf'])
    assert.deepEqual(values, [['cv.pdf']])
    assert.deepEqual(queue.files, [])
    await a11yAudit()
  })

  test('controlled: a removal the caller refuses keeps the row’s preview', async function (assert) {
    const kept = [photo()]
    const heard: string[][] = []
    const ignore = (files: File[]) => heard.push(files.map(f => f.name))
    await render(
      <template>
        <FileUpload @multiple={{true}} @value={{kept}} @onValueChange={{ignore}} />
      </template>,
    )
    const upload = new FileUploadHarness()
    const preview = upload.file('photo.png').preview!
    await upload.remove('photo.png')
    assert.deepEqual(heard, [[]])
    assert.deepEqual(upload.files, ['photo.png'], 'the caller kept it')
    assert.strictEqual(upload.file('photo.png').preview, preview)
    assert.true(await loads(preview), 'and its preview still loads')
    await a11yAudit()
  })

  test('a block lays the parts out; the zone takes a block of its own', async function (assert) {
    const uploads = new Uploads()
    const start = [file('kept.txt', 1, 'text/plain')]
    await render(
      <template>
        <FileUpload
          @name="custom"
          @multiple={{true}}
          @upload={{uploads.upload}}
          @defaultValue={{start}}
          as |u|
        >
          <u.Queue class="order-first" />
          <u.Dropzone class="min-h-40" as |zone|>
            {{if zone.isDragging "Let go" "Add attachments"}}
          </u.Dropzone>
          <p data-test-count>{{u.files.length}} kept, {{u.uploads.length}} uploading</p>
          <u.List />
          <button type="button" data-test-clear {{on "click" u.clear}}>Clear</button>
        </FileUpload>
      </template>,
    )
    const upload = new FileUploadHarness('custom')
    assert.strictEqual(upload.text, 'Add attachments')
    assert.dom(upload.dropzone).hasClass('min-h-40', 'the caller’s class goes on the zone')
    await upload.drag(photo())
    assert.strictEqual(upload.text, 'Let go')
    await upload.drop(photo())
    assert.dom('[data-test-count]').hasText('1 kept, 1 uploading')
    assert.true(upload.queue!.classList.contains('order-first'))
    await uploads.resolve('photo.png', 'photo.png')
    assert.dom('[data-test-count]').hasText('2 kept, 0 uploading')
    assert.deepEqual(upload.files, ['kept.txt', 'photo.png'], 'a string names itself')
    await click('[data-test-clear]')
    assert.deepEqual(upload.files, [], 'u.clear empties the list')
    await a11yAudit()
  })

  test('@queue: the files go into the queue it is given', async function (assert) {
    const uploads = new Uploads()
    const queue = new Queue({ name: 'photos', fileQueue: undefined as never })
    await render(<template><FileUpload @queue={{queue}} @upload={{uploads.upload}} /></template>)
    const upload = new FileUploadHarness()
    await upload.select(photo())
    assert.deepEqual(
      queue.files.map(f => f.name),
      ['photo.png'],
      "in ember-file-upload's queue while it uploads",
    )
    await uploads.resolve('photo.png', 'photo.png')
    assert.deepEqual(queue.files, [], 'and out of it once done')
    await a11yAudit()
  })

  test('the upload queue’s strings are arguments', async function (assert) {
    const uploads = new Uploads()
    const retryLabel = (name: string) => `Réessayer ${name}`
    const progressLabel = (name: string) => `Envoi de ${name}`
    const leftOutLabel = (names: string[]) => `Un seul fichier ; ignoré : ${names.join(', ')}`
    await render(
      <template>
        <FileUpload
          @upload={{uploads.upload}}
          @dropLabel="Déposez pour ajouter"
          @retryLabel={{retryLabel}}
          @progressLabel={{progressLabel}}
          @uploadFailedLabel="Échec de l’envoi"
          @unknownKindLabel="FICHIER"
          @leftOutLabel={{leftOutLabel}}
        />
      </template>,
    )
    const upload = new FileUploadHarness()
    await upload.drag(photo())
    assert.strictEqual(upload.text, 'Déposez pour ajouter')
    await upload.leave()

    await upload.drop(file('LISEZMOI', 10, ''), file('b.txt', 10, 'text/plain'))
    assert.strictEqual(upload.leftOut, 'Un seul fichier ; ignoré : b.txt')
    const readme = upload.file('LISEZMOI')
    assert.strictEqual(readme.details, 'FICHIER · 10 bytes', 'a file with no extension')
    assert.strictEqual(readme.progressBar.label, 'Envoi de LISEZMOI')
    await uploads.reject('LISEZMOI', undefined)
    assert.strictEqual(readme.details, 'Échec de l’envoi')
    assert.strictEqual(readme.retryButton.label, 'Réessayer LISEZMOI')
    await a11yAudit()
  })

  test('its strings and how it names, sizes and previews values are arguments', async function (assert) {
    interface Doc {
      title: string
      bytes: number
      thumb?: string
    }
    const docs: Doc[] = [{ title: 'Spec', bytes: 2048, thumb: 'data:image/png;base64,AAAA' }]
    const nameOf = (doc: Doc) => doc.title
    const sizeOf = (doc: Doc) => doc.bytes
    const previewOf = (doc: Doc) => doc.thumb
    const removeLabel = (name: string) => `Supprimer ${name}`
    const rejectedLabel = (names: string[]) => `Refusé : ${names.join(', ')}`
    await render(
      <template>
        <FileUpload
          @accept=".pdf"
          @defaultValue={{docs}}
          @nameOf={{nameOf}}
          @sizeOf={{sizeOf}}
          @previewOf={{previewOf}}
          @locale="fr"
          @prompt="Choisir un fichier"
          @hint="ou le déposer ici"
          @description="PDF, 5 Mo au plus"
          @removeLabel={{removeLabel}}
          @rejectedLabel={{rejectedLabel}}
        />
      </template>,
    )
    const upload = new FileUploadHarness()
    assert.strictEqual(upload.text, 'Choisir un fichier ou le déposer ici PDF, 5 Mo au plus')
    const spec = upload.file('Spec')
    assert.strictEqual(spec.details, 'FILE · 2 ko')
    assert.strictEqual(spec.preview, 'data:image/png;base64,AAAA')
    assert.strictEqual(spec.removeButton.label, 'Supprimer Spec')
    await upload.drop(file('a.txt', 1, 'text/plain'))
    assert.strictEqual(upload.rejected, 'Refusé : a.txt')
    await a11yAudit()
  })

  test('RTL: the parts flip, and a Progress bar fills from the inline start', async function (assert) {
    const uploads = new Uploads()
    const start = [file('cv.pdf', 10, 'application/pdf')]
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="width: 360px">
            <FileUpload
              @multiple={{true}}
              @defaultValue={{start}}
              @upload={{uploads.upload}}
              @prompt="اختر الملفات"
              @hint="أو اسحبها وأفلتها هنا"
            />
          </div>
        </DirectionProvider>
      </template>,
    )
    const upload = new FileUploadHarness()
    assert.strictEqual(getComputedStyle(upload.element).direction, 'rtl')
    const cv = upload.file('cv.pdf')
    const row = cv.element.getBoundingClientRect()
    const media = cv.media.getBoundingClientRect()
    const remove = cv.removeButton.element.getBoundingClientRect()
    assert.true(media.right > remove.right, 'the media at the right, the remove button at the left')
    assert.true(row.right - media.right < 16, 'the media starts the row from the right')

    await upload.select(file('notes.txt', 10, 'text/plain'))
    await uploads.progress('notes.txt', 25)
    const bar = upload.file('notes.txt').progressBar
    await transitioned(bar.indicator)
    const track = bar.element.getBoundingClientRect()
    const fill = bar.indicator.getBoundingClientRect()
    // The indicator is the track's width, moved back by what's left to do (and clipped): right
    // to left, its visible quarter is the track's right-hand quarter.
    assert.true(
      Math.abs(fill.left - (track.right - track.width * 0.25)) < 1,
      'the fill starts at the right',
    )
    await a11yAudit()
  })
})
