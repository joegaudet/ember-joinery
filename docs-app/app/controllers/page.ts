import Controller from '@ember/controller'

/**
 * A guide page's query params. A transition keeps a query param only where a controller
 * declares it, so the ones the Query Params page's example sets are declared here, for the
 * example to work on the page (`primitives/query-params.md`).
 */
export default class PageController extends Controller {
  queryParams = ['view', 'compact']
}
