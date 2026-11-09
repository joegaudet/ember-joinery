import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { registerDestructor } from '@ember/destroyable'
import { RotateCcw } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

interface Block {
  title?: string
  language: string
  code: string
  lineNumbers?: boolean
  highlight?: number[]
  diff?: boolean
}

// Upstream's route names a real model in `model:`; Joinery's examples use a placeholder.
const blocks: Block[] = [
  {
    title: 'hooks/use-debounce.ts',
    language: 'ts',
    lineNumbers: true,
    code: `export function useDebounce<T>(value: T, delay = 300) {
  const [debounced, setDebounced] = React.useState(value)

  React.useEffect(() => {
    const timeout = setTimeout(() => setDebounced(value), delay)
    return () => clearTimeout(timeout)
  }, [value, delay])

  return debounced
}`,
  },
  {
    language: 'bash',
    code: 'pnpm dlx shadcn@latest add code-block',
  },
  {
    title: 'components/search.tsx',
    language: 'tsx',
    lineNumbers: true,
    diff: true,
    code: ` export function Search() {
   const [query, setQuery] = React.useState("")
-  const results = useSearch(query)
+  const debounced = useDebounce(query, 300)
+  const results = useSearch(debounced)

   return <SearchResults results={results} />
 }`,
  },
  {
    title: 'app/api/chat/route.ts',
    language: 'ts',
    lineNumbers: true,
    highlight: [5, 6, 7, 8],
    code: `import { streamText } from "ai"

export async function POST(request: Request) {
  const { messages } = await request.json()

  const result = streamText({
    model: "provider/model",
    messages,
  })

  return result.toUIMessageStreamResponse()
}`,
  },
  {
    title: '.env.local',
    language: 'bash',
    code: 'AI_GATEWAY_API_KEY=your-api-key',
  },
]

// Where each block starts in the stream.
const offsets = blocks.map((_, index) =>
  blocks.slice(0, index).reduce((total, block) => total + block.code.length, 0),
)
const total = blocks.reduce((sum, block) => sum + block.code.length, 0)

/** A block as much of it has streamed: its rows, and the code without a diff's markers. */
function streamed(block: Block, code: string) {
  const rows = code.split('\n')
  // A diff row starts with +, - or a space. The marker is not part of the code.
  const source = block.diff ? rows.map(row => row.slice(1)).join('\n') : code
  return { block, rows, source, incomplete: code.length < block.code.length }
}

type Streamed = ReturnType<typeof streamed>

function variantOf(item: Streamed, index: number) {
  if (item.block.diff) {
    const row = item.rows[index]
    return row?.startsWith('+') ? 'added' : row?.startsWith('-') ? 'removed' : 'default'
  }
  return item.block.highlight?.includes(index) ? 'highlighted' : 'default'
}

export default class CodeBlockStreaming extends Component {
  @tracked length = total

  #timeout: ReturnType<typeof setTimeout> | undefined

  constructor(owner: unknown, args: object) {
    super(owner as never, args)
    registerDestructor(this, () => clearTimeout(this.#timeout))
  }

  get streaming(): boolean {
    return this.length < total
  }

  /** The blocks that have started, each cut to what has streamed so far. */
  get visible(): Streamed[] {
    return blocks.flatMap((block, index) =>
      this.length > offsets[index]!
        ? [streamed(block, block.code.slice(0, this.length - offsets[index]!))]
        : [],
    )
  }

  #tick(): void {
    if (this.length >= total) return
    this.#timeout = setTimeout(() => {
      this.length += 3
      this.#tick()
    }, 16)
  }

  replay = () => {
    this.length = 0
    this.#tick()
  }

  <template>
    <div class="flex w-full max-w-md flex-col gap-4">
      {{#each this.visible key="block" as |item|}}
        <CodeBlock as |b|>
          {{#if item.block.title}}
            <b.Header>
              <b.Title>{{item.block.title}}</b.Title>
              <b.Actions>
                <b.CopyButton @value={{item.source}} disabled={{item.incomplete}} />
              </b.Actions>
            </b.Header>
          {{/if}}
          <b.Content @lineNumbers={{item.block.lineNumbers}}>
            {{#each (highlightedCode item.source item.block.language) as |line index|}}
              <b.Line @code={{line}} @variant={{variantOf item index}} />
            {{/each}}
          </b.Content>
        </CodeBlock>
      {{/each}}
      <Button
        @variant="outline"
        @size="sm"
        class="self-start"
        disabled={{this.streaming}}
        {{on "click" this.replay}}
      >
        <Icon @icon={{RotateCcw}} />
        Replay
      </Button>
    </div>
  </template>
}
