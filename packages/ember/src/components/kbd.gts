import type { TOC } from '@ember/component/template-only'
import { As, type TagName } from '@ember-joinery/primitives/as'

export interface KbdSignature {
  Args: {
    /** The tag to render instead of `kbd`. */
    as?: TagName
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The key: `Ctrl`, `⌘`, `Enter`, or an icon. */
    default: []
  }
  Element: HTMLElement
}

/**
 * Displays textual user input from the keyboard: shadcn's Kbd, a styled `<kbd>`. It is the
 * styled counterpart of the primitives' `Key`; for a whole shortcut built from a string
 * (`"ctrl+k"`), with the Mac's keys on a Mac, see the primitives' `KeyCombo`.
 *
 *   <Kbd>Ctrl</Kbd>
 *   <Button @variant="outline">Accept <Kbd data-icon="inline-end">⏎</Kbd></Button>
 */
const Kbd: TOC<KbdSignature> = <template>
  <As
    @as={{@as}}
    @tag="kbd"
    class="jn-kbd"
    data-slot="kbd"
    data-test-jn="kbd"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</As>
</template>

export default Kbd

export interface KbdGroupSignature {
  Args: {
    /** The tag to render instead of `kbd`. */
    as?: TagName
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The keys, each a `<Kbd>`, and anything between them (`<span>+</span>`). */
    default: []
  }
  Element: HTMLElement
}

/**
 * Keys shown together, as one shortcut: shadcn's KbdGroup, a `<kbd>` around `<Kbd>`s (in HTML,
 * a `<kbd>` inside a `<kbd>` is one input made of several keys).
 *
 *   <KbdGroup>
 *     <Kbd>Ctrl</Kbd>
 *     <span>+</span>
 *     <Kbd>B</Kbd>
 *   </KbdGroup>
 */
export const KbdGroup: TOC<KbdGroupSignature> = <template>
  <As
    @as={{@as}}
    @tag="kbd"
    class="jn-kbd-group"
    data-slot="kbd-group"
    data-test-jn="kbd-group"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</As>
</template>
