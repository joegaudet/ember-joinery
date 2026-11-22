---
'@ember-joinery/power-calendar': patch
'@ember-joinery/primitives': patch
---

The date pickers track their modes with a Switchyard chart; nothing changes in behavior, except that a close a controlled `@open` refuses no longer forgets the month paged to or the start of a range. A controlled Dialog no longer calls `@onClose`, nor clears its `returnValue`, for a close or open its `@open` refused, and InputOTP clears its pending selection sync when it goes.
