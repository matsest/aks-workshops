var uniqueName = 'mxe'

var environment = 'dev'
var slot = 'blue'
var vnetAddressPrefixBase = '10.10'

var vnetAddressPrefix = '${vnetAddressPrefixBase}.0.0/16'
var aksSubnetAddressPrefix = '${vnetAddressPrefixBase}.0.0/20'
var agwSubnetAddressPrefix = '${vnetAddressPrefixBase}.16.0/25'
var vnetName = 'iac-${environment}-${slot}-vnet'
var agwName = 'iac-${environment}-${slot}-aks-agw'
var aksName = 'iac-${environment}-${slot}-aks'
var agwPipName = 'iac-${environment}-${slot}-agw-pip'
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
          description: 'Deny any connectivity from any vnets'
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
  name: vnetName
  dependsOn: [
    aksNsg
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

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: 'aks'
  dependsOn: [
    vnet
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

resource agwPip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: agwPipName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${uniqueName}-iac-dev-blue-agw-pip'
    }
  }
}

resource agw 'Microsoft.Network/applicationGateways@2020-11-01' = {
  name: agwName
  location: resourceGroup().location
  dependsOn: [
    agwPip
    vnet
  ]
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          subnet: {
            id: agwSubnet.id
          }
        }
      }
    ]
    sslCertificates: []
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: agwPip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
          }
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', agwName)}/frontendIPConfigurations/appGatewayFrontendIP'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', agwName)}/frontendPorts/appGatewayFrontendPort'
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', agwName)}/httpListeners/appGatewayHttpListener'
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', agwName)}/backendAddressPools/appGatewayBackendPool'
          }
          backendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', agwName)}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
          }
        }
      }
    ]
    probes: []
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  location: resourceGroup().location
  name: aksName
  dependsOn: [
    agw
  ]
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
    //addonProfiles: {
    //  ingressApplicationGateway: {
    //    config: {
    //      applicationGatewayId: agw.id
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
        vnetSubnetID: aksSubnet.id
      }
    ]
  }
}
