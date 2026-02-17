import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final RegExp linkRegex = RegExp(
  r'((https?:\/\/)|(www\.))[^\s]+',
  caseSensitive: false,
);
Widget buildClickableText(String text, bool isMe) {
  final List<InlineSpan> spans = [];

  //  Split the text into parts
  text.splitMapJoin(
    linkRegex,
    onMatch: (Match match) {
      final String url = match.group(0)!;
      final String launchUrlString =
          url.startsWith('www.') ? 'https://$url' : url;
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          recognizer:
              TapGestureRecognizer()
                ..onTap = () async {
                  try {
                    final Uri uri = Uri.parse(launchUrlString);
                    // Directly try to launch. ExternalApplication mode is more reliable.
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint("Could not launch link: $e");
                    // Optionally show a SnackBar to the user
                  }
                },
        ),
      );
      return '';
    },
    onNonMatch: (String nonMatch) {
      spans.add(
        TextSpan(
          text: nonMatch,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      );
      return '';
    },
  );

  return Text.rich(
    TextSpan(children: spans),
    textAlign: isMe ? TextAlign.right : TextAlign.left,
  );
}
