import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import { Progress } from '@ember-joinery/ember'

export default class ProgressDemo extends Component {
  @tracked progress = 13

  constructor(owner: Owner, args: object) {
    super(owner, args)
    const timer = setTimeout(() => (this.progress = 66), 500)
    registerDestructor(this, () => clearTimeout(timer))
  }

  <template>
    {{! Upstream's has no name; Joinery's has one, so it passes the accessibility audit. }}
    <Progress @value={{this.progress}} class="w-[60%]" aria-label="Progress" />
  </template>
}
