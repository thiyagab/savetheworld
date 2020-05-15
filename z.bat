echo 'building'
call flutter build web
call copy /y build\web\main.dart.js* public\
call firebase deploy