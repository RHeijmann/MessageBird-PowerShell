#######################################################
# SMS-versturen naar group met MessageBird, v1.0      #
# - Door: Rik Heijmann                                #
# - Voor: Extern-IT (Extern-IT.nl), The Netherlands   #
# - Datum: 18-5-2018                                  #
#######################################################

#################### Belangrijk!
#Kost geld! 0,061 per SMS!
#Voordat dit script gebruikt, moet er binnen Internet Explorer gekozen worden of de standaard instellingen gebruikt moeten worden.


#################### Instructie
# 1. Stel de onderstaande instellingen in,
# 2. Voer dit script uit.

#################### MessageBird instellingen
$MessageBird_Accesskey = "1234567890ABDCGSFW@213"
$MessageBird_GroupID = "1234567890djsndad"

#################### SMS-bericht
$Van="Extern-IT"
#Tip! Maak gebruik van de variabelen: $Contact_LastName & $Contact_FirstName. Deze kun je in het bericht zetten om het iets persoonlijker te maker. Deze zullen zich per contact aanpassen.
$Bericht="Welkom bij Extern-IT! Wij zullen u voortaan SMS'matisch op de hoogte houden van storingen!"






























#######################################
#######################################


#Groups ophalen. Controleert ook of dit lukt
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

	While ($Huidig_Contact -lt $Aantal_Contacten)  {
		$Contact_MobilePhone = $x.items.Get($Huidig_Contact).msisdn
		$Contact_FirstName = $x.items.Get($Huidig_Contact).firstName
		$Contact_LastName = $x.items.Get($Huidig_Contact).lastName

		#Bericht verzenden!, Er wordt ook gecontroleerd of er een foutmelding optreed.
		try {
			$response_volledig = Invoke-WebRequest -Uri https://rest.messagebird.com/messages -Headers @{"Authorization"="AccessKey $MessageBird_Accesskey"} -Method POST -Body @{
				recipients=$msisdn
				originator="$Van"
				body="$Bericht"
			}

			$response = $response_volledig.Content
		} 
		# Vang het JSON bericht van MessageBird op en gebruik deze om de foutmelding uit te halen.
		catch { $response =
		$_.ErrorDetails.Message}

		# Lees de inhoud van $response als JSON in. Zodat de waardes van de inhoud gemakkelijk benaderbaar zijn.
		$x = $response | ConvertFrom-Json

		#Testen of er een ID is. Zo niet dan bestaat de gebruiker al.
		If ($x.id) { 
		Write-Host("SUCCESS: Bericht is verzonden!")
		}

		#Test op basis van de foutmelding of het account nog niet is toegevoegd.
		ElseIf ($x.description) {
			If ($x.description="no (correct) recipients found") {
				Write-Host("ERROR: Het mobiele nummer klopt niet of is niet in het juiste formaat")
			}

			#Onbekende foutmelding.
			Else {
				Write-Host("ERROR: Er ging iets mis. Deze foutmelding is nog niet bekend. En een oplossing is nog niet verwerkd in dit script.")
			}
		}

		#Geen foutmelding en ook geen bericht of het goed gegaan is.
		Else {
			Write-Host("ERROR: Er ging iets mis.")
		}

		$Huidig_Contact++
	}
}

ElseIf ($x.count -eq 0) {
	Write-Host("ERROR: In deze group zitten geen contacten.")
}

#Geen foutmelding en ook geen bericht of het goed gegaan is.
Else {
	Write-Host("ERROR: Er ging iets mis, klopt het Group-id?")
}