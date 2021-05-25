targetScope = 'subscription'

param environment string = 'dev'
param slot string = 'blue'
param timestamp string = utcNow('ddMMyyyyhhmmss')

param vnetAddressPrefixBase string = '10.10'
var vnetAddressPrefix = '${vnetAddressPrefixBase}.0.0/16'
var aksSubnetAddressPrefix = '${vnetAddressPrefixBase}.0.0/20'
var agwSubnetAddressPrefix = '${vnetAddressPrefixBase}.16.0/25'

resource baseRg 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: 'iac-${environment}-rg'
}

resource slotRg 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: 'iac-${environment}-${slot}-rg'
}

module nsg 'nsg.bicep' = {
  name: 'nsg-${timestamp}'
  scope: slotRg
  params: {
    agwSubnetAddressPrefix: agwSubnetAddressPrefix
    aksSubnetAddressPrefix: aksSubnetAddressPrefix
    environment: environment
    slot: slot
  }
}

module vnet 'vnet.bicep' = {
  name: 'vnet-${timestamp}'
  scope: slotRg
  dependsOn: [
    nsg
  ]
  params: {
    environment: environment
    slot: slot
    aksNsgName: nsg.outputs.aksNsgName
    agwSubnetAddressPrefix: agwSubnetAddressPrefix
    aksSubnetAddressPrefix: aksSubnetAddressPrefix
    vnetAddressPrefix: vnetAddressPrefix
  }
}
