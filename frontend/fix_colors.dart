import 'dart:io';

void main() async {
  final dir = Directory('lib/presentation');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  int modifiedCount = 0;
  for (final file in files) {
    if (file.path.contains('fyne_bottom_nav.dart')) continue;
    String content = await file.readAsString();
    String original = content;

    content = content.replaceAll(r'const Color(0xFF1A1A1A).withValues(alpha: 0.4)', r'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)');
    content = content.replaceAll(r'const Color(0xFF1A1A1A).withValues(alpha: 0.5)', r'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)');
    content = content.replaceAll(r'const Color(0xFF1A1A1A)', r'Theme.of(context).colorScheme.onSurface');

    if (content != original) {
      // Because we might have `const Text(..., style: TextStyle(color: Theme...))` now,
      // it's safer to just let flutter analyze tell us. Usually we didn't use const on Text.
      await file.writeAsString(content);
      print('Modificato: ${file.path}');
      modifiedCount++;
    }
  }
}
