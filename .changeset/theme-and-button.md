---
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

The theme and the first components. `@ember-joinery/ember` ships shadcn's eight styles compiled
to plain CSS in `@layer joinery` (Nova as `joinery.css`; Luma, Lyra, Maia, Mira, Rhea, Sera and
Vega as `styles/<style>.css`), with logical sides so each works right to left; shadcn's tokens
in OKLCH, light and `.dark` (`tokens.css`, the Neutral base colour, and `themes/<colour>.css`
for Neutral, Stone, Zinc, Mauve, Olive, Mist and Taupe); and `tailwind.css`, the tokens as
Tailwind's theme for Tailwind apps. `Icon` draws `lucide` icons, imported one at a time.
`Button` is shadcn's Button, with typed `@variant` and `@size`, `@as`, and a `button` modifier
for your own elements (`<LinkTo {{button}}>`); `Spinner` is shadcn's loading indicator.
`@ember-joinery/test-support` adds `ButtonHarness`, `IconHarness` and `SpinnerHarness`.
