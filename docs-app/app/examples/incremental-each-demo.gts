import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { on } from '@ember/modifier'
import type Owner from '@ember/owner'
import { IncrementalEach } from '@ember-joinery/primitives/incremental-each'

const BATCH_SIZE = 400
const rows = Array.from({ length: 20_000 }, (_, i) => `Row ${i + 1}`)

export default class IncrementalEachDemo extends Component {
  @tracked visible = true
  @tracked elapsedMs = 0
  @tracked batches = 0
  @tracked done = false
  @tracked mode: 'sync' | 'lazy' = 'lazy'

  startedAt = performance.now()
  tickId: ReturnType<typeof setInterval> | undefined

  constructor(owner: Owner, args: object) {
    super(owner, args)
    this.startTicker()
    registerDestructor(this, () => this.stopTicker())
  }

  stopTicker = () => clearInterval(this.tickId)

  sample = () => {
    if (this.done) return
    this.elapsedMs = Math.round(performance.now() - this.startedAt)
    const rendered = document.querySelectorAll('.incremental-demo li').length
    this.batches = Math.ceil(rendered / BATCH_SIZE)
  }

  startTicker = () => {
    this.stopTicker()
    this.tickId = setInterval(this.sample, 100)
  }

  handleDone = () => {
    this.done = true
    this.elapsedMs = Math.round(performance.now() - this.startedAt)
    this.batches = Math.ceil(rows.length / BATCH_SIZE)
    this.stopTicker()
  }

  toggleMode = () => {
    this.handleDone()
    this.stop()
    this.mode = this.mode === 'lazy' ? 'sync' : 'lazy'
    // we have to give enough time for ember to delete all the nodes from
    // the stop() call above
    requestAnimationFrame(() => {
      this.start()
    })
  }

  start = () => {
    this.startedAt = performance.now()
    this.done = false
    this.elapsedMs = 0
    this.batches = 0
    this.visible = true
    this.startTicker()
  }

  stop = () => {
    this.visible = false
    this.done = false
    this.elapsedMs = 0
    this.batches = 0
    this.stopTicker()
  }

  toggle = () => {
    if (this.visible) {
      this.stop()
      return
    }

    this.start()
  }

  <template>
    <div class="incremental-card not-prose">
      <div class="incremental-controls">
        <button type="button" {{on "click" this.toggleMode}}>
          Mode:
          {{this.mode}}
        </button>
        <button type="button" {{on "click" this.toggle}}>
          {{if this.visible "Hide" "Show"}}
          rows
        </button>
        {{#if this.visible}}
          <span class="incremental-count">
            {{rows.length}}
            rows ·
            {{this.batches}}
            batches ·
            {{this.elapsedMs}}ms{{if this.done " (done)"}}
          </span>
        {{/if}}
      </div>

      {{#if this.visible}}
        {{! tabindex and a label, which upstream's list doesn't have: a box that scrolls needs
            to be reachable from the keyboard. }}
        <ul class="incremental-demo" tabindex="0" aria-label="Rows">
          <IncrementalEach
            @items={{rows}}
            @batchSize={{BATCH_SIZE}}
            @initial={{this.mode}}
            @onDone={{this.handleDone}}
            as |row|
          ><li>{{row}}</li></IncrementalEach>
        </ul>
      {{/if}}
    </div>

    <style>
      .incremental-card {
        background: #fff;
        color: #111827;
        border-radius: 8px;
        padding: 1rem;
        box-shadow:
          0 10px 15px -3px rgb(0 0 0 / 0.1),
          0 4px 6px -4px rgb(0 0 0 / 0.1);
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
      }
      .incremental-controls {
        display: flex;
        align-items: center;
        gap: 0.75rem;
      }
      .incremental-controls button {
        padding: 0.4rem 0.9rem;
        font: inherit;
        color: #fff;
        background: #4f46e5;
        border: 0;
        border-radius: 6px;
        cursor: pointer;
      }
      .incremental-controls button:hover {
        background: #4338ca;
      }
      .incremental-count {
        color: #6b7280;
        font-size: 0.875rem;
      }
      .incremental-demo {
        max-height: 320px;
        overflow: auto;
        background: #f9fafb;
        border: 1px solid #e5e7eb;
        border-radius: 6px;
        padding: 0.75rem 1rem;
        margin: 0;
        list-style: none;
      }
      .incremental-demo li {
        padding: 0.125rem 0;
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        font-size: 0.875rem;
        color: #111827;
      }
    </style>
  </template>
}
