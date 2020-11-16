;Programmer: P�ntek R�bert Gerg� 2018
;Microcontroller: Microchip PIC16F1619
; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR
#include "p16F1619.inc" 
 
 __CONFIG _CONFIG1, _FOSC_INTOSC & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_ON & _FCMEN_ON
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _WRT_OFF & _PPS1WAY_ON & _ZCD_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_ON
; CONFIG3
; __config 0xFFFF
 __CONFIG _CONFIG3, _WDTCPS_WDTCPS1F & _WDTE_OFF & _WDTCWS_WDTCWSSW & _WDTCCS_SWC 

;------------------------------------------------------------------------------- 
;ORAJEL beallitas
 #define osccon b'01111000' ;16 mhz-re �ll�tjuk a bels? oscill�tort 
 
;------------------------------------------------------------------------------- 
;INTERRUPT l�bak defini�l�sa
 
#define intpps b'00010100' ; Interrupt perif�ria hozz�rendel�s l�bakhoz
#define intcon b'11001000' ; Interrupt konfigur�ci� v�ltoz�s figyel�sre van be�ll�tva   
#define ioccp  b'11000000' ; Interrupt felfut� �l figyel�s 6. 7. es l�bon C porton
#define ioccn  b'11000000' ; Interrupt lefut� �l figyel�s 6. 7. es l�bon C porton


;-------------------------------------------------------------------------------    
RES_VECT CODE 0x0000		; processor reset vector
    GOTO Start			; go to beginning of program
    
org 4				;ISR kezd? c�me
goto ISR

;-------------------------------------------------------------------------------
;V�ltoz�k mem�ria ter�lethez rendel�sre k�z�s ram-ot haszn�lom
    
cblock     0x70
    POS:2   ;0x70 LSB, 0x71 MSB ;Poz�ci�t ebben a k�t byteban t�roljuk
    s	    ;0x72
    state   ;0x73
    temp    ;0x74
endc
   
;------------------------------------------------------------------------------- 
;INTERRUPT SERVICE ROUTINE

ISR			;ISR programja
 BANKSEL PORTC		;megvizsg�ljuk melyik l�bon j�tt interrupt
 movfw PORTC		;�s ezt lementj�k a temp-be
 movwf temp		
 btfss temp,7
 goto APIN
 BTEST
 btfss temp,6
 goto BPIN
 goto UGRAS

PINA
movfw s			;s-be l�trehozzuk az el�z? �s az aktu�lis �llapot kombin�cioj�t
iorlw b'00000100'     
movwf s
 goto BTEST
PINB
movfw s
iorlw b'00001000'
movwf s
 goto UGRAS

;---------------------------------------------------------
;Lehets�ges esetek melyek el?fordulhatnak az enk�der forg�sa k�zben a t�bla ut�n ide ugrik vissza a program
SEMMI
    goto EXITISR
PLUS1
    incf POS
    btfsc STATUS,Z
    incf POS+1
    goto EXITISR
MINUS1
    movlw 0x01
    subwf POS
    BTFSS STATUS,C
    decf POS+1
    goto EXITISR
PLUS2
    incf POS
    btfsc STATUS,Z
    incf POS+1  
    incf POS
    btfsc STATUS,Z
    incf POS+1
    goto EXITISR
MINUS2
    movlw 0x0
    subwf POS
    BTFSS STATUS,C
    decf POS+1
    goto EXITISR
    
EXITISR			
 
	    
 rrf s
 rrf s			;Itt jobbra shiftel�nk kett�t, hogy az legyen a r�gi poz�ci�
 movfw s	    
 andlw 0x03		;maszkolunk
 movwf s
 
   BANKSEL IOCCF
    MOVLW 0xff		;interrupt flaget t�r�lj�k a c porton
    XORWF IOCCF, W	;Ezt az ISR-b�l valo kil�p�s el?tt el kell v�gezni    
    ANDWF IOCCF, F	;Ezt �rdemes k�l�n blokkokba helyezni �gy t�bb el�gaz�shoz lehet felhaszn�lni    
    retfie
 
Start
;------------------------------------------------------------------------------- 
;oRAJEL be�ll�t�s
BANKSEL OSCCON
    movlw osccon
    movwf OSCCON
;-------------------------------------------------------------------------------
;I/O be�ll�t�sok
BANKSEL ANSELC
    CLRF ANSELC 

BANKSEL TRISC
    movlw b'11111111'
    movwf TRISC 
 
BANKSEL PORTC
    clrf PORTC
;-------------------------------------------------------------------------------
;LED D5 RA5
;BANKSEL ANSELA
    ;CLRF ANSELA 

;BANKSEL TRISA
    ;CLRF TRISA 
 
;BANKSEL PORTA
    ;clrf PORTA

   

;------------------------------------------------------------------------------- 
;INTERRUPT l�bak be�ll�t�sa

BANKSEL INTPPS
 movlw intpps
 movwf INTPPS
 
BANKSEL INTCON
 movlw intcon
 movwf INTCON

BANKSEL IOCCP
 movlw ioccp
 movwf IOCCP
 
BANKSEL IOCCN
 movlw ioccn
 movwf IOCCN
 
;------------------------------------------------------------------------------- 
;State null�z�sa program indul�sakor
movlw 0x00
movwf POS
movwf POS+1
    
BANKSEL PORTC
movfw PORTC
andlw 0x03
movwf s

   
;------------------------------------------------------------------------------- 
;F?program
 
 main
 
    movfw POS
    goto main
    
;-------------------------------------------------
;Sz�m�tott ugr�s amely lev�logatja az enk�der lehets�ges �llapotait
UGRAS
     org     0xf7 
     movfw     s
     andlw     0x0F                ; Maskoljuk az �rv�nytelen r�szt csak az als� 4 bit kell, ez 16 �rt�ket tud t�rolni; Als� 4biten �gy az aktu�lis pozici� van
     movwf     state		   ; state k�ztes v�ltoz�ba mentj�k el az aktu�lis poz�ci�t
     movlw     high TABEL	   ; A mem�riac�m 13 bites ahol a t�bl�zatunk kezd�dik(org 256) annak a fels? 5 bitj�t bem�soljuk a pc lath ba
     movwf     PCLATH		   ; A PCLATH fogja adni a t�bl�zat fels? 5 bitj�nek a cim�t, hogy nek�nk csak az als� 8 bittel keljen foglakoznunk
     movlw     low TABEL	   ; A t�bl�zat c�m�nek als� 8 bitj�t elhelyezi a work regiszterbe
     addwf     state,w             ; �llapothoz tart�z� offset hozz�ad�sa work regiszterhez, ez �ltal l�trej�n a megfelel? �llapoth�z tartoz� mem�riac�munk aminek hat�s�ra a kiv�nt sz�mol�si esem�nyt v�gre tudjuk hajtani
     btfsc     STATUS,C            ; T�lcsordul�s ellen?rz�s, ezzel ellen�rizz�k, hogy el�f�rt�nk-e az adott mem�ria lapon
     incf      PCLATH,f            ; igen esetben: increment PCLATH   ha t�ll�g akkor a pclathban l�v? fels? 5 bitet eggyel eltoljuk, hogy r�f�rj�nk a t�bl�ra
     movwf     PCL                
;----------------------------------------------------------------
 ;A lehets�ges �llapotokat tartalmaz� t�bl�zat
 ;SEMMI->nincs elmozdul�s | PLUS1/2 -> counter +1/2 | MINUS1/2 -> counter -1/2
    org 256		   ;  PCL m�dos�t�sa
TABEL
     goto     SEMMI        ; 0000
     goto     PLUS1        ; 0001
     goto     MINUS1       ; 0010
     goto     PLUS2        ; 0011
     goto     MINUS1       ; 0100
     goto     SEMMI        ; 0101
     goto     MINUS2       ; 0110
     goto     PLUS1        ; 0111
     goto     PLUS1        ; 1000
     goto     MINUS2       ; 1001
     goto     SEMMI        ; 1010
     goto     MINUS1       ; 1011
     goto     PLUS2        ; 1100
     goto     MINUS1       ; 1101
     goto     PLUS1        ; 1110
     goto     SEMMI        ; 1111
 
 
 end