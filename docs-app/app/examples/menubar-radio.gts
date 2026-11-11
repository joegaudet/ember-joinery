import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Menubar } from '@ember-joinery/ember'

export default class MenubarRadio extends Component {
  @tracked user = 'benoit'
  @tracked theme = 'system'

  setUser = (user: string) => (this.user = user)
  setTheme = (theme: string) => (this.theme = theme)

  <template>
    <Menubar class="w-72" as |bar|>
      <bar.Menu as |m|>
        <m.Trigger>Profiles</m.Trigger>
        <m.Content>
          <m.RadioGroup @value={{this.user}} @onValueChange={{this.setUser}} as |g|>
            <g.Item @value="andy">Andy</g.Item>
            <g.Item @value="benoit">Benoit</g.Item>
            <g.Item @value="luis">Luis</g.Item>
          </m.RadioGroup>
          <m.Separator />
          <m.Item @inset={{true}}>Edit...</m.Item>
          <m.Item @inset={{true}}>Add Profile...</m.Item>
        </m.Content>
      </bar.Menu>
      <bar.Menu as |m|>
        <m.Trigger>Theme</m.Trigger>
        <m.Content>
          <m.RadioGroup @value={{this.theme}} @onValueChange={{this.setTheme}} as |g|>
            <g.Item @value="light">Light</g.Item>
            <g.Item @value="dark">Dark</g.Item>
            <g.Item @value="system">System</g.Item>
          </m.RadioGroup>
        </m.Content>
      </bar.Menu>
    </Menubar>
  </template>
}
