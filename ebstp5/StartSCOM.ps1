Add-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName "JBS-ITS-DEV" | Select-AzureRmSubscription

Start-AzureRmVM -ResourceGroupName ebstp5 -Name ebstp5dc
Start-AzureRmVM -ResourceGroupName ebstp5 -Name ebstp5sql1
Start-AzureRmVM -ResourceGroupName ebstp5 -Name ebstp5scom