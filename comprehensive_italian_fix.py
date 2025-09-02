#!/usr/bin/env python3
"""
Fix completo per traduzioni italiane miste
Sostituisce frasi complete inglese-italiano con traduzioni fluenti
"""

import re

def get_comprehensive_translations():
    """Traduzioni complete per tutte le frasi problematiche"""
    return {
        # Onboarding fixes
        r'"onboarding\.welcome\.title" = "Welcome to\\nThrustr! 💪";': 
        '"onboarding.welcome.title" = "Benvenuto in\\nThrustr! 💪";',
        
        r'"onboarding\.welcome\.subtitle" = "We\'re with you on your fitness journey\.\\nLet\'s Inizia!";': 
        '"onboarding.welcome.subtitle" = "Siamo con te nel tuo percorso fitness.\\nIniziamo!";',
        
        r'"onboarding\.feature\.workout" = "Smart Allenamento tracking";': 
        '"onboarding.feature.workout" = "Tracciamento intelligente allenamenti";',
        
        r'"onboarding\.feature\.progress" = "Progresso analysis";': 
        '"onboarding.feature.progress" = "Analisi dei progressi";',
        
        r'"onboarding\.feature\.nutrition" = "Nutrizione control";': 
        '"onboarding.feature.nutrition" = "Controllo nutrizionale";',
        
        r'"onboarding\.feature\.goals" = "Personal Obiettivi";': 
        '"onboarding.feature.goals" = "Obiettivi personali";',
        
        r'"onboarding\.personalInfo\.name" = "Name";': 
        '"onboarding.personalInfo.name" = "Nome";',
        
        r'"onboarding\.personalInfo\.name\.placeholder" = "e\.g\., John";': 
        '"onboarding.personalInfo.name.placeholder" = "es., Marco";',
        
        r'"onboarding\.personalInfo\.age\.years" = "%d years";': 
        '"onboarding.personalInfo.age.years" = "%d anni";',
        
        r'"onboarding\.consent\.title" = "Consent";': 
        '"onboarding.consent.title" = "Consenso";',
        
        r'"onboarding\.consent\.subtitle" = "Please review and accept the documents to Continua\.";': 
        '"onboarding.consent.subtitle" = "Rivedi e accetta i documenti per continuare.";',
        
        r'"onboarding\.consent\.terms\.title" = "Accept Terms of Service";': 
        '"onboarding.consent.terms.title" = "Accetta Termini di Servizio";',
        
        r'"onboarding\.consent\.terms\.desc" = "You need to accept the Terms of Service to use the app\.";': 
        '"onboarding.consent.terms.desc" = "Devi accettare i Termini di Servizio per usare l\'app.";',
        
        r'"onboarding\.consent\.viewTerms" = "View Terms of Service";': 
        '"onboarding.consent.viewTerms" = "Visualizza Termini di Servizio";',
        
        r'"onboarding\.consent\.privacy\.title" = "Accept Privacy Policy";': 
        '"onboarding.consent.privacy.title" = "Accetta Privacy Policy";',
        
        r'"onboarding\.consent\.privacy\.desc" = "Please review and accept our Privacy Policy\.";': 
        '"onboarding.consent.privacy.desc" = "Rivedi e accetta la nostra Privacy Policy.";',
        
        r'"onboarding\.consent\.viewPrivacy" = "View Privacy Policy";': 
        '"onboarding.consent.viewPrivacy" = "Visualizza Privacy Policy";',
        
        r'"onboarding\.consent\.marketing" = "I want to receive product updates and tips";': 
        '"onboarding.consent.marketing" = "Voglio ricevere aggiornamenti prodotto e consigli";',
        
        # Dashboard fixes
        r'"dashboard\.todayStats" = "Today\'s Stats";': 
        '"dashboard.todayStats" = "Statistiche di Oggi";',
        
        r'"dashboard\.quickActions" = "Quick Actions";': 
        '"dashboard.quickActions" = "Azioni Rapide";',
        
        r'"dashboard\.startWorkout" = "Start Workout";': 
        '"dashboard.startWorkout" = "Inizia Allenamento";',
        
        r'"dashboard\.addMeal" = "Add Meal";': 
        '"dashboard.addMeal" = "Aggiungi Pasto";',
        
        # Training fixes
        r'"training\.newWorkout" = "New Workout";': 
        '"training.newWorkout" = "Nuovo Allenamento";',
        
        r'"training\.history" = "History";': 
        '"training.history" = "Cronologia";',
        
        # Meal translations
        r'"dashboard\.meals\.breakfast" = "Breakfast";': 
        '"dashboard.meals.breakfast" = "Colazione";',
        
        r'"dashboard\.meals\.lunch" = "Lunch";': 
        '"dashboard.meals.lunch" = "Pranzo";',
        
        r'"dashboard\.meals\.dinner" = "Dinner";': 
        '"dashboard.meals.dinner" = "Cena";',
        
        r'"dashboard\.meals\.snack" = "Snack";': 
        '"dashboard.meals.snack" = "Spuntino";',
        
        # Goal translations
        r'"onboarding\.goals\.title" = "Your Obiettivi";': 
        '"onboarding.goals.title" = "I Tuoi Obiettivi";',
        
        r'"onboarding\.goals\.subtitle" = "Which direction are you planning to Progresso\?";': 
        '"onboarding.goals.subtitle" = "In quale direzione pianifichi di progredire?";',
        
        r'"onboarding\.goals\.mainGoal" = "Main Obiettivo";': 
        '"onboarding.goals.mainGoal" = "Obiettivo Principale";',
        
        r'"onboarding\.goals\.activityLevel" = "Activity Level";': 
        '"onboarding.goals.activityLevel" = "Livello di Attività";',
        
        r'"onboarding\.goals\.targetWeight" = "Target Peso \(Optional\)";': 
        '"onboarding.goals.targetWeight" = "Peso Target (Opzionale)";',
        
        r'"onboarding\.goals\.targetWeight\.toggle" = "Serie target Peso";': 
        '"onboarding.goals.targetWeight.toggle" = "Imposta peso target";',
        
        # Goal options
        r'"onboarding\.goals\.cut\.title" = "Grassi Loss";': 
        '"onboarding.goals.cut.title" = "Perdita Grassi";',
        
        r'"onboarding\.goals\.cut\.subtitle" = "Lose Peso and reduce body Grassi";': 
        '"onboarding.goals.cut.subtitle" = "Perdi peso e riduci il grasso corporeo";',
        
        r'"onboarding\.goals\.bulk\.title" = "Muscle Gain";': 
        '"onboarding.goals.bulk.title" = "Guadagno Muscolare";',
        
        r'"onboarding\.goals\.bulk\.subtitle" = "Build Massa Muscolare and get stronger";': 
        '"onboarding.goals.bulk.subtitle" = "Costruisci massa muscolare e diventa più forte";',
        
        r'"onboarding\.goals\.maintain\.title" = "Maintain";': 
        '"onboarding.goals.maintain.title" = "Mantieni";',
        
        r'"onboarding\.goals\.maintain\.subtitle" = "Maintain current Peso while getting stronger";': 
        '"onboarding.goals.maintain.subtitle" = "Mantieni il peso attuale diventando più forte";',
        
        # Activity levels
        r'"onboarding\.activity\.sedentary" = "Sedentary";': 
        '"onboarding.activity.sedentary" = "Sedentario";',
        
        r'"onboarding\.activity\.sedentary\.desc" = "Desk job, little movement";': 
        '"onboarding.activity.sedentary.desc" = "Lavoro da scrivania, poco movimento";',
        
        r'"onboarding\.activity\.light" = "Lightly Active";': 
        '"onboarding.activity.light" = "Leggermente Attivo";',
        
        r'"onboarding\.activity\.light\.desc" = "1-2 workouts per Settimana";': 
        '"onboarding.activity.light.desc" = "1-2 allenamenti a settimana";',
        
        r'"onboarding\.activity\.moderate" = "Moderately Active";': 
        '"onboarding.activity.moderate" = "Moderatamente Attivo";',
        
        r'"onboarding\.activity\.moderate\.desc" = "3-4 workouts per Settimana";': 
        '"onboarding.activity.moderate.desc" = "3-4 allenamenti a settimana";',
        
        r'"onboarding\.activity\.active" = "Active";': 
        '"onboarding.activity.active" = "Attivo";',
        
        r'"onboarding\.activity\.active\.desc" = "5-6 workouts per Settimana";': 
        '"onboarding.activity.active.desc" = "5-6 allenamenti a settimana";',
        
        r'"onboarding\.activity\.veryActive" = "Very Active";': 
        '"onboarding.activity.veryActive" = "Molto Attivo";',
        
        r'"onboarding\.activity\.veryActive\.desc" = "Daily workouts, physical job";': 
        '"onboarding.activity.veryActive.desc" = "Allenamenti quotidiani, lavoro fisico";',
        
        # Common English words that need translation
        r'"onboarding\.progress\.step" = "Step %d/%d";': 
        '"onboarding.progress.step" = "Passaggio %d/%d";',
        
        # Fix remaining English phrases
        r' = "All";': ' = "Tutti";',
        r' = "Clear";': ' = "Pulisci";',
        r' = "Search exercises\.\.\.";': ' = "Cerca esercizi...";',
        r' = "Other";': ' = "Altro";',
        r' = "Total";': ' = "Totale";',
        r' = "Latest";': ' = "Ultimo";',
        r' = "Entries";': ' = "Voci";',
        r' = "None";': ' = "Nessuno";',
        r' = "Optional";': ' = "Opzionale";',
        r' = "Loading";': ' = "Caricamento";',
        r' = "Close";': ' = "Chiudi";',
        r' = "Pause";': ' = "Pausa";',
        r' = "Reset";': ' = "Reimposta";',
        r' = "Custom";': ' = "Personalizzato";',
        r' = "Calculate";': ' = "Calcola";',
        r' = "Results";': ' = "Risultati";',
        r' = "About";': ' = "Informazioni";',
        r' = "Allow";': ' = "Consenti";',
        r' = "Ready";': ' = "Pronto";',
        r' = "Active";': ' = "Attivo";',
        r' = "Paused";': ' = "In Pausa";',
    }

def apply_comprehensive_fixes(file_path):
    """Applica tutte le correzioni"""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    translations = get_comprehensive_translations()
    
    for pattern, replacement in translations.items():
        content = re.sub(pattern, replacement, content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Correzioni complete applicate!")

if __name__ == "__main__":
    file_path = "/Users/burakmacbookmini/Documents/Cursor Projects/Apps/thrustr/Resources/it.lproj/Localizable.strings"
    apply_comprehensive_fixes(file_path)