import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RecoveryKeyScreen extends StatefulWidget {
  const RecoveryKeyScreen({super.key});

  @override
  State<RecoveryKeyScreen> createState() => _RecoveryKeyScreenState();
}

class _RecoveryKeyScreenState extends State<RecoveryKeyScreen> {
  late String _mnemonic;
  late List<String> _words;

  @override
  void initState() {
    super.initState();
    _mnemonic = bip39.generateMnemonic(strength: 256); // 24 words
    _words = _mnemonic.split(' ');
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          cross: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Fyne - Master Recovery Key', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('CUSTODISCI QUESTA CHIAVE CON LA VITA. È l\'unico modo per recuperare i tuoi dati criptati.'),
            pw.SizedBox(height: 40),
            pw.GridView(
              crossAxisCount: 3,
              children: List.generate(_words.length, (i) => pw.Text('${i + 1}. ${_words[i]}')),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(title: const Text('Recovery Key'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.security, size: 64, color: Colors.cyanAccent),
            const SizedBox(height: 24),
            Text(
              "Questa è la tua Master Key",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              "Nessuno, nemmeno Fyne, può recuperare i tuoi dati senza queste 24 parole. Scrivile o salva il PDF.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _words.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    center: Text(
                      "${index + 1}. ${_words[index]}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Salva come PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
