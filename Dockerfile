ARG TARGET_IMAGE=mcr.microsoft.com/powershell:lts-ubuntu-22.04
FROM $TARGET_IMAGE as base
WORKDIR /root
RUN apt-get update && apt-get install inetutils-ping dnsutils net-tools nano -y --no-install-recommends

FROM base as devcontainer
WORKDIR /root
RUN apt-get update && apt-get install git wget make -y --no-install-recommends
RUN wget https://github.com/hadolint/hadolint/releases/download/v2.10.0/hadolint-Linux-x86_64 && \
	mv /root/hadolint-Linux-x86_64 /bin/hadolint && chmod +x /bin/hadolint

FROM base as final
RUN echo 'Import-Module FC_Core,FC_Log,FC_Data,FC_Docker,FC_Git,FC_TFS,FC_SysAdmin,FC_Misc; Get-Module fc*' >> /opt/microsoft/powershell/7-lts/profile.ps1
COPY Modules/. /usr/local/share/powershell/Modules
COPY Scripts/. /usr/local/share/powershell/Scripts

