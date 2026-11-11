import type { Message } from './i18n.ts'

/**
 * Every string `@ember-joinery/primitives` shows or announces itself, in English, for a
 * translation catalog. An argument (`@label`, `@labels`) still beats each one.
 */
export const messages = {
  breadcrumbLabel: { id: 'joinery.breadcrumb.label', message: 'Breadcrumb' },
  calendarToday: {
    id: 'joinery.calendar.today',
    message: 'Today, {date}',
    description: "A day's name, when it is today: {date} is the full date.",
  },
  calendarSelected: {
    id: 'joinery.calendar.selected',
    message: '{date}, selected',
    description: "A selected day's name: {date} is the full date.",
  },
  calendarTodaySelected: {
    id: 'joinery.calendar.todaySelected',
    message: 'Today, {date}, selected',
    description: "Today's name, when it is selected: {date} is the full date.",
  },
  calendarMonthDropdown: { id: 'joinery.calendar.monthDropdown', message: 'Choose the Month' },
  calendarYearDropdown: { id: 'joinery.calendar.yearDropdown', message: 'Choose the Year' },
  calendarNextMonth: { id: 'joinery.calendar.nextMonth', message: 'Go to the Next Month' },
  calendarPreviousMonth: {
    id: 'joinery.calendar.previousMonth',
    message: 'Go to the Previous Month',
  },
  calendarWeekNumber: { id: 'joinery.calendar.weekNumber', message: 'Week {week}' },
  calendarWeekNumberHeader: { id: 'joinery.calendar.weekNumberHeader', message: 'Week Number' },
  commandResults: {
    id: 'joinery.command.results',
    message: '{count} result',
    plural: '{count} results',
    description: 'Announced as the number of results changes.',
  },
  commandListLabel: { id: 'joinery.command.listLabel', message: 'Suggestions' },
  commandLoading: { id: 'joinery.command.loading', message: 'Loading...' },
  commandDialogTitle: { id: 'joinery.command.dialogTitle', message: 'Command Palette' },
  commandDialogDescription: {
    id: 'joinery.command.dialogDescription',
    message: 'Search for a command to run...',
  },
  inputOtpLabel: { id: 'joinery.input-otp.label', message: 'One-time password' },
  messageScrollerLabel: { id: 'joinery.message-scroller.label', message: 'Messages' },
  messageScrollerToStart: { id: 'joinery.message-scroller.toStart', message: 'Scroll to start' },
  messageScrollerToEnd: { id: 'joinery.message-scroller.toEnd', message: 'Scroll to end' },
  navigationMenuLabel: { id: 'joinery.navigation-menu.label', message: 'Main' },
  questionnaireProgressLabel: {
    id: 'joinery.questionnaire.progressLabel',
    message: 'Questionnaire progress',
  },
  questionnaireProgress: {
    id: 'joinery.questionnaire.progress',
    message: 'Question {current} of {total}',
  },
  questionnairePrevious: { id: 'joinery.questionnaire.previous', message: 'Previous' },
  questionnaireSkip: { id: 'joinery.questionnaire.skip', message: 'Skip' },
  questionnaireNext: { id: 'joinery.questionnaire.next', message: 'Next' },
  questionnaireSubmit: { id: 'joinery.questionnaire.submit', message: 'Submit' },
  questionnaireRequired: {
    id: 'joinery.questionnaire.required',
    message: 'Choose an answer to continue.',
  },
  questionnaireOptional: {
    id: 'joinery.questionnaire.optional',
    message: 'Choose an answer or skip this question.',
  },
  ratingItem: { id: 'joinery.rating.item', message: '{count} star', plural: '{count} stars' },
  ratingSummary: { id: 'joinery.rating.summary', message: 'Rated {value} out of {total}' },
  sliderValue: { id: 'joinery.slider.value', message: 'Value' },
  sliderMinimum: { id: 'joinery.slider.minimum', message: 'Minimum' },
  sliderMaximum: { id: 'joinery.slider.maximum', message: 'Maximum' },
  sliderNthValue: { id: 'joinery.slider.nthValue', message: 'Value {index} of {count}' },
  toastClose: { id: 'joinery.toast.close', message: 'Close toast' },
  toasterLabel: {
    id: 'joinery.toaster.label',
    message: 'Notifications {hotkey}',
    description: 'The toasts\' region: {hotkey} is the shortcut that moves to it, "alt+T".',
  },
  zoetropeScrollLeft: { id: 'joinery.zoetrope.scrollLeft', message: 'Left' },
  zoetropeScrollRight: { id: 'joinery.zoetrope.scrollRight', message: 'Right' },
} satisfies Record<string, Message>
