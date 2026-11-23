import { after, invoke, Machine, State, transition, type Clock } from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'

/** How long the button shows that it copied, in milliseconds, as upstream's. */
const COPIED_FOR = 2000

export class CopyState extends State {
  declare private readonly brand: never
  /** Nothing copied lately. */
  static Idle = CopyState.of('idle')
  /** Waiting for the clipboard to take the text. */
  static Copying = CopyState.of('copying')
  /** Copied: it says so for `COPIED_FOR`. */
  static Copied = CopyState.of('copied')
}

/**
 * The copy button's chart: `copy(text)` writes to the clipboard, then it shows that it copied
 * for two seconds. A clipboard that refuses (or a page without one) leaves it idle.
 */
export class CopyMachine extends Machine<CopyState> {
  // Not the Ember clock, whose timers `settled()` waits for: a test checks the copied state
  // right after the click, and the copied state is no work for a test to wait out.
  static override clock: Clock = {
    setTimeout: (fn, ms) => setTimeout(fn, ms),
    clearTimeout: handle => clearTimeout(handle as ReturnType<typeof setTimeout>),
  }

  /** What the clipboard is to take. */
  text = ''

  get isCopied(): boolean {
    return this.matches(CopyState.Copied)
  }

  @transition({ from: [CopyState.Idle, CopyState.Copied], to: CopyState.Copying })
  copy(text: string) {
    this.text = text
  }

  // Tests wait for the write (`@invoke` promises are test waiters).
  @invoke(CopyState.Copying, { onDone: CopyState.Copied, onError: CopyState.Idle })
  async write(): Promise<void> {
    await navigator.clipboard.writeText(this.text)
  }

  @after(COPIED_FOR, { from: CopyState.Copied, to: CopyState.Idle })
  reset() {}
}

/** A started `CopyMachine`, stopped (its timer with it) when `owner` is destroyed. */
export function copyMachine(owner: object): CopyMachine {
  return machine(owner, new CopyMachine())
}
