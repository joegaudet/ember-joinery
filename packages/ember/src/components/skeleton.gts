import type { TOC } from '@ember/component/template-only'
import { As, type TagName } from '@ember-joinery/primitives/as'

export interface SkeletonSignature {
  Args: {
    /** The tag to render instead of `div`, such as `span` inside a line of text. */
    as?: TagName
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    default: []
  }
  Element: HTMLElement
}

/**
 * A placeholder to show while content loads: shadcn's Skeleton, a pulsing, rounded block in
 * the theme's `--muted`. It has no size of its own: give it one with classes (`h-4 w-[250px]`)
 * or CSS of yours, which wins over Joinery's.
 *
 *   <Skeleton class="h-4 w-[250px]" />
 *   <Skeleton class="size-10 rounded-full" />
 */
const Skeleton: TOC<SkeletonSignature> = <template>
  <As
    @as={{@as}}
    @tag="div"
    class="jn-skeleton"
    data-slot="skeleton"
    data-test-jn="skeleton"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</As>
</template>

export default Skeleton
