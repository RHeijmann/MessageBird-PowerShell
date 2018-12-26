#######################################################
# GroupID achterhalen, v1.0                           #
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
$MessageBird_GroupNaam = "Extern-IT"


#######################################
#######################################

#Haal de datum op. En sla deze op.

#Contacten ophalen. Controleert ook of dit lukt
try {
	$response_volledig = Invoke-WebRequest -Uri https://rest.messagebird.com/groups/ -Headers @{"Authorization"="AccessKey $MessageBird_Accesskey"} -Method GET
	$response = $response_volledig.Content

} 
# Vang het JSON bericht van MessageBird op en gebruik deze om de foutmelding uit te halen.
catch { $response =
$_.ErrorDetails.Message}

# Lees de inhoud van $response als JSON in. Zodat de waardes van de inhoud gemakkelijk benaderbaar zijn.
$x = $response | ConvertFrom-Json

#Testen of het verzoek geslaagd is. Zo ja, loop ieder contact na en vul zijn/haar gegevens in een .csv.
If ($x.count -gt 0) { 
	$Aantal_Groups = $x.items.Count

	#De contacten lijst van MessageBird begint bij 0. Niet bij 1.
	$Huidige_Group = 0

	While ($Huidige_Group -lt $Aantal_Groups)  {
		$GroupID = $x.items.Get($Huidige_Group).id
		$GroupName = $x.items.Get($Huidige_Group).name

		If ($GroupName -eq $MessageBird_GroupNaam) {
			Write-Host "SUCCESS: Group $GroupName heeft het ID: $GroupID"
			exit
		}
		Else {
			$Huidige_Group++
		}
	}
}

#Geen foutmelding en ook geen bericht of het goed gegaan is.
Else {
	Write-Host("ERROR: Er kon geen group gevonden worden met deze naam.")
}