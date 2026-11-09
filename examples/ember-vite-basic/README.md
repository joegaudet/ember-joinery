# ember-vite-basic

Joinery in a Vite (Embroider) Ember app: the packages imported into `.gjs` files and
`joinery.css` imported once from `app/app.js`, plus two add-ons: `@ember-joinery/code-block`,
whose Code Block loads Shiki on demand, and `@ember-joinery/carousel`, whose Carousel its smoke
test moves with `CarouselHarness`. CI builds it and runs its smoke test.

```bash
pnpm --filter ember-vite-basic test
```
