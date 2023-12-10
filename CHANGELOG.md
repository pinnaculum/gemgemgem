## [0.6.1] - 2023-12-10

### Added
- Links grids: settings for the layout's opacity (when the grid is collapsed)
- New theme: splendid

### Changed
- Automatic focus of the first visible element in the page when
  a (vertical) flick is finished

## [0.6.0] - 2023-12-06

### Added
- Config settings for the page margins
- Link grids: make it possible to limit the grid's height when
  no link in the grid is focused
- Add a shortcut to skip a grid and focus the next element in the layout

### Changed
- Change the default shortcut to go back in the history

### Fixed
- Disable TTS, animations and MultiEffect on preformatted text items

## [0.5.9] - 2023-11-29

### Added

- Text-to-speech: support read-through mode (automatic sequential TTS of
  the entire page)

### Changed

- Make it possible to use a custom levior config file

## [0.5.8] - 2023-11-25

### Changed

- Use levior in proxy mode

## [0.5.7] - 2023-11-07

### Added

- Support for laying out links in grid layouts
- Config settings and shortcuts for configuring the links grids
- Separators for gemini "blanks"

## [0.5.6] - 2023-10-23

### Added

- Settings: translation languages configuration

## [0.5.5] - 2023-10-22

### Added

- Support for text translations

### Changed

- gemqti: transform into a python package with a module per interface

## [0.5.4] - 2023-10-20

### Added

- Add a "Test TTS" button in the settings to test the text-to-speech feature
- Add a config setting to enable/disable automatic updates

### Changed

- nanotts: Use -f with an input file instead of passing the text with -i

## [0.5.3] - 2023-10-19

### Added

- Add support for nanotts

## [0.5.2] - 2023-10-18

### Added

- Add support for the Pico text-to-speech engine
- Add a combo box to select the TTS engine
- Show a privacy warning when the user selects gtts

## [0.5.1] - 2023-10-01

### Changed

- Make sure TTS actions are disabled when a gemspace is hidden

## [0.5.0] - 2023-09-27

### Added

- Support for the misfin protocol
- Add popup dialogs to create misfin identities and send messages

## [0.4.9] - 2023-09-25

### Added

- gtts caching system: generated mp3 TTS files are cached for a certain time
- Add config settings for the gtts TLD and the lifetime for cached TTS files

### Changed

- When going out of focus, pause the TTS audio instead of stopping it

### Fixed

- Make sure to stop and destroy the TTS player when a TextItem is destroyed

### Changed

## [0.4.8] - 2023-09-24

This release adds support for text-to-speech in gemalaya

### Added

- Support for text-to-speech (TTS) on text items, using gtts
- TTS audio player with keyboard shortcuts to seek and play/pause the audio
- Basic config settings for TTS: autoplay and "slow reading"
- API for text language detection

## [0.4.7] - 2023-09-23

### Added

- Support file uploads with the titan protocol

## [0.4.6] - 2023-09-21

### Added

- Convert rst (restructured text) documents to gemtext
- Add a UI option to show link URLs when links are focused

### Fixed

- Reset the action mode and text search buffer when a page is loaded

## [0.4.5] - 2023-09-17

### Added

- Convert markdown documents to gemtext

### Changed

- Lower default cache TTL

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
