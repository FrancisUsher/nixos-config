import { expect, mock, test } from 'claude-code/testing'

const long = (word: string) => Array(40).fill(word).join(' ')
const ANSWER = [long('alpha'), long('beta')].join('\n\n')
const typed = (text: string) => ({ text, wait: false, origin: { kind: 'composer' } as const })

test('/annotate-send with no review says so', async ($) => {
  const answer = await $.command.run({ command: 'annotate-send', args: '' })
  expect(answer.text).toBe('No review in progress.')
})

test('typing /annotate-send turns the prompt into the feedback', async ($, on) => {
  mock.store(on)
  const submitted: string[] = []
  on('turn.complete', () => ({ text: '' }))
  on('prompt.submit', ($, e) => {
    submitted.push(e.text)
    return { text: e.text }
  })
  await $.turn.complete({ turnId: 't1', answer: ANSWER, durationMs: 1, isAborted: false, usage: null })
  await $.command.run({ command: 'annotate', args: '' })
  await $.prompt.submit(typed('alpha is wrong'))
  await $.prompt.submit(typed('/annotate-send'))
  expect(submitted.length).toBe(1)
  expect(submitted[0]).toMatch(/\*\*Section 1\*\*\n> alpha[\s\S]*- alpha is wrong/)
  const after = await $.command.run({ command: 'annotate-send', args: '' })
  expect(after.text).toBe('No review in progress.')
})

test('notes survive a send that fails or is dropped', async ($, on) => {
  mock.store(on)
  let outcome: 'throw' | 'drop' | 'enter' = 'throw'
  const submitted: string[] = []
  on('turn.complete', () => ({ text: '' }))
  on('prompt.submit', ($, e) => {
    if (outcome === 'throw') throw new Error('boom')
    if (outcome === 'drop') return { drop: 'nope' }
    submitted.push(e.text)
    return { text: e.text }
  })
  await $.turn.complete({ turnId: 't1', answer: ANSWER, durationMs: 1, isAborted: false, usage: null })
  await $.command.run({ command: 'annotate', args: '' })
  await $.prompt.submit(typed('keep me'))

  await $.prompt.submit(typed('/annotate-send')).catch(() => {})
  outcome = 'drop'
  await $.prompt.submit(typed('/annotate-send'))
  outcome = 'enter'
  await $.prompt.submit(typed('/annotate-send'))
  expect(submitted.length).toBe(1)
  expect(submitted[0]).toMatch(/- keep me/)
})

test('an unsent review is restored from the store when the session starts', async ($, on) => {
  mock.store(on, { review: { sections: ['alpha', 'beta'], index: 1, notes: [{ section: 1, text: 'saved' }] } })
  const submitted: string[] = []
  on('command.register', ($, e) => ({ value: { command: e.name } }))
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('prompt.submit', ($, e) => {
    submitted.push(e.text)
    return { text: e.text }
  })
  await $.session.start({ cwd: '/', surface: 'terminal' })
  await $.prompt.submit(typed('/annotate-send'))
  expect(submitted[0]).toMatch(/\*\*Section 2\*\*\n> beta\n\n- saved/)
})
