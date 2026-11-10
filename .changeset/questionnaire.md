---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Questionnaire` is shadcn's Questionnaire: a multi-step native form of single-choice,
multiple-choice, freeform and skippable questions, with progress, validation (its own, or yours
through `@invalid` and `@message`), navigation buttons that show where they apply, letter or
number shortcuts, the keyboard of upstream's (arrows between answers and items, flipped right to
left; `Enter` and `Meta+Enter` to confirm), a controlled or uncontrolled active item
(`@item`, `@defaultItem`, `@onItemChange`), controlled or default answers, and a reset that puts
them back. Its behaviour is `@ember-joinery/primitives/questionnaire`, @shadcn/react's headless
Questionnaire, whose state classes put their parts on any element, so a card's or a dialog's
title can be the question (`{{i.title}}`). `@ember-joinery/test-support` adds
`QuestionnaireHarness`.
