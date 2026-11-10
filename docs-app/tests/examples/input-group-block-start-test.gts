import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, FieldGroupHarness, InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupBlockStart from 'docs-app/examples/input-group-block-start'

module('Example | input-group-block-start', function (hooks) {
  setupRenderingTest(hooks)

  test('a header above an input, and a file header above a textarea', async function (assert) {
    await render(<template><InputGroupBlockStart /></template>)
    const [inputField, textareaField] = new FieldGroupHarness().fields
    const input = inputField!.find(InputGroupHarness)
    const textarea = textareaField!.find(InputGroupHarness)

    assert.strictEqual(input.label, 'Input')
    assert.strictEqual(inputField!.description, 'Header positioned above the input.')
    assert.deepEqual(input.aligns, ['block-start'])
    assert.deepEqual(input.texts, ['Full Name'])
    assert.ok(
      input.addon('block-start').getBoundingClientRect().bottom <=
        input.control.getBoundingClientRect().top,
      'the header is above the input',
    )
    assert.ok(
      input.element.offsetHeight > input.control.offsetHeight,
      'h-auto: it grows to hold both',
    )

    assert.dom(textarea.control).hasTagName('textarea')
    assert.strictEqual(textarea.label, 'Textarea')
    assert.strictEqual(textareaField!.description, 'Header positioned above the textarea.')
    assert.deepEqual(textarea.texts, ['script.js'])
    assert.strictEqual(textarea.icons.length, 2, 'the file icon and the copy icon')
    const copy = textarea.find(ButtonHarness)
    assert.strictEqual(copy.label, 'Copy', 'named by its sr-only text')
    assert.strictEqual(copy.size, 'icon-xs')
    const header = textarea.addon('block-start').getBoundingClientRect()
    const button = copy.element.getBoundingClientRect()
    assert.ok(header.right - button.right < 16, 'ml-auto: the copy button goes to the end')
    assert.ok(button.left - header.left > header.width / 2)
    assert.ok(
      textarea.addon('block-start').getBoundingClientRect().bottom <=
        textarea.control.getBoundingClientRect().top,
      'the header is above the textarea',
    )
    await textarea.fillIn("console.log('hi')")
    assert.strictEqual(textarea.value, "console.log('hi')")
    await a11yAudit()
  })
})
