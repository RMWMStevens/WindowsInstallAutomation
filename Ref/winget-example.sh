:: Downloaded from: https://pastebin.com/x5J9kseK
:: ----------------------------------------------------------------------
:: Whatsapp Beta van MSStore
winget install --id=9NBDXK71NK08 --accept-package-agreements && \
:: Unigram van MSStore
winget install --id=9n97zckpd60q --accept-package-agreements && \
:: Steam
winget install --id=Valve.Steam -e -h --silent && \
:: Discord
winget install --id=Discord.Discord -e -h --silent && \
:: FireFox
winget install --id=Mozilla.Firefox -e -h --silent && \
:: Teams
winget install --id=Microsoft.Teams -e -h --silent && \
:: Visual Studio Code
winget install --id=Microsoft.VisualStudioCode -e -h --silent && \
:: Epic Games Launcher
winget install --id=EpicGames.EpicGamesLauncher -e -h --silent && \
:: Signal
winget install -e --id OpenWhisperSystems.Signal.Beta \


:: Verwijderen van apps
winget uninstall --name "Teams" && \
winget uninstall --name "Films en tv" && \
winget uninstall --name "Cortana" && \
winget uninstall --name "Disney+" && \
winget uninstall --name "Microsoft Nieuws" && \
winget uninstall --name "MSN weer" && \
winget uninstall --name "Office" && \
winget uninstall --name "Microsoft Solitaire Collection" && \
winget uninstall --name "Microsoft Plaknotities" && \
winget uninstall --name "Power Automate" && \
winget uninstall --name "Groove Muziek"
