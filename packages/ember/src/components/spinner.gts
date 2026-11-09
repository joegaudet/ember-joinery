import type { TOC } from '@ember/component/template-only'
import { LoaderCircle } from 'lucide'
import Icon, { type IconNode } from './icon.gts'

export interface SpinnerSignature {
  Args: {
    /**
     * The icon it turns: one from `lucide` (`import { Loader } from 'lucide'`), or any icon in
     * that format. Default lucide's `loader-circle`, upstream's `Loader2Icon`.
     */
    icon?: IconNode
    /** What the spinner announces. Default `Loading`. */
    label?: string
    /** The component's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Element: SVGSVGElement
}

/**
 * A loading indicator: lucide's `loader-circle`, turning, with the `status` role and a label,
 * as shadcn's Spinner. Inside a Button, mark its side as you would an icon's
 * (`data-icon="inline-start"`). Size it with a class (`size-6`) or CSS of your own, and turn
 * another icon with `@icon`.
 *
 *   <Button disabled><Spinner data-icon="inline-start" /> Saving</Button>
 *   <Spinner @icon={{Loader}} @label="Saving" />
 *
 * `jn-size-4` styles nothing (`jn-spinner` sizes it): it stands for upstream's `size-4`, which
 * the style sheets' `svg:not([class*='size-'])` rules look for, so a small Button's icon size
 * leaves the spinner at its own, as upstream's.
 */
const Spinner: TOC<SpinnerSignature> = <template>
  <Icon
    @icon={{if @icon @icon LoaderCircle}}
    @label={{if @label @label "Loading"}}
    class="jn-spinner jn-size-4"
    data-slot="spinner"
    role="status"
    data-test-jn="spinner"
    data-test-jn-name={{@name}}
    ...attributes
  />
</template>

export default Spinner
