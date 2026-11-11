---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`SidebarProvider` is shadcn's Sidebar: `<SidebarProvider as |sidebar|>` yields the `Sidebar`
(`@side`, `@variant` of `sidebar`, `floating` or `inset`, and `@collapsible` of `offcanvas`,
`icon` or `none`), its Header, Content, Footer, Group (Label, Action, Content), Menu (Item,
Button, Action, Badge, Skeleton, Sub, SubItem, SubButton), Input, Separator, Rail, Inset and
Trigger, a modifier for each part (`<LinkTo {{sidebar.menuButton isActive=true}}>`), and what
upstream's `useSidebar()` returns (`state`, `open`, `setOpen`, `openMobile`, `setOpenMobile`,
`isMobile`, `toggleSidebar`). Its state is its own (`@defaultOpen`) or yours (`@open`,
`@onOpenChange`); the trigger, the rail and ⌘B/Ctrl+B (`@keyboardShortcut`) toggle it; each
change is kept in upstream's `sidebar_state` cookie, which `sidebarStateFromCookie()` reads back;
and below 768px wide (`@mobileBreakpoint`, measured in the window it renders in) it is a Sheet
with its own open state. A menu button's `@tooltip` names it while the sidebar is collapsed to
its icons. The trigger adds `aria-expanded`, which upstream's lacks, and keeps a ghost Button's
resting look while the sidebar is open. Slid off the screen (`offcanvas`), the sidebar hides
its items from the Tab key and screen readers, which upstream's leaves focusable off the
screen, and focus inside it goes to the trigger as it closes. `<UseSidebar as |sidebar|>` yields
the same from the nearest provider around it, as upstream's `useSidebar()` does, so a routed
page reaches the sidebar without its block params.
`@ember-joinery/test-support` adds `SidebarHarness`, `SidebarMenuButtonHarness` and
`SidebarMenuSubButtonHarness`. A floating part's content now also sees Radix Popper's own
custom properties (`--radix-popper-anchor-width` and the rest), which upstream's sidebar
examples size their menus by.
