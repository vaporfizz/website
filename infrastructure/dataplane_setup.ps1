[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]
    $Environment,
    [Parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName
)

Connect-AzAccount
$storageAccount = Get-AzStorageAccount -Name stvfizzweb$Environment -ResourceGroupName $ResourceGroupName
Enable-AzStorageStaticWebsite -Context $storageAccount.Context -IndexDocument "index.html"
