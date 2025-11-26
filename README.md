# debian-vpn-gateway


Es gibt viele überzeugende Gründe, einen eigenen Linux-Server als VPN 
zu betreiben, anstatt sich auf einen kommerzielle Anbieter zu verlassen. 
Hier ist eine perfekte Einführung, die die wichtigsten Vorteile hervorhebt:

# Warum einen eigenen Linux-Server ?

In einer Zeit, in der Bedenken hinsichtlich Datenschutz und Datensicherheit 
ständig zunehmen, suchen viele nach einfachen alternativen Wegen, ihre 
Online-Privatsphäre zu schützen. Kommerzielle VPN-Anbieter versprechen 
oftmals Anonymität und Sicherheit, doch die Realität sieht oftmals 
anders aus: Du musst darauf vertrauen, dass eine Firma oder eine Privatperson 
(VPN-Anbieter), dessen Geschäftsmodell auf der Verwaltung Deiner 
Daten basiert, Deine Privatsphäre wirklich respektiert und keine Protokolle 
führt  oder Deine Informationen an Werbefirmen verkauft.Dies war der 
wahre Grund weshalb Avast in den USA zu einer riesigen Geldstrafe
verurteil worden ist. Sie haben klangheimlich die VPN-Kundendaten gesammelt 
und ohne Skrupel an Fremdfirmen verkauft.

Die Entscheidung für einen eigenen, selbst gehosteten Linux-VPN-Server 
eliminiert dieses existierende Vertrauensproblem vollständig.

1.Vollständige Kontrolle und Vertrauen: Der größte Vorteil ist die
absolute Transparenz. Du weisst ganz genau, welche Software auf Deinem
Server läuft, wer darauf Zugriff hat und, am wichtigsten, dass keine 
Verbindungsprotokolle (Logs) erstellt oder gespeichert werden. Es gibt
keine "No-Logs-Richtlinie", der Du blind vertrauen musst, sondern eine
technische Garantie.

2.Keine Datenweitergabe an Dritte: Im Gegensatz zu kommerziellen VPN Diensten, 
die potenziell gehackt werden, Daten an Werbetreibende verkaufen oder auf 
rechtliche Anordnungen hin kooperieren könnten, bleiben Deine  Daten unter 
Deiner direkten Kontrolle. Du und Deine Mitbenutzer des Services  sind die 
einzigen Nutznießer und Du als Administrator der einzige Verantwortliche.

3.Optimierte Leistung und dedizierte Bandbreite: 
Dein VPN ist nicht überfüllt mit Tausenden von anderen Nutzern, die sich
eine Serverkapazität teilen. Du erhälst die volle, dedizierte Bandbreite
Deines gemieteten virtuellen Servers, was zu konsistenteren und oftmals 
schnelleren Verbindungsgeschwindigkeiten führt.

4.Maßgeschneiderte Konfiguration: 
Als Betreiber eines eigenen Linux-Servers kannst Du genau die Sicherheitsprotokolle 
(wie WireGuard oder OpenVPN) und andere Einstellungen wählen, die Deinen spezifischen 
Anforderungen entsprechen – ein Grad an Anpassung, den Dir kein kommerzieller Dienst 
anbieten kann.
 
Kurz gesagt: Ein selbst gehostetes VPN bietet maximale Sicherheit durch technische
Souveränität. Es verwandelt das Versprechen der digitalen Privatsphäre in eine
überprüfbare Realität. Während es ein gewisses technisches Grundwissen erfordert,
um es einzurichten und administrieren, ist die daraus resultierende Seelenfrieden – 
zu wissen, dass niemand ausser Dir Deine Daten sammelt – unbezahlbar.

## Die Entstehungsgeschichte dieser Scriptsammlung

Die Sammlung dieser Scripte entstand aus einer eher ungewöhnlichen, aber in der
IT-Welt nicht seltenen Situation heraus: Ein ehemaliger Kunde von mir zeigte
eine bemerkenswerte Loyalität gegenüber seiner Hardware. Er weigerte sich vehement,
seine über zwölf Jahre im Einsatz befindliche Firewall vom Typ Zyxel USG 100 
auszutauschen, obwohl diese Firewall längst das Ende ihres natürlichen Lebenszyklus
erreicht hatte und den modernen Sicherheitsanforderungen an einer modernen Firewall
kaum noch genügte. (Eigentlich gar nicht um ehrlich zu sein) 

Die eigentliche Herausforderung bestand darin, die Konnektivität und Sicherheit
seines Netzwerks zu gewährleisten, ohne die veraltete, aber vom Kunden geliebte 
"Asbach-Uralt-Version" der Firewall  ersetzen zu müssen. Um diese scheinbar
unmögliche Aufgabe zu lösen und moderne VPN-Verbindungen 
(konkret: IKEv2/IPsec und WireGuard) auf der betagten Hardware zu realisieren, 
war ich gezwungen, tief in die Materie einzutauchen und maßgeschneiderte Skripte
zu entwickeln, die das System quasi "überlisteten".

Diese Sammlung ist also das direkte Ergebnis dieser kreativen Problemlösung
im Umgang mit veralteter Infrastruktur und dem starken Willen eines Kunden,
an seiner bewährten Technik festzuhalten.

Der Schutz der digitalen Privatsphäre ist ein zentrales Anliegen in der heutigen 
digitalen vernetzten Welt. Viele Internetnutzer empfinden es als Eingriff in ihre
Grundrechte, wenn ihr Surfverhalten ohne ihre explizite Zustimmung von 
Internetanbietern (ISP), staatlichen Akteuren oder großen Technologieunternehmen
zu Überwachungs- und Kommerzzwecken analysiert wird. Wenn Du aktiv Maßnahmen ergreifen
möchtest, um Deine  Online-Identität zu schützen und der ständigen Überwachung zu 
entgehen, findest Du in den folgenden Dokumenten wertvolle Lösungsansätze.


### Was wird alles benötigt ? 

Bevor Du beginnst, die Kontrolle über Deine digitale Privatsphäre
zurückzugewinnen, solltest Du  sicherstellen, dass Du die notwendige
Infrastruktur und das erforderliche Wissen auch wirklich mitbringst.
Zunächst benötigst Du den Zugriff auf einen virtuellen privaten Server (VPS),
der das Debian-Betriebssystem in der Version 12 oder 13 unterstützt. Diese Server
sind heutzutage sehr erschwinglich; einfache Instanzen, die für diesen Zweck
vollkommen ausreichen, kosten oft nicht mehr als 5 Euro pro Monat. Darüber hinaus
sind Erfahrungen in der Handhabung der Linux-Kommandozeile unerlässlich. 
Die Einrichtung und Wartung erfordert die Navigation im Terminal, das Bearbeiten
von Konfigurationsdateien und das Ausführen von Befehlen.

### Strategische Wahl des Server-Standorts

Bei der Auswahl des Standorts für Deinen VPN-Server ist der
primäre Sicherheitsgedanke, einen Rechtsraum zu wählen, der nicht Deinem 
eigenen aktuellen Wohnsitz unterliegt und idealerweise strengere Datenschutzgesetze
bietet oder zumindest nicht dem Datenaustauschabkommen Deines Heimatlandes
unterliegt.


Für Nutzer aus der Schweiz:

Als Schweizer Bürger ist es ratsam, einen Server im Ausland zu mieten.
Standorte innerhalb der EU, wie beispielsweise Deutschland, sind eine solide Option.
Noch wessentlich vorteilhafter für die Privatsphäre wäre ein Standort außerhalb der
EU, wie das Vereinigte Königreich (UK), um sich von der EU-Rechtsprechung und den
dortigen Datenvorratsrichtlinien abzugrenzen.


Für Nutzer aus Deutschland:

Deutschen Nutzern wird wirklich dringend empfohlen, den Server nicht direkt in
Deutschland zu hosten. Eine exzellente Alternative wäre die Schweiz, die für ihre
robusten Datenschutzgesetze und ihre Neutralität bekannt ist. Der wirkliche Haken 
dabei: Die Hosting-Preise in der Schweiz können leider das Vier- bis Fünffache der
Kosten für einen vergleichbaren Server in Deutschland betragen.

Allgemeine Empfehlung:

Suche nach einem Standort, der ein gutes Gleichgewicht zwischen starkem
Datenschutzrecht (z.B. Island, Schweiz, oder Länder mit ähnlichen Garantien)
,Zuverlässigkeit des Anbieters und einen erschwinglichen Preisen bietet.



### Übliche und empfohlene Leistungsmerkmale eines VPS

Für den Betrieb eines reinen VPN-Servers benötigst Du keine 
Hochleistungshardware. Die Anforderungen sind relativ gering, 
da der Server hauptsächlich Datenpakete weiterleitet und keine
rechenintensiven Anwendungen hostet. Die folgenden Spezifikationen
sind typisch für einen kosteneffizienten und dennoch leistungsstarken
VPS in der Preisklasse von 3 bis 6 Euro pro Monat:


Technische Mindestanforderungen:

CPU: 
Eine Single-Core-CPU mit mindestens 1.6 GHz ist vollkommen
ausreichend.

Arbeitsspeicher (RAM): 
1 GB RAM ist das Minimum, 2 GB bieten komfortable Reserven
für das Betriebssystem und zusätzliche Dienste.

Festplattenspeicher: 
Eine 20 GB SSD (Solid State Drive) bietet mehr als genügend
Platz für das Betriebssystem Debian und alle notwendigen 
Konfigurationen.


Netzwerk:

1 dedizierte IPv4-Adresse: Unverzichtbar für die Erreichbarkeit
des Servers aus dem Internet.

1 Gbit/s Netzwerkschnittstelle: Stellt sicher, dass die 
physische Verbindung schnell genug ist.

Datenvolumen: 
Ein Inklusiv-Volumen von 2 bis 4 TB pro Monat. Dies reicht in
der Regel für den privaten Gebrauch aus, bei einigen Anbietern
sind mittlerweile auch unlimitierte Tarife üblich.


Wichtige administrative Merkmale:

Konsolenzugriff (KVM/VNC): Ein unverzichtbares Feature. 
Solltest Du dich durch eine fehlerhafte Firewall-Konfiguration oder
Netzwerk-Setup versehentlich via SSH aussperren, ermöglicht der
Konsolenzugriff die Fehlerbehebung direkt am "virtuellen Bildschirm"
des Servers.







 









