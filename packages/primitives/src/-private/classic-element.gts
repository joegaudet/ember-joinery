// Before Ember 7.1 there is no `element` helper, and a classic component's `tagName` is the
// one public way to render an element whose tag is chosen at runtime (the technique behind
// ember-element-helper). `As` uses this only on those versions; see as.gts.
// eslint-disable-next-line ember/no-classic-components
import EmberComponent from '@ember/component'

export interface ClassicElementSignature {
  Args: { tagName: string }
  Blocks: { default: [] }
  // Whichever tag `tagName` names; `As` declares the type from its `@tag`.
  Element: any
}

// eslint-disable-next-line ember/require-tagless-components
export default class ClassicElement extends EmberComponent<ClassicElementSignature> {
  <template>{{yield}}</template>
}
