## [0.4.4] - 2023-09-11

### Added

- Add a download object button for certain mime types when a link is focused
- GeminiAgent: remove temporary files on destruction
- Page loading animation
- Media playback control actions for the video player

### Changed

- Set better size boundaries for image preview items

### Fixed

- When we're switching from one gemspace to another, focus the first visible
  item in the flickable, so that navigating betweens items with "Tab" will work
  without any user intervention

## [0.4.3] - 2023-09-09

### Added

- Transparently render Atom & RSS feeds as gemini tinylogs

### Changed

## [0.4.2] - 2023-09-07

### Added

- Keywords to URL expansion rules
- Actions to save and load the pages in the stack layouts
- Add a combo box to set the theme in the settings

## [0.4.1] - 2023-09-06

### Changed

- Links: left alignment for the link text
- New theme variables
- Use QML's MultiEffect on text items (controls brightness and contrast)

## [0.4.0] - 2023-09-05

### Added

- gemalaya AppImage: automatic wheel updates

## [0.3.9] - 2023-08-31

### Added

- Add support for snippets (for input responses)
- Text search mode

## [0.3.8] - 2023-08-27

### Added

- Basic configuration dialog (F12 key)
- Themable scrollbar
- Animate the keyboard sequence item on success

### Changed

- The page flicking speed can now be amplified by holding "Control" or "Shift"
  (Control+Shift+PageDown for example is the fastest down flick)
- If the page is really large, render it in multiple sections (reaching the end
  of the page will render the next section)
- Set a custom persistent path for ignition's "known hosts" file
- Animate the scrollbar's background color depending on how
  fast we scroll (right now only the color's red component is changed)

## [0.3.7] - 2023-08-23

Minor changes in gemalaya

## [0.3.6] - 2023-08-23

Major changes in gemalaya

### Changed

- Use a Flickable instead of a ScrollView
- When a link is focused, the following keys will
  open the link: Kp_Enter (Enter key), the Return key and the space key

### Added

- Add config settings for the Flickable item
- Add keyboard shortcuts to cycle between the elements in the page

## [0.3.5] - 2023-08-21

Minor changes in gemalaya

## [0.3.4] - 2023-08-20

### Added

gemalaya:

- Support for multimedia content
- Spawn a levior process from gemalaya to be able to load web content
  with the http to gemini proxy
- Add shortcuts to increase/decrease the font sizes

## [0.3.1] - 2023-07-05

### Added
- Support for creating gempubs from yaml project files
- gemv: Follow and open gempub archive links
