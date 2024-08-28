# IBAN Formatter Example

## Description

This project provides an example of a TextInputFormatter for an IBAN input field in Flutter that inserts spaces automatically while managing text selection offsets.

We implemented a custom formatter to demonstrate how to set up a TextField with specific formatting rules.
Therefore, the formatter handles both text formatting and natural text selection offset adjustment.

## How to use the project

### Setting Up the Flutter Project:

#### macOS

- https://docs.flutter.dev/get-started/install/macos/mobile-ios?tab=vscode
- https://docs.flutter.dev/get-started/install/macos/mobile-android?tab=vscode

#### windows

- https://docs.flutter.dev/get-started/install/windows/mobile?tab=vscode

## Structure of the project

This project consists of a single main class that contains the complete example.

## Example

### Creating a Text Field:

First, we create a `TextField`. This field is set with a maximum length of 27 characters representing the default format of a German IBAN (DE12 3456 7890 1234 5678 90). The IBAN itself consists of 22 characters with 5 spaces in between. Additionally, we provide a custom extension of the `TextInputFormatter` class called `IbanFormatter` as the input formatter, which will be explained in detail below.

```dart
TextField(
  maxLines: 1,
  // 22 (IBAN length) + 5 (Space length)
  maxLength: 27,
  inputFormatters: const [
    IbanFormatter(),
  ],
  decoration: InputDecoration(
    labelText: 'IBAN',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  ),
),
```

### The IBAN Formatter:

The `IbanFormatter` extends the `TextInputFormatter` class. On top, we define some static variables for the text length set to 22, the number of spaces set to 5, and the total maximum length as their sum. We then override the `formatEditUpdate` function, which receives the old `TextEditingValue` and the new `TextEditingValue` as parameters. The new value represents the state after a user input change, while the old value represents the state before. Inside the `formatEditUpdate` function, the `formattingIban` method is called, which receives the new value's text as a string and formats it as an IBAN string. The details of how this method works will be described in the next section.

```dart
class IbanFormatter extends TextInputFormatter {
  static const textLength = 22;
  static const spaceLength = 5;
  static const maxLength = textLength + spaceLength;

  const IbanFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newFormattedText = formattingIban(newValue.text);
    final calculatedTextSelection = calculateSelectionOffset(
      oldValue: oldValue,
      newValue: newValue,
      newText: newFormattedText,
      maxFormattedLength: maxLength,
    );

    return newValue.copyWith(
      text: newFormattedText,
      selection: calculatedTextSelection,
    );
  }
}
```

After formatting the IBAN, we use the `copyWith` method to update the `newValue` parameter, by setting the text to the newly formatted text. We also update the selection parameter using a custom `calculateSelectionOffset` function. This function will contain all the logic needed to automatically adjust the offset after changes are made in the text input field. The function will be described in the final section.

### Formatting a String with Spaces:

In this section, we would like to briefly explain how the string is formatted as an IBAN.

```dart
String formattingIban(String input) {
  return input
      .replaceAll(' ', '')
      .toUpperCase()
      .replaceAllMapped(RegExp(r'.{1,4}'), (match) => '${match.group(0)} ')
      .trim();
}
```

First, we clean the string of all spaces, then we convert all letters to uppercase, and then we use a regular expression to find groups of 4 characters and insert a space after each group. Finally, we trim any trailing space at the end.

### Calculate the Selection Offset with Spaces:

Now we reach to the crucial part of this blog: how do we adjust the offset so that, from the user's perspective, the spaces do not affect the cursor position?

```dart
TextSelection? calculateSelectionOffset({
  required TextEditingValue oldValue,
  required TextEditingValue newValue,
  required String newText,
  required int maxFormattedLength,
}) {
  final oldOffset = oldValue.selection.baseOffset;
  final newOffset = newValue.selection.baseOffset;

  // Prevent the "range start is out of text of length" error
  if (newOffset > newText.length || oldOffset > newText.length) {
    return TextSelection.collapsed(
      offset: newText.length,
    );
  }

  // If the old offset equals the length of the old text, it shifts the offset to the end of the new text
  if (oldValue.text.length == oldOffset) {
    return TextSelection.collapsed(
      offset: newText.length,
    );
  }

  final newTextUntilOldOffset = newText.substring(0, oldOffset);
  final newTextUntilNewOffset = newText.substring(0, newOffset);
  final spaceDifference =
      countSpaceDif(newTextUntilNewOffset, newTextUntilOldOffset);
  // Adjust the offset by increasing it based on the difference in spaces
  if (spaceDifference > 0) {
    return TextSelection.collapsed(
      offset: newOffset + spaceDifference,
    );
  }

  // Reduce the selection offset by one if a digit following a space is removed
  if (newOffset != 0 && newValue.text[newOffset - 1] == ' ') {
    return TextSelection.collapsed(
      offset: newOffset - 1,
    );
  }

  // Return null and use default selection behavior
  return null;
}

int countSpaceDif(String newTextUntilNewOffset, String newTextUntilOldOffset) {
  return ' '.allMatches(newTextUntilNewOffset).length -
      ' '.allMatches(newTextUntilOldOffset).length;
}
```

Therefore, we implement the `calculateSelectionOffset` method. The function takes as parameters the old and new `TextEditingValue`, the newly formatted text as a string, and the maximum length as an integer and it returns null or a `TextSelection`. Within the function, we obtain the old and new offsets from the selection and baseOffset of each respective value.

At first, we check if the new offset is greater than the new text length or if the old offset was greater than the new text length. If either condition is true, we set the offset to the end of the new text to avoid an out-of-range error.

```dart
// Prevent the "range start is out of text of length" error
if (newOffset > newText.length || oldOffset > newText.length) {
  return TextSelection.collapsed(
    offset: newText.length,
  );
}
```

Next, we check if the old text length matches the old offset, which indicates that the cursor was at the end of the field. If this was the case, we set the offset to the end of the new text. This behavior is necessary, for example, when copying and pasting a complete IBAN.

```dart
// If the old offset equals the length of the old text, it shifts the offset to the end of the new text
if (oldValue.text.length == oldOffset) {
  return TextSelection.collapsed(
    offset: newText.length,
  );
}
```

Subsequently, we increase the offset by the number of spaces added when inserting a digit or when copying and pasting multiple digits. To do this, we take the substring of the new text from the start to the old offset and from the old offset to the new offset. We calculate the difference in the number of spaces using a helper function. If the difference is greater than 0, meaning spaces have been added, we return the new offset plus the difference.

```dart
  final newTextUntilOldOffset = newText.substring(0, oldOffset);
  final newTextUntilNewOffset = newText.substring(0, newOffset);
  final spaceDifference =
      countSpaceDif(newTextUntilNewOffset, newTextUntilOldOffset);
  // Adjust the offset by increasing it based on the difference in spaces
  if (spaceDifference > 0) {
    return TextSelection.collapsed(
      offset: newOffset + spaceDifference,
    );
  }
```

In case a digit is removed after a space, we need to adjust the new offset by subtracting 1, so the cursor jumps back to the previous group. Therefore, we check if the character in the new text at offset - 1 is a space, and as a safeguard, we also ensure that the new offset is not 0.

```dart
  // Reduce the selection offset by one if a digit following a space is removed
  if (newOffset != 0 && newValue.text[newOffset - 1] == ' ') {
    return TextSelection.collapsed(
      offset: newOffset - 1,
    );
  }
```

Finally, if none of the above conditions are met, we simply return null. This ensures that the default behavior for the offset is applied.

And that's it. By adding the `IbanFormatter` as an `inputFormatter` in the TextField, the formatter is applied with every change in the text field.
