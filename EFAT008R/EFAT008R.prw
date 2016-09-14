/*
+-----------------------------------------------------------------------+
| TOTVS MEXICO SA DE CV - Todos los derechos reservados.                |
|-----------------------------------------------------------------------|
|    Cliente:                                                           |
|    Archivo: EFAT008R.PRW                                              |
|   Objetivo: Impresi�n de Pedido de venta Modelo 1.                    |
| Responable: Filiberto P�rez DESARROLLADOR                             |
|      Fecha: Junio del 2014                                            |
+-----------------------------------------------------------------------+
*/

#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "FONT.CH" 
#INCLUDE "PROTHEUS.CH"                    

User Function EFAT008R()

Local cAreaA:=alias()
cPerg := "EFAT008R" 

AjustaSX1()
Pergunte(cPerg,.F.)

@ 200,1 TO 400,377 DIALOG oLeTxt TITLE OemToAnsi("Impresi�n de Pedido de Venta")
@ .5,.5 TO 6,23
@ 01,001 Say "                                                                      "
@ 02,001 Say " Este programa imprime el formato de Pedido de venta de acuerdo a los "
@ 03,001 Say " par�metros informados por el usuario.                                "
@ 04,001 Say "                                                                      "
@ 86,095 BMPBUTTON TYPE 05 ACTION Pergunte(cPerg) 	// Boton de Parametros
@ 86,125 BMPBUTTON TYPE 06 ACTION Reimprime() 	 	// Boton de Generaci�n e Impresion
@ 86,155 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)

Activate Dialog oLeTxt Centered
RETURN

static function REIMPRIME()
Processa({|lEnd|MontaRel()})
return

// FUNCION PRINCIPAL PARA IMPRESION DEL REPORTE
Static Function MontaRel()
local iNum       		:= 0
local iNumMax    		:= 40
local iCont       	    := 0
Local cDescripcion	    := ""
Local cNumSer			:= ""  
Local cQuery			:= ""
local nLines			:= 0


Private mes 		:= 0
Private ano 		:= space(4)
Private meses		:= {'Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'}
Private nom_mes	    := space(15) 
private oPrint	    := nil
private oBrush

private nPagNum 	:= 0
Private nRenIni  	:= 50 
Private nColIni  	:= 20 
Private nLin     	:= nRenIni+800

Private oLucCon10   := TFont():New("Lucida Console",10,10,,.F.,,,,.T.,.F.)
Private oLucCon10N	:= TFont():New("Lucida Console",10,10,,.T.,,,,.T.,.F.)

//Private cLogoCli	:=  GetSrvProfString("Startpath","") + ".png"
Private cLogoCli	:=  GetSrvProfString("Startpath","") + "logoFac.jpg"	

Private _Subtotal		:= 0
Private _nDesc   		:= 0    
Private _nIva   		:= 0
Private cNum	       

aArea:=Getarea()
oFont6  	:= TFont():New("Arial",9, 6,.T.,.F.,5,.T.,5,.T.,.F.)
oFont8  	:= TFont():New("Arial",9, 8,.T.,.F.,5,.T.,5,.T.,.F.)
oFont8n  	:= TFont():New("Arial",9, 8,.T.,.T.,5,.T.,5,.T.,.F.) 
oFont9x 	:= TFont():New("Arial",8,8,.T.,.F.,5,.T.,5,.T.,.F.)
oFont9 	    := TFont():New("Arial",9,9,.T.,.F.,5,.T.,5,.T.,.F.)
oFont10 	:= TFont():New("Arial",9,10,.T.,.F.,5,.T.,5,.T.,.F.)
oFont10n	:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
oFont12 	:= TFont():New("Arial",9,12,.T.,.F.,5,.T.,5,.T.,.F.)
oFont12n	:= TFont():New("Arial",9,12,.T.,.T.,5,.T.,5,.T.,.F.)
oFontCN 	:= TFont():New("Times New Roman",9,9,.T.,.F.,5,.T.,5,.T.,.F.)  

oArial08 	:= TFont():New("Arial",9, 8,.T.,.F.,5,.T.,5,.T.,.F.)
oArial08N	:= TFont():New("Arial",9, 8,.T.,.T.,5,.T.,5,.T.,.F.)
oArial10 	:= TFont():New("Arial",9,10,.T.,.F.,5,.T.,5,.T.,.F.)
oArial10N	:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
oArial12 	:= TFont():New("Arial",9,12,.T.,.F.,5,.T.,5,.T.,.F.)
oArial12N	:= TFont():New("Arial",9,12,.T.,.T.,5,.T.,5,.T.,.F.)
oArial14 	:= TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
oArial14N	:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)

//SC6->(dbsetorder(3))  

cQuery  =   " SELECT *"
cQuery  +=  " FROM " + RetSqlName("SC5") + " SC5 "
cQuery  +=  " WHERE C5_FILIAL = '" + xFilial("SC5") + "' "
cQuery  +=  " AND   C5_NUM    = '" + mv_par01 + "'"
cQuery  +=  " AND   SC5.D_E_L_E_T_<>'*' "
cQuery  := ChangeQuery(cQuery)
DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"ENC",.T.,.T.) 
If ENC->(eof())
	Aviso("Atencion","No existen informaci�n por reportar",{ "Ok" })
	Return
Else
	
	cNum:= ENC->C5_NUM
	
	cFileName := ALLTRIM(ENC->C5_NUM) + "_Mod1.pdf"
	oPrint	:= FWMsPrinter():New(cFileName,6,.T.,,.T.,,,,,,,.t.,)
	oPrint:SetResolution()
	oPrint:SetPortrait()
	//oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:cPathPDF:= "C:\SPOOL\PedidosVenta\"

	ProcRegua(10) 
	While !ENC->(eof())
		nPagNum := 0
		oPrint:StartPage()
		EncPag()
		cNum := 0
		iNum := 0
		IncProc()
		
		cQuery := " SELECT CAST(CAST(C6_VDOBS AS VARBINARY(8000)) AS VARCHAR(8000)) AS C6_VDOBS,*  "
		cQuery += " FROM " + RetSqlName("SC6")+" SC6 "
		cQuery += " WHERE C6_NUM    = '"+ENC->C5_NUM+"'"                                
		cQuery += "   AND C6_FILIAL = '" + xFilial("SC6") + "'"
		cQuery += "   AND D_E_L_E_T_<>'*'" 
		cQuery := ChangeQuery(cQuery) 
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"DET",.T.,.T.)
		While !DET->(eof())
		
			oPrint:Say( nLin,nColIni     , TRANSFORM(DET->C6_QTDVEN,"@E 9,999,999"),oLucCon10, 100)
			oPrint:Say( nLin,nColIni+250 , DET->C6_PRODUTO, oLucCon10,100)
			//oPrint:Say( nLin,nColIni+1630, DET->C6_LOCAL,oLucCon10, 100)
			cUnidad:=ALLTRIM(Posicione("SB1",1,xFilial("SB1")+DET->C6_PRODUTO,"B1_UM"))
		   	oPrint:Say( nLin,nColIni+2070, cUnidad, oLucCon10, 100)//
			cDescripcion:=ALLTRIM(Posicione("SB1",1,xFilial("SB1")+DET->C6_PRODUTO,"B1_DESC"))
			oPrint:Say( nLin,nColIni+1730, TRANSFORM(DET->C6_PRCVEN,"@E 9,999,999.9999"), oLucCon10, 100)			
			oPrint:Say( nLin,nColIni+2130, TRANSFORM(DET->C6_VALOR, "@E 999,999,999.9999"), oLucCon10, 100)
			
			iCont := 1
			WHILE iCont < len(TRIM(cDescripcion))
				if iNum >= iNumMax
					oPrint:EndPage() 
					oPrint:StartPage()
					EncPag()
					iNum := 0
					nLin := nRenIni+800
				endif				
				oPrint:Say( nLin,nColIni+600, SUBSTR(TRIM(cDescripcion),iCont,45), oLucCon10, 100)
				iCont += 45
				nLin  += 50
				iNum  ++      
			ENDDO   
			iCont := 1
			if !empty(alltrim(DET->C6_NUMSERI))
				cNumSer :=  "Numero de Serie: " + TRIM(DET->C6_NUMSERI)
				WHILE iCont < len(cNumSer)
					oPrint:Say( nLin,nColIni, SUBSTR(cNumSer,iCont,45), oLucCon10, 100)
					iCont += 45
					nLin  += 50
					iNum  ++      
				ENDDO 	
			endif		  
cObs :=  Alltrim(DET->C6_VDOBS) // Variable que contiene la descriocuion de la pieza					
cCadena:= cObs

nLimite:= 68
nResto:= len(cCadena)//-nLimite
nPosIni:= 1
nPosFin:= 0
nLinDes := 0
nFall		:= 1

IF LEN(cCadena)<68
oPrint:Say(nLin,nColIni+600,cCadena,oLucCon10)
			
ENDIF

while nResto >=68
//while len(cCadena) >=55

		nPosFin:= 68
		IF LEN(cCadena)>=68
			nPosFin:= rat(" ",substr(cCadena,nPosIni,nPosFin) )
		ELSE
			nPosFin:= 68 
		ENDIF               
		IF nPosFin == 0
			cImprime:=cCadena
			//msgalert(cImprime) //imprimir
			oPrint:Say(nLin,,cImprime,oLucCon10)
					nLinDes ++
					nFall ++ 
			//BREAK	
		ENDIF
		cImprime:=substr(cCadena,nPosIni,nPosFin)
		
		oPrint:Say(nLin + (nLinDes * 35),0480,U_fJustTex(cImprime,68),oLucCon10)		//Descripcion

					//nLoop ++
					nLinDes ++
					nFall ++
	    nResto:= len(cCadena)-nPosIni
	    cCadena:=alltrim(substr(cCadena, nPosFin , len(cCadena)))

enddo
//nLinDes ++
//nFall ++

			
			
			            
/*
			if !empty(cObs)    
				nLines := MLCount(cObs)
							
				For iCont := 1 To nLines
					IF !EMPTY(MemoLine(cObs,,iCont))
					
						if iNum >= iNumMax 
							oPrint:EndPage() 
							oPrint:StartPage()
							EncPag()
							iNum := 0
							nLin := nRenIni+800
						endif											
						iNum ++
						
						oPrint:Say(nLin,nColIni,U_fJustTex(cObs,68),oLucCon10) //Linea que muestra el campo descripcion Memo
						
						
						//oPrint:Say(nLin,nColIni+650,ALLTRIM(MemoLine(cObs,,iCont,45)),oLucCon10,100)
						nLin += 50

					ENDIF
				Next iCont			
			endif
*/			
			iNum ++
			nLin += 50

			if iNum >= iNumMax
				oPrint:EndPage() 
				oPrint:StartPage()
				EncPag()
				iNum := 0
				nLin := nRenIni+800
			endif
			
			_Subtotal	+= DET->C6_VALOR
			_nDesc   	+= DET->C6_VALDESC
			_nIva		+= 0 
		
          	DET->(Dbskip())
        End
        DET->(Dbclosearea())
		
		PiePag()
		//oPrint:EndPage()     // Finaliza a p�gina
		ENC->(dbSkip())
	EndDo 

	ENC->(dbCloseArea())

	oPrint:EndPage()
	oPrint:Print()
	FreeObj(oPrint)
	
Endif
restarea(aArea)
Return

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------//
/////////////////////////////////////////////////////////////Funcion que ajusta texto /////////////////////////////////////////////////////////////////////////////////
User FUNCTION fJustTex(cMemo, nLen)

LOCAL nLin, cLin, lInic, lFim
Local aWords:={}
Local cNovo:=""
Local cWord, lContinua, nTotLin
Local nAux:=0

   lInic:=.T.
   lFim:=.F.
   nTotLin:=MLCOUNT(cMemo, nLen)
   FOR nLin:=1 TO nTotLin

      cLin:=RTRIM(MEMOLINE(cMemo, nLen, nLin)) //recuperar

      IF EMPTY(cLin) //Uma linha em branco ->Considerar um par�grafo vazio
         IF lInic  //Inicio de paragrafo
           aWords:={}  //Limpar o vetor de palavras
           lInic:=.F.
         ELSE
            AADD(aWords, CHR(13)+CHR(10)) //Incluir quebra de linha
         ENDIF
         AADD(aWords, CHR(13)+CHR(10)) //Incluir quebra de linha
         lFim:=.T.
      ELSE
         IF lInic  //Inicio de paragrafo
            aWords:={} //Limpar o vetor de palavras
            //Incluir a primeira palavra com os espacos que a antecedem
            cWord:=""
            WHILE SUBSTR(cLin, 1, 1)==" "
               cWord+=" "
               cLin:=SUBSTR(cLin, 2)
            END
            IF(nNext:=AT(SPACE(1), cLin))<>0
               cWord+=SUBSTR(cLin, 1, nNext-1)
            ENDIF
            AADD(aWords, cWord)
            cLin:=SUBSTR(cLin, nNext+1)
            lInic:=.F.
         ENDIF
         //Retirar as demais palavras da linha
         WHILE(nNext:=AT(SPACE(1), cLin))<>0
            IF !EMPTY(cWord:=SUBSTR(cLin, 1, nNext-1))
               IF cWord=="," .AND. !EMPTY(aWords)
                  aWords[LEN(aWords)]+=cWord
               ELSE
                  AADD(aWords, cWord)
               ENDIF
            ENDIF
            cLin:=SUBSTR(cLin, nNext+1)
         END
         IF !EMPTY(cLin) //Incluir a ultima palavra
            IF cLin=="," .AND. !EMPTY(aWords)
               aWords[LEN(aWords)]+=cLin
            ELSE
               AADD(aWords, cLin)
            ENDIF
         ENDIF
         IF nLin==nTotLin  //Foi a ultima linha -> Finalizar o paragrafo
            lFim:=.T.
         ELSEIF RIGHT(cLin, 1)=="." //Considerar que o 'ponto' finaliza paragrafo
            AADD(aWords, CHR(13)+CHR(10))
            lFim:=.T.
         ENDIF
      ENDIF

      IF lFim
         IF LEN(aWords)>0
            nNext:=1
            nAuxLin:=1
            WHILE nAuxLin<=LEN(aWords)
               //Montar uma linha formatada
               lContinua:=.T.
               nTot:=0
               WHILE lContinua
                  nTot+=(IF(nTot=0, 0, 1)+LEN(aWords[nNext]))
                  IF nNext==LEN(aWords)
                     lContinua:=.F.
                  ELSEIF (nTot+1+LEN(aWords[nNext+1]))>=nLen
                     lContinua:=.F.
                  ELSE
                     nNext++
                  ENDIF
               END
               IF nNext==LEN(aWords)  //Ultima linha ->Nao formata
                  FOR nAux:=nAuxLin TO nNext
                     //cNovo+=(IF(nAux==nAuxLin, "", " ")+aWords[nAux])
                     cNovo+=(CalcSpaces(nNext-nAuxLin, nLen-nTot-1, nAux-nAuxLin)+aWords[nAux])
                  NEXT
               ELSE //Formatar
                  FOR nAux:=nAuxLin TO nNext
                     cNovo+=(CalcSpaces(nNext-nAuxLin, nLen-nTot-1, nAux-nAuxLin)+aWords[nAux])
                  NEXT
                  cNovo+=CHR(13)+CHR(10)//" "
               ENDIF
               nNext++
               nAuxLin:=nNext
            END
         ENDIF

         lFim:=.F.  //Indicar que o fim do paragrafo foi processado
         lInic:=.T. //Forcar inicio de paragrafo

      ENDIF

   NEXT

   //Retirar linhas em branco no final
   WHILE LEN(cNovo)>2 .AND. (RIGHT(cNovo, 2)==CHR(13)+CHR(10))
      cNovo:=LEFT(cNovo, LEN(cNovo)-2)
   END

   cMemo:=cNovo

RETURN (cMemo)

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------

Static FUNCTION CalcSpaces(nQt, nTot, nPos)
LOCAL cSpaces,; //Retorno de espacos
      nDist,;   //Total de espacos excedentes a distribuir em cada separacao
      nLim      //Ate que posicao devera conter o resto da divisao

   IF nPos==0
      cSpaces:=""
   ELSE
      nDist:=INT(nTot/nQt)
      nLim:=nTot-(nQt*nDist)
      cSpaces:=REPL(SPACE(1), 1+nDist+IF(nPos<=nLim, 1, 0))
   ENDIF

RETURN cSpaces 


// FUNCION PARA IMPRESION DE ENCABEZADO
Static Function EncPag()

//Private cNum:= ENC->C5_NUM

	Fec:= ENC->C5_EMISSAO
	cVendedor:= ENC->C5_VEND1
	cNaturaleza:= ENC->C5_NATUREZ
	//cobs:= SC6->C6_VDBS
	
	dia := substr(fec,7,2)
	mes := substr(fec,5,2)
	ano := substr(fec,1,4)
	
	nLin := nRenIni+800

	oPrint:SayBitmap(50,100,cLogoCli,475,176)
	
	oPrint:Say( nRenIni,nColIni+700     ,Alltrim(SM0->M0_NOMECOM)														,oArial14N)
	oPrint:Say( nRenIni+70,nColIni+700  ,Alltrim(SM0->M0_ENDCOB) + " " + AllTrim(SM0->M0_COMPCOB)					,oArial10N)
	oPrint:Say( nRenIni+120,nColIni+700 ,AllTrim(SM0->M0_BAIRCOB) + ", " + AllTrim(SM0->M0_CIDCOB)					,oArial10N)
	oPrint:Say( nRenIni+170,nColIni+700 ,AllTrim(SM0->M0_ESTCOB) + " M�xico. C.P. " + AllTrim(SM0->M0_CEPCOB)	,oArial10N)
	oPrint:Say( nRenIni+220,nColIni+700 ,"RFC: " + Alltrim(SM0->M0_CGC) + ". Tel�fono: " + Alltrim(SM0->M0_TEL)	,oArial10N)

	nPagNum := nPagNum + 1
	oPrint:Say(0050,2250,"P�gina: "+Transform(nPagNum,"999"),oArial10N) // Numero de la pagina
	  	
   	/*IMPRIME DATOS DEL CLIENTE*/ 
	dbselectarea("SA1")
	dbSetOrder(1)
	IF SA1->(dbseek(xFILIAL("SA1")+ENC->C5_CLIENTE+ENC->C5_LOJACLI)) 
		cNumcLII  	:= ALLTRIM(ENC->C5_CLIENTE)
		cCliNom	    := ALLTRIM(SA1->A1_NOME)
		cCliRfc	    := ALLTRIM(SA1->A1_CGC)
		cCliCalle	:= ALLTRIM(SA1->A1_END)
		cCliNumExt	:= ALLTRIM(SA1->A1_NR_END)
		cCliNumInt	:= ALLTRIM(SA1->A1_NROINT)
		cCliMun	    := ALLTRIM(SA1->A1_MUN)
		cCliCol	    := ALLTRIM(SA1->A1_BAIRRO)
		cCliEst	    := AllTrim(POSICIONE("SX5", 1, XFILIAL("SX5") + '12' + SA1->A1_EST, 'SX5->X5_DESCSPA'))
		cCliPais	:= AllTrim(POSICIONE("SYA", 1, XFILIAL("SX5") + SA1->A1_PAIS, 'SYA->YA_DESCR'))
		cCliCp		:= ALLTRIM(SA1->A1_CEP)    
		cTelP	   	:= ALLTRIM(SA1->A1_TEL)
		cCliCont  	:= ALLTRIM(SA1->A1_CONTATO)	
		cMoneda    	:= AllTrim(POSICIONE("CTO",1,XFILIAL("CTO")+strzero(SC5->C5_MOEDA,2),"CTO_DESC"))

		cNaturaleza := POSICIONE("SED",1,XFILIAL("SED") + cNaturaleza, "ED_DESCRIC")//Agregado cVendor
		cOrCoCnt    := ALLTRIM(ENC->C5_OCCLIEN)// Agregado cOrCoCnt
		cVendedor   := POSICIONE("SA3",1,XFILIAL("SA3") + cVendedor, "A3_NOME")//Agregado cVendor 
		cRespCap    := ALLTRIM(ENC->C5_CAPTUR)//Agregado cRespCap
		cTransporte := ALLTRIM(ENC->C5_TRANSPO)//Agregado Transporte
		
		oPrint:Say( nRenIni+300,050,"CLIENTE:     ", oArial10N, 100) /*Nombre */
		oPrint:Say( nRenIni+350,050,"R.F.C.:      ", oArial10N, 100) /*R.F.C. */
		oPrint:Say( nRenIni+400,050,"DIRECCION:   ", oArial10N, 100) /*Direccion, Colonia */
		oPrint:Say( nRenIni+550,050,"ENTREGAR EN: ", oArial10N, 100) /*Email, tel y fax */
		oPrint:Say( nRenIni+650,050,"TRANSPORTE: ", oArial10N, 100) /*Transporte Informacion Libre*/
		
	   	oPrint:Say( nRenIni+300,300,"(" + cNumcLII + ") - " + cCliNom,oArial10, 100) /*Cliente  */
		oPrint:Say( nRenIni+350,300,cCliRfc,oArial10, 100) /*R.F.C. */
		oPrint:Say( nRenIni+400,300,cCliCalle + " " + cCliNumExt + " " + cCliNumInt + ", " + cCliCol,oArial10, 100) /*Direccion, Colonia */	
		oPrint:Say( nRenIni+450,300,cCliMun + ", " + cCliEst + " C.P. " + cCliCp +  " " + cCliPais,oArial10, 100) /*Ciudad, CP */ 
		oPrint:Say( nRenIni+500,300,"TEL. " + cTelP + " FAX. "+SA1->A1_FAX,oArial10, 100) /*Email, tel y fax */ 
		oPrint:Say( nRenIni+550,300,ALLTRIM(MV_PAR05),oArial10N)                                         
		oPrint:Say( nRenIni+600,300,ALLTRIM(MV_PAR06) + " " + ALLTRIM(MV_PAR07),oArial10N)
		oPrint:Say( nRenIni+650,300,cTransporte,oArial10, 100)
        
        //AGREGADO CAMPO NATURALIZE DE LA MODALIDAD

		oPrint:Say( nRenIni+300,1520,"TPO DE PEDIDO : ", oArial10N, 100) //NATURALEZA DE LA MODALIDADA
		//-----------------------------------------------------------------------------------------
		oPrint:Say( nRenIni+350,1520,"PEDIDO:       ", oArial10N, 100) 
		oPrint:Say( nRenIni+400,1520,"FECHA:        ", oArial10N, 100)
		oPrint:Say( nRenIni+450,1520,"COND. PAGO:   ", oArial10N, 100) 
		oPrint:Say( nRenIni+500,1520,"MONEDA:       ", oArial10N, 100) 
		//oPrint:Say( nRenIni+550,1520,"CONTACTO:     ", oArial10N, 100)
		//----------------------------------------------------------------------------------------- 
		oPrint:Say( nRenIni+550,1520,"ORDEN COMPRA CLIENTE: ", oArial10N, 100) 
		oPrint:Say( nRenIni+600,1520,"VENDEDOR: ", oArial10N, 100) 
		oPrint:Say( nRenIni+650,1520,"RESPONSABLE DE LA CAPTURA: ", oArial10N, 100) 

		SE4->(dbseek(xfilial("SE4")+SC5->C5_CONDPAG))
		oPrint:Say( nRenIni+300,1900,cNaturaleza,oArial10N) //Naturaleza Modalidad
		oPrint:Say( nRenIni+350,1900,cNum,oArial10N) 
		oPrint:Say( nRenIni+400,1900,DIA + "/" + MES + "/" + ANO,oArial10N) // Fecha 
		oPrint:Say( nRenIni+450,1900,SE4->E4_DESCRI   ,oArial10) //Fecha Elaborac.
		oPrint:Say( nRenIni+500,1900,cMoneda,oArial10) //Moneda
		//oPrint:Say( nRenIni+550,1800,cCliCont,oArial10)//Contacto
		oPrint:Say( nRenIni+550,1900,cOrCoCnt,oArial10)//Orden compra cliente
		oPrint:Say( nRenIni+600,1900,cVendedor,oArial10)//Vendedor
		oPrint:Say( nRenIni+650,2000,cRespCap,oArial10)//Responsable captura

	ENDIF
		
	oPrint:Say( nRenIni+710,nColIni     , Replicate("_",250)     	,oLucCon10, 110)
	oPrint:Say( nRenIni+735,nColIni     , "Cantidad"             	,oArial10N, 110)
	oPrint:Say( nRenIni+735,nColIni+250 , "Clave"                	,oArial10N, 110)
	oPrint:Say( nRenIni+735,nColIni+600 , "D e s c r i p c i � n"	,oArial10N, 110) //Tiene que aparecer abajo de esta
	//oPrint:Say( nRenIni+730,nColIni+1630, "Alm"              		,oArial10N, 110)  
	oPrint:Say( nRenIni+735,nColIni+1800, "Precio Unitario"      	,oArial10N, 110)
	oPrint:Say( nRenIni+735,nColIni+2070, "UM"                   	,oArial10N, 110)
	oPrint:Say( nRenIni+735,nColIni+2250, "Importe"              	,oArial10N, 110)
	oPrint:Say( nRenIni+750,nColIni     , Replicate("_",250)     	,oLucCon10, 110)
Return                     

// FUNCION PARA IMPRESIOND DE PIE DE P�GINA 
Static Function PiePag() 
	Local cTotal

	/* IMPRIME Notas del Pedido, SUBTOTALES Y TOTALES */    
	oPrint:Say (nRenIni+2300+200,nColIni     ,Replicate("_",250)	,oLucCon10, 100 )
	oPrint:Say (nRenIni+2350+200,nColIni     ,"OBSERVACIONES: "  	,oArial10N, 100 )
	oPrint:Say (nRenIni+2350+200,nColIni+300 ,ALLTRIM(MV_PAR02) 	,oArial10N, 100 )   
	oPrint:Say (nRenIni+2400+200,nColIni+300 ,ALLTRIM(MV_PAR03) 	,oArial10N, 100 )
	oPrint:Say (nRenIni+2450+200,nColIni+300 ,ALLTRIM(MV_PAR04) 	,oArial10N, 100 )
	/*	                            
	oPrint:Say (nRenIni+2350+200,nColIni+1750,"Total:    " 		,oArial10N, 100)	
	oPrint:Say (nRenIni+2350+200,nColIni+2130,TRANSFORM(ENC->C5_VALBRUT,"999,999,999.9999")	,oLucCon10N, 100 )
	cTotal := Implet(ENC->C5_VALBRUT,ENC->C5_MOEDA)
	oPrint:Say( 2800,020,ALLTRIM(cTotal),oArial10N, 100)       
	*/
	oPrint:Say (nRenIni+2350+200,nColIni+1750,"Subtotal: " 	,oArial10N, 100)
	//oPrint:Say( nRenIni+2400+200,nColIni+1750,"Descuento:"  ,oArial10N, 100)
	oPrint:Say( nRenIni+2400+200,nColIni+1750,"IVA:      "  ,oArial10N, 100) 
	oPrint:Say( nRenIni+2450+200,nColIni+1750,"Total:    "  ,oArial10N, 100)
	
	nImp:=	Impuesto(mv_par01)
	
	oPrint:Say (nRenIni+2350+200,nColIni+2130,TRANSFORM(_Subtotal,"999,999,999.9999"),oLucCon10N,100)//Subtotal
	//oPrint:Say (nRenIni+2400+200,nColIni+2130,TRANSFORM(_nDesc   ,"999,999,999.9999"),oLucCon10N, 100 )
	//oPrint:Say (nRenIni+2400+200,nColIni+2130,TRANSFORM(_nIva ,"999,999,999.9999"),oLucCon10N, 100 )//IVA
	oPrint:Say (nRenIni+2400+200,nColIni+2130,TRANSFORM( nImp ,"999,999,999.9999"),oLucCon10N, 100 )//IVA
	oPrint:Say (nRenIni+2450+200,nColIni+2130,TRANSFORM(_Subtotal - _nDesc + nImp,"999,999,999.9999"),oLucCon10N, 100 )//Total
	
	cTotal := Implet(_Subtotal - _nDesc + _nIva,ENC->C5_MOEDA)
	
	oPrint:Say( 2800,020,ALLTRIM(cTotal),oArial10N, 100)       

Return

Static Function ImpLet(pTotal,pMoneda)                            
       If  pMoneda == 1
          _cSimbM := " $ "
          _cLin := Extenso(pTotal,.f.,1,,"2",.t.,.t.,.f.,"2")        
           cCentavos := Right(_cLin,9)
          _cLin := "("+Left(_cLin,Len(_cLin)-9)+cCentavos+")"
       else
           _cSimbM := " USD$ "
           _cLin := Extenso(pTotal,.f.,2,,"2",.t.,.t.,.f.,"2")
           cCentavos := Right(_cLin,8)
           _cLin :="("+ Left(_cLin,Len(_cLin)-8)+cCentavos + ")"
    EndIf                                   
Return(_cLin)  

// FUNCION DE AJUSTE DE PREGUNTAS
Static Function AjustaSX1()
	Local _sAlias := Alias()                              
	Local i := 0
	Local j:= 0
	dbSelectArea("SX1")
	dbSetOrder(1)
	
	cPerg := PADR("EFAT008R",10)
	aRegs:={} //G=Edit S=Texto C=Combo el siguiente parametro es para el Valid

	aAdd(aRegs,{cPerg,"01","�Cod. Pedido?  ","�Cod. Pedido?  ","�Cod. Pedido?  ","MV_CH1","C",06,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","SC5"}) 
	aAdd(aRegs,{cPerg,"02","Observaciones 1","Observaciones 1","Observaciones 1","MV_CH2","C",99,0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","",""}) 				
	aAdd(aRegs,{cPerg,"03","Observaciones 2","Observaciones 2","Observaciones 2","MV_CH3","C",99,0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","",""}) 						
	aAdd(aRegs,{cPerg,"04","Observaciones 3","Observaciones 3","Observaciones 3","MV_CH4","C",99,0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","",""}) 						
	aAdd(aRegs,{cPerg,"05","Facturar a 1   ","Facturar a 1   ","Facturar a 1   ","MV_CH5","C",99,0,0,"G","","MV_PAR05","","","","","","","","","","","","","","","","","","","","","","","","",""})		
	aAdd(aRegs,{cPerg,"06","Facturar a 2   ","Facturar a 2   ","Facturar a 2   ","MV_CH6","C",99,0,0,"G","","MV_PAR06","","","","","","","","","","","","","","","","","","","","","","","","",""})		
	aAdd(aRegs,{cPerg,"07","Facturar a 3   ","Facturar a 3   ","Facturar a 3   ","MV_CH7","C",99,0,0,"G","","MV_PAR07","","","","","","","","","","","","","","","","","","","","","","","","",""})		
	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next
	dbSelectArea(_sAlias)
Return

//RETORNA IMPUESTO
Static Function Impuesto(cNum)
	
	Local nImp	:=	0

	cQuery := " SELECT SUM (C6_VALOR* (FB_ALIQ/100)) AS IVA FROM "+InitSqlName("SC6") + " C6, "+InitSqlName("SFC") + " FC, "+InitSqlName("SFB") + " FB "  
 	cQuery += " WHERE	C6_NUM = '" + cNum + "' "
 	cQuery += " AND		C6_TES=FC_TES "
    cQuery += " AND		FC_IMPOSTO=FB_CODIGO "
    cQuery += " AND		C6.D_E_L_E_T_<>'*' "
    cQuery += " AND		FC.D_E_L_E_T_<>'*' "
    cQuery += " AND		FB.D_E_L_E_T_<>'*' "
    
    cSQL:= GetNextAlias()
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cSQL,.T.,.T.) 
    
    If (cSQL)->(eof())
    	nImp	:=	0
    Else 
    	nImp	:=	(cSQL)->IVA
    Endif
    (cSQL)->(dbCloseArea())  

Return(nImp)