FROM microsoft/powershell
RUN ["pwsh", "-c", "Install-Module pester -Force"]
WORKDIR /tests/Modules/tests

VOLUME "/tests"
CMD ["pwsh","-c", " Invoke-Pester -OutputFile /tests/PesterResults.xml -OutputFormat NUnitXml"]