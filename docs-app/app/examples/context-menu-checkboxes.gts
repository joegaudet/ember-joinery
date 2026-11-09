import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ContextMenu } from '@ember-joinery/ember'

// Upstream passes `defaultChecked`, which Radix's CheckboxItem doesn't take (its state is the
// caller's), so on ui.shadcn.com the items start unchecked and don't toggle. This keeps the state
// the example means, as the dropdown menu's checkbox examples do.
export default class ContextMenuCheckboxes extends Component {
  @tracked showBookmarksBar = true
  @tracked showFullUrls = false
  @tracked showDeveloperTools = true

  setShowBookmarksBar = (checked: boolean) => (this.showBookmarksBar = checked)
  setShowFullUrls = (checked: boolean) => (this.showFullUrls = checked)
  setShowDeveloperTools = (checked: boolean) => (this.showDeveloperTools = checked)

  <template>
    <ContextMenu as |c|>
      <c.Trigger
        class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm"
      >
        <span class="hidden pointer-fine:inline-block">
          Right click here
        </span>
        <span class="hidden pointer-coarse:inline-block">
          Long press here
        </span>
      </c.Trigger>
      <c.Content>
        <c.Group>
          <c.CheckboxItem
            @checked={{this.showBookmarksBar}}
            @onCheckedChange={{this.setShowBookmarksBar}}
          >
            Show Bookmarks Bar
          </c.CheckboxItem>
          <c.CheckboxItem @checked={{this.showFullUrls}} @onCheckedChange={{this.setShowFullUrls}}>
            Show Full URLs
          </c.CheckboxItem>
          <c.CheckboxItem
            @checked={{this.showDeveloperTools}}
            @onCheckedChange={{this.setShowDeveloperTools}}
          >
            Show Developer Tools
          </c.CheckboxItem>
        </c.Group>
      </c.Content>
    </ContextMenu>
  </template>
}
