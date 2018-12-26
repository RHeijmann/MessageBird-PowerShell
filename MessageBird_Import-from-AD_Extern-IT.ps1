Import-Module ActiveDirectory

#######################################################
# Synchronisatie tool voor AD Naar MessageBird v1.0   #
# - Door: Rik Heijmann & Bas Gubbels                  #
# - Voor: Extern-IT (Extern-IT.nl), The Netherlands   #
# - Datum: 18-5-2018                                  #
#######################################################

#################### Belangrijk!
#Voordat dit script gebruikt, moet er binnen Internet Explorer gekozen worden of de standaard instellingen gebruikt moeten worden.
#
#De Contact_MobilePhone waarde dient als volgt opgebouwd te zijn: "landcode" + "6" + "mobielnummer"
#Bijvoorbeeld: 31658584737
#In onze AD's wordt het opgeslagen als +31658584737. Het script zal het + karakter weghalen.


#################### Instructie
# 1. Stel de onderstaande instellingen in,
# 2. Voer dit script uit op een Active Directory Domain-Controller als Domain Admin.


#################### MessageBird instellingen
$MessageBird_Accesskey = "1234567890ABDCGSFW@213"
$MessageBird_GroupID = "1234567890djsndad"

#################### ActiveDirectory instellingen
$AD_OU = "OU=Users,DC=ad,DC=contozo,DC=com"

#################### Voor statistiek
$Folder = "C:\MessageBird"


#######################################
#######################################

$Rapport_Toegevoegd = 0
New-Item $Folder\Toegevoegd.csv -ItemType file -Force

$Rapport_Nummerstaatverkeerd = 0
New-Item $Folder\Nummerstaatverkeerd.csv -ItemType file -Force

$Rapport_Onbekendefout = 0
New-Item $Folder\Onbekendefout.csv -ItemType file -Force

$Rapport_TotaalAanwezig = 0

# Schoon de $users variabele op.
$users = $null  

#Leeg de Group
try 
{
	$response_volledig = Invoke-WebRequest -Uri https://rest.messagebird.com/groups/$MessageBird_GroupID/contacts -Headers @{"Authorization"="AccessKey $MessageBird_Accesskey"} -Method GET
	$response = $response_volledig.Content

} 
# Vang het JSON bericht van MessageBird op en gebruik deze om de foutmelding uit te halen.
catch 
{ 
$response = $_.ErrorDetails.Message
}

# Lees de inhoud van $response als JSON in. Zodat de waardes van de inhoud gemakkelijk benaderbaar zijn.
$x = $response | ConvertFrom-Json

#Testen of het verzoek geslaagd is. Zo ja, loop ieder contact na en vul zijn/haar gegevens in een .csv.
If ($x.count -gt 0) { 
	$Aantal_Contacten = $x.items.Count

	#De contacten lijst van MessageBird begint bij 0. Niet bij 1.
	$Huidig_Contact = 0

	While ($Huidig_Contact -lt $Aantal_Contacten)  {
		$Contact_ID = $x.items.Get($Huidig_Contact).id

		try 
        {
			$response_volledig = Invoke-WebRequest -Uri https://rest.messagebird.com/contacts/$Contact_ID -Headers @{"Authorization"="AccessKey $MessageBird_Accesskey"} -Method DELETE
			$response = $response_volledig.Content
		}
		# Vang het JSON bericht van MessageBird op en gebruik deze om de foutmelding uit te halen.
		catch 
        {
        $response =	$_.ErrorDetails.Message
        }

		$Huidig_Contact++
	}
}

ElseIf ($x.count -eq 0) 
{
	Write-Host("SUCCESS: In deze group zitten geen contacten.")
}

#Geen foutmelding en ook geen bericht of het goed gegaan is.
Else 
{
	Write-Host("ERROR: Er ging iets mis, klopt het Group-id?")
exit
}

#Doe per user het script uitvoeren:

Get-ADUser -SearchBase "$AD_OU" -filter * -properties * | Select-Object MobilePhone, Surname, Givenname | Export-Csv -Path $Folder\UserInfo.csv -NoTypeInformation
$users = Import-csv $Folder\UserInfo.csv -delimiter "," 

$user = 0


While ($user -lt $users.Count)  {

	$Contact_MobilePhone = $users.Get($user).MobilePhone
	$Contact_FirstName = $users.Get($user).Givenname
	$Contact_LastName = $users.Get($user).Surname

#	$Contact_MobilePhone = "+31612345678"
#	$Contact_FirstName = "Rik"
#	$Contact_LastName = "Heijmann"

	#Verwijder het + karakter en sla de variabele gewijzigd op.
	$Contact_MobilePhone = $Contact_MobilePhone -replace '[+]',''

	#Controleer of de gebruiker nog niet is toegevoegd.

	# Voeg de gebruiker toe, en vang de gebruikergegevens op voor later gebruik.
	try 
	{
		$response_volledig = Invoke-WebRequest -Uri https://rest.messagebird.com/contacts -Headers @{"Authorization"="AccessKey $MessageBird_Accesskey"} -Method POST -Body @{
    		msisdn=$Contact_MobilePhone
    		firstName=$Contact_FirstName
    		lastName=$Contact_LastName
           }
		$response = $response_volledig.Content
	} 
	catch 
	{
		$response = $_.ErrorDetails.Message
	}

	# Lees de inhoud van $response als JSON in. Zodat de waardes van de inhoud gemakkelijk benaderbaar zijn.
	$z = $response | ConvertFrom-Json

	#Testen of er een ID is. Zo niet dan bestaat de gebruiker al.
	If ($z.id) 
	{
		$MessageBird_UserID = $z.id

		#	Invoke-WebRequest -Uri https://rest.messagebird.com/groups/$MessageBird_GroupID/contacts -Headers @{"Authorization"="AccessKey $MessageBird_Accesskey"} -Method PUT -Body @{
		#   ids=($MessageBird_UserID)
		#	}

		#	#Laat de gebruiker weten dat wij grote storingen per SMS doorgeven:
		#	Invoke-WebRequest -Uri https://rest.messagebird.com/messages -Headers @{"Authorization"="$MessageBird_Accesskey"} -Method POST -Body @{
		#		recipients=$Contact_MobilePhone
		#		originator="Extern-IT"
		#		body="Welkom bij Extern-IT! Wij zullen u voortaan SMS'matisch op de hoogte houden van storingen!"
		#	}

        .\Benodigd\cURL\curl.exe -X PUT https://rest.messagebird.com/groups/$MessageBird_GroupID/contacts -H 'Authorization: AccessKey kjI09Jm99M34ZrvuNb00j5ZuQ' -d "ids[]=$MessageBird_UserID"


		"{0},{1},{2}" -f $Contact_FirstName,$Contact_LastName,$Contact_MobilePhone | add-content -path $Folder\Toegevoegd.csv
		++$Rapport_Toegevoegd
	}

	ElseIf ($z.errors.Get(0).description="msisdn is invalid") 
	{
		"{0},{1},{2}" -f $Contact_FirstName,$Contact_LastName,$Contact_MobilePhone | add-content -path $Folder\Nummerstaatverkeerd.csv
		++$Rapport_Nummerstaatverkeerd
	}

	Else 
	{

		"{0},{1},{2}" -f $Contact_FirstName,$Contact_LastName,$Contact_MobilePhone | add-content -path $Folder\Onbekendefout.csv
		++$Rapport_Onbekendefout

	}

    ++$user
}

#Simpele spellingscorrecties voorde conclusie. Indien meer dan 1 voeg "en" toe aan bepaalde woorden.
$mv1 = $null
If ($Rapport_Toegevoegd -ne 1) { $mv1 = "en" };

$mv21 = $null
$mv22 = $null
If ($Rapport_Nummerstaatverkeerd -ne 1) { $mv21 = "e"; $mv22 = "s" };

$mv3 = "is"
If ($Rapport_Onbekendefout -ne 1) { $mv3 = "zijn" };

Remove-Item $Folder\UserInfo.csv

Pause
Write-Host "FINISH! $Rapport_Toegevoegd contact$mv1 toegevoegd, $Rapport_Nummerstaatverkeerd verkeerd ingevoerd$mv21 nummer$mv22, $Rapport_Onbekendefout $mv3 er fout gegaan."