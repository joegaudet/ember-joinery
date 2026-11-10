import type { TOC } from '@ember/component/template-only'
import { Separator, type SidebarBlockParams } from '@ember-joinery/ember'

// Upstream's SidebarTrigger finds its provider through React's context; here it is the one the
// page's SidebarProvider yields.
const SiteHeader: TOC<{ Args: { sidebar: SidebarBlockParams } }> = <template>
  <header
    class="flex h-(--header-height) shrink-0 items-center gap-2 border-b transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-(--header-height)"
  >
    <div class="flex w-full items-center gap-1 px-4 lg:gap-2 lg:px-6">
      <@sidebar.Trigger class="-ml-1" />
      <Separator @orientation="vertical" class="mx-2 data-[orientation=vertical]:h-4" />
      <h1 class="text-base font-medium">Documents</h1>
    </div>
  </header>
</template>

export default SiteHeader
