program ETAPA1
!-----------------------------------------------------------------------------------------------------------
!Objetivo: 
!Cálculo de Concentración a nivel del suelo según decreto Nº 1074/18, (III.1 ETAPA 1: Sondeo Simple).
!
!-----------------------------------------------------------------------------------------------------------
!Entradas: 
!       Namelist "ETAPA1.INP" con dos secciones:
!               -&DIMS: NSRCS
!               
!               -&INPUTS:
!                       POLLUTID, PERIOD, C_bg,Clim.
!                       SRCID(:),Q(:),h_ch(:),T_s(:),d_s(:),V_s(:),tiene_sombrerete(:)
!
!-----------------------------------------------------------------------------------------------------------
!Salidas:
!       - ETAPA1.OUT    Datos de entrada, calculos intermedios y tabla de resultados finales.
!
!-----------------------------------------------------------------------------------------------------------
!COMPLIACIÓN: gfortran -ffree-line-length-2000000 ETAPA1.f90 -o ETAPA1.EXE
!-----------------------------------------------------------------------------------------------------------
implicit none
integer i

!Datos de de entrada:
integer :: NSRCS                         !Número de fuentes (chimeneas/conductos)
character(len=8) :: PERIOD,POLLUTID
real :: C_bg,C_lim
character(len=8), allocatable :: SRCID(:)
real,allocatable :: Q(:),h_ch(:),T_s(:),d_s(:),V_s(:)
logical,allocatable :: tiene_sombrerete(:)

!Parámetros:
real, parameter :: T_a=293.0                !Temperatura del aire ambiente.
real, parameter :: u(5) = (/ 1,2,3,5,10 /)  !Velocidad del viento. [m/s]
real, parameter :: g=9.81                   !Aceleración por la gravedad. [m/s2]

!variables intermedias
real :: F_b, uDh, C1, C30, Cmax
real, dimension(5) :: Dh, h_e, Cu_Q, C_Q
real, allocatable :: C(:)


namelist/DIMS/NSRCS
namelist/INPUTS/Q,h_ch,T_s,d_s,V_s,C_bg,C_lim,PERIOD,POLLUTID,SRCID,tiene_sombrerete

!leo dimensiones (numero de fuentes)
open(unit=1,file='ETAPA1.INP')
read(1,DIMS)
close(1)
!Reallocación de arrays según en numero de fuentes.
allocate(SRCID(NSRCS),Q(NSRCS), h_ch(NSRCS),T_s(NSRCS),d_s(NSRCS),V_s(NSRCS), tiene_sombrerete(NSRCS))
allocate(C(NSRCS))
!leo inputs
open(unit=1,file='ETAPA1.INP')
read(1, INPUTS)
close(1)
!-------------------------------------------------------------------------------------------
!Abro archivos de salida
open(1,file='ETAPA1.OUT',status="unknown",action="write")

        !Header de archivos de salida:
         write(1,'(/"## ("a8", "a8")"//)') POLLUTID,PERIOD
         
!Procedimiento:
!loop sobre chimeneas
do i=1,NSRCS,1

        ! 1º Paso: Estimación de uDh (elevacion normalizada de la  pluma)
                F_b=g*V_s(i)*d_s(i)*d_s(i)*(T_s(i)-T_a)/(4*T_s(i)) !Fuerza de empuje térmico.
                
                if (F_b .LT. 55) then
                        uDh=21.4*F_b**(0.75)
                else
                        uDh=38.7*F_b**(0.75)
                end if
        
        !2º Paso: Elevación de la pluma para cada velocidad.
                if ( (T_s(i) .LT. T_a) .OR. tiene_sombrerete(i) ) then
                        Dh=0
                else
                        Dh=uDh/u
                end if
        
        !3º Paso: Cálculo de Altura efectiva (h_e) para cada u
                h_e= h_ch(i) + Dh
        
        !4º Paso: Para c/altura efectiva calcular los valores de uC/Q
                Cu_Q = 0.0414*h_e**(1.5)
                !Cu_Q=0.0414*h_e**(-1.5) !Según Aldo.
        
        !5º Paso: Obtengo C/Q
                C_Q=Cu_Q/u
        
        !6º Paso: Obtengo máxima concentracion y lo multiplico por 2 para contemplar imprecisiones.
                C1=2*Q(i)*maxval(C_Q)
        
        !7º Paso: Ajuste por tiempo de promediado.
                if (PERIOD == "15 MIN") then
                            C(i)=1.5*C1
                else if (PERIOD =="1") then
                            C(i)=1.0*C1
                else if (PERIOD =="3") then
                            C(i)=0.7*C1
                else if (PERIOD =="8") then
                            C(i)=0.7*C1
                else if (PERIOD =="24") then
                            C(i)=0.4*C1
                else if (PERIOD =="3 MONTHS") then
                            C(i)=0.12*C1
                else if (PERIOD =="ANNUAL") then
                            C(i)=0.08*C1
                endif

        !Inputs y Resultados de esta chimenea:
        write(1,'("### "a8"."/)') SRCID(i)
        write(1,'("#### Datos de entrada:"/"<center>(Q H T D U) = ("5(f8.3)")</center>"/)') Q(i),h_ch(i),T_s(i),d_s(i),V_s(i)
        write(1,'("#### Cálculos intermedios:"/)')
        write(1,'("   + F<sub>b</sub>  = "  f10.5 )') F_b
        write(1,'("   + uDh   = "  f10.5 )') uDh
        write(1,'("   + Dh    = " 5f10.5 )') Dh
        write(1,'("   + h<sub>e</sub>   = " 5f10.5 )') h_e
        write(1,'("   + Cu/Q  = " 5f10.5 )') Cu_Q
        write(1,'("   + C/Q   = " 5f10.5 )') C_Q
        write(1,'("   + C<sub>1</sub>    = "  f10.5 )') C1
        write(1,'("   + C<sub>"a6"</sub> = "  f10.5/)') PERIOD,C(i)
        !------------------------------------------------------------------------------------------------
end do
!end loop para cada chimenea

!8º Paso: Para comparar con 30% del valor de la normativa.
        C30=sum(C)/0.3

!9º Paso: Sumar concentración de fondo.
        Cmax = C30 + C_bg

        !Resultados:
         write(1,'(/"#### Resultados:"/)')
         write(1,'("| Contaminante | Tiempo de promediado | Concentración Acumulada [ug/m3] |  Concentración ajustada al 30% [ug/m3]  |  Concentración de fondo [ug/m3]   |  Concentración total máxima [ug/m3]   |  Conetración límite según norma [ug/m3* |")')
         write(1,'("|  ------   |  -----   | -------- | -------- | -------- | -------- | ------- |")')
         write(1,'("| "2(a8" | ") 5(f10.2" |"))') POLLUTID,PERIOD,sum(C), C30, C_bg, Cmax, C_lim
         write(1,'("**Tabla:** Resultados finales de Etapa 1."/)')


close(1)
end program
