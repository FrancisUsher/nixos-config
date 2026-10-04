const SHORT_PARAGRAPH = 160
const MAX_GROUP = 3

export function paragraphs(text) {
  const blocks = []
  let current = []
  let openFence = null
  for (const line of text.split('\n')) {
    const fence = line.match(/^\s*(`{3,}|~{3,})/)?.[1]
    if (fence && !openFence) openFence = fence
    else if (fence && fence[0] === openFence[0] && fence.length >= openFence.length) openFence = null
    if (!openFence && line.trim() === '') {
      if (current.length) blocks.push(current.join('\n'))
      current = []
    } else {
      current.push(line)
    }
  }
  if (current.length) blocks.push(current.join('\n'))
  return blocks
}

export function splitSections(text) {
  const sections = []
  let group = []
  for (const paragraph of paragraphs(text)) {
    group.push(paragraph)
    const groupLength = group.join('\n\n').length
    if (groupLength >= SHORT_PARAGRAPH || group.length >= MAX_GROUP) {
      sections.push(group.join('\n\n'))
      group = []
    }
  }
  if (group.length) sections.push(group.join('\n\n'))
  return sections
}
