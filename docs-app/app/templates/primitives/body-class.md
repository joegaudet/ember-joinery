# Body Class

`{{bodyClass}}` puts classes on `<body>` while it renders and takes them off when it stops:
from a route's template, the classes are on `<body>` while that route shows. It is
ember-primitives' `bodyClass` (from ember-set-body-class).

<Example @name="body-class-lock-scroll" @title="Locking the page's scrolling" />

## Usage

```gts
import { bodyClass } from '@ember-joinery/primitives/body-class'

<template>
  {{bodyClass "settings-page"}}
  {{bodyClass (if this.menuOpen "menu-open")}}
</template>
```

The argument is reactive and takes several classes, separated by spaces. Several helpers can
ask for the same class; it stays until none of them does.

## API

| Argument  | Type                          | What it does                                    |
| --------- | ----------------------------- | ----------------------------------------------- |
| (classes) | `string \| undefined \| null` | The classes to put on `<body>`, space-separated |

### From ember-primitives

Two differences. A class `<body>` already had (from `index.html`, or your own code) is never
taken off, even when a helper asked for it too; ember-primitives takes it off. And the classes
apply as the helper renders, rather than on the next animation frame.

## Testing

The classes are on `document.body`: `assert.dom(document.body).hasClass('menu-open')`. They
come off when the test's render is torn down, so nothing bleeds into the next test.
