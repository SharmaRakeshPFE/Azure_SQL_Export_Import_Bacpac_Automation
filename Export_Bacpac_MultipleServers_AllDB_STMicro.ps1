##Script to take backup (bacpac) for multiple databases from multiple servers in their respective folders
##Author - Rakesh Sharma
## Ver 1.0
##How to use##
##Execute the script to create a database and obects on the local server for centralized repository
##Create a CSV or Txt File containing list of Azure SQL Logical Servers
##Create database GET_AZURESQL_STATS
##Create a table to store the credential in database GET_AZURESQL_STATS

cls ##Clearing Screen
##Reading the SQL Servers from list##
$SqlInstances= Get-Content -Path C:\Infosys\SqlPackage\servers.txt

##Provide the name of the Local Instance to store the data##
$LocalInstance ='MININT-B7K1QNM\SQL01'

##PRovide the credential to connect to local repository##
$localUser='sa'
$localPwd='sa'

##Provide the name of the database to read credential to connect to Azure SQL Servers##
$Repositorydb='GET_AZURESQL_STATS'

##Looping through each Instance##
 foreach ($SqlInstance in $SqlInstances)  
  {

    try
        {     
            Write-Host 'connecting to Instance =' $SqlInstance
            Write-Host 'Reading Credentials to Connect to ' $SqlInstance
           
            ##Pulling Credential from the database to connect to Local Azure SQL Server ##
            $cmdlocaluser="select USERNAME,PWD from TBL_CREDENTIAL where LOGICAL_SERVER =" + '''' + $SqlInstance + ''''
            $LocalCred=Invoke-Sqlcmd -Query $cmdlocaluser -ServerInstance $LocalInstance -Username $localUser -Password $localPwd -Database $Repositorydb
            $username=$LocalCred.USERNAME
            $pwd=$LocalCred.pwd

                               $Folder="C:\Infosys\SqlPackage\Files\" + $SqlInstance
                               $Folder=$Folder.Replace(".","_")
                               Write-Host "Creating Directories"
                               md $Folder -Force
                               Write-Host $Folder
                               Write-Host "Initiating BACPAC process for " $SqlInstances
                                ##Pulling list of databases using above credentials -> Make sure that the credential have access to all databases##
                                $databases=Invoke-Sqlcmd -Query "select name from [sys].databases where name <> 'master'" -ServerInstance $SqlInstance -Username $username -Password $pwd -Database 'master' 
                                              foreach ($databaseName in $databases.name)
                                            {
                                                  
                                                   $Path=   $Folder + "\" + $databaseName
                                                   $ComandoOut="C:\Infosys\SqlPackage\Script\Export.bat " + $SqlInstance + " " + $databaseName + " " + $username + " " + $pwd + " " + $Path + ".bacpac" 
                                                   $STARTTIMESTAMP=Get-Date
                                                   Write-Host $STARTTIMESTAMP

                                                    $SqlQuery_1="INSERT INTO [TBL_BACPAC_LOCATIONS] (LSERVER,DATABASENAME,BACPAC_PATH,RESTORE_FLAG) VALUES (" + "'" + $SqlInstance + "'," + "'" +  $databaseName + "'," + "'" + $Path + "'," + "0" +")"
                                                   $SqlQuery_2="INSERT INTO [TBL_BACPAC_TIMESTAMP] VALUES (" + "'" + $SqlInstance + "'," + "'" +  $databaseName + "'," + "'" + "BACKUP STARTED" + "'" + "," + "'"+ $STARTTIMESTAMP + "'" + "," + $DBsize.DbSizeInMB + ")" 
                                                   $SQL_TSQL_Size="SELECT ((SUM(reserved_page_count) * 8192) / 1024 / 1024) AS DbSizeInMB FROM sys.dm_db_partition_stats"
                                                                                                      
                                                   write-host $SqlQuery_1
                                                   write-host $SqlQuery_2
                                                   

                                                   ##Get Database Size##
                                                   $DBsize=Invoke-Sqlcmd $SQL_TSQL_Size -ServerInstance $SqlInstance -Database $databaseName -Username $username -Password $pwd
                                                                                                     
                                                   Write-Host $DBsize.DbSizeInMB
                                                   
                                                   Invoke-Sqlcmd $SqlQuery_1 -ServerInstance $LocalInstance -Username $localUser -Password $localPwd -Database $Repositorydb
                                                   Invoke-Sqlcmd $SqlQuery_2 -ServerInstance $LocalInstance -Username $localUser -Password $localPwd -Database $Repositorydb
                                                   Write-Host "BACPAC PATH STORED IN DB"
                                                   Write-Host "####################################" 
                                                   Write-Host $ComandoOut
                                                   
                                                   
                                                   
                                                   ##Intentionally Supressing the output for security reasons##
                                                   Write-Host "Creating BACPAC for database " $databaseName
                                                   Invoke-Expression -Command $ComandoOut | Out-Null
                                                   
                                                   $ENDTIMESTAMP=Get-Date    
                                                   Write-Host $ENDTIMESTAMP                                               
                                                   $SqlQuery_3="INSERT INTO [TBL_BACPAC_TIMESTAMP] VALUES (" + "'" + $SqlInstance + "'," + "'" +  $databaseName + "'," + "'" + "BACKUP COMPLETED" + "'" + "," +"'"+ $ENDTIMESTAMP + "'" + "," + $DBsize.DbSizeInMB + ")" 
                                                   Write-Host $SqlQuery_3
                                                   Invoke-Sqlcmd $SqlQuery_3 -ServerInstance $LocalInstance -Username $localUser -Password $localPwd -Database $Repositorydb
                                                   $path=""
                                                   Write-Host "Bacpac completed for " $databaseName 
                                            }

        }    
  
 catch
  {
    Write-Host -ForegroundColor DarkYellow "Error:"
    Write-Host -ForegroundColor Magenta $Error[0].Exception
  }
 
 
 }


