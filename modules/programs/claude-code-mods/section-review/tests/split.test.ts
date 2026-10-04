import { expect, test } from 'claude-code/testing'
import { splitSections } from '../hooks/split.js'

const long = (word: string) => Array(40).fill(word).join(' ')

test('long paragraphs each become a section', async () => {
  const text = [long('alpha'), long('beta'), long('gamma')].join('\n\n')
  expect(splitSections(text)).toEqual([long('alpha'), long('beta'), long('gamma')])
})

test('short paragraphs are grouped up to three at a time', async () => {
  const text = ['## Heading', 'one', 'two', 'three', 'four'].join('\n\n')
  expect(splitSections(text)).toEqual(['## Heading\n\none\n\ntwo', 'three\n\nfour'])
})

test('a short heading joins the long paragraph after it', async () => {
  const text = ['## Heading', long('body')].join('\n\n')
  expect(splitSections(text)).toEqual(['## Heading\n\n' + long('body')])
})

test('blank lines inside a code fence do not split it', async () => {
  const fence = '```js\nconst a = 1\n\nconst b = 2\n```'
  const text = [long('intro'), fence].join('\n\n')
  expect(splitSections(text)).toEqual([long('intro'), fence])
})

test('a different fence inside a fence does not close it', async () => {
  const fence = '~~~md\n```js\nconst a = 1\n```\n\nafter the inner block\n~~~'
  const text = [long('intro'), fence].join('\n\n')
  expect(splitSections(text)).toEqual([long('intro'), fence])
})
