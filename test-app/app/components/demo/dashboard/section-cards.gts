import type { TOC } from '@ember/component/template-only'
import { TrendingDown, TrendingUp } from 'lucide'
import { Badge, Card, Icon } from '@ember-joinery/ember'

// Each title's `leading-8` and `@[250px]/card:leading-9` aren't upstream's. Its CardTitle's
// className goes through tailwind-merge, whose `text-2xl` and `text-3xl` drop the Card title's
// own `leading-snug`, so the title takes their line heights, 2rem and 2.25rem. Joinery's Card
// title keeps `leading-snug` (`--tw-leading`), which those utilities read before their own, so
// these two say upstream's line heights again.

const SectionCards: TOC<object> = <template>
  <div
    class="grid grid-cols-1 gap-4 px-4 *:data-[slot=card]:bg-gradient-to-t *:data-[slot=card]:from-primary/5 *:data-[slot=card]:to-card *:data-[slot=card]:shadow-xs lg:px-6 @xl/main:grid-cols-2 @5xl/main:grid-cols-4 dark:*:data-[slot=card]:bg-card"
  >
    <Card class="@container/card" as |c|>
      <c.Header>
        <c.Description>Total Revenue</c.Description>
        <c.Title
          class="text-2xl leading-8 font-semibold tabular-nums @[250px]/card:text-3xl @[250px]/card:leading-9"
        >
          $1,250.00
        </c.Title>
        <c.Action>
          <Badge @variant="outline">
            <Icon @icon={{TrendingUp}} />
            +12.5%
          </Badge>
        </c.Action>
      </c.Header>
      <c.Footer class="flex-col items-start gap-1.5 text-sm">
        <div class="line-clamp-1 flex gap-2 font-medium">
          Trending up this month
          <Icon @icon={{TrendingUp}} class="size-4" />
        </div>
        <div class="text-muted-foreground">
          Visitors for the last 6 months
        </div>
      </c.Footer>
    </Card>
    <Card class="@container/card" as |c|>
      <c.Header>
        <c.Description>New Customers</c.Description>
        <c.Title
          class="text-2xl leading-8 font-semibold tabular-nums @[250px]/card:text-3xl @[250px]/card:leading-9"
        >
          1,234
        </c.Title>
        <c.Action>
          <Badge @variant="outline">
            <Icon @icon={{TrendingDown}} />
            -20%
          </Badge>
        </c.Action>
      </c.Header>
      <c.Footer class="flex-col items-start gap-1.5 text-sm">
        <div class="line-clamp-1 flex gap-2 font-medium">
          Down 20% this period
          <Icon @icon={{TrendingDown}} class="size-4" />
        </div>
        <div class="text-muted-foreground">
          Acquisition needs attention
        </div>
      </c.Footer>
    </Card>
    <Card class="@container/card" as |c|>
      <c.Header>
        <c.Description>Active Accounts</c.Description>
        <c.Title
          class="text-2xl leading-8 font-semibold tabular-nums @[250px]/card:text-3xl @[250px]/card:leading-9"
        >
          45,678
        </c.Title>
        <c.Action>
          <Badge @variant="outline">
            <Icon @icon={{TrendingUp}} />
            +12.5%
          </Badge>
        </c.Action>
      </c.Header>
      <c.Footer class="flex-col items-start gap-1.5 text-sm">
        <div class="line-clamp-1 flex gap-2 font-medium">
          Strong user retention
          <Icon @icon={{TrendingUp}} class="size-4" />
        </div>
        <div class="text-muted-foreground">Engagement exceed targets</div>
      </c.Footer>
    </Card>
    <Card class="@container/card" as |c|>
      <c.Header>
        <c.Description>Growth Rate</c.Description>
        <c.Title
          class="text-2xl leading-8 font-semibold tabular-nums @[250px]/card:text-3xl @[250px]/card:leading-9"
        >
          4.5%
        </c.Title>
        <c.Action>
          <Badge @variant="outline">
            <Icon @icon={{TrendingUp}} />
            +4.5%
          </Badge>
        </c.Action>
      </c.Header>
      <c.Footer class="flex-col items-start gap-1.5 text-sm">
        <div class="line-clamp-1 flex gap-2 font-medium">
          Steady performance increase
          <Icon @icon={{TrendingUp}} class="size-4" />
        </div>
        <div class="text-muted-foreground">Meets growth projections</div>
      </c.Footer>
    </Card>
  </div>
</template>

export default SectionCards
