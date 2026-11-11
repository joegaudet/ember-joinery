import Component from '@glimmer/component'
import { idFor } from '@ember-joinery/primitives/id'

/** A field that names its parts from its own id, as Joinery's components do. */
class EmailField extends Component {
  get inputId() {
    return idFor(this, 'input') // 'jn-7-input'
  }

  get hintId() {
    return idFor(this, 'hint') // 'jn-7-hint'
  }

  <template>
    <div data-test-jn="email-field">
      <label for={{this.inputId}} data-test-jn-part="label">Email</label>
      <input
        id={{this.inputId}}
        type="email"
        aria-describedby={{this.hintId}}
        data-test-jn-part="input"
      />
      <p id={{this.hintId}} data-test-jn-part="hint">We never share it.</p>
    </div>
  </template>
}

<template><EmailField /></template>
