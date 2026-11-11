import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Download, Terminal, WrapText } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'
import { CodeBlock } from '@ember-joinery/code-block'

const output = `$ pnpm lint
apps/web/components/message-list.tsx
  18:22  error  'messages' is possibly 'undefined'. Add a guard before calling map  @typescript-eslint/no-unsafe-call
  42:7   warning  React Hook React.useEffect has a missing dependency: 'scrollToBottom'  react-hooks/exhaustive-deps

✖ 2 problems (1 error, 1 warning)`

function download(value: string, filename: string) {
  const url = URL.createObjectURL(new Blob([value], { type: 'text/plain' }))
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}

export default class CodeBlockActionsExample extends Component {
  @tracked wrap = true

  toggleWrap = () => (this.wrap = !this.wrap)
  download = () => download(output, 'lint.log')

  <template>
    <div class="w-full max-w-md">
      <CodeBlock as |b|>
        <b.Header>
          <b.Title><Icon @icon={{Terminal}} />Terminal</b.Title>
          <b.Actions>
            <Button
              @variant="ghost"
              @size="icon-xs"
              aria-label="Wrap lines"
              aria-pressed={{if this.wrap "true" "false"}}
              class="aria-pressed:text-foreground"
              {{on "click" this.toggleWrap}}
            >
              <Icon @icon={{WrapText}} />
            </Button>
            <Button
              @variant="ghost"
              @size="icon-xs"
              aria-label="Download"
              {{on "click" this.download}}
            >
              <Icon @icon={{Download}} />
            </Button>
            <b.CopyButton @value={{output}} />
          </b.Actions>
        </b.Header>
        <b.Content @code={{output}} @wrap={{this.wrap}} />
      </CodeBlock>
    </div>
  </template>
}
