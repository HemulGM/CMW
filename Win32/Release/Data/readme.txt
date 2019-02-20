#������� "fix" ������ ������ �������

#---------------------------------------------------------------------------------
#EventLog.inf
#��������: ���� ������������ ������� ������� ������� Windows
[Presets]
#Timeslot - ��������� �������� (� ����), 14 (��� ������) - ���������
Timeslot=14

[EventSource]
#������������ ���������� ������� Windows
#Disk - ������� ������� � ���������� ������
#atapi - ������� ����������� atapi
#cdrom - ������� ����������� cdrom
#EventLog - ������� ��
#Microsoft-Windows-Kernel-General - ����������� ������ Windows
#Microsoft-Windows-Kernel-Power - ������ Windows
#Microsoft-Windows-WER-SystemErrorReporting - ������ Windows
#Ntfs - ������ �������� ������� NTFS
#volsnap - ������ �������� ����������� �����
Disk
Microsoft-Windows-Kernel-General
Microsoft-Windows-Kernel-Power
Microsoft-Windows-WER-SystemErrorReporting

#---------------------------------------------------------------------------------
#IgnoreApps.inf
#������ ���� ��������������, ������������� ���������� ������� ����� �������������� ��� ��������� ������ ������ ������������� ��������
microsoft
adobe
google
embarcadero
borland
nvidia

#---------------------------------------------------------------------------------
#ImPaths.inf
#������ �������� � �������, ��� �������� �� ����������
#������������ ��� ����=����
#����������:
# %USER% - ������� ������������
# %SYS32% - "C:\Windows\System32\"
# %SYS64% - "C:\Windows\SysWOW64\"
# %APPDATA% - "C:\Users\%USER%\AppData\Roaming\" ��� "C:\Documents and Settings\%USER%\Local Settings\"
# %TASKS% - "C:\Windows\Tasks\"
[Paths]
AppData=%APPDATA%\Temp
Windows Tasks=%APPDATA%\%TASKS%
User Doc=C:\Users\%USER%\Documents
MsConfig=msconfig

#---------------------------------------------------------------------------------
#WinApps.inf
#������������ ������ �������� ������������� ����������, ������� ������� �������
# ";" - ���� "���"
# "," - ���� "�"
#������ (guardian;toolbar;) - ����� ������� ����������, � �������� �������� ������������ ����� "guardian" ��� "toolbar".
#������ (qip,guard,) - ����� ������� ����������, � �������� �������� ������������ ������������ ����� "qip" � "guard".
guardian;toolbar;
qip,guard,
mail,guard,
qip,tools,
qip,toolbar,
auto,update,
������.���;������;�������;���������;
bing,bar,
ask,bar,
mail,�������,

#---------------------------------------------------------------------------------
#Config.inf
#���� ������������
#����� ��������� ������
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
#��� �����
StyleName=Windows
#������ ����
Width=917
#������ ����
Height=504
#�����
Left=116
#������
Top=58
#��������� ����������
LastResolutionWidth=1366
LastResolutionHeight=768
#��������� ����
WindowState=0
