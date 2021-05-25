param environment string
param slot string
param agwId string
param aksSubnetId string

var aksName = 'iac-${environment}-${slot}-aks'

resource aks 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  location: resourceGroup().location
  name: aksName
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: aksName
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      networkPolicy: 'calico'
    }
    // Need to uncomment this at first because the validation checks for the resource id
    // Also need to consider manual handling of managed identity and role assignment. -> do it with cli instead
    //addonProfiles: {
    //  ingressApplicationGateway: {
    //    config: {
    //      applicationGatewayId: agwId
    //    }
    //    enabled: true
    //  }
    //}
    agentPoolProfiles: [
      {
        name: 'system'
        count: 1
        vmSize: 'Standard_D4_v3'
        mode: 'System'
        vnetSubnetID: aksSubnetId
      }
    ]
  }
}
