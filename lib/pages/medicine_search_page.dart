import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/medicine_result.dart';
import 'medicine_detail_page.dart';

class MedicineSearchPage extends StatefulWidget {
  const MedicineSearchPage({super.key});

  @override
  State<MedicineSearchPage> createState() => _MedicineSearchPageState();
}

class _MedicineSearchPageState extends State<MedicineSearchPage> {
  final TextEditingController _queryController = TextEditingController();

  bool _isLoading = false;
  bool _isCsvLoaded = false;
  int _loadedCount = 0;
  String? _error;

  List<MedicineResult> _allMedicines = [];
  List<MedicineResult> _results = [];

  // 🔤 Alfabetik filtre için
  final List<String> _letters = const [
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H',
    'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P',
    'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z',
  ];
  String? _selectedLetter; // null = hepsi

  @override
  void initState() {
    super.initState();
    _loadMedicinesFromCsv();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicinesFromCsv() async {
    try {
      final raw = await rootBundle.loadString('assets/medicines.csv');

      // Önce ; ile dene, tek kolon çıkarsa , ile tekrar dene
      List<List<dynamic>> rows = const CsvToListConverter(
        fieldDelimiter: ';',
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(raw);

      if (rows.isEmpty || rows.first.length == 1) {
        rows = const CsvToListConverter(
          fieldDelimiter: ',',
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(raw);
      }

      if (rows.isEmpty) return;

      final header = rows.first.map((e) => e.toString().trim()).toList();

      int idxLetter = header.indexOf('Letter');
      int idxDrugName = header.indexOf('Drug Name');
      int idxPrice = header.indexOf('Price');
      int idxPrescReq =
          header.indexOf('Prescription Required (hkt-küb)');
      int idxProsp = header.indexOf('Prosp');
      int idxActive = header.indexOf('Active Ingredient');
      int idxAtc = header.indexOf('ATC Code');
      int idxPrescStatus = header.indexOf('Prescription Status');
      int idxCompany = header.indexOf('Pharmaceutical Company');
      int idxBarcode = header.indexOf('Barcode');
      int idxLastUpdate = header.indexOf('Last Update Date');
      int idxDetailUrl = header.indexOf('Detail URL');
      int idxHowToUse = header.indexOf('Nasıl Kullanılmalı?');
      int idxIndications =
          header.indexOf('Hangi Hastalıklar İçin Kullanılır?');
      
      // Citation source URLs (open source only)
      int idxSourceActiveIngredient = header.indexOf('Source URL - Active Ingredient');
      int idxSourceAtcCode = header.indexOf('Source URL - ATC Code');
      int idxSourceCompany = header.indexOf('Source URL - Company');
      int idxSourceUsageInfo = header.indexOf('Source URL - Usage Info');
      int idxSourceDrugInfo = header.indexOf('Source URL - Drug Info');

      String getField(List<dynamic> row, int idx) {
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].toString();
      }

      final List<MedicineResult> meds = [];
      for (final row in rows.skip(1)) {
        if (row.isEmpty) continue;

        final drugName = getField(row, idxDrugName).trim();
        if (drugName.isEmpty) continue;

        final activeIngredient = getField(row, idxActive).trim();
        final company = getField(row, idxCompany).trim();
        final barcode = getField(row, idxBarcode).trim();
        final price = getField(row, idxPrice).trim();
        final prescReq = getField(row, idxPrescReq).trim();
        final prescStatus = getField(row, idxPrescStatus).trim();
        final atc = getField(row, idxAtc).trim();
        final lastUpdate = getField(row, idxLastUpdate).trim();
        final detailUrl = getField(row, idxDetailUrl).trim();
        final howToUse = getField(row, idxHowToUse).trim();
        final indications = getField(row, idxIndications).trim();
        final letter = getField(row, idxLetter).trim();
        final prosp = getField(row, idxProsp).trim();
        
        // Citation source URLs
        final sourceUrlActiveIngredient = getField(row, idxSourceActiveIngredient).trim();
        final sourceUrlAtcCode = getField(row, idxSourceAtcCode).trim();
        final sourceUrlCompany = getField(row, idxSourceCompany).trim();
        final sourceUrlUsageInfo = getField(row, idxSourceUsageInfo).trim();
        final sourceUrlDrugInfo = getField(row, idxSourceDrugInfo).trim();

        meds.add(
          MedicineResult(
            name: drugName,
            activeIngredient: activeIngredient,
            company: company,
            price: price.isEmpty ? null : price,
            barcode: barcode.isEmpty ? null : barcode,
            prescriptionRequired:
                prescReq.isEmpty ? null : prescReq,
            prescriptionStatus:
                prescStatus.isEmpty ? null : prescStatus,
            atcCode: atc.isEmpty ? null : atc,
            lastUpdate: lastUpdate.isEmpty ? null : lastUpdate,
            detailUrl: detailUrl.isEmpty ? null : detailUrl,
            howToUse: howToUse.isEmpty ? null : howToUse,
            indications: indications.isEmpty ? null : indications,
            letter: letter.isEmpty ? null : letter,
            prosp: prosp.isEmpty ? null : prosp,
            sourceUrlActiveIngredient: sourceUrlActiveIngredient.isEmpty ? null : sourceUrlActiveIngredient,
            sourceUrlAtcCode: sourceUrlAtcCode.isEmpty ? null : sourceUrlAtcCode,
            sourceUrlCompany: sourceUrlCompany.isEmpty ? null : sourceUrlCompany,
            sourceUrlUsageInfo: sourceUrlUsageInfo.isEmpty ? null : sourceUrlUsageInfo,
            sourceUrlDrugInfo: sourceUrlDrugInfo.isEmpty ? null : sourceUrlDrugInfo,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _allMedicines = meds;
        _isCsvLoaded = true;
        _loadedCount = meds.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'İlaç verileri yüklenirken hata oluştu: $e';
      });
    }
  }

  // Arama algoritması (önce isim başı, sonra isim içi, sonra diğer alanlar)
  List<MedicineResult> _searchMedicines(String query) {
    final lower = query.toLowerCase();

    final List<MedicineResult> startsWith = [];
    final List<MedicineResult> inName = [];
    final List<MedicineResult> others = [];

    for (final m in _allMedicines) {
      final name = m.name.toLowerCase();
      final active = m.activeIngredient.toLowerCase();
      final company = m.company.toLowerCase();
      final barcode = (m.barcode ?? '').toLowerCase();

      if (name.startsWith(lower)) {
        startsWith.add(m);
      } else if (name.contains(lower)) {
        inName.add(m);
      } else if (active.contains(lower) ||
          company.contains(lower) ||
          barcode.contains(lower)) {
        others.add(m);
      }
    }

    return [...startsWith, ...inName, ...others];
  }

  /// Hem arama metni hem harf filtresini birlikte uygulayan tek yer
  void _updateResults({bool fromSearchButton = false}) {
    if (!_isCsvLoaded) return;

    final query = _queryController.text.trim();
    List<MedicineResult> base = [];

    // 1) Metne göre sonuç
    if (query.isEmpty) {
      // Sorgu yok → sadece harfe göre liste
      if (_selectedLetter != null) {
        base = List<MedicineResult>.from(_allMedicines);
      } else {
        base = [];
      }
    } else {
      // Live search için 3 harf altı threshold
      if (!fromSearchButton && query.length < 3) {
        // Butona basmadıysa ve 3 harften azsa arama yapma
        if (_selectedLetter != null) {
          base = List<MedicineResult>.from(_allMedicines);
        } else {
          base = [];
        }
      } else {
        base = _searchMedicines(query);
      }
    }

    // 2) Harf filtresini uygula
    if (_selectedLetter != null) {
      final letterUpper = _selectedLetter!;
      base = base.where((m) {
        final sourceLetter = (m.letter != null && m.letter!.isNotEmpty)
            ? m.letter!
            : m.name.substring(0, 1);
        return sourceLetter.toUpperCase() == letterUpper;
      }).toList();
    }

    setState(() {
      _results = base;
      _isLoading = false;
    });
  }

  Future<void> _onSearchPressed() async {
    final query = _queryController.text.trim();
    if (query.isEmpty && _selectedLetter == null) {
      _showSnackBar('En az bir arama kelimesi ya da harf seçmelisin.');
      return;
    }
    if (!_isCsvLoaded) {
      _showSnackBar('İlaç verileri henüz yüklenmedi, birazdan tekrar dene.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    _updateResults(fromSearchButton: true);
  }

  void _onQueryChanged(String value) {
    if (!_isCsvLoaded) return;
    _updateResults(fromSearchButton: false);
  }

  void _onLetterTapped(String letter) {
    if (!_isCsvLoaded) return;
    setState(() {
      if (_selectedLetter == letter) {
        _selectedLetter = null; // toggle off
      } else {
        _selectedLetter = letter;
      }
    });
    _updateResults(fromSearchButton: false);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlaç Sorgulama'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ÜST ARAMA BLOĞU
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _queryController,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _onSearchPressed(),
                    decoration: const InputDecoration(
                      labelText: 'İlaç adı / etken madde / barkod',
                      hintText: 'Örn: PAROL, NUROFEN, PARASETAMOL...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _onSearchPressed,
                      icon: const Icon(Icons.search),
                      label: const Text('İlaç Bilgisini Getir'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!_isCsvLoaded)
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'İlaç veritabanı yükleniyor (offline CSV)...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Offline ilaç verisi: $_loadedCount kayıt yüklendi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Canlı arama 3 harften sonra devreye giriyor. Aşağıdan harf seçerek listeyi filtreleyebilirsin.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🔤 ALFABETİK ŞERİT
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _letters.map((letter) {
                        final isSelected = _selectedLetter == letter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(letter),
                            selected: isSelected,
                            onSelected: (_) => _onLetterTapped(letter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _ErrorBanner(message: _error!),
              ),

            // SONUÇ LİSTESİ
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              _selectedLetter == null &&
                                      _queryController.text.trim().isEmpty
                                  ? 'İlaç ismi, etkin madde, firma veya barkod ile\n'
                                    'offline veritabanından arama yapabilirsin.\n\n'
                                    'Ya da üstteki harflerden birini seçerek\n'
                                    'o harfle başlayan ilaçları listeleyebilirsin.'
                                  : 'Filtrelerine uygun ilaç bulunamadı.\n'
                                    'Arama metnini veya harf seçimini değiştirmeyi deneyebilirsin.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final med = _results[index];
                            return _MedicineCard(
                              med: med,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MedicineDetailPage(medicine: med),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// LİSTEDEKİ KISA KART
class _MedicineCard extends StatelessWidget {
  final MedicineResult med;
  final VoidCallback onTap;

  const _MedicineCard({
    required this.med,
    required this.onTap,
  });

  Color _statusColor() {
    final status = (med.prescriptionStatus ?? med.prescriptionRequired ?? '')
        .toLowerCase();
    if (status.contains('reçetesiz') || status.contains('otc')) {
      return Colors.green;
    }
    if (status.contains('reçeteli') || status.contains('kırmızı')) {
      return Colors.red;
    }
    return Colors.blueGrey;
  }

  String _statusText() {
    if (med.prescriptionStatus != null &&
        med.prescriptionStatus!.isNotEmpty) {
      return med.prescriptionStatus!;
    }
    if (med.prescriptionRequired != null &&
        med.prescriptionRequired!.isNotEmpty) {
      return med.prescriptionRequired!;
    }
    return 'Reçete bilgisi yok';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor();
    final statusText = _statusText();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 32,
                color: theme.colorScheme.primary.withOpacity(0.9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1) İlaç adı
                    Text(
                      med.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 2) Reçete chip'i (ALT SATIRDA)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: statusColor.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 3) Etken madde + firma
                    Text(
                      [
                        if (med.activeIngredient.isNotEmpty)
                          'Etken madde: ${med.activeIngredient}',
                        if (med.company.isNotEmpty) 'Firma: ${med.company}',
                      ].join('  •  '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 4) Fiyat / Barkod chip'leri
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (med.price != null && med.price!.isNotEmpty)
                          Chip(
                            label: Text(
                              'Fiyat: ${med.price}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (med.barcode != null && med.barcode!.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.qr_code_2, size: 14),
                            label: Text(
                              med.barcode!,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // 5) "Detayı gör" CTA
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Detayı gör',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
