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
 * - `align=start|end` places it as upstream's preview does (centred otherwise).
 */
export default class ParityRoute extends Route {
  queryParams = {
    theme: { refreshModel: false },
    dir: { refreshModel: false },
    align: { refreshModel: false },
  }

  async model({ name }: { name: string }): Promise<ParityModel> {
    return { name, example: await loadExample(name) }
  }
}
