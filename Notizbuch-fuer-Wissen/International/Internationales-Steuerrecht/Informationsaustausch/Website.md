# Website

Einstellen des Buchskriptes,

  


Zugang nur nach Anmeldung

  
  


abgeschlossenen Bereich fur Kunden einrichten

  
Eingefugt aus <<https://www.netz-gaenger.de/blog/wordpress-tutorials/kundenbereich-in-wordpress-einrichten/>>   


Ziel

Ich mochte eine WordPress-Website, die nur berechtigte Personen, also meine Freunde und meine Familie sehen durfen. Meine Besucher sollen sich hierfur selbst registrieren und ihre Profildaten wie Name und Passwort verwalten durfen. Die Freischaltung der Registrierung erfolgt manuell durch mich. Des Weiteren mochte ich alle RSS-Feeds deaktivieren, da diese sich naturlich nicht durch ein Passwort schutzen lassen und von Suchmaschinen gelesen werden konnen.

Losung

Folgende 2 WordPress-Plugins nutze ich, um den Blog vor neugierigen Blicken abzuschotten und fur meine Besucher zu optimieren:

  * [Absolute Privacy](<https://wordpress.org/plugins/absolute-privacy/>): Dieses Plugin macht die komplette Website nur registrierten Benutzern zuganglich und wickelt die Registrierungsprozedur ab (Nachricht an Admin, Bestatigung an Besucher nach Freigabe usw.) Außerdem lasst sich mit diesem Plugin der RSS-Feed deaktivieren.
  * [Peter’s Login Redirect](<https://wordpress.org/plugins/peters-login-redirect/>): Mit diesem Plugin lasst sich festlegen, welche Benutzer oder Benutzergruppen nach dem Login auf welche Seite weitergeleitet werden sollen. Sinnvoll ist, Besucher nach dem Login direkt auf die Startseite weiterzuleiten statt ihnen das (leere) Dashboard anzuzeigen.



Erweiterung

Als zusatzliche Maßnahme empfiehlt es sich, zu verhindern, dass hochgeladene Dateien uber den Direktlink (z.B. domain.de/wp-content/uploads/datei-xyz.jpg) von einem nicht autorisierten Benutzer aufgerufen oder gar in einer anderen Website eingebettet werden konnen (sog. Hotlinking). Alle hochgeladenen Dateien sind namlich nach Einrichtung der o.g. Plugins weiterhin verfugbar, nur Beitrage und Seiten sind geschutzt!

  
Eingefugt aus <<https://pabstwp.de/blog/private-wordpress-website-mit-registrierung/>>
