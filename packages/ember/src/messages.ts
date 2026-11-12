import type { Message } from '@ember-joinery/primitives/i18n'

/**
 * Every string `@ember-joinery/ember` shows or announces itself, in English, for a translation
 * catalog. Its components also show `@ember-joinery/primitives/messages`' (a calendar's, a
 * slider's). An argument (`@label`, `@closeLabel`) still beats each one.
 */
export const messages = {
  breadcrumbLabel: {
    id: 'joinery.breadcrumb.styledLabel',
    message: 'breadcrumb',
    description: "The breadcrumb's name, lowercase as upstream's.",
  },
  breadcrumbMore: { id: 'joinery.breadcrumb.more', message: 'More' },
  comboboxClear: { id: 'joinery.combobox.clear', message: 'Clear' },
  comboboxShowOptions: { id: 'joinery.combobox.showOptions', message: 'Show options' },
  comboboxRemove: { id: 'joinery.combobox.remove', message: 'Remove' },
  dialogClose: { id: 'joinery.dialog.close', message: 'Close' },
  documentFileDropLabel: { id: 'joinery.document-file-drop.label', message: 'Drop files anywhere' },
  paginationLabel: {
    id: 'joinery.pagination.label',
    message: 'pagination',
    description: "The pagination's name, lowercase as upstream's.",
  },
  paginationPreviousLabel: {
    id: 'joinery.pagination.previousLabel',
    message: 'Go to previous page',
  },
  paginationNextLabel: { id: 'joinery.pagination.nextLabel', message: 'Go to next page' },
  paginationPrevious: { id: 'joinery.pagination.previous', message: 'Previous' },
  paginationNext: { id: 'joinery.pagination.next', message: 'Next' },
  paginationMore: { id: 'joinery.pagination.more', message: 'More pages' },
  sheetClose: { id: 'joinery.sheet.close', message: 'Close' },
  sidebarMobileTitle: { id: 'joinery.sidebar.mobileTitle', message: 'Sidebar' },
  sidebarMobileDescription: {
    id: 'joinery.sidebar.mobileDescription',
    message: 'Displays the mobile sidebar.',
  },
  sidebarToggle: { id: 'joinery.sidebar.toggle', message: 'Toggle Sidebar' },
  spinnerLabel: { id: 'joinery.spinner.label', message: 'Loading' },
} satisfies Record<string, Message>
