'Trackbar.inc
'Version 1.0 (ab XProfan 10.0)
'von Jacob Liebeck

subproc Create.Trackbar
Parameters hwnd&,style&,x%,y%,dx%,dy%
'Style:
'0=horizontal,2=vertikal
'$10=Keine Ticks,0=Ticks
'$100=Tooltip mit aktuellem Wert bei Verschieben
Return Control("msctls_trackbar32","",$50010020+style&,x%,y%,dx%,dy%,hwnd&,1003,%hInstance,$020000)
endproc

proc SetTrackPos
Parameters handle&,pos%
SendMessage(handle&,$405,1,pos%)
endproc

proc GetTrackPos
Parameters handle&
SendMessage(handle&,$400,0,0)
endproc

proc SetTrackRange
Parameters handle&,min%,max%
SendMessage(handle&,$406,1,min% | (max%*65536))
endproc

