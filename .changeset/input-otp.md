---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`InputOTP` is shadcn's Input OTP, yielding its `Group`, `Slot` and `Separator`, on a new
`@ember-joinery/primitives/input-otp`: the `input-otp` library's one invisible native input under
slots you render, which also covers ember-primitives' `OTP`. Its code is controlled or not
(`@value`, `@defaultValue`, `@onValueChange`), `@pattern` (`REGEXP_ONLY_DIGITS` and the rest)
refuses what it doesn't match, every paste goes through `@pasteTransformer`, `@onComplete` hears
a complete code, `@autoSubmit` submits its form, and a browser's autofill of a code it was sent
fills it at once. `@ember-joinery/test-support` adds `InputOTPHarness`, which types, deletes,
moves the caret, pastes and autofills as a browser does, and ember-primitives' `fillOTP`.
