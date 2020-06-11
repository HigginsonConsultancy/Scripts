Try
    {
    $EventlogName = "HigginsonConsultancy"
    $EventlogSource = "VM Build Script"
    New-EventLog -LogName $EventlogName -Source $EventlogSource
    Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Information -Message "Starting VM Build Script"
    }
    
    Catch
    {
    }

# Download the source media
Try
    {
    EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Information -Message "Attempting to download media"
    $url="https://github.com/HigginsonConsultancy/Media/raw/master/Orca.zip"
    $output="c:\Temp\Orca.zip"
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Error -Message "Unable to download media successfully"
    }

Try
    {
    EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Information -Message "Starting to expand media to correct location"
    Expand-Archive -LiteralPath $output -DestinationPath C:\Temp\
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Error -Message "Unable to extract zip file successfully"
    }

Try
    {
    EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Information -Message "Starting Application Install"
    $Argument3 = "/i " + [char]34 + "C:\Temp\Orca\Orca-x86_en-us.msi" + [char]34 + " /qb"
    Start-Process -FilePath msiexec.exe -ArgumentList $Argument3 -Wait
        }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Error -Message "Unable to install application"
    }

EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101  -EntryType Information -Message "VM Build Script Completed"



