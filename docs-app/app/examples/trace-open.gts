import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Terminal } from 'lucide'
import { Button, Icon, TraceCollapsible, TraceLine } from '@ember-joinery/ember'
import { CodeBlock } from '@ember-joinery/code-block'

const node = `$ node --version
v24.18.0`

const pnpm = `$ pnpm --version
10.33.4`

export default class TraceOpen extends Component {
  @tracked open = false

  setOpen = (open: boolean) => (this.open = open)

  toggle = () => (this.open = !this.open)

  <template>
    <div class="flex w-full max-w-sm flex-col items-start gap-4">
      <TraceCollapsible @defaultOpen={{true}} as |c|>
        <c.Trigger>
          <TraceLine as |l|>
            <l.Icon>
              <Icon @icon={{Terminal}} />
            </l.Icon>
            <l.Title>Ran node --version</l.Title>
          </TraceLine>
        </c.Trigger>
        <c.Content>
          <CodeBlock @size="sm" as |b|>
            <b.Content @code={{node}} @wrap={{true}} class="max-h-64" />
          </CodeBlock>
        </c.Content>
      </TraceCollapsible>
      <TraceCollapsible @open={{this.open}} @onOpenChange={{this.setOpen}} as |c|>
        <c.Trigger>
          <TraceLine as |l|>
            <l.Icon>
              <Icon @icon={{Terminal}} />
            </l.Icon>
            <l.Title>Ran pnpm --version</l.Title>
          </TraceLine>
        </c.Trigger>
        <c.Content>
          <CodeBlock @size="sm" as |b|>
            <b.Content @code={{pnpm}} @wrap={{true}} class="max-h-64" />
          </CodeBlock>
        </c.Content>
      </TraceCollapsible>
      <Button @variant="outline" @size="sm" {{on "click" this.toggle}}>
        {{if this.open "Hide" "Show"}}
        the pnpm output
      </Button>
    </div>
  </template>
}
