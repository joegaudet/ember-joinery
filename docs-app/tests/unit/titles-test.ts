import { module, test } from 'qunit'
import { title } from 'docs-app/titles'

module('Unit | title', function () {
  test('names read in title case, as in the ui.shadcn.com sidebar', function (assert) {
    assert.strictEqual(title('getting-started'), 'Getting Started')
    assert.strictEqual(title('alert-dialog'), 'Alert Dialog')
    assert.strictEqual(title('button.md'), 'Button')
    assert.strictEqual(title('chart.gts.md'), 'Chart')
  })

  test('acronyms keep their capitals', function (assert) {
    assert.strictEqual(title('input-otp'), 'Input OTP')
    assert.strictEqual(title('rtl'), 'RTL')
  })

  test("a section's index page is its overview", function (assert) {
    assert.strictEqual(title('index'), 'Overview')
    assert.strictEqual(title('index.md'), 'Overview')
  })
})
