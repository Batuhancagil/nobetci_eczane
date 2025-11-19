import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/medicine_result.dart';

class MedicineDetailPage extends StatelessWidget {
  final MedicineResult medicine;

  const MedicineDetailPage({
    super.key,
    required this.medicine,
  });

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDetailUrl() async {
    final url = medicine.detailUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildInfoRow(String label, String? value, {String? sourceUrl, String? sourceName}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value),
          ),
          if (sourceUrl != null && sourceUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: InkWell(
                onTap: () => _openUrl(sourceUrl),
                child: Tooltip(
                  message: sourceName ?? 'Kaynağı görüntüle',
                  child: Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceLink(String label, String? url, String description) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => _openUrl(url),
        child: Row(
          children: [
            Icon(Icons.link, size: 18, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(medicine.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medication_rounded,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              medicine.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Basic Information Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Temel Bilgiler',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Etken madde',
                        medicine.activeIngredient.isEmpty ? null : medicine.activeIngredient,
                        sourceUrl: medicine.sourceUrlActiveIngredient,
                        sourceName: 'PubChem - NIH Açık Kaynak Veritabanı',
                      ),
                      _buildInfoRow(
                        'Firma',
                        medicine.company.isEmpty ? null : medicine.company,
                        sourceUrl: medicine.sourceUrlCompany,
                        sourceName: 'TİTCK - Türkiye İlaç ve Tıbbi Cihaz Kurumu',
                      ),
                      _buildInfoRow('Fiyat', medicine.price),
                      _buildInfoRow('Barkod', medicine.barcode),
                      _buildInfoRow(
                        'Reçete durumu',
                        medicine.prescriptionStatus ?? medicine.prescriptionRequired,
                      ),
                      _buildInfoRow(
                        'ATC Kodu',
                        medicine.atcCode,
                        sourceUrl: medicine.sourceUrlAtcCode,
                        sourceName: 'WHO ATC/DDD - Dünya Sağlık Örgütü',
                      ),
                      _buildInfoRow('Güncelleme Tarihi', medicine.lastUpdate),
                      _buildInfoRow('Harf', medicine.letter),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Usage Information Cards
              if (medicine.howToUse != null && medicine.howToUse!.isNotEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    title: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Nasıl Kullanılır?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (medicine.sourceUrlUsageInfo != null && medicine.sourceUrlUsageInfo!.isNotEmpty)
                          InkWell(
                            onTap: () => _openUrl(medicine.sourceUrlUsageInfo),
                            child: Tooltip(
                              message: 'PubMed Central - Bilimsel Makaleler',
                              child: Icon(
                                Icons.open_in_new,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    children: [
                      Text(
                        medicine.howToUse!,
                        style: const TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                ),

              if (medicine.indications != null && medicine.indications!.isNotEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    title: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Hangi Hastalıklar İçin Kullanılır?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (medicine.sourceUrlUsageInfo != null && medicine.sourceUrlUsageInfo!.isNotEmpty)
                          InkWell(
                            onTap: () => _openUrl(medicine.sourceUrlUsageInfo),
                            child: Tooltip(
                              message: 'PubMed Central - Bilimsel Makaleler',
                              child: Icon(
                                Icons.open_in_new,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    children: [
                      Text(
                        medicine.indications!,
                        style: const TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                ),

              if (medicine.prosp != null && medicine.prosp!.isNotEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    title: const Text(
                      'Prospektüs Bilgisi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    children: [
                      Text(
                        medicine.prosp!,
                        style: const TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Sources Section
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.source, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Kaynaklar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bu bilgiler aşağıdaki açık kaynak ve güvenilir kaynaklardan derlenmiştir:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      _buildSourceLink(
                        'PubChem',
                        medicine.sourceUrlActiveIngredient,
                        'NIH Açık Kaynak Veritabanı - Etken madde bilgileri',
                      ),
                      _buildSourceLink(
                        'WHO ATC/DDD',
                        medicine.sourceUrlAtcCode,
                        'Dünya Sağlık Örgütü - ATC kodu bilgileri',
                      ),
                      _buildSourceLink(
                        'TİTCK',
                        medicine.sourceUrlCompany,
                        'Türkiye İlaç ve Tıbbi Cihaz Kurumu - Resmi ilaç bilgileri',
                      ),
                      _buildSourceLink(
                        'FarmaLOG',
                        medicine.sourceUrlDrugInfo,
                        'Gönüllü Doktor/Eczacı Platformu - İlaç bilgileri',
                      ),
                      _buildSourceLink(
                        'PubMed Central',
                        medicine.sourceUrlUsageInfo,
                        'NIH Açık Erişim - Bilimsel makaleler ve kullanım bilgileri',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Detail URL Button
              if (medicine.detailUrl != null && medicine.detailUrl!.isNotEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _openDetailUrl,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Resmi detay sayfası'),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu bilgiler sadece bilgilendirme amaçlıdır. İlaçları mutlaka doktorunuzun önerdiği şekilde kullanınız.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
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
