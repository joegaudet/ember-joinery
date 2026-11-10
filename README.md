# Joinery

shadcn/ui for Ember: every component on [ui.shadcn.com](https://ui.shadcn.com/), in modern Ember,
on a headless primitives layer, and each with a test harness.

> **Status: pre-release.** Nothing is published yet. The plan, and every decision behind it, is in
> [JOINERY_PLAN.md](JOINERY_PLAN.md). The work lands as one stacked PR, and nothing publishes until
> it has been reviewed and merged. The first release is 1.0.0.

## What it will be

- **Every shadcn/ui component**, written the modern Ember way: `.gts` template-tag components
  with full Glint types, yielded parts (`<Dialog as |d|><d.Trigger>`), state you can control or
  leave to the component, and typed `@variant` and `@size` arguments.
- **Headless primitives** (`@ember-joinery/primitives`): the unstyled, accessible behaviour
  underneath, including everything [ember-primitives](https://github.com/universal-ember/ember-primitives)
  offers.
- **shadcn's theme tokens**, so any shadcn theme pastes in unchanged. The CSS ships compiled, so
  Tailwind is optional.
- **A harness for every component** (`@ember-joinery/test-support`). Tests drive components the
  way users do, and check ARIA as they go.
- **Accessible:** WCAG 2.2 AA, WAI-ARIA keyboard patterns, and right-to-left layouts.
- **Opt-in add-ons** for the heavy parts: charts, carousel, data table, code block, file uploads,
  a rich-text editor, and a [Formwright](https://joegaudet.com/ember-formwright/) bridge.

```gts
import { Dialog, Button, Input } from '@ember-joinery/ember'

<template>
  <Dialog @name="edit-profile" as |d|>
    <d.Trigger>Edit profile</d.Trigger>
    <d.Content>
      <d.Header>
        <d.Title>Edit profile</d.Title>
        <d.Description>Make changes to your profile here.</d.Description>
      </d.Header>
      <Input @name="name" @value={{this.name}} @onValueChange={{this.setName}} />
      <d.Footer>
        <d.Close>Cancel</d.Close>
        <Button>Save changes</Button>
      </d.Footer>
    </d.Content>
  </Dialog>
</template>
```

## Packages (planned)

| Package                       |                                                                                    |
| ----------------------------- | ---------------------------------------------------------------------------------- |
| `@ember-joinery/ember`        | The styled components, their CSS and the theme tokens                              |
| `@ember-joinery/primitives`   | Headless behaviour and utilities                                                   |
| `@ember-joinery/test-support` | A harness for every component                                                      |
| `@ember-joinery/chart`        | Charts: Glimmer SVG on d3                                                          |
| `@ember-joinery/carousel`     | Carousel, on embla-carousel                                                        |
| `@ember-joinery/data-table`   | Data table, on @tanstack/table-core                                                |
| `@ember-joinery/code-block`   | Code block, on shiki                                                               |
| `@ember-joinery/file-upload`  | File uploads (drop zone, file list, upload queue), on ember-file-upload            |
| `@ember-joinery/tiptap`       | Rich-text editor with a formatting toolbar, on Tiptap                              |
| `@ember-joinery/formwright`   | Joinery's inputs as [Formwright](https://joegaudet.com/ember-formwright/) controls |

These will support Ember 6.12 LTS and 7.x, in Vite (Embroider) apps and classic ember-cli apps.

## Links

- Site and live demo: https://joegaudet.com/ember-joinery/ (not live yet)
- Guide: https://joegaudet.com/ember-joinery/guide/ (not live yet)
- Sibling projects: [Formwright](https://joegaudet.com/ember-formwright/) (forms) and
  [real-enums](https://joegaudet.com/real-enums/).

## Credits

Joinery is an independent project, not affiliated with shadcn/ui. Its design, component APIs and
examples are ported from [shadcn/ui](https://ui.shadcn.com/) (MIT, © shadcn), and its headless
layer covers the features of [ember-primitives](https://github.com/universal-ember/ember-primitives)
(MIT). Its toasts port [sonner](https://github.com/emilkowalski/sonner) (MIT, © Emil Kowalski),
which shadcn/ui's Sonner wraps, its charts port [recharts](https://github.com/recharts/recharts)
(MIT, © recharts), which shadcn/ui's charts are built on, its Drawer ports
[vaul](https://github.com/emilkowalski/vaul) (MIT, © Emil Kowalski), which shadcn/ui's Drawer is
built on, and its Command follows [cmdk](https://github.com/dip/cmdk) (MIT, © Paco Coursey),
which shadcn/ui's Command is built on, and ports its command score. Its file uploads are built on
[ember-file-upload](https://github.com/adopted-ember-addons/ember-file-upload) (MIT), and its
rich-text editor on [Tiptap](https://github.com/ueberdosis/tiptap) (MIT, © Tiptap GmbH). See
[NOTICE](NOTICE).

## License

MIT. See [LICENSE.md](LICENSE.md).
