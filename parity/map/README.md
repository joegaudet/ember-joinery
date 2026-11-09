# Parity map

One file per upstream docs page, `<component>.json` (the page's name in
`apps/v4/content/docs/components/radix`, or `chart` for the charts gallery and `blocks` for
blocks). Each maps upstream example ids to the Joinery guide examples that port them:

```json
{
  "examples": {
    "button-demo": "button-demo",
    "button-rtl": {
      "example": "button-rtl",
      "threshold": 0.02,
      "reason": "Arabic text shapes differently in Glimmer's whitespace."
    },
    "button-group-demo": { "skip": "Shown on Button Group's page too, and compared there." }
  }
}
```

- A string is the Joinery example's name (`docs-app/app/examples/<name>.gts`).
- `threshold` overrides the default (1% of the content box's pixels may differ; see "Parity" in
  CONTRIBUTING.md) and needs a written `reason`. It is one fraction for both themes, or one for
  each, `{ "light": 0.04, "dark": 0.13 }`, where the two themes differ by more than a point or
  so, so the theme that differs less isn't given the other's slack.
- `fullWidth: true` stretches the example across both stages (`?fullWidth=true`), for one that
  upstream shows full width: the chart demo, whose preview has `[&_.preview>div]:w-full`, and
  the charts gallery's interactive charts, in a cell the gallery's whole width. Centred on a
  plain stage, an example with no width of its own shrinks to its content, and a chart in it to
  nothing. The guide's `<Example @fullWidth={{true}}>` does the same in its preview.
- `skip` marks an example that can't be compared, with the reason. It still counts as mapped.

An example shown on two pages is mapped once, in either page's file. `pnpm parity` checks every
file against `upstream/inventory.json`, and with `--require-complete` it fails when any docs page
example or chart is missing from the map.
