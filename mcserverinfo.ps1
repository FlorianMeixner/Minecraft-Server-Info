Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Farben & Fonts (Modern Dark Theme)
$bgColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$accentColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
$font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)

$lastServerInfo = $null

function Get-MinecraftServerInfo($domain, $port) {
    try {
        if ($port -eq $null -or $port -eq '') { $port = 25565 }
        $hostPort = "$domain`:$port"
        $url = "https://api.mcstatus.io/v2/status/java/$hostPort"
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing
        return $response
    } catch {
        return $null
    }
}

function Get-ICMPPing($hostname) {
    try {
        $pingSender = New-Object System.Net.NetworkInformation.Ping
        $reply = $pingSender.Send($hostname, 2000)
        if ($reply.Status -eq "Success") {
            return "$($reply.RoundtripTime) ms"
        } else {
            return "Nicht erreichbar"
        }
    } catch {
        return "Fehler"
    }
}

function Format-ServerInfo($info, $domain, $port) {
    $icmpPing = Get-ICMPPing -hostname $domain

    $output = @()
    $output += "MOTD: $($info.motd.clean)"
    $output += "Version: $($info.version.name_clean)"
    $output += "Online Spieler: $($info.players.online) / $($info.players.max)"
    $output += "IP: $domain"
    $output += "Port: $port"
    $output += "Ping (ICMP): $icmpPing"

    if ($info.players.list -and $info.players.list.Count -gt 0) {
        $output += ""
        $output += "Spieler online:"
        foreach ($player in $info.players.list) {
            $output += "- $($player.name_clean)"
        }
    }
    return $output
}

function Load-And-ShowServerInfo {
    $domain = $textboxDomain.Text.Trim()
    $port = $textboxPort.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($domain)) {
        $outputBox.Text = "Bitte eine Domain eingeben."
        $pictureBox.Image = $null
        return
    }
    
    if ($port -and -not ($port -match '^\d+$')) {
        $outputBox.Text = "Bitte einen gültigen Port (Zahl) eingeben oder leer lassen."
        $pictureBox.Image = $null
        return
    }

    if (-not $port) { $port = 25565 }

    try {
        $info = Get-MinecraftServerInfo -domain $domain -port $port
        if ($info -eq $null) {
            $outputBox.Text = "Server nicht erreichbar oder nicht vorhanden."
            $pictureBox.Image = $null
            return
        }
    } catch {
        $outputBox.Text = "Server nicht erreichbar oder nicht vorhanden."
        $pictureBox.Image = $null
        return
    }

    $lastServerInfo = @{ info = $info; domain = $domain; port = $port }

    $outputBox.Lines = Format-ServerInfo $info $domain $port

    # Server-Icon anzeigen (Base64 aus API)
    if ($info.icon) {
        try {
            $iconData = $info.icon -replace "^data:image\/png;base64,", ""
            $bytes = [Convert]::FromBase64String($iconData)
            $ms = New-Object System.IO.MemoryStream(,$bytes)
            $img = [System.Drawing.Image]::FromStream($ms)
            $pictureBox.Image = $img
        } catch {
            $pictureBox.Image = $null
        }
    } else {
        $pictureBox.Image = $null
    }
}

# GUI Setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "Minecraft Server Info"
$form.Size = New-Object System.Drawing.Size(600, 450)
$form.StartPosition = "CenterScreen"
$form.BackColor = $bgColor
$form.Font = $font

# Domain Label
$labelDomain = New-Object System.Windows.Forms.Label
$labelDomain.Text = "Minecraft Server Domain:"
$labelDomain.Location = New-Object System.Drawing.Point(20, 20)
$labelDomain.Size = New-Object System.Drawing.Size(200, 25)
$labelDomain.ForeColor = $accentColor
$labelDomain.BackColor = $bgColor
$labelDomain.Anchor = "Top, Left"
$form.Controls.Add($labelDomain)

# Domain TextBox
$textboxDomain = New-Object System.Windows.Forms.TextBox
$textboxDomain.Location = New-Object System.Drawing.Point(20, 50)
$textboxDomain.Size = New-Object System.Drawing.Size(360, 25)
$textboxDomain.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
$textboxDomain.ForeColor = [System.Drawing.Color]::White
$textboxDomain.BorderStyle = 'FixedSingle'
$textboxDomain.Anchor = "Top, Left, Right"
$form.Controls.Add($textboxDomain)

# Port Label
$labelPort = New-Object System.Windows.Forms.Label
$labelPort.Text = "Port (optional, Standard 25565):"
$labelPort.Location = New-Object System.Drawing.Point(20, 85)
$labelPort.Size = New-Object System.Drawing.Size(200, 25)
$labelPort.ForeColor = $accentColor
$labelPort.BackColor = $bgColor
$labelPort.Anchor = "Top, Left"
$form.Controls.Add($labelPort)

# Port TextBox
$textboxPort = New-Object System.Windows.Forms.TextBox
$textboxPort.Location = New-Object System.Drawing.Point(20, 115)
$textboxPort.Size = New-Object System.Drawing.Size(140, 25)
$textboxPort.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
$textboxPort.ForeColor = [System.Drawing.Color]::White
$textboxPort.BorderStyle = 'FixedSingle'
$textboxPort.Anchor = "Top, Left"
$form.Controls.Add($textboxPort)

# Button: Server Infos anzeigen (Lädt & zeigt Daten)
$buttonShowInfo = New-Object System.Windows.Forms.Button
$buttonShowInfo.Text = "Server Infos anzeigen"
$buttonShowInfo.Location = New-Object System.Drawing.Point(20, 150)
$buttonShowInfo.Size = New-Object System.Drawing.Size(520, 30)
$buttonShowInfo.BackColor = $accentColor
$buttonShowInfo.ForeColor = [System.Drawing.Color]::White
$buttonShowInfo.FlatStyle = 'Flat'
$buttonShowInfo.Anchor = "Top, Left, Right"
$form.Controls.Add($buttonShowInfo)

# Panel als Container für Icon und TextBox
$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(20, 190)
$panel.Size = New-Object System.Drawing.Size(560, 220)
$panel.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
$panel.BorderStyle = 'FixedSingle'
$panel.Anchor = "Top, Bottom, Left, Right"
$form.Controls.Add($panel)

# PictureBox für Server-Icon (erst Größe setzen)
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Size = New-Object System.Drawing.Size(64,64)
# Position wird durch Funktion gesetzt
$pictureBox.Location = New-Object System.Drawing.Point(0, 10)
$pictureBox.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
$pictureBox.BorderStyle = 'FixedSingle'
$panel.Controls.Add($pictureBox)

# Funktion zum Zentrieren des Icons horizontal im Panel
function Center-Icon {
    $pictureBox.Left = ([int](($panel.Width - $pictureBox.Width) / 2))
}

# Initial zentrieren
Center-Icon

# Panel Resize Event, um Icon immer zu zentrieren
$panel.Add_Resize({
    Center-Icon
})

# Ausgabe TextBox (unter dem Icon im Panel)
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Location = New-Object System.Drawing.Point(10, 80)
$outputBox.Size = New-Object System.Drawing.Size(540, 130)
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
$outputBox.ForeColor = [System.Drawing.Color]::White
$outputBox.BorderStyle = 'None'
$outputBox.Anchor = "Top, Bottom, Left, Right"
$panel.Controls.Add($outputBox)

# Button Klick Event
$buttonShowInfo.Add_Click({
    Load-And-ShowServerInfo
})

# Enter-Taste im Domain-TextBox zum Abrufen
$textboxDomain.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq 'Enter') {
        $buttonShowInfo.PerformClick()
        $e.SuppressKeyPress = $true
    }
})

# Enter-Taste im Port-TextBox zum Abrufen
$textboxPort.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq 'Enter') {
        $buttonShowInfo.PerformClick()
        $e.SuppressKeyPress = $true
    }
})

# GUI starten
[void]$form.ShowDialog()
