# Changelog  
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [2020-03-01] - 2020-03-01
### Added
- option: experimental SendMessage methods (remove annotation on page, remove annotation under mouse)
- option: colorpicker popup for `A (hold)` (.ini setting) instead of default cycle colors one by one

## [2020-02-25] - 2020-02-25
### Added
- option: experimental SendMessage methods (highlight selection, annotate dot under mouse, get page under mouse, get document canvas X Y pt under mouse, get foreground page). (requires SumatraPDF C++ edits)

## [2020-02-24] - 2020-02-24
### Added
- Readme instruction on changing default highlight color

### Changed
- quick jump label no longer force lowercase

## [2020-02-20] - 2020-02-20
### Added
- Jump shortcuts (`Ctrl + PgUp` ...) also work on Numpads (`Ctrl + Numpad PgDn` ...)

### Changed
- Clarified Readme about .ini file options
- New icon (H on yellow background) with multiple sizes

## [2020-02-18] - 2020-02-18
### Added
- `readme.html` (based on `README.md`) and tray menu option to open it
- Option:  `CapsLock` = erase highlight under mouse (.ini setting). Use if touchpad palm tracking blocks `E`.
- Option: `Q` = quick jumps menu (.ini setting)
- Option: use selected text as label in jump menu list (.ini setting) (issue #4)
- Option: experimental better position and page detection for `D`, `E`, `Ctrl+Del` and quick jump shortcuts (requires SumatraPDF C++ edits)

### Fixed
- `D` and `E`: read correct mouse canvas position from notification window (issue #6)
- `A` shortcut passthrough to SumatraPDF if unsupported filetype or if document not focused (issue #3)
- Tray menu popup window condensed to fit low resolution screens, now shows only shortcuts (issue #1)

## [2020-02-14] - 2020-02-14
### Added
- Support for `CHM MOBI TXT LOG` filetypes (requires SumatraPDF advanced setting)
- Support for `DJV` filetype
- Readme entry on known issue in continous page mode
- Readme clarification on compatibility and possible breaking changes

### Changed
- Reworked functions to get filepath, smx data, pagenumber and document length
- Improved legacy function for filepath from SumatraPDF window title, but some edge cases remain
- Readme clarification on SumatraPDF version compatibility

### Fixed
- `D` (dot) and `E` (erase) failed in some SumatraPDF language translations, for example Dutch
- Green and red highlight failed if no .smx file existed
- Stop if unsupported filetype
- Pass single character hotkey to SumatraPDF if unsupported filetype or if document not focused

## [2020-02-09] - 2020-02-09
### Changed
- Renamed app HighlightJump to signal both highlight and jump features
- Big code rework
- Changed mouse shortcuts (see Readme)
- Changed shortcut: `A` = yellow, or hold to cycle color
- Changed shortcut: `D` ("dot") = blue rectangular dot
- Changed shortcut: `E` ("erase") = remove all highlighting under mouse
- Changed shortcut: `Control + Delete` = remove all highlighting on page
- Changed shortcut: `R` = red (Overrides SumatraPDF "reload". Replacement: `Ctrl+R`)
- Changed shortcut: `G` = green (Overrides SumatraPDF "go to". Use `Ctrl+G` instead)
- Changed jump shortcuts to be shorter (see Readme)
- Use SendMessage to make SumatraPDF save annotations, refresh, and goto page

### Fixed
- Fixed compatibility with new SumatraPDF `A` annotation key
- Fixed blue rectangle annotation position in .epub
- Fixed blue rectangle annotation works even if no .smx exists yet

### Added
- Quick jump: temporarily store and jump to pagenumber. Shortcuts `1 2 3 4 5`. Cleared on app close.
- Show tray icon also when running .ahk uncompiled
- option: experimental SendMessage methods to silently get filepath and canvas position (requires SumatraPDF C++ edits)
- .ini file

## [2017-05-23] - 2017-05-23
### Added
- First GitHub release (then named sumatra_highlight_helper)
