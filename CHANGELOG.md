# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
