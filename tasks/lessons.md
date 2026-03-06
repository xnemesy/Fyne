# Lessons Learned & Technical Patterns

## Violazioni Trovate
Durante l'audit di Quality Assurance (QA) per la Beta Readiness sono state identificate diverse regressioni critiche che bloccano la compilazione (`flutter analyze` riporta 31 errori). Le violazioni ricorrenti sono:

1. **Uso non valido di `const` su variabili statiche della classe Theme**
   - *Violazione:* `const FyneColors.amber`, `const FyneColors.forest`
   - *Motivo:* In `FyneColors`, i colori sono definiti come `static const Color`, ma istanziarli anteponendo un ulteriore `const` prima della classe (es. `const FyneColors.amber`) o usarli chiamando successivi metodi non-costanti (`const FyneColors.amber.withValues(...)`) risulta sintatticamente errato, producendo un Invalid Constant Value error.

2. **Costruttore di `Category` deprecato/invalido**
   - *Violazione:* Inizializzazione di costruttori con parametri posizionali mancanti `Category(id, name)`.
   - *Motivo:* A seguito del refactoring, la classe `Category` in `categorization_service.dart` richiede parametri nominati e campi obbligatori (`id`, `name`, `icon`, `color`).

3. **Proprietà rimosse/deprecate nei pacchetti esterni (`fl_chart`)**
   - *Violazione:* Uso del parametro inesistente `tooltipRoundedRadius` in `LineTouchTooltipData`.
   - *Motivo:* La proprietà non è più supportata nell'API della versione adottata attualmente nel progetto (`fl_chart ^1.1.1`).

4. **Metodi non definiti referenziati nella UI**
   - *Violazione:* Richiamo e interpolazione di stringa con il metodo `_buildFingerprint` (in `dashboard_screen.dart`) assente nell'implementazione.
   - *Motivo:* Residuo di un refactoring precedente o di un componente deprecato la cui firma non è stata allineata nel widget tree.

## Pattern Corretti Approvati

1. **Gestione Colori (`FyneColors`)**
   - *Pattern:* `color: FyneColors.amber` oppure `color: FyneColors.forest.withValues(alpha: 0.15)`
   - *Regola:* **Non** anteporre `const` all'accesso o alle espressioni che invocano le costanti statiche di `FyneColors` in combinazione con manipolatori come `withValues`.

2. **Inizializzazione Modelli (`Category`)**
   - *Pattern:* `Category(id: 'unique_id', name: 'Alimentari', icon: 'shopping_cart', color: '#4CAF50')`
   - *Regola:* Utilizzare esclusivamente parametri enumerati (named parameters) e compilare tutti i campi contrassegnati come required (vedi `categorization_service.dart`).

3. **Integrazione Charting**
   - *Pattern:* Rimozione di firme deprecate. Utilizzare i metodi formalmente supportati per l'override dei default in `LineTouchTooltipData`.
   - *Regola:* Controllare il CHANGELOG di librerie UI sensibili (`fl_chart`) per allineare le firme visive.

4. **Code Quality Generale**
   - *Pattern:* Evitare interpolazioni stringa di variabili o getter non definiti. Rimuovere logicamente call non raggiungibili se il fallback non è definito.
   - *Regola:* `flutter analyze` deve restituire sempre **0 errori**. Qualsiasi warning sollevato va controllato con la whitelist dei warning tollerati (ovvero variabili interne inutilizzate ma mantenute pre-approvate).
