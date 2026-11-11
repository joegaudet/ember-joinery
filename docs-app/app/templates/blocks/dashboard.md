# Dashboard

A dashboard with sidebar, charts and data table.

<Example @name="dashboard-01" @title="dashboard-01" @block={{true}} @blockHeight={{1000}} />

An inset [Sidebar](/components/sidebar.md) that slides off the screen, a header with its
trigger, four section cards, an interactive area [Chart](/components/chart.md), and a
[Data Table](/components/data-table.md) of a document's sections: rows to select, page through,
hide columns of and drag into a new order, each opening a [Drawer](/components/drawer.md) with
its chart and form. Pick 375 to see it on a phone, with the sidebar in a sheet. The
[live demo](https://joegaudet.com/ember-joinery/demo/) is this block, as an app copies it in.

## Installation

Blocks aren't exported from a package: copy the block's files into your app. It uses
`@ember-joinery/ember`, the chart and data table add-ons, and lucide's icons:

```bash
pnpm add @ember-joinery/ember @ember-joinery/chart @ember-joinery/data-table lucide
```

and Tailwind's utilities for its layout (`@container/main`, `@xl/main:grid-cols-2`…), as
upstream's does: see [Installation](/getting-started/installation.md) for a Tailwind app.

## Files

| File                                      | What it is                                                                                   |
| ----------------------------------------- | -------------------------------------------------------------------------------------------- |
| `dashboard-01.gts`                        | The page: a `SidebarProvider` with `--sidebar-width` and `--header-height`, and its inset    |
| `dashboard-01/app-sidebar.gts`            | `AppSidebar`: the sidebar's header, navigation, documents, secondary links and user          |
| `dashboard-01/nav-main.gts`               | `NavMain`: Quick Create, the inbox, and the main navigation                                  |
| `dashboard-01/nav-documents.gts`          | `NavDocuments`: the documents, each with a menu of actions                                   |
| `dashboard-01/nav-secondary.gts`          | `NavSecondary`: Settings, Get Help and Search, at the sidebar's foot                         |
| `dashboard-01/nav-user.gts`               | `NavUser`: the user's menu                                                                   |
| `dashboard-01/site-header.gts`            | `SiteHeader`: the trigger and the page's title                                               |
| `dashboard-01/section-cards.gts`          | `SectionCards`: four [Cards](/components/card.md) with a trend [Badge](/components/badge.md) |
| `dashboard-01/chart-area-interactive.gts` | `ChartAreaInteractive`: stacked areas over 3 months, 30 or 7 days                            |
| `dashboard-01/data-table.gts`             | `DataTable`: the sections' table, its views and its pagination                               |
| `dashboard-01/sortable.ts`                | `SortableRows`: the rows' drag and drop, which upstream takes from dnd-kit                   |
| `dashboard-01/data.ts`                    | The sections: upstream's `data.json`                                                         |

The sidebar's parts take the `SidebarProvider`'s yield (`@sidebar`), where upstream's call
`useSidebar()`. The chart and each row's drawer, deeper in the page, reach it with
[`<UseSidebar>`](/components/sidebar.md#usesidebar) for `isMobile`, where upstream's call
`useIsMobile()`: the same 768px breakpoint, measured in the window the block renders in.

## Where it parts from upstream

- **Drag and drop.** Upstream's table reorders its rows with dnd-kit. Joinery has no
  drag-and-drop package, so the block carries `SortableRows`: the handle drags its row with a
  mouse, a pen or a finger (upstream's mouse and touch sensors), up and down only, the other
  rows making room, and dropping it reorders the data (dnd-kit's `closestCenter`,
  `restrictToVerticalAxis` and `verticalListSortingStrategy`). The handle has
  `touch-action: none` and keeps the pointer while it drags, so a touch on it drags the row
  rather than scrolling the page. From the keyboard, Space or Enter picks a row up, the up and
  down arrows move it a row at a time (dnd-kit's sortable keyboard coordinates; its default
  moves 25px a press), Space, Enter or Tab drops it, and Escape puts it back. Left and right
  move nothing, as in upstream's, whose coordinates find no row beside one in a column, so text
  direction doesn't change them. The handle is described by dnd-kit's instructions, and a live
  region says each step in dnd-kit's words. Upstream's dnd-kit also scrolls the page as a row
  is dragged near its edge; `SortableRows` doesn't.
- **The row's type.** Upstream infers it from a zod schema; Joinery takes no zod, so it is an
  interface (`Section`, in `data.ts`).
- **Headers.** Upstream's drag column has an empty header and its actions column none; a header
  cell needs a name, so each has a visually hidden one ("Reorder", "Actions").
- **Add Section.** Below the `lg` breakpoint upstream's button shows its icon alone, unnamed;
  Joinery's has `aria-label="Add Section"` at every width.
- **Focus in the drawer.** Its scrolling region takes focus, so the keyboard can scroll it.
- `DataTable` from `@ember-joinery/data-table` goes around upstream's Tabs, as
  `display: contents`, so `DataTableHarness` can find each part (`dt.head`, `dt.row`,
  `dt.viewOptions`…) and the header cells carry `aria-sort`.
- **The section cards' titles** add `leading-8 @[250px]/card:leading-9`. Upstream's
  `CardTitle` runs its classes through tailwind-merge, whose `text-2xl` and
  `@[250px]/card:text-3xl` drop the Card title's own `leading-snug`, so the title takes their
  line heights (2rem, then 2.25rem). Joinery merges no classes: its Card title keeps
  `leading-snug`, which Tailwind's `text-*` utilities read before their own line height, so
  without these the titles stand about 5px taller than upstream's, and everything below them
  with them. An app that copies the block keeps them for the same reason; the same goes for any
  `text-*` class given to a Joinery part whose style sets its leading.
- **The chart's range on a phone.** Upstream's effect switches the chart to the last 7 days
  each time the window becomes a phone's; Joinery's does it when the Sidebar's provider says the
  window is narrower than 768px (its `isMobile`, read through `<UseSidebar>`), in the microtask
  after the render that saw it, as an effect runs after its render.

Pixel for pixel, the block is upstream's: its parity check compares the whole page, sidebar,
cards, chart and table, in light and dark (`parity/map/blocks.json`).

## Accessibility

- The sidebar, its trigger and its mobile sheet are the [Sidebar](/components/sidebar.md)'s:
  see its Accessibility notes.
- The table's checkboxes are named ("Select all", "Select row"), each Target, Limit and
  unassigned Reviewer is named by a visually hidden label, and the icon buttons by visually
  hidden text ("Open menu", "Go to next page"…).
- Upstream's colours fall short of WCAG AA's 4.5:1 for small text in two places: the avatar's
  initials (see [Avatar](/components/avatar.md)), and a selected row's muted text (its type badge
  and an unassigned reviewer's placeholder, `--muted-foreground` on the row's `--muted` tint).
  Joinery keeps them; to meet AA, darken the muted text in a selected row:

  ```css
  tr[data-state='selected'] .text-muted-foreground {
    color: var(--foreground);
  }
  ```

## Testing

The block's test drives it with `SidebarHarness`, `CardHarness`, `ChartHarness`,
`ToggleGroupHarness`, `TabsHarness`, `DataTableHarness`, `SelectHarness`,
`DropdownMenuHarness`, `DrawerHarness` and `ToasterHarness`, with the table as a page object
(see its Test tab): the chart's ranges, selecting and paging the rows, hiding a column, the
views' tabs and select, dragging a row with the keyboard, a mouse and a finger, a row's drawer,
and the toast its target's form shows as it saves. It also shows the block in the guide's frame
at 375px, as a phone does: the sidebar in a sheet, the chart on the last 7 days, and a row's
drawer from the bottom of the screen, without its chart.

## Upstream

shadcn/ui's [`dashboard-01`](https://ui.shadcn.com/blocks) block, from
`apps/v4/registry/bases/radix/blocks/dashboard-01` at shadcn-ui/ui@8ab2771, in the Nova style.
Each of its `IconPlaceholder`s is the lucide icon it names.
