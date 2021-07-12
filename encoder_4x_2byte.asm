;Programmer: Péntek Róbert Gergó 2018
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
;óRAJEL beállítás
 #define osccon b'01111000' ;16 mhz-re állítjuk a bels? oscillátort 
 
;------------------------------------------------------------------------------- 
;INTERRUPT lábak definiálása
 
#define intpps b'00010100' ; Interrupt periféria hozzárendelés lábakhoz
#define intcon b'11001000' ; Interrupt konfiguráció változás figyelésre van beállítva   
#define ioccp  b'11000000' ; Interrupt felfutó él figyelés 6. 7. es lábon C porton
#define ioccn  b'11000000' ; Interrupt lefutó él figyelés 6. 7. es lábon C porton


;-------------------------------------------------------------------------------    
RES_VECT CODE 0x0000		; processor reset vector
    GOTO Start			; go to beginning of program
    
org 4				;ISR kezd? címe
goto ISR

;-------------------------------------------------------------------------------
;Változók memória területhez rendelésre közös ram-ot használom
    
cblock     0x70
    POS:2   ;0x70 LSB, 0x71 MSB ;Pozíciót ebben a két byteban tároljuk
    s	    ;0x72
    state   ;0x73
    temp    ;0x74
endc
   
;------------------------------------------------------------------------------- 
;INTERRUPT SERVICE ROUTINE

ISR			;ISR programja
 BANKSEL PORTC		;megvizsgáljuk melyik lábon jött interrupt
 movfw PORTC		;és ezt lementjük a temp-be
 movwf temp		
 btfss temp,7
 goto APIN
 BTEST
 btfss temp,6
 goto BPIN
 goto UGRAS

APIN
movfw s			;s-be létrehozzuk az elöz? és az aktuális állapot kombinácioját
iorlw b'00000100'     
movwf s
 goto BTEST
BPIN
movfw s
iorlw b'00001000'
movwf s
 goto UGRAS

;---------------------------------------------------------
;Lehetséges esetek melyek el?fordulhatnak az enkóder forgása közben a tábla után ide ugrik vissza a program
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
 rrf s			;Itt jobbra shiftelünk kettöt, hogy az legyen a régi pozíció
 movfw s	    
 andlw 0x03		;maszkolunk
 movwf s
 
   BANKSEL IOCCF
    MOVLW 0xff		;interrupt flaget töröljük a c porton
    XORWF IOCCF, W	;Ezt az ISR-böl valo kilépés el?tt el kell végezni    
    ANDWF IOCCF, F	;Ezt érdemes külön blokkokba helyezni így több elágazáshoz lehet felhasználni    
    retfie
 
Start
;------------------------------------------------------------------------------- 
;oRAJEL beállítás
BANKSEL OSCCON
    movlw osccon
    movwf OSCCON
;-------------------------------------------------------------------------------
;I/O beállítások
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
;INTERRUPT lábak beállítása

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
;State nullázása program indulásakor
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
;Számított ugrás amely leválogatja az enkóder lehetséges állapotait
UGRAS
     org     0xf7 
     movfw     s
     andlw     0x0F                ; Maskoljuk az érvénytelen részt csak az alsó 4 bit kell, ez 16 értéket tud tárolni; Alsó 4biten így az aktuális pozició van
     movwf     state		   ; state köztes változóba mentjük el az aktuális pozíciót
     movlw     high TABEL	   ; A memóriacím 13 bites ahol a táblázatunk kezdödik(org 256) annak a fels? 5 bitjét bemásoljuk a pc lath ba
     movwf     PCLATH		   ; A PCLATH fogja adni a táblázat fels? 5 bitjének a cimét, hogy nekünk csak az alsó 8 bittel keljen foglakoznunk
     movlw     low TABEL	   ; A táblázat címének alsó 8 bitjét elhelyezi a work regiszterbe
     addwf     state,w             ; Állapothoz tartózó offset hozzáadása work regiszterhez, ez által létrejön a megfelel? állapothóz tartozó memóriacímunk aminek hatására a kivánt számolási eseményt végre tudjuk hajtani
     btfsc     STATUS,C            ; Túlcsordulás ellen?rzés, ezzel ellenörizzük, hogy eléfértünk-e az adott memória lapon
     incf      PCLATH,f            ; igen esetben: increment PCLATH   ha túllóg akkor a pclathban lév? fels? 5 bitet eggyel eltoljuk, hogy ráférjünk a táblára
     movwf     PCL                
;----------------------------------------------------------------
 ;A lehetséges állapotokat tartalmazó táblázat
 ;SEMMI->nincs elmozdulás | PLUS1/2 -> counter +1/2 | MINUS1/2 -> counter -1/2
    org 256		   ;  PCL módosítása
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
