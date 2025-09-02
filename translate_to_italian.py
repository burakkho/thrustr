#!/usr/bin/env python3
"""
İtalyanca çeviri scripti - Thrustr iOS fitness app
2,672+ string'i İtalyancaya çevirir
"""

import re
import os

def translate_fitness_terms():
    """Fitness terminolojisi çeviri sözlüğü"""
    return {
        # Basic UI
        "Dashboard": "Dashboard",
        "Training": "Allenamento", 
        "Nutrition": "Nutrizione",
        "Profile": "Profilo",
        "Settings": "Impostazioni",
        "Analytics": "Analisi",
        "History": "Cronologia",
        "Today": "Oggi",
        "Week": "Settimana",
        "Month": "Mese",
        "Year": "Anno",
        
        # Training terms
        "Workout": "Allenamento",
        "Exercise": "Esercizio",
        "Set": "Serie",
        "Sets": "Serie",
        "Rep": "Ripetizione", 
        "Reps": "Ripetizioni",
        "Weight": "Peso",
        "Rest": "Riposo",
        "Lift": "Sollevamento",
        "Cardio": "Cardio",
        "WOD": "WOD",
        "Program": "Programma",
        "Start": "Inizia",
        "Finish": "Termina",
        "Complete": "Completa",
        "Completed": "Completato",
        "Progress": "Progresso",
        "Goal": "Obiettivo",
        "Goals": "Obiettivi",
        
        # Nutrition
        "Meal": "Pasto",
        "Meals": "Pasti",
        "Food": "Cibo",
        "Calories": "Calorie",
        "Protein": "Proteine",
        "Carbs": "Carboidrati",
        "Fat": "Grassi",
        "Fiber": "Fibre",
        "Sugar": "Zuccheri",
        "Sodium": "Sodio",
        
        # Common actions
        "Add": "Aggiungi",
        "Edit": "Modifica", 
        "Delete": "Elimina",
        "Save": "Salva",
        "Cancel": "Annulla",
        "Done": "Fatto",
        "Back": "Indietro",
        "Next": "Avanti",
        "Previous": "Precedente",
        "Retry": "Riprova",
        "Continue": "Continua",
        "Skip": "Salta",
        "Finish": "Termina",
        
        # Time/Date
        "Today": "Oggi",
        "Yesterday": "Ieri", 
        "Tomorrow": "Domani",
        "This Week": "Questa Settimana",
        "Last Week": "Settimana Scorsa",
        "This Month": "Questo Mese",
        "Morning": "Mattina",
        "Afternoon": "Pomeriggio",
        "Evening": "Sera",
        "Night": "Notte",
        
        # Body measurements
        "Height": "Altezza",
        "Weight": "Peso",
        "Age": "Età",
        "Gender": "Genere",
        "Male": "Maschio",
        "Female": "Femmina",
        "Body Fat": "Grasso Corporeo",
        "Muscle Mass": "Massa Muscolare",
        
        # Common phrases
        "Get Started": "Inizia",
        "Let's Go": "Andiamo",
        "Good Job": "Bravo",
        "Well Done": "Ben Fatto",
        "Keep Going": "Continua Così",
        "Almost There": "Ci Siamo Quasi",
        "You did it": "Ce l'hai fatta",
        "Loading": "Caricamento",
        "Please wait": "Attendere prego",
        "No data": "Nessun dato",
        "Empty": "Vuoto",
        "Error": "Errore",
        "Success": "Successo",
        "Warning": "Avviso",
        "Info": "Informazione"
    }

def translate_line(line, translations):
    """Tek satır çevirir"""
    # Eğer key-value pair değilse, olduğu gibi döndür
    if not re.match(r'^"[^"]+"\s*=\s*"[^"]*";', line.strip()):
        return line
    
    # Key ve value'yu ayır
    match = re.match(r'^("[^"]+")\s*=\s*"([^"]*)";', line.strip())
    if not match:
        return line
    
    key = match.group(1)
    value = match.group(2)
    
    # Boş value'lar için
    if not value:
        return line
    
    # Çeviriye başla
    translated_value = value
    
    # Direct translations
    for eng, ita in translations.items():
        translated_value = re.sub(r'\b' + re.escape(eng) + r'\b', ita, translated_value, flags=re.IGNORECASE)
    
    # Format için özel durumlar (%@, %d, etc.)
    # Bu formatlar olduğu gibi kalmalı
    
    return f'{key} = "{translated_value}";'

def main():
    input_file = "/Users/burakmacbookmini/Documents/Cursor Projects/Apps/thrustr/Resources/it.lproj/Localizable.strings"
    
    # Translation dictionary
    translations = translate_fitness_terms()
    
    # Dosyayı oku
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Her satırı çevir
    translated_lines = []
    for line in lines:
        if line.strip().startswith('//') or line.strip() == '':
            # Yorum ve boş satırlar olduğu gibi kalır
            translated_lines.append(line)
        else:
            translated_lines.append(translate_line(line, translations))
    
    # Dosyayı güncelle
    with open(input_file, 'w', encoding='utf-8') as f:
        f.writelines(translated_lines)
    
    print(f"✅ İtalyanca çeviri tamamlandı: {len(lines)} satır işlendi")

if __name__ == "__main__":
    main()