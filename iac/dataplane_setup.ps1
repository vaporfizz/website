# Sets up the Azure data plane after control plane deployment
param (
    [Parameter(Mandatory=$true)]
    [String]
    $Environment,
    [Parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName
)

Connect-AzAccount -Identity
$storageAccount = Get-AzStorageAccount -Name stvfizzweb$Environment -ResourceGroupName $ResourceGroupName
Enable-AzStorageStaticWebsite -Context $storageAccount.Context -IndexDocument "index.html"
