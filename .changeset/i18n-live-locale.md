---
'@ember-joinery/primitives': patch
'@ember-joinery/carousel': patch
'@ember-joinery/power-calendar': patch
---

Built-in strings follow a live change of the translator's `locale`: a carousel's slide names
(`1 of 5`) and an input OTP's fallback name (`One-time password`) are set again in the new
language, not only on the next render. A date range picker reads typed text with the range
message it writes (`{from} – {to}`, or its translation), so a translated separator reads back,
and a dash, a hyphen or `to` still split English.
