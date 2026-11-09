# File Drop

A zone to drop files on, or to click to pick them, and a way to take files dropped anywhere on
the page.

shadcn/ui has no drop zone: these are ember-primitives' FileDrop and DocumentFileDrop, drawn in
shadcn's terms.

<Example @name="file-drop-demo" @title="File Drop" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { DocumentFileDrop, FileDrop } from '@ember-joinery/ember'
```

## Usage

```gts
<FileDrop @accept="image/*" @multiple={{true}} @onFiles={{this.add}} as |zone|>
  {{if zone.isDragging "Drop to upload" "Drag images here, or click to choose"}}
</FileDrop>
```

A `FileDrop` is a `<label>` for a visually hidden `<input type="file">`: a press on the zone,
or Enter or Space on its input, opens the file picker, and its text names the input. `@accept`
filters drops as the file picker does (`.mkv`, `video/*`, `video/webm`), and without
`@multiple` it takes only the first file that matches. The same file can be picked twice in a
row.

## Drop anywhere on the page

`DocumentFileDrop` takes files dropped anywhere on the page, and covers the page with an
overlay while they are dragged over it. A drop on a `FileDrop` goes only to that `FileDrop`,
and a drop elsewhere doesn't open the file in the browser tab. Drag a file over this page to
see it.

<Example @name="file-drop-document" @title="Drop anywhere on the page" />

## API Reference

### FileDrop

| Argument    | Type                      | Default | What it does                                           |
| ----------- | ------------------------- | ------- | ------------------------------------------------------ |
| `@onFiles`  | `(files: File[]) => void` |         | Called with the files that match `@accept`             |
| `@accept`   | `string`                  | any     | Which files to take, as an `accept` attribute reads it |
| `@multiple` | `boolean`                 | `false` | Whether to take more than one                          |
| `@disabled` | `boolean`                 | `false` | Whether it takes no files                              |
| `@name`     | `string`                  |         | Its name, for `FileDropHarness` (`data-test-jn-name`)  |

Its block gets `{ isDragging }`. It is the primitives' [File Drop](/primitives/file-drop.md)
with Joinery's styles.

### DocumentFileDrop

| Argument    | Type                      | Default               | What it does                                                   |
| ----------- | ------------------------- | --------------------- | -------------------------------------------------------------- |
| `@onFiles`  | `(files: File[]) => void` |                       | Called with the files dropped on the page that match `@accept` |
| `@accept`   | `string`                  | any                   | Which files to take                                            |
| `@multiple` | `boolean`                 | `false`               | Whether to take more than one                                  |
| `@label`    | `string`                  | `Drop files anywhere` | What the overlay says, without a block                         |
| `@name`     | `string`                  |                       | Its name, for `DocumentFileDropHarness`                        |

Its block is what the overlay shows.

### Data attributes

| Part    | Attribute           | Value                                   |
| ------- | ------------------- | --------------------------------------- |
| zone    | `class`             | `jn-file-drop`                          |
| zone    | `data-slot`         | `file-drop`                             |
| zone    | `data-dragging`     | present while files are dragged over it |
| zone    | `data-disabled`     | present while `@disabled`               |
| zone    | `data-test-jn`      | `file-drop`                             |
| input   | `data-test-jn-part` | `input`                                 |
| overlay | `class`             | `jn-document-file-drop`                 |
| overlay | `data-slot`         | `document-file-drop`                    |
| overlay | `data-test-jn`      | `document-file-drop`                    |

The overlay's box is a `jn-document-file-drop-content`.

## Keyboard interactions

| Key              | What it does                         |
| ---------------- | ------------------------------------ |
| `Tab`            | Moves focus to the zone's file input |
| `Enter`, `Space` | Opens the file picker                |

Drag and drop has no keyboard equivalent, so the file picker is always there as the way to
pick files.

## Accessibility

- The zone's text is the accessible name of its file input, which stays in the tab order.
- The zone shows Nova's focus ring while its input has focus.
- The page overlay lets the pointer through and says only what the drop will do; it isn't
  announced, as a drag is a pointer gesture.

## Testing

`FileDropHarness` from `@ember-joinery/test-support` picks and drops files on a zone, styled or
headless; `DocumentFileDropHarness` drags them over the page:

```ts
import { DocumentFileDropHarness, FileDropHarness } from '@ember-joinery/test-support'

const photo = new File(['…'], 'photo.png', { type: 'image/png' })
await new FileDropHarness().drop([photo])

const page = new DocumentFileDropHarness()
await page.drag([photo])
assert.true(page.isShown)
```

| Member        | What it is                                            |
| ------------- | ----------------------------------------------------- |
| `text`        | What the zone says                                    |
| `input`       | Its hidden file input                                 |
| `accept`      | Which files it takes, or `''`                         |
| `isMultiple`  | Whether it takes more than one                        |
| `isDisabled`  | Whether it takes none                                 |
| `isDragging`  | Whether files are dragged over it                     |
| `isFocused`   | Whether its input has focus                           |
| `pick(files)` | Picks files, as the file picker does                  |
| `drag(files)` | Drags files over it; returns whether it allows a drop |
| `leave()`     | Drags them away again                                 |
| `drop(files)` | Drops files on it; returns whether it took the drop   |

`DocumentFileDropHarness` has `isShown`, `text`, `drag(files)`, `leave()` and `drop(files)`,
on the page. For the headless DocumentFileDrop, which renders nothing, `dragFilesOver`,
`dragFilesAway` and `dropFiles` do the same on any element: `dropFiles(document.body, files)`.

## Upstream

ember-primitives' [File Drop](https://github.com/universal-ember/ember-primitives/blob/9584c783bae34e6f0b628ec09a1e1f3cbdb4107e/ember-primitives/src/components/file-drop.gts), from
`ember-primitives/src/components/file-drop.gts` at universal-ember/ember-primitives@9584c78
(0.64.2). Joinery adds `@disabled`, and the styled DocumentFileDrop's overlay.
