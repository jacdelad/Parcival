unit Converter;

interface

uses Math;

implementation

function Convert(abschnitt,einheit1,einheit2:Integer;wert1,wert2:PDouble):Integer;stdcall;
var Calc:Extended;
begin
Calc:=wert1^;
Result:=0;
case abschnitt of
0:begin//Temperatur
case einheit1 of                 //Umrechnen in Kelvin
0:Calc:=Calc;                    //Kelvin
1:Calc:=Calc-273.15;             //∞C
2:Calc:=(Calc+459.67)/1.8;       //∞F
3:Calc:=Calc/1.8;                //∞ Rankine
4:Calc:=Calc*100/33+273.15;      //∞ Newton
5:Calc:=Calc*1.25+273.15;        //∞ RÈaumur
6:Calc:=(Calc-7.5)*40/21+273.15; //∞ R¯mer
7:Calc:=373.16-Calc*2/3;         //∞Delisle
else Result:=27;Exit;end;
case einheit2 of
0:Calc:=Calc;                    //Kelvin
1:Calc:=Calc+273.15;             //∞C
2:Calc:=Calc*1.8-459.67;         //∞F
3:Calc:=Calc*1.8;                //∞ Rankine
4:Calc:=(Calc-273.15)*0.33;      //∞ Newton
5:Calc:=(Calc-273.15)*0.8;       //∞ RÈaumur
6:Calc:=(Calc-273.15)*21/40+7.5; //∞ R¯mer
7:Calc:=(373.16-Calc)*1.5;       //∞Delisle
else Result:=28;Exit;end;
end;
1:begin //Druck
case einheit1 of                 //Umrechnen in Pascal
0:Calc:=Calc;
1:Calc:=Calc/100000;  //bar
2:Calc:=Calc/98066.5; //at
3:Calc:=Calc/101325;  //atm
4:Calc:=Calc/133.322; //Torr
5:Calc:=Calc/133.322; //mmHg
6:Calc:=Calc/6894.757293168; //psi
7:Calc:=Calc/9806.65; //mWS (Meter Wassers‰ule)
else Result:=27;Exit;end;
case einheit2 of
0:Calc:=Calc;
1:Calc:=Calc*100000;  //bar
2:Calc:=Calc*98066.5; //at
3:Calc:=Calc*101325;  //atm
4:Calc:=Calc*133.322; //Torr
5:Calc:=Calc*133.322; //mmHg
6:Calc:=Calc*6894.757293168; //psi
7:Calc:=Calc*9806.65; //mWS (Meter Wassers‰ule)
else Result:=28;Exit;end;
end;
2:begin //L‰nge
case einheit1 of                 //Umrechnen in Pascal
0:Calc:=Calc;         //Meter
1:Calc:=Calc*1000;    //Kilometer
2:Calc:=Calc*100;     //Hektometer
3:Calc:=Calc*10;      //Dekameter
4:Calc:=Calc*0.1;     //Dezimeter
5:Calc:=Calc*0.01;    //Zentimeter
6:Calc:=Calc*0.001;   //Millimeter
7:Calc:=Calc*0.000001;//Mikrometer
8:Calc:=Calc*0.000000001;//Nanometer
9:Calc:=Calc*Power(10,-12);//Picometer
10:Calc:=Calc*Power(10,-15);//Femtometer
11:Calc:=Calc*Power(10,-18);//Attometer
12:Calc:=Calc/443.30171114460501817537015692881;//Linie
13:Calc:=Calc/393.7007874015748031496062992126;//Zoll
14:Calc:=Calc/3.2808398950131233595800524934383;//Fuﬂ
15:Calc:=Calc/1.9;//Klafter
16:Calc:=Calc*1852;//Seemeile (sm)
17:Calc:=Calc*1609.344;//Landmeile
18:Calc:=Calc*1066.8;//Werst
19:Calc:=Calc*1000/33;//Sun (sun)
20:Calc:=Calc*149.597870691*IntPower(10,9);//Astronomische Einheit (AE)
21:Calc:=Calc*9.460528*IntPower(10,15);//Lichtjahr (Lj, ly, lyr)
22:Calc:=Calc*30*856776*IntPower(10,15);//Parallaxensekunde (Parsec -> pc)
23:Calc:=Calc*Power(10,-10);//≈ngstrˆm (≈)
24:Calc:=Calc*0.000375;//Punkt (p)
25:Calc:=Calc*3*0.02;//Stich
26:Calc:=Calc/3.7663;//Preuﬂische Rute
27:Calc:=Calc/4.2951;//S‰chsische Rute
28:Calc:=Calc*2220;//Leuge
29:Calc:=Calc/0.9144;//International Yard (yd)
30:Calc:=Calc/0.914401833;//Survey Yard
31:Calc:=Calc*1609.334;//Statute mile
32:Calc:=Calc*20.1168;//Chain
33:Calc:=Calc*201.168;//Furlong
34:Calc:=Calc*5.0292; //Rod
35:Calc:=Calc*0.201168;//Link
else Result:=27;Exit;end;
case einheit2 of
0:Calc:=Calc;         //Meter
1:Calc:=Calc*0.001;    //Kilometer
2:Calc:=Calc*0.01;     //Hektometer
3:Calc:=Calc*0.1;      //Dekameter
4:Calc:=Calc*10;     //Dezimeter
5:Calc:=Calc*100;    //Zentimeter
6:Calc:=Calc*1000;   //Millimeter
7:Calc:=Calc*1000000;//Mikrometer
8:Calc:=Calc*1000000000;//Nanometer
9:Calc:=Calc*IntPower(10,12);//Picometer
10:Calc:=Calc*IntPower(10,15);//Femtometer
11:Calc:=Calc*IntPower(10,18);//Attometer
12:Calc:=Calc*443.30171114460501817537015692881;//Linie
13:Calc:=Calc*393.7007874015748031496062992126;//Zoll
14:Calc:=Calc*3.2808398950131233595800524934383;//Fuﬂ
15:Calc:=Calc*1.9;//Klafter
16:Calc:=Calc/1852;//Seemeile (sm)
17:Calc:=Calc/1609.344;//Landmeile
18:Calc:=Calc/1066.8;//Werst
19:Calc:=Calc/1000/33;//Sun (sun)
20:Calc:=Calc/149.597870691*Power(10,-9);//Astronomische Einheit (AE)
21:Calc:=Calc/9.460528*IntPower(10,15);//Lichtjahr (Lj, ly, lyr)
22:Calc:=Calc/30*856776*IntPower(10,15);//Parallaxensekunde (Parsec -> pc)
23:Calc:=Calc*Power(10,10);//≈ngstrˆm (≈)
24:Calc:=Calc/0.000375;//Punkt (p)
25:Calc:=Calc/3*0.02;//Stich
26:Calc:=Calc*3.7663;//Preuﬂische Rute
27:Calc:=Calc*4.2951;//S‰chsische Rute
28:Calc:=Calc/2220;//Leuge
29:Calc:=Calc*0.9144;//International Yard (yd)
30:Calc:=Calc*0.914401833;//Survey Yard
31:Calc:=Calc/1609.334;//Statute mile
32:Calc:=Calc/20.1168;//Chain
33:Calc:=Calc/201.168;//Furlong
34:Calc:=Calc/5.0292; //Rod
35:Calc:=Calc/0.201168;//Link
else Result:=28;Exit;end;
end;
3:begin //Energie
case einheit1 of
0:Calc:=Calc;              //Joule
1:Calc:=Calc*Power(10,-7); //Erg
2:Calc:=Calc*4.1868;       //Kalorie
3:Calc:=Calc*0.00027777777777777777777777777778;//Kilowattstunde
4:Calc:=Calc*0.00003412037668895864610345298212;//Steinkohleeinheit
5:Calc:=Calc*0.00002388458966274959396197573326;//Rohˆleinheit
6:Calc:=Calc*0.00003150995714645828081673808924;//m≥ Erdgas
else Result:=27;exit;end;
case einheit2 of
0:Calc:=Calc;              //Joule
1:Calc:=Calc*Power(10,7);  //Erg
2:Calc:=Calc*0.239;        //Kalorie
3:Calc:=Calc*3600;         //Kilowattstunde
4:Calc:=Calc*29308;        //Steinkohleeinheit
5:Calc:=Calc*41868;        //Rohˆleinheit
6:Calc:=Calc*31736;        //m≥ Erdgas
else Result:=28;exit;end;
end;
4:begin //Geschwindigkeit
case einheit1 of
0:Calc:=Calc;              //km/h
1:Calc:=Calc*1.609344;     //mph
2:Calc:=Calc*3.6;          //m/s
3:Calc:=Calc*1.852;          //Knoten
else Result:=27;exit;end;
case einheit2 of
0:Calc:=Calc;              //km/h
1:Calc:=Calc*0.62137119223733396961743418436332; //mph
2:Calc:=Calc*0.27777777777777777777777777777778; //m/s
3:Calc:=Calc*0.53995680345572354211663066954644; //Knoten
else Result:=28;exit;end;
end;
5:begin //Leistung
case einheit1 of
0:Calc:=Calc;              //Watt
1:Calc:=Calc*735.49875;    //PS
2:Calc:=Calc*0.73549875;   //kW
3:Calc:=Calc*745.7;        //bhp
else Result:=27;exit;end;
case einheit2 of
0:Calc:=Calc;              //Watt
1:Calc:=Calc/735.49875;    //PS
2:Calc:=Calc/0.73549875;   //kW
3:Calc:=Calc/745.7;        //bhp
else Result:=28;exit;end;
end;
6:begin //Fl‰che
case einheit1 of
0:Calc:=Calc;               //Quadratmeter
1:Calc:=Calc*1000000;       //Quadratkilometer
2:Calc:=Calc/10000;         //Quadratzentimeter
3:Calc:=Calc/1000000;       //Quadratmillimeter
4:Calc:=Calc*100;           //Ar (a)
5:Calc:=Calc*10000;         //Hektar (ha)
6:Calc:=Calc*Power(10,-28); //Barn (b)
7:Calc:=Calc*4046.8564224;  //Acre
8:Calc:=Calc*2500;          //Morgen
9:Calc:=Calc*1600;          //Rai
10:Calc:=Calc*2589988.110336;//Quadratmeile
11:Calc:=Calc*0.00064516;   //Quadratzoll
12:Calc:=Calc*1000;         //Griechisches Stremma
13:Calc:=Calc*1270          //Moreotisches Stremma
//noch um Dunam,Tagewerk und verschiedene Morgen erweitern
else Result:=27;exit;end;
case einheit2 of
0:Calc:=Calc;               //Quadratmeter
1:Calc:=Calc/1000000;       //Quadratkilometer
2:Calc:=Calc*10000;         //Quadratzentimeter
3:Calc:=Calc*1000000;       //Quadratmillimeter
4:Calc:=Calc/100;           //Ar (a)
5:Calc:=Calc/10000;         //Hektar (ha)
6:Calc:=Calc/Power(10,-28); //Barn (b)
7:Calc:=Calc/4046.8564224;  //Acre
8:Calc:=Calc/2500;          //Morgen
9:Calc:=Calc*1600;          //Rai
10:Calc:=Calc/2589988.110336;//Quadratmeile
11:Calc:=Calc/0.00064516;   //Quadratzoll
12:Calc:=Calc/1000;         //Griechisches Stremma
13:Calc:=Calc/1270          //Moreotisches Stremma
else Result:=28;exit;end;
end;
7:begin //Zeit
case einheit1 of
0:Calc:=Calc;               //Sekunde
1:Calc:=Calc*60;            //Minute
2:Calc:=Calc*3600;          //Stunde
3:Calc:=Calc*86400;         //Tag
else Result:=27;exit;end;
case einheit2 of
0:Calc:=Calc;               //Sekunde
1:Calc:=Calc/60;            //Minute
2:Calc:=Calc/3600;          //Stunde
3:Calc:=Calc/86400;         //Tag
else Result:=28;exit;end;
end;
8:begin //Masse
case einheit1 of
0:Calc:=Calc;               //Gramm
1:Calc:=Calc*1000;          //Kilogramm
2:Calc:=Calc*1000000;       //Tonne
3:Calc:=Calc/5;             //Karat
4:Calc:=Calc*28.8;          //Unze
5:Calc:=Calc*50;            //Neulot
6:Calc:=Calc*50000;         //Zentner (ztr)
7:Calc:=Calc*100000;        //Doppelzentner, auch Quintal (dz)
8:Calc:=Calc*2000000;       //Schiffzentner
9:Calc:=Calc*150000;        //Schiffpfund
10:Calc:=Calc*7500;         //Lispfund
11:Calc:=Calc*350.78;       //Apothekerpfund
12:Calc:=Calc*16000000;     //Pfund-Schwehr
13:Calc:=Calc*10000000;     //Schiff-Pfund
14:Calc:=Calc*700000;       //Lieﬂ-Pfund
else Result:=27;exit;end;
case einheit2 of
0:Calc:=Calc;               //Gramm
1:Calc:=Calc/1000;          //Kilogramm
2:Calc:=Calc/1000000;       //Tonne
3:Calc:=Calc*5;             //Karat
4:Calc:=Calc/28.8;          //Unze
5:Calc:=Calc/50;            //Neulot
6:Calc:=Calc/50000;         //Zentner (ztr)
7:Calc:=Calc/100000;        //Doppelzentner, auch Quintal (dz)
8:Calc:=Calc/2000000;       //Schiffzentner
9:Calc:=Calc/150000;        //Schiffpfund
10:Calc:=Calc/7500;         //Lispfund
11:Calc:=Calc/350.78;       //Apothekerpfund
12:Calc:=Calc/16000000;     //Pfund-Schwehr
13:Calc:=Calc/10000000;     //Schiff-Pfund
14:Calc:=Calc/700000;       //Lieﬂ-Pfund
else Result:=28;exit;end;
end;
9:begin //Raum
case einheit1 of
0:Calc:=Calc*1000000;        //m≥
1:Calc:=Calc*1000000;        //Festmeter (fm)
2:Calc:=Calc*1000000;        //Raummeter (Ster) (rm)
3:Calc:=Calc*16.387064;      //Kubikzoll (cubic inch) (ci)
4:Calc:=Calc*28316.846592;   //Kubikfuﬂ (cubic foot) (cf)
5:Calc:=Calc*1000;           //Liter (l, dm≥)
6:Calc:=Calc;                //ccm, cm≥
7:Calc:=Calc/1000;           //mm≥
8:Calc:=Calc*158987.294928;  //Barrel
9:Calc:=Calc*3785.411784;    //Gallone US (gal)
10:Calc:=Calc*473.176473;    //Pint (US)
11:Calc:=Calc/176.841000;    //Pfiff
12:Calc:=Calc*500;           //Kr¸gerl
13:Calc:=Calc*50000;         //Neuscheffel
14:Calc:=Calc*114500;        //Tonne
15:Calc:=Calc*114.5;         //Stof
16:Calc:=Calc*229000;        //Fass, Gebinde
17:Calc:=Calc*15000000;      //Zuber
18:Calc:=Calc*18370;         //Imi
19:Calc:=Calc*1837;          //Hellaichmaﬂ
20:Calc:=Calc*293920;        //Eimer
21:Calc:=Calc*17635200;      //Fuder
22:Calc:=Calc*734800;        //Anker
23:Calc:=Calc*2939200;       //Ohm (Ohme, Ahm, Aam, Saum, Sauma, Soma, Sohm)
24:Calc:=Calc*4408800;       //Oxhoft
25:Calc:=Calc*734800;        //St¸bchen
26:Calc:=Calc*283170000;     //Registertonne (RT, reg tn)
27:Calc:=Calc*4546;          //Imperial gallon (gal)
28:Calc:=Calc*36349;         //bushel (GB) (bu)
29:Calc:=Calc*35239;         //bushel (US) (bu)
30:Calc:=Calc*100000;        //Hektoliter
else Result:=27;exit;end;
case einheit2 of
0:Calc:=Calc/1000000;        //m≥
1:Calc:=Calc/1000000;        //Festmeter (fm)
2:Calc:=Calc/1000000;        //Raummeter (Ster) (rm)
3:Calc:=Calc/16.387064;      //Kubikzoll (cubic inch) (ci)
4:Calc:=Calc/28316.846592;   //Kubikfuﬂ (cubic foot) (cf)
5:Calc:=Calc/1000;           //Liter (l, dm≥)
6:Calc:=Calc;                //ccm, cm≥
7:Calc:=Calc*1000;           //mm≥
8:Calc:=Calc/158987.294928;  //Barrel
9:Calc:=Calc/3785.411784;    //Gallone US (gal)
10:Calc:=Calc/473.176473;    //Pint (US)
11:Calc:=Calc*176.841000;    //Pfiff
12:Calc:=Calc/500;           //Kr¸gerl
13:Calc:=Calc/50000;         //Neuscheffel
14:Calc:=Calc/114500;        //Tonne
15:Calc:=Calc/114.5;         //Stof
16:Calc:=Calc/229000;        //Fass, Gebinde
17:Calc:=Calc/15000000;      //Zuber
18:Calc:=Calc/18370;         //Imi
19:Calc:=Calc/1837;          //Hellaichmaﬂ
20:Calc:=Calc/293920;        //Eimer
21:Calc:=Calc/17635200;      //Fuder
22:Calc:=Calc/734800;        //Anker
23:Calc:=Calc/2939200;       //Ohm (Ohme, Ahm, Aam, Saum, Sauma, Soma, Sohm)
24:Calc:=Calc/4408800;       //Oxhoft
25:Calc:=Calc/734800;        //St¸bchen
26:Calc:=Calc/283170000;     //Registertonne (RT, reg tn)
27:Calc:=Calc/4546;          //Imperial gallon (gal)
28:Calc:=Calc/36349;         //bushel (GB) (bu)
29:Calc:=Calc/35239;         //bushel (US) (bu)
30:Calc:=Calc/100000;        //Hektoliter
else Result:=28;exit;end;
end;
10:begin //Z‰hlmaﬂe
case einheit1 of
0:Calc:=Calc;               //Eins
1:Calc:=Calc*12;             //Dutzend
2:Calc:=Calc*2;              //Paar
3:Calc:=Calc*10;             //Halbstiege, Decher, Dekade
4:Calc:=Calc*15;             //Mandel, Malter
5:Calc:=Calc*16;             //Bauern-, Groﬂe Mandel
6:Calc:=Calc*30;             //Band, Bund
7:Calc:=Calc*40;             //Zimmer
8:Calc:=Calc*60;             //Schock
9:Calc:=Calc*64;             //Groﬂschock
10:Calc:=Calc*80;            //Wall
11:Calc:=Calc*120;           //Groﬂhundert
12:Calc:=Calc*144;           //Gros, Groﬂ, Gross
13:Calc:=Calc*1200;          //Groﬂtausend
14:Calc:=Calc*1728;          //Maﬂ
else Result:=27;exit;end;
case einheit2 of
0:Calc:=Calc;               //Eins
1:Calc:=Calc/12;             //Dutzend
2:Calc:=Calc*0.5;              //Paar
3:Calc:=Calc*0.1;             //Halbstiege, Decher, Dekade
4:Calc:=Calc/15;             //Mandel, Malter
5:Calc:=Calc/16;             //Bauern-, Groﬂe Mandel
6:Calc:=Calc/30;             //Band, Bund
7:Calc:=Calc/40;             //Zimmer
8:Calc:=Calc/60;             //Schock
9:Calc:=Calc/64;             //Groﬂschock
10:Calc:=Calc/80;            //Wall
11:Calc:=Calc/120;           //Groﬂhundert
12:Calc:=Calc/144;           //Gros, Groﬂ, Gross
13:Calc:=Calc/1200;          //Groﬂtausend
14:Calc:=Calc/1728;          //Maﬂ
else Result:=28;exit;end;
end;
else Result:=29;Exit;end;
wert2^:=Calc;
end;

exports
Convert name 'Convert';

end.
