import 'package:flutter/material.dart';

/// Screen with app info, privacy policy, and legal information
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Informazioni',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // App info card
            _buildSection(
              icon: Icons.wallet,
              title: 'Cards',
              children: [
                _buildInfoTile('Versione', '1.0.0'),
                _buildInfoTile('Build', '2026.01'),
                _buildInfoTile('Sviluppatore', 'Paolo Artasensi'),
              ],
            ),
            const SizedBox(height: 20),
            
            // Privacy section
            _buildSection(
              icon: Icons.privacy_tip,
              title: 'Privacy',
              children: [
                _buildExpandableTile(
                  'Informativa sulla Privacy',
                  '''Cards rispetta la tua privacy. Tutti i dati delle tessere sono salvati localmente sul tuo dispositivo e non vengono mai trasmessi a server esterni.

• I dati delle tessere (nome, codice, categoria) sono memorizzati solo sul dispositivo
• Non raccogliamo dati personali
• Non utilizziamo servizi di tracciamento o analytics
• La funzione di esportazione salva i dati in formato JSON sul tuo dispositivo

Per le tessere volo, l'app può connettersi a servizi esterni per info live (vedi sezione API).''',
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // API & Services section
            _buildSection(
              icon: Icons.cloud,
              title: 'Servizi & API',
              children: [
                _buildExpandableTile(
                  'OpenSky Network',
                  '''Utilizziamo OpenSky Network per il tracking dei voli in tempo reale.

• Servizio: https://opensky-network.org
• Licenza: Gratuito per uso non commerciale
• Dati: Posizione, altitudine, velocità degli aerei
• Privacy: Inviamo solo il numero di volo per cercare i dati

OpenSky Network è una rete collaborativa di ricevitori ADS-B che fornisce dati di volo aperti.''',
                ),
                _buildExpandableTile(
                  'OpenWeatherMap (opzionale)',
                  '''Se configurato, utilizziamo OpenWeatherMap per il meteo a destinazione.

• Servizio: https://openweathermap.org
• Licenza: Gratuito fino a 1000 richieste/giorno
• Dati: Temperatura, condizioni meteo
• Privacy: Inviamo solo il codice aeroporto (es. FCO, JFK)

Richiede API key configurata dall'utente.''',
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Terms section
            _buildSection(
              icon: Icons.description,
              title: 'Termini di Utilizzo',
              children: [
                _buildExpandableTile(
                  'Condizioni d\'uso',
                  '''Utilizzando Cards, accetti i seguenti termini:

1. L'app è fornita "così com'è" senza garanzie di alcun tipo
2. L'utente è responsabile del backup dei propri dati
3. Non siamo responsabili per perdita di dati o malfunzionamenti
4. L'app è destinata esclusivamente all'uso personale''',
                ),
                _buildExpandableTile(
                  'Esclusione di Responsabilità',
                  '''Cards è un'applicazione per la gestione personale delle tessere fedeltà. Non siamo affiliati con nessuno dei negozi o brand le cui tessere possono essere salvate nell'app.

L'app non garantisce la validità o l'accettazione dei codici a barre generati presso i punti vendita.''',
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Data management section
            _buildSection(
              icon: Icons.storage,
              title: 'Gestione Dati',
              children: [
                _buildExpandableTile(
                  'Dove sono salvati i miei dati?',
                  '''Tutti i dati delle tue tessere sono salvati localmente sul tuo dispositivo utilizzando Hive, un database locale sicuro e veloce.

I dati non vengono mai sincronizzati con server cloud a meno che tu non esporti manualmente il file JSON e lo condivida.''',
                ),
                _buildExpandableTile(
                  'Come posso eliminare i miei dati?',
                  '''Puoi eliminare singole tessere tenendo premuto sulla card e confermando l'eliminazione.

Per eliminare tutti i dati, puoi disinstallare l'app dal tuo dispositivo.''',
                ),
                _buildExpandableTile(
                  'Backup e Ripristino',
                  '''Puoi esportare tutte le tue tessere in un file JSON dalla schermata principale (menu ⋯ > Esporta tessere).

Per ripristinare le tessere, usa la funzione Importa tessere e seleziona il file JSON precedentemente salvato.''',
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Credits section
            _buildSection(
              icon: Icons.favorite,
              title: 'Crediti & Licenze',
              children: [
                _buildExpandableTile(
                  'Tecnologie utilizzate',
                  '''• Flutter - Framework UI (BSD License)
• Hive - Database locale (Apache 2.0)
• Material Icons - Icone (Apache 2.0)
• connectivity_plus - Connettività (BSD)
• barcode_widget - Generazione barcode (MIT)
• mobile_scanner - Scanner fotocamera (BSD)
• screen_brightness - Luminosità schermo (MIT)
• share_plus - Condivisione (BSD)''',
                ),
                _buildExpandableTile(
                  'Servizi esterni',
                  '''• OpenSky Network - Tracking voli (CC BY-NC 4.0)
  https://opensky-network.org
  
• OpenWeatherMap - Dati meteo (CC BY-SA 4.0)
  https://openweathermap.org
  
• Clearbit Logo API - Loghi brand (gratuito)
  https://clearbit.com''',
                ),
                _buildExpandableTile(
                  'Open Source',
                  '''Cards è sviluppata con componenti open source.

Il codice sorgente dei pacchetti utilizzati è disponibile su pub.dev e GitHub.

Ringraziamo tutti i contributori della community Flutter!''',
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Contact section
            _buildSection(
              icon: Icons.email,
              title: 'Contatti',
              children: [
                _buildInfoTile('Sviluppatore', 'Paolo Artasensi'),
                _buildInfoTile('Sito Web', 'dev.paoloartasensi.it'),
              ],
            ),
            const SizedBox(height: 40),
            
            // Footer
            Center(
              child: Text(
                '© ${DateTime.now().year} Cards. Tutti i diritti riservati.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableTile(String title, String content) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      iconColor: Colors.white.withValues(alpha: 0.5),
      collapsedIconColor: Colors.white.withValues(alpha: 0.5),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 14,
        ),
      ),
      children: [
        Text(
          content,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
