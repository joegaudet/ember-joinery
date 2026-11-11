---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Avatar` is shadcn's Avatar, with `@size` and its `Image`, `Fallback` and `Badge` parts, and
`AvatarGroup` with its `Count`. It is built on `@ember-joinery/primitives/avatar`, ember-primitives'
and Radix's headless Avatar: the image renders once it has loaded, the fallback shows until
then (after `@delayMs`) and if it fails, the URL goes on the image or the avatar, and the
avatar yields where its image is; `ImageLoader` loads an image off the page, and tests wait for
it. `@ember-joinery/test-support` adds `AvatarHarness` and `AvatarGroupHarness`.
