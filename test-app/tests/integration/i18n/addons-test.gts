import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { unlocalized } from 'test-app/tests/helpers/pseudo'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { pseudoTranslator, setupTranslator } from '@ember-joinery/test-support'
import { Carousel } from '@ember-joinery/carousel'
import { messages as carouselMessages } from '@ember-joinery/carousel/messages'
import { CodeBlock } from '@ember-joinery/code-block'
import { setupClipboard } from '@ember-joinery/code-block/test-support'
import type { UploadFile } from 'ember-file-upload'
import { FileUpload } from '@ember-joinery/file-upload'
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'
import { PhoneInput } from '@ember-joinery/maskito'
import {
  DatePicker,
  DateRangePicker,
  PowerCalendar,
  PowerCalendarMultiple,
  PowerCalendarRange,
} from '@ember-joinery/power-calendar'
import { DatePickerHarness } from '@ember-joinery/power-calendar/test-support'
import { RichTextEditor } from '@ember-joinery/tiptap'
import { RichTextEditorHarness } from '@ember-joinery/tiptap/test-support'

// What a test passes in itself is written pseudo-localized, so only Joinery's own strings can
// show up unwrapped.
const SLIDES = ['⟦1⟧', '⟦2⟧']
const MARCH_4 = new Date(2026, 2, 4)
const RANGE = { from: new Date(2026, 2, 4), to: new Date(2026, 2, 6) }
// Dates, numbers and the names of months, days and countries are Intl's, not messages.
const INTL = [
  /^(Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day(, \w+ \d+, 2026)?$/,
  /^(Su|Mo|Tu|We|Th|Fr|Sa)$/,
  /^\w+ 2026$/,
  /^\+\d+$/,
  /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)$/,
  /^Mar 4 – 6, 2026$/,
  /^United States$/,
  /^\.txt$/,
]
const file = (name: string) => new File(['x'], name, { type: 'text/plain' })
const never = (_upload: UploadFile): Promise<unknown> => new Promise(() => {})
const fail = (_upload: UploadFile): Promise<unknown> => Promise.reject(new Error(''))

module('Integration | i18n | add-ons', function (hooks) {
  setupRenderingTest(hooks)
  setupClipboard(hooks)

  module('with the pseudo-locale', function (hooks) {
    setupTranslator(hooks, pseudoTranslator)

    test('every built-in string goes through the translator', async function (assert) {
      await render(
        <template>
          <Carousel style="width: 320px; margin: 0 64px" as |c|>
            <c.Content>
              {{#each SLIDES as |n|}}<c.Item>{{n}}</c.Item>{{/each}}
            </c.Content>
            <c.Previous />
            <c.Next />
          </Carousel>
          <CodeBlock as |b|>
            <b.Header><b.Actions><b.CopyButton @value="⟦x⟧" /></b.Actions></b.Header>
            <b.Content @code="1" />
          </CodeBlock>
          <PhoneInput aria-label="⟦phone⟧" />
          <label>⟦mobile⟧ <PhoneInput /></label>
          <PowerCalendar @defaultValue={{MARCH_4}} />
          <PowerCalendarMultiple />
          <PowerCalendarRange />
          <DateRangePicker @name="range" @defaultValue={{RANGE}} />
          <DatePicker @name="empty" />
          <RichTextEditor @label="⟦body⟧" />
        </template>,
      )
      assert.deepEqual(unlocalized(undefined, INTL), [], 'closed')
      assert
        .dom('[data-slot="carousel"]')
        .hasAttribute('aria-roledescription', pseudoTranslator.t(carouselMessages.carousel))
      await new DatePickerHarness('range').open()
      assert.deepEqual(unlocalized(undefined, INTL), [], 'with a picker open')
      await a11yAudit()
    })

    test('the file upload, its queue and its messages', async function (assert) {
      await render(
        <template>
          <FileUpload @name="one" @upload={{never}} @accept=".txt" />
          <FileUpload @name="many" @multiple={{true}} @upload={{fail}} />
        </template>,
      )
      const one = new FileUploadHarness('one')
      // Its description is `@accept`, the caller's; a file's name, kind and size are the file's.
      const ACCEPT = [/\.txt$/, /^TXT$/, /^\d+ byte$/]
      assert.deepEqual(unlocalized(undefined, ACCEPT), [], 'empty')
      await one.select(file('⟦a⟧.txt'))
      await one.drop(file('⟦b⟧.txt'), file('⟦c⟧.txt'))
      await new FileUploadHarness('many').select(file('⟦d⟧'))
      assert.true(one.leftOut?.startsWith('⟦'), one.leftOut)
      assert.deepEqual(one.uploading, ['⟦b⟧.txt'], 'queued')
      assert.deepEqual(new FileUploadHarness('many').failed, ['⟦d⟧'])
      assert.deepEqual(unlocalized(undefined, ACCEPT), [], 'queued, left out and failed')
      await one.drop(new File(['x'], '⟦e⟧.exe'))
      assert.true(one.rejected?.startsWith('⟦'), one.rejected)
      assert.deepEqual(unlocalized(undefined, ACCEPT), [], 'turned away')
      await a11yAudit()
    })

    test("the rich text editor's tooltips and text styles, with Ctrl's keys", async function (assert) {
      // The keys are words (Ctrl, Shift, Alt) off Apple's systems, which show ⌘, ⇧ and ⌥.
      const platform = Object.getOwnPropertyDescriptor(Navigator.prototype, 'platform')!
      Object.defineProperty(Navigator.prototype, 'platform', {
        get: () => 'Linux x86_64',
        configurable: true,
      })
      try {
        await render(<template><RichTextEditor @label="⟦body⟧" /></template>)
        const editor = new RichTextEditorHarness()
        // A key's own letter is the key's.
        const KEYS = [/^[A-Z0-9]$/]
        await editor.hoverTool('bold')
        assert.true(editor.tooltip('bold').startsWith('⟦'), editor.tooltip('bold'))
        assert.deepEqual(unlocalized(undefined, KEYS), [], 'a tooltip open')
        await editor.blockTypeMenu.open()
        assert.deepEqual(unlocalized(undefined, KEYS), [], 'the text style menu open')
        await a11yAudit()
      } finally {
        Object.defineProperty(Navigator.prototype, 'platform', platform)
      }
    })

    test('an explicit argument beats the translator', async function (assert) {
      await render(<template><PowerCalendar @label="Due" @previousMonthLabel="Back" /></template>)
      assert.dom('[data-slot="calendar"]').hasAttribute('aria-label', 'Due')
      assert.dom('[aria-label="Back"]').exists()
      await a11yAudit()
    })
  })

  module('with a translator in German', function (hooks) {
    setupTranslator(hooks, { locale: 'de', t: pseudoTranslator.t })

    test('the calendars take its locale, unless @locale is given', async function (assert) {
      await render(<template><PowerCalendar @defaultValue={{MARCH_4}} /></template>)
      assert.dom('[data-slot="calendar"]').includesText('März 2026')
      await render(<template><PowerCalendar @defaultValue={{MARCH_4}} @locale="fr" /></template>)
      assert.dom('[data-slot="calendar"]').includesText('mars 2026')
      await a11yAudit()
    })
  })

  test('with no translator, English', async function (assert) {
    await render(<template><PowerCalendar /></template>)
    assert.dom('[data-slot="calendar"]').hasAttribute('aria-label', 'Choose date')
    await a11yAudit()
  })
})
