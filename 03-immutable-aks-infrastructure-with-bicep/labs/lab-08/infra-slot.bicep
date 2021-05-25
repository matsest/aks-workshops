targetScope = 'subscription'

// RG to deploy to
param rgName string = 'iac-dev-blue-rg'

// Environment
param environment string = 'dev'
param slot string = 'blue'
param vnetAddressPrefixBase string = '10.10'

// Optional
param uniqueName string = 'mxe'
param timeStamp string = utcNow('ddMMyyyyhhmmss')

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: rgName
}

module vnet 'vnet.bicep' = {
  name: 'vnet'
  scope: rg
  params: {
    environment: environment
    slot: slot
    vnetAddressPrefixBase: vnetAddressPrefixBase
  }
}

module agw 'agw.bicep' = {
  name: 'agw'
  scope: rg
  params: {
    environment: environment
    slot: slot
    uniqueName: uniqueName
    agwSubnetId: vnet.outputs.agwSubnetId
  }
}

module aks 'aks.bicep' = {
  name: 'aks'
  scope: rg
  params:{
    environment: environment
    slot: slot
    agwId: agw.outputs.agwId
    aksSubnetId: vnet.outputs.aksSubnetId
  }
}
