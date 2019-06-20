#############################################################################################
# This script Disable Users with Expired Password 
# Also, script add descriprion "Disable by cleanup script + date"
# You can set monthly executing via Task Scheduler.
#
# Haim Cohen 02-28-2019
# Version 1.1
#############################################################################################

$logdate = Get-Date -format dd-MM-yyyy.csv
$logfile = "C:\AdminScripts\disable_users_report"
$exprusers = get-aduser -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress |where {$_.Enabled -eq "True"} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $true }
$exprusers | Disable-ADAccount
$exprusers | get-aduser  -Properties Description | ForEach-Object { Set-ADUser $_ -Description "Disabled by cleanup script $logdate.  $($_.Description)" }
$exprusers | Export-Csv -Path $logfile\Expired_Users_$logdate.csv
$css = @" 
<style>
h1, h5, th { text-align: center; font-family: Segoe UI; }
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; }
td { font-size: 11px; padding: 5px 20px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
"@

Import-CSV $logfile\Expired_Users_$logdate.csv -Delimiter ',' | ConvertTo-Html -Head $css -Body "<h1>Expired Password Users Report</h1>`n<h5>Haim Cohen | Generated on $(Get-Date)</h5>" | Out-File $logfile\Expired_Users_$logdate.html
$htmlreport = Get-Item $logfile\Expired_Users_$logdate.html
$status = $exprusers.count

# mail to admin if 

If ($status -gt 0) {
  $smtp = "YOUR SMTP SERVER"
  $to = "ADMIN01@MAIL; ADMIN02@MAIL"
  $from = "AD-Cleanup@MY.ORG"
  $subject = "users that disables"
  $body = "Dear Admin,`nAttached a report of Domain users that disabled by cleanup script.`n`nScript powered by PowerShell, Dev by Haim Cohen 2019."
  $Attch = $htmlreport
  Send-MailMessage -smtp $smtp -to $to -from $from -subject $subject -body $body -Attachments $Attch 

  }  Else {
  echo "$((Get-Date).ToString('MM-dd-yyyy HH:mm')): Users with Expired Password Not Found" > $logfile\Expired_Users_$logdate.csv.csv
  exit
 } 

