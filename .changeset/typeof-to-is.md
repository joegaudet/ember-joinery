---
'@ember-joinery/carousel': patch
'@ember-joinery/chart': patch
'@ember-joinery/code-block': patch
'@ember-joinery/data-table': patch
'@ember-joinery/ember': patch
'@ember-joinery/file-upload': patch
'@ember-joinery/formwright': patch
'@ember-joinery/power-calendar': patch
'@ember-joinery/primitives': patch
'@ember-joinery/test-support': patch
'@ember-joinery/tiptap': patch
---

Type checks in package source use `@sindresorhus/is` (`isString`, `isFunction`, …) instead of `typeof`, and a lint rule keeps it that way. `@sindresorhus/is` is a new runtime dependency, so `ember-joinery add` now installs it into the app for most components, `icon` included. `isNumber` rejects `NaN`, so a `NaN` reaching a numeric check now takes the non-number branch.
