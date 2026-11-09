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

## API

`FileDrop` takes `@onFiles`, `@accept`, `@multiple`, `@disabled` and `@name`;
`DocumentFileDrop` takes `@onFiles`, `@accept` and `@multiple`. Both yield `{ isDragging }`.
`accepts(file, accept)`, `filesFrom(files, accept, multiple)`, `hasFiles(event)` and
`DragState` are exported, for a drop target of your own.

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
