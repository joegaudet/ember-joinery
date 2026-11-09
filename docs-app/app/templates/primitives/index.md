# Primitives

`@ember-joinery/primitives` is the headless layer under Joinery's components: their behaviour,
focus management, keyboard handling and ARIA, with no styles. Use a primitive on its own, unstyled,
the way you'd use ember-primitives or Radix, when you bring your own design.

It also covers every feature of
[ember-primitives](https://github.com/universal-ember/ember-primitives), and its non-visual
utilities, one subpath export each (`@ember-joinery/primitives/<feature>`).

<SectionList @section="primitives" />

## Layout rules and your CSS layers

[Scroller](/primitives/scroller.md), [Zoetrope](/primitives/zoetrope.md),
[Hero](/primitives/hero.md) and [Sticky Footer](/primitives/sticky-footer.md) need a few rules
to work at all: a track that scrolls sideways, a grid, a size. They come with the component,
with nothing to import: the document (or the shadow root) adopts them as a style sheet when the
component first renders. They are in `@layer joinery`, at no specificity, so your CSS wins:

- your CSS outside any layer always does;
- your layers do once `joinery` comes before them. A layer's place is where the page first
  names it, and an adopted style sheet comes after all of the page's own. `joinery.css` names
  the layer, and so does the
  [Tailwind setup on Installation](/getting-started/installation.md#tailwind-apps), so with
  either there is nothing to do.

If nothing names it first, `joinery` is the last layer, and beats every layer of yours:
Tailwind's utilities too, so `<Hero class="h-80">` keeps the viewport's height. In an app that
uses the primitives without `joinery.css`, name it ahead of your own layers, at the top of your
first style sheet:

```css
/* Layers named first lose. With Tailwind: */
@layer theme, base, joinery, components, utilities;

/* With no layers of your own, there is nothing to do. With some: */
@layer joinery, my-app;
```
