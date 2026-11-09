import { uniqueId } from '@ember-joinery/primitives/id'

<template>
  {{#let (uniqueId) (uniqueId) as |emailId hintId|}}
    <label for={{emailId}}>Email</label>
    <input id={{emailId}} type="email" aria-describedby={{hintId}} />
    <p id={{hintId}}>We never share it.</p>
  {{/let}}
</template>
