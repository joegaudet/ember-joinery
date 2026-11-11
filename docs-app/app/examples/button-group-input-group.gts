import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { AudioLines, Plus } from 'lucide'
import { Button, ButtonGroup, Icon, InputGroup, Tooltip } from '@ember-joinery/ember'

export default class ButtonGroupInputGroup extends Component {
  @tracked voiceEnabled = false

  toggleVoice = () => (this.voiceEnabled = !this.voiceEnabled)

  <template>
    {{!
      Upstream's icon buttons and input have no names, but for the input's placeholder; these are
      named (aria-label), so the audit passes.
    }}
    <ButtonGroup class="[--radius:9999rem]">
      <ButtonGroup>
        <Button @variant="outline" @size="icon" aria-label="Add">
          <Icon @icon={{Plus}} />
        </Button>
      </ButtonGroup>
      <ButtonGroup>
        <InputGroup as |g|>
          <g.Input
            placeholder={{if this.voiceEnabled "Record and send audio..." "Send a message..."}}
            disabled={{this.voiceEnabled}}
            aria-label="Message"
          />
          <g.Addon @align="inline-end">
            <Tooltip as |t|>
              <g.Button
                @size="icon-xs"
                data-active={{if this.voiceEnabled "true" "false"}}
                class="data-[active=true]:bg-orange-100 data-[active=true]:text-orange-700 dark:data-[active=true]:bg-orange-800 dark:data-[active=true]:text-orange-100"
                aria-pressed={{if this.voiceEnabled "true" "false"}}
                aria-label="Voice Mode"
                {{on "click" this.toggleVoice}}
                {{t.trigger}}
              >
                <Icon @icon={{AudioLines}} />
              </g.Button>
              <t.Content>Voice Mode</t.Content>
            </Tooltip>
          </g.Addon>
        </InputGroup>
      </ButtonGroup>
    </ButtonGroup>
  </template>
}
