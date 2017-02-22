$servers = Get-ADComputer -Filter * -Searchbase "OU=Servers,DC=foo,DC=bar" | Sort Name

$output = "C:\1-Misc\AllServices.csv"

Add-Content $output "Service,Server,Account,Status"

foreach ($server in $servers)
{
    $server.Name
    $services = Get-WmiObject win32_service -ComputerName $server.Name | Select name,startname,startmode
    foreach ($service in $services)
    {
        Add-Content $output "$($service.name),$($server.Name),$($service.startname),$($service.startmode)"
    }

}