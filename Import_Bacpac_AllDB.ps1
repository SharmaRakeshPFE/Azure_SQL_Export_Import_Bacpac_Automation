<#

##Script to take backup (bacpac) for multiple databases from multiple servers in their respective folders
##Author - Rakesh Sharma
## Ver 1.0
##How to use##
##Execute the script to create a database and obects on the local server for centralized repository
##Create a CSV or Txt File containing list of Azure SQL Logical Servers
##Create database GET_AZURESQL_STATS
##Create a table to store the credential in database GET_AZURESQL_STATS

#>

cls ##Clearing Screen
##Reading the Azure Logical Servers from list##
$SOURCE_INS="rsazuresqlserver.database.windows.net"
$TARGET_INS="insysqlserver.database.windows.net"

##Provide the name of the Local Instance to store the data##
$LocalInstance ='MININT-B7K1QNM\SQL01'

##Provide the credential to connect to local repository##
$localUser='sa'
$localPwd='sa'


$SOURCE_DB_SQL="select DATABASENAME from TBL_BACPAC_LOCATIONS where LSERVER=" + "'" + $SOURCE_INS + "'" + "AND RESTORE_FLAG=0" 
Write-Host $SOURCE_DB_SQL


##Provide the name of the database to read credential to connect to Azure SQL Servers##
$Repositorydb='GET_AZURESQL_STATS'

                                              $databases=Invoke-Sqlcmd -Query $SOURCE_DB_SQL -ServerInstance $LocalInstance -Username $localUser -Password $localPwd -Database $Repositorydb 
                                              
                                              foreach ($database in $databases)
                                            {
                                                   ##Write-Host $database.DATABASENAME
                                                   Write-Host "Retrieving path for bacpac File for database =  " $DATABASE.DATABASENAME
                                                   $TARGETDB=$database.DATABASENAME
                                                   $BACPAC_PATH_SQL="SELECT BACPAC_PATH FROM TBL_BACPAC_LOCATIONS WHERE LSERVER=" + "'" + $SOURCE_INS + "'" + "AND RESTORE_FLAG=0 AND DATABASENAME=" + "'" + $database.DATABASENAME + "'"
                                                   $BACPAC_PATH=Invoke-Sqlcmd -Query $BACPAC_PATH_SQL -ServerInstance $LocalInstance -Username $localUser -Password $localPwd -Database $Repositorydb 
                                                   
                                                   $ABS_PATH=$BACPAC_PATH.BACPAC_PATH + ".bacpac"
                                                   WRITE-HOST "Path for bacpac " $ABS_PATH 

                                                                Write-Host 'Reading Credentials to Connect to ' $SqlInstance
           
                                                                ##Pulling Credential from the database to connect to Local Azure SQL Server ##
                                                                $cmdlocaluser="select USERNAME,PWD from TBL_CREDENTIAL where LOGICAL_SERVER =" + '''' + $TARGET_INS + ''''
                                                                $LocalCred=Invoke-Sqlcmd -Query $cmdlocaluser -ServerInstance $LocalInstance -Username $localUser -Password $localPwd -Database $Repositorydb
                                                                $Rusername=$LocalCred.USERNAME
                                                                $Rpwd=$LocalCred.pwd

                                                   $ComandoOut="C:\Infosys\SqlPackage\Script\Import.bat " + $ABS_PATH + " " +  $TARGET_INS + " " + $TARGETDB + " " + $Rusername + " " + $Rpwd
                                                   ##Write-Host $ComandoOut
                                                   Write-Host "####################################" 
                                                   Write-Host "Importing Bacpac for " $TARGETDB  
                                                   Invoke-Expression -Command $ComandoOut | Out-Null
                                                   Write-Host "Bacpac Import completed for " $TARGETDB 
                                                   Write-Host "####################################" 

                                                   Start-Sleep -s 10
                                                   
                                                   $RestoreDBStatus="select name as DatabaseName, state_desc as [Status] from sys.databases where name <> 'master'"
                                                   $DBStatus=Invoke-Sqlcmd -Query $RestoreDBStatus -ServerInstance $TARGET_INS -Username $Rusername -Password $Rpwd -Database $TARGETDB
                                                   $DBStatus.DatabaseName + "=" +  $DBStatus.Status
                                            }
