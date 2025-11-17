import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/medicine_result.dart';

class MedicineCard extends StatelessWidget {
  final MedicineResult med;
  final VoidCallback? onTap;

  const MedicineCard({
    super.key,
    required this.med,
    this.onTap,
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

  String _shorten(String? text, {int max = 140}) {
    if (text == null || text.trim().isEmpty) return '';
    final t = text.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max).trimRight()}…';
  }

  void _openDetailUrl() async {
    final url = med.detailUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor();
    final statusText = _statusText();
    final hasDetailUrl =
        med.detailUrl != null && med.detailUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır: isim + status chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      med.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Aktif madde + firma
              Text(
                [
                  if (med.activeIngredient.isNotEmpty)
                    'Etkin madde: ${med.activeIngredient}',
                  if (med.company.isNotEmpty) 'Firma: ${med.company}',
                ].join('  •  '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 6),
              // Fiyat, barkod, ATC, güncelleme
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
                  if (med.atcCode != null && med.atcCode!.isNotEmpty)
                    Chip(
                      label: Text(
                        'ATC: ${med.atcCode}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (med.lastUpdate != null &&
                      med.lastUpdate!.isNotEmpty)
                    Chip(
                      label: Text(
                        'Güncelleme: ${med.lastUpdate}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Nasıl kullanılır / hangi hastalıklar
              if ((med.howToUse ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Kullanım: ${_shorten(med.howToUse)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              if ((med.indications ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Endikasyonlar: ${_shorten(med.indications)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              if ((med.prosp ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Prospektüs: ${_shorten(med.prosp)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              if (hasDetailUrl) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openDetailUrl,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Detay sayfasını aç'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
