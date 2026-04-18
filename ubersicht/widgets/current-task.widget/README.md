## Para instalar este widget:
 1. Correr inicialmente o Uberstich inalterado
 2. cd /Applications/Übersicht.app/Contents/Resources
 3. Instalar a dependência do "toggl-api": ```npm install toggl-api```
 4. Aplicar o patch1: ```patch server.js [this_widget_folder]/server.patch```
 5. Aplicar o patch2: ```patch server.js [private_folder]/toggl_api_auth.patch```

## Para inicialmente criar o patch usar:
```diff -u server.original.js server.modified.js > server.patch```
