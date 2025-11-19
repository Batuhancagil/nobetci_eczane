#!/usr/bin/env python3
"""
Add citation source URLs to drugs_table_detailed.csv
Uses only open source and reliable sources (no ilacabak.com):
- PubChem (NIH) for active ingredients
- WHO ATC/DDD for ATC codes
- TİTCK for company info
- FarmaLOG for drug info
- PubMed Central for usage info
"""

import csv
import urllib.parse
import re
from pathlib import Path

INPUT_CSV = "drugs_table_detailed.csv"
OUTPUT_CSV = "drugs_table_detailed_with_sources.csv"
BACKUP_CSV = "drugs_table_detailed_backup_before_sources.csv"

def normalize_for_url(text):
    """Normalize text for URL usage"""
    if not text:
        return ""
    # Remove extra whitespace
    text = ' '.join(text.split())
    # URL encode
    return urllib.parse.quote(text, safe='')

def normalize_compound_name(compound_name):
    """Normalize compound name for PubChem URL"""
    if not compound_name:
        return ""
    # Remove common suffixes and clean up
    text = compound_name.lower().strip()
    # Remove "kombinasyon" and similar words
    text = re.sub(r'\s+kombinasyon.*', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s+combination.*', '', text, flags=re.IGNORECASE)
    # Take first part if multiple compounds
    if '+' in text or 've' in text.lower():
        parts = re.split(r'[+\s]+ve\s+', text, flags=re.IGNORECASE)
        text = parts[0].strip()
    # Clean up
    text = text.strip()
    # Replace spaces with dashes for PubChem
    text = re.sub(r'\s+', '-', text)
    # Remove special characters except dashes
    text = re.sub(r'[^a-z0-9\-]', '', text)
    return text

def generate_pubchem_url(active_ingredient):
    """Generate PubChem URL for active ingredient"""
    if not active_ingredient or not active_ingredient.strip():
        return ""
    normalized = normalize_compound_name(active_ingredient)
    if not normalized:
        return ""
    # Try direct compound name first
    return f"https://pubchem.ncbi.nlm.nih.gov/compound/{normalized}"

def generate_who_atc_url(atc_code):
    """Generate WHO ATC/DDD URL for ATC code"""
    if not atc_code or not atc_code.strip():
        return ""
    # Clean ATC code
    code = atc_code.strip().upper()
    if not code:
        return ""
    return f"https://www.whocc.no/atc_ddd_index/?code={code}"

def generate_titck_url(drug_name):
    """Generate TİTCK search URL"""
    if not drug_name or not drug_name.strip():
        return ""
    normalized = normalize_for_url(drug_name)
    if not normalized:
        return ""
    return f"https://www.titck.gov.tr/ilac/arama?q={normalized}"

def generate_farmalog_url(drug_name):
    """Generate FarmaLOG URL"""
    if not drug_name or not drug_name.strip():
        return ""
    # Normalize drug name for FarmaLOG (keep Turkish characters)
    normalized = urllib.parse.quote(drug_name.strip(), safe='')
    if not normalized:
        return ""
    # Try direct drug page first, fallback to search
    return f"https://farmalog.info/arama?q={normalized}"

def generate_pubmed_url(drug_name, active_ingredient):
    """Generate PubMed Central search URL"""
    if not drug_name or not drug_name.strip():
        return ""
    # Combine drug name and active ingredient for search
    search_terms = []
    if drug_name and drug_name.strip():
        search_terms.append(drug_name.strip())
    if active_ingredient and active_ingredient.strip():
        # Take first part of active ingredient if combination
        ai_part = active_ingredient.split()[0] if active_ingredient.split() else active_ingredient
        search_terms.append(ai_part.strip())
    
    if not search_terms:
        return ""
    
    query = '+'.join([urllib.parse.quote(term, safe='') for term in search_terms])
    return f"https://www.ncbi.nlm.nih.gov/pmc/?term={query}"

def add_citation_sources():
    """Add citation source URLs to CSV"""
    if not Path(INPUT_CSV).exists():
        print(f"ERROR: {INPUT_CSV} not found!")
        return
    
    print(f"Reading {INPUT_CSV}...")
    
    # Read existing CSV
    rows = []
    fieldnames = None
    
    with open(INPUT_CSV, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = list(reader.fieldnames)
        
        for row in reader:
            rows.append(row)
    
    print(f"Loaded {len(rows)} drugs")
    
    # Create backup
    print(f"Creating backup: {BACKUP_CSV}...")
    with open(BACKUP_CSV, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print("Backup created")
    
    # Add new source URL columns
    new_columns = [
        'Source URL - Active Ingredient',
        'Source URL - ATC Code',
        'Source URL - Company',
        'Source URL - Usage Info',
        'Source URL - Drug Info'
    ]
    
    # Add columns to fieldnames if not already present
    for col in new_columns:
        if col not in fieldnames:
            fieldnames.append(col)
    
    # Generate source URLs for each row
    print("\nGenerating source URLs...")
    for i, row in enumerate(rows):
        if (i + 1) % 1000 == 0:
            print(f"  Processed {i + 1}/{len(rows)} drugs...")
        
        drug_name = row.get('Drug Name', '').strip()
        active_ingredient = row.get('Active Ingredient', '').strip()
        atc_code = row.get('ATC Code', '').strip()
        company = row.get('Pharmaceutical Company', '').strip()
        
        # Generate URLs
        row['Source URL - Active Ingredient'] = generate_pubchem_url(active_ingredient)
        row['Source URL - ATC Code'] = generate_who_atc_url(atc_code)
        row['Source URL - Company'] = generate_titck_url(drug_name)  # TİTCK has company info
        row['Source URL - Usage Info'] = generate_pubmed_url(drug_name, active_ingredient)
        row['Source URL - Drug Info'] = generate_farmalog_url(drug_name)
    
    # Write updated CSV
    print(f"\nWriting updated CSV: {OUTPUT_CSV}...")
    with open(OUTPUT_CSV, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    print(f"✓ Successfully added citation sources to {OUTPUT_CSV}")
    print(f"\nSummary:")
    print(f"  Total drugs: {len(rows)}")
    
    # Count non-empty URLs
    counts = {col: 0 for col in new_columns}
    for row in rows:
        for col in new_columns:
            if row.get(col, '').strip():
                counts[col] += 1
    
    print(f"\nSource URLs generated:")
    for col in new_columns:
        print(f"  {col}: {counts[col]}/{len(rows)} drugs")

if __name__ == '__main__':
    add_citation_sources()

