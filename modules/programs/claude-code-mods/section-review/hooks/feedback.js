const QUOTE_LIMIT = 300

function quote(section) {
  const clipped = section.length > QUOTE_LIMIT ? section.slice(0, QUOTE_LIMIT).trimEnd() + ' …' : section
  return clipped
    .split('\n')
    .map((line) => '> ' + line)
    .join('\n')
}

export function composeFeedback(sections, notes) {
  const bySection = new Map()
  for (const note of notes) {
    bySection.set(note.section, [...(bySection.get(note.section) ?? []), note.text])
  }
  const items = [...bySection.keys()]
    .sort((a, b) => a - b)
    .map((index) => {
      const replies = bySection.get(index).map((text) => '- ' + text).join('\n')
      return `**Section ${index + 1}**\n${quote(sections[index])}\n\n${replies}`
    })
  return ['Feedback on your last reply, section by section:', ...items].join('\n\n')
}
