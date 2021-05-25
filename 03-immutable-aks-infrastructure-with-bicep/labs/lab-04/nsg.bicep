param environment string
param slot string
param vnetAddressPrefixBase string
param aksSubnetAddressPrefix string
param agwSubnetAddressPrefix string

var aksNsgName = 'iac-${environment}-${slot}-aks-nsg'

resource aksNsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: aksNsgName
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

output aksNsgId string = aksNsg.id
output aksNsgName string = aksNsg.name
