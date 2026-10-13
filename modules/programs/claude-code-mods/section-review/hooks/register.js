import { splitSections } from './split.js'
import { composeFeedback } from './feedback.js'
import { reviewBand } from './band.js'
import { annotateHint } from './hint.js'

const TYPED_BY_USER = ['composer', 'bridge']
const STORE_KEY = 'review'

let latestSections = []
let review = null

async function setReview($, value) {
  review = value
  $.ui.invalidate('ui.render')
  if (value) await $.store.set(STORE_KEY, value)
  else await $.store.delete(STORE_KEY)
}

async function startReview($) {
  if (review) return { text: `Resumed the review in progress (${review.notes.length} notes).` }
  if (latestSections.length === 0) return { text: 'No reply to review yet.' }
  await setReview($, { sections: latestSections, index: 0, notes: [] })
  return {}
}

async function page($, step) {
  if (!review) return
  await setReview($, { ...review, index: Math.min(Math.max(review.index + step, 0), review.sections.length - 1) })
}

async function cancelReview($) {
  await setReview($, null)
  return {}
}

function unsendable() {
  if (!review) return 'No review in progress.'
  if (review.notes.length === 0) return 'No notes yet. Type one and press Enter, or /annotate-cancel.'
}

async function submitFeedback($, submit) {
  const result = await submit(composeFeedback(review.sections, review.notes))
  if (result.drop === undefined) {
    latestSections = []
    await setReview($, null)
  }
  return result
}

async function sendReview($) {
  const reason = unsendable()
  if (reason) return { text: reason }
  await submitFeedback($, (text) => $.prompt.submit({ text, asUser: true }))
  return {}
}

export function register(on) {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'annotate', description: "Page through Claude's last reply section by section and note feedback" })
    await $.command.register({ name: 'annotate-send', description: 'Send the review notes as the next prompt' })
    await $.command.register({ name: 'annotate-cancel', description: 'Discard the review notes' })
    review = (await $.store.get(STORE_KEY)) ?? null
    $.ui.invalidate('ui.render')
    return next(e)
  })

  on('turn.start', async ($, e, next) => {
    latestSections = []
    $.ui.invalidate('ui.render')
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    if (!e.agentId && !e.isAborted && e.answer.trim()) latestSections = splitSections(e.answer)
    $.ui.invalidate('ui.render')
    return next(e)
  })

  on('command.run', { command: 'annotate' }, async ($) => startReview($))
  on('command.run', { command: 'annotate-send' }, async () => ({ text: unsendable() }))
  on('command.run', { command: 'annotate-cancel' }, async ($) => cancelReview($))

  on('prompt.submit', async ($, e, next) => {
    if (e.text.trim() === '/annotate-send' && !unsendable()) return submitFeedback($, (text) => next({ ...e, text }))
    if (!review || !TYPED_BY_USER.includes(e.origin.kind) || e.text.trimStart().startsWith('/')) return next(e)
    await setReview($, { ...review, notes: [...review.notes, { section: review.index, text: e.text.trim() }] })
    return { drop: `Noted on section ${review.index + 1}` }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (!review && latestSections.length === 0) return next(e)
    if (!review) return annotateHint($.ui.resolve(e), latestSections.length, () => startReview($))
    return reviewBand($.ui.resolve(e), review, {
      prev: () => page($, -1),
      next: () => page($, 1),
      send: () => sendReview($),
      cancel: () => cancelReview($),
    })
  })
}
