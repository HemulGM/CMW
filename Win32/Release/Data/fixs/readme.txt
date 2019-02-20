#Расширение для файла "*.fix"
#Fix для применения к ОС
#Name - Название или краткое описание
#Problem - Содержание проблемы, которую исправляет это решение
#Desc - Полное описание действия, решения проблемы
#Actions - кол-во действий (от 1 до N будут выполняться команды)
#Act1-ActN - дейтвия по порядку
#Type - тип дейтвия
# cmd - выполнить команду в CMD без показа терминала
# cmdt - выполнить команду в CMD с выводом окна терминала (+pause)
#  Command - команда для выполнения в треминале CMD
#  Info - описание текущего действия (не обязательно)
# msg - показать сообщение
#  QUERYREGPATHEXST(HKLM\SOFTWARE\Microsoft\MSLicensing) - Запрос на существование пути 
#  QUERYREGKEYEXIST(HKLM\SOFTWARE\Microsoft\MSLicensing, KEYNAME) - Запрос на существование ключа
#  QUERYREGKEYVALUE(HKLM\SOFTWARE\Microsoft\MSLicensing, KEYNAME, DATA) - Запрос на совпадение данных ключа
#TimeWait - время перерыва между выполнением действий (секунд)

[info]
Name=Сброс лимита лицензии для сервера
Problem=При попытке подключения к УРС возникает ошибка с контекстом клиентской лицензии
Desc=Удалить раздел реестра "HKLM\SOFTWARE\Microsoft\MSLicensing"
Actions=2
TimeWait=1

[Act1]
Type=cmd
Command=reg HKLM\SOFTWARE\Microsoft\MSLicensing
Info=удаление ключа "HKLM\SOFTWARE\Microsoft\MSLicensing" из реестра

[Act2]
Type=msg
QUERY=QUERYREGPATHEXST(HKLM\SOFTWARE\Microsoft\MSLicensing) 
MessageWithTrue=Сообщение при получении положительного ответа от запроса или при отсутствии запроса
MessageWithFalse=Сообщение при получении отрицательного ответа от запроса