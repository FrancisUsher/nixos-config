import { expect, mock, test } from 'claude-code/testing'


const long = (word: string) => Array(40).fill(word).join(' ')
const ANSWER = [long('alpha'), long('beta'), long('gamma')].join('\n\n')

const BAND = {
  plugin: 'section-review',
  component: 'AbovePrompt',
  requestId: 'AbovePrompt',
  surface: 'terminal',
  viewport: { columns: 100, rows: 40 },
  props: { hasSurvey: false, isWorking: false, maxRows: 20, bodyColumns: 96, scroll: { offset: 0, bodyRows: 20 }, view: {} },
} as const

const typed = (text: string) => ({ text, wait: false, origin: { kind: 'composer' } as const })

test('/annotate with no reply yet says so', async ($) => {
  const answer = await $.command.run({ command: 'annotate', args: '' })
  expect(answer.text).toBe('No reply to review yet.')
})

test('typed lines become notes on the current section and are sent as one prompt', async ($, on) => {
  mock.store(on)
  const submitted: string[] = []
  on('turn.complete', () => ({ text: '' }))
  on('prompt.submit', ($, e) => {
    submitted.push(e.text)
    return { text: e.text }
  })
  on('ui.render', () => ({ type: 'Text', props: {}, children: ['engine band'] }))

  await $.turn.complete({ turnId: 't1', answer: ANSWER, durationMs: 1, isAborted: false, usage: null })
  await $.command.run({ command: 'annotate', args: '' })

  const ui = await $.ui.mount(BAND)
  expect(await ui.find({ type: 'Text', text: /section 1\/3/ })).toBeDefined()

  expect(await $.prompt.submit(typed('alpha is wrong'))).toEqual({ drop: 'Noted on section 1' })
  await ui.press({ key: 'next' })
  await ui.press({ key: 'next' })
  expect(await ui.find({ type: 'Text', text: /section 3\/3/ })).toBeDefined()
  await $.prompt.submit(typed('why gamma?'))
  await ui.press({ key: 'next' })
  expect(await ui.find({ type: 'Text', text: /section 3\/3 · 2 notes/ })).toBeDefined()

  await ui.press({ key: 'send' })
  expect(submitted.length).toBe(1)
  expect(submitted[0]).toMatch(/\*\*Section 1\*\*\n> alpha[\s\S]*- alpha is wrong/)
  expect(submitted[0]).toMatch(/\*\*Section 3\*\*\n> gamma[\s\S]*- why gamma\?/)
  expect(submitted[0]).not.toMatch(/Section 2/)
  expect(await ui.find({ type: 'Text', text: 'engine band' })).toBeDefined()
})

test('a hint appears after a reply and pressing it starts the review', async ($, on) => {
  mock.store(on)
  on('turn.complete', () => ({ text: '' }))
  on('ui.render', () => ({ type: 'Text', props: {}, children: ['engine band'] }))

  const ui = await $.ui.mount(BAND)
  expect(await ui.find({ key: 'start' })).toBeUndefined()

  await $.turn.complete({ turnId: 't1', answer: ANSWER, durationMs: 1, isAborted: false, usage: null })
  const hint = await ui.find({ key: 'start' })
  expect(hint?.props.label).toBe('ctrl+↓ annotate · 3 sections')
  expect(hint?.props.action).toBe('app:diffFileListDown')

  await ui.press({ key: 'start' })
  expect(await ui.find({ type: 'Text', text: /section 1\/3/ })).toBeDefined()
})

test('the hint clears when the next turn starts', async ($, on) => {
  mock.store(on)
  on('turn.complete', () => ({ text: '' }))
  on('turn.start', ($, e) => ({ turnId: e.turnId }))
  on('ui.render', () => ({ type: 'Text', props: {}, children: ['engine band'] }))

  await $.turn.complete({ turnId: 't1', answer: ANSWER, durationMs: 1, isAborted: false, usage: null })
  await $.turn.start({ turnId: 't2' })
  const ui = await $.ui.mount(BAND)
  expect(await ui.find({ key: 'start' })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: 'engine band' })).toBeDefined()
})

test('slash commands pass through while reviewing', async ($, on) => {
  mock.store(on)
  on('turn.complete', () => ({ text: '' }))
  on('prompt.submit', ($, e) => ({ text: e.text }))
  await $.turn.complete({ turnId: 't1', answer: ANSWER, durationMs: 1, isAborted: false, usage: null })
  await $.command.run({ command: 'annotate', args: '' })
  expect(await $.prompt.submit(typed('/annotate-send'))).toEqual({ text: '/annotate-send' })
})

test('/annotate-cancel drops the notes and stops swallowing prompts', async ($, on) => {
  mock.store(on)
  on('turn.complete', () => ({ text: '' }))
  on('prompt.submit', ($, e) => ({ text: e.text }))
  await $.turn.complete({ turnId: 't1', answer: ANSWER, durationMs: 1, isAborted: false, usage: null })
  await $.command.run({ command: 'annotate', args: '' })
  await $.prompt.submit(typed('a note'))
  await $.command.run({ command: 'annotate-cancel', args: '' })
  expect(await $.prompt.submit(typed('hello'))).toEqual({ text: 'hello' })
})
