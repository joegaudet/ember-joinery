# Introduction

Joinery is [shadcn/ui](https://ui.shadcn.com/) for Ember: every component on ui.shadcn.com,
written the modern Ember way, on a headless primitives layer, and each with a test harness.

- **Components you compose.** Each component yields its parts
  (`<Dialog as |d|><d.Trigger>…</d.Trigger><d.Content>…`), and its state can be left to it or
  controlled through `@open` and `@onOpenChange`, `@value` and `@onValueChange`, as in Radix.
  Every part takes `@as` for another tag, or a modifier for your own element
  (`<LinkTo {{d.trigger}}>`), as upstream's `asChild` does.
- **shadcn's design, compiled.** The styles are shadcn's own style sheets, all eight of them,
  ported, and the theme tokens use shadcn's names, so any shadcn theme pastes in unchanged. The
  CSS ships compiled, so Tailwind is optional.
- **Headless primitives.** `@ember-joinery/primitives` is the unstyled, accessible behaviour
  underneath, including everything [ember-primitives](https://github.com/universal-ember/ember-primitives)
  offers. Use it on its own when you bring your own styles.
- **A harness for every component.** `@ember-joinery/test-support` drives each component the
  way a user does, and reads its state through ARIA, so every test checks the ARIA contract too.
- **Accessible.** WCAG 2.2 AA, the WAI-ARIA keyboard patterns, and right-to-left layouts.

<div class="callout">

**Joinery 1.0.0 is in review.** Every component is built, and nothing is on npm yet: the
packages publish once the release is merged. The plan, and every decision behind it, is in
[JOINERY_PLAN.md](https://github.com/joegaudet/ember-joinery/blob/main/JOINERY_PLAN.md).

</div>

## Live examples

Every example in this guide is live, and every one is tested.

<Example @name="introduction" @title="A first example" />

**Preview** shows the example running. **Template** shows its exact source, and **Test** shows
the test that covers it: write yours the same way. Each component page shows every example its
[ui.shadcn.com](https://ui.shadcn.com/docs/components) page has, ported, and the switchers above
a preview show it in any style, base colour and radius, light or dark, right to left, and at a
phone's width.

## The packages

| Package                       | What it holds                                                                                                                                                            |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `@ember-joinery/ember`        | The styled components, their CSS and the theme tokens                                                                                                                    |
| `@ember-joinery/primitives`   | The headless behaviour, and ember-primitives' utilities                                                                                                                  |
| `@ember-joinery/test-support` | A harness for every component and primitive, and the testing helpers                                                                                                     |
| Opt-in add-ons                | Chart, Carousel, Data Table, Code Block, File Upload, Rich Text Editor, Power Calendar, Masked and Phone Input, and the Formwright bridge, each a package on its library |

## Where to next

- [Installation](/getting-started/installation.md): add Joinery to a Vite, classic or Tailwind
  app.
- [Theming](/getting-started/theming.md), [Styles](/getting-started/styles.md) and the
  [Theme Builder](/getting-started/theme-builder.md): make it look like yours.
- [Dark mode](/getting-started/dark-mode.md) and [RTL](/getting-started/rtl.md).
- [Testing](/getting-started/testing.md): harnesses, page objects and the selectors.
- [Components](/components/index.md): every component, A to Z.
- [Primitives](/primitives/index.md): the headless layer, and the utilities that come with it.
- [Charts](/charts/index.md), [Blocks](/blocks/index.md) and
  [Formwright](/formwright/index.md).
- [API reference](/reference/index.md): every package's API, generated from its types.
