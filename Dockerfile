FROM mcr.microsoft.com/powershell:lts-ubuntu-18.04

RUN apt-get update && apt-get install inetutils-ping dnsutils net-tools nano -y

RUN echo 'Import-Module FC_Log -verbose' >> /opt/microsoft/powershell/7-lts/profile.ps1
COPY Modules/. /usr/local/share/powershell/Modules
COPY Scripts/. /usr/local/share/powershell/Scripts

