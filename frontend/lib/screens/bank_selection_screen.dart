import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../providers/budget_provider.dart';

class BankSelectionScreen extends ConsumerStatefulWidget {
  const BankSelectionScreen({super.key});

  @override
  ConsumerState<BankSelectionScreen> createState() => _BankSelectionScreenState();
}

class _BankSelectionScreenState extends ConsumerState<BankSelectionScreen> {
  List<dynamic> _institutions = [];
  List<dynamic> _filteredInstitutions = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInstitutions();
  }

  Future<void> _fetchInstitutions() async {
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/api/banking/institutions', queryParameters: {'country': 'IT'});
      setState(() {
        _institutions = response.data;
        _filteredInstitutions = _institutions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore nel caricamento banche: $e")));
    }
  }

  void _filterInstitutions(String query) {
    setState(() {
      _filteredInstitutions = _institutions
          .where((inst) => inst['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _connectBank(String institutionId) async {
    setState(() { _isLoading = true; });
    try {
      final api = ref.read(apiServiceProvider);
      // In production, the redirectUrl should be a deep link to your app
      // e.g., fyne://callback
      final response = await api.post('/api/banking/connect', data: {
        'institutionId': institutionId,
        'redirectUrl': 'https://banking-abstraction-layer-719543584184.europe-west8.run.app/', // Temporary fallback
      });

      final String authLink = response.data['link'];
      final Uri url = Uri.parse(authLink);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // After launching, the user will be redirected. 
        // We can show a "Waiting for connection" state or just pop.
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Autorizzazione avviata nel browser...")),
          );
        }
      } else {
        throw "Impossibile aprire il link di autorizzazione";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        title: Text("Seleziona la tua Banca", style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _searchController,
              onChanged: _filterInstitutions,
              decoration: InputDecoration(
                hintText: "Cerca banca...",
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A6741)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _filteredInstitutions.length,
                  itemBuilder: (context, index) {
                    final inst = _filteredInstitutions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        leading: inst['logo'] != null 
                          ? Image.network(inst['logo'], width: 32, height: 32)
                          : const Icon(LucideIcons.landmark, color: Color(0xFF4A6741)),
                        title: Text(inst['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text(inst['bic'] ?? "", style: GoogleFonts.inter(fontSize: 12)),
                        trailing: const Icon(LucideIcons.chevronRight, size: 18),
                        onTap: () => _connectBank(inst['id']),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
