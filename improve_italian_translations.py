#!/usr/bin/env python3
"""
Migliora le traduzioni italiane - Fix per frasi miste inglese-italiano
Corregge problemi come 'Inizia your first' → 'Inizia il tuo primo'
"""

import re
import os

def get_improved_translations():
    """Traduzioni migliorate per frasi complete"""
    return {
        # Mixed phrases that need complete replacement
        r'"onboarding\.welcome\.subtitle" = "We\'re with you on your fitness journey\.\nLet\'s Inizia!";': 
        '"onboarding.welcome.subtitle" = "Siamo con te nel tuo percorso fitness.\nInitiamo!";',
        
        r'"onboarding\.welcome\.start" = "Let\'s Inizia!";':
        '"onboarding.welcome.start" = "Iniziamo!";',
        
        r'"onboarding\.personalInfo\.title" = "Personal Informazione";':
        '"onboarding.personalInfo.title" = "Informazioni Personali";',
        
        r'"onboarding\.personalInfo\.subtitle" = "Let\'s get to know you better";':
        '"onboarding.personalInfo.subtitle" = "Conosciamoci meglio";',
        
        r'"onboarding\.measurements\.skip" = "Salta This Step";':
        '"onboarding.measurements.skip" = "Salta Questo Passaggio";',
        
        r'"onboarding\.measurements\.skipStep" = "Salta This Step";':
        '"onboarding.measurements.skipStep" = "Salta Questo Passaggio";',
        
        r'"onboarding\.summary\.startApp" = "Inizia App";':
        '"onboarding.summary.startApp" = "Inizia App";',
        
        r'"dashboard\.welcome" = "Hello, %@!";':
        '"dashboard.welcome" = "Ciao, %@!";',
        
        r'"dashboard\.howFeeling" = "How are you feeling Oggi\?";':
        '"dashboard.howFeeling" = "Come ti senti oggi?";',
        
        r'"dashboard\.greeting\.goodMorning" = "Good Mattina";':
        '"dashboard.greeting.goodMorning" = "Buongiorno";',
        
        r'"dashboard\.greeting\.goodAfternoon" = "G\'day";':
        '"dashboard.greeting.goodAfternoon" = "Buon Pomeriggio";',
        
        r'"dashboard\.greeting\.goodEvening" = "Good Sera";':
        '"dashboard.greeting.goodEvening" = "Buonasera";',
        
        r'"dashboard\.greeting\.goodNight" = "Good Notte";':
        '"dashboard.greeting.goodNight" = "Buonanotte";',
        
        r'"dashboard\.stats\.today" = "Oggi";':
        '"dashboard.stats.today" = "Oggi";',
        
        r'"dashboard\.actions\.startWorkout\.desc" = "Create a new Allenamento and track your exercises";':
        '"dashboard.actions.startWorkout.desc" = "Crea un nuovo allenamento e traccia i tuoi esercizi";',
        
        r'"dashboard\.actions\.logWeight\.desc" = "Record your current Peso and track Progresso";':
        '"dashboard.actions.logWeight.desc" = "Registra il tuo peso attuale e traccia i progressi";',
        
        r'"dashboard\.actions\.nutrition\.desc" = "Log daily Calorie and macronutrients";':
        '"dashboard.actions.nutrition.desc" = "Registra calorie giornaliere e macronutrienti";',
        
        r'"dashboard\.noWorkouts\.subtitle" = "Tap the button above to Inizia your first Allenamento!";':
        '"dashboard.noWorkouts.subtitle" = "Tocca il pulsante sopra per iniziare il tuo primo allenamento!";',
        
        r'"dashboard\.weightEntry\.title" = "Enter Current Peso";':
        '"dashboard.weightEntry.title" = "Inserisci Peso Attuale";',
        
        r'"dashboard\.healthPermission\.message" = "Allow access to display health data\.";':
        '"dashboard.healthPermission.message" = "Consenti l\'accesso per mostrare i dati sanitari.";',
        
        r'"training\.history\.empty\.subtitle" = "Tap \+ button to Inizia your first Allenamento!";':
        '"training.history.empty.subtitle" = "Tocca il pulsante + per iniziare il tuo primo allenamento!";',
        
        r'"training\.active\.empty\.subtitle" = "Tap \+ button to Inizia a new Allenamento";':
        '"training.active.empty.subtitle" = "Tocca il pulsante + per iniziare un nuovo allenamento";',
        
        r'"training\.new\.subtitle" = "How would you like to Inizia your Allenamento\?";':
        '"training.new.subtitle" = "Come vorresti iniziare il tuo allenamento?";',
        
        r'"empty_state\.no_workouts\.subtitle" = "Inizia your first Allenamento";':
        '"empty_state.no_workouts.subtitle" = "Inizia il tuo primo allenamento";',
        
        r'"empty_state\.no_results\.subtitle" = "Try different search terms";':
        '"empty_state.no_results.subtitle" = "Prova termini di ricerca diversi";',
        
        r'"empty_state\.no_custom_metcon\.subtitle" = "Create your first custom Allenamento";':
        '"empty_state.no_custom_metcon.subtitle" = "Crea il tuo primo allenamento personalizzato";',
        
        r'"empty_state\.no_metcon_found\.subtitle" = "Try different filters";':
        '"empty_state.no_metcon_found.subtitle" = "Prova filtri diversi";',
    }

def improve_translations(file_path):
    """Migliora le traduzioni esistenti"""
    
    # Leggi file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Applica le correzioni
    improvements = get_improved_translations()
    
    for pattern, replacement in improvements.items():
        content = re.sub(pattern, replacement, content)
    
    # Correggi parole miste comuni
    mixed_word_fixes = {
        r'\bInitiamo\b': 'Iniziamo',
        r'\bInitia\b': 'Inizia',
        r'\bContinua\b(?=\s)': 'Continua',
        r'\bSalta\b(?=\s)': 'Salta',
        r'\bAggiungi\b(?=\s)': 'Aggiungi',
        r'\bModifica\b(?=\s)': 'Modifica',
        r'\bElimina\b(?=\s)': 'Elimina',
        r'\bSalva\b(?=\s)': 'Salva',
        r'\bTermina\b(?=\s)': 'Termina',
        r'\bCompleta\b(?=\s)': 'Completa',
        r'\bCompletato\b(?=\s)': 'Completato',
        r'\bProgresso\b(?=\s)': 'Progresso',
        r'\bObiettivo\b(?=\s)': 'Obiettivo',
        r'\bObiettivi\b(?=\s)': 'Obiettivi',
        r'\bAllenamento\b(?=\s)': 'Allenamento',
        r'\bEsercizio\b(?=\s)': 'Esercizio',
        r'\bNutrizione\b(?=\s)': 'Nutrizione',
        r'\bProfilo\b(?=\s)': 'Profilo',
        r'\bImpostazioni\b(?=\s)': 'Impostazioni',
        r'\bCronologia\b(?=\s)': 'Cronologia',
        r'\bAnalisi\b(?=\s)': 'Analisi',
        r'\bInformazione\b(?=\s)': 'Informazioni',
        r'\bRipetizione\b(?=\s)': 'Ripetizione',
        r'\bRipetizioni\b(?=\s)': 'Ripetizioni',
        r'\bPeso\b(?=\s)': 'Peso',
        r'\bCalorie\b(?=\s)': 'Calorie',
        r'\bProteine\b(?=\s)': 'Proteine',
        r'\bCarboidrati\b(?=\s)': 'Carboidrati',
        r'\bGrassi\b(?=\s)': 'Grassi',
        r'\bSerie\b(?=\s)': 'Serie',
        r'\bSettimana\b(?=\s)': 'Settimana',
        r'\bMese\b(?=\s)': 'Mese',
        r'\bAnno\b(?=\s)': 'Anno',
        r'\bOggi\b(?=\s)': 'Oggi',
        r'\bIeri\b(?=\s)': 'Ieri',
        r'\bDomani\b(?=\s)': 'Domani',
        r'\bMattina\b(?=\s)': 'Mattina',
        r'\bPomeriggio\b(?=\s)': 'Pomeriggio',
        r'\bSera\b(?=\s)': 'Sera',
        r'\bNotte\b(?=\s)': 'Notte',
        r'\bSuccesso\b(?=\s)': 'Successo',
        r'\bErrore\b(?=\s)': 'Errore',
        r'\bAvanti\b(?=\s)': 'Avanti',
        r'\bIndietro\b(?=\s)': 'Indietro',
        r'\bPrecedente\b(?=\s)': 'Precedente',
        r'\bFatto\b(?=\s)': 'Fatto',
        r'\bAnnulla\b(?=\s)': 'Annulla',
        r'\bEtà\b(?=\s)': 'Età',
        r'\bAltezza\b(?=\s)': 'Altezza',
        r'\bGenere\b(?=\s)': 'Genere',
        r'\bMaschio\b(?=\s)': 'Maschio',
        r'\bFemmina\b(?=\s)': 'Femmina',
        r'\bVuoto\b(?=\s)': 'Vuoto',
        r'"Nessun dato"(?=\s)': '"Nessun dato"',
        r'\bSollevamento\b(?=\s)': 'Sollevamento',
        r'\bMassa Muscolare\b(?=\s)': 'Massa Muscolare',
        r'\bCardio\b(?=\s)': 'Cardio',
        r'\bProgramma\b(?=\s)': 'Programma',
    }
    
    for pattern, replacement in mixed_word_fixes.items():
        content = re.sub(pattern, replacement, content)
    
    # Scrivi file migliorato
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Traduzioni italiane migliorate!")

def main():
    file_path = "/Users/burakmacbookmini/Documents/Cursor Projects/Apps/thrustr/Resources/it.lproj/Localizable.strings"
    improve_translations(file_path)

if __name__ == "__main__":
    main()