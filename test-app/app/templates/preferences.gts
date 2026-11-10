import type { TOC } from '@ember/component/template-only'
import SettingsDialog from '../components/demo/settings/settings-dialog.gts'
import type PreferencesController from '../controllers/preferences.ts'

// The settings block, open over the dashboard the application template draws.
const Preferences: TOC<{ Args: { controller: PreferencesController } }> = <template>
  <SettingsDialog @section={{@controller.section}} />
</template>

export default Preferences
