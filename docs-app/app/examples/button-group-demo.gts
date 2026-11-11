import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import {
  Archive,
  ArrowLeft,
  CalendarPlus,
  Clock,
  ListFilter,
  MailCheck,
  MoreHorizontal,
  Tag,
  Trash2,
} from 'lucide'
import { Button, ButtonGroup, DropdownMenu, Icon } from '@ember-joinery/ember'

export default class ButtonGroupDemo extends Component {
  @tracked label = 'personal'

  setLabel = (label: string) => (this.label = label)

  <template>
    <ButtonGroup>
      <ButtonGroup class="hidden sm:flex">
        <Button @variant="outline" @size="icon" aria-label="Go Back">
          <Icon @icon={{ArrowLeft}} />
        </Button>
      </ButtonGroup>
      <ButtonGroup>
        <Button @variant="outline">Archive</Button>
        <Button @variant="outline">Report</Button>
      </ButtonGroup>
      <ButtonGroup>
        <Button @variant="outline">Snooze</Button>
        <DropdownMenu as |m|>
          <Button @variant="outline" @size="icon" aria-label="More Options" {{m.trigger}}>
            <Icon @icon={{MoreHorizontal}} />
          </Button>
          <m.Content @align="end" class="w-40">
            <m.Group>
              <m.Item>
                <Icon @icon={{MailCheck}} />
                Mark as Read
              </m.Item>
              <m.Item>
                <Icon @icon={{Archive}} />
                Archive
              </m.Item>
            </m.Group>
            <m.Separator />
            <m.Group>
              <m.Item>
                <Icon @icon={{Clock}} />
                Snooze
              </m.Item>
              <m.Item>
                <Icon @icon={{CalendarPlus}} />
                Add to Calendar
              </m.Item>
              <m.Item>
                <Icon @icon={{ListFilter}} />
                Add to List
              </m.Item>
              <m.Sub as |s|>
                <s.Trigger>
                  <Icon @icon={{Tag}} />
                  Label As...
                </s.Trigger>
                <s.Content>
                  <m.RadioGroup @value={{this.label}} @onValueChange={{this.setLabel}} as |g|>
                    <g.Item @value="personal">Personal</g.Item>
                    <g.Item @value="work">Work</g.Item>
                    <g.Item @value="other">Other</g.Item>
                  </m.RadioGroup>
                </s.Content>
              </m.Sub>
            </m.Group>
            <m.Separator />
            <m.Group>
              <m.Item @variant="destructive">
                <Icon @icon={{Trash2}} />
                Trash
              </m.Item>
            </m.Group>
          </m.Content>
        </DropdownMenu>
      </ButtonGroup>
    </ButtonGroup>
  </template>
}
