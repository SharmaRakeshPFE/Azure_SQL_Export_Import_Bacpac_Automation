##Modify the script accordingly
"C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\sqlpackage.exe" /a:Export /SourceServerName:%1 /SourceDatabaseName:%2 /SourceUser:%3 /SourcePassword:%4 /TargetFile:%5 >>C:\Infosys\SqlPackage\log\Exporta.Log
