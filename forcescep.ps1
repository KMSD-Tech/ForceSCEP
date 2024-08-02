# Please define the issuer name for your certificates (DigiCert is provided as an example) - use the CN of your CA
$issuerName = "DigiCert Global Root CA"

# Function to check the registry key
function Check-RegistryKey {
    $key = "HKCU:\Software\InTunePkg"
    $name = "SCEP-User"

    Write-Host "Checking registry key: $key\$name"

    if (Test-Path $key) {
        Write-Host "Registry key path exists: $key"
        try {
            $value = Get-ItemProperty -Path $key -Name $name
            Write-Host "Registry key value: $($value.$name)"
            return $value.$name -eq 1
        } catch {
            Write-Host "Registry key not found: $name"
            return $false
        }
    } else {
        Write-Host "Registry key path does not exist: $key"
        return $false
    }
}

# Function to set the registry key
function Set-RegistryKey {
    $key = "HKCU:\Software\InTunePkg"
    $name = "SCEP-User"
    $value = 1

    if (!(Test-Path $key)) {
        New-Item -Path $key -Force | Out-Null
    }

    Set-ItemProperty -Path $key -Name $name -Value $value
    Write-Host "Registry key set: $key\$name = $value"
}

# Function to trigger Intune sync using Shell.Application COM object
function Trigger-IntuneSync {
    $Shell = New-Object -ComObject Shell.Application
    $Shell.open("intunemanagementextension://syncapp")
    Write-Output "Intune sync triggered using Shell.Application COM object."
}

# Function to check for the presence of the SCEP certificate
function Check-SCEPCertificate {
    param (
        [string]$IssuerName
    )

    $certs = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Issuer -like "*$IssuerName*" }
    return $certs.Count -gt 0
}

# Function to disconnect from the current SSID
function DisconnectFromCurrentSSID {
    $currentProfileOutput = (netsh wlan show interfaces) | Where-Object { $_ -match '^\s*Profile\s*:\s*(.*)' } 
    $currentSSID = $currentProfileOutput | ForEach-Object { $Matches[1].Trim() }
    
    Write-Host "Current SSID: '$currentSSID'"
    
    if ($currentSSID -eq "") {
        Write-Host "No active Wi-Fi connection found."
        return $null
    } else {
        $disconnectResult = netsh wlan disconnect
        Write-Host "Disconnect Result: $disconnectResult"
        Write-Host "Disconnected from SSID: '$currentSSID'"
        Start-Sleep -Seconds 3  # Wait for 3 seconds
        return $currentSSID
    }
}

# Function to reconnect to the specified SSID
function ReconnectToSpecifiedSSID {
    param (
        [string]$SSIDToReconnect
    )

    Write-Host "Attempting to reconnect to SSID: '$SSIDToReconnect'"
    
    $connectResult = netsh wlan connect name=$SSIDToReconnect
    Write-Host "Connect Result: $connectResult"
    Write-Host "Reconnected to SSID: '$SSIDToReconnect'"
    Start-Sleep -Seconds 3  # Wait for 3 seconds
}

# Function to check the network authentication type
function Check-NetworkAuthenticationType {
    $interfaceOutput = netsh wlan show interfaces
    $authTypeLine = $interfaceOutput | Where-Object { $_ -match '^\s*Authentication\s*:\s*(.*)' }
    $authType = $authTypeLine | ForEach-Object { $Matches[1].Trim() }
    
    Write-Host "Network Authentication Type: '$authType'"
    
    return $authType -eq "WPA2-Enterprise"
}

# Main script

try {
    # Check if the registry key is already set
    if (Check-RegistryKey) {
        Write-Output "Registry key is already set. No need to disconnect/reconnect."
    } else {
        # Check if the SCEP certificate is already installed
        if (Check-SCEPCertificate -IssuerName $issuerName) {
            Write-Output "SCEP Certificate is already installed. No need to trigger Intune sync."
        } else {
            # Trigger Intune sync
            Trigger-IntuneSync

            # Wait for the SCEP certificate to be installed
            while (-not (Check-SCEPCertificate -IssuerName $issuerName)) {
                Write-Output "Waiting for SCEP certificate to be installed..."
                Start-Sleep -Seconds 30  # Check every 30 seconds
            }

            Write-Output "SCEP Certificate installed successfully."
        }

        # Check if the network authentication type is WPA2-Enterprise
        if (Check-NetworkAuthenticationType) {
            # Disconnect from the current SSID
            $SSIDToReconnect = DisconnectFromCurrentSSID

            # Reconnect to the same SSID
            if ($SSIDToReconnect -ne $null) {
                ReconnectToSpecifiedSSID -SSIDToReconnect $SSIDToReconnect
                # Set the registry key
                Set-RegistryKey
            } else {
                Write-Host "No SSID returned from DisconnectFromCurrentSSID function."
            }
        } else {
            Write-Host "Network Authentication Type is not WPA2-Enterprise. Skipping disconnect/reconnect."
        }
    }

} catch {
    Write-Output "An error occurred: $_"
}