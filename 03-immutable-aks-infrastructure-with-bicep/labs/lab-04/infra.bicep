param environment string = 'dev'
param slot string = 'blue'
param vnetAddressPrefixBase string = '10.10'
var vnetAddressPrefix = '${vnetAddressPrefixBase}.0.0/16'
var aksSubnetAddressPrefix = '${vnetAddressPrefixBase}.0.0/20'
var agwSubnetAddressPrefix = '${vnetAddressPrefixBase}.16.0/25'

module nsg 'nsg.bicep' = {
  name: 'nsg'
  params: {
    agwSubnetAddressPrefix: agwSubnetAddressPrefix
    aksSubnetAddressPrefix: aksSubnetAddressPrefix
    environment: environment
    slot: slot
    vnetAddressPrefixBase: vnetAddressPrefixBase
  }
}

module vnet 'vnet.bicep' = {
  name: 'vnet'
  dependsOn: [
    nsg // not necessary?
  ]
  params: {
    vnetAddressPrefix: vnetAddressPrefix
    agwSubnetAddressPrefix: agwSubnetAddressPrefix
    aksSubnetAddressPrefix: aksSubnetAddressPrefix
    environment: environment
    slot: slot
    aksNsgName: nsg.outputs.aksNsgName
  }
}
