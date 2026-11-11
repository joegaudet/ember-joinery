import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, FieldGroupHarness, InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupBlockEnd from 'docs-app/examples/input-group-block-end'

module('Example | input-group-block-end', function (hooks) {
  setupRenderingTest(hooks)

  test('a footer below an amount, and a counter and Post button below a comment', async function (assert) {
    await render(<template><InputGroupBlockEnd /></template>)
    const [amountField, commentField] = new FieldGroupHarness().fields
    const amount = amountField!.find(InputGroupHarness)
    const comment = commentField!.find(InputGroupHarness)

    assert.strictEqual(amount.label, 'Input')
    assert.strictEqual(amountField!.description, 'Footer positioned below the input.')
    assert.strictEqual(amount.placeholder, 'Enter amount')
    assert.deepEqual(amount.aligns, ['block-end'])
    assert.deepEqual(amount.texts, ['USD'])
    assert.ok(
      amount.control.getBoundingClientRect().bottom <=
        amount.addon('block-end').getBoundingClientRect().top,
      'the footer is below the input',
    )
    assert.ok(amount.element.offsetHeight > amount.control.offsetHeight, 'h-auto')

    assert.dom(comment.control).hasTagName('textarea')
    assert.strictEqual(comment.label, 'Textarea')
    assert.strictEqual(commentField!.description, 'Footer positioned below the textarea.')
    assert.deepEqual(comment.texts, ['0/280'])
    const post = comment.find(ButtonHarness)
    assert.strictEqual(post.label, 'Post')
    assert.strictEqual(post.variant, 'default')
    assert.strictEqual(post.size, 'sm')
    const footer = comment.addon('block-end').getBoundingClientRect()
    const button = post.element.getBoundingClientRect()
    assert.ok(footer.right - button.right < 16, 'ml-auto: Post goes to the end')
    assert.ok(comment.control.getBoundingClientRect().bottom <= footer.top, 'below the textarea')

    await comment.fillIn('Looks good')
    assert.strictEqual(comment.value, 'Looks good')
    await a11yAudit()
  })
})
