export function annotateHint({ Button }, sectionCount, onStart) {
  return Button({
    key: 'start',
    label: `ctrl+↓ annotate · ${sectionCount} section${sectionCount === 1 ? '' : 's'}`,
    plain: true,
    dimColor: true,
    action: 'app:diffFileListDown',
    onPress: onStart,
  })
}
