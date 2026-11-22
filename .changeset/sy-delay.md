---
'@ember-joinery/primitives': patch
---

Tooltips, navigation menus and submenus time their delays with Switchyard statecharts; nothing changes in behavior, except that a controlled tooltip or navigation menu whose parent refuses an open no longer makes the next one skip its delay (a refused tooltip open no longer closes the other tooltips either).
