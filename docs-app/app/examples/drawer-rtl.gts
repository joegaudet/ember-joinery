import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Minus, Plus } from 'lucide'
import { Button, Drawer, Icon } from '@ember-joinery/ember'
import { BarChart } from '@ember-joinery/chart'

// Upstream's example opens in Arabic, and offers Hebrew and English (a picker the guide's frame
// doesn't have).
const locale = 'ar-EG'
const t = {
  trigger: 'فتح الدرج',
  title: 'نقل الهدف',
  description: 'حدد هدف نشاطك اليومي.',
  caloriesPerDay: 'سعرات حرارية/يوم',
  decrease: 'تقليل',
  increase: 'زيادة',
  submit: 'إرسال',
  cancel: 'إلغاء',
}

const data = [
  {
    goal: 400,
  },
  {
    goal: 300,
  },
  {
    goal: 200,
  },
  {
    goal: 300,
  },
  {
    goal: 200,
  },
  {
    goal: 278,
  },
  {
    goal: 189,
  },
  {
    goal: 239,
  },
  {
    goal: 300,
  },
  {
    goal: 200,
  },
  {
    goal: 278,
  },
  {
    goal: 189,
  },
  {
    goal: 349,
  },
]

const localized = (value: number) => value.toLocaleString(locale)

export default class DrawerRtl extends Component {
  @tracked goal = 350

  onClick = (adjustment: number): void => {
    this.goal = Math.max(200, Math.min(400, this.goal + adjustment))
  }

  get atMin(): boolean {
    return this.goal <= 200
  }

  get atMax(): boolean {
    return this.goal >= 400
  }

  <template>
    {{!
      Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
      Arabic. Upstream puts dir on the content; Joinery's takes it from the nearest dir.
    }}
    <Drawer as |d|>
      <Button @variant="outline" {{d.trigger}}>{{t.trigger}}</Button>
      <d.Content>
        <div class="mx-auto w-full max-w-sm">
          <d.Header>
            <d.Title>{{t.title}}</d.Title>
            <d.Description>{{t.description}}</d.Description>
          </d.Header>
          <div class="p-4 pb-0">
            <div class="flex items-center justify-center space-x-2">
              <Button
                @variant="outline"
                @size="icon"
                class="h-8 w-8 shrink-0 rounded-full"
                disabled={{this.atMin}}
                {{on "click" (fn this.onClick -10)}}
              >
                <Icon @icon={{Minus}} />
                <span class="sr-only">{{t.decrease}}</span>
              </Button>
              <div class="flex-1 text-center">
                <div class="text-7xl font-bold tracking-tighter">
                  {{localized this.goal}}
                </div>
                <div class="text-[0.70rem] text-muted-foreground uppercase">
                  {{t.caloriesPerDay}}
                </div>
              </div>
              <Button
                @variant="outline"
                @size="icon"
                class="h-8 w-8 shrink-0 rounded-full"
                disabled={{this.atMax}}
                {{on "click" (fn this.onClick 10)}}
              >
                <Icon @icon={{Plus}} />
                <span class="sr-only">{{t.increase}}</span>
              </Button>
            </div>
            <div class="mt-3 h-[120px]">
              {{! Upstream's ResponsiveContainer is the chart's own: without a @width and
                  @height, a Joinery chart fills its box and follows it. Upstream fills its
                  bars through a style; @fill gives them the same colour. Right to left,
                  upstream reverses the x-axis. }}
              <BarChart @data={{data}} as |c|>
                <c.XAxis
                  @dataKey="goal"
                  @tickLine={{false}}
                  @tickMargin={{10}}
                  @axisLine={{false}}
                  @tickFormatter={{localized}}
                  @reversed={{true}}
                />
                <c.Bar @dataKey="goal" @fill="var(--chart-2)" />
              </BarChart>
            </div>
          </div>
          <d.Footer>
            <Button>{{t.submit}}</Button>
            <Button @variant="outline" {{d.close}}>{{t.cancel}}</Button>
          </d.Footer>
        </div>
      </d.Content>
    </Drawer>
  </template>
}
