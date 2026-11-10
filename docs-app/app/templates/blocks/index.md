# Blocks

Blocks are whole screens built from Joinery's components, ported from
[ui.shadcn.com/blocks](https://ui.shadcn.com/blocks): login, signup, a dashboard with a sidebar,
and settings. They aren't exported from a package; copy them into your app. The live demo is
built from them.

Each is upstream's block, at the commit Joinery pins: `login-01`, `signup-01`, `dashboard-01`,
and `sidebar-13`, upstream's settings dialog. Each shows in a frame of its own, as on
ui.shadcn.com, so its breakpoints are the frame's: pick a width above the preview to see it on a
phone or a tablet. Their layout is Tailwind's utilities, as upstream's is, so an app that copies
one in uses Tailwind (see [Installation](/getting-started/installation.md)).

<SectionList @section="blocks" />
