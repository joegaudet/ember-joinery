# File Drop

A zone to drop files on, or to click to pick them, and a way to take files dropped anywhere on
the page, as ember-primitives' FileDrop and DocumentFileDrop. They have no styles; the styled
[File Drop](/components/file-drop.md) is built on them.

<Example @name="file-drop-headless" @title="A drop zone of your own" />

## Usage

```gts
import { DocumentFileDrop, FileDrop } from '@ember-joinery/primitives/file-drop'

<template>
  <FileDrop @accept="video/*" @onFiles={{this.load}} as |zone|>
    {{if zone.isDragging "Let go to add it" "Drop a video here, or click to choose one"}}
  </FileDrop>

  <DocumentFileDrop @accept="video/*" @onFiles={{this.load}} as |page|>
    {{#if page.isDragging}}<div class="overlay">Drop to load</div>{{/if}}
  </DocumentFileDrop>
</template>
```

- `FileDrop` is a `<label>` for a visually hidden `<input type="file">`, with `data-dragging`
  while files are dragged over it. Show its focus with `:focus-within`, because the focused
  input is hidden.
- `@accept` filters drops as the file picker does: extensions (`.mkv`), wildcards (`video/*`)
  and exact types. Without `@multiple`, only the first file that matches.
- `isDragging` doesn't flicker as the pointer crosses children, and a drag of text or links
  isn't a file drag.
- `DocumentFileDrop` renders nothing of its own. It keeps a dropped file from opening in the
  tab, and leaves a drop on a `FileDrop` to that `FileDrop`.

## Drop anywhere on the page

Drag a file over any part of this page, then drop it anywhere. `DocumentFileDrop` renders only
its block, which gets `page.isDragging`; here a paragraph of the block's own shows it with
`data-dragging`.

<Example @name="file-drop-document-headless" @title="Drop anywhere on the page" />

## API

`FileDrop` takes `@onFiles`, `@accept`, `@multiple`, `@disabled` and `@name`;
`DocumentFileDrop` takes `@onFiles`, `@accept` and `@multiple`. Both yield `{ isDragging }`.
`accepts(file, accept)`, `filesFrom(files, accept, multiple)`, `hasFiles(event)` and
`DragState` are exported, for a drop target of your own.

## Keyboard interactions

| Key     | What it does                                         |
| ------- | ---------------------------------------------------- |
| `Tab`   | Moves focus to the zone's file input                 |
| `Enter` | Opens the file picker (the browser's, for the input) |
| `Space` | Opens the file picker                                |

Drag and drop has no keyboard equivalent, so the file picker is always there as the way to pick
files. `DocumentFileDrop` takes only drops, so give the page a `FileDrop` (or a file input) too.

## Accessibility

- `FileDrop` is a `<label>` for a visually hidden `<input type="file">`. The input stays in the
  tab order, and the text in the zone is its accessible name, so write it as an instruction
  ("Drop images here, or click to choose").
- Show focus on the zone with `:focus-within`, because the focused input is hidden.
- `@disabled` disables the input, so the zone leaves the tab order.
- `DocumentFileDrop` renders no element and takes no focus. What its block shows while files
  are dragged is for sighted users; the files it takes are the caller's to announce.

## Testing

```ts
import { FileDropHarness, dropFiles } from '@ember-joinery/test-support'

await new FileDropHarness().drop([file]) // a FileDrop
await dropFiles(document.body, [file]) // a DocumentFileDrop
```

The [File Drop](/components/file-drop.md#testing) page lists their members.

## Upstream

ember-primitives' [File Drop](https://github.com/universal-ember/ember-primitives/blob/9584c783bae34e6f0b628ec09a1e1f3cbdb4107e/ember-primitives/src/components/file-drop.gts) at
universal-ember/ember-primitives@9584c78 (0.64.2). Joinery adds `@disabled`.
