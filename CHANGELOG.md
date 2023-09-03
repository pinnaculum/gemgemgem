# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
