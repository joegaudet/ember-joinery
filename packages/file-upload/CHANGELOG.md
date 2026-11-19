# @ember-joinery/file-upload

## 1.0.0

### Major Changes

- a73065d: `@ember-joinery/file-upload` is a new opt-in add-on, on ember-file-upload: `FileUpload`, file
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

### Minor Changes

- 17c5b5c: The add-ons' built-in strings go through the app's translator, each package's in its own
  `<package>/messages`: Carousel's role descriptions, slide names (`{index} of {count}`) and step
  buttons; Code Block's Copy and Copied; File Upload's prompt, hint, drop label, its rejected,
  left-out, remove, retry and progress names, Upload failed and `FILE`; Phone Input's country
  picker's name; Power Calendar's month buttons, its calendars' names and the pickers' placeholder,
  trigger names and range (`{from} – {to}`); the Rich Text Editor's toolbar, text styles,
  tools and its shortcuts' Ctrl, Shift and Alt. An argument still wins. File Upload's, Phone Input's and Power Calendar's `@locale`
  default to the translator's. Chart and Data Table show no strings of their own.

### Patch Changes

- a73065d: Every package's tarball carries Joinery's `LICENSE.md` and `NOTICE`, with the licences and
  notices of what it ports (shadcn/ui, ember-primitives, sonner, recharts and the rest), copied in
  from the repository's root by the package's `prepack`.
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [17c5b5c]
- Updated dependencies [17c5b5c]
- Updated dependencies [99eab0c]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
  - @ember-joinery/primitives@1.0.0
  - @ember-joinery/ember@1.0.0
  - @ember-joinery/test-support@1.0.0
