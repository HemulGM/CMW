#Каталог "fix" хранит список решений

#---------------------------------------------------------------------------------
#EventLog.inf
#Описание: Файл конфигурации анализа журнала событий Windows
[Presets]
#Timeslot - временной интервал (в днях), 14 (две недели) - нормально
Timeslot=14

[EventSource]
#Перечисление источников событий Windows
#Disk - события жестких и оптических дисков
#atapi - события контроллера atapi
#cdrom - события контреллера cdrom
#EventLog - события ОС
#Microsoft-Windows-Kernel-General - критические ошибки Windows
#Microsoft-Windows-Kernel-Power - ошибки Windows
#Microsoft-Windows-WER-SystemErrorReporting - ошибки Windows
#Ntfs - ошибки файловой системы NTFS
#volsnap - ошибки теневого копирования томов
Disk
Microsoft-Windows-Kernel-General
Microsoft-Windows-Kernel-Power
Microsoft-Windows-WER-SystemErrorReporting

#---------------------------------------------------------------------------------
#IgnoreApps.inf
#Список имен производителей, установленные приложения которых будут игнорироваться при получении общего списка установленных программ
microsoft
adobe
google
embarcadero
borland
nvidia

#---------------------------------------------------------------------------------
#ImPaths.inf
#Важные каталоги и команды, для открытия из приложения
#Отображаемое имя пути=путь
#Переменные:
# %USER% - текущий пользователь
# %SYS32% - "C:\Windows\System32\"
# %SYS64% - "C:\Windows\SysWOW64\"
# %APPDATA% - "C:\Users\%USER%\AppData\Roaming\" или "C:\Documents and Settings\%USER%\Local Settings\"
# %TASKS% - "C:\Windows\Tasks\"
[Paths]
AppData=%APPDATA%\Temp
Windows Tasks=%APPDATA%\%TASKS%
User Doc=C:\Users\%USER%\Documents
MsConfig=msconfig

#---------------------------------------------------------------------------------
#WinApps.inf
#Перечисление частей названий установленных приложений, которые следует удалить
# ";" - знак "или"
# "," - знак "и"
#пример (guardian;toolbar;) - будет выбрано приложение, в названии которого присутствует часть "guardian" или "toolbar".
#пример (qip,guard,) - будет выбрано приложение, в названии которого одновременно присутствуют части "qip" и "guard".
guardian;toolbar;
qip,guard,
mail,guard,
qip,tools,
qip,toolbar,
auto,update,
яндекс.бар;тулбар;туллбар;яндексбар;
bing,bar,
ask,bar,
mail,спутник,

#---------------------------------------------------------------------------------
#Config.inf
#Файл конфигурации
#Имена возможных стилей
#WINDOWS
#AMAKRITS
#AMETHYSTKAMRI
#AQUAGRAPHITE
#AQUALIGHTSLATE
#AURIC
#CARBON
#CHARCOALDARKSLATE
#COBALTXEMEDIA
#CYANDUSK
#CYANNIGHT
#EMERALDLIGHTSLATE
#GOLDENGRAPHITE
#ICEBERGCLASSICO
#LAVENDERCLASSICO
#LIGHT
#LUNA
#METROPOLISUIBLACK
#METROPOLISUIBLUE
#METROPOLISUIDARK
#METROPOLISUIGREEN
#OBSIDIAN
#RUBYGRAPHITE
#SAPPHIREKAMRI
#SILVER
#SLATECLASSICO
#SMOKEYQUARTZKAMRI
#TURQUOISEGRAY

[Config]
#Имя стиля
StyleName=Windows
#Ширины окна
Width=917
#Высота окна
Height=504
#Слева
Left=116
#Сверху
Top=58
#Последнее разрешение
LastResolutionWidth=1366
LastResolutionHeight=768
#Состояние окна
WindowState=0
