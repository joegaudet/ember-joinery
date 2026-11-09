import type { TOC } from '@ember/component/template-only'
import { LoaderCircle } from 'lucide'
import Icon from './icon.gts'

export interface SpinnerSignature {
  Args: {
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
 * (`data-icon="inline-start"`).
 *
 *   <Button disabled><Spinner data-icon="inline-start" /> Saving</Button>
 */
const Spinner: TOC<SpinnerSignature> = <template>
  <Icon
    @icon={{LoaderCircle}}
    @label={{if @label @label "Loading"}}
    class="jn-spinner"
    data-slot="spinner"
    role="status"
    data-test-jn="spinner"
    data-test-jn-name={{@name}}
    ...attributes
  />
</template>

export default Spinner
