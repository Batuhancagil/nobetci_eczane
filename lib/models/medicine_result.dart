class MedicineResult {
  final String name; // Drug Name
  final String activeIngredient; // Active Ingredient
  final String company; // Pharmaceutical Company
  final String? price; // Price
  final String? barcode; // Barcode
  final String? prescriptionRequired; // Prescription Required (hkt-küb)
  final String? prescriptionStatus; // Prescription Status
  final String? atcCode; // ATC Code
  final String? lastUpdate; // Last Update Date
  final String? detailUrl; // Detail Page URL
  final String? howToUse; // Nasıl Kullanılmalı?
  final String? indications; // Hangi Hastalıklar İçin Kullanılır?
  final String? letter; // Letter
  final String? prosp; // Prosp
  
  // Citation source URLs (open source only)
  final String? sourceUrlActiveIngredient; // PubChem
  final String? sourceUrlAtcCode; // WHO ATC/DDD
  final String? sourceUrlCompany; // TİTCK
  final String? sourceUrlUsageInfo; // PubMed Central
  final String? sourceUrlDrugInfo; // FarmaLOG

  MedicineResult({
    required this.name,
    required this.activeIngredient,
    required this.company,
    this.price,
    this.barcode,
    this.prescriptionRequired,
    this.prescriptionStatus,
    this.atcCode,
    this.lastUpdate,
    this.detailUrl,
    this.howToUse,
    this.indications,
    this.letter,
    this.prosp,
    this.sourceUrlActiveIngredient,
    this.sourceUrlAtcCode,
    this.sourceUrlCompany,
    this.sourceUrlUsageInfo,
    this.sourceUrlDrugInfo,
  });
}
