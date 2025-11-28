# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.0.6] - 2025-11-29

### Added

- Horizontal scroll in vimouto.
- `vimouto:adjustViewport()`.
- `Buffer:adjustView()`.
- `Buffer:calculateDigits()`.

### Changed

- Change main font.

### Fixed

- Bug: tree entries oveflow.
- Bug: pressing tab to close tree when cursor in tree will make the cursor vanish.


## [0.0.5] - 2025-11-28

### Added

- Test for vimouto TREE mode.
- `Ada/` home directory Ada.
- Ep3: Write the future.
- notes-from-future.txt.
- NFF 2025-11-30.

### Changed

- Master branch to main.

## Fixed

- Audio path has changed to `audios/`.


## [0.0.4] - 2025-11-27

### Added

- Lust testing library.
- Testing for util.lua.
- `vimouto:reset()`.
- Test i, I, o, O, a, A.
- Basic tree listing. Toggle with tab. Switch between tree and current buffer with space.
- TREE mode.
- Make treeBindings.

### Changed

- Move splitlines to util.lua.
- Move fontH and fontW to vimoto table.
- Proper quit from vimouto using fsm.pop().

## Fixed

- Don't open file if already opened before.


## [0.0.3] - 2025-11-25

### Added

- Buffer class for vimouto.
- Opening file support with :e filename.
- Buffer id.
- Command :ls to list buffers.
- Arrow keys in insert mode.

### Changed

- Turn vimouto into several files.
- Modes are for whole session instead of per buffer.
- Turn echo() and echoError() for whole session.

### Fixed

- Bug: pressing J in insert mode will result in jJ.
- Bug: pressing o, O, i, I, a, A after displaying message in cmd didn't erase the message.
- Bug: backspace after j didn't work properly


## [0.0.2] - 2025-11-24

### Added

- roboto.ttf font.
- Vimouto: in-game vim like text editor.
- `fsm.textinput()`.
- Supported vim binding: i, I, a, A, o, O, 0, $, x, h, j, k, l, dd, gg, G
- Support cmd mode :q, and :w filename commands.
- Line number.
- `jk` maping to escape in insert mode.
- Message and error message in cmd line.


## [0.0.1] - 2025-11-21

### Added

- Stack-based singleton FSM.
- Button and Menu class.
- 2 characters: Ichinose Kotomi and Kanbe Kotori.
- Pattern pngs.
- Audio for home screen.
- Ep1: Hajimari.
- Dialogue class.
- Typing effect in dialogue box.
- Pressing q to quit episode.
- `fsm.keypressed()`.
- `home.stopAudio()` and `home.playAudio()` to be used in fsm.
- `fsm.push()` stops current state audio before changing state.
- `fsm.pop()` plays the current state audio after changing state.
- `Dialogue:reset()`.
- New character: Kasugano Sora.
- New audio: clannad-track-6.mp3.
- Ep2: Nii-san new hobby.
- More tiled patterns.
- Pattern viewer.
- util.lua.
- Option for right aligned menu UI.
- Stories and Areas sub menu in home screen.
- Hide apply button if pattern viewer opened from home.
- Reset the necessary global variables when exiting pattern state.
- Pause audio when pushing state and resume when popping state.
- Radio UI.
- Audio class: wrapper for love audio.
- Warn if audio doesn''t exits.
- README.md
