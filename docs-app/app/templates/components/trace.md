# Trace

The building block for reasoning, tool calls, sources and more.

<Example @name="trace-demo" @title="Trace" />

`Trace` is a list of lines. Each line has an icon, a title, and an optional description and
status. A line can expand to show more detail, link to a page, or open a dialog or sheet.

Every line has the same shape, so reasoning, tool calls, sources and plans built from `Trace`
look and behave the same.

Use `Trace` for the steps an agent takes, like calling a tool, running a subagent or editing a
file. Use [Message](/components/message.md) for its reply, and
[Marker](/components/marker.md) for notes and dividers between turns.

ui.shadcn.com shows these examples in the Rhea style; pick Rhea in an example's style switcher to
see them as there. The streaming examples play a scripted conversation, as upstream's do with its
`createChat()` helper and the AI SDK's `useChat()`: the guide's port of the two is
`docs-app/app/examples/trace/scripted-chat.ts`, shown after each example's source.

## Built with Trace

Upstream builds its AI Elements (Chain of Thought, Plan, Queue, Reasoning, Sources, Stack Trace,
Subagent, Task, Terminal, Test Results and Tool) from `Trace` parts. They are compositions, not
components, so they aren't part of Joinery; the examples below build the same patterns.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { Trace, TraceCollapsible, TraceLine } from '@ember-joinery/ember'
```

Its rows that expand are built on the primitives'
[Collapsible](/primitives/collapsible.md), and a row's detail is often a
[Code Block](/components/code-block.md) (`@ember-joinery/code-block`).

## Usage

Use a `TraceLine` for a single step:

```gts
<Trace>
  <TraceLine as |l|>
    <l.Icon>
      <Icon @icon={{Search}} />
    </l.Icon>
    <l.Title>Searched for minimumReleaseAge</l.Title>
  </TraceLine>
</Trace>
```

Wrap the line in a `TraceCollapsible` to show more detail when it expands:

```gts
<Trace>
  <TraceCollapsible as |c|>
    <c.Trigger>
      <TraceLine as |l|>
        <l.Icon>
          <Icon @icon={{Terminal}} />
        </l.Icon>
        <l.Title>Ran node --version</l.Title>
      </TraceLine>
    </c.Trigger>
    <c.Content>v24.18.0</c.Content>
  </TraceCollapsible>
</Trace>
```

## Composition

Use the following composition to build a trace line:

```text
Trace
└── TraceLine
    ├── l.Icon
    ├── l.Title
    ├── l.Description
    └── l.Icon
```

Wrap the line in a `TraceCollapsible` to show more detail when it expands:

```text
Trace
└── TraceCollapsible
    ├── c.Trigger
    │   └── TraceLine
    └── c.Content
```

`TraceLine` is always the line. To make a line do something, wrap it in that thing's trigger.

## Features

- One row for reasoning, tool calls, sources, plans and tasks
- Rows that expand, link out, or open a dialog, sheet, drawer or popover
- `running`, `error` and `pending` states, with a shimmer while running
- Nested rows, so a summary expands into steps and a step into its output
- Works with reasoning, tool and source parts from a chat's messages
- Keyboard and screen reader support from the trigger that wraps each row
- Customizable styling through `class` on every part

## Trace Line

Use a `TraceLine` on its own for a step with no detail to show. It reads as plain text.

<Example @name="trace-static" @title="Trace Line" />

## Status

Set `@status` on `TraceLine` when a step is running, has failed or hasn't started yet.

<Example @name="trace-status" @title="Status" />

| `@status`   | Use for                                                                       |
| ----------- | ----------------------------------------------------------------------------- |
| none        | Work that is done: "Ran pnpm install".                                        |
| `"error"`   | Work that failed. Say so in the title: "Failed to run pnpm lint".             |
| `"running"` | Work in progress. Write the title in the present tense: "Running pnpm build". |
| `"pending"` | Work that has not started, such as a plan step: "Run pnpm test".              |

## Description

Put secondary text such as a diff stat, a duration or a count in a `l.Description` after the
`l.Title`. It does not truncate.

<Example @name="trace-description" @title="Description" />

## Collapsible

Wrap the line in a `TraceCollapsible` to show more detail when it expands. Put the `TraceLine`
inside `c.Trigger` and the detail in `c.Content`.

<Example @name="trace-collapsible" @title="Collapsible" />

## Open State

Rows start closed. Use `@defaultOpen` on `TraceCollapsible` to start open, or `@open` with
`@onOpenChange` to control a row.

<Example @name="trace-open" @title="Open State" />

To open a row while it streams and let the reader's click win, pass the reader's choice, else
whether it is running (upstream's `open ?? running`):

```gts
class ThinkingRow extends Component {
  @tracked open: boolean | undefined
  get isOpen() {
    return this.open ?? this.args.running
  }
  setOpen = (open: boolean) => (this.open = open)

  <template>
    <TraceCollapsible @open={{this.isOpen}} @onOpenChange={{this.setOpen}} as |c|>
      <c.Trigger>
        <TraceLine @status={{if @running "running"}} as |l|>…</TraceLine>
      </c.Trigger>
      <c.Content>{{@text}}</c.Content>
    </TraceCollapsible>
  </template>
}
```

## Link

Wrap the `TraceLine` in an anchor. For a new tab, use an arrow-up-right icon and a visually
hidden "(opens in a new tab)".

<Example @name="trace-link" @title="Link" />

```gts
<a href="https://docs.astro.build" target="_blank" rel="noreferrer">
  <TraceLine as |l|>
    <l.Title>
      Install Astro
      <span class="sr-only"> (opens in a new tab)</span>
    </l.Title>
    <l.Icon>
      <Icon @icon={{ArrowUpRight}} />
    </l.Icon>
  </TraceLine>
</a>
```

## Dialog

Wrap the `TraceLine` in the dialog's trigger. The dialog owns its open state, Escape and focus
return.

<Example @name="trace-dialog" @title="Dialog" />

```gts
<Dialog as |d|>
  <d.Trigger>
    <TraceLine as |l|>
      <l.Title>Searched the web for cache keys</l.Title>
      <l.Icon>
        <Icon @icon={{ChevronRight}} />
      </l.Icon>
    </TraceLine>
  </d.Trigger>
  <d.Content>…</d.Content>
</Dialog>
```

## Sheet

The same shape as the dialog. Drawer and Popover work the same way.

<Example @name="trace-sheet" @title="Sheet" />

## Group

Put rows that sit next to each other in a `Trace`. It also styles any trigger or link that wraps
a `TraceLine`.

<Example @name="trace-group" @title="Group" />

## Sources

A collapsible row whose detail is a `Trace` of link rows.

<Example @name="trace-sources" @title="Sources" />

## Chain of Thought

A chain of thought is a collapsible row with step rows inside. Set the parent's status and title
from its children.

<Example @name="trace-steps" @title="Chain of Thought" />

## Commit

A commit is a collapsible row with a line for each changed file. Say what changed in the title,
Added, Edited or Deleted, and put the line counts in the description. Each file opens its diff
in a [Sheet](#sheet).

<Example @name="trace-commit" @title="Commit" />

## Whole Turn

Three levels: the turn, a summary, and the rows. Text between steps sits between two `Trace`
lists.

<Example @name="trace-turn" @title="Whole Turn" />

## Reasoning

Render a `reasoning` part from a chat's messages. The row is a `TraceLine` until the first text
arrives. See [Open State](#open-state).

<Example @name="trace-thinking" @title="Reasoning" />

## Tool

Render tool parts from a chat's messages: a finished call is a row that opens on its output, a
failed one says so, and one still running shimmers.

<Example @name="trace-tool-calls" @title="Tool" />

## API Reference

### Trace

A list of rows: a `div` laid out as a column. It also styles any trigger or link that wraps a
`TraceLine` (as wide as its line, rounded, with a focus ring), a Dialog's, Sheet's, Drawer's,
Popover's, Tooltip's or menu's trigger too: those render a root around their trigger, with
`display: contents`, where upstream's Radix roots render none, and the trace looks through it.

| Argument | Type     | Default | What it does                                       |
| -------- | -------- | ------- | -------------------------------------------------- |
| `@as`    | tag name | `div`   | The tag to render                                  |
| `@name`  | `string` |         | Its name, for `TraceHarness` (`data-test-jn-name`) |

### TraceLine

One line: an icon and a title. It is a `span`, so it is not a button or a tab stop. Wrap it in a
trigger or a link to make it do something.

| Argument  | Type                                | Default | What it does                                           |
| --------- | ----------------------------------- | ------- | ------------------------------------------------------ |
| `@status` | `"running" \| "error" \| "pending"` |         | The state of the work the line reports                 |
| `@as`     | tag name                            | `span`  | The tag to render                                      |
| `@name`   | `string`                            |         | Its name, for `TraceLineHarness` (`data-test-jn-name`) |

It yields its parts, each as a component (`l.Icon`) and as a modifier for your own element
(`<i {{l.icon}}>`): `Icon`, `Title` and `Description`. The module exports the same components as
`TraceIcon`, `TraceTitle` and `TraceDescription`. Each takes `@as`, and attributes.

- **Icon**: a decorative icon slot, hidden from assistive tech (`aria-hidden`). Before the
  title it names the action; after it, it is the indicator, and sits a little closer.
- **Title**: one sentence on one line. It truncates, and shimmers while the line is running.
- **Description**: secondary text after the title, such as a count or a duration, in a lighter
  muted colour. It does not truncate.

### TraceCollapsible

A row that expands, on the primitives' `CollapsibleState`. Upstream's takes the props of
`Collapsible` but `asChild`; so does Joinery's.

| Argument        | Type                      | Default | What it does                                                  |
| --------------- | ------------------------- | ------- | ------------------------------------------------------------- |
| `@open`         | `boolean`                 |         | The controlled open state. Pass it with `@onOpenChange`       |
| `@defaultOpen`  | `boolean`                 | `false` | Whether the row starts open                                   |
| `@onOpenChange` | `(open: boolean) => void` |         | Called when the open state changes                            |
| `@disabled`     | `boolean`                 | `false` | Whether the trigger can't open or close it                    |
| `@name`         | `string`                  |         | Its name, for `TraceCollapsibleHarness` (`data-test-jn-name`) |

It yields `Trigger`, `Content`, `isOpen` and `toggle`.

- **Trigger** (`c.Trigger`): the `<button>` that opens and closes the row. Put a `TraceLine`
  inside it. It adds a chevron after the line, which turns a quarter while open; `@icon`
  replaces it (default lucide's `chevron-right`). Its text is muted, the foreground on hover,
  and the destructive colour when its line has `@status="error"`.
- **Content** (`c.Content`): the detail, indented under the line behind a border on its start
  side, its text muted. It animates open and closed (the accordion keyframes, from the measured
  `--radix-collapsible-content-height`), and stays in the document, `hidden` and empty, while
  closed. A `class` or attribute you give it goes on its inner element, which lays the detail
  out, as upstream's `className` does.

### Data attributes

| Part                    | `class`                                                        | `data-slot`                       | `data-test-jn-part`                  |
| ----------------------- | -------------------------------------------------------------- | --------------------------------- | ------------------------------------ |
| Trace                   | `jn-trace`                                                     | `trace`                           | (`data-test-jn="trace"`)             |
| TraceLine               | `jn-trace-line`                                                | `trace-line`                      | (`data-test-jn="trace-line"`)        |
| Icon                    | `jn-trace-icon`                                                | `trace-icon`                      | `icon`                               |
| Title                   | `jn-trace-title`                                               | `trace-title`                     | `title`                              |
| Description             | `jn-trace-description`                                         | `trace-description`               | `description`                        |
| TraceCollapsible        | `jn-trace-collapsible`                                         | `trace-collapsible`               | (`data-test-jn="trace-collapsible"`) |
| Trigger                 | `jn-trace-collapsible-trigger group/trace-collapsible-trigger` | `trace-collapsible-trigger`       | `trigger`                            |
| Trigger's chevron       | `jn-trace-icon jn-trace-collapsible-trigger-icon`              | `trace-icon`                      | `indicator`                          |
| Content                 | `jn-trace-collapsible-content`                                 | `trace-collapsible-content`       | `content`                            |
| Content's inner element | `jn-trace-collapsible-content-inner`                           | `trace-collapsible-content-inner` |                                      |

A line has `data-status` when it has a `@status`. The collapsible, its trigger and its content
have Radix's `data-state` (`open` or `closed`); the trigger has `aria-expanded` and
`aria-controls`.

## Keyboard interactions

A `TraceLine` on its own isn't focusable. A row's trigger is a `<button>`: Tab reaches it, and
`Enter` and `Space` open and close it, as the WAI-ARIA disclosure pattern asks. A line in a link,
or in a dialog's or a sheet's trigger, takes the keyboard of that element.

## Accessibility

`Trace` adds no roles of its own. Each line gets its semantics from the element that wraps it.

- A `TraceLine` on its own is a `span`. It is read as text and is not a tab stop.
- Wrap it in a `TraceCollapsible`'s trigger and it becomes a button with `aria-expanded`. Wrap
  it in a link, or in the trigger for a dialog or sheet, and it takes the keyboard and focus
  behavior of that element.
- The icon slot is hidden from assistive tech, so the title is the accessible name. Write it as
  a sentence that says what happened, like "Edited trace.gts", not just "trace.gts".
- When a link opens a new tab, add "(opens in a new tab)" to the title, visually hidden.
- Status is shown with color and motion, so put it in the title too. Write "Running pnpm build"
  while it runs and "Failed to run pnpm build" when it errors.
- The shimmer on a running title stops when the reader prefers reduced motion. The title still
  says what is happening.
- Inside a Message Scroller, each line is announced once when it is added.
- A row's content mutes its text. If you put a block with a muted background inside it, give
  the block `text-foreground` so it keeps its contrast. `CodeBlock` sets its own text color.

## Testing

`TraceHarness`, `TraceLineHarness` and `TraceCollapsibleHarness` from
`@ember-joinery/test-support` drive a trace, a line and a row:

```ts
import { TraceCollapsibleHarness, TraceHarness } from '@ember-joinery/test-support'

const run = new TraceCollapsibleHarness('node') // <TraceCollapsible @name="node">
await run.open()
assert.strictEqual(run.line.title, 'Ran node --version')
assert.deepEqual(new TraceHarness().titles, ['Ran node --version'])
```

| `TraceLineHarness`                  | What it is                                                     |
| ----------------------------------- | -------------------------------------------------------------- |
| `title`, `description`, `text`      | Its title (a hidden note included), its description, all of it |
| `titleElement`, `icons`             | The title part, and the icon slots in order                    |
| `status`                            | Its `@status`, or `null` for work that is done                 |
| `isRunning`, `isError`, `isPending` | Each status                                                    |
| `control`                           | The link or button that wraps it, or `null`                    |
| `isLink`, `href`, `opensInNewTab`   | Whether a link wraps it, where to, and in a new tab            |
| `click()`, `focus()`                | Clicks or focuses what wraps it                                |

| `TraceCollapsibleHarness`                  | What it is                                                     |
| ------------------------------------------ | -------------------------------------------------------------- |
| `trigger`, `content`, `indicator`          | Each part (the indicator is the chevron)                       |
| `line`                                     | A `TraceLineHarness` for the line in its trigger               |
| `isOpen`, `isShown`, `isDisabled`          | From `aria-expanded`; shown, or animating out; disabled        |
| `label`, `text`                            | The trigger's name, and the content's text (`''` while closed) |
| `controlsContent`                          | Whether `aria-controls` names the content                      |
| `toggle()`, `open()`, `close()`, `focus()` | Uses the trigger, as a reader does                             |

| `TraceHarness`                          | What it is                                               |
| --------------------------------------- | -------------------------------------------------------- |
| `lines`, `titles`                       | Every line in it, nested ones included, and their titles |
| `collapsibles`                          | Every row that expands in it                             |
| `line(options)`, `collapsible(options)` | One of each, by `@name` or `index`                       |

## Upstream

shadcn/ui's [Trace](https://ui.shadcn.com/docs/components/radix/trace), from
`apps/v4/registry/bases/radix/ui/trace.tsx` at shadcn-ui/ui@8ab2771, shown in the Rhea style.
