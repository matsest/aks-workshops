resource appaMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'appa'
  location: resourceGroup().location
}

resource appbMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'appb'
  location: resourceGroup().location
}

resource appcMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'appc'
  location: resourceGroup().location
}
