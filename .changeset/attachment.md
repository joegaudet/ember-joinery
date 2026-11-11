---
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Attachment` is shadcn's Attachment: a file or image in a chat composer, a message thread or an
upload list, with `@state` (`idle`, `uploading`, `processing`, `error`, `done`), `@size`
(`default`, `sm`, `xs`), `@orientation` (`horizontal`, `vertical`), `@as`, and its parts,
yielded as components and modifiers (`Media` with `@variant`, `Content`, `Title`,
`Description`, `Actions`, `Action`, a ghost `icon-xs` Button by default, and `Trigger`, a button
or link over the whole card below the actions). `AttachmentGroup` lays attachments out in a row
that scrolls across and snaps. `@ember-joinery/test-support` adds `AttachmentHarness` and
`AttachmentGroupHarness`.
