import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const IbanFormatterApp());
}

class IbanFormatterApp extends StatelessWidget {
  const IbanFormatterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('IBAN Formatter'),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  maxLines: 1,
                  // 22 (IBAN length) + 5 (Space length);
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

// String formattingIban(String input) {
//   const groupLength = 4;
//   final buffer = StringBuffer();
//   input = input.replaceAll(' ', '');

//   for (int i = 0; i < input.length; i++) {
//     buffer.write(input[i]);
//     if ((i + 1) % groupLength == 0 && i != input.length - 1) {
//       buffer.write(' ');
//     }
//   }

//   return buffer.toString().toUpperCase();
// }

String formattingIban(String input) {
  return input
      .replaceAll(' ', '')
      .toUpperCase()
      .replaceAllMapped(RegExp(r'.{1,4}'), (match) => '${match.group(0)} ')
      .trim();
}

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
