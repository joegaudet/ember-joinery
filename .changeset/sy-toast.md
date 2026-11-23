---
'@ember-joinery/primitives': patch
---

Toasts run their life, swipe and auto-close timer on Switchyard statecharts; nothing changes in how they behave. A `toast.promise()` toast dismissed while it waits now stays dismissed, instead of coming back as the success or error toast.
