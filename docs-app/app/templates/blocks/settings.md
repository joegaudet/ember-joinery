# Settings

A sidebar in a dialog: settings, a section at a time.

<Example @name="sidebar-13" @title="sidebar-13" @block={{true}} />

The dialog opens as the page does, as upstream's (`useState(true)`); close it and its button
opens it again. From the `md` breakpoint up, a [Sidebar](/components/sidebar.md) that doesn't
collapse lists the sections, beside a [Breadcrumb](/components/breadcrumb.md) and the section's
panel. Pick 375 to see it without the sidebar.

## Installation

Blocks aren't exported from a package: copy the block's files into your app. It uses
`@ember-joinery/ember` and lucide's icons:

```bash
pnpm add @ember-joinery/ember lucide
```

and Tailwind's utilities for its layout, as upstream's does: see
[Installation](/getting-started/installation.md) for a Tailwind app.

## Files

| File                             | What it is                                                                     |
| -------------------------------- | ------------------------------------------------------------------------------ |
| `sidebar-13.gts`                 | The page: the dialog's button, centred                                         |
| `sidebar-13/settings-dialog.gts` | `SettingsDialog`: a [Dialog](/components/dialog.md) around a `SidebarProvider` |

The panel holds upstream's placeholders, ten muted boxes, for your settings. The
[live demo](https://joegaudet.com/ember-joinery/demo/#/settings) opens the same dialog from the
dashboard's Settings link, with each section a link of its own.

## Accessibility

- The dialog is named "Settings" and described by its title and description, which are visually
  hidden (`sr-only`), as upstream's.
- The panel scrolls, so it can take focus (`tabindex="0"`) for the keyboard to scroll it;
  upstream's can't, which fails WCAG 2.2's Keyboard criterion.

## Testing

The block's test drives it with `DialogHarness`, `SidebarHarness` and `BreadcrumbHarness`, as a
page object (see its Test tab).

## Upstream

shadcn/ui's [`sidebar-13`](https://ui.shadcn.com/blocks/sidebar#sidebar-13) block, "A sidebar in
a dialog", from `apps/v4/registry/bases/radix/blocks/sidebar-13` at shadcn-ui/ui@8ab2771, in the
Nova style. It is the settings block of the four Joinery ports.
