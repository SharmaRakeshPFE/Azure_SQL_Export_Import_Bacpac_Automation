##Script to take backup (bacpac) for multiple databases from multiple servers in their respective folders
## Customer - STMicroelectronics 
##Author - Rakesh Sharma
## Ver 1.0
##How to use##
##Execute the script to create a database and obects on the local server for centralized repository
##Create a CSV or Txt File containing list of Azure SQL Logical Servers
##Create database GET_AZURESQL_STATS
##Create a table to store the credential in database GET_AZURESQL_STATS
##Code Reusability Support - Yes
<#

CREATE DATABASE GET_AZURE_STATS
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TBL_CREDENTIAL](
	[LOGICAL_SERVER] [varchar](400) NULL,
	[USERNAME] [varchar](100) NULL,
	[PWD] [varchar](200) MASKED WITH (FUNCTION = 'default()') NULL
) ON [PRIMARY]
GO

#>

cls ##Clearing Screen
##Reading the Azure Logical Servers from list##
##Create a text File with the list of servers on which backup has to be taken
$SqlInstances= Get-Content -Path C:\STMicroelectronics\servers.txt

##Provide the name of the Local Instance to store the data##
$LocalInstance ='MININT-B7K1QNM\SQL01'

##Provide the credential to connect to local repository##
$localUser='sa'
$localPwd='sa'

##Provide the name of the database to read credential to connect to Azure SQL Servers##
$Repositorydb='GET_AZURESQL_STATS'

##Looping through each Instance##
 foreach ($SqlInstance in $SqlInstances)  
  {

    ##try
      ##  {     
            Write-Host 'connecting to Instance =' $SqlInstance
            Write-Host 'Reading Credentials to Connect to ' $SqlInstance
           
            ##Pulling Credential from the database to connect to Local Azure SQL Server ##
            $cmdlocaluser="select USERNAME,PWD from TBL_CREDENTIAL where LOGICAL_SERVER =" + '''' + $SqlInstance + ''''
            $LocalCred=Invoke-Sqlcmd -Query $cmdlocaluser -ServerInstance $LocalInstance -Username $localUser -Password $localPwd -Database $Repositorydb
            $username=$LocalCred.USERNAME
            $pwd=$LocalCred.pwd

                               $Folder="C:\STMicroelectronics\SqlPackage\Files\" + $SqlInstance
                               $Folder=$Folder.Replace(".","_")
                               Write-Host "Creating Directories"
                               md $Folder -Force
                               Write-Host $Folder
                               Write-Host "Initiating BACPAC process for " $SqlInstances
                                ##Pulling list of databases using above credentials -> Make sure that the credential have access to all databases##
                                
                                ##Important = In case you need bacpac for all databases change where name <> 'master'"
                                ## Test this script by adding name of database##

                                $databases=Invoke-Sqlcmd -Query "select name from [sys].databases where name = 'azsqldb'" -ServerInstance $SqlInstance -Username $username -Password $pwd -Database 'master' 
                                              foreach ($databaseName in $databases.name)
                                            {
                                                   $Path=   $Folder + "\" + $databaseName
                                                   $ComandoOut="C:\STMicroelectronics\SqlPackage\Script\Export.bat " + $SqlInstance + " " + $databaseName + " " + $username + " " + $pwd + " " + $Path + ".bacpac" 
                                                  $SqlQuery_1="INSERT INTO [TBL_BACPAC_LOCATIONS] (LSERVER,DATABASENAME,BACPAC_PATH,RESTORE_FLAG) VALUES (" + "'" + $SqlInstance + "'," + "'" +  $databaseName + "'," + "'" + $Path + "'," + "0" +")"
                                                    write-host $SqlQuery_1
                                                   Invoke-Sqlcmd $SqlQuery_1 -ServerInstance $LocalInstance -Username $localUser -Password $localPwd -Database $Repositorydb
                                                   Write-Host "BACPAC PATH STORED IN DB"
                                                   Write-Host "####################################" 
                                                   Write-Host $ComandoOut
                                                   #Intentionally Supressing the output for security reasons##
                                                   Write-Host "Creating BACPAC for database " $databaseName
                                                   Invoke-Expression -Command $ComandoOut | Out-Null
                                                   $path=""
                                                   Write-Host "Bacpac completed for " $databaseName 
                                            }

        ##}    
 
 
 ##catch
  ##{
    ##Write-Host -ForegroundColor DarkYellow "Error:"
    ##Write-Host -ForegroundColor Magenta $Error[0].Exception
  ##}
 
 
 }


