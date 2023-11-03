{MaxInt64=9.223.372.036.854.775.807}
library Parcival;

uses
  Forms,
  SysUtils,
  Windows,
  StrUtils,
  Math,
  Graphics,
  Classes,
  dglOpenGL,
  Converter in 'Converter.pas';

{$R *.res}

const edition='Plus';ver='2.9.2.0093';pdate='28.12.2016';ErrorCnt=30;MinVer=11;
type TCallbackProc1=Function(S:Integer):Integer;stdcall;
type TCallbackProc2=Function(S1,S2:Integer):Integer;stdcall;
type PDouble=^Double;
var polys,err,itr,itis:^Integer;
gq:String='';
//callb:PChar;
fopen:Boolean=False;
ViewInit:Boolean=False;
Rendered:Boolean=False;
elog:Boolean=False;
fillalg,fillsep:Boolean;
eintrag:Integer=0;
eh:array [0..7] of Boolean;
xmin,xmax,ymin,ymax,zmin,zmax,xkoord,ykoord,zkoord:Double;
tmat:array [0..2,0..2] of extended;
yvals,xvals:array of Extended;
zvals:array of array of Extended;
zm1,zm2,hmid,amid,gmid:Extended;
xt,gl1,ergebnis,alg1,alg2,alg3:String;
error,xl,yl,t,mx,my,xleft,yleft,dx,dy,color,bcolor,feh,its:Integer;
f2,erg:PChar;
logfile:textfile;
exitsave:Pointer;
hdc1,hdc2:HDC;
pf3:Int64;
VarV,VarN:Array of String;

function Version(v:PChar):Integer;stdcall;
begin StrCopy(v,ver);Result:=Length(v);end;

function XDate(v:PChar):Integer;stdcall;
begin StrCopy(v,pdate);Result:=Length(v);end;

function XEdition(v:PChar):Integer;stdcall;
begin StrCopy(v,edition);Result:=Length(v);end;

function minimum():Integer;stdcall;
begin
Result:=MinVer;//Minumum-Version
end;

procedure CloseLog;inline;
begin
if fopen then begin Writeln(logfile,'Loggen beendet...'#13#10);CloseFile(logfile);end;
end;

function errcnt():Integer;stdcall;
begin Result:=ErrorCnt;end;

function errcode(x:Integer;e:PChar):Integer;stdcall;
var b,a:String;
begin
b:=IfThen((gq=''),'',' ("'+gq+'")');
case x of
0:a:='Kein Fehler!';
1:a:='Kein Term!';
2:a:='Klammern unausgewogen!';
3:a:='Unerlaubtes Zeichen im Term'+b+'!';
4:a:='Division durch Null!';
5:a:='Falsche Klammeranordnung!';
6:a:='Unerlaubte Position von "°", "²", "³" oder "!" in einer Zahl'+b+'!';
7:a:='Fakultät einer negativen Zahl nicht möglich!';
8:a:='Mehrere Dezimalpunkte sind nicht erlaubt'+b+'!';
9:a:='Mehrere aufeinander folgende Operatoren sind nicht erlaubt'+b+'!';
10:a:='Operator am Anfang oder Ende des Terms nicht erlaubt!';
11:a:='Unbekanntes Schlüsselwort oder Schlüsselwort mit falscher Parameteranzahl'+b+'!';
12:a:='Nicht definierter Funktionswert!';
13:a:='Mehrere Parameter ohne zugehörige Funktion!';
14:a:='Zahl außerhalb des Bereichs für diese Funktion!';
15:a:='Schrittweite nähert den Startwert nicht dem Endwert!';
16:a:='Schrittweite darf nicht 0 sein!';
17:a:='Funktion für diesen Wert nicht definiert!';
18:a:='Operator fehlt!';
19:a:='Nach einer der verwendeten Funktionen darf keine w1e Operation erfolgen'+b+'!';
20:a:='Natürliche Zahl erwartet!';
21:a:='3D-Fenster nicht initialisiert!';
22:a:='Unerlaubtes Ergebnis! Funktion abgebrochen!';
23:a:='Nicht genügend Speicher für diese Funktion!';
24:a:='Nichtnumerisches Zeichen in Wertetabelle!';
25:a:='Graph nicht gerendert!';
26:a:='Operation abgebrochen'+b+'!';
27:a:='Starteinheit ist nicht definiert!';
28:a:='Zieleinheit ist nicht definiert!';
29:a:='Maßeinheit ist nicht definiert!';
30:a:='Keine freien Callbacks mehr!'
else a:='Unbekannter Fehler';end;
StrCopy(e,PChar(a));
Result:=Length(a);
end;

procedure Log(m:String);inline;
var d:TDateTime;f:String;
begin
if fopen then begin d:=Now;f:=IntToStr(eintrag);Writeln(logfile,FormatDateTime('hh:mm:ss.zzz',d)+' - Eintrag-Nr. '+StringOfChar('0',6-Length(f))+f+': '+m);Inc(eintrag);Flush(logfile);end;
end;

procedure MyExit;
begin
DLLProc:=ExitSave;
Log('DLL wird vorzeitig beendet...');
if elog then begin Append(logfile);fopen:=True;CloseLog;end;
FreeMem(erg);
end;

function operator(f,op:String):Boolean;inline;
var b:Integer;
begin
Result:=False;
for b:=1 to Length(op) do begin
if ContainsStr(f,op[b]) then begin Result:=True;Break;end;
end;
end;

procedure se(e:Integer);inline;
begin
err^:=e;
if fopen then begin f2:=AllocMem(256);
ErrCode(e,f2);
Log('Fehler '+IntToStr(e)+' ist aufgetreten! ("'+f2+'")');
FreeMem(f2);end;
end;

function GetFile:String;inline;
var MemoryBasicInformation:TMemoryBasicInformation;DllPath:array[0..MAX_PATH] of Char;Len:DWord;
begin
Result:='';
if VirtualQuery(@GetModuleFileName,MemoryBasicInformation,SizeOf(TMemoryBasicInformation))=SizeOf(TMemoryBasicInformation) then begin
Len:=GetModuleFileNameA(DWord(MemoryBasicInformation.AllocationBase),DllPath,SizeOf(DllPath));
if (Len<=SizeOf(DllPath)) then Result:=DllPath;
end;
while (Result[Length(Result)]<>'\') do Result:=LeftStr(Result,Length(Result)-1);
end;

function SetErrorHandling(bit,wert:Integer):Integer;stdcall;
var f:Boolean;d:TDateTime;i:Integer;
begin
if (bit>High(eh)) OR (bit<0) then begin Log('Ungültiger Handler ('+IntToStr(bit)+')...');Result:=0;end else begin
d:=Now;
if (wert<>0) then f:=True else f:=False;
Log('Handler '+IntToStr(bit)+' von '+IfThen(eh[bit],'True','False')+' auf '+IfThen(f,'True','False')+' gesetzt.');
if (bit=4) then
if (wert<>0) AND (eh[4]) then Log('Loggen bereits eingeschaltet...')
else if (wert<>0) AND (Not(eh[4]))  then begin
AssignFile(logfile,GetFile()+'Log.txt');
Try Append(logfile) except on e:einouterror do Rewrite(logfile);end;
if Not(elog) then begin
Writeln(logfile,'Parcival-Logdatei');
Writeln(logfile,'Parcival-Version: '+ver+', '+pdate);
Writeln(logfile,'Beginn: '+FormatDateTime('dd.mm.yyyy - hh:mm',d));
elog:=True;
end;
fopen:=True;
for i:=0 to High(eh) do begin
if (i=4) then Write(logfile,'Handler 4=True') else write(logfile,'Handler '+IntToStr(i)+'='+IfThen(eh[i],'True','False'));
if (i<High(eh)) then write(logfile,', ') else writeln(logfile,'');end;
Log('Handler '+IntToStr(bit)+' von '+IfThen(eh[bit],'True','False')+' auf '+IfThen(f,'True','False')+' gesetzt.');
end
else begin if fopen then CloseFile(logfile);fopen:=False;end;
Result:=IfThen(eh[bit],1,0);
eh[bit]:=f;end;
end;

function GetErrorHandling(bit:Integer):Integer;stdcall;
begin
if eh[bit] then Result:=1 else Result:=0;
end;

function GetFirstOp(p,o:String):Integer;inline;
var i,a,r:Integer;
begin
i:=0;r:=Length(p);//+1 und in der for-schleife r-1
for a:=1 to r do begin
i:=Pos(MidStr(p,a,1),o);
if i>0 then begin i:=a;Break;end;
end;
if (i=r+1) then Result:=0 else Result:=i;
end;

function Isint(w:Extended):Boolean;inline;
begin
if ((w=Int(w)) or Not(eh[0])) then Result:=True else Result:=False;
end;

Procedure It(i:Integer);inline;
begin
Inc(itr^,i);
end;

function fak(f:Integer):Int64;inline;
var i:Integer;
begin
Result:=1;
for i:=2 to f do Result:=Result*i;
end;

function XVal(a:String):Extended;inline;
var x,av,e:Integer;o:String;ev:Extended;
begin
e:=0;
av:=0;
Result:=0;
gq:=a;
while (av<Length(a)) do begin Inc(av);
if not(ContainsStr('§0123456789,°²³!~#',a[av])) then begin Inc(e);Break;end;
end; //while (av...)
if (e<>0) then begin se(3);exit;end;
if ContainsStr(a,',') then begin
if ContainsStr(RightStr(a,Length(a)-Pos(',',a)),',') then begin Se(8);exit;end;end;
if Operator(a,'°³!²') then begin
  e:=Length(a);
  while not(ContainsStr('0123456789,~§#',a[e])) do Dec(e);
if Operator(LeftStr(a,e),'°!²³') then begin Se(6);exit; end else begin
    o:=RightStr(a,Length(a)-e);
    a:=LeftStr(a,e);
    ev:=StrToFloat(ReplaceStr(ReplaceStr(ReplaceStr(a,'#','E-'),'~','E+'),'§','-'));
    av:=0;
    x:=0;//unnötig
    while (av<Length(o)) do begin
      Inc(av);
      if ('!'=o[av]) then begin
        if IsInt(ev) then x:=Trunc(ev) else begin
          Se(20);exit;end;
        if (x<1) then begin
          Se(7);exit;end;
          ev:=Fak(x);end
      else if ('°'=o[av]) then begin It(1);ev:=ev/57.295779513082320876798154814105;end else
      if ('²'=o[av]) then begin it(1);ev:=Sqr(ev);end else
      if ('³'=o[av]) then begin it(1);ev:=Power(ev,3);end;
      end; // while (a<...)
    if (err^<>0) then exit;end; // if operator...(innen)
  Result:=ev end
else begin
  Result:=StrToFloat(ReplaceStr(ReplaceStr(ReplaceStr(a,'#','E-'),'~','E+'),'§','-'));
end; // if Operator...(außen)
end;

function XStr(a:Extended):String;inline;
begin
if a<0 then Result:='§'+FloatToStr(Abs(a)) else Result:=FloatToStr(a);
Result:=ReplaceStr(ReplaceStr(Result,'E-','#'),'E','~');
end;

function GetBefore(f:String;g:Integer):String;inline;
var r:Integer;
begin
r:=g-1;
while ((r>1) and ContainsStr('0123456789,§!°²³~#',f[r-1])) do Dec(r);
Result:=MidStr(f,r,g-r);
xl:=Length(Result);
end;

function GetAfter(f:String;g:Integer):String;inline;
var r:Integer;
begin
r:=g+1;
while ContainsStr('0123456789,§!°²³~#',f[r+1]) do Inc(r);
Result:=MidStr(f,g+1,r-g);
yl:=Length(result);
end;

function Calculate(x:String):String;//inline;
var a,b,p,c:Integer;zv,xv,yv:Extended;xla,yla:String;
begin
c:=0;
zv:=0;
while (c<3) do begin
b:=GetFirstOp(x,Trim(MidStr('^  */\+- &| =<>',3*c+1,3)));
while (b<>0) do begin
a:=Pos(x[b],'^*/\+-&|=<>');
if (ContainsStr('^*/\+-&|=<>;()',x[b-1]) or ContainsStr('^*/\+-&|=<>;()',x[b+1])) then begin Se(9);exit;end else
if ((b=Length(x)) or (b=1)) then begin Se(10);exit;end;
xv:=XVal(GetBefore(x,b));
if (err^<>0) then exit;
yv:=XVal(GetAfter(x,b));
if (err^<>0) then exit;
if (a=1) then begin
  if ((xv<0) and (yv<>Int(yv))) then begin Se(17);exit;end;
  if (xv=0) then zv:=0 else if (xv<0) then begin
    if (xv=Int(xv)) then begin
      if ((Trunc(yv) Mod 2)=0) then p:=1 else p:=-1;
      zv:=Power(Abs(xv),yv)*p;end
    else if (yv=Int(yv)) then begin
      if ((Trunc(yv) Mod 2)=0) then p:=1 else p:=-1;
      zv:=Power(Abs(xv),yv)*p;end
      else begin Se(14);exit;end;
    end
  else
  zv:=Power(xv,yv);end
else begin if (a=2) then zv:=xv*yv else if (a=3) then begin
if (yv=0) then begin Se(4);exit;end else zv:=xv/yv;
end else if (a=4) then begin if (yv=0) then begin Se(4);exit;end else zv:=Int(xv/yv);end else
if (a=5) then zv:=xv+yv else if (a=6) then zv:=xv-yv
else if (a=7) then begin if (IsInt(xv) and IsInt(yv)) then begin zv:=Trunc(xv) And Trunc(yv);end else begin Se(20);exit;end;end
else if (a=8) then begin if (IsInt(xv) or IsInt(yv)) then begin zv:=Trunc(xv) And Trunc(yv);end else begin Se(20);exit;end;end;
end;
It(1);
xla:=LeftStr(x,b-1-xl);
yla:=RightStr(x,Length(x)-1-xl-yl-Length(xla));
x:=xla+XStr(zv)+yla;
b:=GetFirstOp(x,Trim(MidStr('^  */\+- &| =<>',3*c+1,3)));
end; // while (b<>0)
if (err^<>0) then Break;
Inc(c);
end; // while (c<3)
Result:=x;
end;

function base(x,b:Integer):String;inline;
Var z,l:Integer;
begin
It(3);
For l:=Trunc(LogN(b,x)) downto 0 do begin
z:=Trunc(x*Power(b,-l));
if (z>0) then begin Result:=Result+'123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'[z];x:=x-z*Round(Power(b,l));It(7);end else Result:=Result+'0';It(2);
end;end;

function fracpc(x:Extended;u:Integer):String;inline;
var d,b:Extended;n,r:Integer;
begin
b:=x-Int(x);
d:=Power(10,-1*u);
It(4);
n:=0;
while True do begin Inc(n);
if ((b*n-Int(b*n)+d>=1) Or (b*n-Int(b*n)-d>=0)) then Break;
It(16);
end;
It(15);
r:=Trunc(n*x);
if (n*x-Int(n*x)+d>1) then Inc(r);
Result:=IntToStr(r)+'/'+IntToStr(n);
end;

function SumTeil(w:Integer):Integer;inline;
var c:Integer;
begin
c:=0;
Result:=0;
while (c<w-1) do begin Inc(c);if (w mod c=0) then begin Inc(Result,c);It(1);end;end;
end;

function befreundet(x,y:Integer):Integer;inline;
begin
if (SumTeil(Min(x,y))=Max(x,y)) then Result:=1 else Result:=0;
end;

function GGT(c,d:Integer):Integer;inline;
var y:Integer;
begin
y:=Min(c,d);
d:=Max(c,d);
while (y>0) do begin c:=y;y:=(d mod y);d:=c;It(3);end;
Result:=d;
end;

function KGV(d,e:Integer):Integer;inline;
begin
It(3);
Result:=(d*e Div GGT(d,e));
end;

function Isprim(z:Integer):Integer;inline;
var f,n:Integer;xi:Boolean;
begin
It(4);
Result:=0;
if (z<11) then if ((z=2) or (z=3) or (z=7) or (z=5)) then begin Result:=1;exit;end else exit;
if (z mod 2=0) then exit;
f:=1;
xi:=True;
n:=Trunc(Sqrt(z));
while ((f<n) and xi) do begin
Inc(f,2);
if (z mod f=0) then xi:=False;
It(4);
end;
It(1);
if xi then Result:=1;
end;

function XTime(d:Extended;f:Integer):String;inline;
var u:Boolean;r:Integer;s:String;
begin
Result:='';
u:=False;
if ((f<0) or (f>9)) then begin Se(14);exit;end else begin
if f>4 then begin Dec(f,5);u:=True;end;
Result:=IntToStr(Trunc(d))+IfThen(u,'°','h');
d:=60*Frac(d);
r:=Trunc(d);
Result:=Result+IfThen(r<10,'0')+IntToStr(r)+IfThen(u,'''','m');
d:=60*Frac(d);
r:=Trunc(d);
if (f<4) then Result:=Result+IfThen(r<10,'0')+IntToStr(Trunc(d));
if (f<3) then begin s:=IntToStr(Trunc(Power(10,(3-f))*Frac(d)));if Length(s)<(3-f) then s:=StringOfChar('0',(3-f)-Length(s))+s;
Result:=Result+'.'+s;end;
Result:=Result+IfThen(u,'"','s');
end;
end;

function arabtoroem(zahl:Integer):String;inline;
begin Result:='';
While (Zahl>=1000) do begin Result:=Result+'M';Dec(zahl,1000);It(3);end;
if (Zahl>=900) then begin Result:=Result+'CM';Dec(zahl,900);It(3);end;
if (Zahl>=500) then begin Result:=Result+'D';Dec(zahl,500);It(3);end;
if (Zahl>=400) then begin Result:=Result+'CD';Dec(zahl,400);It(3);end;
While (Zahl>=100) do begin Result:=Result+'C';Dec(zahl,100);It(3);end;
if (Zahl>=90) then begin Result:=Result+'XC';Dec(zahl,90);It(3);end;
if (Zahl>=50) then begin Result:=Result+'L';Dec(zahl,50);It(3);end;
if (Zahl>=40) then begin Result:=Result+'XL';Dec(zahl,40);It(3);end;
While (Zahl>=10) do begin Result:=Result+'X';Dec(zahl,10);It(3);end;
if (Zahl>=9) then begin Result:=Result+'IX';Dec(zahl,9);It(3);end;
if (Zahl>=5) then begin Result:=Result+'V';Dec(zahl,5);It(3);end;
if (Zahl>=4) then begin Result:=Result+'IV';Dec(zahl,4);It(3);end;
While (Zahl>0) do begin Result:=Result+'I';Dec(zahl);It(3);end;
end;

procedure GetLastResult(e:PChar);stdcall;
begin
StrCopy(e,PChar(ergebnis));
end;

function RoemToArab(x:String):Integer;inline;
begin
Result:=0;
while (Length(x)>0) And (x[1]='m') do begin Inc(Result,1000);x:=RightStr(x,Length(x)-1);end;
if (LeftStr(x,2)='cm') then begin Inc(Result,900);x:=RightStr(x,Length(x)-2);end;
if (Length(x)>0) And (x[1]='d') then begin Inc(Result,500);x:=RightStr(x,Length(x)-1);end;
if (LeftStr(x,2)='cd') then begin Inc(Result,400);x:=RightStr(x,Length(x)-2);end;
while (Length(x)>0) And (x[1]='c') do begin Inc(Result,100);x:=RightStr(x,Length(x)-1);end;
if (LeftStr(x,2)='xc') then begin Inc(Result,90);x:=RightStr(x,Length(x)-2);end;
if (Length(x)>0) And (x[1]='l') then begin Inc(Result,50);x:=RightStr(x,Length(x)-1);end;
if (LeftStr(x,2)='xl') then begin Inc(Result,40);x:=RightStr(x,Length(x)-2);end;
while (Length(x)>0) And (x[1]='x') do begin Inc(Result,10);x:=RightStr(x,Length(x)-1);end;
if (LeftStr(x,2)='ix') then begin Inc(Result,9);x:=RightStr(x,Length(x)-2);end;
if (Length(x)>0) And (x[1]='v') then begin Inc(Result,5);x:=RightStr(x,Length(x)-1);end;
if (LeftStr(x,2)='iv') then begin Inc(Result,4);x:=RightStr(x,Length(x)-2);end;
while (Length(x)>0) And (x[1]='i') do begin Inc(Result);x:=RightStr(x,Length(x)-1);end;
end;

function repconst(f,c,v:String):String;inline;
var d:Integer;
begin
d:=Pos(f,c);
while (d>0) do begin
if (d>1) And Not(ContainsStr('+-*/^\&|=<>(',f[d-1])) then begin f:=LeftStr(f,d-1)+'*'+RightStr(f,Length(f)-d);Inc(d);end;
if Not(ContainsStr('+-*/^\&|=<>)',f[d+Length(c)])) then begin f:=LeftStr(f,d+Length(c))+'*'+RightStr(f,Length(f)-d-Length(c)-1);Inc(d);end;
f:=StuffString(f,d,Length(c),v);d:=Pos(f,c);//NEU
end;
Result:=f;
end;

function PreParse(fx:String):String;inline;
var e,f,l:Integer;pf1,pf2:Int64;
begin
queryperformancecounter(pf1);
error:=0;
Log('Präparsen von '+fx+'...');
if (fx='') then begin error:=1;exit end;
if Operator(fx,'#§~') then begin error:=3;exit end;
if ContainsStr('°!²³',LeftStr(fx,1)) then begin error:=10;exit;end;
fx:=RepConst(RepConst(RepConst(RepConst(RepConst(RepConst(ReplaceStr(ReplaceStr(ReplaceStr(ReplaceStr(ReplaceStr(ReplaceStr(ReplaceStr(ReplaceStr(LowerCase(fx),' ',''),']',')'),'}',')'),'{','('),'[','('),'<','('),'>',')'),'%pi%','3.14159265358979323264'),'%phi%','1.6180339887498948482'),'%ez%','2.71828182845904523536'),'%if%','19771210'),'%ans%','%ans%'),'%x%','%x%'),'%y%','%y%');
if Operator(LeftStr(fx,1)+RightStr(fx,1),'^*/+\-&|=<>;') then begin error:=10;exit;end;
f:=0;
l:=Length(fx);
while (f<l) do begin Inc(f);
if ((f>1) and ('('=fx[f]) and ContainsStr('0123456789,°!²³)',fx[f-1])) then begin Inc(l);fx:=LeftStr(fx,f-1)+'*'+RightStr(fx,l-f);end;end;
f:=0;e:=0;
while (f<l) do begin Inc(f);if (fx[f]='(') then Inc(e) else if (fx[f]=')') then Dec(e);end;
if (e<0) then begin error:=5;exit;end;
if (e>0) then fx:=fx+StringOfChar(')',e);
fx:='('+fx+')';
Result:=fx;
queryperformancecounter(pf2);
Log('...wird zu '+fx+' ('+Format('%1.3f',[1000*(pf2-pf1)/pf3])+'ms)');
end;

function Vorzeichen(a,b:Extended):String;inline;
var idx:Integer;
begin
idx:=Trunc(Log10(Abs(a))/3+9);
if (idx<1) then idx:=1 else if (idx>15) then idx:=15;
a:=Round(a/Power(10,3*(idx-9)-b))/Power(10,b);
Result:=FloatToStr(a);
if Not(ContainsStr(Result,',')) then Result:=Result+',';
Result:=Result+IfThen(Length(Result)-Pos(',',Result)<b,StringOfChar('0',Trunc(b-Length(Result)+Pos(',',Result))))+IfThen((idx<>9),'yzafpnµm.kMGTPEZY'[idx]);
It(32);
end;

function CBase(a:Integer;b:String):String;inline;
var l,i:Integer;e:Int64;
begin
l:=Length(b);
e:=0;
Result:='';
for i:=1 to l do e:=e+Trunc(Pos(b[i],'123456789abcdefghijklmnopqrstuvwxyz')*Power(a,l-i));
Result:=IntToStr(e);
end;

function Quersum(x:Extended):Extended;inline;
var b,a:Integer;
begin
Result:=0;
a:=Ceil(Log10(x));
For b:=a+1 downto 1 do Result:=Result+Trunc(10*Frac(x*Power(10,-b)));
end;

function CTime(a:String):String;inline;
var h,z:Extended;
begin
Result:='';
a:=ReplaceStr(ReplaceStr(ReplaceStr(ReplaceStr(a,'°','h'),'''','m'),'"','s'),'.',',');
if ContainsStr(a,'h') then if TryStrToFloat(LeftStr(a,Pos('h',a)-1),z) then a:=RightStr(a,Length(a)-Pos('h',a)) else exit;
if ContainsStr(a,'m') then begin if TryStrToFloat(LeftStr(a,Pos('m',a)-1),h) then begin z:=z+h/60;a:=RightStr(a,Length(a)-Pos('m',a));end else exit;end;
if ContainsStr(a,'s') then if TryStrToFloat(LeftStr(a,Pos('s',a)-1),h) then z:=z+h/3600 else exit;
Result:=FloatToStr(z);
end;

function RON(x:Extended):String;inline;
begin
Result:='R;'+IfThen((x>0),'R+,')+IfThen((x<0),'R-,')+'Q,'+IfThen((x>0),'Q+,')+IfThen((x<0),'Q-,')+IfThen(x=Int(x),'Z')+IfThen((x>0) And (x=Int(x)),'Z+,N,')+IfThen((x<0) And (x=Int(x)),'Z-,');
Result:=LeftStr(Result,Length(Result)-1);
end;

function Thousands(x:Extended):String;inline;
var b,a:Integer;d:String;
begin
a:=Trunc(Log10(x))+1;
for b:=0 to Trunc((a/3)) do begin
d:=IntToStr(Trunc(1000*Frac(x/IntPower(10,3*b+3))));
while Length(d)<3 do d:='0'+d;
Result:=Chr($27)+d+Result;
end;
Delete(Result,1,1);
while LeftStr(Result,4)='000'+Chr($27) do Delete(Result,1,2);
d:=FloatToStr(Frac(x));
Delete(d,1,1);
if Length(d)<>0 then Result:=Result+d;
while (LeftStr(Result,1)='0') And (MidStr(Result,2,1)<>Chr($27)) do Delete(Result,1,1);  
end;

Function SetVar(a,b:String):Integer;inline;
var l:Integer;m:Boolean;
begin
Result:=0;
m:=True;
for l:=0 to High(VarN) do if a=VarN[l] then begin VarV[l]:=b;m:=False;Result:=l;Break;end;
if m then begin
SetLength(VarN,High(VarN)+1);
SetLength(VarV,High(VarV)+1);
VarN[High(VarN)]:=a;
VarV[High(VarV)]:=b;
Result:=High(VarN);end;
end;

function SetVariable(a,b:String):Integer;stdcall;
begin
Result:=SetVar(a,b);
end;

function Parse(fx:String;term2:PChar;fehler,iterations,mode:Integer):Integer;stdcall;
var l,g,f,e:Integer;goon,comma:Boolean;z,p,q,es,svar:String;x,y,ze:Extended;tr:TRoundToRange;a1,b1:Double;
label w1,w2;
begin
Log('Parsen von '+fx+'...');
gq:='';ze:=0;
err:=Ptr(fehler);
itr:=Ptr(iterations);
if (mode=1) then begin fx:=PreParse(fx);if (error>0) then begin Se(error);exit;end;end;
for l:=0 to High(VarN) do if ContainsStr(fx,'%'+VarN[l]+'%') then fx:=ReplaceStr(fx,'%'+VarN[l]+'%',VarV[l]); 
fx:=ReplaceStr(ReplaceStr(ReplaceStr(ReplaceStr(fx,'(-','(§'),'e+','~'),'e-','#'),'%ans%','('+ergebnis+')');
if eh[1] then ReplaceStr(fx,',',';');
fx:=ReplaceStr(fx,'.',',');
if (LeftStr(fx,2)='-') then fx:='(0'+RightStr(fx,Length(fx)-1);
f:=0;
l:=Length(fx);
while (f<l) do begin Inc(f);
if ((fx[f]='-') and Not(ContainsStr('0123456789,°²³!)',fx[f-1]))) then begin fx:=StuffString(fx,f,1,'§');l:=Length(fx);end;
if (fx[f]=')') And ContainsStr('1234567890,§',fx[f+1]) then begin Se(18);exit;end;end;
if ('(§)'=fx) Or ('(#)'=fx) then begin Se(10);exit;end;
goon:=False;
e:=Pos('input(',fx);
while (e<>0) do begin
f:=e+6;
while (fx[f]<>')') do Inc(f);
p:=MidStr(fx,e+6,f-e-6);
q:=LeftStr(p,Pos(';',p)-1);
p:=RightStr(p,Length(p)-Length(q)-1);
if (q='roem') then z:=IntToStr(RoemToArab(p));
{if (q='ord') then z:=IntToStr(Ord(LeftStr(ze,1)));}
if (q='time') then begin z:=CTime(p);if (z='') then begin Se(12);exit;end;end;
if (Length(q)>0) then if TryStrToInt(q,g) then if (g<37) And (g>1) then z:=CBase(g,p) else begin Se(17);exit;end;
fx:=LeftStr(fx,e-1)+z+RightStr(fx,Length(fx)-f);
e:=Pos('input(',fx);end;
if ContainsStr(fx,'%') then if ContainsStr(fx,':=') then begin svar:=ReplaceStr(LeftStr(fx,Pos(fx,':=')-1),'%','');Delete(fx,0,Pos(fx,':=')+1);end;
Log('Parsvorgang für '+fx);
while (Not(goon) And ContainsStr(fx,'(')) do begin //Beginn der Berechnungen
e:=Length(fx);
while ('('<>fx[e]) do Dec(e);
z:=RightStr(fx,Length(fx)-e);
z:=LeftStr(z,Pos(')',z)-1);
p:=LeftStr(fx,e-1);
f:=Length(z);
g:=Length(p);
while (Not(ContainsStr('0123456789/^*+-,\&|=<>!°²³();',MidStr(p,g,1))) and (g>1)) do Dec(g);
q:=RightStr(p,Length(p)-g);
p:=LeftStr(p,Length(p)-Length(q));
//p=alles vor der Funktion
//q=Erwe1terte Funktion
//f=Länge der Operation für Calculate
//g=wieder frei verfügbar
if operator(z,'+-*/\^;') then begin //if operator...
if goon then begin gq:=q;Se(19);exit;end;
z:=calculate(z);end//if Operator...
//Komplexere Operationen:
else if ContainsStr(z,';') then z:=XStr(XVal(GetBefore(z,Pos(';',z))))+';'+XStr(XVal(GetAfter(z,Pos(';',z)))) else z:=XStr(XVal(z));
if (err^<>0) then Break;
comma:=True;
if ((''=q) and ContainsStr(z,';')) then begin Se(13);exit;end;
//Operationen mit 2 Parametern...
if (q<>'') then begin
if ContainsStr(z,';') then begin
x:=XVal(GetBefore(z,Pos(';',z)));
if (err^<>0) then Break;
y:=XVal(GetAfter(z,Pos(';',z)));
if (err^<>0) then Break;
It(1);
if (q='log') then if (x<0) then begin Se(17);exit;end else begin ze:=Ln(x)/Ln(y);Goto w2;end;
if (q='shl') then if (IsInt(x) and IsInt(y)) then begin ze:=Trunc(x) Shl Trunc(y);Goto w2;end else begin Se(20);exit;end;
if (q='shr') then if (IsInt(x) and IsInt(y)) then begin ze:=Trunc(x) Shr Trunc(y);Goto w2;end else begin Se(20);exit;end;
if (q='mod') then begin if (Isint(x) and Isint(y)) then begin ze:=Trunc(x) Mod Trunc(y);It(2);Goto w2;end else begin Se(20);exit;end;end;
if (q='root') then begin if (y=0) then begin Se(17);exit;end else if ((x<0) And Not(Odd(Trunc(y)))) then begin Se(17);exit;end;ze:=Power(x,1/y);Goto w2;end;
if (q='round') then if IsInt(y) then begin tr:=Trunc(y);ze:=SimpleRoundTo(x,-1*tr);It(1);Goto w2;end else begin Se(20);exit;end;
if (q='min') then begin ze:=Min(x,y);Goto w2;end;
if (q='max') then begin ze:=Max(x,y);Goto w2;end;
if (q='and') then if (IsInt(x) and IsInt(y)) then begin if eh[3] then ze:=Trunc(x) And Trunc(y) else ze:=IfThen((y<>0) And (x<>0),1,0);Goto w2;end else begin Se(20);exit;end;
if (q='or') then if (IsInt(x) and IsInt(y)) then begin if eh[3] then ze:=Trunc(x) Or Trunc(y) else ze:=IfThen((y<>0) Or (x<>0),1,0);Goto w2;end else begin Se(20);exit;end;
if (q='xor') then if (IsInt(x) and IsInt(y)) then begin if eh[3] then ze:=Trunc(x) XOr Trunc(y) else ze:=IfThen((y<>0) XOr (x<>0),1,0);Goto w2;end else begin Se(20);exit;end;
if (q='nxor') then if (IsInt(x) and IsInt(y)) then begin if eh[3] then ze:=Not(Trunc(x) XOr Trunc(y)) else ze:=IfThen((y<>0) XOr (x<>0),0,1);Goto w2;end else begin Se(20);exit;end;
if (q='nand') then if (IsInt(x) and IsInt(y)) then begin if eh[3] then ze:=Not(Trunc(x) And Trunc(y)) else ze:=IfThen((y<>0) And (x<>0),0,1);Goto w2;end else begin Se(20);exit;end;
if (q='nor') then if (IsInt(x) and IsInt(y)) then begin if eh[3] then ze:=Not(Trunc(x) Or Trunc(y)) else ze:=IfThen((y<>0) Or (x<>0),0,1);Goto w2;end else begin Se(20);exit;end;
if (q='band') then if (IsInt(x) and IsInt(y)) then begin ze:=Trunc(x) And Trunc(y);Goto w2;end else begin Se(20);exit;end;
if (q='bor') then if (IsInt(x) and IsInt(y)) then begin ze:=Trunc(x) Or Trunc(y);Goto w2;end else begin Se(20);exit;end;
if (q='bxor') then if (IsInt(x) and IsInt(y)) then begin ze:=Trunc(x) XOr Trunc(y);Goto w2;end else begin Se(20);exit;end;
if (q='bnxor') then if (IsInt(x) and IsInt(y)) then begin ze:=Not(Trunc(x) XOr Trunc(y));Goto w2;end else begin Se(20);exit;end;
if (q='bnand') then if (IsInt(x) and IsInt(y)) then begin ze:=Not(Trunc(x) And Trunc(y));Goto w2;end else begin Se(20);exit;end;
if (q='bnor') then if (IsInt(x) and IsInt(y)) then begin ze:=Not(Trunc(x) Or Trunc(y));Goto w2;end else begin Se(20);exit;end;
if (q='ident') then if (IsInt(x) and IsInt(y)) then if (y<>0) And (y<>1) then begin Se(14);exit;end else begin if y=0 then if x=0 then ze:=0 else ze:=1 else if x=1 then ze:=1 else ze:=0;Goto w2;end else begin Se(20);exit;end;
if (q='pol') then begin ze:=Sqrt(Sqr(x)+Sqr(y));Goto w2;end;
if (q='equ') then begin ze:=IfThen(Trunc(x)=Trunc(y),1,0);Goto w2;end;
if (q='neq') then begin ze:=IfThen(Trunc(x)<>Trunc(y),1,0);Goto w2;end;
if (q='lt') then begin ze:=IfThen(Trunc(x)<Trunc(y),1,0);Goto w2;end;
if (q='lte') then begin ze:=IfThen(Trunc(x)<=Trunc(y),1,0);Goto w2;end;
if (q='gt') then begin ze:=IfThen(Trunc(x)>Trunc(y),1,0);Goto w2;end;
if (q='gte') then begin ze:=IfThen(Trunc(x)>=Trunc(y),1,0);Goto w2;end;
if (q='sci') then if IsInt(y) then begin es:=Vorzeichen(x,y);goon:=True;Goto w2;end else begin Se(20);exit;end;
if (q='divmod') then if IsInt(y) then begin es:=IntToStr(Trunc(x) Div Trunc(y))+';'+IntToStr(Trunc(x) Mod Trunc(y));goon:=True;It(3);Goto w2;end else begin Se(20);exit;end;
if (q='time') then if IsInt(y) then begin es:=XTime(x,Trunc(y));goon:=True;It(15);Goto w2;end else begin Se(20);exit;end;
if (q='base') then begin if (IsInt(x) and IsInt(y)) then begin if ((y>36) or (y<2)) then begin Se(17);exit;end;es:=Base(Trunc(x),Trunc(y));goon:=True;Goto w2;end else begin Se(20);exit;end;end;
if (q='fracpc') then begin if Isint(y) then begin es:=FracPC(x,Trunc(y));goon:=True;Goto w2;end else begin Se(20);exit;end;end;
if (q='teiler') then if (IsInt(x) and IsInt(y)) then begin ze:=Not(Trunc(x) Mod Trunc(y));It(1);Goto w2;end else begin Se(20);exit;end;
if (q='ggt') then if (IsInt(x) and IsInt(y)) then begin ze:=GGT(Trunc(x),Trunc(y));It(2);Goto w2;end else begin Se(20);exit;end;
if (q='kgv') then if (IsInt(x) and IsInt(y)) then begin ze:=KGV(Trunc(x),Trunc(y));It(2);Goto w2;end else begin Se(20);exit;end;
if (q='digit') then if IsInt(y) then begin ze:=Int(10*Frac(x/Power(10,y)));It(4);Goto w2;end else begin Se(20);exit;end;
if (q='varback') then if (IsInt(x) and IsInt(y)) then begin ze:=Power(Trunc(x),Trunc(y));Goto w2;end else begin Se(20);exit;end;
if (q='varnoback') then if (IsInt(x) and IsInt(y)) then begin ze:=Fak(Trunc(x))/Fak(Trunc(x)-Trunc(y));Goto w2;end else begin Se(20);exit;end;
if (q='kombback') then if (IsInt(x) and IsInt(y)) then begin ze:=Fak(Trunc(x)+Trunc(y)-1)/(Fak(Trunc(y))*Fak(Trunc(x)-1));Goto w2;end else begin Se(20);exit;end;
if (q='kombnoback') then if (IsInt(x) and IsInt(y)) then begin ze:=Fak(Trunc(x))/(Fak(Trunc(y))*Fak(Trunc(x)-1));Goto w2;end else begin Se(20);exit;end;
if (q='quasibefreundet') then if (IsInt(x) and IsInt(y)) then begin if ((SumTeil(Trunc(x))-1=y) and (SumTeil(Trunc(y))-1=x)) then ze:=1 else ze:=0;Goto w2;end else begin Se(20);exit;end;
if (q='befreundet') then if (IsInt(x) and IsInt(y)) then begin ze:=Befreundet(Trunc(x),Trunc(y));It(2);Goto w2;end else begin Se(20);exit;end;
Se(11);gq:=q;exit;
w2:
comma:=False;
if goon then z:=es else z:=XStr(ze);
end; //Komplexe Berechnungen mit 2 Parametern...
//Operationen mit 1 Parameter...
if comma and Not(ContainsStr(z,';')) then begin
It(1);
ze:=XVal(z);
if (q='sqr') then begin ze:=Sqr(Abs(ze));Goto w1;end;
if (q='sqrt') then if (ze<0) then begin Se(17);exit;end else begin ze:=Sqrt(ze);Goto w1;end;
if (q='cos') then begin ze:=Cos(ze);Goto w1;end;
if (q='sin') then begin ze:=Sin(ze);Goto w1;end;
if (q='tan') then if (Cos(ze)=0) then begin Se(17);exit;end else begin ze:=Tan(ze);Goto w1;end;
if (q='crd') then begin ze:=2*Sin(ze/2);Goto w1;end;
if (q='versin') then begin ze:=1-Cos(ze);Goto w1;end;
if (q='vercosin') then begin ze:=1+Cos(ze);Goto w1;end;
if (q='coversin') then begin ze:=1-Sin(ze);Goto w1;end;
if (q='covercosin') then begin ze:=1+Sin(ze);Goto w1;end;
if (q='haversin') then begin ze:=(1-Cos(ze))/2;Goto w1;end;
if (q='havercosin') then begin ze:=(1+Cos(ze))/2;Goto w1;end;
if (q='hacoversin') then begin ze:=(1-Sin(ze))/2;Goto w1;end;
if (q='hacoversocin') then begin ze:=(1+Sin(ze))/2;Goto w1;end;
if (q='exsec') then if (Cos(ze)=0) then begin err^:=12;exit;end else begin ze:=secant(ze)-1;Goto w1;end;
if (q='excosec') then if (Sin(ze)=0) then begin err^:=12;exit;end else begin ze:=csc(ze)-1;Goto w1;end;
if (q='cot') then if (Sin(ze)=0) then begin Se(17);exit;end else begin ze:=Cot(ze);Goto w1;end;
if (q='ln') then if (ze<0) then begin Se(17);exit;end else begin ze:=Ln(ze);Goto w1;end;
if (q='lg') then if (ze<0) then begin Se(17);exit;end else begin ze:=Log10(ze);Goto w1;end;
if (q='abs') then begin ze:=Abs(ze);Goto w1;end;
if (q='int') then begin ze:=Int(ze);Goto w1;end;
if (q='frac') then begin ze:=Frac(ze);Goto w1;end;
if (q='ceil') then begin ze:=Ceil(ze);Goto w1;end;
if (q='floor') then begin ze:=Floor(ze);Goto w1;end;
if (q='pred') then if IsInt(ze) then begin ze:=Pred(Trunc(ze));It(1);Goto w1;end else begin Se(20);exit;end;
if (q='succ') then if IsInt(ze) then begin ze:=Succ(Trunc(ze));It(1);Goto w1;end else begin Se(20);exit;end;
if (q='neg') then ze:=-1*ze;
if (q='reziproke') then begin if (ze<>0) then ze:=1/ze;Goto w1;end;
if (q='digits') then if IsInt(ze) then begin if (ze=0) then ze:=1 else ze:=1+Int(Log10(ze));Goto w1;end else begin Se(20);exit;end;
if (q='even') then if IsInt(ze) then begin if Not(Odd(Trunc(ze))) then ze:=1 else ze:=0;It(3);Goto w1;end else begin Se(20);exit;end;
if (q='odd') then if IsInt(ze) then begin if Odd(Trunc(ze)) then ze:=1 else ze:=0;It(3);Goto w1;end else begin Se(20);exit;end;
if (q='vollkommen') then if IsInt(ze) then begin ze:=Befreundet(Trunc(ze),Trunc(ze));It(2);Goto w1;end else begin Se(20);exit;end;
if (q='sign') then begin ze:=Sign(ze);Goto w1;end;
if (q='arabtoroem') or (q='roem') then if (IsInt(ze) and (Int(ze)>0)) then begin es:=ArabtoRoem(Trunc(ze));goon:=True;Goto w1;end else begin Se(20);exit;end;
if (q='quersum') then if IsInt(ze) then begin ze:=Quersum(ze);Goto w1;end else begin Se(20);exit;end;
if (q='xquersum') then if IsInt(ze) then begin while (ze>9) do ze:=Quersum(ze);Goto w1;end else begin Se(20);exit;end;
if (q='lz') then if (ze<0) then begin Se(17);exit;end else begin ze:=Log2(ze);Goto w1;end;
if (q='exp') then begin ze:=Exp(ze);Goto w1;end;
if (q='not') then if IsInt(ze) then begin if eh[3] then ze:=Not Trunc(ze) else ze:=IfThen((ze=0),1,0);Goto w1;end else begin Se(20);exit;end;
if (q='bnot') then if IsInt(ze) then begin ze:=Not Trunc(ze);Goto w1;end else begin Se(20);exit;end;
if (q='arctan') then begin ze:=ArcTan(ze);Goto w1;end;
if (q='sec') then if (Cos(ze)=0) then begin Se(12);exit;end else begin ze:=secant(ze);Goto w1;end;
if (q='cosec') then if (Sin(ze)=0) then begin Se(12);exit;end else begin ze:=csc(ze);Goto w1;end;
if (q='arcsin') then if (Sqr(ze)>0) then begin ze:=ArcSin(ze);Goto w1;end else begin Se(12);exit;end;
if (q='arccos') then if ((ze=0) or (ze=-1) or ((1-ze)/(1+ze)<0)) then begin Se(12);exit;end else begin ze:=Arccos(ze);Goto w1;end;
if (q='arccot') then begin ze:=ArcCot(ze);Goto w1;end;
if (q='arcsec') then if ((ze=0) or (ze=-1) or ((1-(1/ze))/(1+(1-ze))<=0)) then begin Se(12);exit;end else begin ze:=Arcsec(ze);Goto w1;end;
if (q='arccosec') then if ((ze=0) or (1-Sqr(1/ze)<0) or (Sqrt(1-Sqr(1/ze))=0)) then begin Se(12);exit;end else begin ze:=Arccsc(ze);Goto w1;end;
if (q='sinh') then begin ze:=Sinh(ze);Goto w1;end;
if (q='cosh') then begin ze:=Cosh(ze);Goto w1;end;
if (q='tanh') then begin ze:=Tanh(ze);Goto w1;end; //Fehlerabfrage...
if (q='coth') then begin ze:=Coth(ze);Goto w1;end; //Fehlerabfrage...
if (q='sech') then begin ze:=Sech(ze);Goto w1;end; //Fehlerabfrage...
if (q='cosech') then begin ze:=Csch(ze);Goto w1;end; //Fehlerabfrage...
if (q='arcsinh') then begin ze:=Arcsinh(ze);Goto w1;end; //Fehlerabfrage...
if (q='arccosh') then begin ze:=Arccosh(ze);Goto w1;end; //Fehlerabfrage...
if (q='arctanh') then begin ze:=Arctanh(ze);Goto w1;end; //Fehlerabfrage...
if (q='arccoth') then begin ze:=arccoth(ze);Goto w1;end; //Fehlerabfrage...
if (q='arcsech') then begin ze:=arcsech(ze);Goto w1;end; //Fehlerabfrage...
if (q='arccosech') then begin ze:=arccsch(ze);Goto w1;end; //Fehlerabfrage...
if (q='rnd') then begin Randomize;ze:=ze*Random(1);Goto w1;end;
if (q='prim') then if IsInt(ze) then if (Trunc(ze)<1) then begin Se(14);exit;end else begin ze:=IsPrim(Trunc(ze));It(1);Goto w1;end else begin Se(20);exit;end;
if (q='perm') then if IsInt(ze) then begin ze:=Fak(Trunc(ze));It(1);Goto w1;end else begin Se(20);exit;end;
if (q='defizient') then if IsInt(ze) then begin if (ze<1) then begin Se(14);exit;end;if (SumTeil(Trunc(ze))<Trunc(ze)) then ze:=1 else ze:=0;Goto w1;end else begin Se(20);exit;end;
if (q='abundant') then if IsInt(ze) then begin if (ze<1) then begin Se(14);exit;end;if (SumTeil(Trunc(ze))>Trunc(ze)) then ze:=1 else ze:=0;Goto w1;end else begin Se(20);exit;end;
if (q='lightdefizient') then if IsInt(ze) then begin if (ze<1) then begin Se(14);exit;end;if (SumTeil(Trunc(ze))=Trunc(ze)-1) then ze:=1 else ze:=0;Goto w1;end else begin Se(20);exit;end;
if (q='lightabundant') then if IsInt(ze) then begin if (ze<1) then begin Se(14);exit;end;if (SumTeil(Trunc(ze))=Trunc(ze)+1) then ze:=1 else ze:=0;Goto w1;end else begin Se(20);exit;end;
if (q='radtodeg') then begin It(1);ze:=ze*57.2957795130823208768;Goto w1;end;
if (q='degtorad') then begin It(1);ze:=ze/57.2957795130823208768;Goto w1;end;
if (q='gratodeg') then begin It(1);ze:=ze*0.9;Goto w1;end;
if (q='degtogra') then begin It(1);ze:=ze/0.9;Goto w1;end;
if (q='radtogra') then begin It(1);ze:=ze*63.66197723675813430755;Goto w1;end;
if (q='gratorad') then begin It(1);ze:=ze/63.66197723675813430755;Goto w1;end;
if (q='shortenrad') then begin It(5);ze:=ze-Int(ze/6.28318530717958647693)*6.28318530717958647693;Goto w1;end;
if (q='shortengra') then begin It(3);ze:=ze-Int(ze/400)*400;Goto w1;end;
if (q='shortendeg') then begin It(3);ze:=ze-Int(ze/360)*360;Goto w1;end;
if (q='range') then begin It(9);es:=RON(ze);goon:=True;Goto w1;end;
if (q='thousands') then begin es:=Thousands(ze);goon:=True;Goto w1;end;
if (q='chr') then if IsInt(ze) then if (ze<256) And (ze>-1) then begin es:=Chr(Trunc(ze));goon:=True;Goto w1;end else Se(14);
Se(11);gq:=q;exit;{w1 unten}
w1:
if goon then z:=es else z:=XStr(ze);
end;//Komplexe Berechnungen mit 1 Parameter...
end;//Funktionsaufrufe
if goon then Break;
q:=RightStr(fx,Length(fx)-f-2-Length(p)-Length(q));
fx:=p+IfThen((p<>'') And Not(ContainsStr('/*-+^\&|=<>(',p[Length(p)])),'*')+z+IfThen((q<>'') And Not(ContainsStr('²³!°/*-+^\&|=<>)',q[1])),'*')+q;
end; //while-Schleife für Berechnungen
if ('('=LeftStr(fx,1)) then fx:=MidStr(fx,2,Length(fx)-2);
if goon then fx:=z else begin
while (('0'=RightStr(fx,1)) and ContainsStr(fx,',')) do fx:=LeftStr(fx,Length(fx)-1);
if (RightStr(fx,1)=',') then fx:=LeftStr(fx,Length(fx)-1);
fx:=ReplaceStr(ReplaceStr(ReplaceStr(fx,'§','-'),'~','E+'),'#','E-');
if (fx='-0') then fx:='0';end;
StrCopy(term2,PChar(fx));
Result:=Length(fx);
if svar<>'' then SetVar(svar,fx);//Variable belegen
Log('Ergebnis: '+fx);
end;

function Table(term:String;min,max,step:Pointer;iterations,typ:Integer):Integer;stdcall;
var l,mi,ma,st:Double;c,feh,its:Integer;sum,hmi,prod,e:Extended;t:Boolean;
begin
Log('Tabelle erstellen mit Formel '+term);
mi:=Double(min^);
st:=Double(step^);
ma:=Double(max^);
itis:=Ptr(iterations);
l:=mi;
xt:='';
its:=0;
feh:=0;
sum:=0;
prod:=1;
hmi:=0;
c:=0;
t:=False;
if (term[1]='$') then begin
Log('Zahlenkette erkannt');
xt:=term;
t:=True;term:=ReplaceStr(RightStr(term,Length(term)-1),'.',',')+'|';
feh:=Pos('|',term);
while (feh<>0) do begin
f2:=PChar(LeftStr(term,feh-1));
if (f2<>'#') then begin
if TryStrToFloat(f2,e) then begin
prod:=prod*e;
sum:=sum+e;
hmi:=hmi+1/e;end
else begin Se(24);exit;end;
end;
term:=RightStr(term,Length(term)-feh);
Inc(itis,8);
Inc(c);
feh:=Pos('|',term);end;
end else begin
Log('Term erkannt');
term:=PreParse(term);
if (error>0) then begin Result:=error;exit;end;
while (l<ma) do begin
gl1:=ReplaceStr(LowerCase(term),'%x%','('+FloatToStr(l)+')');
Parse(gl1,f2,Integer(Addr(feh)),Integer(Addr(its)),0);
xt:=xt+'|'+IfThen((feh>0),'#',f2);
if feh=0 then begin e:=StrToFloat(f2);sum:=sum+e;prod:=prod*e;hmi:=hmi+1/e;end;
l:=l+st;
Inc(c);
end; //while
end;
if typ=1 then ergebnis:=FloatToStr(sum) else if typ=2 then ergebnis:=FloatToStr(prod) else ergebnis:=xt;
amid:=sum/c;
gmid:=Power(prod,1/c);
hmid:=1/hmi;
itis^:=its;
Log('Ergebnis '+ergebnis);
Result:=Length(Ergebnis);
end;

function ami(e:PChar;x:Integer):Integer;stdcall;
var a:String;b:Integer;
begin
case x of
0:a:=FloatToStr(amid);
1:a:=FloatToStr(gmid);
2:a:=FloatToStr(hmid);end;
b:=Pos(',',a);
if (b<>0) then a:=LeftStr(a,b-1)+'.'+RightStr(a,Length(a)-b);
StrCopy(e,PChar(a));
Result:=Length(e);
end;

function GetBit(i,pos:Integer):Boolean;inline;
begin
Result:=(i And (1 shl pos))<>0;
end;

function Graph(term:String;hand1,hand2:HDC;xleft,yleft,dx,dy:Integer;xmi,xma,ymi,yma,sx:Pointer;color,flags,iterations:Integer):Integer;stdcall;
var step,xmin,xmax,ymin,ymax,x,y:Extended;cv:TBitmap;itr:^Integer;nobind:Boolean;
begin
Log('Graph zeichnen');
nobind:=GetBit(flags,2);
xmin:=Double(xmi^);
xmax:=Double(xma^);
ymin:=Double(ymi^);
ymax:=Double(yma^);
if (sx=NIL) then step:=0 else step:=Double(sx^);
if (step=0) then step:=(xmax-xmin)/dx;
Result:=0;
term:=PreParse(term);
if (error>0) then begin Result:=error;exit;end;
cv:=Tbitmap.Create();cv.SetSize(dx,dy);
BitBlt(cv.canvas.handle,xleft,yleft,dx,dy,hand1,0,0,SRCCOPY);
if GetBit(flags,4) then begin
cv.Canvas.MoveTo(Round((0-xmin)/(xmax-xmin)*dx+xleft),yleft);
cv.canvas.Lineto(Round((0-xmin)/(xmax-xmin)*dx+xleft),yleft+dy);
cv.Canvas.MoveTo(xleft,Round(yleft+dy-(0-ymin)/(ymax-ymin)*dy));
cv.canvas.Lineto(xleft+dx,Round(yleft+dy-(0-ymin)/(ymax-ymin)*dy));
if GetBit(flags,5) then begin
cv.canvas.brush.style:=bsclear;
cv.Canvas.TextOut(xleft+dx-10,Round(4+yleft+dy-(0-ymin)/(ymax-ymin)*dy),'X');
cv.canvas.TextOut(Round((0-xmin)/(xmax-xmin)*dx+xleft+4),yleft,'Y');end;end;
x:=xmin;
itr:=Ptr(iterations);
cv.canvas.Pen.Color:=color;
its:=0;
while (x<xmax) do begin
gl1:=LowerCase(ReplaceStr(term,'%x%','('+FloatToStr(x)+')'));
feh:=0;
Parse(gl1,erg,Integer(Addr(feh)),Integer(Addr(its)),0);
if (feh>0) then if ((feh=4) Or (feh=7) Or (feh=12) Or (feh=14) Or (feh=17)) then y:=0 else begin Result:=feh;cv.Free;exit;end else y:=StrToFloat(erg);
if (x=xmin) then cv.Canvas.MoveTo(Round((x-xmin)/(xmax-xmin)*dx+xleft),Round(yleft+dy-(y-ymin)/(ymax-ymin)*dy)) else
  if (feh>0) then if eh[2] then begin Se(22);Result:=22;cv.Free;exit;end else cv.Canvas.MoveTo(Round((x-xmin)/(xmax-xmin)*dx+xleft),Round(yleft+dy-(y-ymin)/(ymax-ymin)*dy)) else if nobind then begin cv.Canvas.Pixels[Round((x-xmin)/(xmax-xmin)*dx+xleft),Round(yleft+dy-(y-ymin)/(ymax-ymin)*dy)]:=color;end else cv.Canvas.LineTo(Round((x-xmin)/(xmax-xmin)*dx+xleft),Round(yleft+dy-(y-ymin)/(ymax-ymin)*dy));
x:=x+step;itr^:=itr^+its;
end;//while
if (hand1<>0) then BitBlt(hand1,xleft,yleft,dx,dy,cv.Canvas.Handle,0,0,SRCCOPY);
if (hand2<>0) then BitBlt(hand2,xleft,yleft,dx,dy,cv.Canvas.Handle,0,0,SRCCOPY);
cv.Free;
Log('Graph zeichnen beendet');
end;

Function Init3D(hand1,hand2:HDC;xl,yl,tx,ty,c,bc:Integer;ralg:String):Integer;stdcall;
begin
hdc1:=hand1;
hdc2:=hand2;
xleft:=xl;
yleft:=yl;
dx:=tx;
dy:=ty;
color:=c;
bcolor:=bc;
if (ralg<>'')then begin
if ContainsStr(ralg,'_') then begin
fillalg:=True;fillsep:=True;
alg1:=PreParse(LeftStr(ralg,Pos('_',ralg)-1));
if error<>0 then begin Result:=error;Se(error);exit;end;
ralg:=RightStr(ralg,Length(ralg)-Pos('_',ralg));
alg2:=PreParse(LeftStr(ralg,Pos('_',ralg)-1));
if error<>0 then begin Result:=error;Se(error);exit;end;
alg3:=PreParse(RightStr(ralg,Length(ralg)-Pos('_',ralg)));
if error<>0 then begin Result:=error;Se(error);exit;end;
end else begin
fillalg:=True;fillsep:=False;
alg1:=PreParse(ralg);
if error<>0 then begin Result:=error;Se(error);exit;end;
end;end else fillalg:=False;
viewinit:=True;
Result:=0;
end;

function Render3D(term:String;xmi,xma,ymi,yma,zmi,zma,stx,sty:Pointer;otis,poly:Integer;Func:TCallbackProc1):Integer;stdcall;
var stepx,stepy:Double;cx,cy,zval:Extended;tx,ty,cflag:Integer;abort:Boolean;
begin
Rendered:=False;
if viewinit then begin
Result:=0;
abort:=False;
Log('Rendere '+term);
itis:=Ptr(otis);
polys:=Ptr(poly);
xmin:=Double(xmi^);
xmax:=Double(xma^);
ymin:=Double(ymi^);
ymax:=Double(yma^);
zmin:=Double(zmi^);
zmax:=Double(zma^);
stepx:=Double(stx^);
if (stepx=0) then stepx:=(xmax-xmin)/40;
stepy:=Double(sty^);
if (stepy=0) then stepy:=(ymax-ymin)/40;
mx:=Round((xmax-xmin)/stepx);//Anzahl Schritte in X-Richtung
my:=Round((ymax-ymin)/stepy);//Anzahl Schritte in Y-Richtung
polys^:=mx*my;
term:=PreParse(term);
if (error>0) then begin se(error);Result:=error;exit;end;
zm1:=0;
zm2:=0;
its:=0;//Iterationen
try SetLength(xvals,mx) except on e:eoutofmemory do begin Se(23);Result:=23;exit;end;end;//Matrix mit X-Werten
try SetLength(yvals,my) except on e:eoutofmemory do begin Se(23);Result:=23;exit;end;end;//Matrix mit Y-Werten
try SetLength(zvals,mx,my) except on e:eoutofmemory do begin Se(23);Result:=23;exit;end;end;//Matrix mit Z-Werten
cx:=xmin;//Wertezähler X-Richtung
For tx:=0 to mx-1 do begin
cy:=ymin;//Wertezähler Y-Richtung
For ty:=0 to my-1 do begin
gl1:=LowerCase(ReplaceStr(ReplaceStr(term,'%y%','('+FloatToStr(cy)+')'),'%x%','('+FloatToStr(cx)+')'));
feh:=0;
Parse(gl1,erg,Integer(Addr(feh)),Integer(Addr(its)),0);
//if Not(TryStrToFloat(erg,zval)) then begin Log('Umwandlung fehlgeschlagen: "'+erg+'"');zval:=0;end;
if (feh<>0) then begin Log('Umwandlung fehlgeschlagen: "'+erg+'"');zval:=0;end else zval:=StrToFloat(erg);
if (feh>0) then if ((feh=4) Or (feh=7) Or (feh=12) Or (feh=14) Or (feh=17)) then zvals[tx,ty]:=0 else begin Result:=feh;exit;end else zvals[tx,ty]:=zval;
if (feh>0) and eh[2] then begin Se(22);Result:=22;exit;end;
if ((dx=0) and (dy=0)) then begin zm1:=zval;zm2:=zval;end else begin if zm1<zval then zm1:=zval;if zm2>zval then zm2:=zval;end;//zm1:Max-Wert;zm2:Min-Wert
yvals[ty]:=cy;
cy:=cy+stepy;//Inc(ty);
end; // y-Schleife
xvals[tx]:=cx;
cx:=cx+stepx;//Inc(tx);
if Assigned(Func) then if (Func(Round(100*tx/mx))<>0) then begin;abort:=True;Se(26);Result:=26;gq:='Rendern';Break;end;
end; // x-Schleife
itis^:=its;
if Assigned(Func) then Func(100);
Rendered:=Not(abort);
Log('Rendern beendet');if abort then exit;
end else begin Se(21);Result:=21;end;
end;

function ViewAnimation(alp,bet,gam,xk,yk,zk,scax,scay:Pointer;flags:Integer;dalp,dbet,dgam:Pointer;fps,tf:Integer;Func:TCallbackProc2):Integer;stdcall;
var bitmap:Array of TBitmap;koords:array of array of TPoint;pf1,pf2,pf5,pf4:Int64;borders,coordsystem,labels,hidebackface,abort:Boolean;cv,cv2:TBitmap;tm,ex,ey,xmi,xma,ymi,yma,sx,sy,cnt,cflag:Integer;zval,pr,pg,pb,cval,cx,cy,af,fmin,fmax,fmed:Extended;xf,yf,dal,dbe,dga,alpha,beta,gamma,scalx,scaly:Double;pts:array[0..3]of TPoint;p1,p2:array[0..2]of TPoint;
function SetVar(v:String):String;//inline;
begin
v:=ReplaceStr(v,'%maxx%',FloatToStr(xmax));
v:=ReplaceStr(v,'%minx%',FloatToStr(xmin));
v:=ReplaceStr(v,'%maxy%',FloatToStr(ymax));
v:=ReplaceStr(v,'%miny%',FloatToStr(ymin));
v:=ReplaceStr(v,'%maxz%',FloatToStr(zmax));
v:=ReplaceStr(v,'%minz%',FloatToStr(zmin));
v:=ReplaceStr(v,'%x%',FloatToStr(cx));
v:=ReplaceStr(v,'%y%',FloatToStr(cy));
v:=ReplaceStr(v,'%z%',FloatToStr(zval));
Result:=v;
end;
function calcx(x,y,z:Extended):Integer;
begin
Result:=Round(xleft+dx*(0.5+scalx*(tmat[0,0]*(x-xkoord)+tmat[1,0]*(y-ykoord)+tmat[2,0]*(z-zkoord)/(zmax-zmin))));
end;
function calcy(x,y,z:Extended):Integer;
begin
Result:=Round(yleft+dy*(0.5-scaly*(tmat[0,1]*(x-xkoord)+tmat[1,1]*(y-ykoord)+tmat[2,1]*(z-zkoord)/(zmax-zmin))));
end;
begin
if Rendered then begin
Log('Zeichne Graph...');Result:=0;
if eh[6] then try SetLength(bitmap,tf) except on e:eoutofmemory do begin Se(23);Result:=23;exit;end;end;//Bildpuffer erzeugen
abort:=False;
hidebackface:=GetBit(flags,3);
coordsystem:=GetBit(flags,4);
labels:=GetBit(flags,5);
borders:=GetBit(flags,2);
cflag:=IfThen(GetBit(flags,0),1,0)+IfThen(GetBit(flags,1),2,0);
scalx:=Double(scax^);
if (scalx=0) then scalx:=0.2;
scaly:=Double(scay^);
if (scaly=0) then scaly:=0.2;
alpha:=Double(alp^)/57.2957795130823208768;
beta:=Double(bet^)/57.2957795130823208768;
gamma:=Double(gam^)/57.2957795130823208768;
dal:=Double(dalp^)/57.2957795130823208768;
dbe:=Double(dbet^)/57.2957795130823208768;
dga:=Double(dgam^)/57.2957795130823208768;
try SetLength(koords,mx,my) except on e:eoutofmemory do begin Se(23);Result:=23;exit;end;end;
cv:=Tbitmap.Create();cv.SetSize(dx,dy);
cv2:=TBitmap.Create();cv2.SetSize(dx,dy);
BitBlt(cv2.canvas.handle,xleft,yleft,dx,dy,HDC1,0,0,SRCCOPY);
if EH[5] then cv2.Canvas.TextOut(3,0,'Parcival '+ver);//immer noch billiges Logo
cv.canvas.pen.Color:=color;
cv.Canvas.Brush.Color:=bcolor;
if borders then cv.Canvas.Pen.Style:=psClear else cv.Canvas.Pen.Style:=psSolid;
cnt:=0;pf2:=1;fmed:=0;fmin:=MaxExtended;
while (cnt<tf) do begin
af:=1/(pf2-pf1)*IfThen(cnt>0,pf3);
queryperformancecounter(pf1);
if (cnt<>1) then begin
if (af<fmin) then fmin:=af;
if (af>fmax) then fmax:=af;
fmed:=fmed+af;end;
Log('Frame '+IntToStr(cnt+1)+' von '+IntToStr(tf)+' wird gezeichnet ('+Format('%1.2f',[af])+'fps).');
BitBlt(cv.canvas.handle,xleft,yleft,dx,dy,cv2.canvas.Handle,0,0,SRCCOPY);
tmat[0,0]:=cos(alpha)*cos(gamma)-sin(alpha)*sin(beta)*sin(gamma);
tmat[1,0]:=sin(alpha)*cos(gamma)+cos(alpha)*sin(beta)*sin(gamma);
tmat[2,0]:=cos(beta)*sin(gamma);
tmat[0,1]:=-sin(alpha)*cos(beta)*cos(gamma)-cos(alpha)*sin(gamma);
tmat[1,1]:=cos(alpha)*sin(beta)*cos(gamma)-sin(alpha)*sin(gamma);
tmat[2,1]:=cos(beta)*cos(gamma);
if coordsystem then begin
cv.canvas.brush.style:=bsclear;
cv.canvas.MoveTo(CalcX(xvals[0],0,0),CalcY(xvals[0],0,0));
cv.canvas.lineto(CalcX(xvals[mx-1],0,0),CalcY(xvals[mx-1],0,0));
cv.canvas.MoveTo(CalcX(0,yvals[0],0),CalcY(0,yvals[0],0));
cv.canvas.lineto(CalcX(0,yvals[my-1],0),CalcY(0,yvals[my-1],0));
cv.canvas.MoveTo(CalcX(0,0,zm2),CalcY(0,0,zm2));
cv.canvas.lineto(CalcX(0,0,zm1),CalcY(0,0,zm1));
if labels then begin
cv.canvas.TextOut(CalcX(xvals[0],0,0),CalcY(xvals[0],0,0),'X');
cv.canvas.TextOut(CalcX(0,yvals[0],0),CalcY(0,yvals[0],0),'Y');
cv.canvas.TextOut(CalcX(xvals[mx-1],0,0),CalcY(xvals[mx-1],0,0),'X');
cv.canvas.TextOut(CalcX(0,yvals[my-1],0),CalcY(0,yvals[my-1],0),'Y');
cv.canvas.TextOut(CalcX(0,0,zm2),CalcY(0,0,zm2),'Z');
end;
end;
if (sin(alpha)*cos(beta)<0) then begin sx:=-1;xmi:=mx-1;xma:=0;end else begin sx:=1;xmi:=0;xma:=mx-1;end;
if (cos(alpha)*cos(beta)>0) then begin sy:=-1;ymi:=my-1;yma:=0;end else begin sy:=1;ymi:=0;yma:=my-1;end;
ex:=xmi;
while (ex<>xma) and Not(Abort) do begin
cx:=xvals[ex];
ey:=ymi;
while (ey<>yma) do begin
cy:=yvals[ey];
zval:=zvals[ex,ey];
koords[ex,ey].x:=CalcX(cx,cy,zval);
koords[ex,ey].y:=CalcY(cx,cy,zval);
if ((ey<>ymi) and (ex<>xmi)) then begin
pts[0]:=koords[ex,ey];
pts[1]:=koords[ex,ey-sy];
pts[2]:=koords[ex-sx,ey-sy];
pts[3]:=koords[ex-sx,ey];
if hidebackface then begin cv.canvas.Polyline(pts);cv.canvas.MoveTo(pts[0].x,pts[0].y);cv.Canvas.LineTo(pts[3].x,pts[3].y);end else //Drahtgittermodell
begin zval:=(zval+zvals[ex-sx,ey-sy])/2;
if fillalg then
if fillsep then begin
Parse(SetVar(alg1),erg,Integer(Addr(feh)),Integer(Addr(its)),1);
if (feh=0) then if Not(TryStrToFloat(erg,pr)) then pr:=0;
Parse(SetVar(alg2),erg,Integer(Addr(feh)),Integer(Addr(its)),1);
if (feh=0) then if Not(TryStrToFloat(erg,pg)) then pg:=0;
Parse(SetVar(alg3),erg,Integer(Addr(feh)),Integer(Addr(its)),1);
if (feh=0) then if Not(TryStrToFloat(erg,pb)) then pb:=0;
cv.Canvas.Brush.Color:=RGB(Round(pr),Round(pg),Round(pb));
end else begin
Parse(SetVar(alg1),erg,Integer(Addr(feh)),Integer(Addr(its)),1);
if (feh=0) then if Not(TryStrToFloat(erg,pr)) then pr:=0;
cv.Canvas.Brush.Color:=Round(pr);
end else if (cflag=1) then begin // für Blau(min)-Grün(mid)-Rot(max)
cval:=zval/(zm2-zm1);
pr:=cos(1.57079*(cval+0.66666666666666666667));
pg:=cos(1.57079*(cval));
pb:=cos(1.57079*(0.66666666666666666667-cval));
if(pr<0) then pr:=0;
if(pg<0) then pg:=0;
if(pb<0) then pb:=0;
cv.Canvas.Brush.color:=RGB(round(255*pr),round(255*pg),round(255*pb));end //Farbverlauf 1
else if (cflag=2) then begin t:=round(255*(zval-zm2)/(zm1-zm2));cv.Canvas.Brush.color:=RGB(t,t,t);end //für Schwarz(min)-grau(med)-weiß(max)
else if (cflag=3) then begin
cval:=(zval-zm2)/(zm1-zm2);
pr:=4*cval-2;
pg:=2-4*Abs(cval-0.5);
pb:=2-4*cval;
if(pr<0) then pr:=0;
if(pg<0) then pg:=0;
if(pb<0) then pb:=0;
if(pr>1) then pr:=1;
if(pg>1) then pg:=1;
if(pb>1) then pb:=1;
cv.Canvas.Brush.Color:=RGB(round(255*pr),round(255*pg),round(255*pb));end; //Farbverlauf 2
if eh[7] then begin p1[0]:=pts[0];p1[1]:=pts[1];p1[2]:=pts[2];p2[0]:=pts[2];p2[1]:=pts[3];p2[2]:=pts[0];cv.Canvas.Polygon(p1);cv.Canvas.Polygon(p2);end else cv.Canvas.Polygon(pts);end;
end;
Inc(ey,sy);
end;
Inc(ex,sx);
if Assigned(Func) then if (Func(cnt,Round(100*Abs(ex-xmi)/Abs(xmi-xma)))<>0) then begin abort:=True;Se(26);gq:='Zeichnen';Result:=26;end;
end;
if Abort then Break;
Inc(cnt);//Neuer Frame
alpha:=alpha+dal;
beta:=beta+dbe;
gamma:=gamma+dga;
if eh[6] then begin
try bitmap[cnt]:=Tbitmap.Create();bitmap[cnt].SetSize(dx,dy);except on EOutOfResources do begin for tf:=0 to cnt-1 do bitmap[tf].Free;Se(23);Result:=23;exit;end;end;
BitBlt(bitmap[cnt].Canvas.Handle,0,0,dx,dy,cv.Canvas.Handle,0,0,SRCCOPY);
queryperformancecounter(pf2);
end else begin
if (hdc1<>0) then BitBlt(hdc1,xleft,yleft,dx,dy,cv.Canvas.Handle,0,0,SRCCOPY);
if (hdc2<>0) then BitBlt(hdc2,xleft,yleft,dx,dy,cv.Canvas.Handle,0,0,SRCCOPY);
queryperformancecounter(pf2);
tm:=Trunc(1000/fps-1000*(pf2-pf1)/pf3);
if (tm<0) then begin
//Frame droppen
tm:=Ceil(Abs(tm)/1000*fps);
Inc(cnt,tm);
Log(IntToStr(tm)+' Frames w'+IfThen(tm=1,'ird','erden')+' gedroppt.');
alpha:=alpha+tm*dal;
beta:=beta+tm*dbe;
gamma:=gamma+tm*dga;
end else Sleep(tm);
end;
end;
Log('Zeichnen beendet...');
Log('Kleinster Framewert: '+Format('%1.2f',[fmin]));
Log('Größter Framewert: '+Format('%1.2f',[fmax]));
Log('Mittlerer Framewert: '+Format('%1.2f',[fmed/(tf-1)]));
cv.Free();
cv2.Free();
if eh[6] then begin
Log('Zeichne auf Bildschirm...');
pf2:=1;pf5:=1;fmax:=0;fmed:=0;
for cnt:=1 to tf do begin
af:=1/(pf2-pf1)*pf3;
queryperformancecounter(pf1);
if (cnt=2) then begin fmin:=af;fmed:=fmed+af;end else begin
if (af<fmin) then fmin:=af;
if (af>fmax) then fmax:=af;
if (cnt<>1) then fmed:=fmed+af;end;
Log('Frame '+IntToStr(cnt)+' von '+IntToStr(tf)+' wird gezeichnet ('+Format('%1.2f',[af])+'fps).');
if (hdc1<>0) then BitBlt(hdc1,xleft,yleft,dx,dy,bitmap[cnt].Canvas.Handle,0,0,SRCCOPY);
if (hdc2<>0) then BitBlt(hdc2,xleft,yleft,dx,dy,bitmap[cnt].Canvas.Handle,0,0,SRCCOPY);
bitmap[cnt].Free();
if Assigned(Func) then if (Func(cnt,-1)<>0) then begin Se(26);gq:='Zeichnen';Result:=26;for tm:=cnt+1 to tf do bitmap[tm].Free;exit;end;
queryperformancecounter(pf5);
Sleep(Trunc(1000/fps-1000*(pf5-pf1)/pf3));
queryperformancecounter(pf2);
end;
Log('Zeichnen beendet...');
Log('Kleinster Framewert: '+Format('%1.2f',[fmin]));
Log('Größter Framewert: '+Format('%1.2f',[fmax]));
Log('Mittlerer Framewert: '+Format('%1.2f',[fmed/(tf-1)]));
Log('Zeichnen beendet...');
end;
end else begin
Se(25);Result:=25;end;
end;

function Validate(x:PChar):Integer;stdcall;
var a:Extended;
begin
Result:=IfThen(TryStrToFloat(x,a),1,0);
end;

function cpuspeed(n:Integer):Integer;stdcall;
var  TimerHigh, TimerLow: DWORD;
begin
if n=0 then begin
SetPriorityClass(GetCurrentProcess,REALTIME_PRIORITY_CLASS);
SetThreadPriority(GetCurrentThread,THREAD_PRIORITY_TIME_CRITICAL);
try
asm
  dw 310Fh
  mov TimerLow,eax
  mov TimerHigh,edx
end;
Sleep(1000); //Delay
asm
  dw 310Fh
  sub eax,TimerLow
  sub edx,TimerHigh
  mov TimerLow,eax
  mov TimerHigh,edx
end;
Result:=Trunc(TimerLow/(1000000)); //1000.0*Delay
finally
SetPriorityClass(GetCurrentProcess,NORMAL_PRIORITY_CLASS);
end;end else if n=1 then Result:=Trunc(pf3/1000000) else
begin Log('Ungültiger Parameter für Prozessortest...('+IntToStr(n)+')');Result:=-1;end;
end;

function Benchmark(n:Integer):Integer;stdcall;
var a:Integer;p1,p2:Int64;e,f:String;
begin
case n of
0:begin;f:='%x%+%x%';e:='Additionstest';end;
1:begin;f:='%x%-%x%';e:='Subtraktionstest';end;
2:begin;f:='%x%*%x%';e:='Multiplikationstest';end;
3:begin;f:='%x%/%x%';e:='Divisionstest';end;
4:begin;f:='%x%\%x%';e:='Integerdivisionstest';end;
5:begin;f:='%x%^%x%';e:='Potenztest';end;
6:begin;f:='Sin(%x%)';e:='Sinustest';end;
7:begin;f:='Cos(%x%)';e:='Cosinustest';end;
8:begin;f:='Tan(%x%)';e:='Tangenstest';end;
9:begin;f:='Root(%x%;%x%)';e:='Wurzeltest';end;
10:begin;f:='Prim(%x%)';e:='Primzahltest';end else
Log('Ungültiger Parameter für Benchmarktest...('+IntToStr(n)+')');end;
Log('Starte Benchmarktest ('+e+')...');
queryperformancecounter(p1);
for a:=0 to 199999 do Parse(ReplaceStr(f,'%x%',IntToStr(a)),erg,0,0,1);
queryperformancecounter(p2);
Result:=Trunc(1000*(p2-p1)/pf3);
Log(IntToStr(Result)+' Millieskunden...');
end;

procedure OGLTest(hdc1:hWnd);stdcall;
var rc,dc:HDC;dx,dy:Integer;rect:TRect;
begin
InitOpenGL;
dc:=GetDC(hdc1);
GetClientRect(hdc1,rect);
RC:=CreateRenderingContext(dc,[opDoubleBuffered],32,24,0,0,0,0);
ActivateRenderingContext(dc,RC);
dx:=rect.Right-rect.left;
dy:=rect.Bottom-rect.top;
glViewport(0,0,dx,dy);
glClearColor(0,0,0,1); //Hintergrundfarbe
glMatrixMode(GL_PROJECTION);
glLoadIdentity;
gluPerspective(60,dx/dy,0.1,100);
glMatrixMode(GL_MODELVIEW);
glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
glTranslatef(0, 0,-3);
glColor3f(0,0,1);
glPolygonMode(gl_front_and_back,gl_line);
glBegin(GL_Quads);
glVertex3f(-1,-1, 0);
glVertex3f( 1,-1, 0);
glVertex3f( 1, 1, 0);
glVertex3f( -1, 1, 0);
glEnd;glFlush();glFinish();SwapBuffers(dc);//messagebox(0,0,0,0);
DestroyRenderingContext(RC);
end;

exports
OGLTest name 'OGLTest',
Benchmark name 'Benchmark',
Parse name 'Parse',
Version name 'Version',
XDate name 'Date',
XEdition name 'Edition',
ErrCode name 'ErrCode',
ErrCnt name 'ErrCnt',
seterrorhandling name 'SetErrorHandling',
geterrorhandling name 'GetErrorHandling',
cpuspeed name 'CPUSpeed',
graph name 'Graph',
table name 'Table',
ami name 'Amid',
Init3D name 'Init3D',
Render3D name 'Render3D',
ViewAnimation name 'ViewAnimation',
getlastresult name 'GetLastResult',
Validate name 'Validate',
setvariable name 'SetVariable',
minimum name 'MinimumParcival';

begin
ExitSave:=ExitProc;
DLLProc:=@MyExit;
erg:=AllocMem(128);
for t:=0 to High(eh) do eh[t]:=False;
SetRoundMode(rmNearest);
queryperformancefrequency(pf3);
end.
