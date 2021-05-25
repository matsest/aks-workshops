var vnetAddressPrefix = '10.10.0.0/16'
var aksSubnetAddressPrefix = '10.10.0.0/20'
var agwSubnetAddressPrefix = '10.10.16.0/25'

resource aksNsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'iac-dev-blue-aks-nsg'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'deny-connection-from-agw'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Deny'
          description: 'Deny any connectivity from any VNets'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: aksSubnetAddressPrefix
          destinationPortRange: '*'
        }
      }
      {
        name: 'allow-connection-from-agw'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          description: 'Allow connectivity from agw subnet into aks subnet'
          protocol: 'Tcp'
          sourceAddressPrefix: agwSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: aksSubnetAddressPrefix
          destinationPortRange: '80'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  location: resourceGroup().location
  name: 'iac-dev-blue-vnet'
  dependsOn: [
    aksNsg // This is not necessary as the aksNsg.id is referred to
  ]
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

// These resources are also defined inline within the vnet resource.
resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: 'aks'
  dependsOn: [
    vnet // unnecessary as it is the parent?
  ]
  parent: vnet
  properties: {
    addressPrefix: aksSubnetAddressPrefix
    networkSecurityGroup: {
      id: aksNsg.id
    }
  }
}

resource agwSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: 'agw'
  dependsOn: [
    vnet
  ]
  parent: vnet
  properties: {
    addressPrefix: agwSubnetAddressPrefix
  }
}
