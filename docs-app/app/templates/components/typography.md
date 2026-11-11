# Typography

Styles for headings, paragraphs, lists, etc.

We do not ship any typography styles by default. This page is an example of how you can use
utility classes to style your text.

They are Tailwind's classes, so they need a Tailwind app (see
[Installation](/getting-started/installation.md)), whose preflight resets these elements first:
no margins, borders or list bullets but what a class gives them. The previews here give these
examples that reset too, as ui.shadcn.com's do. Without Tailwind, write the same rules in your
own CSS.

<Example @name="typography-demo" @title="Typography" />

## h1

<Example @name="typography-h1" @title="h1" />

## h2

<Example @name="typography-h2" @title="h2" />

## h3

<Example @name="typography-h3" @title="h3" />

## h4

<Example @name="typography-h4" @title="h4" />

## p

<Example @name="typography-p" @title="p" />

## blockquote

<Example @name="typography-blockquote" @title="blockquote" />

## table

<Example @name="typography-table" @title="table" />

## list

<Example @name="typography-list" @title="list" />

## Inline code

<Example @name="typography-inline-code" @title="Inline code" />

## Lead

<Example @name="typography-lead" @title="Lead" />

## Large

<Example @name="typography-large" @title="Large" />

## Small

<Example @name="typography-small" @title="Small" />

## Muted

<Example @name="typography-muted" @title="Muted" />

## RTL

Upstream's right-to-left example writes its sides with logical classes (`border-s-2`, `ps-6`,
`ms-6`, `text-start`), so the same markup lays itself out right to left inside any element with
`dir="rtl"` (see [Direction](/primitives/direction.md)).

<Example @name="typography-rtl" @title="RTL" @dir="rtl" />

## Testing

There is no component, so there is no harness: test your own text with qunit-dom, as each
example's Test tab does (`assert.dom('h1').hasText(…)`), and end with an axe audit.

## Upstream

shadcn/ui's [Typography](https://ui.shadcn.com/docs/components/radix/typography), from
`apps/v4/content/docs/components/radix/typography.mdx` and its examples in
`apps/v4/examples/radix/typography-*.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
