# SuuntoStravaGrafanaPerformance
Display Suunto activities in Grafana

The problem
Activity apps like Strava, Suunto, Garmin Connect provide good but somewhat basic presentation of activity data. Even with the paid version there is much to be desired from Strava visual presentation.

The solution
Use Grafana's powerful visualisation tools to organise and display activity app data.



Considered options
All 3 provide developer API, which allows integration with external tools
 - Strava has an excelent API, however it has recently been ringfenced by a paid for service. No longer free to use their Dev API. Grafana does support Strava as a data source

 - Suunto does not provide an API for direct integraiton with Grafana. However, using a Python / Powershell scrip, the data can be exported from Suunto (via thier API), injected into a database (PostreSQL) and read/displayed in Grafana

 - Garmin Connect - does have an API, however it is only available for businesses and organisations. Not available to individuals for personal projects



Ecosystem components

- Azure Container Apps - using a Consumtion based plan (Azure Container Apps Environment + Log Analytics Workspace)
- Database - PostgreSQL (free offering from Neon), persistent storage
- Grafana - containeraised, running in the Azure Container Apps

Alternative consideration

 - Data storage required for Grafana - any dashboards or changes made must be stored permanently. In order to achive this a storage solution was required.
   -- Mount to Azure Storage account - was unsuitable due to incopatability b/n Grafana SQLite grafana.db and the SMB storage of Azure (Premium V3 may offer a better option)
   -- PostgreSQL - The Azure offering was unsuitable due to the eventual cost. Neon PostgreSQL was the better option due to simplicity, cost and availability. In addition, having the data stored externally made Grafana more flexible

Files / Folders
- connectToSuuntoAPI.ps1 - purelly explores integration using the Suunto API
- terraformAlternatives - Using Terraform instead of AZ to build the Azure infrastructure
- AzContainerBuild - instructions on building the Azure infrastructure using the AZ CLI
- secretsHandling - options and instructions on secure connection and secrets handling b/n the Azure Container app and the Neon PostgreSQL database
- deployGrafanaStravaContainerApp - YAML file to deploy Grafana in the Azure Container app