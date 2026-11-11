---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`FileDrop` and `DocumentFileDrop` are ember-primitives': a zone to drop files on or press to pick
them, and a way to take files dropped anywhere on the page, filtered by `@accept` as the file
picker filters them. `@ember-joinery/primitives/file-drop` has the headless ones (with
`@disabled`, and `accepts`, `filesFrom`, `hasFiles` and `DragState` for a target of your own);
`@ember-joinery/ember`'s FileDrop is a dashed drop zone, and its DocumentFileDrop covers the page
with an overlay while files are dragged over it. `@ember-joinery/test-support` adds
`FileDropHarness`, `DocumentFileDropHarness`, and `dragFilesOver`, `dragFilesAway` and
`dropFiles`.
