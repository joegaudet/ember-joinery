import { isElement, isNewable, isString } from '@ember-joinery/primitives/narrowing'

class Card {}

const values: { label: string; value: unknown }[] = [
  { label: "'hello'", value: 'hello' },
  { label: '42', value: 42 },
  { label: 'a <p> element', value: document.createElement('p') },
  { label: 'class Card', value: Card },
  { label: '() => new Card()', value: () => new Card() },
]

const yesNo = (answer: boolean) => (answer ? 'yes' : 'no')

/** Type guards, in a template: what each value is. */
<template>
  <table data-test-jn="guards">
    <caption>What each value is</caption>
    <thead>
      <tr>
        <th scope="col">Value</th>
        <th scope="col">isString</th>
        <th scope="col">isElement</th>
        <th scope="col">isNewable</th>
      </tr>
    </thead>
    <tbody>
      {{#each values as |row|}}
        <tr data-test-jn-part="row" data-test-jn-value={{row.label}}>
          <th scope="row">{{row.label}}</th>
          <td>{{yesNo (isString row.value)}}</td>
          <td>{{yesNo (isElement row.value)}}</td>
          <td>{{yesNo (isNewable row.value)}}</td>
        </tr>
      {{/each}}
    </tbody>
  </table>
</template>
