#Ifndef NULL
  '#define NULL cptr(any ptr, 0)
  const NULL as any ptr = 0
#endif

Screen 12

#ifndef __mod_fame_bi__
	#define __mod_fame_bi__
	#include once "fame.bi"
#EndIf

#Inclib "fame"

' definiciones del sistema a emular
const tamram =1024*1024*16 ' 16 MEGAS DE RAM MAXIMA
Dim Shared nrom As String 'nombre de la rom a cargar
Dim Shared inirom As Integer ' inicio rom principal
Dim Shared pila As Integer ' pila inicial segun ROM &h00000000
Dim Shared pc   As Integer ' inicio programa segun ROM &h00000004

' propias del sistema emulado


' depuracion
Dim Shared depurar As Integer=1
  
' reservamos la RAM requerida (lo mejor, es pillar TODO, o sea, 16mb)
Dim Shared ram(tamram) As UByte 'ptr
'Dim Shared ramp As Short Ptr = @ram(0) ' apunta a la RAM

' variables de la CPU FAME emulada
Dim Shared mc68k As M68K_CONTEXT 'Ptr

' depuracion
Sub debug(pila As Integer)
	Dim As Integer sr	
	Dim As Integer f
	
	Locate 1,1
	print "PC:";hex(m68k_get_pc(),8);" (nota: PC de INS anterior)"
	print "D0:";hex(m68k_get_register(M68K_REG_D0),8);"  ";
	print "D1:";hex(m68k_get_register(M68K_REG_D1),8);"  ";
	print "D2:";hex(m68k_get_register(M68K_REG_D2),8);"  ";
	print "D3:";hex(m68k_get_register(M68K_REG_D3),8)
	print "D4:";hex(m68k_get_register(M68K_REG_D4),8);"  ";
	print "D5:";hex(m68k_get_register(M68K_REG_D5),8);"  ";
	print "D6:";hex(m68k_get_register(M68K_REG_D6),8);"  ";
	print "D7:";hex(m68k_get_register(M68K_REG_D7),8)
	print "A0:";hex(m68k_get_register(M68K_REG_A0),8);"  ";
	print "A1:";hex(m68k_get_register(M68K_REG_A1),8);"  ";
	print "A2:";hex(m68k_get_register(M68K_REG_A2),8);"  ";
	print "A3:";hex(m68k_get_register(M68K_REG_A3),8)
	print "A4:";hex(m68k_get_register(M68K_REG_A4),8);"  ";
	print "A5:";hex(m68k_get_register(M68K_REG_A5),8);"  ";
	print "A6:";hex(m68k_get_register(M68K_REG_A6),8);"  ";
	print "A7:";hex(m68k_get_register(M68K_REG_A7),8)
	print "SR:";hex((sr = m68k_get_register(M68K_REG_SR)),4);
	print "  Flags:";
	Print IIf ((sr shr 4) and 1, "X", "-");
	Print IIf ((sr Shr 3) And 1, "N", "-");
	Print	IIf ((sr Shr 2) And 1, "Z", "-");
	Print	IIf ((sr Shr 1) And 1, "V", "-");
	Print	IIf ((sr      ) And 1, "C", "-");	
	Print "  IRQ: ";Bin(SR And &B11100000,8)
	For f=1 To 16
		Locate f,60
		Print Hex(pila-f,6);" : ";Hex(ram(pila-f),2)
	Next
	print			
End Sub

' leemos una direccion que esta intercambiada H por L y la dejamos bien 
Function leedir_swap(a As Integer) As Integer
	Dim a1 As Integer
	Dim a2 As Integer
	Dim a3 As Integer
	Dim a4 As Integer
	Dim dato As integer
	a1=ram(a+0)
	a2=ram(a+1)
	a3=ram(a+2)
	a4=ram(a+3)
	dato=(a2 Shl 24)+(a1 Shl 16)+(a4 Shl 8)+a3
	Return dato
End Function

' leemos un fichero intercambiando ALTO por BAJO segun necesita el FAME
Sub leerom_swap(n As String, d As Integer)
	Dim f As Integer
	Dim a As string=" "
	Dim b As String=" "
	f=0
	Open n For binary As 1
	While Not Eof(1)
		Get #1,f+1,a
		Get #1,f+2,b
		ram(d+f+0)=Asc(b) ' intercambiamos High por Low
		ram(d+f+1)=Asc(a) ' es necesario por el sistema del emulador FAME
		f+=2
	Wend
	Close 1
End Sub



' -------------------------------------------------
'          emulador de terminal de texto
' -------------------------------------------------
Sub terminal(valor As Integer, modo As integer)

	'valor Xor=1

	' modo=1 escritura (recibir en terminal), 0 lectura (enviar desde teclado)
	Static rs232 As Integer=0
	Dim skey As String
	Dim car As ubyte

	If modo=1 Then ' modo escritura en pantalla
	    If valor=&h600001 Then ' modo envio a terminal
		   If ram(valor Xor 1)=&h3 Then rs232=0:Exit Sub ' reset RS232 (ficticio)
			If ram(valor Xor 1)=&h15 Then rs232=0:Exit Sub ' modo 9600 (ficticio, a mi me la pela)
	    End If


		If valor=&h600003 Then ' modo envio a terminal
			rs232=1 ' recibido y listo para enviar
	   	Open "con:" For Output As 3
	   	car=ram(valor Xor 1)
	   	Print #3,Chr(car);
	   	Close 3
	   	ram(valor Xor 1)=0
		End If
	Else 
		' modo lectura desde terminal (lectura teclado)
	    If valor=&h600001 And rs232<>3 Then 
		   	skey=InKey
		   	If skey<>"" Then 
		   		rs232=3:ram(valor Xor 1)=1:ram((valor Xor 1)+2)=Asc(skeY):Exit Sub ':ram(valor+2)=Asc(skey)
		   	Else
		   		ram(valor Xor 1)=2
		   	End If
		   	rs232=1
		   '	Exit Sub 
		   'EndIf
	  	   'Exit Sub
	   End If
		'If valor=&h600001 Then 
			'ram(valor)=1 ' preparado para enviar
			'rs232=0
		   	'skey=InKey
		   	'If skey="" Then 
		   		'ram(valor)=1
		   	'	ram(valor+2)=Asc(skey)
		   	'	Exit sub
		   	'EndIf
		   	'ram(valor)=skey
		   	'rs232=3
		   	'Exit Sub 
		'End If
	
	   If valor=&h600003 And rs232=3 Then
	   	skey=InKey:If skey="" Then rs232=0: Exit Sub
			ram(valor Xor 1)=Asc(skey)
			rs232=0
	   End If
	 
	   'For valor=&h2384 To &h2384+256
	   '	ram(&h100000+(valor-&h2384))=ram(valor)
	   'Next
	End If
   
End Sub


' funciones HARDWARE para escribir por nosotros en caso de elegir el modelo externo
' si elegimos el modelo interno de direccionamiento, estas funciones no se usan.
'Function read_byte Cdecl (ByVal a As Integer) As Integer
'	If depurar Then Print "read byte: ";Hex(a,8);" --> ";Hex(ram(a),2)
'	terminal(a,0)
'	Return ram(a Xor 1)
'End Function
'Function read_word cdecl (byval a As Integer) As Integer
'	Dim w As Short
'	w=ram(a+1)*256+ram(a)
'	If depurar Then Print "read word: ";Hex(a,8);" --> ";Hex(w,4)
'	Return w'ram(a Shr 1)
'End Function
'Sub write_byte Cdecl (a As Integer,d As Integer)
'	If depurar Then Print "write byte: "; Hex(a,8);" <-- ";Hex(d,2)
'	ram(a Xor 1)=d And &hff
'	terminal(a,1)
'End Sub
'Sub write_word Cdecl (a As Integer,d As integer)
'	If depurar Then Print "write word: "; Hex(a,8);" <-- ";Hex(d,4)
'	d And=&hFFFF
'	ram(a+1)=d Shr 8
'	ram(a)=d And &hFF
'End Sub

' funciones HARDWARE para escribir por nosotros en caso de elegir el modelo externo
' si elegimos el modelo interno de direccionamiento, estas funciones no se usan.
Function read_byte Cdecl (ByVal a As Integer) As Integer
	If depurar Then Print "read byte: ";Hex(a,8);" --> ";Hex(ram(a),2)
	terminal(a,0)
	Return ram(a Xor 1)
End Function
Function read_word cdecl (byval a As Integer) As Integer
	Dim w As Short
	w=ram(a+1)*256+ram(a)
	If depurar Then Print "read word: ";Hex(a,8);" --> ";Hex(w,4)
	Return w'ram(a Shr 1)
End Function
Sub write_byte Cdecl (a As Integer,d As Integer)
	If depurar Then Print "write byte: "; Hex(a,8);" <-- ";Hex(d,2)
	ram(a Xor 1)=d And &hff
	terminal(a,1)
End Sub
Sub write_word Cdecl (a As Integer,d As integer)
	If depurar Then Print "write word: "; Hex(a,8);" <-- ";Hex(d,4)
	d And=&hFFFF
	ram(a+1)=d Shr 8
	ram(a)=d And &hFF
End Sub

' -------------------------------------------------
' espacio del programa en RAM (lo que seria la ROM)
' -------------------------------------------------
Dim Shared p68ks(0 To 2) as M68K_PROGRAM => _
	{_
		(&h000000,tamram,@ram(0)), _
	   (-1,-1,NULL ) _
	}
' espacio de trabajo RAM
Dim Shared d68ks(0 To 3) As M68K_DATA => _
	{_
		(&h000000,tamram,NULL,@ram(0) ),_
		(-1,-1,NULL) _
	}

Dim Shared d68ks_rb(0 To 3) As M68K_DATA => _
	{_
		(&h000000,tamram,@read_byte,NULL), _
		(-1,-1,NULL) _
	}
Dim Shared d68ks_rw(0 To 3) As M68K_DATA => _
	{_
		(&h000000,tamram,@read_word,NULL), _
		(-1,-1,NULL)_
	}
Dim Shared d68ks_wb(0 To 3) As M68K_DATA => _
	{_
		(&h000000,tamram,@write_byte,NULL), _
		(-1,-1,NULL)_
	}
Dim Shared d68ks_ww(0 To 3) As M68K_DATA => _
	{_
		(&h000000,tamram,@write_word,NULL), _
		(-1,-1,NULL)_
	}
' ---------------------------------------------



' -------------------------------
'         MOTOR PRINCIPAL
' -------------------------------
  
  ' ponemos a cero todos los registros
  Dim f As Integer
  Dim ff As Byte Ptr
  ff=@mc68k
  For f=0 To SizeOf(mc68k)
  	 *(ff+f)=0
  Next

 	mc68k.sv_fetch   = @p68ks(0)
	mc68k.user_fetch = @p68ks(0)

  ' si queremos que sea el emulador el que gestione la RAM
 	'mc68k.sv_read_byte    = @d68ks(0)
	'mc68k.user_read_byte  = @d68ks(0)
	'mc68k.sv_read_word    = @d68ks(0)
	'mc68k.user_read_word  = @d68ks(0)
	'mc68k.sv_write_byte   = @d68ks(0)
	'mc68k.user_write_byte = @d68ks(0)
	'mc68k.sv_write_word   = @d68ks(0)
	'mc68k.user_write_word = @d68ks(0)
 
  ' si queremos tener control de la RAM (definir entonces las funciones aparte)
 	mc68k.sv_read_byte    = @d68ks_rb(0)
	mc68k.user_read_byte  = @d68ks_rb(0)
	mc68k.sv_read_word    = @d68ks_rw(0)
	mc68k.user_read_word  = @d68ks_rw(0)
	mc68k.sv_write_byte   = @d68ks_wb(0)
	mc68k.user_write_byte = @d68ks_wb(0)
	mc68k.sv_write_word   = @d68ks_ww(0)
	mc68k.user_write_word = @d68ks_ww(0)


  ' forma de gestionar registros (ejemplos)
  'm68k_set_register(M68K_REG_SR,&h1111) ' SR o Status Register
  'm68k_set_register(M68K_REG_A7,&h2222) ' pila (STACK)
  'm68k_set_register(M68K_REG_PC,&h5000) ' PC Program Counter
  'm68k_set_register(M68K_REG_D2,&h4444) ' un dato aleatorio en D2


  ' activamos la CPU
   m68k_set_context(@mc68k)
 
  ' inicializamos el motor
 	m68k_init()

  ' inicializamos la CPU 
   m68k_reset()
 	'if m68k_reset() = M68K_OK Then
	'	Print ("Reset OK")
	'Else
	'	Print ("Reset ERROR")
	'	Sleep:end
 	'End If



  ' parametros del sistema a emular

   ' monitor S100
	nrom="t68k.bin"
	inirom=&h000000
	
	' tiny basic
	'nrom="tbi68k.bin"
	'inirom=&h900 ' regpc en 922??

   leerom_swap(nrom,inirom)
   
   pc  =leedir_swap(&h000004)
   pila=leedir_swap(&h000000)

   m68k_set_register(M68K_REG_PC,pc  ) ' PC cogido en 000004h
   m68k_set_register(M68K_REG_A7,pila) ' A7 (SSP) cogido en 000000h
   
   Dim status As Integer
   'debug(pila)
   While 1=1
     If depurar Then Locate 15,1 ' para depurar rutinas de lectura/escritura, quitar luego
 	  m68k_emulate(1)
     If depurar Then debug(pila)
         
     status=m68k_get_cpu_state()
	   If (status <> M68K_OK) Then 
				Print "RUN ERROR:";status
				If status=38 Then Print "....BUS ADDRESS ERROR"
				Sleep:End
	   End If
	   
	   
	   'Sleep
	   'cls
   Wend
   
' notas:
   
' direcciones exclusivas CPU
'00 SUPER_STACK
'04 MAIN
'08 BUS_ERROR
'0c ADDRESS_ERROR
'10 ILLEGAL_INSTRUCTION
   
' si tenemos un error de direccion (38d) comprobar que no se este escribiendo
' fuera de las direcciones de RAM asignadas.
' por ejemplo, si no hemos "ponido" la pila, por defecto esta en "0", y si a "0"
' le restamos un valor inicial que metemos dentro, al restar "4", obtenemos "fffffc"
' con lo cual, caemos fuera del espacio de memoria reservado al 68000 (00ffffff o 16mb)
   
' la libreria a usar para compilar es la FAME.LIB
' la DLL del FAME.DLL debe ir con el exe cuando se ejecuta