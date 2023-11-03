'Erzeugt Progressbars (lauffähig ab XProfan 10.0)
'von Jacob Liebeck
'Version 1.1.1 (14.08.2006)
Def SetWindowTheme(3) !"uxtheme.dll","SetWindowTheme"

Subproc Create.Progressbar
'Erzeugt eine Progressbar (die meisten Parameter erklären sich von selbst
'Style: 0=Unterbrochene Linie, 1=durchgezogene Linie (kein Einfluss bei WinXP mit aktivierten Styles)
'       0=Windows-Default,2=Ohne Theme
'       0=Horizontal,4=Vertikal
'       0=kein Rahmen,8=Rahmen
'       Style wird durch Addieren der Einzelstyles ermittelt
'Color: Farbe des Balkens festlegen (als RGB(x,y,z)-Wert); -1=SystemDefault (kein Einfluss bei WinXP mit aktivierten Styles)
Parameters HWnd&,style&,color&,x&,y&,dx&,dy&
declare handle&,o%,t&
if TestBit(style&,1)
style&=SetBit(style&,1,0)
o%=1
endif
if TestBit(style&,3)
Sub style&,8
style&=SetBit(style&,23,1)
endif
declare a$
handle&=Control("MSCTLS_PROGRESS32","",$50000000+style&,x&,y&,dx&,dy&,HWnd&,1001,%hInstance,0)
case Neq(-1,color&):sendmessage(handle&,$409,0,color&)
t&=UseDLL("uxtheme.dll")
if t&
case o%:SetWindowTheme(handle&,"","")
FreeDLL t&
endif
Return handle&
endproc

proc SetProgress
Parameters handle&,wert&
'Setzt den Füllstand (in Prozent) einer Progressbar
sendmessage(handle&,$402,wert&,0)
endproc

proc GetProgress
'Liest den aktuellen Füllstand (in Prozent) der Progressbar aus
Parameters handle&
Return sendmessage(handle&,$405,0,0)
endproc

proc SetProgressColor
'Ändert die Farbe der Fortschrittsbalkens
Parameters handle&,color&
sendmessage(handle&,$409,0,color&)
endproc

