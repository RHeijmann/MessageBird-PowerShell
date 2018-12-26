#######################################################
# MessageBird Group Exporteren, v1.0                  #
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
$MessageBird_Accesskey = "1234567890ABDFSFAFWA"
$MessageBird_GroupID = "1234567890aadf"


#######################################
#######################################

#Haal de datum op. En sla deze op.
$Datum = (((get-date).ToUniversalTime()).ToString("yyyy-MM-dd"))
New-Item "MessageBird;_Alle-Contacten-van_$MessageBird_GroupID-$Datum.csv" -ItemType file

#Contacten ophalen. Controleert ook of dit lukt
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
		$Contact_MobilePhone = $x.items.Get($Huidig_Contact).msisdn
		$Contact_FirstName = $x.items.Get($Huidig_Contact).firstName
		$Contact_LastName = $x.items.Get($Huidig_Contact).lastName

		"{0},{1},{2}" -f $Contact_FirstName,$Contact_LastName,$Contact_MobilePhone | add-content -path "MessageBird;_Alle-Contacten-van_$MessageBird_GroupID-$Datum.csv"

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
