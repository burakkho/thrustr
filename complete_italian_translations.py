#!/usr/bin/env python3
"""
Complete Italian Localization Script for Thrustr Fitness App
Translates Turkish fitness app strings to Italian with proper terminology
"""

import re
import os
from typing import Dict, Set

class FitnessTranslator:
    def __init__(self):
        # Comprehensive fitness terminology mapping Turkish -> Italian
        self.fitness_terms = {
            # Core Fitness Terms
            "antrenman": "allenamento",
            "egzersiz": "esercizio", 
            "hareket": "movimento",
            "tekrar": "ripetizione",
            "set": "serie",
            "ağırlık": "peso",
            "kilo": "kg",
            "gram": "grammi",
            "kalori": "calorie",
            "protein": "proteine",
            "karbonhidrat": "carboidrati",
            "yağ": "grassi",
            "makro": "macro",
            "besin": "nutriente",
            "yemek": "pasto",
            
            # Body & Health Terms
            "vücut": "corpo",
            "kas": "muscolo",
            "kitle": "massa",
            "indeks": "indice",
            "ölçüm": "misurazione",
            "boy": "altezza",
            "kilo": "peso",
            "yağ": "grasso",
            "sağlık": "salute",
            "fitness": "fitness",
            "kondisyon": "condizione",
            
            # Workout Types
            "kardio": "cardio",
            "koşu": "corsa",
            "yürüyüş": "camminata",
            "bisiklet": "ciclismo",
            "yüzme": "nuoto",
            "crossfit": "crossfit",
            "yoga": "yoga",
            "pilates": "pilates",
            "squat": "squat",
            "bench": "panca",
            "deadlift": "stacco",
            
            # Time & Duration
            "süre": "durata",
            "zaman": "tempo",
            "dakika": "minuto",
            "saniye": "secondo",
            "saat": "ora",
            "gün": "giorno",
            "hafta": "settimana",
            "ay": "mese",
            "yıl": "anno",
            
            # Progress & Goals
            "hedef": "obiettivo",
            "amaç": "scopo",
            "ilerleme": "progresso",
            "gelişme": "sviluppo",
            "başarı": "successo",
            "sonuç": "risultato",
            "performans": "prestazione",
            "rekor": "record",
            
            # Equipment & Tools
            "ekipman": "attrezzatura",
            "alet": "attrezzo",
            "dumbbell": "manubrio",
            "barbell": "bilanciere",
            "kettlebell": "kettlebell",
            "makine": "macchina",
            "treadmill": "tapis roulant",
            "eliptik": "ellittica",
            
            # Actions & Verbs
            "başla": "inizia",
            "bitir": "termina",
            "kaydet": "salva",
            "sil": "elimina",
            "düzenle": "modifica",
            "ekle": "aggiungi",
            "çıkar": "rimuovi",
            "değiştir": "cambia",
            "seç": "seleziona",
            "ara": "cerca",
            
            # Common UI Terms
            "ana sayfa": "dashboard",
            "profil": "profilo",
            "ayarlar": "impostazioni",
            "geçmiş": "cronologia",
            "analiz": "analisi",
            "rapor": "report",
            "grafik": "grafico",
            "liste": "lista",
            "detay": "dettaglio",
            "özet": "riepilogo",
            
            # Measurements & Units
            "metre": "metro",
            "santimetre": "centimetro",
            "milimetre": "millimetro",
            "kilometre": "chilometro",
            "litre": "litro",
            "mililitre": "millilitro",
            "derece": "grado",
            "yüzde": "percentuale",
            
            # Food & Nutrition
            "beslenme": "nutrizione",
            "diyet": "dieta",
            "öğün": "pasto",
            "kahvaltı": "colazione",
            "öğle yemeği": "pranzo",
            "akşam yemeği": "cena",
            "atıştırmalık": "spuntino",
            "su": "acqua",
            "vitamin": "vitamina",
            "mineral": "minerale",
            "lif": "fibra",
            
            # Body Parts
            "bacak": "gamba",
            "kol": "braccio",
            "göğüs": "petto",
            "sırt": "schiena",
            "karın": "addome",
            "omuz": "spalla",
            "kalça": "anca",
            "diz": "ginocchio",
            "ayak": "piede",
            "el": "mano",
        }
        
        # Common Turkish-Italian phrase patterns
        self.phrase_patterns = {
            # Questions
            r"(.+) mi\?": r"\1?",
            r"(.+) mu\?": r"\1?",
            r"(.+) mı\?": r"\1?",
            r"(.+) mü\?": r"\1?",
            
            # Possessives
            r"(.+)nız": r"il tuo \1",
            r"(.+)niz": r"il tuo \1",
            r"(.+)ınız": r"il tuo \1",
            r"(.+)iniz": r"il tuo \1",
            
            # Plurals (basic pattern)
            r"(.+)lar": r"\1i",
            r"(.+)ler": r"\1i",
        }

    def translate_turkish_to_italian(self, turkish_text: str) -> str:
        """
        Translate Turkish text to Italian using fitness-specific terminology
        """
        text = turkish_text.lower().strip()
        
        # Direct fitness term translations
        for turkish_term, italian_term in self.fitness_terms.items():
            # Word boundary matching to avoid partial matches
            pattern = r'\b' + re.escape(turkish_term) + r'\b'
            text = re.sub(pattern, italian_term, text, flags=re.IGNORECASE)
        
        # Handle common Turkish grammatical patterns
        for pattern, replacement in self.phrase_patterns.items():
            text = re.sub(pattern, replacement, text)
        
        # Capitalize first letter and handle proper capitalization
        if text:
            text = text[0].upper() + text[1:]
        
        # Handle common UI patterns
        text = self._handle_ui_patterns(text)
        
        return text
    
    def _handle_ui_patterns(self, text: str) -> str:
        """Handle common UI text patterns"""
        # Navigation and buttons
        ui_translations = {
            "tamam": "OK",
            "iptal": "Annulla", 
            "kaydet": "Salva",
            "düzenle": "Modifica",
            "bitti": "Fatto",
            "geri": "Indietro",
            "tekrar dene": "Riprova",
            "bitir": "Termina",
            "ekle": "Aggiungi",
            "değiştir": "Cambia",
            "devam et": "Continua",
            "başlat": "Inizia",
            "durdur": "Pausa",
            "sıfırla": "Reset",
            "sil": "Elimina",
            "paylaş": "Condividi",
            "kopyala": "Copia",
            "yapıştır": "Incolla",
            "aç": "Apri",
            "kapat": "Chiudi",
            "minimize": "Minimizza",
            "maksimize": "Massimizza",
        }
        
        for turkish, italian in ui_translations.items():
            text = re.sub(r'\b' + re.escape(turkish) + r'\b', italian, text, flags=re.IGNORECASE)
        
        return text

    def parse_strings_file(self, file_path: str) -> Dict[str, str]:
        """Parse iOS .strings file and return key-value dictionary"""
        strings_dict = {}
        
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Regex to match iOS .strings format: "key" = "value";
            pattern = r'^"([^"]+)"\s*=\s*"([^"]*)";\s*$'
            
            for line in content.split('\n'):
                line = line.strip()
                if line and not line.startswith('//') and not line.startswith('/*'):
                    match = re.match(pattern, line)
                    if match:
                        key, value = match.groups()
                        strings_dict[key] = value
                        
        except FileNotFoundError:
            print(f"Warning: File {file_path} not found")
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            
        return strings_dict
    
    def generate_complete_italian_file(self, turkish_file: str, italian_file: str, output_file: str):
        """Generate complete Italian localization file"""
        
        print("Reading Turkish reference file...")
        turkish_strings = self.parse_strings_file(turkish_file)
        print(f"Found {len(turkish_strings)} Turkish keys")
        
        print("Reading existing Italian file...")
        italian_strings = self.parse_strings_file(italian_file)
        print(f"Found {len(italian_strings)} existing Italian keys")
        
        # Create comprehensive Italian translations
        complete_italian = {}
        
        # Start with existing Italian translations
        complete_italian.update(italian_strings)
        
        # Translate missing keys from Turkish
        missing_count = 0
        for key, turkish_value in turkish_strings.items():
            if key not in complete_italian:
                # Translate Turkish to Italian
                italian_translation = self.translate_turkish_to_italian(turkish_value)
                complete_italian[key] = italian_translation
                missing_count += 1
            
        print(f"Translated {missing_count} missing keys from Turkish")
        
        # Write complete Italian file
        self._write_strings_file(complete_italian, output_file)
        print(f"Complete Italian localization written to: {output_file}")
        print(f"Total keys: {len(complete_italian)}")
        
        return complete_italian
    
    def _write_strings_file(self, strings_dict: Dict[str, str], output_file: str):
        """Write dictionary to iOS .strings file format"""
        
        # Group keys by category for better organization
        categorized_keys = self._categorize_keys(strings_dict)
        
        with open(output_file, 'w', encoding='utf-8') as file:
            # Write header
            file.write('/*\n')
            file.write('   Localizable.strings (Italian)\n')
            file.write('   Thrustr - Complete Italian Localization\n')
            file.write('   Generated by Claude Code\n')
            file.write('*/\n\n')
            
            # Write categorized sections
            for category, keys in categorized_keys.items():
                if keys:
                    file.write(f'// MARK: - {category}\n')
                    
                    for key in sorted(keys):
                        value = strings_dict[key]
                        # Escape quotes in values
                        escaped_value = value.replace('"', '\\"')
                        file.write(f'"{key}" = "{escaped_value}";\n')
                    
                    file.write('\n')
    
    def _categorize_keys(self, strings_dict: Dict[str, str]) -> Dict[str, list]:
        """Categorize keys by their prefixes for organized output"""
        categories = {
            'Common Actions': [],
            'Navigation': [],
            'Tab Bar': [],
            'Dashboard': [],
            'Training': [],
            'Nutrition': [],
            'Profile': [],
            'Analytics': [],
            'Settings': [],
            'Errors': [],
            'Onboarding': [],
            'Calculators': [],
            'Body Measurements': [],
            'Food & Meals': [],
            'Workouts': [],
            'Health': [],
            'Achievements': [],
            'Miscellaneous': []
        }
        
        for key in strings_dict.keys():
            categorized = False
            
            # Categorize based on key prefixes
            if key.startswith('common.'):
                categories['Common Actions'].append(key)
                categorized = True
            elif key.startswith('navigation.'):
                categories['Navigation'].append(key)
                categorized = True
            elif key.startswith('tab.'):
                categories['Tab Bar'].append(key)
                categorized = True
            elif key.startswith('dashboard.'):
                categories['Dashboard'].append(key)
                categorized = True
            elif key.startswith('training.'):
                categories['Training'].append(key)
                categorized = True
            elif key.startswith('nutrition.'):
                categories['Nutrition'].append(key)
                categorized = True
            elif key.startswith('profile.'):
                categories['Profile'].append(key)
                categorized = True
            elif key.startswith('analytics.'):
                categories['Analytics'].append(key)
                categorized = True
            elif key.startswith('settings.'):
                categories['Settings'].append(key)
                categorized = True
            elif key.startswith('error.'):
                categories['Errors'].append(key)
                categorized = True
            elif key.startswith('onboarding.'):
                categories['Onboarding'].append(key)
                categorized = True
            elif key.startswith('calculator.'):
                categories['Calculators'].append(key)
                categorized = True
            elif key.startswith('body.') or 'measurement' in key:
                categories['Body Measurements'].append(key)
                categorized = True
            elif key.startswith('food.') or key.startswith('meal.'):
                categories['Food & Meals'].append(key)
                categorized = True
            elif key.startswith('workout.') or key.startswith('exercise.'):
                categories['Workouts'].append(key)
                categorized = True
            elif key.startswith('health.'):
                categories['Health'].append(key)
                categorized = True
            elif key.startswith('achievement.'):
                categories['Achievements'].append(key)
                categorized = True
            
            if not categorized:
                categories['Miscellaneous'].append(key)
        
        return categories


def main():
    """Main execution function"""
    
    # File paths
    turkish_file = '/Users/burakmacbookmini/Documents/Cursor Projects/Apps/thrustr/Resources/tr.lproj/Localizable.strings'
    italian_file = '/Users/burakmacbookmini/Documents/Cursor Projects/Apps/thrustr/Resources/it.lproj/Localizable.strings'
    output_file = '/Users/burakmacbookmini/Documents/Cursor Projects/Apps/thrustr/Resources/it.lproj/Localizable_Complete.strings'
    
    # Verify files exist
    if not os.path.exists(turkish_file):
        print(f"Error: Turkish file not found: {turkish_file}")
        return
    
    if not os.path.exists(italian_file):
        print(f"Warning: Italian file not found: {italian_file}")
        print("Will create from Turkish only")
    
    # Create translator and generate complete file
    translator = FitnessTranslator()
    
    print("Starting Italian localization completion...")
    print("=" * 50)
    
    complete_italian = translator.generate_complete_italian_file(
        turkish_file, 
        italian_file, 
        output_file
    )
    
    print("=" * 50)
    print("Italian localization completed successfully!")
    print(f"Output file: {output_file}")
    
    # Show some sample translations
    print("\nSample translations:")
    print("-" * 20)
    sample_keys = list(complete_italian.keys())[:10]
    for key in sample_keys:
        print(f"{key}: {complete_italian[key]}")


if __name__ == "__main__":
    main()