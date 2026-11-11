---
'@ember-joinery/primitives': minor
'@ember-joinery/test-support': minor
---

ember-primitives' app utilities, one subpath export each: `store` (`createStore`, one instance
per context, owner or none, with `findOwner` and `isOwner`), `service` (now also `(service "router")` for a
registered service, and `asyncService` for one loaded on demand), `head` (`InHead`),
`body-class` (`{{bodyClass}}`), `iframe` (`inIframe`, `notInIframe`), `load` (a component that
loads another), `qp` (`qp`, `withQP`, `castToBoolean`), `link-helper` (the `link` helper:
external, active, and a routed click, with `isExternalLink`, `isActiveLink` and
`dynamicSegments`), `proper-links` (`@properLinks`, `setupProperLinks`,
`shouldHandle`), `viewport` (`viewport()` and `InViewport`), `on-resize` (`{{onResize}}`),
`resize-observer` (`resizeObserver()` and `ignoreROError`), `dom-context` (`Provide` and `Consume`) and `narrowing` (`isString`,
`isElement`, `isNewable`, `isNonNullableObject`, `Newable`). `@ember-joinery/test-support` adds `setupRouting` and
`getRouter`, and `waitForObservers` and `scrollIntoView` for what the observers report.
