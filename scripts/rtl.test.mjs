import { test } from 'node:test'
import assert from 'node:assert/strict'
import { logicalClasses, splitClass } from './rtl.mjs'

test('splitClass splits variants, utility and modifier at the top level', () => {
  assert.deepEqual(splitClass('pl-2'), [null, 'pl-2', null])
  assert.deepEqual(splitClass('hover:bg-primary/80'), ['hover', 'bg-primary', '80'])
  assert.deepEqual(splitClass("[&_svg:not([class*='size-'])]:size-4"), [
    "[&_svg:not([class*='size-'])]",
    'size-4',
    null,
  ])
  assert.deepEqual(splitClass('has-data-[icon=inline-end]:pr-2'), [
    'has-data-[icon=inline-end]',
    'pr-2',
    null,
  ])
})

test('logicalClasses makes physical sides logical, keeping variants and modifiers', () => {
  assert.equal(
    logicalClasses('pl-2 has-data-[icon=inline-end]:pr-1.5 -ml-1 mr-auto text-left'),
    'ps-2 has-data-[icon=inline-end]:pe-1.5 -ms-1 me-auto text-start',
  )
  assert.equal(
    logicalClasses(
      'rounded-l-md rounded-tr-lg border-l border-r-2 left-2 -right-1 hover:left-0/50',
    ),
    'rounded-s-md rounded-se-lg border-s border-e-2 start-2 -end-1 hover:start-0/50',
  )
  assert.equal(logicalClasses('float-left origin-top-right'), 'float-start origin-top-end')
})

test('logicalClasses leaves look-alikes and whole-word prefixes alone', () => {
  // `border-l` and `text-left` are whole utilities, not prefixes.
  assert.equal(
    logicalClasses('border-ring rounded-lg placeholder:text-muted text-left-x'),
    'border-ring rounded-lg placeholder:text-muted text-left-x',
  )
  assert.equal(logicalClasses('px-2 ps-1 rtl:pl-2 ltr:pr-2'), 'px-2 ps-1 rtl:pl-2 ltr:pr-2')
})

test('logicalClasses adds an rtl: twin where there is no logical form', () => {
  assert.equal(
    logicalClasses('translate-x-1/2 -translate-x-px'),
    'translate-x-1/2 rtl:-translate-x-1/2 -translate-x-px rtl:translate-x-px',
  )
  assert.equal(
    logicalClasses('data-open:translate-x-0 space-x-2 cursor-w-resize'),
    'data-open:translate-x-0 rtl:data-open:-translate-x-0 space-x-2 rtl:space-x-reverse cursor-w-resize rtl:cursor-e-resize',
  )
  assert.equal(logicalClasses('jn-rtl-flip size-4'), 'rtl:rotate-180 size-4')
})

test('logicalClasses keeps physical positions on a physical side', () => {
  assert.equal(
    logicalClasses('data-[side=left]:left-0 data-[side=right]:pl-2'),
    'data-[side=left]:left-0 data-[side=right]:ps-2',
  )
  assert.equal(
    logicalClasses(
      'data-[side=inline-start]:slide-in-from-right-2 data-[side=inline-end]:slide-out-to-left-2',
    ),
    'data-[side=inline-start]:slide-in-from-end-2 data-[side=inline-end]:slide-out-to-start-2',
  )
})
