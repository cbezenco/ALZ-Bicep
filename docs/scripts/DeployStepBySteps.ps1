# global parameter
[bool] $varTelemetryOptOut = 0
$varDeplRegion = "westeurope"
$varTopLevelMGPrefix = "LAB"
$varManagementSubscriptionId = "be8567b7-fd32-478f-ada5-2df8958c3d55"
$varConnectivitySubscriptionId = "91bb19d8-d81c-47fc-ad7d-0b67d426dc39"
$varIdentitySubscriptionId = "227ce446-6000-4aa8-8a27-e28856d07c37"
$varLZ01SubscriptionId = "ad114725-fe05-4c26-93ad-7732249ed6b5"
$varTags = @{CostCenter="ESLZ";Env="Prod"}

# var 1.ManagementGroups
$varTopLevelManagementGroupPrefix = $varTopLevelMGPrefix
$varTopLevelManagementGroupDisplayName = $varTopLevelManagementGroupPrefix

# var 2.Custom Policy Definitions

# var 3.Custom Role Definitions
$varAssignableScopeManagementGroupId = $varTopLevelMGPrefix

# var 4. Logging & Sentinel
$varManagementRG = "rg-"+$varTopLevelMGPrefix+"-logging" 
$varLogAnalyticsWorkspaceName = "law-"+$varTopLevelMGPrefix+"-eslz"
$varLogAnalyticsWorkspaceLocation = $varDeplRegion
[System.Int32] $varLogAnalyticsWorkspaceLogRetentionInDays = "30"
$varLogAnalyticsWorkspaceSolutions = @("AgentHealthAssessment","AntiMalware","AzureActivity","ChangeTracking","Security","SecurityInsights","ServiceMap","SQLAssessment","Updates","VMInsights")
$varAutomationAccountName = "aa-"+$varTopLevelMGPrefix+"-eslz"
$varAutomationAccountLocation = $varDeplRegion


# var 5. Hub Networking
$varConnectionRG = "rg-"+$varTopLevelMGPrefix+"-hub"
[bool] $varBastionEnabled = 1
[bool] $varDdosEnabled = 1
[bool] $varAzureFirewallEnabled = 1
[bool] $varPrivateDNSZonesEnabled = 1
$varDdosPlanName = $varTopLevelMGPrefix.ToLower()+"-ddos-plan" 
$varBastionName = $varTopLevelMGPrefix+"-bastion" 
$varBastionSku = "Standard"
$varPublicIPSku = "Standard"
$varHubNetworkAddressPrefix = "10.20.0.0/16"
$varHubNetworkName = $varTopLevelMGPrefix+"-hub-"+$varDeplRegion
$varAzureFirewallName = $varTopLevelMGPrefix+"-fw"
$varAzureFirewallTier = "Standard"
$varHubRouteTableName = $varTopLevelMGPrefix+"-hub-routetable"
$varDNSServerIPArray = @("10.20.1.15","192.168.2.200")
[bool] $varNetworkDNSEnableProxy = 1
[bool] $varDisableBGPRoutePropagation = 0

# var 6. Role Assignments for Management Groups & Subscriptions

# var 7. Subscription Placement
# parSubscriptionIds
# parTargetManagementGroupId

# 8. ALZ Default Policy Assignments
# parTopLevelManagementGroupPrefix
# parLogAnalyticsWorkSpaceAndAutomationAccountLocation
# parLogAnalyticsWorkspaceResourceID
# parLogAnalyticsWorkspaceLogRetentionInDays
# parAutomationAccountName
# parMSDFCEmailSecurityContact
# parDdosProtectionPlanId


# 1. ManagementGroups
New-AzTenantDeployment `
  -TemplateFile infra-as-code/bicep/modules/managementGroups/managementGroups.bicep `
  -TemplateParameterFile infra-as-code/bicep/modules/managementGroups/managementGroups.parameters.json `
  -parTopLevelManagementGroupPrefix $varTopLevelManagementGroupPrefix `
  -parTopLevelManagementGroupDisplayName $varTopLevelManagementGroupDisplayName `
  -parTelemetryOptOut $varTelemetryOptOut `
  -Location $varDeplRegion

# 2. Custom Policy Definitions
New-AzManagementGroupDeployment `
  -TemplateFile infra-as-code/bicep/modules/policy/definitions/custom-policy-definitions.bicep `
  -parTargetManagementGroupID $varTopLevelManagementGroupPrefix `
  -parTelemetryOptOut $varTelemetryOptOut `
  -Location $varDeplRegion `
  -ManagementGroupId $varTopLevelMGPrefix

# 3. Custom Role Definitions
New-AzManagementGroupDeployment `
  -TemplateFile infra-as-code/bicep/modules/customRoleDefinitions/customRoleDefinitions.bicep `
  -parAssignableScopeManagementGroupId $varAssignableScopeManagementGroupId `
  -parTelemetryOptOut $varTelemetryOptOut `
  -Location $varDeplRegion `
  -ManagementGroupId $varTopLevelMGPrefix

# 4. Logging & Sentinel

Select-AzSubscription -SubscriptionId $varManagementSubscriptionId

# Create Resource Group - optional when using an existing resource group
New-AzResourceGroup `
  -Name $varManagementRG `
  -Location $varDeplRegion

New-AzResourceGroupDeployment `
  -TemplateFile infra-as-code/bicep/modules/logging/logging.bicep `
  -parLogAnalyticsWorkspaceName $varLogAnalyticsWorkspaceName `
  -parLogAnalyticsWorkspaceLocation $varLogAnalyticsWorkspaceLocation `
  -parLogAnalyticsWorkspaceLogRetentionInDays $varLogAnalyticsWorkspaceLogRetentionInDays `
  -parLogAnalyticsWorkspaceSolutions $varLogAnalyticsWorkspaceSolutions `
  -parAutomationAccountName $varAutomationAccountName `
  -parAutomationAccountLocation $varAutomationAccountLocation `
  -parTags $varTags `
  -ResourceGroup $varManagementRG 

# 5. Hub Networking working with -parDDoSEnabled bug

Select-AzSubscription -SubscriptionId $varConnectivitySubscriptionId

New-AzResourceGroup `
  -Name $varConnectionRG `
  -Location $varDeplRegion

New-AzResourceGroupDeployment `
  -TemplateFile infra-as-code/bicep/modules/hubNetworking/hubNetworking.bicep `
  -TemplateParameterFile infra-as-code/bicep/modules/hubNetworking/hubNetworking.parameters.example.json `
  -parLocation $varDeplRegion `
  -parBastionEnabled $varBastionEnabled `
  -parDDoSEnabled $varDdosEnabled `
  -parAzureFirewallEnabled $varAzureFirewallEnabled `
  -parPrivateDNSZonesEnabled $varPrivateDNSZonesEnabled `
  -parCompanyPrefix $varTopLevelMGPrefix `
  -parDDoSPlanName $varDdosPlanName `
  -parBastionName $varBastionName `
  -parBastionSku $varBastionSku `
  -parPublicIPSku $varPublicIPSku `
  -parTags $varTags `
  -parHubNetworkAddressPrefix $varHubNetworkAddressPrefix `
  -parHubNetworkName $varHubNetworkName `
  -parAzureFirewallName $varAzureFirewallName `
  -parAzureFirewallTier $varAzureFirewallTier `
  -parHubRouteTableName $varHubRouteTableName `
  -parDNSServerIPArray $varDNSServerIPArray `
  -parNetworkDNSEnableProxy $varNetworkDNSEnableProxy `
  -parDisableBGPRoutePropagation $varDisableBGPRoutePropagation `
  -ResourceGroupName $varConnectionRG

  # 6 Role Assignments

  # 7 Subscription Placement
  
  New-AzManagementGroupDeployment `
  -TemplateFile infra-as-code/bicep/modules/subscriptionPlacement/subscriptionPlacement.bicep `
  -parSubscriptionIds @($varManagementSubscriptionId) `
  -parTargetManagementGroupId "LAB-platform-management"`
  -Location $varDeplRegion `
  -ManagementGroupId $varTopLevelMGPrefix

  New-AzManagementGroupDeployment `
  -TemplateFile infra-as-code/bicep/modules/subscriptionPlacement/subscriptionPlacement.bicep `
  -parSubscriptionIds @($varConnectivitySubscriptionId) `
  -parTargetManagementGroupId "LAB-platform-connectivity"`
  -Location $varDeplRegion `
  -ManagementGroupId $varTopLevelMGPrefix

  New-AzManagementGroupDeployment `
  -TemplateFile infra-as-code/bicep/modules/subscriptionPlacement/subscriptionPlacement.bicep `
  -parSubscriptionIds @($varIdentitySubscriptionId) `
  -parTargetManagementGroupId "LAB-platform-identity"`
  -Location $varDeplRegion `
  -ManagementGroupId $varTopLevelMGPrefix

  New-AzManagementGroupDeployment `
  -TemplateFile infra-as-code/bicep/modules/subscriptionPlacement/subscriptionPlacement.bicep `
  -parSubscriptionIds @($varLZ01SubscriptionId) `
  -parTargetManagementGroupId "LAB-landingzones-online"`
  -Location $varDeplRegion `
  -ManagementGroupId $varTopLevelMGPrefix

  # 8. ALZ Default Policy Assignments

  New-AzManagementGroupDeployment `
  -TemplateFile infra-as-code/bicep/modules/policy/assignments/alzDefaults/alzDefaultPolicyAssignments.bicep `
  -TemplateParameterFile infra-as-code/bicep/modules/policy/assignments/alzDefaults/alzDefaultPolicyAssignments.parameters.example.json `
  -parTopLevelManagementGroupPrefix $varTopLevelMGPrefix `
  -parLogAnalyticsWorkSpaceAndAutomationAccountLocation $varDeplRegion `
  -parLogAnalyticsWorkspaceResourceID "/subscriptions/be8567b7-fd32-478f-ada5-2df8958c3d55/resourcegroups/rg-lab-logging/providers/microsoft.operationalinsights/workspaces/law-lab-eslz" `
  -parLogAnalyticsWorkspaceLogRetentionInDays 30 `
  -parAutomationAccountName "aa-LAB-eslz" `
  -parMSDFCEmailSecurityContact "root@lab.bezencon.net"`
  -parDdosProtectionPlanId ""`
  -Location $varDeplRegion `
  -ManagementGroupId $varTopLevelMGPrefix


  