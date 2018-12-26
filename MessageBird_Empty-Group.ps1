#######################################################
# SMS-versturen naar group met MessageBird, v1.0      #
# - Door: Rik Heijmann                                #
# - Voor: Extern-IT (Extern-IT.nl), The Netherlands   #
# - Datum: 18-5-2018                                  #
#######################################################

#################### Belangrijk!
#Voordat dit script gebruikt, moet er binnen Internet Explorer gekozen worden of de standaard instellingen gebruikt moeten worden.


#################### Instructie
# 1. Stel de onderstaande instellingen in,
# 2. Voer dit script uit.

#################### MessageBird instellingen
$MessageBird_Accesskey = "1234567890ABDCGSFW@213"
$MessageBird_GroupID = "1234567890djsndad"


#######################################
#######################################


#Leeg de Group
try {
	$response_volledig = Invoke-WebRequest -Uri https://rest.messagebird.com/groups/$MessageBird_GroupID/contacts -Headers @{"Authorization"="AccessKey $MessageBird_Accesskey"} -Method GET
	$response = $response_volledig.Content

} 
# Vang het JSON bericht van MessageBird op en gebruik deze om de foutmelding uit te halen.
catch { $response =
$_.ErrorDetails.Message}

# Lees de inhoud van $response als JSON in. Zodat de waardes van de inhoud gemakkelijk benaderbaar zijn.
$x = $response | ConvertFrom-Json

#Testen of het verzoek geslaagd is. Zo ja, loop ieder contact na en vul zijn/haar gegevens in een .csv.
If ($x.count -gt 0) { 
	$Aantal_Contacten = $x.items.Count

	#De contacten lijst van MessageBird begint bij 0. Niet bij 1.
	$Huidig_Contact = 0

	while ($Huidig_Contact -lt $Aantal_Contacten)  {
		$Contact_ID = $x.items.Get($Huidig_Contact).id

		try {
			$response_volledig = Invoke-WebRequest -Uri https://rest.messagebird.com/groups/$MessageBird_GroupID/contacts/$Contact_ID -Headers @{"Authorization"="AccessKey $MessageBird_Accesskey"} -Method DELETE
			$response = $response_volledig.Content

		}
		# Vang het JSON bericht van MessageBird op en gebruik deze om de foutmelding uit te halen.
		catch { $response =
		$_.ErrorDetails.Message}

		$Huidig_Contact++
	}
}

ElseIf ($x.count -eq 0) {
	Write-Host("SUCCESS: In deze group zitten geen contacten.")
}


#Geen foutmelding en ook geen bericht of het goed gegaan is.
Else {
	Write-Host("ERROR: Er ging iets mis, klopt het Group-id?")
}
