import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, focus, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import FocusRestore from 'docs-app/examples/focus-restore'

/** The example: a list of tasks, each with a Done button that removes it. */
class TaskListHarness extends Harness {
  static component = 'task-list'

  get tasks() {
    return this.values('task')
  }

  doneButton(task: string) {
    return this.part('done', task)
  }

  /** Presses a task's Done button, as a keyboard user would: focus it, then press it. */
  async complete(task: string) {
    await focus(this.doneButton(task))
    await click(this.doneButton(task))
  }
}

module('Example | focus-restore', function (hooks) {
  setupRenderingTest(hooks)

  test('removing the focused task keeps focus in the list', async function (assert) {
    await render(<template><FocusRestore /></template>)
    const list = new TaskListHarness()
    assert.deepEqual(list.tasks, [
      'Write the changeset',
      'Port the styles',
      'Test the harness',
      'Ship it',
    ])

    await list.complete('Port the styles')
    assert.deepEqual(list.tasks, ['Write the changeset', 'Test the harness', 'Ship it'])
    assert
      .dom(list.doneButton('Write the changeset'))
      .isFocused('focus goes to the first task left, not to <body>')

    await focus(list.doneButton('Ship it'))
    await focus(list.doneButton('Test the harness'))
    await click(list.doneButton('Test the harness'))
    assert.dom(list.doneButton('Ship it')).isFocused('or to the task focused before')
    await a11yAudit()
  })
})
