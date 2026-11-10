import { focus, settled, triggerKeyEvent } from '@ember/test-helpers'

type TextControl = HTMLInputElement | HTMLTextAreaElement

/**
 * One edit as a browser makes it: a cancelable `beforeinput` (which Maskito answers), then, if
 * nothing cancelled it, the edit itself and an `input`.
 */
function edit(
  element: TextControl,
  inputType: string,
  data: string | null,
  apply: (from: number, to: number) => void,
  dataTransfer: DataTransfer | null = null,
): void {
  const before = new InputEvent('beforeinput', {
    inputType,
    data,
    dataTransfer,
    bubbles: true,
    cancelable: true,
    composed: true,
  })
  if (!element.dispatchEvent(before)) return
  const from = element.selectionStart ?? element.value.length
  const to = element.selectionEnd ?? from
  apply(from, to)
  element.dispatchEvent(
    new InputEvent('input', { inputType, data, dataTransfer, bubbles: true, composed: true }),
  )
}

/** Puts the caret at the end, as a click after the text would. */
function caretToEnd(element: TextControl): void {
  const end = element.value.length
  element.setSelectionRange(end, end)
}

/** Types `text` one character at a time at the caret (the end), as a keyboard does. */
export async function typeText(element: TextControl, text: string): Promise<void> {
  await focus(element)
  caretToEnd(element)
  for (const char of text) {
    edit(element, 'insertText', char, (from, to) => element.setRangeText(char, from, to, 'end'))
  }
  await settled()
}

/** Presses Backspace `times` times with the caret at the end. */
export async function backspace(element: TextControl, times = 1): Promise<void> {
  await focus(element)
  caretToEnd(element)
  for (let i = 0; i < times; i++) {
    edit(element, 'deleteContentBackward', null, (from, to) => {
      if (from === to && from > 0) element.setRangeText('', from - 1, to, 'end')
      else element.setRangeText('', from, to, 'end')
    })
  }
  await settled()
}

/**
 * Presses Delete `times` times, starting with the caret at `at` (a character's index), as a
 * keyboard does: the caret stays where it is and the text after it moves up.
 */
export async function deleteForward(element: TextControl, at: number, times = 1): Promise<void> {
  await focus(element)
  element.setSelectionRange(at, at)
  for (let i = 0; i < times; i++) {
    edit(element, 'deleteContentForward', null, (from, to) => {
      if (from === to) element.setRangeText('', from, Math.min(from + 1, element.value.length))
      else element.setRangeText('', from, to, 'start')
    })
  }
  await settled()
}

/** Z's key code, which Maskito's undo and redo shortcuts read (`keyCode`, as layouts differ). */
const Z = 90

/** Presses Ctrl+Z, which undoes the last edit. */
export async function undo(element: TextControl): Promise<void> {
  await focus(element)
  await triggerKeyEvent(element, 'keydown', Z, { ctrlKey: true })
}

/** Presses Ctrl+Shift+Z, which redoes the edit undone last. */
export async function redo(element: TextControl): Promise<void> {
  await focus(element)
  await triggerKeyEvent(element, 'keydown', Z, { ctrlKey: true, shiftKey: true })
}

/**
 * Drops `text` at the end, as a drag and drop of text does: a cancelable `beforeinput`
 * (`insertFromDrop`, with the text as its `data` and on its `dataTransfer`), then, if nothing
 * cancelled it, the insertion and an `input`.
 */
export async function dropText(element: TextControl, text: string): Promise<void> {
  await focus(element)
  caretToEnd(element)
  const dataTransfer = new DataTransfer()
  dataTransfer.setData('text/plain', text)
  edit(
    element,
    'insertFromDrop',
    text,
    (from, to) => element.setRangeText(text, from, to, 'end'),
    dataTransfer,
  )
  await settled()
}

/**
 * Pastes `text` over what the element holds, as a user who selects it all and pastes does: a
 * `paste` event with the text on its clipboard (which a component may take over), then, if
 * nothing cancelled it, the insertion.
 */
export async function pasteText(element: TextControl, text: string): Promise<void> {
  await focus(element)
  element.setSelectionRange(0, element.value.length)
  const clipboardData = new DataTransfer()
  clipboardData.setData('text/plain', text)
  const paste = new ClipboardEvent('paste', {
    clipboardData,
    bubbles: true,
    cancelable: true,
    composed: true,
  })
  if (element.dispatchEvent(paste)) {
    edit(element, 'insertFromPaste', text, (from, to) =>
      element.setRangeText(text, from, to, 'end'),
    )
  }
  await settled()
}
