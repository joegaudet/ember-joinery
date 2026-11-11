---
'@ember-joinery/carousel': major
'@ember-joinery/ember': minor
---

`@ember-joinery/carousel` is a new add-on: shadcn's Carousel, on Embla's framework-agnostic
`embla-carousel`. `Carousel` takes upstream's `@orientation`, `@opts`, `@plugins` and `@setApi`,
and yields `Content`, `Item`, `Previous` and `Next` (with `item`, `previous` and `next`
modifiers) and what upstream's `useCarousel()` returns: `api`, `canScrollPrev`, `canScrollNext`,
`scrollPrev`, `scrollNext`, `scrollTo` and `orientation`. It takes its direction from the
nearest `dir` and follows it, flips the arrow keys right to left, takes the up and down arrows
when vertical, names each slide by its place (`@slideLabel`), and reinitializes in place when
its options or plugins change. `{{embla}}` is its headless part, for markup of your own. Its
`/test-support` has `CarouselHarness`, and `settled()` waits for a carousel to come to rest.
`@ember-joinery/ember`'s style sheets style its parts.
