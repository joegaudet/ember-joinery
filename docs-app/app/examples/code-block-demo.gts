import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Download, FileCode, WrapText } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

// Upstream's route names a real model in `model:`; Joinery's examples use a
// placeholder of the same length, so the code lays out the same.
const code = `import { streamText } from "ai"

export async function POST(request: Request) {
  const { messages } = await request.json()

  const result = streamText({
    model: "your-provider/your-model-id",
    system: "You are a helpful assistant. Answer in one short paragraph.",
    messages,
  })

  return result.toUIMessageStreamResponse()
}`

function download(value: string, filename: string) {
  const url = URL.createObjectURL(new Blob([value], { type: 'text/plain' }))
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}

const variantFor = (index: number) => (index >= 5 && index <= 9 ? 'highlighted' : 'default')

export default class CodeBlockDemo extends Component {
  @tracked wrap = false

  toggleWrap = () => (this.wrap = !this.wrap)
  download = () => download(code, 'route.ts')

  <template>
    <div class="w-full max-w-lg">
      <CodeBlock as |b|>
        <b.Header>
          <b.Title><Icon @icon={{FileCode}} />app/api/chat/route.ts</b.Title>
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
            <b.CopyButton @value={{code}} />
          </b.Actions>
        </b.Header>
        <b.Content @wrap={{this.wrap}} @lineNumbers={{true}}>
          {{#each (highlightedCode code "ts") as |line index|}}
            <b.Line @code={{line}} @variant={{variantFor index}} />
          {{/each}}
        </b.Content>
      </CodeBlock>
    </div>
  </template>
}
