#���������� ��� ����� "*.fix"
#Fix ��� ���������� � ��
#Name - �������� ��� ������� ��������
#Problem - ���������� ��������, ������� ���������� ��� �������
#Desc - ������ �������� ��������, ������� ��������
#Actions - ���-�� �������� (�� 1 �� N ����� ����������� �������)
#Act1-ActN - ������� �� �������
#Type - ��� �������
# cmd - ��������� ������� � CMD ��� ������ ���������
# cmdt - ��������� ������� � CMD � ������� ���� ��������� (+pause)
#  Command - ������� ��� ���������� � ��������� CMD
#  Info - �������� �������� �������� (�� �����������)
# msg - �������� ���������
#  QUERYREGPATHEXST(HKLM\SOFTWARE\Microsoft\MSLicensing) - ������ �� ������������� ���� 
#  QUERYREGKEYEXIST(HKLM\SOFTWARE\Microsoft\MSLicensing, KEYNAME) - ������ �� ������������� �����
#  QUERYREGKEYVALUE(HKLM\SOFTWARE\Microsoft\MSLicensing, KEYNAME, DATA) - ������ �� ���������� ������ �����
#TimeWait - ����� �������� ����� ����������� �������� (������)

[info]
Name=����� ������ �������� ��� �������
Problem=��� ������� ����������� � ��� ��������� ������ � ���������� ���������� ��������
Desc=������� ������ ������� "HKLM\SOFTWARE\Microsoft\MSLicensing"
Actions=2
TimeWait=1

[Act1]
Type=cmd
Command=reg HKLM\SOFTWARE\Microsoft\MSLicensing
Info=�������� ����� "HKLM\SOFTWARE\Microsoft\MSLicensing" �� �������

[Act2]
Type=msg
QUERY=QUERYREGPATHEXST(HKLM\SOFTWARE\Microsoft\MSLicensing) 
MessageWithTrue=��������� ��� ��������� �������������� ������ �� ������� ��� ��� ���������� �������
MessageWithFalse=��������� ��� ��������� �������������� ������ �� �������