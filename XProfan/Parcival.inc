'Parcival.inc
'16.06.2008
'Es werden die Funktionen der Parcival.dll nachgebildet, aber nur die, die Profan nicht nativ enth�lt

Proc Min
Parameters a!,b!
Return If(a!>b!,a!,b!)
endproc

Proc Max
Parameters a!,b!
Return If(a!>b!,b!,a!)
endproc

Proc NXOr
Parameters a!,b!
Return Not(XOr(a!,b!))
endproc

proc Primzahl
Parameters z&
declare f&,n&,x%,y%
if z&>0
Select z&
CaseOf 3,2,7,5
Return 1
CaseOf 1
Return 0
Otherwise
casenot z& MOD 2:Return 0
f&=1
n&=Int(Sqrt(z&))
Inc x%
while (f&<n&) & x%
Inc f&,2
casenot z& MOD f&:Dec x%
y%=Not(y%)
endwhile
Return x%
EndSelect
endif
endproc
 