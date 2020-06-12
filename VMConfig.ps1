Try
    {
    $EventlogName = "HigginsonConsultancy"
    $EventlogSource = "VM Build Script"
    New-EventLog -LogName $EventlogName -Source $EventlogSource
    Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting VM Build Script"
    }
    
    Catch
    {
    }

# Download the source media
Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to download media"
    $url="https://github.com/HigginsonConsultancy/Media/raw/master/Orca.zip"
    $output="c:\Windows\Temp\Orca.zip"
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting to expand media to correct location"
    Expand-Archive -LiteralPath $output -DestinationPath C:\Windows\Temp\
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting Application Install"
    $Argument3 = "/i " + [char]34 + "C:\Windows\Temp\Orca\Orca-x86_en-us.msi" + [char]34 + " /qb"
    Start-Process -FilePath msiexec.exe -ArgumentList $Argument3 -Wait
        }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "VM Build Script Completed"



