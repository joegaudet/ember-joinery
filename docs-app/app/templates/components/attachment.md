# Attachment

Displays a file or image attachment with media, metadata, upload state, and actions.

<Example @name="attachment-demo" @title="Attachment" />

The `Attachment` component displays a file or image attachment, its media, name, and metadata,
with optional actions and upload state. Use it for files and images in chat composers, message
threads, and upload lists.

ui.shadcn.com shows these examples in the Rhea style; pick Rhea in an example's style switcher to
see them as there.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { Attachment, AttachmentGroup } from '@ember-joinery/ember'
```

## Usage

```gts
import { FileText, X } from 'lucide'
import { Attachment, Icon } from '@ember-joinery/ember'

<template>
  <Attachment as |at|>
    <at.Media>
      <Icon @icon={{FileText}} />
    </at.Media>
    <at.Content>
      <at.Title>sales-dashboard.pdf</at.Title>
      <at.Description>PDF · 2.4 MB</at.Description>
    </at.Content>
    <at.Actions>
      <at.Action aria-label="Remove sales-dashboard.pdf">
        <Icon @icon={{X}} />
      </at.Action>
    </at.Actions>
  </Attachment>
</template>
```

The examples name the attachment's parts `at` rather than `a`: in a template, a block parameter
named `a` would turn every `<a>` element inside it into a call to it.

## Composition

Use the following composition to build an attachment:

```text
Attachment
├── at.Media
├── at.Content
│   ├── at.Title
│   └── at.Description
├── at.Actions
│   └── at.Action
└── at.Trigger
```

Use `AttachmentGroup` to lay out multiple attachments in a scrollable row:

```text
AttachmentGroup
├── Attachment
└── Attachment
```

## Features

- Icon and image media through the `Media` part
- Upload states: `idle`, `uploading`, `processing`, `error`, and `done` with built-in styling
  and a shimmer while in progress
- Three sizes and horizontal or vertical orientation
- A full-card `Trigger` that opens a link or dialog while the actions stay independently
  clickable
- Scrollable, snapping `AttachmentGroup` with an edge fade
- Customizable styling through `class` on every part

## Image

Set `@variant="image"` on the `Media` part and render an `<img>` inside it. Use
`@orientation="vertical"` to stack the media above the content.

<Example @name="attachment-image" @title="Image" />

## States

Set `@state` to reflect the upload lifecycle. `uploading` and `processing` shimmer the title,
and `error` switches to a destructive treatment.

<Example @name="attachment-states" @title="States" />

## Sizes

Use `@size` to switch between `default`, `sm`, and `xs`.

<Example @name="attachment-sizes" @title="Sizes" />

## Group

Wrap attachments in `AttachmentGroup` to lay them out in a horizontally scrollable, snapping
row with an edge fade.

<Example @name="attachment-group" @title="Group" />

## Trigger

Add a `Trigger` part to make the whole card open a link or dialog. It fills the card behind
the actions, so the actions stay clickable.

<Example @name="attachment-trigger" @title="Trigger" />

```gts
<Dialog as |d|>
  <Attachment as |at|>
    {{! media, content, actions }}
    <at.Trigger aria-label="Preview research-summary.pdf" {{d.trigger}} />
  </Attachment>
  <d.Content>{{! ... }}</d.Content>
</Dialog>
```

## Accessibility

The `Action` part renders a [`Button`](/components/button.md), and the `Trigger` part renders a
real `<button>` (or a link, with `@as="a"`, or your element, with the `at.trigger` modifier).
Follow the guidance below so both are operable and announced.

### Label icon-only actions

An action is usually icon-only, so give each one an `aria-label` describing the action and its
target.

```gts
<at.Action aria-label="Remove sales-dashboard.pdf">
  <Icon @icon={{X}} />
</at.Action>
```

### Label the trigger

The `Trigger` covers the card with no text of its own, so give it an `aria-label` for what
activating it does.

```gts
<at.Trigger
  @as="a"
  href={{this.url}}
  target="_blank"
  rel="noreferrer"
  aria-label="Open workspace.png"
/>
```

The trigger sits behind the actions in the stacking order, so an action and the trigger never
trap each other — both remain separately focusable and clickable.

### Keyboard scrolling

An `AttachmentGroup` scrolls horizontally. When its attachments are interactive: a trigger or
actions, keyboard users reach off-screen items by tabbing to them. For a row of presentational
attachments, make the group itself focusable and scrollable by adding `tabindex="0"`,
`role="group"`, and an `aria-label`.

### Meaning beyond color

The `error` state uses a destructive color. Keep the failure reason in the `Description` part so
the state is not conveyed by color alone.

That colour is upstream's: a failed upload's description is `--destructive` at 80%, which falls
short of the 4.5:1 WCAG AA asks of its small text. Joinery keeps it, as ui.shadcn.com shows it;
an app that needs AA can draw it at full strength:

```css
[data-slot='attachment'][data-state='error'] [data-slot='attachment-description'] {
  color: var(--destructive);
}
```

## API Reference

### Attachment

The root attachment container. It is a layout, with no role of its own.

| Argument       | Type                                                         | Default        | What it does                                      |
| -------------- | ------------------------------------------------------------ | -------------- | ------------------------------------------------- |
| `@state`       | `"idle" \| "uploading" \| "processing" \| "error" \| "done"` | `"done"`       | The upload state. Drives styling and the shimmer. |
| `@size`        | `"default" \| "sm" \| "xs"`                                  | `"default"`    | The attachment size.                              |
| `@orientation` | `"horizontal" \| "vertical"`                                 | `"horizontal"` | Lay the media beside or above the content.        |
| `@as`          | tag name                                                     | `div`          | The tag to render, such as `li` in a list         |
| `@name`        | `string`                                                     |                | Its name, for `AttachmentHarness`                 |

It yields its parts, each as a component (`at.Title`) and as a modifier for your own element
(`<h3 {{at.title}}>`): `Media`, `Content`, `Title`, `Description`, `Actions`, `Action` and
`Trigger`. Each takes `@as`, and attributes.

### Media

The media slot for an icon or image preview.

| Argument   | Type                | Default  | What it does                                   |
| ---------- | ------------------- | -------- | ---------------------------------------------- |
| `@variant` | `"icon" \| "image"` | `"icon"` | Whether the media holds an icon or an `<img>`. |

As a modifier, `{{at.media variant="image"}}`.

### Content

Wraps the title and description.

### Title

The attachment name, a `<span>`. Shimmers while the attachment is `uploading` or `processing`.

### Description

Secondary metadata such as the file type, size, or upload status, a `<span>`.

### Actions

A container for one or more actions, aligned to the end of the attachment. On a vertical
attachment, it sits over the media's top end corner.

### Action

An action button. Renders a [`Button`](/components/button.md) and takes its arguments.

| Argument   | Type             | Default     | What it does                       |
| ---------- | ---------------- | ----------- | ---------------------------------- |
| `@variant` | `Button` variant | `"ghost"`   | The button variant.                |
| `@size`    | `Button` size    | `"icon-xs"` | The button size.                   |
| `@as`      | tag name         | `button`    | `a` for a link, such as a download |
| `@name`    | `string`         |             | Its name, for `ButtonHarness`      |

Like upstream's (and Button), it sets no `type`: in a form, give it `type="button"`. As a
modifier, `{{at.action variant="secondary" size="icon-sm"}}`.

### Trigger

A full-card overlay that activates the attachment. Renders a `<button>` (`type="button"`) by
default.

| Argument | Type     | Default  | What it does                                      |
| -------- | -------- | -------- | ------------------------------------------------- |
| `@as`    | tag name | `button` | `a` for a link (upstream's `asChild` on an `<a>`) |

A dialog's or a popover's trigger modifier goes on it (`<at.Trigger {{d.trigger}} />`), and the
`at.trigger` modifier makes a component of your own the trigger (`<LinkTo {{at.trigger}}>`).

### AttachmentGroup

Lays out attachments in a horizontally scrollable, snapping row. It takes `@as` and `@name`,
for `AttachmentGroupHarness`.

### Data attributes

| Part            | `class`                                                                                    | `data-slot`              | `data-test-jn-part`                 |
| --------------- | ------------------------------------------------------------------------------------------ | ------------------------ | ----------------------------------- |
| Attachment      | `jn-attachment`, `group/attachment`, `jn-attachment-size-*`, `jn-attachment-orientation-*` | `attachment`             | (`data-test-jn="attachment"`)       |
| Media           | `jn-attachment-media`, `jn-attachment-media-variant-*`                                     | `attachment-media`       | `media`                             |
| Content         | `jn-attachment-content`                                                                    | `attachment-content`     | `content`                           |
| Title           | `jn-attachment-title`                                                                      | `attachment-title`       | `title`                             |
| Description     | `jn-attachment-description`                                                                | `attachment-description` | `description`                       |
| Actions         | `jn-attachment-actions`                                                                    | `attachment-actions`     | `actions`                           |
| Action          | a Button's, and `jn-attachment-action`                                                     | `attachment-action`      | `action`                            |
| Trigger         | `jn-attachment-trigger`                                                                    | `attachment-trigger`     | `trigger`                           |
| AttachmentGroup | `jn-attachment-group`                                                                      | `attachment-group`       | (`data-test-jn="attachment-group"`) |

The attachment also has `data-state`, `data-size` and `data-orientation`, and the media
`data-variant`.

## Keyboard interactions

An attachment isn't focusable; its actions and its trigger are, in that order, in the tab order.
The trigger is a native button (or link): Enter (and, for a button, Space) activates it. Tabbing
to an attachment out of view in an `AttachmentGroup` scrolls the row to it.

## Testing

`AttachmentHarness` from `@ember-joinery/test-support` drives an `<Attachment>`, and
`AttachmentGroupHarness` an `<AttachmentGroup>`:

```ts
import { AttachmentHarness } from '@ember-joinery/test-support'

const upload = new AttachmentHarness('report') // <Attachment @name="report">
assert.strictEqual(upload.title, 'sales-dashboard.pdf')
assert.strictEqual(upload.state, 'uploading')
await upload.action('Cancel upload').click()
```

| `AttachmentHarness`                                                        | What it is                                                              |
| -------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `state`, `size`, `orientation`                                             | Its `@state`, `@size` and `@orientation`                                |
| `isBusy`, `isError`                                                        | Whether it is uploading or processing; whether it failed                |
| `title`, `description`                                                     | Their text, or `''`                                                     |
| `mediaVariant`, `image`, `imageAlt`                                        | The media's `@variant`, its `<img>` and that image's `alt`              |
| `media`, `content`, `titleElement`, `descriptionElement`, `actionsElement` | Each part; throws without it                                            |
| `actions`, `actionLabels`                                                  | A [`ButtonHarness`](/components/button.md) for each action; their names |
| `action(name)`                                                             | The action with that accessible name                                    |
| `trigger`, `hasTrigger`, `triggerLabel`, `href`                            | The trigger, whether there is one, its name, and where it links         |
| `open()`, `focusTrigger()`                                                 | Press the trigger; move focus to it                                     |

| `AttachmentGroupHarness` | What it is                                        |
| ------------------------ | ------------------------------------------------- |
| `attachments`, `titles`  | An `AttachmentHarness` for each, and their titles |
| `isScrollable`           | Whether the row is wider than it shows            |
| `scrollOffset`           | How far it is scrolled across, from its start     |

## Upstream

shadcn/ui's [Attachment](https://ui.shadcn.com/docs/components/radix/attachment), from
`apps/v4/registry/bases/radix/ui/attachment.tsx` at shadcn-ui/ui@8ab2771, shown in the Rhea
style.
