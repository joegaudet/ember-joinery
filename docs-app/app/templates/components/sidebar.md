# Sidebar

A composable, themeable and customizable sidebar component.

<Example @name="sidebar-demo" @title="Sidebar" @block={{true}} />

A sidebar that collapses to icons.

Sidebars are one of the most complex components to build. They are central to any application
and often contain a lot of moving parts.

We now have a solid foundation to build on top of. Composable. Themeable. Customizable.

Each example on this page is a whole screen, so it shows in a frame of its own, as on
ui.shadcn.com: the sidebar is fixed to the frame's edge, and the frame's width decides the
breakpoints. Pick 375 to see the mobile sheet.

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { SidebarProvider } from '@ember-joinery/ember'
```

## Usage

```gts title="app/templates/application.gts"
import { SidebarProvider } from '@ember-joinery/ember'
import AppSidebar from '../components/app-sidebar.gts'

<template>
  <SidebarProvider as |sidebar|>
    <AppSidebar @sidebar={{sidebar}} />
    <main>
      <sidebar.Trigger />
      {{outlet}}
    </main>
  </SidebarProvider>
</template>
```

```gts title="app/components/app-sidebar.gts"
import type { TOC } from '@ember/component/template-only'
import type { SidebarBlockParams } from '@ember-joinery/ember'

const AppSidebar: TOC<{ Args: { sidebar: SidebarBlockParams } }> = <template>
  <@sidebar.Sidebar>
    <@sidebar.Header />
    <@sidebar.Content>
      <@sidebar.Group />
      <@sidebar.Group />
    </@sidebar.Content>
    <@sidebar.Footer />
  </@sidebar.Sidebar>
</template>

export default AppSidebar
```

Upstream's parts are separate components that find their provider through React's context
(`useSidebar()`). Joinery's `SidebarProvider` yields them all, with its state, so a component of
yours that renders part of the sidebar takes what it yields as an argument, as `AppSidebar`
takes `@sidebar` here. A template that can't be given it, such as a route's, rendered through
the `{{outlet}}`, gets the same from [`<UseSidebar>`](#usesidebar).

## Composition

Use the following composition to build a `Sidebar` layout:

```text
SidebarProvider
├── Sidebar
│   ├── Header
│   ├── Content
│   │   ├── Group
│   │   │   ├── GroupLabel
│   │   │   ├── GroupAction
│   │   │   ├── GroupContent
│   │   │   └── Menu
│   │   │       ├── MenuItem
│   │   │       │   ├── MenuButton
│   │   │       │   ├── MenuAction
│   │   │       │   └── MenuBadge
│   │   │       └── MenuItem
│   │   │           ├── MenuButton
│   │   │           └── MenuSub
│   │   │               ├── MenuSubItem
│   │   │               └── MenuSubItem
│   │   └── Group
│   │       └── Menu
│   │           ├── MenuItem
│   │           └── MenuItem
│   ├── Footer
│   └── Rail
├── Inset
└── Trigger
```

## Structure

- **SidebarProvider**: handles the collapsible state and yields the sidebar's parts.
- **Sidebar**: the main collapsible sidebar panel.
- **Header**: sticky at the top; use for branding, titles, or workspace switchers.
- **Footer**: sticky at the bottom; use for user menus, settings, or actions.
- **Content**: the scrollable region between the header and footer.
- **Group**: groups related navigation with an optional label, action, and content areas.
- **Menu** / **MenuItem**: menu structure for links, badges, actions, and nested submenus.
- **Rail**: a strip along the sidebar's edge that toggles it.
- **Inset**: wraps the main content when using the `inset` variant.
- **Trigger**: a control that toggles the sidebar open or collapsed.

## SidebarProvider

The `SidebarProvider` component provides the sidebar's state to the `Sidebar` and its parts.
Always render the sidebar inside one.

| Argument            | Type                      | Default           | What it does                                                      |
| ------------------- | ------------------------- | ----------------- | ----------------------------------------------------------------- |
| `@defaultOpen`      | `boolean`                 | `true`            | Whether it starts open, uncontrolled                              |
| `@open`             | `boolean`                 |                   | Whether it is open, controlled                                    |
| `@onOpenChange`     | `(open: boolean) => void` |                   | Called with each new open state                                   |
| `@keyboardShortcut` | `string \| false`         | `"b"`             | The key that, with ⌘ or Ctrl, toggles it; `false` for none        |
| `@mobileBreakpoint` | `number`                  | `768`             | The viewport width, in pixels, below which the sidebar is a sheet |
| `@cookieName`       | `string \| false`         | `"sidebar_state"` | The cookie its open state is kept in; `false` for none            |
| `@name`             | `string`                  |                   | Its name, for `SidebarHarness` (`data-test-jn-name`)              |

`@mobileBreakpoint` is Joinery's (upstream's is a constant in its `use-mobile` hook), and it can
only be 768 or wider. The desktop sidebar's CSS is upstream's, which shows it from Tailwind's `md`
breakpoint (768px) up, so a narrower breakpoint would leave widths between the two with neither
the sheet nor the sidebar.

### Width

The sidebar is 16rem wide, 18rem on mobile, and 3rem collapsed to its icons, as upstream's
`SIDEBAR_WIDTH`, `SIDEBAR_WIDTH_MOBILE` and `SIDEBAR_WIDTH_ICON`. Joinery's CSS sets them as the
`--sidebar-width`, `--sidebar-width-mobile` and `--sidebar-width-icon` custom properties, so set
them on the provider (its `style`, or a class of yours) to change them:

```gts
<SidebarProvider style="--sidebar-width: 20rem; --sidebar-width-mobile: 20rem" as |sidebar|>
  <sidebar.Sidebar />
</SidebarProvider>
```

### Keyboard Shortcut

To toggle the sidebar, use the `cmd+b` keyboard shortcut on Mac and `ctrl+b` on Windows. Pass
another key with `@keyboardShortcut="k"`, or `@keyboardShortcut={{false}}` for none.

### Persisted State

As upstream's, the provider keeps the open state in a cookie (`sidebar_state`, for a week) each
time it changes. Upstream reads it back on the server; an Ember app reads it with
`sidebarStateFromCookie()`, which gives `true`, `false`, or `undefined` before it is set, and
passes it to `@defaultOpen`:

```gts
import { SidebarProvider, sidebarStateFromCookie } from '@ember-joinery/ember'

<template>
  <SidebarProvider @defaultOpen={{(sidebarStateFromCookie)}} as |sidebar|>
    …
  </SidebarProvider>
</template>
```

## Sidebar

The main `Sidebar` component used to render a collapsible sidebar.

| Argument             | Type                                 | Default                          | What it does                                 |
| -------------------- | ------------------------------------ | -------------------------------- | -------------------------------------------- |
| `@side`              | `"left" \| "right"`                  | `"left"`                         | The side of the sidebar                      |
| `@variant`           | `"sidebar" \| "floating" \| "inset"` | `"sidebar"`                      | The variant of the sidebar                   |
| `@collapsible`       | `"offcanvas" \| "icon" \| "none"`    | `"offcanvas"`                    | How it collapses                             |
| `@mobileTitle`       | `string`                             | `"Sidebar"`                      | The mobile sheet's title, for screen readers |
| `@mobileDescription` | `string`                             | `"Displays the mobile sidebar."` | The mobile sheet's description               |

| `@collapsible` | What it does                                                 |
| -------------- | ------------------------------------------------------------ |
| `offcanvas`    | A collapsible sidebar that slides in from the left or right. |
| `icon`         | A sidebar that collapses to icons.                           |
| `none`         | A non-collapsible sidebar.                                   |

<div class="callout">

**Note:** If you use the `inset` variant, remember to wrap your main content in an `Inset`.

</div>

```gts
<SidebarProvider as |sidebar|>
  <sidebar.Sidebar @variant="inset" />
  <sidebar.Inset>
    <main>{{outlet}}</main>
  </sidebar.Inset>
</SidebarProvider>
```

Your attributes (`class`, `dir`) go on the panel inside the sidebar
(`data-slot="sidebar-container"`), as upstream's `className` does; on the plain panel with
`@collapsible="none"`; and on the sheet on mobile.

## useSidebar

Upstream's `useSidebar()` hook is what the provider yields, beside its parts:

```gts
<SidebarProvider as |sidebar|>
  {{sidebar.state}} {{sidebar.open}} {{sidebar.isMobile}}
  <button type="button" {{on "click" sidebar.toggleSidebar}}>Toggle</button>
</SidebarProvider>
```

| Property        | Type                        | Description                                   |
| --------------- | --------------------------- | --------------------------------------------- |
| `state`         | `"expanded" \| "collapsed"` | The current state of the sidebar.             |
| `open`          | `boolean`                   | Whether the sidebar is open.                  |
| `setOpen`       | `(open: boolean) => void`   | Sets the open state of the sidebar.           |
| `openMobile`    | `boolean`                   | Whether the sidebar is open on mobile.        |
| `setOpenMobile` | `(open: boolean) => void`   | Sets the open state of the sidebar on mobile. |
| `isMobile`      | `boolean`                   | Whether the sidebar is on mobile.             |
| `toggleSidebar` | `() => void`                | Toggles the sidebar. Desktop and mobile.      |

Upstream's hook works in any component under the provider. In Ember, a template the provider's
block params don't reach (a route's, rendered through the application's `{{outlet}}`, or a
component you'd rather not pass them to) uses `<UseSidebar>`, which yields the same parts and
state from the nearest `SidebarProvider` around it, found through the DOM
([`dom-context`](/primitives/dom-context.md)), as upstream's hook finds it through React's
context. As upstream's hook does, it throws when there is none.

```gts title="app/templates/inbox.gts"
import { UseSidebar } from '@ember-joinery/ember'

<template>
  <UseSidebar as |sidebar|>
    <header>
      <sidebar.Trigger />
      <h1>Inbox</h1>
    </header>
    {{if sidebar.isMobile "On a phone" "On a wide screen"}}
  </UseSidebar>
</template>
```

## SidebarHeader

Use the `Header` part to add a sticky header to the sidebar.

<Example @name="sidebar-header" @title="Header" @block={{true}} />

## SidebarFooter

Use the `Footer` part to add a sticky footer to the sidebar.

<Example @name="sidebar-footer" @title="Footer" @block={{true}} />

## SidebarContent

The `Content` part wraps the content of the sidebar. This is where you add your `Group`s. It is
scrollable.

```gts
<sidebar.Sidebar>
  <sidebar.Content>
    <sidebar.Group />
    <sidebar.Group />
  </sidebar.Content>
</sidebar.Sidebar>
```

## SidebarGroup

Use the `Group` part to create a section within the sidebar.

A `Group` has a `GroupLabel`, a `GroupContent` and an optional `GroupAction`.

<Example @name="sidebar-group" @title="Group" @block={{true}} />

The `GroupAction` is a button beside the label:

<Example @name="sidebar-group-action" @title="Group Action" @block={{true}} />

To make a `Group` collapsible, wrap it in a [Collapsible](/components/collapsible.md), and make
its label the trigger: `<sidebar.GroupLabel @as="button" {{c.trigger}}>`.

<Example @name="sidebar-group-collapsible" @title="Collapsible Group" @block={{true}} />

## SidebarMenu

The `Menu` part is used for building a menu within a `Group`.

<Example @name="sidebar-menu" @title="Menu" @block={{true}} />

## SidebarMenuButton

The `MenuButton` part renders a menu button within a `MenuItem`.

By default, the `MenuButton` renders a button, but you can use `@as="a"` to render a link, or the
`menuButton` modifier on a component of your own, such as a `LinkTo`.

Use `@isActive` to mark a menu item as active.

```gts
<sidebar.MenuButton @as="a" href="#" @isActive={{true}}>Home</sidebar.MenuButton>
<LinkTo @route="inbox" {{sidebar.menuButton isActive=true}}>Inbox</LinkTo>
```

`@tooltip` gives it a tooltip, on the side, while the sidebar is collapsed to its icons (and
never on mobile), as in the demo at the top of the page. Upstream's `tooltip` also takes an object
of TooltipContent's props (`side`, `align`, `hidden`, `children`…); Joinery's takes the text
only, and shows it on the right, centred, as upstream's does by default.

## SidebarMenuAction

The `MenuAction` part renders a button at the end of a `MenuItem`, here a
[Dropdown Menu](/components/dropdown-menu.md)'s trigger (`{{m.trigger}}`). With
`@showOnHover={{true}}`, it shows only while its item is hovered or has focus.

<Example @name="sidebar-menu-action" @title="Menu Action" @block={{true}} />

## SidebarMenuSub

The `MenuSub` part renders a submenu within a `MenuItem`, of `MenuSubItem`s, each with a
`MenuSubButton`: a link (`@size` is `"md"` or `"sm"`, `@isActive` marks the current one).

<Example @name="sidebar-menu-sub" @title="Menu Sub" @block={{true}} />

Each item's submenu can open and close, in a [Collapsible](/components/collapsible.md) that is
the menu item (`<Collapsible @as="li" {{sidebar.menuItem}}>`), its menu button the trigger:

<Example @name="sidebar-menu-collapsible" @title="Collapsible Menu" @block={{true}} />

Upstream wraps each item in the Collapsible's `<div>`, which puts a `<div>` straight inside the
menu's `<ul>`, a list that may only hold `<li>`s; Joinery's example makes the Collapsible the
`<li>` itself, as the demo's are.

## SidebarMenuBadge

The `MenuBadge` part renders a badge within a `MenuItem`.

<Example @name="sidebar-menu-badge" @title="Menu Badge" @block={{true}} />

## SidebarMenuSkeleton

The `MenuSkeleton` part renders a skeleton for a `Menu` while it loads (`@showIcon` adds one for
the icon). Upstream's example renders it as the fallback of a React Server Component's
`Suspense`; this one waits for the projects with [`load`](/primitives/load.md), whose
`<:loading>` block it is. The projects take three seconds.

<Example @name="sidebar-rsc" @title="Menu Skeleton" @block={{true}} />

## SidebarTrigger

Use the `Trigger` part to render a button that toggles the sidebar. To make a button of your own
the trigger, use the `trigger` modifier, or call `toggleSidebar`:

```gts
<SidebarProvider as |sidebar|>
  <button type="button" {{sidebar.trigger}}>Toggle Sidebar</button>
  <button type="button" {{on "click" sidebar.toggleSidebar}}>Toggle Sidebar</button>
</SidebarProvider>
```

The trigger tells assistive technology whether the sidebar is open (`aria-expanded`), which
upstream's doesn't; `toggleSidebar` on your own button doesn't. A ghost Button styles
`aria-expanded` as an open menu's trigger, filled, which upstream's trigger never shows, so the
trigger's own class, `jn-sidebar-trigger`, keeps a ghost trigger's resting look while the
sidebar is open (its hover is the ghost Button's). The `trigger` modifier adds that class too, so
a ghost Button of yours rests the same way; any other variant shows its `aria-expanded` look
while the sidebar is open.

## SidebarRail

The `Rail` part renders a rail within a `Sidebar`. This rail can be used to toggle the sidebar.

```gts
<sidebar.Sidebar>
  <sidebar.Header />
  <sidebar.Content>
    <sidebar.Group />
  </sidebar.Content>
  <sidebar.Footer />
  <sidebar.Rail />
</sidebar.Sidebar>
```

## Controlled Sidebar

Use `@open` and `@onOpenChange` to control the sidebar.

<Example @name="sidebar-controlled" @title="Controlled" @block={{true}} />

## Theming

We use the following CSS variables to theme the sidebar.

```css
:root {
  --sidebar: oklch(0.985 0 0);
  --sidebar-foreground: oklch(0.145 0 0);
  --sidebar-primary: oklch(0.205 0 0);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.97 0 0);
  --sidebar-accent-foreground: oklch(0.205 0 0);
  --sidebar-border: oklch(0.922 0 0);
  --sidebar-ring: oklch(0.708 0 0);
}

.dark {
  --sidebar: oklch(0.205 0 0);
  --sidebar-foreground: oklch(0.985 0 0);
  --sidebar-primary: oklch(0.488 0.243 264.376);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.269 0 0);
  --sidebar-accent-foreground: oklch(0.985 0 0);
  --sidebar-border: oklch(1 0 0 / 10%);
  --sidebar-ring: oklch(0.439 0 0);
}
```

Joinery's `tokens.css` and base colours define them, as shadcn's themes do.

## Styling

Here are some tips for styling the sidebar based on different states.

```gts
<sidebar.Sidebar @collapsible="icon">
  <sidebar.Content>
    <sidebar.Group class="group-data-[collapsible=icon]:hidden" />
  </sidebar.Content>
</sidebar.Sidebar>
```

```gts
<sidebar.MenuItem>
  <sidebar.MenuButton />
  <sidebar.MenuAction class="peer-data-[active=true]/menu-button:opacity-100" />
</sidebar.MenuItem>
```

The parts keep upstream's markers for these: the sidebar is a `group` and a `peer`, its wrapper
a `group/sidebar-wrapper`, a menu item a `group/menu-item`, and a menu button a
`peer/menu-button`.

## RTL

Joinery's styles use logical properties, so a sidebar lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)). `@side` stays physical, as
upstream's does, so a right-to-left page puts its sidebar on the right with `@side="right"`.
Upstream's Changelog lists the changes its copied source needed for this; Joinery's Sidebar has
them all.

<Example @name="sidebar-rtl" @title="RTL" @dir="rtl" @block={{true}} />

## API Reference

### Parts

| Part                          | Element                                           | Arguments                                                                                                   |
| ----------------------------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `Header`, `Footer`, `Content` | `<div>`                                           | `@as`                                                                                                       |
| `Group`, `GroupContent`       | `<div>`                                           | `@as`                                                                                                       |
| `GroupLabel`                  | `<div>`                                           | `@as` (`"button"` for a Collapsible's trigger)                                                              |
| `GroupAction`                 | `<button>`                                        | `@as`                                                                                                       |
| `Menu`, `MenuSub`             | `<ul>`                                            | `@as`                                                                                                       |
| `MenuItem`, `MenuSubItem`     | `<li>`                                            | `@as`                                                                                                       |
| `MenuButton`                  | `<button>`                                        | `@isActive`, `@variant` (`default`, `outline`), `@size` (`default`, `sm`, `lg`), `@tooltip`, `@as`, `@name` |
| `MenuAction`                  | `<button>`                                        | `@showOnHover`, `@as`                                                                                       |
| `MenuBadge`                   | `<div>`                                           | `@as`                                                                                                       |
| `MenuSkeleton`                | `<div>`                                           | `@showIcon`                                                                                                 |
| `MenuSubButton`               | `<a>`                                             | `@size` (`md`, `sm`), `@isActive`, `@as`, `@name`                                                           |
| `Input`                       | `<input>`                                         | an [Input](/components/input.md)'s (`@value`, `@onValueChange`…)                                            |
| `Separator`                   | `<div>`                                           | `@orientation`, `@decorative` (default `true`)                                                              |
| `Inset`                       | `<main>`                                          | `@as`                                                                                                       |
| `Trigger`                     | a ghost `icon-sm` [Button](/components/button.md) | `@label` (`"Toggle Sidebar"`), `@icon` (lucide's `panel-left`)                                              |
| `Rail`                        | `<button>`                                        | `@label` (`"Toggle Sidebar"`)                                                                               |

### Modifiers

Each part is also a modifier, for an element or component of your own: `header`, `footer`,
`content`, `group`, `groupLabel`, `groupAction`, `groupContent`, `menu`, `menuItem`,
`menuButton` (`isActive`, `variant`, `size`, `name`), `menuAction` (`showOnHover`), `menuBadge`,
`menuSub`, `menuSubItem`, `menuSubButton` (`size`, `isActive`, `name`), `inset`, and `trigger`,
which toggles the sidebar. The modifiers render the classes and attributes their parts do.
`asSidebarMenuButton` and `asSidebarMenuSubButton` are the same two, as exports.

### Data attributes

| Part             | `class`                                                                                  | `data-slot`               | Also                                                                 |
| ---------------- | ---------------------------------------------------------------------------------------- | ------------------------- | -------------------------------------------------------------------- |
| Provider         | `jn-sidebar-wrapper group/sidebar-wrapper`                                               | `sidebar-wrapper`         | `data-test-jn="sidebar"`                                             |
| Sidebar          | `jn-sidebar group peer`                                                                  | `sidebar`                 | `data-state`, `data-collapsible`, `data-variant`, `data-side`        |
| Gap              | `jn-sidebar-gap`                                                                         | `sidebar-gap`             |                                                                      |
| Container        | `jn-sidebar-container`                                                                   | `sidebar-container`       | `data-side`                                                          |
| Inner            | `jn-sidebar-inner`                                                                       | `sidebar-inner`           | `data-sidebar="sidebar"`                                             |
| Plain sidebar    | `jn-sidebar-static`                                                                      | `sidebar`                 | with `@collapsible="none"`                                           |
| Mobile sheet     | `jn-sheet-content jn-sidebar-mobile`                                                     | `sheet-content`           | `data-sidebar="sidebar"`, `data-mobile="true"`, `role="dialog"`      |
| Menu button      | `jn-sidebar-menu-button peer/menu-button group/menu-button` and its variant's and size's | `sidebar-menu-button`     | `data-size`, `data-active`, `data-test-jn="sidebar-menu-button"`     |
| Menu action      | `jn-sidebar-menu-action`                                                                 | `sidebar-menu-action`     | `data-show-on-hover`                                                 |
| Submenu button   | `jn-sidebar-menu-sub-button`                                                             | `sidebar-menu-sub-button` | `data-size`, `data-active`, `data-test-jn="sidebar-menu-sub-button"` |
| Trigger          | `jn-sidebar-trigger` and a Button's                                                      | `sidebar-trigger`         | `aria-expanded`                                                      |
| Inset            | `jn-sidebar-inset`                                                                       | `sidebar-inset`           | no `data-sidebar`, as upstream's                                     |
| Every other part | `jn-sidebar-<part>`                                                                      | `sidebar-<part>`          | `data-sidebar="<part>"`, as upstream's                               |

The mobile sheet's `data-slot` is the Sheet's own (upstream's is `sidebar`): the Dialog
primitive sets it.

## Keyboard interactions

| Key                      | What it does                                                    |
| ------------------------ | --------------------------------------------------------------- |
| `⌘` + `B` / `Ctrl` + `B` | Toggles the sidebar, anywhere on the page (`@keyboardShortcut`) |
| `Space` / `Enter`        | On the trigger, toggles the sidebar                             |
| `Tab` / `Shift` + `Tab`  | Moves through the menu buttons, actions and links               |
| `Esc`                    | On mobile, closes the sheet, with focus back where it was       |

The rail is out of the tab order, as upstream's: the trigger and the shortcut are the keyboard's
ways to toggle the sidebar.

## Accessibility

- The menus are lists (`<ul>` and `<li>`), and their buttons and links are native ones, so the
  page's tab order goes through them.
- The trigger has `aria-expanded`, so a screen reader hears whether the sidebar is open;
  upstream's doesn't. The rail has upstream's `aria-label` and `title`, "Toggle Sidebar".
- Slid off the screen (`@collapsible="offcanvas"`, collapsed), the sidebar hides what is in it
  (`visibility: hidden`, once the slide has finished), so the Tab key and screen readers skip
  what nobody can see. Upstream's leaves its menu buttons, links and actions in the tab order,
  off the screen, which fails WCAG 2.2's Focus Visible and Focus Not Obscured. Closing it while
  focus is inside (with the shortcut, say) moves focus to the trigger first. The rail stays, so a
  pointer can still open it from the screen's edge. Collapsed to its icons, it still shows them,
  so they stay in the tab order.
- On mobile the sidebar is a modal [Sheet](/components/sheet.md), named "Sidebar" and described
  ("Displays the mobile sidebar.") for screen readers: focus moves in, stays there and goes back,
  and the page behind is inert.
- A menu button's `@tooltip` names it while the sidebar is collapsed to its icons. Upstream's
  opens while the sidebar is expanded too, hidden, which repeats the label to a screen reader and
  takes the Escape that should close a mobile sheet; Joinery's stays closed then.

## Testing

`SidebarHarness` from `@ember-joinery/test-support` drives a `<SidebarProvider>`:
`state`, `isOpen` (read from the trigger's `aria-expanded`, as a screen reader hears it; without
a trigger, from the panel's `data-state`), `isMobile`, `collapsible`, `variant`, `side`, the
`panel`, its `container` (where your attributes go), `trigger`, `rail`, `inset` and mobile
`sheet`, `elements(name)` (the sidebar's elements by upstream's `data-sidebar`, through any
component between, such as a Collapsible), the `groupLabels` and `badges`, `menuButtons` and
`menuSubButtons` (with their labels, and `menuButton(label)`), and `toggle()`, `open()`,
`close()`, `toggleWithRail()`, `pressShortcut()`, `focusTrigger()` and, on mobile,
`pressOutside()`.

Menu buttons are components of their own (`data-test-jn="sidebar-menu-button"`), so one can be
a Collapsible's or a Dropdown Menu's trigger too. `SidebarMenuButtonHarness` drives one:
`label`, `isActive`, `size`, `variant`, `href`, `isExpanded`, `tooltip`, `isTooltipShown`,
`click()`, `hover()` and `focus()`; `SidebarMenuSubButtonHarness` drives a submenu's.

```ts
import { DropdownMenuHarness, SidebarHarness, child } from '@ember-joinery/test-support'

class AppSidebar extends SidebarHarness {
  static named = 'app'
  @child(DropdownMenuHarness, 'account') declare account: DropdownMenuHarness
}

const sidebar = new AppSidebar()
await sidebar.toggle()
assert.strictEqual(sidebar.state, 'collapsed')
await sidebar.menuButton('Inbox').hover()
assert.strictEqual(sidebar.menuButton('Inbox').tooltip, 'Inbox')
await sidebar.pressShortcut()
assert.true(sidebar.isOpen)
await sidebar.account.open()
```

To test the mobile sheet, give the provider a `@mobileBreakpoint` wider than the test's window.

## Upstream

shadcn/ui's [Sidebar](https://ui.shadcn.com/docs/components/radix/sidebar), from
`apps/v4/registry/bases/radix/ui/sidebar.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, with
its `use-mobile` hook. The page's other examples are upstream's other `sidebar-*` examples in
`apps/v4/examples/radix`, which its docs page doesn't show.
