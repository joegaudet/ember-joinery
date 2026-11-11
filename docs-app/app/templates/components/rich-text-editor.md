# Rich Text Editor

A rich-text editor with a formatting toolbar: headings, bold, italic, underline,
strikethrough, code, lists, quotes and code blocks, with undo and redo, stored as HTML or JSON.

<div class="callout">

**An opt-in add-on.** Rich Text Editor is its own package, `@ember-joinery/tiptap`, built on
[Tiptap](https://tiptap.dev) 3 and its StarterKit. Nothing in Joinery's core packages imports
it, so an app that doesn't install it doesn't load Tiptap or ProseMirror.

</div>

shadcn/ui has no rich-text editor, so this one is drawn from the nearest shadcn parts: the box is
an Input Group, with the toolbar as its block-start addon and the document where its textarea
would be. The toolbar's text style is a Dropdown Menu, the marks and blocks are Toggle Group
items, undo and redo are ghost Buttons, each control has a Tooltip with its name and shortcut,
and Separators divide the groups. It follows the style, base colour and radius you pick, as they
do.

<Example @name="rich-text-editor-demo" @title="Rich Text Editor" />

## Installation

Rich Text Editor is an add-on, so it comes in its own package, with Tiptap's StarterKit as a
dependency and Tiptap's core and ProseMirror, its peers, beside it:

```bash
pnpm add @ember-joinery/tiptap @ember-joinery/ember @tiptap/core @tiptap/pm
```

Keep `@tiptap/core`, `@tiptap/pm` and any Tiptap extensions you add on the version
`@tiptap/starter-kit` has, so the app loads one copy of ProseMirror. The add-on ships no CSS of
its own: Joinery's `joinery.css` (or any of its styles) styles its parts, as it does every
component. Import that once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { RichTextEditor } from '@ember-joinery/tiptap'
```

## Usage

```gts
<RichTextEditor
  @value={{this.body}}
  @onValueChange={{this.setBody}}
  @placeholder="Write something"
/>
```

The editor stores HTML. Select some text and press a toolbar button, or type a shortcut:
`Ctrl`/`⌘`+`B` for bold, `## ` at the start of a line for a heading, `- ` for a list. Each toggle
shows whether its formatting is active at the cursor (`aria-pressed`), and the text style menu
shows the style there.

The value is controlled or not (`@value`, `@defaultValue`, `@onValueChange`). An empty editor
stores `''`, so a required check works as it does for a textarea. A new `@value` from outside (a
reset, a record reloading) replaces the document without calling `@onValueChange`; the value the
editor sent, coming back, changes nothing, so typing never resets the cursor. StarterKit keeps
an empty paragraph after a last heading or list, so there is somewhere to type; it isn't
stored.

In a Field, give the editor an `@id` and the FieldLabel a `for`: the label names the document
(as its `aria-labelledby`, since a `<label>` names no `div`), and a press on it focuses the
document. `@describedBy` takes a FieldDescription's or a FieldError's id.

## Choosing the toolbar, storing JSON

`@toolbar` lists the controls to show, in the toolbar's order of groups: `block-type` (the text
style menu), then `bold`, `italic`, `underline`, `strike` and `code`, then `bullet-list`,
`ordered-list`, `blockquote` and `code-block`, then `undo` and `redo`. A Separator goes between
each two groups that show; `@toolbar={{false}}` hides the toolbar. With `@output="json"` the
editor stores Tiptap's JSON document, and `null` when it is empty.

`toPlainText`, also from `@ember-joinery/tiptap`, reads HTML and JSON alike, for a check that a
document says something, as this comment box's is.

<Example @name="rich-text-editor-json" @title="A comment box: three buttons, stored as JSON" />

## Text styles

The text style menu applies a paragraph or a heading to the blocks at the cursor, and its
trigger shows the style there. `@headingLevels` picks the headings it offers (`[1, 2, 3]` by
default); a heading of another level, pasted in, is still named. After a choice, focus goes back
to the document; Escape sends it back to the trigger.

## Tiptap's own

`@starterKit` takes StarterKit's options (`{ heading: { levels: [2, 3] }, link: false }`) and
`@extensions` more Tiptap extensions, after StarterKit; both are read once, when the editor is
made. `@onCreate` hands over the Tiptap editor as the component is made, before it is mounted,
for commands the toolbar doesn't have.

```gts
import Highlight from '@tiptap/extension-highlight'

const extensions = [Highlight]

<RichTextEditor @extensions={{extensions}} @onCreate={{this.keepEditor}} />
```

## Read-only and disabled

`@readonly` shows the document without its toolbar: it can be read, selected and copied, not
changed (`aria-readonly`). `@disabled` takes it out of the tab order, disables every control,
and dims the box, as a disabled input group is dimmed.

<Example @name="rich-text-editor-disabled" @title="Read-only and disabled" />

## RTL

Joinery's styles use logical properties, so the editor lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the toolbar runs from the
right, its arrow keys flip, and the document's text, lists and quotes start on the right. Every
string is an argument: `@labels` names the toolbar, its controls and the text styles.

<Example @name="rich-text-editor-rtl" @title="RTL" @dir="rtl" />

## API Reference

### RichTextEditor

| Argument         | Type                             | Default       | What it does                                                                  |
| ---------------- | -------------------------------- | ------------- | ----------------------------------------------------------------------------- |
| `@value`         | `string \| JSONContent \| null`  |               | The document, controlled; a new value replaces what is in the editor          |
| `@defaultValue`  | `string \| JSONContent \| null`  | `''`          | The document it starts with, uncontrolled                                     |
| `@onValueChange` | `(value) => void`                |               | Called with the document after each change                                    |
| `@output`        | `'html' \| 'json'`               | `'html'`      | Stores an HTML string (`''` when empty), or Tiptap's JSON (`null` when empty) |
| `@toolbar`       | `RichTextTool[] \| false`        | every control | The controls to show, in their groups; `false` hides the toolbar              |
| `@headingLevels` | `(1 \| 2 \| 3 \| 4 \| 5 \| 6)[]` | `[1, 2, 3]`   | The headings the text style menu offers                                       |
| `@starterKit`    | `Partial<StarterKitOptions>`     |               | StarterKit's options; read once                                               |
| `@extensions`    | `Extensions`                     |               | More Tiptap extensions, after StarterKit; read once                           |
| `@onCreate`      | `(editor: Editor) => void`       |               | Called once with the Tiptap editor                                            |
| `@placeholder`   | `string`                         |               | What an empty document shows (`aria-placeholder`)                             |
| `@disabled`      | `boolean`                        | `false`       | Not editable or focusable, every control disabled, the box dimmed             |
| `@readonly`      | `boolean`                        | `false`       | Readable but not editable (`aria-readonly`), with no toolbar                  |
| `@invalid`       | `boolean`                        | `false`       | `aria-invalid` on the document, and the Input Group's destructive border      |
| `@required`      | `boolean`                        | `false`       | `aria-required` on the document                                               |
| `@id`            | `string`                         | its own       | The document's `id`, which a `<FieldLabel for>` names                         |
| `@label`         | `string`                         |               | The document's `aria-label`, when no label names it                           |
| `@labelledBy`    | `string`                         |               | The document's `aria-labelledby`, in place of a `<label for>`                 |
| `@describedBy`   | `string`                         |               | The document's `aria-describedby`, such as a FieldDescription's id            |
| `@labels`        | `Partial<RichTextLabels>`        | English       | The names of the toolbar, its controls and the text styles                    |
| `@name`          | `string`                         |               | Its name, for `RichTextEditorHarness` (`data-test-jn-name`)                   |

It takes attributes on its element, `class` included. `@labels` takes `toolbar` (`Formatting`),
`blockType` (`Text style`), `paragraph` (`Paragraph`), `heading` (`level => 'Heading 2'`), and
one for each control by its name: `bold`, `italic`, `underline`, `strike` (`Strikethrough`),
`code`, `bullet-list` (`Bulleted list`), `ordered-list` (`Numbered list`), `blockquote`
(`Quote`), `code-block` (`Code block`), `undo` and `redo`. `RichTextValue`, `RichTextTool`,
`RichTextLabels`, `HeadingLevel` and `DEFAULT_TOOLBAR` are exported too, and `toPlainText(value)`.

### Data attributes

| Part        | Attribute            | Value                                                                |
| ----------- | -------------------- | -------------------------------------------------------------------- |
| root        | `class`              | `jn-rich-text-editor jn-input-group`                                 |
| root        | `data-slot`          | `rich-text-editor`                                                   |
| root        | `data-disabled`      | `true` while `@disabled`                                             |
| root        | `data-test-jn`       | `rich-text-editor`                                                   |
| toolbar     | `role`               | `toolbar`, named by `@labels.toolbar`, controlling the document      |
| toolbar     | `data-slot`          | `rich-text-editor-toolbar` (with `data-align="block-start"`)         |
| toolbar     | `data-test-jn-part`  | `toolbar`                                                            |
| a control   | `data-test-jn-value` | its name: `block-type`, `bold`, …, `redo`                            |
| a toggle    | `data-state`         | `on` or `off`, as a Toggle Group item's, while its tooltip opens too |
| a toggle    | `aria-pressed`       | whether its mark or block is active at the cursor                    |
| a control   | `aria-keyshortcuts`  | Tiptap's shortcut for it: `Control+B` (`Meta+B` on Apple's systems)  |
| undo, redo  | `aria-disabled`      | `true` with nothing to undo or redo                                  |
| a separator | `data-test-jn-part`  | `separator`                                                          |
| document    | `role`               | `textbox`, `aria-multiline="true"`                                   |
| document    | `data-slot`          | `input-group-control`, as an Input Group's control                   |
| document    | `data-empty`         | present while it is one empty line, which shows the placeholder      |
| document    | `data-test-jn-part`  | `content`                                                            |

## Keyboard interactions

| Key                             | What it does                                                                         |
| ------------------------------- | ------------------------------------------------------------------------------------ |
| `Tab`                           | Moves into the toolbar, on the control last focused, then the document               |
| `ArrowRight`, `ArrowLeft`       | In the toolbar, the next or previous control (flipped right to left), wrapping round |
| `Home`, `End`                   | In the toolbar, the first or last control                                            |
| `Enter`, `Space`                | On a toggle or button, presses it; focus stays in the toolbar                        |
| `ArrowDown`, `Enter`, `Space`   | On the text style trigger, opens its menu                                            |
| `Ctrl`/`⌘` + `B`, `I`, `U`, `E` | Bold, italic, underline, code                                                        |
| `Ctrl`/`⌘` + `Shift` + `S`      | Strikethrough                                                                        |
| `Ctrl`/`⌘` + `Shift` + `8`, `7` | A bulleted or numbered list                                                          |
| `Ctrl`/`⌘` + `Shift` + `B`      | A quote                                                                              |
| `Ctrl`/`⌘` + `Alt` + `C`        | A code block                                                                         |
| `Ctrl`/`⌘` + `Alt` + `0`–`6`    | A paragraph, or a heading of that level                                              |
| `Ctrl`/`⌘` + `Z`, `Shift` + `Z` | Undo, redo                                                                           |

The toolbar is WAI-ARIA's toolbar pattern: one tab stop, the arrow keys between its controls.
Tiptap's StarterKit also has markdown shortcuts as you type: `# ` to `###### ` for a heading,
`- ` or `* ` for a list, `1. ` for a numbered one, `> ` for a quote, ` ``` ` for a code block.

## Accessibility

- The document is a multi-line `textbox`, named by its `<FieldLabel for>` (as `aria-labelledby`),
  `@label` or `@labelledBy`, and described by `@describedBy`. It carries `aria-invalid`,
  `aria-required`, `aria-readonly`, `aria-disabled` and `aria-placeholder` as its arguments say.
- The toolbar is a `toolbar` named `Formatting`, which `aria-controls` the document. Its toggles
  are `aria-pressed` buttons, named, with their shortcut in `aria-keyshortcuts` and, while their
  tooltip is open, in their description. Undo and redo stay focusable with nothing to undo or
  redo, `aria-disabled`, so the toolbar keeps its shape.
- A press on a control with the pointer keeps focus, and the selection, in the document; from
  the keyboard, focus stays on the control, so a keyboard user can press several in a row.
- The text style trigger's name says what it is for and what it shows (`Text style: Heading 2`),
  so its visible text is in its name.
- The HTML is whatever Tiptap's schema allows, but it is still user input: sanitize it on the
  server before you render it anywhere else.

## Testing

`RichTextEditorHarness`, from `@ember-joinery/tiptap/test-support`, reads the document and the
toolbar, and presses the toolbar's controls as a user does. Text goes in through Tiptap's
commands, since ProseMirror doesn't type what synthetic key events ask for; a shortcut is a real
key press, which its keymaps hear. Each example's **Test** tab uses it.

```ts
import { RichTextEditorHarness } from '@ember-joinery/tiptap/test-support'

const body = new RichTextEditorHarness('body')
await body.typeText('Shipping today')
await body.selectAll()
await body.press('bold')
assert.true(body.isActive('bold'))
assert.strictEqual(body.html, '<p><strong>Shipping today</strong></p>')
await body.setBlockType('Heading 2')
await body.pressShortcut('z') // undo
```

| Member                                                             | What it is                                                             |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| `content`                                                          | The document's element                                                 |
| `editor`                                                           | The Tiptap editor behind it                                            |
| `html`, `json`, `text`                                             | The document as it is stored (HTML), as Tiptap's JSON, as text         |
| `isEmpty`, `placeholder`                                           | Whether it is one empty line, and what it shows then                   |
| `label`, `description`                                             | The document's accessible name and description                         |
| `isEditable`, `isDisabled`, `isReadonly`, `isInvalid`, `isFocused` | Its state, from the DOM and ARIA                                       |
| `focus()`, `blur()`                                                | Focuses the document, or takes focus off it                            |
| `typeText(text)`                                                   | Puts text in at the cursor (at the end, if the document isn't focused) |
| `setContent(html)`                                                 | Replaces the document                                                  |
| `selectAll()`, `moveCursor(to)`                                    | Selects it all, or puts the cursor at `start`, `end` or a position     |
| `pressShortcut(key, modifiers)`                                    | Presses Ctrl (⌘ on Apple's systems) and a key on the document          |
| `toolbar`, `toolbarLabel`                                          | The toolbar (or `null`) and its name                                   |
| `tools`, `separators`                                              | The controls' names in order, and how many Separators divide them      |
| `tool(name)`, `toolLabel(name)`, `toolShortcut(name)`              | A control, its name and its `aria-keyshortcuts`                        |
| `isActive(name)`, `active`                                         | Whether a toggle is pressed, and the ones that are                     |
| `isToolDisabled(name)`                                             | Whether a control can't be pressed now (disabled or `aria-disabled`)   |
| `press(name)`                                                      | Presses a control                                                      |
| `tabStop`, `focusedTool`                                           | The control Tab lands on, and the one focused                          |
| `focusTool(name)`, `pressKey(key)`                                 | Focuses a control; presses a key on the focused one                    |
| `hoverTool(name)`, `unhoverTool(name)`, `tooltip(name)`            | Opens and closes a control's tooltip, and reads it                     |
| `blockType`, `blockTypes()`                                        | The text style at the cursor, and the ones the menu offers             |
| `setBlockType(label)`                                              | Applies a text style through the menu                                  |
| `blockTypeMenu`                                                    | The menu's [`DropdownMenuHarness`](/components/dropdown-menu.md)       |

## Built on

[Tiptap](https://tiptap.dev) 3: its core `Editor`, mounted on the document's element, and its
StarterKit, whose keyboard shortcuts and markdown input rules the editor keeps. The toolbar only
runs Tiptap's commands (`toggleBold`, `setHeading`, `undo`…) and reads `isActive` and `can()`, so
an extension you add works from the keyboard and through `@onCreate`'s editor at once.

Formwright's `@ember-formwright/tiptap` offers the same as the `rich-text` control; this is the
standalone component, for use without a form library. The examples on this page port Formwright's
guide examples for it.
