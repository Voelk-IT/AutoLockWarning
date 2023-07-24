Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public static class IdleTimeFinder
{
    [DllImport("user32.dll")]
    static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static uint GetIdleTime()
    {
        LASTINPUTINFO info = new LASTINPUTINFO();
        info.cbSize = (uint)Marshal.SizeOf(info);
        GetLastInputInfo(ref info);
        return ((uint)Environment.TickCount - info.dwTime);
    }

    internal struct LASTINPUTINFO
    {
        public uint cbSize;
        public uint dwTime;
    }
}
'@

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Einstellen der Anfangswerte für die Timer (in Minuten).
$DialogTimer = 5 # Dieser Wert Setzt das Vorraus wann der Dialog Erscheint.
$LockTimer = 10 # Dieser Wert Setzt den Sperrbildschirm.
$dialogEnabled = $false # $true Steht für AN und $false Steht für aus.

function ShowLockWarningDialog {
    $Form = New-Object system.Windows.Forms.Form
    $Form.Text = "Hinweis: Automatische Sperrung des Computers"
    $Form.TopMost = $true
    $Form.Size = New-Object System.Drawing.Size(700, 400)
    $Form.FormBorderStyle = 'FixedDialog'
    $Form.BackColor = 'White'

    $Label1 = New-Object System.Windows.Forms.Label
    $Label1.Text = "Es scheint, dass Sie den Computer für mehr als $($DialogTimer) Minuten nicht bedient haben.`nAus Sicherheitsgründen wird der Computer automatisch in $($LockTimer) Minuten gesperrt.`nDies dient dem Schutz Ihrer persönlichen Daten und der Verhinderung unbefugter Zugriffe.`nUm den Computer zu entsperren und fortzufahren, geben Sie bitte Ihr Passwort ein oder bewegen Sie die Maus bzw.`ndrücken Sie eine Taste auf der Tastatur.`n`nVielen Dank für Ihr Verständnis und Ihre Unterstützung bei der Gewährleistung der Systemsicherheit."
    $Label1.AutoSize = $true
    $Label1.Location = New-Object System.Drawing.Point(12, 142)

    $PictureBox = New-Object System.Windows.Forms.PictureBox
    $PictureBox.SizeMode = 'StretchImage'
    $PictureBox.Size = New-Object System.Drawing.Size(692, 111)
    $PictureBox.Location = New-Object System.Drawing.Point(12, 12)

    $WebClient = New-Object System.Net.WebClient
    $Stream = $WebClient.OpenRead("https://YOUR-LOGO.JPG")
    $PictureBox.Image = [System.Drawing.Image]::FromStream($Stream)

    $Button = New-Object System.Windows.Forms.Button
    $Button.Text = "Schliessen"
    $Button.Size = New-Object System.Drawing.Size(316, 36)
    $Button.Location = New-Object System.Drawing.Point(192, 280)
    $Button.Add_Click({ $Form.Close() })

    $Label2 = New-Object System.Windows.Forms.Label
    $Label2.Text = "© 2023 www.Voelk-IT.de - All Rights Reserved. Last Updated : 24/07/2023 12:03:30"
    $Label2.AutoSize = $true
    $Label2.BackColor = 'White'
    $Label2.Location = New-Object System.Drawing.Point(141, 350)
    $Label2.Add_Click({
        [System.Windows.Forms.MessageBox]::Show("Entwickler: Aydin Völk", "Entwickler Info")
    })

    $Form.Controls.Add($Label1)
    $Form.Controls.Add($PictureBox)
    $Form.Controls.Add($Button)
    $Form.Controls.Add($Label2)

    $Form.ShowDialog()
}

while ($true) {
    Start-Sleep -Seconds 5
    $idleTime = [IdleTimeFinder]::GetIdleTime()

    if ($dialogEnabled -and $idleTime -gt ($DialogTimer * 60 * 1000)) {
        ShowLockWarningDialog
        $dialogEnabled = $false
    }

    if (!$dialogEnabled -and $idleTime -gt ($LockTimer * 60 * 1000)) {
        rundll32.exe user32.dll,LockWorkStation
        $dialogEnabled = $true
    }

    if ($idleTime -lt ($DialogTimer * 60 * 1000)) {
        $dialogEnabled = $true
    }
}
