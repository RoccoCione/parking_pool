class EnvironmentalCalculator {
  // Costanti medie 2026
  static const double priceBenzina = 1.85;
  static const double priceDiesel = 1.75;
  static const double priceGPL = 0.85;
  static const double priceKWh = 0.35; // Costo medio ricarica domestica/pubblica
  
  static const int minutiDefaultCruising = 5;

  static Map<String, double> getImpact({
    required double cilindrata, 
    required String carburante, 
    required int anno,
  }) {
    double litriRisparmiati = 0;
    double kwhRisparmiati = 0;
    double euroRisparmiati = 0;
    double kgCO2 = 0;

    String fuel = carburante.toLowerCase();

    // --- LOGICA PER AUTO ELETTRICHE ---
    if (fuel == 'elettrica' || fuel == 'elettrico') {
      // Un'auto elettrica media nel traffico Stop&Go consuma circa 0.15 kWh al minuto
      kwhRisparmiati = 0.15 * minutiDefaultCruising;
      euroRisparmiati = kwhRisparmiati * priceKWh;
      
      // CO2 risparmiata (considerando il mix energetico: ~0.4kg di CO2 per ogni kWh prodotto)
      kgCO2 = kwhRisparmiati * 0.4;
    } 
    
    // --- LOGICA PER AUTO TERMICHE E IBRIDE ---
    else {
      // 1. Calcolo Consumo Idle Base (Litri/ora)
      double coeffCarburante = (fuel == 'diesel') ? 0.5 : 0.6;
      double consumoIdle = cilindrata * coeffCarburante;

      // 2. Calcolo Consumo Cruising
      double consumoCruising = consumoIdle * 2.5;

      // 3. Applichiamo lo sconto "Ibrido" (se l'auto è ibrida, consuma il 60% in meno a basse velocità)
      if (fuel.contains('ibrida') || fuel.contains('hybrid')) {
        consumoCruising = consumoCruising * 0.4; 
      }

      // 4. Litri risparmiati in 5 minuti
      litriRisparmiati = consumoCruising * (minutiDefaultCruising / 60);

      // 5. Risparmio Economico (€)
      double prezzo = priceBenzina;
      if (fuel == 'diesel') prezzo = priceDiesel;
      if (fuel == 'gpl' || fuel == 'metano') prezzo = priceGPL;
      euroRisparmiati = litriRisparmiati * prezzo;

      // 6. Risparmio CO2 (kg)
      double coeffCO2 = (fuel == 'diesel') ? 2.6 : 2.3;
      double fattoreAnno = (anno < 2006) ? 1.3 : (anno <= 2014) ? 1.1 : 0.9;
      kgCO2 = litriRisparmiati * coeffCO2 * fattoreAnno;
    }

    return {
      'euro': euroRisparmiati,
      'co2': kgCO2,
      'litri': litriRisparmiati,
      'kwh': kwhRisparmiati,
    };
  }
}