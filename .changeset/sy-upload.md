---
'@ember-joinery/file-upload': patch
---

Each upload now runs as a small Switchyard statechart, with no change in how the component behaves. `@upload` gets a second argument, `{ signal }`, an `AbortSignal` that aborts when its file is replaced or the component goes, so a request can be cancelled; before, it ran on and its result was dropped.
