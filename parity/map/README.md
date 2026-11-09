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
- `threshold` overrides the default (1% of pixels may differ) and needs a written `reason`.
- `skip` marks an example that can't be compared, with the reason. It still counts as mapped.

An example shown on two pages is mapped once, in either page's file. `pnpm parity` checks every
file against `upstream/inventory.json`, and with `--require-complete` it fails when any docs page
example or chart is missing from the map.
