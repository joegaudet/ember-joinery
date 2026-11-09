# Toast

A succinct message that is displayed temporarily.

The toast component has been deprecated. Use the [sonner](/components/sonner.md) component
instead.

## In Joinery

Joinery has one toast, and it is [Sonner](/components/sonner.md)'s: `toast()` to show one from
anywhere, and `<Toaster>` to render them, from `@ember-joinery/ember`. There is no separate
Toast component, as upstream's deprecated one was; its page is here so the guide's components
match ui.shadcn.com's.

```gts
import { Toaster, toast } from '@ember-joinery/ember'

toast('Event has been created', { description: 'Sunday at 9:00 AM' })
```

Upstream's page has no examples. Sonner's page has them all, its API and its harnesses, and
[Toast](/primitives/toast.md) in the primitives is the headless part underneath.

## Upstream

shadcn/ui's [Toast](https://ui.shadcn.com/docs/components/radix/toast) page, at
shadcn-ui/ui@8ab2771, which points to Sonner.
