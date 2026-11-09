import type { TOC } from '@ember/component/template-only'

/** A component the load tests import on demand, as an app splits off a heavy one. */
const LazyGreeting: TOC<{ Args: { name?: string } }> = <template>
  <p data-test-lazy-greeting>Hello, {{if @name @name "stranger"}}</p>
</template>

export default LazyGreeting
