import { expect, test } from 'claude-code/testing'

const long = (word: string) => Array(40).fill(word).join(' ')
const ANSWER = [long('alpha'), long('beta')].join('\n\n')
const typed = (text: string) => ({ text, wait: false, origin: { kind: 'composer' } as const })

test('/annotate-send with no review says so', async ($) => {
  const answer = await $.command.run({ command: 'annotate-send', args: '' })
  expect(answer.text).toBe('No review in progress.')
})

test('typing /annotate-send turns the prompt into the feedback', async ($, on) => {
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
