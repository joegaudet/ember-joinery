import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { restoreFocus } from '@ember-joinery/primitives/focus'

const TASKS = ['Write the changeset', 'Port the styles', 'Test the harness', 'Ship it']

export default class FocusRestore extends Component {
  @tracked tasks = TASKS

  done = (task: string) => (this.tasks = this.tasks.filter(other => other !== task))
  reset = () => (this.tasks = TASKS)

  <template>
    <div class="focus-restore" data-test-jn="task-list">
      <ul class="focus-restore-tasks" aria-label="Tasks" {{restoreFocus}}>
        {{#each this.tasks as |task|}}
          <li data-test-jn-part="task" data-test-jn-value={{task}}>
            <span>{{task}}</span>
            <button
              type="button"
              aria-label="Done: {{task}}"
              data-test-jn-part="done"
              data-test-jn-value={{task}}
              {{on "click" (fn this.done task)}}
            >
              Done
            </button>
          </li>
        {{else}}
          <li>All done.</li>
        {{/each}}
      </ul>
      <button type="button" data-test-jn-part="reset" {{on "click" this.reset}}>Start again</button>
    </div>
    <style>
      .focus-restore {
        display: grid;
        gap: 0.75rem;
        width: min(22rem, 100%);
      }
      .focus-restore-tasks {
        display: grid;
        gap: 0.25rem;
        margin: 0;
        padding: 0;
        list-style: none;
      }
      .focus-restore-tasks li {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1rem;
        padding: 0.375rem 0.5rem;
        border: 1px solid color-mix(in oklab, currentColor 20%, transparent);
        border-radius: 0.375rem;
      }
    </style>
  </template>
}
