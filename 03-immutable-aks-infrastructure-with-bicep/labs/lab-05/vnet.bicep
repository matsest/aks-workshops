param environment string = 'dev'
param slot string = 'blue'
param vnetAddressPrefix string
param aksSubnetAddressPrefix string
param agwSubnetAddressPrefix string
param aksNsgName string

var vnetName = 'iac-${environment}-${slot}-vnet'

resource aksNsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' existing = {
  name: aksNsgName
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  location: resourceGroup().location
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'aks'
        properties: {
          addressPrefix: aksSubnetAddressPrefix
          networkSecurityGroup: {
            id: aksNsg.id
          }
        }
      }
      {
        name: 'agw'
        properties: {
          addressPrefix: agwSubnetAddressPrefix
        }
      }
    ]
  }
}

// Hack to easily get subnet resources from vnet parent, even though we are in the same template
resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: 'aks'
  parent: vnet
}

resource agwSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: 'agw'
  parent: vnet
}

output aksSubnetId string = aksSubnet.id
output agwSubnetId string = agwSubnet.id
