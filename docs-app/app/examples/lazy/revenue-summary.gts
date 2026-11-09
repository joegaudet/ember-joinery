import type { TOC } from '@ember/component/template-only'

/**
 * What `load-on-demand` imports when it renders: in an app, a component heavy enough (a chart,
 * an editor) to keep out of the main bundle.
 */
const RevenueSummary: TOC<{ Args: { year: number } }> = <template>
  <figure data-test-jn="revenue">
    <figcaption>Revenue in {{@year}}</figcaption>
    <p data-test-jn-part="total">$1.2M, up 14%</p>
  </figure>
</template>

export default RevenueSummary
