import Route from '@ember/routing/route'
import { loadExample, type LoadedExample } from '../examples/index.ts'

export interface ParityModel {
  name: string
  /** Undefined when docs-app/app/examples has no example by that name. */
  example: LoadedExample | undefined
}

/**
 * `/parity/<example>` renders one example with nothing around it, for the screenshot comparison
 * with shadcn/ui's own (`pnpm parity`; see "Parity" in CONTRIBUTING.md). Query parameters set
 * up the page the way the comparison asks for:
 *
 * - `theme=dark` puts the `.dark` class on `<html>`, and `theme=light` (the default) the
 *   `.light` one; either also sets `color-scheme`, so the browser's preference can't change it;
 * - `dir=rtl` lays the example out right to left;
 * - `align=start|end` places it as upstream's preview does (centred otherwise);
 * - `fullWidth=true` stretches it across the stage, as `<Example @fullWidth={{true}}>` does;
 * - `style=<style>` and `base=<base colour>` show it in another style or base colour (Nova and
 *   Neutral by default), as the parity app's `base` does.
 */
export default class ParityRoute extends Route {
  queryParams = {
    theme: { refreshModel: false },
    dir: { refreshModel: false },
    align: { refreshModel: false },
    fullWidth: { refreshModel: false },
    style: { refreshModel: false },
    base: { refreshModel: false },
  }

  async model({ name }: { name: string }): Promise<ParityModel> {
    return { name, example: await loadExample(name) }
  }
}
