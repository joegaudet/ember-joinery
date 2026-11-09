import { castToBoolean, qp, withQP } from '@ember-joinery/primitives/qp'

const current = (view: string | undefined, option: string | null) =>
  (view ?? null) === option ? 'page' : undefined

/**
 * A view switcher kept in the URL (`?view=grid`), so a reload or a shared link keeps it.
 * No controller reads the param: `qp` reads it from the router, and `withQP` writes the links.
 */
<template>
  <div data-test-jn="view-switcher">
    <nav aria-label="View">
      <a
        href={{withQP "view" "grid"}}
        aria-current={{current (qp "view") "grid"}}
        data-test-jn-part="option"
        data-test-jn-value="grid"
      >Grid</a>
      <a
        href={{withQP "view" "list"}}
        aria-current={{current (qp "view") "list"}}
        data-test-jn-part="option"
        data-test-jn-value="list"
      >List</a>
      <a
        href={{withQP "view" null}}
        aria-current={{current (qp "view") null}}
        data-test-jn-part="option"
        data-test-jn-value="default"
      >Default</a>
    </nav>
    <p data-test-jn-part="status">
      Showing the
      {{if (qp "view") (qp "view") "default"}}
      view{{if (castToBoolean (qp "compact")) ", compact"}}.
    </p>
  </div>
</template>
