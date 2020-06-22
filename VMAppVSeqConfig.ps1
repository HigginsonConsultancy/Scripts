Try
    {
    $EventlogName = "HigginsonConsultancy"
    $EventlogSource = "VM Build Script"
    New-EventLog -LogName $EventlogName -Source $EventlogSource
    Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
    }
    
    Catch
    {
    }

# Download the Orca media
Try
    {
    $url="https://github.com/HigginsonConsultancy/Media/raw/master/Orca.zip"
    $output="c:\Windows\Temp\Orca.zip"
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Error -Message "Unable to download Orca media successfully"
    }

Try
    {
    Expand-Archive -LiteralPath $output -DestinationPath C:\Windows\Temp\ -force
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Error -Message "Unable to extract Orca zip file successfully"
    }

# Download the App-V Sequencer media
Try
    {
    $url="https://github.com/HigginsonConsultancy/Media/raw/master/AppVSequencer1903x64.zip"
    $output="c:\Windows\Temp\AppVSequencer1903x64.zip"
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Error -Message "Unable to download App-V Sequencer media successfully"
    }

Try
    {
    Expand-Archive -LiteralPath $output -DestinationPath C:\Windows\Temp\ -force
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Error -Message "Unable to extract App-V Sequencer zip file successfully"
    }

# Install Orca
Try
    {
    $Argument3 = "/i " + [char]34 + "C:\Windows\Temp\Orca\Orca-x86_en-us.msi" + [char]34 + " /qb"
    Start-Process -FilePath msiexec.exe -ArgumentList $Argument3 -Wait
        }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Error -Message "Unable to install application"
    }

# Install App-V Sequencer
Try
    {
    $Argument3 = "/i " + [char]34 + "C:\Windows\Temp\AppVSequencer1903x64\Appman Sequencer on amd64-x64_en-us.msi" + [char]34 + " /qb"
    Start-Process -FilePath msiexec.exe -ArgumentList $Argument3 -Wait
        }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Error -Message "Unable to install application"
    }



