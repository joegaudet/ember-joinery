# Code Block

Displays code, terminal output and diffs with an optional header, line numbers and a copy button.

<Example @name="code-block-demo" @title="Code Block" />

`CodeBlock` displays code, terminal output, logs and diffs. It has a header with a title and
actions, line numbers, wrapping, diff and highlighted lines, and a small size for tool output in
a Trace.

Syntax highlighting is optional and lives in a separate helper, `highlightedCode`, so a block
that only shows plain output stays small: Shiki loads the first time something is highlighted.

ui.shadcn.com shows these examples in the Rhea style (all but RTL, in Nova); pick Rhea in an
example's style switcher to see them as there.

## Installation

Code Block is an add-on, so it comes in its own package, with [Shiki](https://shiki.style) as a
dependency:

```bash
pnpm add @ember-joinery/code-block @ember-joinery/ember
```

It ships no CSS of its own: Joinery's `joinery.css` (or any of its styles) styles its parts, as
it does every component. Import that once (see
[Installation](/getting-started/installation.md)), then the component where you use it:

```gts
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'
```

## Usage

```gts
<CodeBlock as |b|>
  <b.Header>
    <b.Title>Terminal</b.Title>
    <b.Actions>
      <b.CopyButton @value={{output}} />
    </b.Actions>
  </b.Header>
  <b.Content @code={{output}} />
</CodeBlock>
```

## Composition

```text
CodeBlock
├── b.Header
│   ├── b.Title
│   └── b.Actions
│       └── b.CopyButton
├── b.Actions (floating, when there is no header)
├── b.Content
│   └── b.Line
└── b.Footer
```

`CodeBlock` yields its parts. `b.Content` takes a string as `@code`, or a list of `b.Line`s as
its block. Use lines when you need line variants or highlighted tokens.

## Features

- **It streams cheaply.** A `@code` string renders as one text node, and `highlightedCode`
  tokenizes only the new lines as code arrives.
- **It copies cleanly.** Line numbers and diff markers are left out of a selection, and blank
  lines survive the copy.
- **It reads left to right.** The content is always `dir="ltr"`. The header follows the page
  direction.
- **It highlights without WASM.** `highlightedCode` uses Shiki's JavaScript engine, loads each
  language on first use and renders ANSI colors in terminal output. `highlightCode` highlights
  ahead of time, outside a template.
- **It fits where code shows up.** Use it in a message, a Markdown fence, a Trace line, Tabs, a
  Dialog or a `typeset` container.
- **It scrolls by keyboard.** The content is focusable, and floating actions show on focus as
  well as on hover.

## Basic

Pass a string to `b.Content` as `@code`. It renders as one text node, so it stays cheap while
output streams.

<Example @name="code-block-basic" @title="Basic" />

## Header

`b.Header` holds a `b.Title` and `b.Actions`. `b.CopyButton` copies its `@value`.

<Example @name="code-block-header" @title="Header" />

A long title truncates. To link the title to a file, make an anchor the title with the `title`
modifier:

```gts
<b.Header>
  <a href="/files/route.ts" {{b.title}}>app/api/chat/route.ts</a>
</b.Header>
```

## Actions

`b.Actions` holds any number of buttons. For a wrap toggle, keep the state yourself and pass it
to `@wrap`.

<Example @name="code-block-actions" @title="Actions" />

```gts
@tracked wrap = false
toggleWrap = () => (this.wrap = !this.wrap)

<b.Actions>
  <Button
    @variant="ghost"
    @size="icon-xs"
    aria-label="Wrap lines"
    aria-pressed={{if this.wrap "true" "false"}}
    {{on "click" this.toggleWrap}}
  >
    <Icon @icon={{WrapText}} />
  </Button>
  <b.CopyButton @value={{output}} />
</b.Actions>
<b.Content @code={{output}} @wrap={{this.wrap}} />
```

## Floating Actions

Without a header, put `b.Actions` directly inside `CodeBlock`. The actions float at the top end
and stay hidden until the block is hovered or focused. They always show on touch screens.

<Example @name="code-block-floating-actions" @title="Floating Actions" />

## Line Numbers

Add `@lineNumbers` to `b.Content`. A `@code` string is split into lines, and the numbers are not
copied with a selection.

<Example @name="code-block-line-numbers" @title="Line Numbers" />

## Start Line

Set `@startLine` to number lines from a given line, for a snippet from the middle of a file. The
gutter grows to fit the widest number.

<Example @name="code-block-start-line" @title="Start Line" />

## Wrap

Long lines scroll by default. Add `@wrap` to wrap them, which suits tool output and error
messages. To let the reader toggle it, see [Actions](#actions).

<Example @name="code-block-wrap" @title="Wrap" />

## Highlighted Lines

Render each line as a `b.Line` and set `@variant="highlighted"` on the lines to call out.

<Example @name="code-block-highlighted-lines" @title="Highlighted Lines" />

## Diff

Set `@variant="added"` or `@variant="removed"` on a `b.Line`. Each one adds a `+` or `−` marker.

<Example @name="code-block-diff" @title="Diff" />

## Height

Cap the height with a `max-h-*` class on `b.Content` (or a `max-height` of your own, without
Tailwind). The content scrolls inside the block.

<Example @name="code-block-height" @title="Height" />

`b.Content` fades its edges with shadcn's `scroll-fade` as it scrolls: left and right by default,
top and bottom when it wraps. Add `scroll-fade-y` to a capped block that does not wrap. In a
Tailwind app, `scroll-fade-*` comes from shadcn's own `shadcn/tailwind.css`, as on ui.shadcn.com.

## Show More

`b.Footer` is a slot below the content. For Show More, cap the content while it is collapsed and
put a ghost `xs` `Button` in the footer.

<Example @name="code-block-show-more" @title="Show More" />

```gts
@tracked expanded = false
id = uniqueId()

<b.Content
  id={{this.id}}
  @code={{code}}
  class={{unless this.expanded "max-h-64 overflow-y-hidden scroll-fade-y"}}
/>
<b.Footer class="justify-center">
  <Button
    @variant="ghost"
    @size="xs"
    aria-expanded={{if this.expanded "true" "false"}}
    aria-controls={{this.id}}
    {{on "click" this.toggle}}
  >
    {{if this.expanded "Show less" "Show more"}}
  </Button>
</b.Footer>
```

### Max Height

To keep a long block from taking over the page, raise the cap instead of removing it. The
expanded content scrolls, and the edges fade as you scroll.

<Example @name="code-block-show-more-scroll" @title="Max Height" />

## Size

Use `@size="sm"` for tool and [Trace](#trace) output. It has tighter padding and `text-xs` text.

<Example @name="code-block-size" @title="Size" />

## Destructive

Use `@variant="destructive"` for errors and failed output.

<Example @name="code-block-destructive" @title="Destructive" />

## Trace

Put a `CodeBlock` with `@size="sm"` in a Trace's collapsible content for tool and terminal
output. Add `@wrap` and a `max-h-64` class to `b.Content` so long output wraps and scrolls inside
the trace. The block sets its own text color, so the trace does not mute it. Upstream's example
(`code-block-trace`) comes with Trace.

## Tabs

Show several files with [Tabs](/components/tabs.md), one `CodeBlock` in each tab's content.

<Example @name="code-block-tabs" @title="Tabs" />

## Message

Put a `CodeBlock` between paragraphs inside a Message. Upstream's example (`code-block-chat`)
comes with Message and Bubble.

## Typeset

A `CodeBlock` inside a `typeset` container keeps its own styles and gets the same space above as
a paragraph.

<Example @name="code-block-typeset" @title="Typeset" />

`typeset` is ui.shadcn.com's prose style sheet (its `typeset.css`), not part of any component,
and Joinery doesn't ship it: here the headings and paragraphs around the block take the page's
own styles.

## RTL

Joinery's styles use logical properties, so the header lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)). Code always reads left to
right. The header follows the page direction.

<Example @name="code-block-rtl" @title="RTL" @dir="rtl" />

## Syntax Highlighting

`highlightedCode` highlights with [Shiki](https://shiki.style) and returns one `CodeLine` per
line for `b.Line`'s `@code`.

<Example @name="code-block-highlighting" @title="Syntax Highlighting" />

```gts
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

<template>
  <CodeBlock as |b|>
    <b.Content>
      {{#each (highlightedCode code "json") as |line|}}
        <b.Line @code={{line}} />
      {{/each}}
    </b.Content>
  </CodeBlock>
</template>
```

Shiki uses its JavaScript regex engine, so there is no WASM to load. Each place that uses
`highlightedCode` keeps its own progress, as upstream's `useHighlightedCode` hook does, and
`await render()` in a test waits for it.

Tokens are colored with GitHub's high-contrast themes, light and dark (`.dark` picks the dark
one). Upstream uses `github-light` and `github-dark`, but some of their colors fall below the
4.5:1 contrast WCAG AA asks for (github-light's orange, for parameters, is 3.5:1 on white), so
Joinery's default differs. To use those, or any Shiki themes:

```ts
import { configureHighlighter } from '@ember-joinery/code-block'

configureHighlighter({
  themes: {
    light: () => import('shiki/themes/github-light.mjs'),
    dark: () => import('shiki/themes/github-dark.mjs'),
  },
})
```

### Languages

Each language loads the first time it is used. A language that is not in the list renders as
plain text.

<Example @name="code-block-languages" @title="Languages" />

The list ships with `bash`, `css`, `diff`, `html`, `javascript`, `json`, `jsx`, `markdown`,
`python`, `sql`, `tsx`, `typescript` and `yaml`, plus aliases such as `ts`, `js`, `sh` and
`yml`. Upstream's list lives in a file you edit; Joinery's is in the package, so add a language
with `registerLanguage`:

```ts
import { registerLanguage } from '@ember-joinery/code-block'

registerLanguage('rust', () => import('shiki/langs/rust.mjs'), { aliases: ['rs'] })
```

### Terminal Output

Pass `"ansi"` as the language to render the colors in terminal output. Without it, escape codes
show as text.

<Example @name="code-block-ansi" @title="Terminal Output" />

ANSI colors do not carry from one line to the next.

### Ahead of Time

Upstream's `highlightCode` runs in a React Server Component, so Shiki stays out of the client
bundle. Joinery's `highlightCode` is the same async function: call it wherever you load data,
and render its lines.

```ts
import { highlightCode, plainLines } from '@ember-joinery/code-block'

const lines = (await highlightCode(code, 'tsx')) ?? plainLines(code)
```

```gts
<b.Content @lineNumbers={{true}}>
  {{#each lines as |line|}}<b.Line @code={{line}} />{{/each}}
</b.Content>
```

### Streaming

While the code streams, the helper tokenizes only the new lines, starting where the last line
left off. Lines that did not change keep the same objects, so Glimmer leaves their elements
alone.

<Example @name="code-block-streaming" @title="Streaming" />

### Markdown

Upstream renders a chat message with Streamdown and routes its fenced code to a `CodeBlock`,
disabling the copy button until the closing fence arrives. Its example (`code-block-markdown`)
comes with Message and Bubble, and a Markdown renderer for Ember.

## Accessibility

- `b.Content` is a `pre` with a `code` element and always sets `dir="ltr"`, so code reads left to
  right on an RTL page.
- `b.Content` has `tabindex="0"`, so keyboard users can focus it and scroll it. Pass
  `tabindex="-1"` to remove the tab stop.
- Floating actions show when focus is inside the block, not only on hover, so keyboard users can
  reach them.
- Line numbers are hidden from screen readers.
- Diff lines carry a `+` or `−` marker as well as a tint, so the change does not rely on color.
- `b.CopyButton` is labelled "Copy", and a polite live region announces "Copied" after a
  successful copy. Give `@copyLabel` and `@copiedLabel` in your page's language.
- Highlighted tokens meet WCAG AA contrast on the block's backgrounds with the default themes.
- Give a wrap toggle `aria-pressed` so its state is announced.
- Give a Show More button `aria-expanded` and point `aria-controls` at the `id` of `b.Content`.

## API Reference

### CodeBlock

The surface that holds the header, the content and the footer.

| Argument   | Type                         | Default     | What it does                                                   |
| ---------- | ---------------------------- | ----------- | -------------------------------------------------------------- |
| `@variant` | `"default" \| "destructive"` | `"default"` | The tone of the block                                          |
| `@size`    | `"default" \| "sm"`          | `"default"` | `"sm"` has tighter padding and `text-xs` code, for tool output |
| `@as`      | tag name                     | `div`       | The tag to render                                              |
| `@name`    | `string`                     |             | Its name, for `CodeBlockHarness` (`data-test-jn-name`)         |

It yields its parts: `Header`, `Title`, `Actions`, `CopyButton`, `Content`, `Line` and
`Footer`, and the modifiers `header`, `title`, `actions` and `footer`, which make an element of
your own that part (`<a href="…" {{b.title}}>`).

### Header, Title, Actions and Footer

A row above the content for a title and actions; a filename or a label, with an optional icon,
which truncates; buttons at the end of the header (as a direct child of `CodeBlock`, they float);
and a row below the content, such as for a Show More button. Each takes `@as` (default `div`) and
attributes on its element.

### CopyButton

A ghost icon button that copies `@value` to the clipboard. It is a
[`Button`](/components/button.md), and takes attributes such as `disabled` and listeners of your
own, which run before it copies.

| Argument       | Type            | Default          | What it does                                        |
| -------------- | --------------- | ---------------- | --------------------------------------------------- |
| `@value`       | `string`        |                  | Required. The text to copy                          |
| `@variant`     | Button variant  | `"ghost"`        | The Button's `@variant`                             |
| `@size`        | Button size     | `"icon-xs"`      | The Button's `@size`                                |
| `@copyLabel`   | `string`        | `"Copy"`         | Its label                                           |
| `@copiedLabel` | `string`        | `"Copied"`       | Its label after a copy, also announced              |
| `@copyIcon`    | a `lucide` icon | lucide's `Copy`  | Its icon                                            |
| `@copiedIcon`  | a `lucide` icon | lucide's `Check` | Its icon after a copy                               |
| `@name`        | `string`        |                  | Its name, for `ButtonHarness` (`data-test-jn-name`) |

### Content

The `pre` that scrolls or wraps.

| Argument       | Type      | Default | What it does                                                     |
| -------------- | --------- | ------- | ---------------------------------------------------------------- |
| `@code`        | `string`  |         | The code as a string. Without it, the block: a list of `b.Line`s |
| `@wrap`        | `boolean` | `false` | Wrap long lines instead of scrolling                             |
| `@lineNumbers` | `boolean` | `false` | Number each line. A `@code` string is split into lines           |
| `@startLine`   | `number`  | `1`     | The number of the first line, with `@lineNumbers`                |

It takes attributes on its `pre`: `tabindex="-1"` removes the tab stop, and a class such as
`max-h-72` caps its height.

### Line

One line of code.

| Argument   | Type                                                 | Default     | What it does                                                     |
| ---------- | ---------------------------------------------------- | ----------- | ---------------------------------------------------------------- |
| `@code`    | `string \| CodeLine`                                 |             | The line: a string, or a line from `highlightedCode`; or a block |
| `@variant` | `"default" \| "added" \| "removed" \| "highlighted"` | `"default"` | The state of the line                                            |

### highlightedCode

```gts
{{#each (highlightedCode code language) as |line|}}<b.Line @code={{line}} />{{/each}}
```

Returns one `CodeLine` per line. It returns plain lines until the language has loaded, and for a
language that is not in the list.

| Argument   | Type     | What it does                                         |
| ---------- | -------- | ---------------------------------------------------- |
| `code`     | `string` | The code to highlight. A trailing newline is ignored |
| `language` | `string` | A language or alias from the list, or `"ansi"`       |

### The highlighter

| Export                                         | What it does                                                                         |
| ---------------------------------------------- | ------------------------------------------------------------------------------------ |
| `highlightCode(code, language)`                | Highlights once: a promise of `CodeLine[]`, or `null` for a language not in the list |
| `loadHighlighter(language)`                    | A highlighter for one language, `highlight(code, state?)`, or `null`                 |
| `plainLines(code)`                             | Code as plain `CodeLine`s                                                            |
| `registerLanguage(name, grammar, { aliases })` | Adds a Shiki grammar (or a loader for one) to the list                               |
| `registeredLanguages()`                        | The languages and aliases in the list                                                |
| `configureHighlighter({ themes })`             | Sets the light and dark Shiki themes; with none, back to `DEFAULT_THEMES`            |

A `CodeLine` is a list of `{ content, style? }` tokens: `style` holds Shiki's
`--shiki-light` and `--shiki-dark` colors.

### Data attributes

| Part       | Attributes                                                                                                                                                                                                                                        |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Root       | `class="jn-code-block group/code-block jn-code-block-variant-<variant>"`, `data-slot="code-block"`, `data-variant`, `data-size`, `data-test-jn="code-block"`, `data-test-jn-name`                                                                 |
| Header     | `class="jn-code-block-header"`, `data-slot="code-block-header"`, `data-test-jn-part="header"`                                                                                                                                                     |
| Title      | `class="jn-code-block-title"`, `data-slot="code-block-title"`, `data-test-jn-part="title"`                                                                                                                                                        |
| Actions    | `class="jn-code-block-actions"`, `data-slot="code-block-actions"`, `data-test-jn-part="actions"`                                                                                                                                                  |
| CopyButton | a Button with `class="… jn-code-block-copy-button"`, `data-slot="code-block-copy-button"`, `data-copied`, `data-test-jn-part="copy-button"`; its live region, `data-test-jn-part="copy-status"`                                                   |
| Content    | `class="jn-code-block-content"`, `data-slot="code-block-content"`, `data-wrap`, `data-numbered`, `dir="ltr"`, `data-test-jn-part="content"`, and inside it `code.jn-code-block-code` (`data-slot="code-block-code"`)                              |
| Line       | `class="jn-code-block-line jn-code-block-line-variant-<variant>"`, `data-slot="code-block-line"`, `data-variant`, `data-test-jn-part="line"`; its content, `data-slot="code-block-line-content"`; a highlighted token, `span.jn-code-block-token` |
| Footer     | `class="jn-code-block-footer"`, `data-slot="code-block-footer"`, `data-test-jn-part="footer"`                                                                                                                                                     |

## Keyboard interactions

| Key              | What it does                                                          |
| ---------------- | --------------------------------------------------------------------- |
| `Tab`            | Moves focus to the actions' buttons, then to the content, and past it |
| Arrow keys       | With the content focused, scroll it                                   |
| `Enter`, `Space` | Activate the focused button, such as Copy                             |

There is no APG pattern for a code block: the content is a scrollable region that takes focus,
and the actions are [buttons](/components/button.md).

## Testing

`CodeBlockHarness` from `@ember-joinery/code-block/test-support` drives a `CodeBlock`, and
`setupClipboard(hooks)` gives each test a clipboard of its own, which records what is copied (a
test browser's own needs focus and a permission):

```ts
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'

module('copying', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  test('it copies the route', async function (assert) {
    await render(<template><Route /></template>)
    const block = new CodeBlockHarness()
    await block.copy()
    assert.strictEqual(clipboard.text, block.code)
    assert.strictEqual(block.copyLabel, 'Copied')
  })
})
```

| Member                                                     | What it is                                                                                        |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `variant`, `size`                                          | Its `@variant` and `@size`                                                                        |
| `title`                                                    | The title's text, or `null`                                                                       |
| `header`, `actions`, `footer`, `content`                   | Its parts' elements (`null` when absent; `content` always)                                        |
| `hasFloatingActions`                                       | Whether the actions float (no header)                                                             |
| `isWrapped`, `isNumbered`, `startLine`                     | `@wrap`, `@lineNumbers` and `@startLine`                                                          |
| `lines`                                                    | Each line's `text`, `variant` and `number`                                                        |
| `code`                                                     | The lines' text, joined with newlines, as a copy of it all would be                               |
| `highlightedLines`, `addedLines`, `removedLines`           | The indices of the lines with each variant                                                        |
| `isHighlighted`, `tokens(index)`                           | Whether Shiki has run, and a line's tokens with their colors                                      |
| `copyButton`, `copyLabel`, `isCopied`, `canCopy`, `status` | The copy button, its label, whether it just copied, whether it can, and what its live region says |
| `copy()`                                                   | Clicks the copy button, and waits for the clipboard                                               |
| `focusContent()`                                           | Focuses the content, as tabbing to it would                                                       |

`setupClipboard(hooks)` returns `{ text, writes, refuse(), allow() }`: the last copy, every copy,
and a way to make copies fail.

## Upstream

shadcn/ui's [Code Block](https://ui.shadcn.com/docs/components/radix/code-block), from
`apps/v4/registry/bases/radix/ui/code-block.tsx`, `hooks/use-highlighted-code.ts` and
`lib/highlighter.tsx` at shadcn-ui/ui@8ab2771, in the Rhea style its page uses.
