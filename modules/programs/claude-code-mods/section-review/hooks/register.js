import { splitSections } from './split.js'
import { composeFeedback } from './feedback.js'
import { reviewBand } from './band.js'

const TYPED_BY_USER = ['composer', 'bridge']

let latestSections = []
let review = null

function startReview($) {
  if (latestSections.length === 0) return { text: 'No reply to review yet.' }
  review = { sections: latestSections, index: 0, notes: [] }
  $.ui.invalidate('ui.render')
  return {}
}

function page($, step) {
  if (!review) return
  review = { ...review, index: Math.min(Math.max(review.index + step, 0), review.sections.length - 1) }
  $.ui.invalidate('ui.render')
}

function cancelReview($) {
  review = null
  $.ui.invalidate('ui.render')
  return {}
}

async function sendReview($) {
  if (!review) return { text: 'No review in progress.' }
  if (review.notes.length === 0) return { text: 'No notes yet. Type one and press Enter, or /annotate-cancel.' }
  const text = composeFeedback(review.sections, review.notes)
  review = null
  $.ui.invalidate('ui.render')
  await $.prompt.submit({ text, asUser: true })
  return {}
}

export function register(on) {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'annotate', description: "Page through Claude's last reply section by section and note feedback" })
    await $.command.register({ name: 'annotate-send', description: 'Send the review notes as the next prompt' })
    await $.command.register({ name: 'annotate-cancel', description: 'Discard the review notes' })
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    if (!e.agentId && !e.isAborted && e.answer.trim()) latestSections = splitSections(e.answer)
    return next(e)
  })

  on('command.run', { command: 'annotate' }, async ($) => startReview($))
  on('command.run', { command: 'annotate-send' }, async ($) => sendReview($))
  on('command.run', { command: 'annotate-cancel' }, async ($) => cancelReview($))

  on('prompt.submit', async ($, e, next) => {
    if (!review || !TYPED_BY_USER.includes(e.origin.kind) || e.text.trimStart().startsWith('/')) return next(e)
    review = { ...review, notes: [...review.notes, { section: review.index, text: e.text.trim() }] }
    $.ui.invalidate('ui.render')
    return { drop: `Noted on section ${review.index + 1}` }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (!review) return next(e)
    return reviewBand($.ui.resolve(e), review, {
      prev: () => page($, -1),
      next: () => page($, 1),
      send: () => sendReview($),
      cancel: () => cancelReview($),
    })
  })
}
