# Introduction

Joinery is [shadcn/ui](https://ui.shadcn.com/) for Ember: every component on ui.shadcn.com,
written the modern Ember way, on a headless primitives layer, and each with a test harness.

- **Components you compose.** Each component yields its parts
  (`<Dialog as |d|><d.Trigger>…</d.Trigger><d.Content>…`), and its state can be left to it or
  controlled through `@open` and `@onOpenChange`, `@value` and `@onValueChange`, as in Radix.
- **shadcn's design, compiled.** The styles are shadcn's own style sheets, ported, and the
  theme tokens use shadcn's names, so any shadcn theme pastes in unchanged. The CSS ships
  compiled, so Tailwind is optional.
- **Headless primitives.** `@ember-joinery/primitives` is the unstyled, accessible behaviour
  underneath, including everything [ember-primitives](https://github.com/universal-ember/ember-primitives)
  offers. Use it on its own when you bring your own styles.
- **A harness for every component.** `@ember-joinery/test-support` drives each component the
  way a user does, and reads its state through ARIA, so every test checks the ARIA contract too.
- **Accessible.** WCAG 2.2 AA, the WAI-ARIA keyboard patterns, and right-to-left layouts.

<div class="callout">

**Joinery is being built.** It lands in stages, and nothing is on npm yet. The plan, and every
decision behind it, is in
[JOINERY_PLAN.md](https://github.com/joegaudet/ember-joinery/blob/main/JOINERY_PLAN.md). The
sidebar lists what exists so far.

</div>

## Live examples

Every example in this guide is live, and every one is tested.

<Example @name="introduction" @title="A first example" />

**Preview** shows the example running. **Template** shows its exact source, and **Test** shows
the test that covers it: write yours the same way. Each component page shows every example its
[ui.shadcn.com](https://ui.shadcn.com/docs/components) page has, ported.

## Where to next

- [Installation](/getting-started/installation.md): add Joinery to a Vite, classic or Tailwind
  app.
- [Components](/components/index.md): every component, A to Z.
- [Primitives](/primitives/index.md): the headless layer, and the utilities that come with it.
