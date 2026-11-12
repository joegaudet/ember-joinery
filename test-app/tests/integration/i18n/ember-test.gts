import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { unlocalized } from 'test-app/tests/helpers/pseudo'
import { click, render, settled } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  Breadcrumb,
  Calendar,
  Combobox,
  CommandDialog,
  Dialog,
  DocumentFileDrop,
  MessageScrollerProvider,
  Pagination,
  Questionnaire,
  Sheet,
  SidebarProvider,
  Spinner,
  NavigationMenu,
  Rating,
  Slider,
  Toaster,
} from '@ember-joinery/ember'
import { toast } from '@ember-joinery/primitives/toast'
import {
  DocumentFileDropHarness,
  pseudoTranslator,
  setupToaster,
  setupTranslator,
} from '@ember-joinery/test-support'
import { messages } from '@ember-joinery/ember/messages'
import { messages as primitiveMessages } from '@ember-joinery/primitives/messages'

// What a test passes in itself is written pseudo-localized, so only Joinery's own strings can
// show up unwrapped.
const ITEMS = ['⟦a⟧', '⟦b⟧']
const QUESTIONS = [{ name: 'q1', required: true, choices: [{ value: 'a' }] }, { name: 'q2' }]
const today = new Date(2026, 2, 12)
// Dates, and the names of months and days, are Intl's, not messages.
const DATES = [
  /^(Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day(, \w+ \d+, 2026)?$/,
  /^(Su|Mo|Tu|We|Th|Fr|Sa)$/,
  /^(January|February|March|April|May|June|July|August|September|October|November|December)( 2026)?$/,
  /^(Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$/,
]
const photo = new File(['photo'], 'photo.png', { type: 'image/png' })
const noop = () => {}
const shown = (message: Parameters<typeof pseudoTranslator.t>[0]) =>
  document.querySelector('#ember-testing')!.textContent!.includes(pseudoTranslator.t(message))

module('Integration | i18n | ember', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  module('with the pseudo-locale', function (hooks) {
    setupTranslator(hooks, pseudoTranslator)

    test('every built-in string goes through the translator', async function (assert) {
      await render(
        <template>
          <Breadcrumb as |b|>
            <b.List><b.Item><b.Ellipsis /></b.Item></b.List>
          </Breadcrumb>
          <Pagination as |p|>
            <p.Content>
              <p.Item><p.Previous href="#1" /></p.Item>
              <p.Item><p.Ellipsis /></p.Item>
              <p.Item><p.Next href="#3" /></p.Item>
              <p.Item><a href="#2" {{p.previous}}></a></p.Item>
            </p.Content>
          </Pagination>
          <Combobox @items={{ITEMS}} @defaultValue="⟦a⟧" as |c|>
            <c.Input aria-label="⟦one⟧" @showClear={{true}} />
            <c.Content><c.List as |item|><c.Item
                  @value={{item}}
                >{{item}}</c.Item></c.List></c.Content>
          </Combobox>
          <Combobox @items={{ITEMS}} @defaultValue="⟦a⟧" as |c|>
            <c.Input aria-label="⟦two⟧" />
            <c.Content><c.List as |item|><c.Item
                  @value={{item}}
                >{{item}}</c.Item></c.List></c.Content>
          </Combobox>
          <Combobox @items={{ITEMS}} @multiple={{true}} @defaultValue={{array "⟦a⟧"}} as |c|>
            <c.Chips>
              <c.Value as |values|>
                {{#each values as |value|}}<c.Chip @value={{value}}>{{value}}</c.Chip>{{/each}}
                <c.ChipsInput aria-label="⟦three⟧" />
              </c.Value>
            </c.Chips>
            <c.Content @anchor={{c.chipsElement}}>
              <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
            </c.Content>
          </Combobox>
          <MessageScrollerProvider as |s|>
            <s.Root>
              <s.Viewport><s.Content /></s.Viewport>
              <s.Button />
              <s.Button @direction="start" />
            </s.Root>
          </MessageScrollerProvider>
          <Spinner />
          <Calendar
            @mode="single"
            @today={{today}}
            @value={{today}}
            @captionLayout="dropdown"
            @showWeekNumber={{true}}
          />
          <SidebarProvider as |sidebar|>
            <sidebar.Sidebar><sidebar.Rail /></sidebar.Sidebar>
            <sidebar.Inset><sidebar.Trigger /></sidebar.Inset>
          </SidebarProvider>
          <DocumentFileDrop @onFiles={{noop}} />
        </template>,
      )
      await new DocumentFileDropHarness().drag([photo])
      assert.deepEqual(unlocalized(undefined, DATES), [])
      await a11yAudit()
    })

    test('the dialogs, the sheet and the questionnaire', async function (assert) {
      await render(
        <template>
          <Dialog @open={{true}} as |d|>
            <d.Content>
              <d.Title>⟦title⟧</d.Title>
              <d.Description>⟦description⟧</d.Description>
              <d.Footer @showCloseButton={{true}} />
            </d.Content>
          </Dialog>
          <Questionnaire @items={{QUESTIONS}} as |q|>
            <q.Progress />
            <q.Item @name="q1" @required={{true}} as |i|>
              <i.Title>⟦1⟧</i.Title>
              <i.Choices>
                <i.Choice @value="a">⟦a⟧</i.Choice>
              </i.Choices>
              <i.Error />
            </q.Item>
            <q.Item @name="q2" as |i|><i.Title>⟦2⟧</i.Title></q.Item>
            <q.Previous />
            <q.Skip />
            <q.Next />
            <q.Submit />
          </Questionnaire>
        </template>,
      )
      await click('[data-test-jn-part="next"]')
      assert.true(
        shown(messages.dialogClose),
        'a dialog, and the questionnaire with its error shown',
      )
      assert.deepEqual(unlocalized(), [], 'a dialog, and the questionnaire with its error shown')

      await render(
        <template>
          <Sheet @open={{true}} as |s|>
            <s.Content><s.Title>⟦title⟧</s.Title><s.Description>⟦d⟧</s.Description></s.Content>
          </Sheet>
        </template>,
      )
      assert.true(shown(messages.sheetClose), 'a sheet')
      assert.deepEqual(unlocalized(), [], 'a sheet')

      await render(<template><CommandDialog @open={{true}} /></template>)
      assert.true(shown(primitiveMessages.commandDialogTitle), 'the command dialog')
      assert.deepEqual(unlocalized(), [], 'the command dialog')

      await render(
        <template>
          <SidebarProvider @mobileBreakpoint={{100000}} as |sidebar|>
            <sidebar.Sidebar />
            <sidebar.Trigger />
          </SidebarProvider>
        </template>,
      )
      await click('[data-sidebar="trigger"]')
      assert.true(shown(messages.sidebarMobileTitle), 'the mobile sidebar')
      assert.deepEqual(unlocalized(), [], 'the mobile sidebar')
      await a11yAudit()
    })

    test('the components on primitives show theirs translated', async function (assert) {
      await render(
        <template>
          <NavigationMenu />
          <Rating />
          <Slider @defaultValue={{array 25 75}} />
          <Toaster @closeButton={{true}} />
        </template>,
      )
      toast('⟦saved⟧')
      await settled()
      assert.deepEqual(unlocalized(), [])
      await a11yAudit()
    })

    test('an explicit argument beats the translator', async function (assert) {
      await render(
        <template>
          <Spinner @label="Saving" />
          <Pagination @label="Pages" />
        </template>,
      )
      assert.dom('[data-slot="spinner"]').hasAttribute('aria-label', 'Saving')
      assert.dom('nav').hasAttribute('aria-label', 'Pages')
      await a11yAudit()
    })
  })

  module('with a translator in German', function (hooks) {
    setupTranslator(hooks, { locale: 'de', t: pseudoTranslator.t })

    test('the calendar takes its locale, unless @locale is given', async function (assert) {
      await render(<template><Calendar @today={{today}} /></template>)
      assert.dom('[role="grid"]').hasAttribute('aria-label', 'März 2026')
      await a11yAudit()
      await render(<template><Calendar @today={{today}} @locale="fr" /></template>)
      assert.dom('[role="grid"]').hasAttribute('aria-label', 'mars 2026')
    })
  })

  test('with no translator, English', async function (assert) {
    await render(<template><Spinner /></template>)
    assert.dom('[data-slot="spinner"]').hasAttribute('aria-label', 'Loading')
    await a11yAudit()
  })
})
