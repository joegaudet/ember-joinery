---
'@ember-joinery/carousel': minor
'@ember-joinery/code-block': minor
'@ember-joinery/file-upload': minor
'@ember-joinery/maskito': minor
'@ember-joinery/power-calendar': minor
'@ember-joinery/tiptap': minor
---

The add-ons' built-in strings go through the app's translator, each package's in its own
`<package>/messages`: Carousel's role descriptions, slide names (`{index} of {count}`) and step
buttons; Code Block's Copy and Copied; File Upload's prompt, hint, drop label, its rejected,
left-out, remove, retry and progress names, Upload failed and `FILE`; Phone Input's country
picker's name; Power Calendar's month buttons, its calendars' names and the pickers' placeholder,
trigger names and range (`{from} – {to}`); the Rich Text Editor's toolbar, text styles,
tools and its shortcuts' Ctrl, Shift and Alt. An argument still wins. File Upload's, Phone Input's and Power Calendar's `@locale`
default to the translator's. Chart and Data Table show no strings of their own.
