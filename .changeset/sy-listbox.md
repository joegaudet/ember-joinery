---
'@ember-joinery/primitives': patch
---

Combobox and the typeahead search (used by Select, menus and `{{typeahead}}`) now keep their modes in Switchyard statecharts; nothing changes in behavior. Fixed: a combobox whose controlled `@open` refuses a close no longer stops filtering, and a combobox reopened while its list animates out filters by what is typed instead of the query it closed with.
