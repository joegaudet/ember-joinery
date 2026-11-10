---
'@ember-joinery/file-upload': major
'@ember-joinery/ember': minor
---

`@ember-joinery/file-upload` is a new opt-in add-on, on ember-file-upload: `FileUpload`, file
uploads in shadcn's look, for one file or many. Its drop zone is a dashed box around a visually
hidden file input, holding Empty's icon, title and description; it turns `--primary` while files
are dragged over it and names, in a status region, the files `@accept` turned away (dropped or
chosen) and, without `@multiple`, those a drop of several left out. Each file the value holds is
an outlined Item with a preview (an image's own, or an icon for its kind), its name, kind and
size, and a remove Button. With `@upload`, each chosen file waits in an upload queue with a
Progress bar that follows ember-file-upload's `progress`, and a failed one shows its error with
Retry and remove. The value is a list, controlled or not (`@value`, `@defaultValue`,
`@onValueChange`), holding one file at most without `@multiple`. It yields `Dropzone`, `List`
and `Queue` for a layout of one's own, takes an ember-file-upload `Queue` (`@queue`), and flips
right to left; every string is an argument. Removing or retrying a file moves focus to the
nearest row's button, and a row stays put while others change. Its `/test-support` has
`FileUploadHarness` and `FileUploadItemHarness`. `@ember-joinery/ember`'s style sheets style its
parts; nothing in the core packages imports it.
