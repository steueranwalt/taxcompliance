# Auslegen und Subsumieren mit ChatGPT - NJW 2024, 2092

Ausgeschnitten aus: [https://beck-online.beck.de/Print/CurrentMagazine?vpath=bibdata%5Czeits%5Cnjw%5C2024%5Ccont%5Cnjw.2024.2092.1.htm&printdialogmode=CurrentDoc&actionname=Index&gesamtversionpath=&timezone=Europe%2FZurich&exportFormat=print&options=WithFootNoteInText&options=WithReferences&options=WithLinks](<https://beck-online.beck.de/Print/CurrentMagazine?vpath=bibdata%5Czeits%5Cnjw%5C2024%5Ccont%5Cnjw.2024.2092.1.htm&printdialogmode=CurrentDoc&actionname=Index&gesamtversionpath=&timezone=Europe%2FZurich&exportFormat=print&options=WithFootNoteInText&options=WithReferences&options=WithLinks>)

TitelFundstelle

  
|   
  
---|---  
Dietrich: Auslegen und Subsumieren mit ChatGPT | NJW 2024, 2092  
  
# Auslegungs- und Subsumtionsfahigkeit des aktuellen Sprachmodells unter Anwendung verschiedener Prompting-Ansatze

Henrik Dietrich [Fn. *: Der Autor ist Wiss. Mitarbeiter am Lehrstuhl Prof. Dr. Marly an der TU Darmstadt.]

Der Einsatz von Kunstlicher Intelligenz in der anwaltlichen Tatigkeit wirft eine Vielzahl von rechtlichen Fragen auf. Zuvor stellt sich aber erst einmal die Frage, wie gut KI uberhaupt juristisch arbeitet. Der Beitrag untersucht die Fahigkeiten von ChatGPT im Hinblick auf die Kernkompetenzen der Auslegung von Gesetzestexten und der Subsumtion des Sachverhalts. 

### I. Einleitung

1Seit der Veroffentlichung von ChatGPT Version 3.5 am 30.11.2022 hat das Thema Kunstliche Intelligenz (KI) verstarkte Aufmerksamkeit in der medialen Berichterstattung erfahren. Das Potenzial von Systemen Kunstlicher Intelligenz (KI-Systeme) erscheint gewaltig. Transformationen in der juristischen Arbeitswelt muten unvermeidlich an, da KI-Systeme mittels Natural Language Processing (NLP), einem Prozess des maschinellen Lernens, die Struktur und die Semantik von Texten entschlusseln konnen.

2Auf dem deutschen Rechtsmarkt lassen sich erste Veranderungen durch den Einsatz Kunstlicher Intelligenz beobachten, wenngleich die Moglichkeiten und Grenzen der automatisierten Gesetzesanwendung noch zu klaren sind. Hinsichtlich der juristischen Kernkompetenzen, dem Auslegen und Subsumieren von Gesetzen, ist die Leistungsfahigkeit des wohl potentesten KI-Sprachmodells ChatGPT in seiner aktuellsten Version 4.0 noch unbekannt.

3In anderen Disziplinen, wie etwa der Augenheilkunde, wurden Untersuchungen zur Leistungsfahigkeit von ChatGPT 4.0 [Fn. 1: Im Folgenden: ChatGPT.] durchgefuhrt und es wurde festgestellt, dass der Chatbot sich ungefahr auf dem Niveau eines durchschnittlichen Assistenzarztes in der Augenheilkunde befindet, indem es bei Prufungsfragen zur Grund- und Fachausbildung eine Korrektheitsrate von 80 % erreichte und damit leicht uber dem Durchschnitt der getesteten Assistenzarzte liegt. [Fn. 2: Ein Forscherteam verglich die Antworten ChatGPTs in den Versionen 3.5 und 4.0 anhand von 167 Beispielfragen zur Augenheilkunde. ChatGPT 4.0 schnitt dabei deutlich besser ab als ChatGPT 3.5. ChatGPT 4.0 beantwortete 80 % aller Fragen richtig, wahrend es bei ChatGPT 3.5 nur in 57 % aller Fragen der Fall war Teebagy/Colwell/Wood/Yaghy/Faustina Improved Performance of ChatGPT-4 on the OKAP Exam: A Comparative Study with ChatGPT-3.5, 2 ff.]

4Der Anbieter von ChatGPT, OpenAI, hat ahnliche Leistungstests im juristischen Bereich durchgefuhrt, indem er das Uniform Bar Exam (Zulassungsprufung fur Anwalte in den USA) simulierte. Die Angaben OpenAIs, wonach ChatGPT bereits das 90. Perzentil in der amerikanischen Anwaltsprufung erreicht, wahrend die Vorversion 3.5 nur das 10. Perzentil erlangte, [Fn. 3: S. <https://openai.com/research/gpt-4>.] haben jedoch lediglich Relevanz fur die Beurteilung der juristischen Leistungen in Bezug auf US-amerikanisches Recht. Bezuglich der Fahigkeiten zur deutschen Rechtsanwendung lassen die simulierten Prufungsergebnisse 

Dietrich: Auslegen und Subsumieren mit ChatGPT(NJW 2024, 2092)

nur vermuten, dass ChatGPT womoglich auch deutsche Gesetzesanwendung meistern konnte.

5Dieser Beitrag zielt darauf ab, die juristischen Fahigkeiten von ChatGPT, vor allem im Hinblick auf die (deutsche) Gesetzesauslegung und -subsumtion, darzulegen. Wie weit entwickelt ist „Legal Tech“ [Fn. 4: Der Begriff Legal Tech bezeichnet den Einsatz von Technologien zur Optimierung juristischer Arbeitsprozesse, Effizienzsteigerung und Kostenreduktion in der Rechtsbranche. Neben der Automatisierung von Dokumentenerstellung und dem Einsatz fortschrittlicher Systeme fur das Fall- und Dokumentenmanagement mittels KI umfasst Legal Tech vor allem die Fahigkeit der KI, selbststandig juristische Falle zu analysieren und Losungsansatze zu erarbeiten. Daruber hinaus beinhaltet es Plattformen fur digitale Kommunikation, Blockchain-Anwendungen fur sichere Transaktionen und die Online-Streitbeilegung. Legal Tech erleichtert den Zugang zu Rechtsdienstleistungen und tragt zur Digitalisierung der Rechtspraxis bei, was eine Transformation traditioneller Arbeitsweisen und eine Neugestaltung der Beziehung zwischen Anwalt und Mandant zur Folge hat. S. die unterschiedlichen Definitionen zu Legal Tech bei Brechmann Legal Tech und das Anwaltsmonopol, 2021, 5 ff.] in Deutschland bereits und lasst sich durch verschiedene Promptingansatze eine Leistungssteigerung erzielen?

6Dafur wird der Aufbau des Leistungstests dargelegt, gefolgt von einer Erlauterung der methodologischen Grundlagen zur Gesetzesauslegung und -subsumtion. Abschließend werden die Testergebnisse analysiert. Vorweg muss jedoch kurz auf die Bedienungs- und Einstellungsoptionen des Untersuchungsgegenstands – ChatGPT – eingegangen werden, um dessen Funktionsweise erlautern zu konnen.

### II. Bedienung und Einstellung von ChatGPT

7ChatGPT vermag bis zu einem Limit von 25.000 Zeichen Text zu verarbeiten. Die in die Kommandozeile eingegebenen Steuerbefehle werden als Prompts (Anweisungen) bezeichnet. Ferner bietet das System die Moglichkeit der Personalisierung der Prompts durch das Definieren sogenannter Custom Instructions (individuelle Anweisungen). Diese ermoglichen es, dem System in einem Umfang von bis zu 1.500 Zeichen generelle Anweisungen bezuglich der Art und Weise, wie es auf Prompts reagieren bzw. antworten soll, zu erteilen. Die Custom Instructions konnen demnach als eine Form der generellen Konfiguration des Systems verstanden werden.

8Wie prazise ChatGPT die Antworten formuliert, wird maßgeblich durch das Festlegen spezifischer Custom Instructions und Prompts beeinflusst. OpenAI hat in Bezug auf das Prompting eigene Empfehlungen publiziert. Nach diesen Empfehlungen sind im Kontext des sogenannten Prompt Engineerings – der Optimierung der Anweisungen – zielgerichtete Strategien von essenzieller Bedeutung, um die Qualitat der Interaktion zu steigern. [Fn. 5: <Https://platform.openai.com/docs/guides/prompt-engineering/six-strategies-for-getting-better-results>.]

### III. Der Versuchsaufbau

9Um ChatGPTs juristische Fahigkeiten bei der Auslegung und Subsumtion gesetzlicher Normen zu bewerten, ist ein Verstandnis juristischer Methoden essenziell. Mit einem methodischen Testansatz wurde ChatGPT uber verschiedene Rechtsbereiche hinweg mittels unterschiedlicher Prompting-Strategien getestet, darunter der Anwendung von Custom Instructions und der Verwendung aufwendiger Prompts, um auch den Einfluss der Prompts auf ChatGPT analysieren zu konnen. Mit 30 Auslegungs- und zehn Subsumtionsaufgaben pro der drei Rechtsgebiete Zivilrecht, Strafrecht und Verwaltungsrecht wurde die Genauigkeit von ChatGPTs Antworten gepruft, wobei jede Aufgabe in vier verschiedenen Prompting bzw. Custom-Instructions-Konstellationen durchgefuhrt wurde. Insgesamt umfasste der Test also 360 Auslegungs- und 120 auszuwertende Subsumtionsaufgaben. 

10Die Ergebnisse wurden nach Prazision und Argumentationstiefe analysiert. Bewertet wurde auf einer Skala von eins bis funf Punkten, wobei eins eine unzureichende und funf die beste Punktzahl darstellt.

### IV. Methoden der Gesetzesauslegung

11Die Auslegung von Normen und die Subsumtion von Sachverhalten unter die entsprechenden Gesetze sind die handwerklichen Kernfahigkeiten fur eine gelungene Rechtsanwendung. Die Gesetzesauslegung bildet dabei die „schopferische Geistestatigkeit“ [Fn. 6: Larenz/Canaris Methodenlehre der Rechtswissenschaft, 3. Aufl. 1995, S. 166.] des Juristen. Daher ist es nicht verwunderlich, dass die juristische Methodenlehre mit seinen Hilfsmitteln der Gesetzesauslegung eine zeitlose juristische Theorie darstellt. [Fn. 7: Ishibe/Sandstrom/Vogenauer/Schroder Rechtswissenschaft in der Neuzeit, Bd. 2, 2023, S. 458 f.]

12 Zeitlose Bedeutung erfahrt dementsprechend der Begrunder der heutigen Methodenlehre Friedrich Carl von Savigny (1779–1861), auf den die vier Arten der Auslegung, die grammatikalische, die systematische, die historische und die teleologische Auslegung, zuruckgehen. [Fn. 8: Wesenberg/Savigny Juristische Methodenlehre nach den Ausarbeitungen des Jakob Grimm, 1951, S. 18 ff., 31 ff., 35 ff.] Der BGH betont die Gleichstufigkeit der vier Auslegungsmethoden, wenn er ausfuhrt: „Unter ihnen hat keine einen unbedingten Vorrang vor einer anderen, wobei Ausgangspunkt der Auslegung der Wortlaut der Vorschrift ist.“ [Fn. 9: BGH 15.5.2019 – VIII ZR 51/18, BeckRS 2019, 11577 Rn. 29.] Es ist daher im konkreten Einzelfall zu ermitteln, welche der Argumente die großtmogliche Überzeugungskraft enthalt und gegenuber den anderen Auslegungsarten obsiegt. [Fn. 10: Puppe Kleine Schule des juristischen Denkens, 5. Auf. 2023, S. 178.] Dabei ist das Ziel der Auslegung, den normativen Gesetzessinn zu ermitteln. [Fn. 11: Larenz/Canaris Methodenlehre der Rechtswissenschaft, 3. Aufl. 1995, S. 140.] Das erlaubt eine Dynamik, nach der auch altere Gesetze auf neue Lebenswirklichkeiten angewendet konnen, indem die ihr innewohnende ursprungliche Bedeutung in einem neuen Kontext betrachtet wird. [Fn. 12: Wank Die Auslegung von Gesetzen, 6. Auf. 2017, S. 77; Hopfner Die systemkonforme Auslegung, 2008, S. 388.]

13Die grammatikalische, auch philologische [Fn. 13: Wesenberg/Savigny Juristische Methodenlehre nach den Ausarbeitungen des Jakob Grimm, 1951, S. 18 ff.] Auslegung genannt, ergrundet die Bedeutung anhand des Wortsinns (Semantik) und des Satzbaus (Syntax) der auslegungsbedurftigen Rechtsnorm. Aufgrund der Mehrdeutigkeit von Sprache ist diese Auslegungsart komplex, ware aber bei einer unumstoßlichen sprachlichen Eindeutigkeit auch nicht vonnoten. Ausgangspunkt der grammatikalischen Auslegung ist der Wortlaut, [Fn. 14: Honsell ZfPW 2016, 106 (120).] also dessen Bedeutung. [Fn. 15: Wank Die Auslegung von Gesetzen, 6. Auf. 2017, S. 32.] Anhand des 

Dietrich: Auslegen und Subsumieren mit ChatGPT(NJW 2024, 2092)

Sprachgebrauchs ist der Wortsinn, der sich durch Legaldefinitionen, den juristischen oder allgemeinen Sprachgebrauch ergeben kann, zu ermitteln. [Fn. 16: Vgl. Dornis/Keßenich/Lemke Rechtswissenschaftliches Arbeiten, 1. Aufl. 2019, § 6 II 3.] Die Syntax eines Rechtssatzes hingegen erlaubt aufgrund der Anordnungen und Wortverbindungen einen Ruckschluss auf die Bedeutung einer Vorschrift. Grenze der grammatikalischen Auslegung ist der durch die Sprache zementierte Inhalt des Gesetzes, mithin die Grenze des Wortsinns. [Fn. 17: BVerfGE 71, 108 (115) = NJW 1986, 1671.]

14Die systematische Auslegung dient dazu, den normativen Gesetzessinn anhand des systematischen Zusammenhangs, in welchem die Norm verortet ist, zu ergrunden. [Fn. 18: Bydlinski Grundzuge der juristischen Methodenlehre, 4. Aufl. 2023, S. 32.] Dabei sind die explizite Bedeutung anderer Vorschriften im Regelungsbereich des auszulegenden Gesetzes zu berucksichtigen. Konkret ist dabei etwa die Stellung innerhalb der Vorschrift (Halbsatz, Satz, Absatz), innerhalb des Gesetzes (Buch, Titel, Untertitel, Abschnitt) und die systemische Dynamik zu anderen Gesetzen mit einem ahnlichen Regelungsbereich zu beachten. Kurzum, es muss die Einbettung der Norm in der Mikro- und Makrolage der geltenden Gesetze berucksichtigt werden. [Fn. 19: Zippelius Juristische Methodenlehre, 12. Aufl. 2021, S. 43.] Die Einheit der Rechtsordnung verlangt zudem eine widerspruchsfreie Auslegung. Vor allem ist die Normenhierachie zu berucksichtigen und bei Gebotenheit eine verfassungs- [Fn. 20: Eckardt Die verfassungskonforme Gesetzesauslegung, 1964, S. 71.] und europarechtskonforme [Fn. 21: EuGH ECLI:EU:C:2004:584 = NJW 2006, 2465 Rn. 108 ff.] Auslegung vorzunehmen.

15Die historische Gesetzesauslegung bedient sich den Beweggrunden des Gesetzeserlasses. Dabei kann auf samtliche Materialien zuruckgegriffen werden, die den Gesetzeserlass begrunden und die geschichtliche Einbettung dokumentieren. Insbesondere sind Materialien zum Referentenentwurf des Ministeriums, zum Regierungsentwurf, zur Bundestags- und Bundesratsdebatte, zum Ausschussprotokoll und selbstverstandlich Materialien zur Gesetzesbegrundung auszuwerten. [Fn. 22: Wank Die Auslegung von Gesetzen, 6. Aufl. 2017, S. 68.] Dadurch konnen die kollektiven Beweggrunde herausgearbeitet werden. Falls eine bestehende Rechtsnorm durch eine neue Vorschrift verworfen werden soll, konnen auch diese Beweggrunde bei der Auslegung der ersetzenden Vorschrift dienlich sein. Durch Änderungen in der Gesellschaft konnen Gesetzesbegrundungen jedoch hinter andere Auslegungsarten zurucktreten, da ihre Aussagekraft durch zeitliche Umbruche verblasst.

16Mittels der teleologischen Auslegung wird der Sinn und Zweck einer Vorschrift ermittelt und dem Normverstandnis zugrunde gelegt. Es geht im Konkreten darum, den sich durch die Norm aufdrangenden gewunschten Zustand zu eruieren. Diese Auslegungsart berucksichtigt mithin die Folgen der unterschiedlichen Auslegung. [Fn. 23: Bydlinski Grundzuge der juristischen Methodenlehre, 4. Aufl. 2023, S. 38.] Dies gebietet teilweise eine rechtskonforme restriktive Auslegung in Form der teleologischen Reduktion oder der rechtskonformen expansiven Auslegung in Form der Analogie. In diesem Sinne strebt die teleologische Auslegung danach, den legislativen Zweck zu realisieren und dabei den gesellschaftlichen Kontext und die sich daraus ergebenden Bedurfnisse zu berucksichtigen. Sie erlaubt eine Auslegung, die sich innerhalb des Wortlauts an den ubergeordneten Zielen und Werten des Gesetzgebers orientiert, um so zu einer sachgerechten und zeitgemaßen Anwendung der Rechtsnormen zu gelangen.

### V. Sauberes Subsumieren

17Die Subsumtion ist die Rechtsanwendung als solche. Ein konkreter Sachverhalt wird unter eine abstrakte Norm gefasst. Die in der vorherigen Rechtsauslegung gewonnenen Erkenntnisse mussen bei der Subsumtion auf den konkreten Sachverhalt angewendet werden. Es erfolgt eine Überprufung, ob der konkret-individuelle Sachverhalt unter den Tatbestand der interpretierten Rechtsnorm fallt. Dies gleicht einem Puzzle, in dem die abstrakten Schlusselbegriffe mit dem konkreten Sachverhalt zusammengebracht werden mussen. [Fn. 24: Hildebrand Juristischer Gutachtenstil, 3. Aufl. 2017, 26.] Dabei ist sehr detailliert mit dem herausgearbeiteten oder bereits gegebenen Sachverhalt zu arbeiten. [Fn. 25: Valerius Einfuhrung in den Gutachtenstil, 4. Aufl. 2017, 19.]

18Fur eine gelungene Subsumtion sind insbesondere folgende Faktoren notwendig: [Fn. 26: Vgl. die Darstellung bei Kuhn JURA 2023, 1376 (1383 f.).] Ein genaues Herausarbeiten der Voraussetzungen durch Erfassung des Wortlauts der Vorschrift, ein detaillierter Abgleich der Sachverhaltsangaben ausschließlich anhand der herausgearbeiteten Voraussetzungen, in dem keine neuen abstrakten Begriffe eingefuhrt werden, sondern nur solche aus der Norm aufgegriffen werden sowie eine detaillierte Begrundung der Subsumtion unter Heranziehung des Normverstandnisses, wobei weitere mogliche Formen des Normverstandnisses aufgedeckt und argumentativ bearbeitet werden, um das eigene Normverstandnis argumentativ zu untermauern.

### VI. Custom Instructions fur den Leistungstest

19Diese Erkenntnisse zur Praxis der Auslegung und sauberen Subsumtion dienten im Leistungstest jeweils als Custom Instruction.

20Die Custom Instructions zur Auslegung lauteten:

Wende bei der Auslegung von Gesetzen die grammatikalische, systematische, historische und teleologische Auslegung an:

  * –Beginne mit dem sehr genauen und gesamten Erfassen des Gesetzestextes und ermittle die entscheidenden Textstellen. Achte auf Semantik und Syntax, adressiere Sprachmehrdeutigkeiten und nutze vorhandene Legaldefinitionen, ansonsten den juristischen Sprachgebrauch. 
  * –Strebe bei EU-Recht eine europarechtskonforme Auslegung an unter Beachtung der Wortsinngrenze. Ermittle die Bedeutung einer Vorschrift durch ihre systematische Platzierung und prufe ihren Kontext unter Berucksichtigung ihrer exakten Position (zB Satz, Absatz) und Stellung im Gesetz (zB Buch, Titel)! Achte auf die Normenhierarchie und gewahrleiste eine verfassungs- und europarechtskonforme Auslegung.
  * –Untersuche, nur falls bereitgestellt, Gesetzesmaterialien bei der Auslegung und prufe die Anpassung an heutige Zeiten, immer innerhalb der Wortsinngrenze. Ohne bereitgestellte Gesetzesmaterialien nimm keine historische Auslegung vor.
  * – 

Dietrich: Auslegen und Subsumieren mit ChatGPT(NJW 2024, 2092)

Ermittle den legislativen Zweck durch Analyse der Interessenbewertungen in der Norm bei der teleologischen Auslegung. Beachte den Normzweck und die praktischen Folgen, wahle sodann die zielkonformste Auslegungsvariante innerhalb des Wortlauts.

  * –Ziel ist es, den wahren Gesetzeszweck ausschließlich innerhalb der Wortlautgrenze zu ermitteln. Es gibt keine feste Rangordnung zwischen den einzelnen Methoden. Lege dich am Ende auf ein Ergebnis innerhalb der Wortlautgrenze fest!



21Die Custom Instructions zur Subsumtion lauteten:

  * –Wortlaut genau erfassen: Beginne mit einer akkuraten Erfassung des Wortlauts der relevanten Norm. Dies ist der Ausgangspunkt jeder Subsumtion und dient dazu, die rechtlichen Voraussetzungen klar zu definieren.
  * –Sachverhalt detailliert abgleichen: Vergleiche den gegebenen Sachverhalt mit den zuvor identifizierten Normvoraussetzungen. Achte darauf, keine neuen abstrakten Begriffe einzufuhren, die nicht aus der Norm hervorgehen.
  * –Detailliert begrunden: Jede Subsumtion sollte durch eine Begrundung untermauert werden, die auf einem Verstandnis der Norm basiert. Bearbeite und widerlege mogliche alternative Normverstandnisse argumentativ.
  * –Pendelblick: Wende den „Pendelblick“ zwischen den abstrakten Begriffen der Norm und den konkreten Begriffen des Sachverhalts an, um eine genaue und passgenaue Zuordnung sicherzustellen.
  * –Sachverhaltswiederholungen vermeiden: Die Subsumtion darf nicht durch eine Wiederholung des Sachverhalts ersetzt werden. Es ist wichtig, uber eine Aufzahlung hinauszugehen und die rechtliche Relevanz der Fakten herauszuarbeiten. Vermeide es, die Subsumtion durch Behauptungen zu ersetzen.
  * –Begrunde, warum der Sachverhalt unter die Definition fallt. Beziehe die konkrete Verwendung oder Umstande eines Gegenstands oder einer Handlung mit ein, um deren Einstufung als tatbestandsmaßig zu untermauern.
  * –Schlusselbegriffe anwenden: Nutze die aus der Norm gewonnenen Schlusselbegriffe, um den Sachverhalt unter die entsprechenden Tatbestandsmerkmale zu subsumieren.



### VII. Unterschiedliche Promptingansatze

22Die weiteren Promptingansatze, welche direkt in der Eingabemaske erfolgten und keine Custom Instructions sind, wurden aufgrund der Promptinghinweise auf der Webseite von OpenAI [Fn. 27: <Https://platform.openai.com/docs/guides/prompt-engineering/six-strategies-for-getting-better-results>. ] zur Optimierung der Ergebnisse abgeleitet.

23Wurden aufwendige Prompts benutzt, sind neben der Aufgabenstellung und der Zurverfugungstellung der maßgeblichen Normen daher folgende abstrakte Prompting-Methoden beachtet worden:

– Klare Anweisungen durch prazise und detaillierte Anfragen 

– Vorgabe, die Rolle eines deutschen Richters einzunehmen

– Bereitstellung von weiteren Informationen und Denkanstoßen

– Aufteilung komplexer Aufgaben in einfachere Unteraufgaben 

– Gewahrung von „Denkzeit“ fur das Modell durch Anforderung einer „Gedankenfolge“

– Vermittlung der Wichtigkeit der Aufgabe. 

### 1\. Promptingansatze fur Auslegungsfragen

24Konkret wurden folgende vier unterschiedlichen Promptingansatze fur die Auslegungsfragen angewandt:

25 1\. Promptingansatz: Aufgabenstellung und Bereitstellung der erforderlichen Gesetzestexte (diese Eingaben erfolgten auch stets bei den anderen Promptingansatzen).

26 2\. Promptingansatz: Einsatz der Custom Instructions.

27 3\. Promptingansatz: Erste Eingabe: Nimm die Rolle eines deutschen Richters ein und gehe umfassend auf die Frage ein. Zeige mir Schritt fur Schritt, wie du zu der jeweiligen Auslegung gekommen bist und stelle deine Gedankengange sehr nachvollziehbar dar. Die Aufgabe ist sehr wichtig, gib dein Bestmogliches, um sie zu losen. Zweite Eingabe: Fallen dir noch mehr Aspekte zu der von mir gestellten Frage ein? Gib eine abschließende Antwort und begrunde sie sehr gut und nachvollziehbar.

284\. Promptingansatz: Erste Eingabe: Unter Einsatz der Custom Instructions: Nimm die Rolle eines deutschen Richters ein und gehe umfassend und nur auf die grammatikalische und systematische Auslegung ein. Zeige mir Schritt fur Schritt, wie du zu der jeweiligen Auslegung gekommen bist und stelle deine Gedankengange sehr nachvollziehbar dar. Die Aufgabe ist sehr wichtig, gib dein Bestmogliches, um sie zu losen. Zweite Eingabe: Nimm die Rolle eines deutschen Richters ein und gehe umfassend und nur auf die historische und teleologische Auslegung ein. Zeige mir Schritt fur Schritt, wie du zu der jeweiligen Auslegung gekommen bist und stelle deine Gedankengange sehr nachvollziehbar dar. Die Aufgabe ist sehr wichtig, gib dein Bestmogliches, um sie zu losen. Dritte Eingabe: Aufgrund der beiden Analysen der jeweiligen Auslegungsmethoden gib eine abschließende sehr gut begrundete und nachvollziehbare Antwort.

### 2\. Promptingansatze fur Subsumtionsaufgaben

29Konkret wurden folgende vier unterschiedlichen Promptingansatze fur die Subsumtionsaufgaben angewandt:

30 1\. Promptingansatz: Aufgabenstellung und Bereitstellung der erforderlichen Gesetzestexte (diese Eingaben erfolgten auch immer bei den anderen Promptingansatzen).

31 2\. Promptingansatz: Einsatz der Custom Instructions.

32 3\. Promptingansatz: Erste Eingabe: Nimm die Rolle eines deutschen Richters ein und gehe umfassend auf die Frage ein. Zeige mir Schritt fur Schritt, wie du zu dem jeweiligen Ergebnis gekommen bist und stelle deine Gedankengange sehr nachvollziehbar dar. Die Aufgabe ist sehr wichtig, gib dein Bestmogliches, um sie zu losen. Zweite Eingabe: Fallen dir noch mehr Aspekte zu der von mir ge-

Dietrich: Auslegen und Subsumieren mit ChatGPT(NJW 2024, 2092)

stellten Frage ein? Gib eine abschließende Antwort und begrunde sie sehr gut und nachvollziehbar.

33 4\. Promptingansatz: Erste Eingabe: Unter Einsatz der Custom Instructions: Als Richter im deutschen Rechtssystem sollst du eine detaillierte rechtliche Subsumtion durchfuhren, die sich ausschließlich auf die erste spezifische Tatbestandsvoraussetzung konzentriert. Beginne zuerst mit der Herausarbeitung der gesamten Tatbestandsvoraussetzungen und zeige sodann diejenigen Tatbestandsvoraussetzungen auf, die zur Losung des Falls erforderlich sind. Bearbeite dann sehr genau nur die erste Halfte der von dir herausgearbeiteten Voraussetzungen. Die weiteren Voraussetzungen, die fur eine vollstandige Subsumtion notwendig sind, werden in einer folgenden, separaten Anfrage behandelt. Bitte halte dich wirklich sehr streng an diese Vorgabe, um eine fokussierte und prazise Bearbeitung zu gewahrleisten. Zweite Eingabe: Als Richter im deutschen Rechtssystem sollst du eine detaillierte rechtliche Subsumtion durchfuhren, die sich ausschließlich auf die weiteren spezifischen Tatbestandsvoraussetzung konzentriert. Beginne zuerst mit der Herausarbeitung der noch zu prufenden Tatbestandsvoraussetzungen und zeige sodann diejenigen Tatbestandsvoraussetzungen auf, die zur Losung des Falls erforderlich sind. Bearbeite dann sehr genau nur die zweite noch fehlende Halfte der von dir herausgearbeiteten Voraussetzungen. Bitte halte dich wirklich sehr streng an diese Vorgabe, um eine fokussierte und prazise Bearbeitung zu gewahrleisten. Dritte Eingabe: Aufgrund der beiden Subsumtionsaufgaben prasentiere eine abschließende sehr gut begrundete Subsumtion unter die Ausgangsfrage.

### VIII. Auswertung der Ergebnisse

34Als Ergebnis lasst sich Folgendes festhalten: 

35Auslegung: (30 Auslegungsfragen fur jeweils jedes Rechtsgebiet, das heißt insgesamt 90 Auslegungsfragen, 150 Punkte pro Spalte als Maximalpunktzahl theoretisch moglich). 

Rechtsgebiet | Punktzahl (1. Promptingansatz)  | Punktzahl (2. Promptingansatz) | Punktzahl (3. Promptingansatz) | Punktzahl (4. Promptingansatz)  
---|---|---|---|---  
Zivilrecht | 99 | 113 | 78 | 124  
Strafrecht | 91 | 104 | 91 | 110  
Öffentliches Recht  | 78 | 96 | 86 | 107  
  
36Subsumtion: (Zehn Subsumtionsaufgaben fur jeweils jedes Rechtsgebiet, das heißt insgesamt 30 Subsumtionsaufgaben, 50 Punkte pro Spalte als Maximalpunktzahl theoretisch moglich). 

Rechtsgebiet | Punktzahl (1. Promptingansatz) | Punktzahl (2. Promptingansatz) | Punktzahl (3. Promptingansatz) | Punktzahl (4. Promptingansatz)  
---|---|---|---|---  
Zivilrecht | 35 | 35 | 32 | 43  
Strafrecht | 30 | 36 | 28 | 36  
Öffentliches Recht  | 33 | 39 | 40 | 43  
  
### 1\. Auslegungsfragen

37Bei den Auslegungsaufgaben uberzeugte ChatGPT oftmals mit der Argumentation am Normzweck. So war bei allen vier Promptingansatzen positiv zu werten, dass das System eine Nachreichung eines analogen Schriftsatzes funf Wochen nach einer technischen Übermittlungsstorung, treffend und mit guten Ausfuhrungen als nicht unverzuglich iSd § [130d](<https://beck-online.beck.de/?typ=reference&y=100&g=ZPO&p=130D>) ZPO, § [121](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=121>) BGB einordnete. 

38Mit dem am wenigsten aufwendigen ersten Promptingansatz wurden teils sehr gute Antworten erzeugt. Etwa auf die Frage hin, ob fahrlassige Mittaterschaft gem. § [25](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=25>) [II](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=25&x=2>) StGB moglich sei, antwortete das System uberzeugend: „(…) Fur eine fahrlassige Mittaterschaft mussten somit mehrere Personen durch ihr Zusammenwirken fahrlassig einen tatbestandlichen Erfolg herbeifuhren. Hier stoßt man jedoch auf dogmatische Schwierigkeiten, denn die Mittaterschaft setzt einen gemeinsamen Tatentschluss voraus, der bei Fahrlassigkeitsdelikten problematisch ist. Fahrlassigkeit impliziert gerade, dass der Eintritt des tatbestandlichen Erfolges nicht gewollt war, was die Bildung eines gemeinsamen Tatentschlusses zur Herbeifuhrung dieses Erfolges ausschließt (…).“

39Der zweite Promptingansatz zeichnete sich durch eine hohere Konsistenz im Vergleich zum ersten Promptingansatz aus, lieferte jedoch auch gelegentlich unvollstandige Antworten. Auf die Frage hin, was eine Handlung als tatlichen Angriff iSd § [114](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=114>) [I](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=114&x=1>) StGB qualifiziert, antwortete das System nach der Auslegung zutreffend, aber unvollstandig, dass „(e)in tatlicher Angriff iSd § [114](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=114>) [I](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=114&x=1>) StGB sich durch eine Handlung qualifiziert, die objektiv als Angriff auf die korperliche Integritat eines Amtstragers oder Soldaten wahrend einer Diensthandlung eingestuft werden kann“. Es wird weiter ausgefuhrt: „Ein expliziter Verletzungsvorsatz ist fur die Annahme eines solchen Angriffs nicht erforderlich. Entscheidend ist die objektive Eignung der Handlung, den Amtstrager physisch zu beeintrachtigen oder anzugreifen, unabhangig von der Intention, eine Verletzung herbeizufuhren.“ Nicht erwahnt wird jedoch, dass ein physischer Kontakt fur einen tatlichen Angriff nicht erforderlich ist.

40Der zweite Promptingansatz garantierte jedoch auch keine stets verwertbaren Ergebnisse. Dies zeigte sich beispielsweise, als ChatGPT auf die Frage hin, ob es zur Wahrnehmung von Verkehrszeichen zwischen dem ruhendem und dem fließenden Verkehr unterschiedliche Sorgfaltspflichten eines Verkehrsteilnehmers gebe, antwortete: „Auf Basis der angewandten Auslegungsmethoden lasst sich schlussfolgern, dass die StVO keine explizite Unterscheidung hinsichtlich der Sorgfaltspflichten zur Wahrnehmung von Verkehrszeichen zwischen ruhendem und fließendem Verkehr trifft.“

41Die solide Argumentationsfahigkeit des Systems wurde selbst bei dem am geringsten bewerteten dritten Promptingansatz deutlich, als ChatGPT gefragt wurde, wie der Begriff „Mitwirkung“ des Notars gem. § [40](<https://beck-online.beck.de/?typ=reference&y=100&g=GMBHG&p=40>) GmbHG zu verstehen sei, insbesondere ob die bloße Beteiligung des Notars an Veranderungen ausreichen wurde, auch wenn ihm die objektive Moglichkeit zur Kenntniserlangung fehlt. Das System erklarte daraufhin: „(…) Basierend auf den vorangegangenen Überlegungen ist ,Mitwirkung’ im Kontext des § [40](<https://beck-online.beck.de/?typ=reference&y=100&g=GMBHG&p=40>) [II](<https://beck-online.beck.de/?typ=reference&y=100&g=GMBHG&p=40&x=2>) GmbHG so zu verstehen, dass sie eine substanzielle Beteiligung des Notars an den Veranderungen erfordert, die 

Dietrich: Auslegen und Subsumieren mit ChatGPT(NJW 2024, 2092)

es ihm ermoglicht, die Richtigkeit der relevanten Informationen zu uberprufen. (…)“ 

42 Im Vergleich zu den anderen neigte der dritte Promptingansatz jedoch haufiger dazu, rechtlich irrelevante Überlegungen einzubeziehen oder Antworten zu liefern, die ausweichend waren oder uber den eigentlichen Wortlaut der Norm hinausgingen. Als das System beispielsweise gefragt wurde, wie die Gefahrdungshaftung gem. § [7](<https://beck-online.beck.de/?typ=reference&y=100&g=STVG&p=7>) StVG zu bewerten sei, wenn durch eine entfernte Batterie Schaden verursacht wurden, antwortete es ausweichend wie folgt: „Fur eine definitive Beurteilung waren jedoch konkrete Umstande des Einzelfalls entscheidend. (…) In jedem Fall ware eine grundliche Prufung der Einzelheiten und Umstande des Schadens notwendig, um eine fundierte rechtliche Bewertung vorzunehmen.“

43Vor allem der vierte Promptingansatz fuhrte haufig zu uberzeugenden Ergebnissen, bei denen ChatGPT eine umfassende und wohlstrukturierte Auslegung nach dem Normzweck demonstrierte. Etwa auf die Frage hin, ob die Rucktrittsnorm des Leistungsstorungsrechts nach § [323](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=323>) BGB auch auf Dienstvertrage anwendbar sei, antwortete das System sehr treffend: „(…) Der Hauptzweck des § [323](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=323>) BGB ist es, dem Glaubiger ein Rucktrittsrecht zu gewahren, wenn die Leistung nicht wie geschuldet erbracht wird und somit der Vertragszweck gefahrdet ist. Bei Dienstvertragen, auch wenn kein konkreter Erfolg geschuldet ist, basiert die Vereinbarung auf der Erwartung einer Leistung nach den vereinbarten Kriterien und Qualitaten. Sollte diese Erwartung aufgrund nicht oder nicht vertragsgemaß erbrachter Leistungen grundlegend enttauscht werden, steht der Sinn und Zweck des Vertrags infrage. Die teleologische Auslegung unterstutzt daher die Ansicht, dass § [323](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=323>) BGB anwendbar sein sollte, um den Glaubiger auch bei Dienstvertragen vor nicht erfullten Leistungsversprechen zu schutzen (…).“

44Die Frage, ob § [12](<https://beck-online.beck.de/?typ=reference&y=100&g=UWG&p=12>) [I](<https://beck-online.beck.de/?typ=reference&y=100&g=UWG&p=12&x=1>) UWG analog auf Unterlassungsanspruche nach dem GeschGehG angewendet werden kann, beantwortete das System beim vierten Promptingansatz unter Berucksichtigung der historischen Auslegung mustergultig wie folgt: „Die historische Auslegung zeigt, dass beide Gesetze auf unterschiedliche rechtspolitische und wirtschaftliche Entwicklungen reagieren. Wahrend das UWG lange etabliert und im Laufe der Zeit angepasst wurde, um den Wettbewerb zu regulieren und unlauteres Verhalten zu sanktionieren, ist das GeschGehG eine relativ neuere Entwicklung, die spezifisch den Schutz von Geschaftsgeheimnissen im Auge hat und auf europaischen Vorgaben beruht. Dies deutet darauf hin, dass der Gesetzgeber die Moglichkeit hatte, ahnliche Regelungen fur den einstweiligen Rechtsschutz im GeschGehG zu verankern, dies jedoch unterließ.“

### 2\. Subsumtionsaufgaben

45Bei den Subsumtionsaufgaben konnte bei allen Promptingansatzen positiv festgestellt werden, dass die jeweiligen Tatbestandsvoraussetzungen, unter die es zu subsumieren galt, in der Regel alle erkannt wurden. 

46Bei jedem der vier Promptingansatze nahm jedoch das System bei einer der zivilrechtlichen Subsumtionsaufgaben irrigerweise einen Fernabsatzvertrag an. Die Aufgabe lautete: „Besteht ein Widerrufsrecht, wenn ich einen Toaster im Laden miete und nach der Mietzeit den gleichen Toaster per Mail bestelle? Steht mir dann ein Widerrufsrecht aufgrund eines Fernabsatzvertrags zu? Subsumiere unter die zitierten Vorschriften.“ Trotz der Bereitstellung von Art. [2a](<https://beck-online.beck.de/?typ=reference&y=100&g=EWG_RL_2002_65&a=2A>) RL 2002/65/EG erkannte das System nicht die Notwendigkeit der Voraussetzung einer durchgehenden Kommunikation via Fernabsatzmittel.

47Und auf die Frage hin, ob eine Strafbarkeit des K nach den §§ [22](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=22>), [23](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=23>), [287](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=287>) StGB vorliegen wurde, wenn dieser zum Versuch einer unerlaubten Veranstaltung einer Lotterie ansetzt, bejahte das System beim ersten bis vierten Promptingansatz mit Hinweis auf § [23](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=23>) StGB eine Strafbarkeit. Dies verwunderte sehr, da der Wortlaut des § [22](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=22>) StGB den Versuch eines Vergehens explizit straffrei stellt.

48Mit Ausnahme dieser beiden Beispiele konnte das System jedoch zumindest mit samtlichen Promptingansatzen zeigen, dass es durchaus imstande ist, das Subsumieren unter die Tatbestandsvoraussetzungen einer Norm zu meistern. ChatGPT uberzeugte zum Beispiel damit, dass es nach Prufung der §§ [946](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=946>), [94](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=94>), [95](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=95>) BGB die abstrakten Eigentumsverhaltnisse an einem Spaten, der in einem veraußerten Grundstuck steckte, nach sauberer Subsumtion dem vormaligen Eigentumer des Grundstucks zuschrieb.

49Auch mit dem einfachsten, dem ersten Promptingansatz bemerkte ChatGPT, wenn ihm notige Sachverhaltsangaben fehlten. Aus der Aufgabenstellung zu einer Strafbarkeit des H nach § [142](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=142>) StGB ging nicht eindeutig hervor, ob sich H nach dem Unfall entfernt hatte oder am Unfallort verblieben war. Daher antwortete das System korrekt: „(…) H hatte sich gem. § [142](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=142>) StGB strafbar gemacht, wenn er sich vom Unfallort entfernt hatte, ohne die notwendigen Feststellungen zu seiner Person, seinem Fahrzeug und der Art seiner Beteiligung zu ermoglichen oder eine angemessene Zeit gewartet zu haben, ohne dass jemand bereit war, die Feststellungen zu treffen. Die genaue Beurteilung hangt von Hs Handlungen unmittelbar nach dem Unfall ab.“

50Auch der dem ersten Promptingansatz leicht uberlegene zweite Promptingansatz uberzeugte durch seine klare Subsumtionsstruktur, etwa als ChatGPT auf die Frage der Strafbarkeit des finnischen Staatsburgers F, der in den USA einen Franzosen erschossen hatte und abschließend nach Deutschland geflohen war, antwortete: „(…) Aufgrund der dargestellten Subsumtion kann F nach deutschem Strafrecht fur die in den USA begangene Tat abgeurteilt werden, da die Voraussetzungen des § [7](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=7>) [II](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=7&x=2>) StGB erfullt sind. Die Tat war am Tatort mit Strafe bedroht, F war zur Zeit der Tat Auslander, befindet sich nun in Deutschland, und es wurde kein Auslieferungsgesuch gestellt.“

51Im Vergleich zu den anderen Ansatzen zeigte der dritte Promptingansatz bei den Subsumtionsaufgaben weniger Schwachen als bei den Auslegungsaufgaben. Dennoch waren die Subsumtionsergebnisse hier insbesondere im Strafrecht nicht zufriedenstellend. Ein Beispiel ist die fehlerhafte Bejahung der Strafbarkeit eines helfenden Freundes nach § [288](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=288>) StGB, obwohl ihm keine Zwangsvollstreckung drohte. Nach dem Wortlaut des § [288](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=288>) StGB kann H schon gar nicht Tater gem. § [288](<https://beck-online.beck.de/?typ=reference&y=100&g=STGB&p=288>) StGB sein. Dieser Ausfall zeigte sich zwar gleichfalls bei dem zweiten Promptingansatz, jedoch waren solche spezifischen Ungenauigkeiten haufiger im Rahmen des dritten Promptingansatzes zu bemerken.

52Der vierte Promptingansatz konnte auch bei den Subsumtionsaufgaben ein nahezu konstant gutes Level errei-

Dietrich: Auslegen und Subsumieren mit ChatGPT(NJW 2024, 2092)

chen. Dies zeigte sich darin, dass alle relevanten Tatbestandsvoraussetzungen berucksichtigt und detailliert gepruft wurden. Bei der Prufung, ob ein Sachmangel vorliegt, weil ein Ladekabel nach dem Kauf nicht mit dem vor Vertragsschluss angegebenen Laptopmodell kompatibel war, fuhrte ChatGPT mit diesem Promptingansatz am prazisesten aus: „(…) Auf Grundlage der durchgefuhrten Subsumtion unter § [434](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=434>) BGB liegt im vorliegenden Fall ein Sachmangel vor, da das Ladekabel nicht fur die spezifisch vorausgesetzte Verwendung, das Laden des Laptops Typ wz3, geeignet ist. Diese Feststellung beruht auf den subjektiven Anforderungen nach § [434](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=434>) [II](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=434&x=2>) Nr. [2](<https://beck-online.beck.de/?typ=reference&y=100&g=BGB&p=434&x=2&n=2>) BGB.“

### IX. Fazit

53ChatGPT zeigte in dem umfassenden Leistungstest sowohl Hohen als auch Tiefen. Es fehlte daher ingesamt an konstant uberzeugenden Antworten. Um die Konstanz zu steigern, bietet sich insbesondere der vierte Promtingansatz an, in dem Custom Instructions und umfangreiche Prompts verwendet wurden. Bei diesem Ansatz kam es in dem durchgefuhrten Leistungstest selten zu ganzlich unverwertbaren Antworten. Denn mithilfe dieses Ansatzes ist es moglich, dem System eine klare Arbeitsweise vorzugeben und es dazu zu bringen durch mehrere Eingabeschritte die Ausgangsfrage detaillierter und durchdachter zu beantworten.

54Es bleibt spannend, abzuwarten, ob die kommende Version des KI-Sprachmodells ChatGPT verbesserte Auslegungs- und Subsumtionsfahigkeiten erhalt. Fur Brainstormingeinsatze, um etwa Argumente fur eine bestimmte Auslegungs- oder Gesetzesanwendung zu erhalten, bietet sich das System jedoch schon jetzt sehr gut an.

  


<https://chatgpt.com/g/g-fPNTKL0ni-subsumptions-bot>
