FROM microsoft/powershell

LABEL maintainer="Brandon McClure (brandonmcclure89@gmail.com)"

# Install Dotnet core 
# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
RUN apt-get update --yes \
&& apt-get install -y wget \
&& wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
&& dpkg -i packages-microsoft-prod.deb \
&& apt-get update --yes \
&& apt-get install -y apt-transport-https
RUN apt-get update --yes 
RUN apt-get install -y dotnet-sdk-5.0 
RUN DEBIAN_FRONTEND=noninteractive apt install nuget -y

RUN ["pwsh", "-c", "Install-Module PSScriptAnalyzer,PSHTMLTable -Force"]
WORKDIR /build

VOLUME "/build"
CMD ["pwsh","-c", "/build/Modules/Build-AllFCModules.ps1"]
#cmd [ "tail","-f", "/dev/null" ]