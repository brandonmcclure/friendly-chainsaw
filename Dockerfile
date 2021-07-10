FROM mcr.microsoft.com/powershell:lts-ubuntu-18.04

RUN apt-get update && apt-get install inetutils-ping dnsutils net-tools nano -y

RUN echo 'Import-Module FC_Core,FC_Log,FC_Data,FC_Docker,FC_Git,FC_TFS,FC_SysAdmin,FC_Misc; Get-Module fc*' >> /opt/microsoft/powershell/7-lts/profile.ps1
COPY Modules/. /usr/local/share/powershell/Modules
COPY Scripts/. /usr/local/share/powershell/Scripts

