# @ember-joinery/tiptap

A rich-text editor in shadcn/ui's look for Ember, an opt-in add-on to
[Joinery](https://joegaudet.com/ember-joinery/): a document with a formatting toolbar (a text
style menu, toggles for the marks and blocks, undo and redo, each with a tooltip), stored as
HTML or JSON, on [Tiptap](https://tiptap.dev) 3 and its StarterKit.

```bash
npm install @ember-joinery/tiptap @ember-joinery/ember @tiptap/core @tiptap/pm
```

`@tiptap/starter-kit` comes with it; Tiptap's core and ProseMirror are its peers, so an app and
the extensions it adds share one copy (keep them on StarterKit's version). Nothing in Joinery's
core packages imports this one, so an app that doesn't install it doesn't load Tiptap. It ships
no CSS of its own: `@ember-joinery/ember`'s `joinery.css` (or any of its styles) styles its
parts, as it does every Joinery component. shadcn/ui has no rich-text editor, so it is drawn
from the nearest shadcn parts: an Input Group holding the toolbar (a block-start addon) and the
document, with a Dropdown Menu, Toggle Groups, Buttons, Tooltips and Separators in the toolbar.

```gts
import { RichTextEditor } from '@ember-joinery/tiptap'

const TOOLS = ['bold', 'italic', 'bullet-list']

<template>
  {{! stores HTML; '' when empty }}
  <RichTextEditor
    @value={{this.body}}
    @onValueChange={{this.setBody}}
    @placeholder="Write something"
  />

  {{! a trimmed toolbar, storing Tiptap's JSON; null when empty }}
  <RichTextEditor @toolbar={{TOOLS}} @output="json" @onValueChange={{this.setComment}} />
</template>
```

The value is controlled or not (`@value`, `@defaultValue`, `@onValueChange`); a new `@value`
from outside replaces the document without a change. `@toolbar` picks the controls
(`block-type`, `bold`, `italic`, `underline`, `strike`, `code`, `bullet-list`, `ordered-list`,
`blockquote`, `code-block`, `undo`, `redo`), or `false` hides it; `@headingLevels` the headings
the text style menu offers. `@starterKit`, `@extensions` and `@onCreate` reach Tiptap itself.
The document is a `textbox` that a `<label for>` with its `@id` names; the toolbar is WAI-ARIA's
toolbar (one tab stop, the arrow keys between its controls, flipped right to left), and every
string is an argument (`@labels`). `toPlainText(value)` reads HTML and JSON alike.

Its harness, `RichTextEditorHarness`, is in `@ember-joinery/tiptap/test-support`:

```ts
import { RichTextEditorHarness } from '@ember-joinery/tiptap/test-support'

const body = new RichTextEditorHarness('body')
await body.typeText('Shipping today')
await body.selectAll()
await body.press('bold')
assert.true(body.isActive('bold'))
assert.strictEqual(body.html, '<p><strong>Shipping today</strong></p>')
await body.setBlockType('Heading 2')
```

The HTML is whatever Tiptap's schema allows, but it is still user input: sanitize it on the
server before rendering it anywhere else.

Full documentation: the Rich Text Editor page of the guide at
**https://joegaudet.com/ember-joinery/guide/**. Built on [Tiptap](https://github.com/ueberdosis/tiptap)
(MIT); design from [shadcn/ui](https://ui.shadcn.com/) (MIT).
