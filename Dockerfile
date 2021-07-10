FROM mcr.microsoft.com/powershell:lts-debian-buster-slim-20210414

RUN apt-get update && apt-get install inetutils-ping dnsutils net-tools -y
COPY Modules/. /usr/local/share/powershell/Modules
COPY Scripts/. /usr/local/share/powershell/Scripts

