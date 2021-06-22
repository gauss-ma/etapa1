#!/bin/bash

source namelist

	ln -s ${dir}/exe/ETAPA1.EXE

echo "# ANEXO
## Cálculos de ETAPA 1 para proyecto: $PROYECTO.
A continuación se realizan las estimaciones de concentración máxima según el decreto Nº 1074/18 sección III.1 ETAPA 1: *Sondeo Simple*.
Estos cálculos están basados en modelo atmosférico bigaussiano y es aplicable a fuentes puntuales elevadas, para periodos de tiempo de concentraciones medias entre 15min y 1año.
Este modelo supone:
       a) Inexistencia de procesos de remoción de los contaminantes.
       b) La pluma de contaminantes no impacta sobre el terreno elevado.

Aplicable bajo condiciones Neutras ó Inestables. No útil para condiciones atmosféricas estables con fuentes de altura efectiva < 10m ó cuando la pluma intercepte terreno.
La Etapa I calcula la concentracion media horaria a nivel del suelo (1º a 6º pasos). Para concentracionesmáximas de otros tiemmpos es necesario multiplicar este valor por un factor de corrección (7º paso). Posteriormente es necesario adicionar la concentración de fondo (8º paso) y finalmente esta estimación debe ser comparada con el 30% del valor límite máximo admisible (9º paso).
"> ETAPA1_${PROYECTO}.md

for (( i=0; i<${#polluts[@]}; i++ ))
do

POLLUTID=${polluts[i]}
PERIOD=${periods[i]}

Cbg=$(awk -F ";" -v pollut=$POLLUTID -v period=$PERIOD '{if($1 == pollut && $2 == period){print $3 }}' ${inp_bg})
read Clim<<< $(./../../utils/get_AQ_std_values.sh OPDS1 $POLLUTID $PERIOD) # (!) NO USAR "OPDS"

awk -F";" -v pollut=$POLLUTID -v period=$PERIOD -v Cbg=$Cbg -v Clim=$Clim 'NR>1{
	if($1 == pollut){i+=1;
		## POLLUT SRCID TYPE XY Z Q H T U D
		SRCID[i]=$2;Q[i]=$6;H[i]=$7;T[i]=$8;U[i]=$9;D[i]=$10
	}else{}
}
END{	printf("&DIMS\nNSRCS=%.0f\n/\n&INPUTS\nPOLLUTID=\"%s\"\nPERIOD=\"%s\"\nC_bg=%s\nC_lim=%s\n\n",i,pollut,period,Cbg,Clim)
	printf("SRCID=");for(j=1;j<=i;j++){printf("\"%s\",",SRCID[j])};printf("\n")
	printf("Q="    );for(j=1;j<=i;j++){printf("%.3f,",  Q[j])};printf("\n")
	printf("h_ch=" );for(j=1;j<=i;j++){printf("%.3f,",  H[j])};printf("\n")
	printf("T_s="  );for(j=1;j<=i;j++){printf("%.3f,",  T[j])};printf("\n")
	printf("V_s="  );for(j=1;j<=i;j++){printf("%.3f,",  U[j])};printf("\n")
	printf("d_s="  );for(j=1;j<=i;j++){printf("%.3f,",  D[j])};printf("\n")
	printf("tiene_sombrerete="  );for(j=1;j<=i;j++){printf("%s,", ".false.")};printf("\n")
	printf("/\n")
}' ${inp_emis} > ETAPA1.INP

./ETAPA1.EXE

cat ETAPA1.OUT >> ETAPA1_${PROYECTO}.md

done

pandoc -s ETAPA1_${PROYECTO}.md -f markdown -o temp.doc

