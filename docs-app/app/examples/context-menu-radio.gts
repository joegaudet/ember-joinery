import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ContextMenu } from '@ember-joinery/ember'

export default class ContextMenuRadio extends Component {
  @tracked user = 'pedro'
  @tracked theme = 'light'

  setUser = (user: string) => (this.user = user)
  setTheme = (theme: string) => (this.theme = theme)

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
          <c.Label>People</c.Label>
          <c.RadioGroup @value={{this.user}} @onValueChange={{this.setUser}} as |g|>
            <g.Item @value="pedro">
              Pedro Duarte
            </g.Item>
            <g.Item @value="colm">Colm Tuite</g.Item>
          </c.RadioGroup>
        </c.Group>
        <c.Separator />
        <c.Group>
          <c.Label>Theme</c.Label>
          <c.RadioGroup @value={{this.theme}} @onValueChange={{this.setTheme}} as |g|>
            <g.Item @value="light">Light</g.Item>
            <g.Item @value="dark">Dark</g.Item>
            <g.Item @value="system">System</g.Item>
          </c.RadioGroup>
        </c.Group>
      </c.Content>
    </ContextMenu>
  </template>
}
