# Joinery

Contributor guide: [CONTRIBUTING.md](CONTRIBUTING.md). The gate is in its "The gate" section: run
it, don't assume it. The plan and every decision behind it: [JOINERY_PLAN.md](JOINERY_PLAN.md).
Change a decision only with the maintainer's agreement, and record the change at the top of the
plan.

## Port from upstream, not from memory

Joinery copies https://ui.shadcn.com/. Port from the upstream source at the commits pinned in
`upstream.json` (until that file exists, the plan's header has the pins): shadcn-ui/ui
`apps/v4/registry/new-york-v4/` and universal-ember/ember-primitives `ember-primitives/src`.
Before writing a component, read its `.tsx`, its docs page and every upstream example for it.

## A component ships whole

A component is done only when it has all of these, in the same PR:

- its harness class in `@ember-joinery/test-support` (or its add-on's `/test-support`);
- its own tests, written with that harness, ending in an axe audit, and covering its WAI-ARIA
  keyboard pattern;
- a guide page with every upstream example for it, each one tested with the harness;
- a parity mapping for each of those examples in `parity/map.json`;
- a changeset.

The full checklist is "Definition of done for every component" in the plan.

## Keep upstream.json honest

`upstream.json` changes only in a sync PR, and that PR ports everything that changed upstream
between the old commit and the new one.

## Keep the website in sync

The site at `docs/site/` is hand-written HTML, not generated. When a change touches anything it
shows (packages, components, arguments, an API used in one of its snippets), update `docs/site/`
in the same PR. The live demo is `test-app/app`.

## Keep the guide in sync

The guide (`docs-app/`) documents every public component, argument, primitive and harness, each
with a live, tested example. A change to the public API updates its guide page and example in the
same PR. See "The guide" in CONTRIBUTING.md.
