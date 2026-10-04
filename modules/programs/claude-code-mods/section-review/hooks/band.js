export function reviewBand({ Box, Text, Markdown, Button }, review, actions) {
  const { sections, index, notes } = review
  const notesHere = notes.filter((note) => note.section === index)
  const header = `Review · section ${index + 1}/${sections.length} · ${notes.length} note${notes.length === 1 ? '' : 's'} · Enter adds a note`

  return Box({
    flexDirection: 'column',
    borderStyle: 'round',
    paddingX: 1,
    children: [
      Text({ dimColor: true, children: [header] }),
      Markdown({ key: 'section-' + index, text: sections[index] }),
      ...notesHere.map((note, i) =>
        Text({ key: 'note-' + i, color: 'yellow', wrap: 'wrap', children: ['↳ ' + note.text] }),
      ),
      Box({
        flexDirection: 'row',
        columnGap: 2,
        children: [
          Button({ key: 'prev', label: 'ctrl+↑ prev', action: 'app:diffFileListUp', onPress: actions.prev }),
          Button({ key: 'next', label: 'ctrl+↓ next', action: 'app:diffFileListDown', onPress: actions.next }),
          Button({ key: 'send', label: '/annotate-send', onPress: actions.send }),
          Button({ key: 'cancel', label: '/annotate-cancel', onPress: actions.cancel }),
        ],
      }),
    ],
  })
}
