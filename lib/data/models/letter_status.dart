/// Represents the feedback state of a single letter tile after a guess.
enum LetterStatus {
  initial, // not yet guessed
  correct, // green - right letter, right position
  present, // yellow - right letter, wrong position
  absent,  // grey - letter not in the word
}
