#INCLUDE "Protheus.ch"
#INCLUDE "TopConn.ch"
#INCLUDE "RWMAKE.CH"
#INCLUDE "stdwin.ch"

#DEFINE IMP_PDF 1

/*--------------------------------------------------------------------------
		Rutina: 	EFAT002R
				ImpresiÛn de Factura ElectrÛnica CFDI
--------------------------------------------------------------------------  */

User Function EFAT002R()
	// Variables necesarias para la rutina
	Local iTamSer		:= TamSX3("F2_SERIE")[01] // Almacenar el tamaÒo de serie de la factura
	Local cSerie  	:= padr(alltrim(SUPERGETMV("GN_SEREDC",.T.,"EDC")),iTamSer) // Almacena la serie configurada para la factura
	
	Private aCores,aRotina,aIndices:={},cArq,cPerg
	Private cCadastro := "FacturaciÛn Electronica"
	Private cDelFunc  := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock
	Private cString   := "SF2"
	Private cMarca    := GETMARK(,"SF2","F2_OK")
	Private lInverte  := .F.
	
	Private cRutEje	:= "EFAT002R"
	
	cPerg := "EFAT002R"
	AjustaSx1()

	if ( IsInCallStack("LOJA701") )	// Agregado para imprimir directamente la factura cuando es generada desde Venta Asistida (LOJA701)
		U_NEFAT002A("I")
	else
		if ( !Pergunte(cPerg,.T.) )
			return
		endif

		aRotina := {	{"Buscar"				,  	'AxPesqui',			0,1},;
						{"Genera Archivo"		, 	'U_EFAT002A("A")',	0,3},;
						{"Imprimir"      		, 	'U_EFAT002A("I")',	0,3}}

//se elimina esta opcion del arreglo
//{"EnvÌo ElectrÛnico"	, 	'U_EFAT002A("E")',	0,3},;
						
		If mv_par08 == 1 //Si es Factura de Salida

			dbSelectArea("SF2")
			dbSetOrder(1)

			cFiltroSF2 := ''

			cFiltroSF2 := "F2_FILIAL = '"+xFilial('SF2')+"' .AND. DTOS(F2_EMISSAO) >= '"+DTOS(MV_PAR01)+"' .And. DTOS(F2_EMISSAO) <= '"+DTOS(MV_PAR02)+"' "
			cFiltroSF2 += " .AND. F2_SERIE >= '" + mv_par03 + "' .AND. F2_SERIE <='" + mv_par04 + "' "
			cFiltroSF2 += " .AND. F2_SERIE <> '" + cSerie + "'"
			cFiltroSF2 += " .AND. F2_DOC   >= '" + mv_par05 + "' .AND. F2_DOC   <='" + mv_par06 + "' "
			cFiltroSF2 += " .AND. F2_APROFOL <> '' .AND. F2_CERTFOL <>'' "

			If  mv_par07 == 1 //factura
				cFiltroSF2 += " .AND. ALLTRIM(F2_ESPECIE)= 'NF' "
			ElseIf mv_par07 == 2 //credito
				cFiltroSF2 += " .AND. ALLTRIM(F2_ESPECIE)= 'NCC' "
			EndIf

			bFiltraBrw	:=	{|| FilBrowse("SF2",@aIndices,cFiltroSF2)}
			Eval( bFiltraBrw )
			MarkBrow("SF2","F2_OK",,,.F.,GetMark(,"SF2","F2_OK"))
			EndFilBrw("SF2",@aIndices)

		Else //Si es factura de entrada
			dbSelectArea("SF1")
			dbSetOrder(1)

			cFiltroSF1 := ''

			cFiltroSF1 := "F1_FILIAL = '"+xFilial('SF1')+"' .AND. DTOS(F1_EMISSAO) >= '"+DTOS(MV_PAR01)+"' .And. DTOS(F1_EMISSAO) <= '"+DTOS(MV_PAR02)+"' "
			cFiltroSF1 += " .AND. F1_SERIE >= '" + mv_par03 + "' .AND. F1_SERIE <='" + mv_par04 + "' "
			cFiltroSF1 += " .AND. F1_DOC   >= '" + mv_par05 + "' .AND. F1_DOC   <='" + mv_par06 + "' "
			cFiltroSF1 += " .AND. F1_APROFOL <> '' .AND. F1_CERTFOL <>'' "

			If  mv_par07 == 1 // factura
				cFiltroSF1 += " .AND. ALLTRIM(F1_ESPECIE)= 'NF' "
			ElseIf mv_par07 == 2 // debito
				cFiltroSF1 += " .AND. ALLTRIM(F1_ESPECIE)= 'NCC' "
			EndIf

			bFiltraBrw	:=	{|| FilBrowse("SF1",@aIndices,cFiltroSF1)}
			Eval( bFiltraBrw )
			MarkBrow("SF1","F1_OK",,,.F.,GetMark(,"SF1","F1_OK"))
			EndFilBrw("SF1",@aIndices)
		EndIf

		If Select("TMP") > 0; dbSelectArea("TMP") ; dbCloseArea() ; EndIf

    endif
Return
/* 	--------------------------------------------------------------------------
		FunciÛn: 	EFAT002A
					Nota Fiscal de salida
		Par·metros: - cTP: Tipo de operaciÛn, (A)rchivo, (E)mail, (I)mprimir
	-------------------------------------------------------------------------- */
User Function EFAT002A(cTP)
	Local   nRegAtu    	:= Recno()
	Local 	 aIndicesT		:=	{}
	
	Private cTpOper    	:= cTp
	Private cSER       	:= ""
	Private cDOC       	:= ""
	Private cCTE       	:= ""
	Private cLOJA      	:= ""
	Private cEspecie		:= ""
	Private cFilName		:= ""
	PRIVATE nTipoCambio 	:= 1.0
	Private cTimbre     	:= " "

	Private cSerie    	:= ""
	Private cDoc      	:= ""
	Private nMoneda    	:= "Pesos"
	Private cObservaciones		:= ""


	if cRutEje	== "EFAT030P"
	
    	MV_PAR01	:= dDataBase - 3
		MV_PAR02	:= dDataBase
		MV_PAR03	:= ParamIxb[2]
		MV_PAR04	:= ParamIxb[2]
		MV_PAR05	:= ParamIxb[1]
		MV_PAR06	:= ParamIxb[1]
		
		if alltrim(paramixb[3]) == "NF"
			MV_PAR07	:= 1
			MV_PAR08	:= 1
		elseif alltrim(paramixb[3]) == "NCC"
			MV_PAR07	:= 2
			MV_PAR08	:= 2
		endif

		cFilFac := 0
		
		If mv_par08 == 1 //Si es Factura de Salida

			dbSelectArea("SF2")
			dbSetOrder(1)

			DbSeek( xFilial("SF2") + ParamIxb[1] + ParamIxb[2] ) // B˙squeda exacta
			IF Found() // Eval˙a la devoluciÛn del ˙ltimo DbSeek realizado
				
				if (SF2->F2_MOEDA = 1)
					nMoneda := "Pesos"
				else
					nMoneda := "Dolares"
				endif
				cSER       	:= SF2->F2_SERIE
				cDOC       	:= SF2->F2_DOC
				cCTE       	:= SF2->F2_CLIENTE
				cLOJA      	:= SF2->F2_LOJA
				cEspecie   	:= SF2->F2_ESPECIE
				nTipoCambio	:= SF2->F2_TXMOEDA
				cTimbre    	:= SF2->F2_TIMBRE
				cVendedor		:= UPPER(POSICIONE("SA3", 1, XFILIAL("SA3") + SF2->F2_VEND1, 'SA3->A3_NOME'))
				if cTpOper == "E"
					cFilName 	:= Lower(AllTrim(SF2->F2_ESPECIE)) + '_' + Lower(AllTrim(SF2->F2_SERIE)) + '_' + Lower(AllTrim(SF2->F2_DOC))
					Processa({ |lEnd| FATR01IM7("TransmisiÛn del correo electrÛnico")},"Efectuando la transmisiÛn, aguarde...")
				endif			
			endif

		Else //Si es factura de entrada
			dbSelectArea("SF1")
			dbSetOrder(1)

			DbSeek( xFilial("SF1") + ParamIxb[1] + ParamIxb[2] ) // B˙squeda exacta
			IF Found() // Eval˙a la devoluciÛn del ˙ltimo DbSeek realizado
			
				if (SF1->F1_MOEDA = 1)
					nMoneda := "Pesos"
				else
					nMoneda := "Dolares"
				endif
				cSER       	:= SF1->F1_SERIE
				cDOC       	:= SF1->F1_DOC
				cCTE       	:= SF1->F1_FORNECE
				cLOJA      	:= SF1->F1_LOJA
				cEspecie   	:= SF1->F1_ESPECIE
				nTipoCambio	:= SF1->F1_TXMOEDA
			   	cTimbre    	:= SF1->F1_TIMBRE
			   	cVendedor		:= UPPER(POSICIONE("SA3", 1, XFILIAL("SA3") + SF1->F1_VEND1, 'SA3->A3_NOME'))
				if ( cTpOper == "E" )
					cFilName 	:= Lower(AllTrim(SF1->F1_ESPECIE)) + '_' + Lower(AllTrim(SF1->F1_SERIE)) + '_' + Lower(AllTrim(SF1->F1_DOC))
				Processa({ |lEnd| FATR01IM7("TransmisiÛn del correo electrÛnico")},"Efectuando la transmisiÛn, aguarde...")
				endif
			endif
		EndIf
	elseif cRutEje == "EFAT002R"
		dbGoTop()
		While !Eof()
			if ( mv_par08 == 1 )
				if ( Marked("F2_OK") )

					if (SF2->F2_MOEDA = 1)
						nMoneda := "Pesos"
					else
						nMoneda := "Dolares"
					endif
					cSER       	:= SF2->F2_SERIE
					cDOC       	:= SF2->F2_DOC
					cCTE       	:= SF2->F2_CLIENTE
					cLOJA      	:= SF2->F2_LOJA
					cEspecie   	:= SF2->F2_ESPECIE
					nTipoCambio	:= SF2->F2_TXMOEDA
					cTimbre    	:= SF2->F2_TIMBRE
					cVendedor		:= UPPER(POSICIONE("SA3", 1, XFILIAL("SA3") + SF2->F2_VEND1, 'SA3->A3_NOME'))
					if ( cTpOper == "A" )
						cFilName 	:= Lower(AllTrim(SF2->F2_ESPECIE)) + '_' + Lower(AllTrim(SF2->F2_SERIE)) + '_' + Lower(AllTrim(SF2->F2_DOC))
						Processa({ |lEnd| FATR01IM7("GeneraciÛn de Archivos de FacturaciÛn ElectrÛnica")},"Generando archivos , aguarde...")
					elseif cTpOper == "E"
						cFilName 	:= Lower(AllTrim(SF2->F2_ESPECIE)) + '_' + Lower(AllTrim(SF2->F2_SERIE)) + '_' + Lower(AllTrim(SF2->F2_DOC))
						Processa({ |lEnd| FATR01IM7("TransmisiÛn del correo electrÛnico")},"Efectuando la transmisiÛn, aguarde...")
					else
					  	cFilName 	:= Lower(AllTrim(SF2->F2_ESPECIE)) + '_' + Lower(AllTrim(SF2->F2_SERIE)) + '_' + Lower(AllTrim(SF2->F2_DOC))
						Processa({ |lEnd| FATR01IM7("EmisiÛn del informe")},"Efectuando la emisiÛn, aguarde...")
					endif
				endif
				dbSelectArea("SF2")
				dbSkip()
			else
				if ( Marked("F1_OK") )
					if (SF1->F1_MOEDA = 1)
						nMoneda := "Pesos"
					else
						nMoneda := "Dolares"
					endif
					cSER       	:= SF1->F1_SERIE
					cDOC       	:= SF1->F1_DOC
					cCTE       	:= SF1->F1_FORNECE
					cLOJA      	:= SF1->F1_LOJA
					cEspecie   	:= SF1->F1_ESPECIE
					nTipoCambio	:= SF1->F1_TXMOEDA
		        	cTimbre    	:= SF1->F1_TIMBRE
		        	cVendedor		:= UPPER(POSICIONE("SA3", 1, XFILIAL("SA3") + SF1->F1_VEND1, 'SA3->A3_NOME'))
					if ( cTpOper == "A" )
					  	cFilName 	:= Lower(AllTrim(SF1->F1_ESPECIE)) + '_' + Lower(AllTrim(SF1->F1_SERIE)) + '_' + Lower(AllTrim(SF1->F1_DOC))
						Processa({ |lEnd| FATR01IM7("GeneraciÛn de Archivos de FacturaciÛn ElectrÛnica")},"Generando archivos , aguarde...")
					elseif ( cTpOper == "E" )
						cFilName 	:= Lower(AllTrim(SF1->F1_ESPECIE)) + '_' + Lower(AllTrim(SF1->F1_SERIE)) + '_' + Lower(AllTrim(SF1->F1_DOC))
						Processa({ |lEnd| FATR01IM7("TransmisiÛn del correo electrÛnico")},"Efectuando la transmisiÛn, aguarde...")
					else
						cFilName 	:= Lower(AllTrim(SF1->F1_ESPECIE)) + '_' + Lower(AllTrim(SF1->F1_SERIE)) + '_' + Lower(AllTrim(SF1->F1_DOC))
						Processa({ |lEnd| FATR01IM7("EmisiÛn del informe")},"Efectuando la emisiÛn, aguarde...")
					endif
				endif
				dbSelectArea("SF1")
				dbSkip()
			endif
		enddo
	endif
Return
/* 	--------------------------------------------------------------------------
		FunciÛn: 	FATR01IM7
					Gestiona las operaciones de generaciÛn, impresiÛn y envÌo
					de las facturas electrÛnicas
	-------------------------------------------------------------------------- */
Static Function FATR01IM7()
	Local i 	 		:= 	1
	Local nIxb	 		:= 	0
	Local oXml			:=	Nil
	Local cRuta		:=	""
	Local cMensaje	:=	""
	Local cBodyMsg	:=	""

	Private oPrint	:= 	NIL
	Private nLin    	:= 	500
	Private nSalto  	:= 	60
	Private cMail2  	:= 	""
	Private cMail3  	:=  ""
	Private cPDFCfd	:=  GetSrvProfString("Startpath","") + "cfd\pdf\"

	Titulo			:= 	PADC("Factura",74)
	nomeprog  		:= 	"ACFATM05"
	wnrel     		:= 	"ACFATM05"
	lEnd      		:= 	.F.

	If ( cTpOper == "I" ) .OR. ( cTpOper == "A" )
		oPrint		:= FWMsPrinter():New(ALLTRIM(cFilName)+".PDF",6,.T.,,.T.,,,,,,,.T.,)
	ElseIf ( cTpOper == "E" )
		oPrint		:= FWMsPrinter():New(ALLTRIM(cFilName)+".PDF",6,.T.,,.T.,,,,,,,.F.,)
	EndIF
	oPrint:SetResolution()
	oPrint:SetPortrait()
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:cPathPDF:= "C:\SPOOL\"

	oXml 	:= 	GetXML()
	if ( oXml == Nil )
		FreeObj(oPrint)
		return(.F.)
	endif

	Imprime(oXml)
	nLin			:=	0
	
	// Elimina el PDF anterior
	ferase(oPrint:cPathPDF + ALLTRIM(cFilName)+".PDF")
	
	oPrint:Print()
	
	// Copia el PDF final para la carpeta del servidor
	COPY FILE (oPrint:cPathPDF + ALLTRIM(cFilName)+".PDF") TO (cPDFCfd + ALLTRIM(cFilName)+".PDF")  

	FreeObj(oPrint)

	if (mv_par08 == 1)
		cRelto 	:= Alltrim(Posicione("SA1",1,xFilial("SA1")+cCTE + cLOJA, "A1_EMAIL"))		// Trae correo electrÛnico de SA1
		cNomeTo	:= Alltrim(Posicione("SA1",1,xFilial("SA1")+cCTE + cLOJA, "A1_NOME"))		
		//Se agrega en el caso de no existir correo
		cRelTo := Padr(cRelTo,200)
		cMensaje := cNomeTo + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Estimado(a):" + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Por este medio le estamos enviando su Comprobante Fiscal Digital, correspondiente al documento: " + cDOC + ", serie:" + cSER + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Adjunto a este correo electrÛnico, le estamos enviando un archivo con extensiÛn XML el cual es su factura electrÛnica conforme a la normatividad del SAT. " + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Adicionalmente, le estamos enviando un archivo con extensiÛn PDF el cual es una versiÛn legible del archivo XML. " + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Dicho archivo lo puede ud. imprimir cuantas veces lo requiera. " + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Favor de revisar sus datos, si tiene alguna correcciÛn hacerla dentro de los siguientes 30 dÌas " + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Gracias por su compra. " + CHR(13) + CHR(10)

		cBodyMsg := "<html>"
		cBodyMsg += "<head></head>"
		cBodyMsg += "<body>"
		cBodyMsg += "<div>"
		cBodyMsg += "<p><span>"+cNomeTo+"<o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Estimado(a): <o:p></o:p></span></p>"
		cBodyMsg += "<p>Por este medio le estamos enviando su Comprobante Fiscal Digital, correspondiente al documento: " + cDOC + ", serie:" + cSER +" <o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Adjunto a este correo electr&oacute;nico, le estamos enviando un archivo con extensi&oacute;n XML el cual es su factura electr&oacute;nica conforme a la normatividad del SAT. <o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Adicionalmente, le estamos enviando un archivo con extensi&oacute;n PDF el cual es una versi&oacute;n legible del archivo XML. <o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Dicho archivo lo puede ud. imprimir cuantas veces lo requiera. <o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Favor de revisar sus datos, si tiene alguna correcci&oacute;n hacerla dentro de los siguientes 30 d&iacute;as <o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Gracias por su compra.<o:p></o:p></span></p>"
		cBodyMsg += "</div>"
		cBodyMsg += "</body>"
		cBodyMsg += "</html>"
	else
		cRelto 	:= Alltrim(Posicione("SA1",1,xFilial("SA1")+cCTE + cLOJA, "A1_EMAIL"))
		cNomeTo	:= Alltrim(Posicione("SA1",1,xFilial("SA1")+cCTE + cLOJA, "A1_NOME"))		
		
		cRelTo := Padr(cRelTo,200)

		cMensaje := cNomeTo + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Estimado(a):" + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Por este medio le estamos enviando su Comprobante Fiscal Digital, correspondiente al documento: " + cDOC + ", serie:" + cSER + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Adjunto a este correo electrÛnico, le estamos enviando un archivo con extensiÛn XML el cual es su factura electrÛnica conforme a la normatividad del SAT. " + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Adicionalmente, le estamos enviando un archivo con extensiÛn PDF el cual es una versiÛn legible del archivo XML. " + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Dicho archivo lo puede ud. imprimir cuantas veces lo requiera. " + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += "Favor de revisar sus datos, si tiene alguna correcciÛn hacerla dentro de los siguientes 30 dÌas " + CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)
		cMensaje += CHR(13) + CHR(10)

		cBodyMsg := "<html>"
		cBodyMsg += "<head></head>"
		cBodyMsg += "<body>"
		cBodyMsg += "<div>"
		cBodyMsg += "<p><span>"+cNomeTo+"<o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Estimado(a): <o:p></o:p></span></p>"
		cBodyMsg += "<p>Por este medio le estamos enviando su Comprobante Fiscal Digital, correspondiente al documento: " + cDOC + ", serie:" + cSER +" <o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Adjunto a este correo electr&oacute;nico, le estamos enviando un archivo con extensi&oacute;n XML el cual es su factura electr&oacute;nica conforme a la normatividad del SAT. <o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Adicionalmente, le estamos enviando un archivo con extensi&oacute;n PDF el cual es una versi&oacute;n legible del archivo XML. <o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Dicho archivo lo puede ud. imprimir cuantas veces lo requiera. <o:p></o:p></span></p>"
		cBodyMsg += "<p><span>Favor de revisar sus datos, si tiene alguna correcci&oacute;n hacerla dentro de los siguientes 30 d&iacute;as <o:p></o:p></span></p>"
		//cBodyMsg += "<p><span>Gracias por su compra.<o:p></o:p></span></p>"
		cBodyMsg += "</div>"
		cBodyMsg += "</body>"
		cBodyMsg += "</html>"

	endif

	if ( cTpOper == "E" )       								// EnvÌo por correo electrÛnico.
		//if ( MsgYesNo("øContinuar con el envÌo del Comprobante Fiscal Digital por correo electrÛnico?") )
			cCaminhoXML := &(GetMv("MV_CFDDOCS"))
			aAttach 	:= {}
			cRelFrom 	:= "facturacion@gasngo.com.mx"

			AAdd(aAttach, cPDFCfd+cFilName+".PDF")
			AAdd(aAttach, cCaminhoXML + cFilName + '.xml')

			aAtcBkp := AClone(aAttach)

			if ( MBSendMail(GetMV("MV_RELACNT"),GetMV("MV_RELPSW"),GetMV("MV_RELSERV"),cRelFrom,cRelTo,"Envio de documento CFDI:  " + cFilName,cMensaje,cBodyMsg,aAttach) )
				ApMsgInfo("°CFDI enviado correctamente!", "EnvÌo de CFDI")
			else
				ApMsgStop("°No se realizÛ el envÌo de archivos digitales!","EnvÌo de CFDI")
			endif
		//endif
	endif
	//FreeObj(oPrint)
Return(.T.)

/* 	--------------------------------------------------------------------------
		FunciÛn: 	GetXML
					Realiza la lectura del archivo XML del documento y lo
					devuelve como un objeto.
		Retorno:
			oXML: 	Objeto con el contenido del archivo XML leÌdo para el
					documento.
	-------------------------------------------------------------------------- */
Static Function GetXML()
	Local cCaminhoXML	:= &(GetMv("MV_CFDDOCS"))
	Local oXML			:= Nil
	Local cAviso		:= ""
	Local cErro		:= ""
	Local cRuta		:= ""

	if (mv_par08 == 1)
		cRuta := cCaminhoXML + Lower(AllTrim(SF2->F2_ESPECIE)) + '_' + Lower(AllTrim(SF2->F2_SERIE)) + '_' + Lower(AllTrim(SF2->F2_DOC)) + '.xml'
	else
		cRuta := cCaminhoXML + Lower(AllTrim(SF1->F1_ESPECIE)) + '_' + Lower(AllTrim(SF1->F1_SERIE)) + '_' + Lower(AllTrim(SF1->F1_DOC)) + '.xml'
	endif

	if ( !File(cRuta) )
		MsgAlert("El archivo XML del documento: "+SF2->F2_SERIE+"-"+SF2->F2_DOC+" no fuÈ localizado. No ser· posible realizar la impresiÛn del mismo.")
		return(Nil)
	endif
	oXML := XmlParserFile(cRuta, "_", @cAviso,@cErro )

	if ( !Empty(cAviso) .or. !Empty(cErro) )
		MsgAlert("Se detectaron problemas con el archivo XML: " +Chr(13)+Chr(10)+Upper(cAviso)+Chr(13)+Chr(10)+Upper(cErro))
		return(Nil)
	endif
Return(oXML)
/* 	--------------------------------------------------------------------------
		FunciÛn: 	Imprime
					Realiza la impresiÛn del formato de la factura o nota.
		Par·metros:
			oXML: 	Objeto con el contenido del archivo XML leÌdo para el
					documento.
	-------------------------------------------------------------------------- */
Static Function Imprime(oXML)
	Local cBitMap	:= "FACTURA.BMP" // Bitmap com a MOLDURA do tipo da NF
	Local i		:= 0
	Local nLoop	:= 0

	// Coordenadas
	Private nPagLim	:= 3200	// Indica el lÌmite vertical de la p·gina para considerar EN LA P¡GINAciÛn del formato.
	Private nPagNum	:= 1		// Indica el n˙mero de p·gina actual.
	Private cDescItems  	:= 0
	Private cRetItems		:= 0
	Private nEmiX	:= 330		// Coordenadas de columna en donde inician datos del emisor
	Private nEmiY := 130		// Coordenadas de lÌnea en donde inician los datos del emisor
	Private nFacX	:= 1650   	// Columna de inicio de datos de factura en encabezado
	Private nFacY	:= 50		// LÌnea de inicio de datos de factura en enabezado
	Private nCliX	:= 120		// Columna de inicio de datos del cliente en encabezado
	Private nCliY	:= 458		// LÌnea de inicio de datos del cliente en encabezado
	Private nCdvX	:= 120   	// Columna de inicio de datos de Condiciones de venta
	Private nCdvY	:= 845		// LÌnea de inicio de datos de Condiciones de venta
	Private nDetX	:= 120 	// Columna de inicio de datos del detalle de la factura
	Private nDetY	:= 690		// LÌnea de inicio de datos del detalle de la factura. Se cambia, era 1000
	Private nFotX	:= 120		// Columna en donde comienza la impresiÛn del pie del reporte.
	Private nFotY	:= 0		// LÌnea en donde comienza la impresiÛn del pie del reporte.
	Private jmp	:= 40		// TamaÒo del salto

	// Fuentes
	Private oFont08		:= TFont():New("Courier New",08,08,,.F.,,,,.T.,.F.)
	Private oCouNew06		:= TFont():New("Courier New",06,06,,.F.,,,,.T.,.F.)
	Private oCouNew07N	:= TFont():New("Courier New",07,07,,.T.,,,,.T.,.F.)
	Private oCouNew08		:= TFont():New("Courier New",08,08,,.F.,,,,.T.,.F.)
	Private oCouNew08N	:= TFont():New("Courier New",08,08,,.T.,,,,.T.,.F.)
	Private oCouNew09		:= TFont():New("Courier New",09,09,,.F.,,,,.T.,.F.)
	Private oCouNew09N	:= TFont():New("Courier New",09,09,,.T.,,,,.T.,.F.)
	Private oCouNew10		:= TFont():New("Courier New",11,11,,.F.,,,,.T.,.F.)
	//Private oCouNew10		:= TFont():New("Arial",10,10,,.F.,,,,.T.,.F.) 
	//Private oCouNew10		:= TFont():New("Calibri",10,10,,.F.,,,,.T.,.F.) 
	//Private oCouNew10		:= TFont():New("Arial black",10,10,,.F.,,,,.T.,.F.) 
	Private oCouNew10N	:= TFont():New("Courier New",10,10,,.T.,,,,.T.,.F.)
	Private oCouNew11		:= TFont():New("Courier New",11,11,,.F.,,,,.T.,.F.)
	Private oCouNew11N	:= TFont():New("Courier New",11,11,,.T.,,,,.T.,.F.)

	Private oArial06  	:= TFont():New("Arial",06,06,,.F.,,,,.T.,.F.)
	Private oArial08  	:= TFont():New("Arial",08,08,,.F.,,,,.T.,.F.)
	Private oArial08N		:= TFont():New("Arial",08,08,,.T.,,,,.T.,.F.)
	Private oArial09  	:= TFont():New("Arial",09,09,,.F.,,,,.T.,.F.)
	Private oArial09N	:= TFont():New("Arial",09,09,,.T.,,,,.T.,.F.)
	Private oArial10  	:= TFont():New("Arial",10,10,,.F.,,,,.T.,.F.)
	Private oArial10N		:= TFont():New("Arial",10,10,,.T.,,,,.T.,.F.)
	Private oArial11 		:= TFont():New("Arial",11,11,,.F.,,,,.T.,.F.)
	Private oArial11N		:= TFont():New("Arial",11,11,,.T.,,,,.F.,.F.)
	Private oArial12 		:= TFont():New("Arial",12,12,,.F.,,,,.T.,.F.)
	Private oArial12N		:= TFont():New("Arial",12,12,,.T.,,,,.F.,.F.)
	Private oArial13 		:= TFont():New("Arial",13,13,,.F.,,,,.T.,.F.)
	Private oArial13N		:= TFont():New("Arial",13,13,,.T.,,,,.F.,.F.)
	Private oArial14		:= TFont():New("Arial",14,14,,.F.,,,,.F.,.F.)
	Private oArial14N		:= TFont():New("Arial",14,14,,.T.,,,,.F.,.F.)		   	// Negrito
	Private oArial16		:= TFont():New("Arial",16,16,,.F.,,,,.F.,.F.)
	Private oArial16N		:= TFont():New("Arial",16,16,,.T.,,,,.F.,.F.)		   	// Negrito
	Private oArial18N		:= TFont():New("Arial",18,18,,.T.,,,,.F.,.F.)		   	// Negrito
	Private oArial20N		:= TFont():New("Arial",20,20,,.T.,,,,.F.,.F.)		   	// Negrito
	Private oArial22N		:= TFont():New("Arial",22,22,,.T.,,,,.F.,.F.)		  	// Negrito
	Private oArialB23N	:= TFont():New("Arial black",23,23,,.T.,,,,.F.,.F.)	// Negrito
	Private oArialB24N	:= TFont():New("Arial black",24,24,,.T.,,,,.F.,.F.)	// Negrito
	Private oCal16b		:= TFont():New("Calibri",16,16,,.T.,,,,.F.,.F.)
	Private oCal14b		:= TFont():New("Calibri",14,14,,.T.,,,,.F.,.F.)
	Private oCal14		:= TFont():New("Calibri",14,14,,.F.,,,,.F.,.F.)
	Private oCal12b		:= TFont():New("Calibri",11,11,,.T.,,,,.F.,.F.)		//cambio de 12 a 11      negrito
	Private oCal12		:= TFont():New("Calibri",12,12,,.F.,,,,.F.,.F.)
	Private oCal10		:= TFont():New("Calibri",10,10,,.F.,,,,.F.,.F.)
	Private oCal08		:= TFont():New("Calibri",08,08,,.F.,,,,.F.,.F.)
	Private oCal10b		:= TFont():New("Calibri",10,10,,.T.,,,,.F.,.F.)

	Private oBrush		:= TBrush():New(,CLR_BLUE)
	Private oBrushGray	:= TBrush():New(,9382400)       // Buscar en http://cloford.com/resources/colours/500col.htm
	Private oBrushLGren	:= TBrush():New(,4231485)
	Private oBrushWhite	:= TBrush():New(,16777215)
	Private oBrushLRed	:= TBrush():New(,255)

    Private nDifLBox	:= 4
    Private nDifLTxt	:= 30

	oPrint:StartPage() 														// Inicia nueva p·gina
	PrtHeader(oXML)               										  	// Imprimir encabezado
	nFotY := ImpDet(oXML)				 						   			// Imprimir el detalle de la factura
	PrtFooter(oXML)													   		// Imprimir pie de p·gina
	oPrint:EndPage()
Return .T.
/* 	--------------------------------------------------------------------------
		FunciÛn: 	PrtHeader
					Imprime la secciÛn de encabezado del documento.
		Par·metros:
			oXML: 	Objeto con el contenido del archivo XML leÌdo para el
					documento.
	-------------------------------------------------------------------------- */
Static Function PrtHeader(oXML)
	Local cFileLogoR	:=  GetSrvProfString("Startpath","") + "transconsult.png"   		// Logo seg˙n filial en caso de requerirse
	Local cFileRFC	:=  GetSrvProfString("Startpath","") + "RFC_transconsult.png"   		// Logo seg˙n filial en caso de requerirse
	
	//DOMICILIO FISCAL EMISOR
	Local cEmisor	   	:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_cfdi_EMISOR:_NOMBRE:TEXT)
	Local cRfc			:= OemToAnsi("R.F.C.: "+oXML:_cfdi_COMPROBANTE:_cfdi_EMISOR:_RFC:TEXT)
	Local cCalle		:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_cfdi_EMISOR:_cfdi_DOMICILIOFISCAL:_CALLE:TEXT)
	Local cMunic		:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_cfdi_EMISOR:_cfdi_DOMICILIOFISCAL:_MUNICIPIO:TEXT)
	Local cEstado		:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_cfdi_EMISOR:_cfdi_DOMICILIOFISCAL:_ESTADO:TEXT)
	Local cPais		:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_cfdi_EMISOR:_cfdi_DOMICILIOFISCAL:_PAIS:TEXT)
	//DATOS DE LA FACTURA
	Local cCert		:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_NOCERTIFICADO:TEXT)
	Local cCertSAT	:= " "
	Local cFolioFis	:= " "
	Local cFechaTimbre	:= " "
	Local cFECHAXml		:= oXML:_cfdi_COMPROBANTE:_FECHA:TEXT
	Local cFECHAFac		:= SubStr(cFECHAXml,9,2)+"/"+SubStr(cFECHAXml,6,2)+"/"+SubStr(cFECHAXml,1,4)+" "+SubStr(cFECHAXml,12,8)
	Local cForPag			:= AllTrim(oXML:_cfdi_COMPROBANTE:_FORMADEPAGO:TEXT)
	//DATOS  DEL CLIENTE
	Local cNumClie	:= ""
	Local cCliNom		:= oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_NOMBRE:TEXT
	Local cCliRfc		:= AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_RFC:TEXT)
	Local cCliCalle	:= OemToAnsi(AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_CALLE:TEXT))
	Local cCliNumExt	:= ""//AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_NOEXTERIOR:TEXT)
	Local cCliNumInt	:= ""
	Local cCliMun		:= AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_MUNICIPIO:TEXT)
	Local cCliEst		:= AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_ESTADO:TEXT)
	Local cCliPais	:= AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_PAIS:TEXT)
	Local cCliCp		:= AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_CODIGOPOSTAL:TEXT)

	Local cEntNombr	:= ""
	Local cEntRFC		:= ""
	Local cEntCalle	:= ""
	Local cEntNumExt	:= ""
	Local cEntNumInt	:= ""
	Local centMun		:= ""
	Local cEntEst		:= ""
	Local centPais	:= ""
	Local cEntCp		:= ""

	//DATOS DE LA SUCURSAL-> LUGAR DE EMISION
	Local cCondP		:= ALLTRIM(SF2->F2_COND)
	Local cEmaiC		:= ""//ALLTRIM(SA1->A1_EMAIL)
	Local cTelC	   	:= ALLTRIM(SA1->A1_EMAIL)
	Local cCliEnt		:= ""
	Local cLojEnt		:= ""

	Local cOCCliente	:= ""
	Local hdrHeight	:= 0
	local lcampos    	:= .T.

	PRIVATE cSerie	:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_SERIE:TEXT)
	PRIVATE cFolio 	:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_FOLIO:TEXT)
	PUBLIC cPedido	:= ""
	PUBLIC cDocRem	:= ""
	PUBLIC cSerRem	:= ""

	if (nPagNum == 1)
		dbSelectArea("SD2")
		dbSetOrder(3)
		dbSeek(xFilial("SD2") + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA)
		dbSelectArea("SC5")
		dbSetOrder(1)
		dbSeek(xFilial("SC5") + SD2->D2_PEDIDO)
		dbSelectArea("SC6")
		dbSetOrder(1)
		dbSeek(xFilial("SC6") + SD2->D2_PEDIDO)
		dbSelectArea("SA3")
		dbSetOrder(1)
		dbSeek(xFilial("SA3") + SF2->F2_VEND1)
		dbSelectArea("SL1")
	   	dbSetOrder(2)
		dbSeek(xFilial("SL1") + SF2->F2_SERIE + SF2->F2_DOC)
	endif
    if !empty(ctimbre)
       cCertSAT	   	:= AllTrim(oXML:_cfdi_comprobante:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_noCertificadoSAT:TEXT)
       cFolioFis	   	:= AllTrim(oXML:_cfdi_comprobante:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_UUID:TEXT)
       cFechaTimbre	:= AllTrim(oXML:_cfdi_comprobante:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_FechaTimbrado:TEXT)
    endif

	cCliEnt := (SC5->C5_CLIENT)
	cLojEnt := (SC5->C5_LOJAENT)
	/*
	if Alltrim(SC5->C5_CLIENTE) <> Alltrim(SC5->C5_CLIENT)
		cCliEnt := Alltrim(SC5->C5_CLIENT)
	else
		cCliEnt := alLtrim(SF2->F2_CLIENTE)
	endif
	*/
	cPedido := ALLTRIM(SD2->D2_PEDIDO)
	//Pendiente Orden de compra del cliente
	//cOCCliente := alltrim(SC5->C5_OCCLIEN )

	/* FPB Adecuacion para buscar el pedido de la remision de la factura */
	IF EMPTY(cPedido)
		cQuery := " SELECT * "
		cQuery += " FROM " + InitSqlName("SD2")+" SD2 "
		cQuery += " WHERE SD2.D2_SERIE  = '" + SD2->D2_SERIREM + "'"
		cQuery += "   AND SD2.D2_DOC    = '" + SD2->D2_REMITO + "'"
		cQuery += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
		cQuery += "   AND SD2.D_E_L_E_T_ = ' '"
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"REM",.T.,.T.)
		If REM->(!eof())
			Do while !eof()
				cDocRem 	:= REM->D2_DOC
			    cSerRem  	:= REM->D2_SERIE
			    cPedido 	:= REM->D2_PEDIDO
			    REM->(Dbskip())
		    END
        EndIf
        REM->(Dbclosearea())

		IF !EMPTY(cDocRem) .AND. !EMPTY(cSerRem)
			cQuery := " SELECT * "
			cQuery += " FROM " + InitSqlName("SC5")+" SC5 "
			cQuery += "   WHERE SC5.C5_NUM  = '" + cPedido + "'"
			cQuery += "   AND SC5.C5_FILIAL = '" + xFilial("SC5") + "'"
			cQuery += "   AND SC5.D_E_L_E_T_ = ' '"
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"PED",.T.,.T.)
			If PED->(!eof())
				Do while !eof()
					cPedido 	:= PED->C5_NUM
					cOCCliente 	:= alltrim(PED->C5_OCCLIEN )
					cCliEnt		:= PED->C5_CLIENT
					cLojEnt		:= PED->C5_LOJAENT
					PED->(Dbskip())
				END
	        EndIf
	        PED->(Dbclosearea())
		ENDIF
	ENDIF
    // FPB Si el cliente de entrega sigue en blanco se asigana el mismo cliente de entrega
	if empty(cCliEnt)
		if  ( mv_par07 == 1 ) // Factura
			cCliEnt		:= SF2->F2_CLIENTE
			cLojEnt		:= SF2->F2_LOJA
		elseif ( mv_par07 == 2 ) // Nota de Credito
			cCliEnt		:= SF1->F1_FORNECE
			cLojEnt		:= SF1->F1_LOJA
		endif
	endif

	if  ( mv_par07 == 1 ) 					// Factura
		cObservaciones := Alltrim(SF2->F2_OBS)
	elseif ( mv_par07 == 2 ) 				// CREDITO
		cObservaciones := Alltrim(SF1->F1_OBS)
	endif

	IF EMPTY(cObservaciones)
		//Pendiente Observaciones del pedido de venta
		//cObservaciones := Alltrim(SC5->C5_OBS)
	ENDIF

	cNumClie		:= ALLTRIM(SF2->F2_CLIENTE)

	dbSelectArea("SA1")
	dbSetOrder(1)

  	if dbSeek(xFilial("SA1") + SF2->F2_CLIENTE+ SF2->F2_LOJA)
		cEmaiC		:= ALLTRIM(SA1->A1_EMAIL)
		cTelC		:= ALLTRIM(SA1->A1_TEL)
	endif

	if	DbSeek(xFilial("SA1") + SF1->F1_FORNECE + SF1->F1_LOJA)
		cEmaiC		:= ALLTRIM(SA1->A1_EMAIL)
		cTelC		:= ALLTRIM(SA1->A1_TEL)
	 endif

	if (Len(cCliRfc) == 12)
		cCliRfc := substr(cCliRfc,1,3)+"-"+substr(cCliRfc,4,6)+"-"+substr(cCliRfc,10,3)
	else
		cCliRfc := substr(cCliRfc,1,4)+"-"+substr(cCliRfc,5,6)+"-"+substr(cCliRfc,11,3)
	endif

	// Imprimir Logo de cliente
	oPrint:SayBitmap(135,100,cFileLogoR,500,202) // y,x,archivo,ancho,alto
	oPrint:SayBitMap(2650,1700,cFileRFC  ,550,250)
	
	// Direccion de emisor
	oPrint:Say(400,050,"TRANSCONSULT, S.A. DE C.V.",oArial16N,,,,2)
	oPrint:Say(450,050,"RFC TCT0202157R5",oArial12N,,,,2)
	                                                               //
	oPrint:Say(500,050,"FUENTE DE LA LUNA NO. 77",oArial10,,,,2)
	oPrint:Say(540,050,"FUENTES DEL PEDREGAL, MEXICO 14140",oArial10,,,,2)
	oPrint:Say(580,050,"TLALPAN, DISTRITO FEDERAL MEXICO",oArial10,,,,2)
	oPrint:Say(620,050,"Tel. +52 (55) 59 27 59 40",oArial10,,,,2)
	oPrint:Say(660,050,"www.transconsult.com.mx",oArial10,,,,2)

	// Numero de P·gina
	oPrint:Say(070,	2100,	"P·gina:  " + STRZERO(nPagNum,2),	oArial10N,,,,2)
	// Layout del encabezado
    nLinBx		:= 90
    nDifLBox	:= 4
    nDifLTxt	:= 30

	// Inicio: Lugar de Expedicion y Numero de Certificado
	fGnBoxHead(nLinBx,	700, 380, "Lugar de ExpediciÛn")
	fGnBoxHead(nLinBx,	1085, 380, "N˙mero de Certificado CSD")

	fGnBoxHead(nLinBx,		1475, 765, "")
	fGnBoxHead(nLinBx+40,	1475, 765, "")

	nLinBx	+=	45
 	fGnBoxDet(nLinBx,	700, 380, 45)
 	fGnBoxDet(nLinBx,	1085, 380, 45)

	fGnBoxDet(nLinBx+49,	1475, 765, 90)

	oPrint:Say(nLinBx + nDifLTxt,	710,	cEstado,	oArial09N,,,,2)   	//Lugar
	oPrint:Say(nLinBx + nDifLTxt,	1095,	cCert,		oArial09N,,,,2)   			//Certificado
	// Fin: Lugar de Expedicion y Numero de Certificado

	// Inicio: Indicacion de Factura / NCC / NDC
	if  ( mv_par07 == 1 ) 					// factura
		oPrint:Say(nLinBx+22,	1490,	"             F A C T U R A ", oArial20N,,CLR_WHITE,,2) //se dejo unicamente invoice a peticiÛn de intelbras
	elseif ( mv_par07 == 2 ) 				// CREDITO
		oPrint:Say(nLinBx+22, 	1490,	"  N O T A   D E   C R … D I T O", oArial20N,,CLR_WHITE,,2)
	endif

	oPrint:Say(nLinBx + 110,	1510,	cSerie,		oArial18N,,CLR_BLACK,,2)
	oPrint:Say(nLinBx + 110,	1600,	cFolio,		oArial18N,,CLR_BLACK,,2)
	// Fin: Indicacion de Factura / NCC / NDC

	// Inicio: FECHA de Expedicion y AÒo de Aprobacion
	nLinBx	+=	45
	fGnBoxHead(nLinBx + nDifLBox,	700, 380, "Fecha de ExpediciÛn")
	fGnBoxHead(nLinBx + nDifLBox,	1085, 380, "Fecha CertificaciÛn")

	nLinBx	+=	45
 	fGnBoxDet(nLinBx + nDifLBox,	700, 380, 45)
 	fGnBoxDet(nLinBx + nDifLBox,	1085, 380, 45)

	oPrint:Say(nLinBx + nDifLBox + nDifLTxt,	710,	cFECHAFac,	oArial09N,,,,2)   			//FECHA de Expedicion
	IF !empty(cTimbre)
     oPrint:Say(nLinBx + nDifLBox + nDifLTxt,	1095, cFechaTimbre,	oArial09N,,,,2)   			//AÒo
    ENDIF
	// Fin: FECHA de Expedicion y AÒo de Aprobacion

	// Inicio: Conducto, Numero de Aprobacion, Pedido y Orden de Compra Cliente
	nLinBx	+=	45
	fGnBoxHead(nLinBx + nDifLBox,	700, 380, "Forma Pago")
	fGnBoxHead(nLinBx + nDifLBox,	1085, 380, "N˙mero Certificado SAT")

	fGnBoxHead(nLinBx + nDifLBox,	1475, 765, "Folio Fiscal")
	//fGnBoxHead(nLinBx + nDifLBox,	1860, 380, "Orden de Compra")

	nLinBx	+=	45
 	fGnBoxDet(nLinBx + nDifLBox,	700, 380, 45)
 	fGnBoxDet(nLinBx + nDifLBox,	1085, 380, 45)

 	fGnBoxDet(nLinBx + nDifLBox,	1475, 765, 45)
 	//fGnBoxDet(nLinBx + nDifLBox,	1860, 380, 45)

	oPrint:Say(nLinBx + nDifLBox + nDifLTxt,	710 ,	cForPag,	oArial09N,,,,2)		//Forma de Pago
	if !empty(cTimbre)
     	oPrint:Say(nLinBx + nDifLBox + nDifLTxt,	1095,	cCertSAT,	oArial09N,,,,2)  	//cCertSAT
     	oPrint:Say(nLinBx + nDifLBox + nDifLTxt,	1600,	cFolioFis,	oArial09N,,,,2)  	//cCertSAT
    endif
	// Fin: Conducto, Numero de Aprobacion, Pedido y Orden de Compra Cliente

	// Inicio: Condiciones de Pago y Representante
	nLinBx	+=	45
	fGnBoxHead(nLinBx + nDifLBox,	0700, 765, "Condiciones de Pago")
	fGnBoxHead(nLinBx + nDifLBox,	1475, 765, "Metodo de Pago")

	nLinBx	+=	45
	
	cMetodoP	:= AllTrim(oXML:_cfdi_COMPROBANTE:_METODODEPAGO:TEXT)
	oPrint:Say(nLinBx + nDifLBox + nDifLTxt,0710,AllTrim(cMetodoP),oArial09N)
		 
	fGnBoxDet(nLinBx + nDifLBox,	700, 765, 45)
	oPrint:Say(nLinBx + nDifLBox + nDifLTxt,0710,AllTrim(u_BtForPag(SF2->F2_COND)),oArial09N)			//forma de pago
 	
 	fGnBoxDet(nLinBx + nDifLBox,	1475, 765, 45)
	//If mv_par07 == 1
	oPrint:Say(nLinBx + nDifLBox + nDifLTxt,1485,AllTrim(cMetodoP),oArial09N)	// Pedido
	//EndIf

	// Inicio: Facturar a y Embarcar a
	nLinBx	+=	45
	fGnBoxHead(nLinBx + nDifLBox,	700, 765, "Facturar a")
	fGnBoxHead(nLinBx + nDifLBox,	1475, 765, "Datos Bancarios")

	nLinBx	+=	45
	fGnBoxDet(nLinBx + nDifLBox,	700, 765, 180)
	fGnBoxDet(nLinBx + nDifLBox,	1475, 765, 180)
/*
	If AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_NOMBRE:TEXT) == "" .or. ;
	   AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_RFC:TEXT) == "" .or. ;
	   AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_CALLE:TEXT) == "" .or. ;
	   AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_MUNICIPIO:TEXT) == "" .or. ;
	   AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_ESTADO:TEXT)== "" .or. ;
	   AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_PAIS:TEXT)== "" .or. ;
	   AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_CODIGOPOSTAL:TEXT)== ""

		If lcampos == .F.
			MsgInfo("Hay campos vacios en el catalogo de clientes, favor de llenarlos.")
		EndIf
		lcampos := .T.
		Return
	EndIf
*/
	// FPB VERIFICA SI EL NUMERO INTERIOR ESTA VACIO
	IF VALTYPE(XmlChildex(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO,"_NOINTERIOR)")) = "O"
		cCliNumInt	:= AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_NOINTERIOR:TEXT)
	ELSE
		cCliNumInt	:= ""
	ENDIF
    // FPB IMPRIME LA DIRECCION DEL CLIENTE CON FORMATO DIFERENTE
    //Facturar a:
	oPrint:Say(nLinBx + nDifLBox + 35,	710,	SUBSTR(cCliNom,1,52),			    											oArial09N) // se quito el codigo del cliente a peticiÛn de intelbras
	oPrint:Say(nLinBx + nDifLBox + 60,	710,	alltrim(SUBSTR(cCliNom,53,100)),   												oArial09N)
	oPrint:Say(nLinBx + nDifLBox + 85,	710,	"RFC: " + cCliRfc + "     TEL: " + cTelC,	    								oArial09N)
	oPrint:Say(nLinBx + nDifLBox + 110,	710,	"DIRECCION: " + cCliCalle + " " + cCliNumExt + " " + cCliNumInt,				oArial09N)
	oPrint:Say(nLinBx + nDifLBox + 135,	710,	AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_cfdi_DOMICILIO:_COLONIA:TEXT) + ", " + cCliMun,	oArial09N)
	oPrint:Say(nLinBx + nDifLBox + 160,	710,	cCliEst + " C.P. " + cCliCp +  " " + cCliPais, 									oArial09N)

	// Inicio: Variables Embarcar a:
	cEntNombr	:= Alltrim(Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_NOME"))
	cEntRFC	:= Alltrim(Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_CGC"))
	cEntCalle	:= Alltrim(Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_END"))
	cEntNumExt	:= Alltrim(Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_NR_END"))
	cEntNumInt	:= Alltrim(Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_NROINT"))
	centMun	:= Alltrim(Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_BAIRRO")) + ", " + Alltrim(Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_MUN"))
	cEntEst	:= Alltrim(POSICIONE("SX5", 1, XFILIAL("SX5") + '12' + Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_EST"), 'SX5->X5_DESCSPA'))
	centPais	:= Alltrim(Posicione("SYA",1,xFilial("SYA") + Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_PAIS"), "YA_DESCR"))
	cEntCp		:= Alltrim(Posicione("SA1",1,xFilial("SA1") + cCliEnt + cLojEnt, "A1_CEP"))
    
    //impresion Datos Bancarios
    
	oPrint:Say(nLinBx + nDifLBox + 35,1485,	"DepÛsito Interbancario: " + GETMV("MV_BANCOSU"),	oArial09N)	//DepÛsito Interbancario:
	oPrint:Say(nLinBx + nDifLBox + 60,1485,	"N˙m. de Cuenta: " + GETMV("MV_BANCUEN"),			oArial09N)	//N˙m. de Cuenta
	oPrint:Say(nLinBx + nDifLBox + 85,1485, "CLABE Interbancaria: " + GETMV("MV_BANCLAB"),		oArial09N)	//CLABE Interbancaria
/*	oPrint:Say(nLinBx + nDifLBox + 120,1485,	"DIRECCION: " + cEntCalle + " " + cEntNumExt + " " + cEntNumInt,				oArial09N)
	oPrint:Say(nLinBx + nDifLBox + 150,1485,	cEntMun,	oArial09N)
	OPrint:Say(nLinBx + nDifLBox + 180,1485,	cEntEst + " C.P. " + cEntCp +  " " + cEntPais, 									oArial09N)
	*/
	// Fin: Facturar a y Embarcar

	// Inicio: Metodo de Pago, Cuenta de Pago, Monedo y Tipo de Cambio
	nLinBx	+=	95
	//fGnBoxHead(nLinBx + nDifLBox,	700, 765, "Metodo de Pago")
	fGnBoxHead(nLinBx + nDifLBox,	1475, 380, "Cuenta de Pago")
	fGnBoxHead(nLinBx + nDifLBox,	1860, 380, "Moneda")
	nLinBx	+=	45
 	//fGnBoxDet(nLinBx + nDifLBox,	700, 765, 45)
 	fGnBoxDet(nLinBx + nDifLBox,	1475, 380, 45)
 	fGnBoxDet(nLinBx + nDifLBox,	1860, 380, 45)
    // Fin: Metodo de Pago, Cuenta de Pago, Monedo y Tipo de Cambio

	cMetodoP	:= AllTrim(oXML:_cfdi_COMPROBANTE:_METODODEPAGO:TEXT)
	cCtaPago	:= AllTrim(oXML:_cfdi_COMPROBANTE:_NUMCTAPAGO:TEXT)
	//oPrint:Say(nLinBx + nDifLBox + nDifLTxt,0710,AllTrim(cMetodoP),oArial09N)
	oPrint:Say(nLinBx + nDifLBox + nDifLTxt,1485,AllTrim(cCtaPago),oArial09N)
	
	DO CASE
		CASE SF2->F2_MOEDA==1
			cTipMoe:= " Mexicano"
		CASE SF2->F2_MOEDA==2
			cTipMoe:= " (EEUU)"
		CASE SF2->F2_MOEDA==3
			cTipMoe:= " (Canadiense)"
		CASE SF2->F2_MOEDA==4
			cTipMoe:= " "
		CASE SF2->F2_MOEDA==5
			cTipMoe:= " "
			
	ENDCASE
	
   	oPrint:Say(nLinBx + nDifLBox + nDifLTxt,1870,UPPER(AllTrim(oXML:_cfdi_COMPROBANTE:_MONEDA:TEXT) + cTipMoe) ,oArial09N)

Return ()

/* 	--------------------------------------------------------------------------
		FunciÛn: 	PrtFooter
					Imprime la secciÛn al pie del documento.
		Par·metros:
			oXML: 	Objeto con el contenido del archivo XML leÌdo para el
					documento.
	-------------------------------------------------------------------------- */
Static Function PrtFooter(oXML)
	LOCAL cSerie 		:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_SERIE:TEXT)
	LOCAL cFolio 		:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_FOLIO:TEXT)
	Local cPago   	:= ""  //OemToAnsi(oXML:_cfdi_COMPROBANTE:_METODODEPAGO:TEXT)

	Local nCadLines	:= 1
	Local nLineSpace	:= 35
	Local nFall		:= 1
	Local nStart		:= 0
	Local cDescTot	:= VAL(OemToAnsi(oXML:_cfdi_COMPROBANTE:_DESCUENTO:TEXT))
	Local cSubTot		:= VAL(OemToAnsi(oXML:_cfdi_COMPROBANTE:_SUBTOTAL:TEXT))
 	Local cPorDesT	:= ""
	Local ntJmp		:= 2
	Local cImmex		:= ""
    Local cNomClien  := ""
	Local cRFCP		:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_RFC:TEXT)
	Local nSaltoRdp	:= 0
	LOCAL cCadOrig 	:= ""

	dbSelectArea("SA1")
	dbSetOrder(1)

  	if dbSeek(xFilial("SA1") + SF2->F2_CLIENTE+ SF2->F2_LOJA)
		cNomClient		:= ALLTRIM(SA1->A1_NOME)
		cImmex			:= "" //ALLTRIM(SA1->A1_IMMEX)
	endif

	If nPagNum	>= 1
		nFotY	:= 	2000
	EndIf
	// Importe y totales
	cExtenso:= BtCan(oXML:_cfdi_COMPROBANTE:_TOTAL:TEXT, cFolio, cSerie )   					// Obtener la cantidad en letra
	cTotal  := Val(oXML:_cfdi_COMPROBANTE:_SUBTOTAL:TEXT)- cDescItems
	cDescTot:= cDescTot-cDescItems

	nFoty += jmp


 	// Verifica la rutina de ejecucion para determinar si presnta la venta de las observaciones
 	if cRutEje == "EFAT002R"
 		//InfObsFT(cDoc, cSerie)
 		APROBADO(cDoc, cSerie)
 		
 	endif    

//IMPRESION DE APROBADORES
			//fila		//col	//ancho	  //alto
	//OBTIENE NUMERO DE APROBADORES
	nAprobs:=0
	
	IF ALLTRIM(SF2->F2_APROB1)<>""
		nAprobs:=	nAprobs + 1
	ENDIF
	IF ALLTRIM(SF2->F2_APROB2)<>""
		nAprobs:=	nAprobs + 1
	ENDIF
	IF ALLTRIM(SF2->F2_APROB3)<>""
		nAprobs:=	nAprobs + 1
	ENDIF
	IF ALLTRIM(SF2->F2_APROB4)<>""
		nAprobs:=	nAprobs + 1
	ENDIF	

//13-JULIO-2015 SOLICITUD DE AMPLIACION DE 35 A 80 CARACTERES EN APROBADOR Y EMPRESA	
/*	//SI HAY 4 APROBADORES DIBUJA 4 RECTANGULOS
	IF nAprobs == 4 
		//fGnBoxDet(nFotY-250,	050		, 547.5   , 230)
		oPrint:Say(nFotY -100,050,PADC(ALLTRIM(SF2->F2_APROB1),35),oCouNew10N)
		oPrint:Say(nFotY -075,050,PADC(ALLTRIM(SF2->F2_CARGO1),35),oCouNew10N)
		oPrint:Say(nFotY -050,050,PADC(ALLTRIM(SF2->F2_EMPRES1),35),oCouNew10N)
		
		//fGnBoxDet(nFotY-250,	597.5	, 547.5   , 230)
		oPrint:Say(nFotY -100,597.5,PADC(ALLTRIM(SF2->F2_APROB2),35),oCouNew10N)
		oPrint:Say(nFotY -075,597.5,PADC(ALLTRIM(SF2->F2_CARGO2),35),oCouNew10N)
		oPrint:Say(nFotY -050,597.5,PADC(ALLTRIM(SF2->F2_EMPRES2),35),oCouNew10N)

		//fGnBoxDet(nFotY-250,	1145	, 547.5   , 230)
		oPrint:Say(nFotY -100,1145,PADC(ALLTRIM(SF2->F2_APROB3),35),oCouNew10N)
		oPrint:Say(nFotY -075,1145,PADC(ALLTRIM(SF2->F2_CARGO3),35),oCouNew10N)
		oPrint:Say(nFotY -050,1145,PADC(ALLTRIM(SF2->F2_EMPRES3),35),oCouNew10N)
		
		//fGnBoxDet(nFotY-250,	1692.5	, 547.5   , 230)
		oPrint:Say(nFotY -100,1692.5,PADC(ALLTRIM(SF2->F2_APROB4),35),oCouNew10N)
		oPrint:Say(nFotY -075,1692.5,PADC(ALLTRIM(SF2->F2_CARGO4),35),oCouNew10N)
		oPrint:Say(nFotY -050,1692.5,PADC(ALLTRIM(SF2->F2_EMPRES4),35),oCouNew10N)
		
	ENDIF

	//SI HAY 3 APROBADORES DIBUJA 3 RECTANGULOS
	IF nAprobs == 3
		//fGnBoxDet(nFotY-250,	050		, 730	  , 230)
		oPrint:Say(nFotY -100,050,PADC(ALLTRIM(SF2->F2_APROB1),50),oCouNew10N)
		oPrint:Say(nFotY -075,050,PADC(ALLTRIM(SF2->F2_CARGO1),50),oCouNew10N)
		oPrint:Say(nFotY -050,050,PADC(ALLTRIM(SF2->F2_EMPRES1),50),oCouNew10N)

		//fGnBoxDet(nFotY-250,	780		, 730	  , 230)
		oPrint:Say(nFotY -100,780,PADC(ALLTRIM(SF2->F2_APROB2),50),oCouNew10N)
		oPrint:Say(nFotY -075,780,PADC(ALLTRIM(SF2->F2_CARGO2),50),oCouNew10N)
		oPrint:Say(nFotY -050,780,PADC(ALLTRIM(SF2->F2_EMPRES2),50),oCouNew10N)

		//fGnBoxDet(nFotY-250,	1510	, 730	  , 230)
		oPrint:Say(nFotY -100,1510,PADC(ALLTRIM(SF2->F2_APROB3),50),oCouNew10N)
		oPrint:Say(nFotY -075,1510,PADC(ALLTRIM(SF2->F2_CARGO3),50),oCouNew10N)
		oPrint:Say(nFotY -050,1510,PADC(ALLTRIM(SF2->F2_EMPRES3),50),oCouNew10N)
		
	ENDIF

	//SI HAY 2 APROBADORES DIBUJA 2 RECTANGULOS
	IF nAprobs == 2 
		//fGnBoxDet(nFotY-250,	050		, 1095   , 230)
		oPrint:Say(nFotY -100,050,PADC(ALLTRIM(SF2->F2_APROB1),75),oCouNew10N)
		oPrint:Say(nFotY -075,050,PADC(ALLTRIM(SF2->F2_CARGO1),75),oCouNew10N)
		oPrint:Say(nFotY -050,050,PADC(ALLTRIM(SF2->F2_EMPRES1),75),oCouNew10N)

		//fGnBoxDet(nFotY-250,	1145	, 1095   , 230)
		oPrint:Say(nFotY -100,1145,PADC(ALLTRIM(SF2->F2_APROB2),75),oCouNew10N)
		oPrint:Say(nFotY -075,1145,PADC(ALLTRIM(SF2->F2_CARGO2),75),oCouNew10N)
		oPrint:Say(nFotY -050,1145,PADC(ALLTRIM(SF2->F2_EMPRES2),75),oCouNew10N)
	ENDIF

	//SI HAY 1 APROBADORES DIBUJA 1 RECTANGULOS
	IF nAprobs == 1 
		//fGnBoxDet(nFotY-250,	050		, 2190   , 230)
		oPrint:Say(nFotY -100,050,PADC(ALLTRIM(SF2->F2_APROB1),140),oCouNew10N)
		oPrint:Say(nFotY -075,050,PADC(ALLTRIM(SF2->F2_CARGO1),140),oCouNew10N)
		oPrint:Say(nFotY -050,050,PADC(ALLTRIM(SF2->F2_EMPRES1),140),oCouNew10N)
	ENDIF	
*/
//13-JULIO-2015 SOLICITUD DE AMPLIACION DE 35 A 80 CARACTERES EN APROBADOR Y EMPRESA
	IF nAprobs == 4 
		//fGnBoxDet(nFotY-250,	050		, 547.5   , 230)
		oPrint:Say(nFotY -200,050,PADC(ALLTRIM(SF2->F2_APROB1),80),oCouNew10N)
		oPrint:Say(nFotY -175,050,PADC(ALLTRIM(SF2->F2_CARGO1),80),oCouNew10N)
		oPrint:Say(nFotY -150,050,PADC(ALLTRIM(SF2->F2_EMPRES1),35),oCouNew10N)
		
		//fGnBoxDet(nFotY-250,	597.5	, 547.5   , 230)
		oPrint:Say(nFotY -200,597.5,PADC(ALLTRIM(SF2->F2_APROB2),80),oCouNew10N)
		oPrint:Say(nFotY -175,597.5,PADC(ALLTRIM(SF2->F2_CARGO2),80),oCouNew10N)
		oPrint:Say(nFotY -150,597.5,PADC(ALLTRIM(SF2->F2_EMPRES2),35),oCouNew10N)

		//fGnBoxDet(nFotY-250,	1145	, 547.5   , 230)
		oPrint:Say(nFotY -200,1145,PADC(ALLTRIM(SF2->F2_APROB3),80),oCouNew10N)
		oPrint:Say(nFotY -175,1145,PADC(ALLTRIM(SF2->F2_CARGO3),80),oCouNew10N)
		oPrint:Say(nFotY -150,1145,PADC(ALLTRIM(SF2->F2_EMPRES3),35),oCouNew10N)
		
		//fGnBoxDet(nFotY-250,	1692.5	, 547.5   , 230)
		oPrint:Say(nFotY -200,1692.5,PADC(ALLTRIM(SF2->F2_APROB4),80),oCouNew10N)
		oPrint:Say(nFotY -175,1692.5,PADC(ALLTRIM(SF2->F2_CARGO4),80),oCouNew10N)
		oPrint:Say(nFotY -150,1692.5,PADC(ALLTRIM(SF2->F2_EMPRES4),35),oCouNew10N)
		
	ENDIF

	//SI HAY 3 APROBADORES DIBUJA 3 RECTANGULOS
	IF nAprobs == 3
		//fGnBoxDet(nFotY-250,	050		, 730	  , 230)
		oPrint:Say(nFotY -200,050,PADC(ALLTRIM(SF2->F2_APROB1),80),oCouNew10N)
		oPrint:Say(nFotY -175,050,PADC(ALLTRIM(SF2->F2_CARGO1),80),oCouNew10N)
		oPrint:Say(nFotY -150,050,PADC(ALLTRIM(SF2->F2_EMPRES1),50),oCouNew10N)

		//fGnBoxDet(nFotY-250,	780		, 730	  , 230)
		oPrint:Say(nFotY -200,780,PADC(ALLTRIM(SF2->F2_APROB2),80),oCouNew10N)
		oPrint:Say(nFotY -175,780,PADC(ALLTRIM(SF2->F2_CARGO2),80),oCouNew10N)
		oPrint:Say(nFotY -150,780,PADC(ALLTRIM(SF2->F2_EMPRES2),50),oCouNew10N)

		//fGnBoxDet(nFotY-250,	1510	, 730	  , 230)
		oPrint:Say(nFotY -200,1510,PADC(ALLTRIM(SF2->F2_APROB3),80),oCouNew10N)
		oPrint:Say(nFotY -175,1510,PADC(ALLTRIM(SF2->F2_CARGO3),80),oCouNew10N)
		oPrint:Say(nFotY -150,1510,PADC(ALLTRIM(SF2->F2_EMPRES3),50),oCouNew10N)
		
	ENDIF

	//SI HAY 2 APROBADORES DIBUJA 2 RECTANGULOS
	IF nAprobs == 2 
		//fGnBoxDet(nFotY-250,	050		, 1095   , 230)
		oPrint:Say(nFotY -200,050,PADC(ALLTRIM(SF2->F2_APROB1),80),oCouNew10N)
		oPrint:Say(nFotY -175,050,PADC(ALLTRIM(SF2->F2_CARGO1),80),oCouNew10N)
		oPrint:Say(nFotY -150,050,PADC(ALLTRIM(SF2->F2_EMPRES1),75),oCouNew10N)

		//fGnBoxDet(nFotY-250,	1145	, 1095   , 230)
		oPrint:Say(nFotY -200,1145,PADC(ALLTRIM(SF2->F2_APROB2),80),oCouNew10N)
		oPrint:Say(nFotY -175,1145,PADC(ALLTRIM(SF2->F2_CARGO2),80),oCouNew10N)
		oPrint:Say(nFotY -150,1145,PADC(ALLTRIM(SF2->F2_EMPRES2),75),oCouNew10N)
	ENDIF

	//SI HAY 1 APROBADORES DIBUJA 1 RECTANGULOS
	IF nAprobs == 1 
		//fGnBoxDet(nFotY-250,	050		, 2190   , 230)
		oPrint:Say(nFotY -200,050,PADC(ALLTRIM(SF2->F2_APROB1),140),oCouNew10N)
		oPrint:Say(nFotY -175,050,PADC(ALLTRIM(SF2->F2_CARGO1),140),oCouNew10N)
		oPrint:Say(nFotY -150,050,PADC(ALLTRIM(SF2->F2_EMPRES1),140),oCouNew10N)
	ENDIF	


	//fGnBoxHead(nFotY,	050, 1420, "OBSERVACIONES")
 	//fGnBoxHead(nFotY,	050, 1300, "Cantidad con Letra")
 	//fGnBoxDet(nFotY+45,	050, 1300, 180) 
 	nFotY := (nFotY - 90)
	fGnBoxHead(nFotY,	050, 1300, "Cantidad con Letra")
 	fGnBoxDet(nFotY+45,	050, 1300, 180)


	//If (cObservaciones) <> " "
		//fObs:=cObservaciones
		If Len(AllTrim(cExtenso)) >= 85     //TamaÒo de la cantidad en letra
			nLoop	:= 1
			For i := 1 To Len(AllTrim(cExtenso)) Step 85
				oPrint:Say(nFotY + 75 +(nLoop*30),060,SUBS(cExtenso,i,85),oCouNew10N)	//Observacion oCouNew09N
				nLoop++
			Next i
		Else
			oPrint:Say(nFotY + 75,060,cExtenso,oCouNew10N)	//Observacion
		EndIf
	//EndIF

	fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, "Importe")
	//fGnBoxDet( nFotY + nSaltoRdp,	1780, 460, 45)
	oPrint:Say(nFotY + nSaltoRdp + 30,	2000,Transform(Val(oXML:_cfdi_COMPROBANTE:_SUBTOTAL:TEXT)," 999,999,999.99"),oCouNew10N)	//Subtotal

	nSaltoRdp	+=	47      
	
	If SF2->F2_VALADI > 0 
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, "Amortizaciones")
		//fGnBoxDet( nFotY + nSaltoRdp,	1780, 460, 45)
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,Transform(SF2->F2_VALADI," 999,999,999.99"),oCouNew10N)	//Subtotal
	
		nSaltoRdp	+=	47    
		
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, "Subtotal")
		//fGnBoxDet( nFotY + nSaltoRdp,	1780, 460, 45)
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,Transform((SF2->F2_VALMERC - SF2->F2_VALADI)," 999,999,999.99"),oCouNew10N)	//Subtotal
	
		nSaltoRdp	+=	47 
	EndIf
/*
	If mv_par07 <> 3

		nDesPrd	:= Val(oXML:_cfdi_COMPROBANTE:_DESCUENTO:TEXT)
		if (nDesPrd > 0)
			fGnBoxHead(nFotY + nSaltoRdp,	1475, 550, "Descuento")
	 		//fGnBoxDet(nFotY + nSaltoRdp,	1780, 460, 45)
			oPrint:Say(nFotY + nSaltoRdp + 30,2000,Transform(Val(oXML:_cfdi_COMPROBANTE:_DESCUENTO:TEXT)," 999,999,999.99"),oCouNew10N)  	//descuento  0 if empresa == 2

			nSaltoRdp	+=	45
		endif
	EndIf
*/
	IF (cRFCP<>"XAXX010101000")
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, "I.V.A.")
 		//fGnBoxDet(nFotY + nSaltoRdp,	1780, 460, 45)
		//oPrint:Say(nFotY + nSaltoRdp + 30,	1820,	+Substring(AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_IMPUESTOS:_cfdi_TRASLADOS:_cfdi_TRASLADO:_TASA:TEXT),1,2)+"%" ,oCouNew10N)
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( Val(oXML:_cfdi_COMPROBANTE:_cfdi_IMPUESTOS:_cfdi_TRASLADOS:_cfdi_TRASLADO:_IMPORTE:TEXT)," 999,999,999.99"), oCouNew10N)
		nSaltoRdp	+=	47
	EndIf
/*
	if ( cRetItems > 0	)
		fGnBoxHead(nFotY + nSaltoRdp,	1475, 300, "Retencion")
 		fGnBoxDet(nFotY + nSaltoRdp,	1780, 460, 45)

		if (cRetItems > 0)
		  	oPrint:Say(nFotY + nSaltoRdp + 30,	1820,	(oXML:_cfdi_COMPROBANTE:_cfdi_IMPUESTOS:_cfdi_RETENCIONES:_cfdi_RETENCION:_IMPUESTO:TEXT),oCouNew10N)
			oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_IMPUESTOS:_cfdi_RETENCIONES:_cfdi_RETENCION:_IMPORTE:TEXT)," 999,999,999.99"),oCouNew10N)
			ntJmp++
		endif
		nSaltoRdp	+=	45
	endif
*/
	fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, "Subtotal")
	//fGnBoxDet(nFotY + nSaltoRdp,	1780, 460, 45)
	//oPrint:Say(nFotY + nSaltoRdp + 30,	1820,	+Substring(AllTrim(oXML:_cfdi_COMPROBANTE:_cfdi_IMPUESTOS:_cfdi_TRASLADOS:_cfdi_TRASLADO:_TASA:TEXT),1,2)+"%" ,oCouNew10N)
	//oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( SF2->F2_VALBRUT," 999,999,999.99"), oCouNew10N)
	oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( SF2->F2_VALBRUT + SF2->F2_VALIMP6," 999,999,999.99"), oCouNew10N)
	nSaltoRdp	+=	47

//IMPRESION DE RETENCIONES                                                               
//RETENCION 1
If SF2->F2_TIPODOC <> "19" .And. SF2->F2_VALIMP6 > 0
	IF Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET1") > 0
		nRetenc:=	Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET1")	
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, CAPITAL(ALLTRIM(Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_DESRET1"))))
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( (SF2->F2_VALMERC + SF2->F2_FRETE) * ( nRetenc / 100	) ," 999,999,999.99"), oCouNew10N)
		nSaltoRdp	+=	47			
	ENDIF
	IF Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET2") > 0
		nRetenc:=	Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET2")	
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, CAPITAL(ALLTRIM(Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_DESRET2"))))
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( (SF2->F2_VALMERC + SF2->F2_FRETE) * ( nRetenc / 100	) ," 999,999,999.99"), oCouNew10N)
		nSaltoRdp	+=	47			
	ENDIF
	IF Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET3") > 0
		nRetenc:=	Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET3")	
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, CAPITAL(ALLTRIM(Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_DESRET3"))))
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( (SF2->F2_VALMERC + SF2->F2_FRETE) * ( nRetenc / 100	) ," 999,999,999.99"), oCouNew10N)
		nSaltoRdp	+=	47			
	ENDIF
	IF Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET4") > 0
		nRetenc:=	Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET4")	
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, CAPITAL(ALLTRIM(Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_DESRET4"))))
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( (SF2->F2_VALMERC + SF2->F2_FRETE) * ( nRetenc / 100	) ," 999,999,999.99"), oCouNew10N)
		nSaltoRdp	+=	47			
	ENDIF
	IF Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET5") > 0
		nRetenc:=	Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET5")	
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, CAPITAL(ALLTRIM(Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_DESRET5"))))
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( (SF2->F2_VALMERC + SF2->F2_FRETE) * ( nRetenc / 100	) ," 999,999,999.99"), oCouNew10N)
		nSaltoRdp	+=	47			
	ENDIF
	IF Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET6") > 0
		nRetenc:=	Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET6")	
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, CAPITAL(ALLTRIM(Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_DESRET6"))))
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( (SF2->F2_VALMERC + SF2->F2_FRETE) * ( nRetenc / 100	) ," 999,999,999.99"), oCouNew10N)
		nSaltoRdp	+=	47			
	ENDIF
	IF Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET7") > 0
		nRetenc:=	Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_PORRET7")	
		fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, CAPITAL(ALLTRIM(Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA, "A1_DESRET7"))))
		oPrint:Say(nFotY + nSaltoRdp + 30,	2000,	Transform( (SF2->F2_VALMERC + SF2->F2_FRETE) * ( nRetenc / 100	) ," 999,999,999.99"), oCouNew10N)
		nSaltoRdp	+=	47			
	ENDIF            
EndIf

	fGnBoxHead(nFotY + nSaltoRdp,	1475-110, 550+100, "Total")
	//fGnBoxDet(nFotY + nSaltoRdp,	1780, 460, 45)
	oPrint:Say(nFotY + nSaltoRdp + 30,	2000,Transform(Val(oXML:_cfdi_COMPROBANTE:_TOTAL:TEXT)," 999,999,999.99"),oCouNew10N)				//Total

	nFotY	+=	225 + 10
    /*
	fGnBoxHead(nFotY,	050, 2190, "Cantidad con Letra")
	nFotY	+=	45
 	fGnBoxDet(nFotY,	050, 2190, 45)
 	oPrint:Say(nFotY + 30,		060, cExtenso,oCouNew11N)
    */
	//nFotY	+=	45 + 10
	nFotY	+=	45 + 60
   	fGnBoxHead(nFotY,	050, 2190, "Sello Digital del CFDI")
	nFotY	+=	45

 	fGnBoxDet(nFotY,	050, 2190, 70)
 	nRenglon	:= 30
 	nLoop		:= 0
 	For i := 1 To Len(oXML:_cfdi_COMPROBANTE:_SELLO:TEXT) Step 140
		oPrint:Say(nFotY + nRenglon, 060,SubStr(oXML:_cfdi_COMPROBANTE:_SELLO:TEXT,i,140),oCouNew10N)
		nRenglon += 30
		nLoop++
		If nLoop == 9999
			Exit
		EndIf
	Next i
	nFotY	+=	45 + 35
   	fGnBoxHead(nFotY,  050, 2190, "Sello del SAT")
	nFotY	+=	45
 	fGnBoxDet(nFotY,	050, 2190, 70)
	nRenglon	:= 30
 	nLoop		:= 0
	IF !empty(cTimbre)
 		For i := 1 To Len(oXML:_cfdi_COMPROBANTE:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_selloSAT:TEXT) Step 140
			oPrint:Say(nFotY + nRenglon, 060,SubStr(oXML:_cfdi_COMPROBANTE:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_selloSAT:TEXT,i,140),oCouNew10N)
			nRenglon += 30
			nLoop++
			If nLoop == 9999
				Exit
			EndIf
		Next i
	ENDIF
  	if !empty(cTimbre)
		BuscaCadOri(@cCadOrig,oXML)
  	endif
	nFotY	+=	70 + 10

	fGnBoxHead(nFotY,	050, 2190, "CADENA ORIGINAL DEL COMPLEMENTO DE CERTIFICACI”N DIGITAL DEL SAT")
	nFotY	+= 35  //	45
	nFotY2	:=0
	lBanhoja:=.F.
	nRenglon	:= 40
	IF !empty(cTimbre)
		For i := 1 To Len(cCadOrig) Step 140 //210
			If (nFotY + nRenglon) <= 3180
				oPrint:Say(nFotY + nRenglon, 060,SubStr(cCadOrig,i,140),oCouNew10N)
				nRenglon +=25
				nLoop++
				nFotY2	:=nFotY+nRenglon+20
			Else

				SetNewPage(oXML)
				nFontY := 780
				oPrint:Say(nFotY + nRenglon,120,SubStr(cCadOrig,i,140),oCouNew10N)
				nRenglon +=25
				nLoop++
				nFotY2	:=nFotY+nRenglon+20
			EndIf
			If nLoop == 9999
				Exit
			EndIf
		Next  	i
	else
		nFotY2	:=2690
	   	nFotY	:=2650
	endif
	/* Impresion del CÛdigo de Barras */
	IF !empty(cTimbre)
		cUUID:="?re="+Alltrim(oXML:_cfdi_COMPROBANTE:_cfdi_EMISOR:_RFC:TEXT)
		cUUID+="&rr="+Alltrim(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_RFC:TEXT)
		cUUID+="&tt="+Alltrim(oXML:_cfdi_COMPROBANTE:_TOTAL:TEXT)
		cUUID+="0000&id="+Alltrim(oXML:_cfdi_COMPROBANTE:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_UUID:TEXT)
		If mv_par08 == 1
			cArchivo := Lower(AllTrim(SF2->F2_ESPECIE)) + '_' + Lower(AllTrim(SF2->F2_SERIE)) + '_' + Lower(AllTrim(SF2->F2_DOC))
		else
		    cArchivo := Lower(AllTrim(SF1->F1_ESPECIE)) + '_' + Lower(AllTrim(SF1->F1_SERIE)) + '_' + Lower(AllTrim(SF1->F1_DOC))
		endif
		CodBarQR( cUUID , cArchivo )
		oPrint:SayBitMap( 2690,0100, GetClientDir() + cArchivo+".jpg", 300, 300)
	endif
	nFoty +=30
	nFotY2-=10  //20

	nFoty += jmp - 10

	oPrint:Sayalign(	nFotY2+30,	500,	"ESTE DOCUMENTO ES UNA REPRESENTACION IMPRESA DE UN CFDI.", oArial10,1200,60,,2,0)
	nFoty += jmp - 10
	If CTOD(SubStr(oXML:_cfdi_COMPROBANTE:_FECHA:TEXT,9,2)+"/"+SubStr(oXML:_cfdi_COMPROBANTE:_FECHA:TEXT,6,2)+"/"+SubStr(oXML:_cfdi_COMPROBANTE:_FECHA:TEXT,1,4)) > CTOD("30/06/2012")
		oPrint:Sayalign(	nFotY2+30+30,	500,"REGIMEN FISCAL:  " + oXML:_cfdi_COMPROBANTE:_cfdi_EMISOR:_cfdi_REGIMENFISCAL:_REGIMEN:TEXT, oArial10,1200,60,,2,0)
   	EndIf
	oPrint:EndPage()

Return ()
/* 	--------------------------------------------------------------------------
		FunciÛn: 	ImpDet
					Imprime la secciÛn de detalle del documento.
		Par·metros:
			oXML: 	Objeto con el contenido del archivo XML leÌdo para el
					documento.
		Retorno:    N˙mero de lÌnea de la p·gina actual en donde termina de
					imprimir el detalle.
	-------------------------------------------------------------------------- */
Static Function ImpDet(oXML)

Local nTotItem 	:= GetMv("MV_NUMITEM",,50)
Local nSaltDet 	:= 40
Local nCurLine	:= nDetY
Local nFall		:= 2
Local cCod			:=	""
Local cProv		:= 	""
Local cCod			:= ""
Local nImpD		:= ""
Local nNeto		:= 0
Local cRFCP		:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_cfdi_RECEPTOR:_RFC:TEXT)

LOCAL cObs      	:= ""
LOCAL cSec      	:= 0
LOCAL cProd     	:= ""
local cQueryObs	:= ""
local cSQLObs    	:= "TRX"
LOCAL cSecNumPed	:= ""
Local cObsItemFac	:= ""
Local cSerieLocal	:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_SERIE:TEXT)
Local cFolioLocal	:= OemToAnsi(oXML:_cfdi_COMPROBANTE:_FOLIO:TEXT)
LOCAL cPedimento 	:= ""
LOCAL fPedimento 	:= ""
LOCAL aPedimento 	:= ""
LOCAL cSecItFt   	:= 0

public cPedimAc[99]

fGnBoxCe(nDetY + nDifLBox,	50, 200, "       CANTIDAD")
//fGnBoxCe(nDetY + nDifLBox,	255, 350, "                    UM")
fGnBoxCe(nDetY + nDifLBox,	255, 200, "         UM")
fGnBoxCe(nDetY + nDifLBox,	455, 1220, "                                                                        DESCRIPCI”N")
//fGnBoxCe(nDetY + nDifLBox,	1525, 150, "       UM")
fGnBoxCe(nDetY + nDifLBox,	1680, 280, "               PRECIO U.")
fGnBoxCe(nDetY + nDifLBox,	1962, 280, "               IMPORTE")

nDetY	+= 80

nFall := 2

If  ( mv_par07 == 1 ) 					// Tipo Doc: factura

	nLinDes	:= 0

	if ( ValType(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO) <> "O" )		// M·s de una partida en factura

		for i := 1 to Len(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO)

			nLinDes	:= 0

			if ( i > nTotItem )
				Exit
			endif

			if ( nFall > 31 ) 	// 31 items por p·gina como m·ximo.

				If mv_par07 == 1
					fGnBoxHead(nDetY + 100,	50, 2190, "LA IMPRESION DE ESTA FACTURA CONTINUA EN LA P¡GINA " + strzero(nPagNum+1,2))
                ElseIf mv_par07 == 2
                	fGnBoxHead(nDetY + 100,	50, 2190, "LA IMPRESION DE ESTA NOTA DE CR…DITO CONTINUA EN LA P¡GINA " + strzero(nPagNum+1,2))
                EndIf

				SetNewPage(oXML)

				nDetY	:= 780

				fGnBoxCe(nDetY + nDifLBox,	50, 200, "       CANTIDAD")
				fGnBoxCe(nDetY + nDifLBox,	255, 350, "                    UM")
				fGnBoxCe(nDetY + nDifLBox,	610, 910, "                                                            DESCRIPCI”N")
				//fGnBoxCe(nDetY + nDifLBox,	1525, 150, "       UM")
				fGnBoxCe(nDetY + nDifLBox,	1680, 280, "               PRECIO U.")
				fGnBoxCe(nDetY + nDifLBox,	1962, 280, "               IMPORTE")

				nDetY	+= 80

				nFall := 2
				nLinDes	:= 0
				nCurLine := nDetY
			endif

			// FPB EXTRAE EL CODIGO DE PRODUCTO Y LA SECUENCIA EN LA FACTURA
			cSec 	:= left(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_noIdentificacion:TEXT,2)
			cProd 	:= right(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_noIdentificacion:TEXT,len(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_noIdentificacion:TEXT) - 2)

   			//Datos del cuerpo de la factura
   			oPrint:Say(nDetY,	60,	Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_CANTIDAD:TEXT) ," 999,999.99"),	oCouNew10)
            //oPrint:Say(nDetY,	260, cProd, oCouNew10)
        	oPrint:Say(nDetY,	260, (oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_UNIDAD:TEXT),	oCouNew10)
        	
			// DESCRIPCION
/*			nLinDes := 0
			If  Alltrim(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_DESCRIPCION:TEXT) <>  ""
				cDescT:=(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_DESCRIPCION:TEXT)		//Descripcion
				If Len(AllTrim(cDescT)) > 55
					nLoop	:= 1
					For rt := 1 To Len(AllTrim(cDescT)) Step 55
						oPrint:Say(nDetY + (nLinDes * 35),0615,SUBSTR(cDescT,rt,55),oCouNew10)		//Descripcion
						nLoop ++
						nLinDes ++
						nFall ++
					Next rt
				Else
					oPrint:Say(nDetY,0615,Substr(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_DESCRIPCION:TEXT,1,55),oCouNew10)
					nLinDes ++
					nFall ++
				Endif
			Endif
*/
cCadena:= Alltrim(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_DESCRIPCION:TEXT)
nLimite:= 68
nResto:= len(cCadena)//-nLimite
nPosIni:= 1
nPosFin:= 0
nLinDes := 0

IF LEN(cCadena)<68
oPrint:Say(nDetY,0480,U_CFDCarEsp(cCadena),oCouNew10)
			
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
			oPrint:Say(nDetY,0480,U_CFDCarEsp(cImprime),oCouNew10)
					nLinDes ++
					nFall ++ 
			//BREAK	
		ENDIF
		cImprime:=substr(cCadena,nPosIni,nPosFin)
		
		oPrint:Say(nDetY + (nLinDes * 35),0480,U_fJustTex(U_CFDCarEsp(cImprime),68),oCouNew10)		//Descripcion

					//nLoop ++
					nLinDes ++
					nFall ++
	    nResto:= len(cCadena)-nPosIni
	    cCadena:=alltrim(substr(cCadena, nPosFin , len(cCadena)))

enddo
nLinDes ++
nFall ++

			//OBSERVACIONES
			If mv_par07 == 1
				// RUTINAS PARA BUSCAR LA SECUENCIA EN EL PEDIDO DE VENTA
				cQueryObs := " SELECT * "
		        cQueryObs += " FROM " + InitSqlName("SD2")+" SD2 "
		        cQueryObs += " WHERE SD2.D2_SERIE  = '"+cSerieLocal+"'"
		        cQueryObs += "   AND SD2.D2_DOC    = '"+cFolioLocal+"'"
		        cQueryObs += "   AND SD2.D2_COD    = '"+cProd +"'"
		        cQueryObs += "   AND SD2.D2_ITEM   = '"+cSec  +"'"
		        cQueryObs += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
		        cQueryObs += "   AND SD2.D_E_L_E_T_ = ' '"
		        dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQueryObs),cSQLObs,.T.,.T.)
		        If (cSQLObs)->(!eof())
		            Do while !eof()
		                cSecNumPed 	:= (cSQLObs)->D2_ITEMPV
		                //cPedimento  := (cSQLObs)->D2_PEDIM
		                cSecItFt    := (cSQLObs)->D2_NUMSEQ
		                (cSQLObs)->(Dbskip())
		            End
		        EndIf
		        (cSQLObs)->(Dbclosearea())
		        // EXTRAE LAS OBSERVACIONES DEL ITEM DEL CAMPO ESPECIFICO DE INTELBRAS
		        IF !EMPTY(cSecItFt)
						SD2->(DBSETORDER(4))
						SD2->(DbSeek(xFilial("SD2") + alltrim(cSecItFt),.T.))
						cObsItemFac := "" //Alltrim(SD2->D2_OBS)
		        ENDIF
		       //VERIFICA SI LAS OBSERVACIONES ESTA EN BLANCO PARA BUSCAR LAS DEL PEDIDO
				IF !empty(cPedido) // VERIFICA QUE EXISTA EL PEDIDO PARA BUSCAR LAS OBSERVACIONES
					SC6->(DbSeek(xFilial("SC6") + alltrim(cPedido) + alltrim(cSecNumPed) + alltrim(cProd)),.T.)
					cObsItemFac := cObsItemFac + Alltrim(SC6->C6_MOPC) //C6_VDOBS
				ENDIF

				cObs:=cObsItemFac		//Observacion
				If Len(AllTrim(cObs)) > 55
					nLoop	:= 1
					For O := 1 To Len(AllTrim(cObs)) Step 55
						oPrint:Say(nDetY + (nLinDes * 35),0615,SUBSTR(cObs,O,55),oCouNew10)		//Descripcion
						nLoop ++
						nLinDes ++
						nFall ++
					Next O
				Else
					IF !EMPTY(cObs)
						oPrint:Say(nDetY + (nLinDes * 35),0615,SUBS(cObs,1,55),oCouNew10)
						nLinDes ++
						nFall ++
					ENDIF
				EndIf
			EndIf

 			//oPrint:Say(nDetY,	1530, (oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_UNIDAD:TEXT),	oCouNew10)
			oPrint:Say(nDetY,	1700, Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_VALORUNITARIO:TEXT)," 99,999,999.99"),	oCouNew10)
			oPrint:Say(nDetY,	1990, Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_IMPORTE:TEXT), " 99,999,999.99"),oCouNew10)

			nDetY	+= (35 * nLinDes)

			nCurLine 	+= jmp
			cRetItems 	+= SD2->D2_VALIMP2

		next i
	else

		nLinDes	:= 0

		// FPB EXTRAE EL CODIGO DE PRODUCTO Y LA SECUENCIA EN LA FACTURA
		cSec 	:= left(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_noIdentificacion:TEXT,2)
		cProd 	:= right(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_noIdentificacion:TEXT,len(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_noIdentificacion:TEXT) - 2)

		oPrint:Say(nDetY,	60,	Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_CANTIDAD:TEXT) ," 999,999.99"),	oCouNew10)
       //oPrint:Say(nDetY,	260, cProd, oCouNew10)                                                                                                
        oPrint:Say(nDetY,	260, (oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_UNIDAD:TEXT),	oCouNew10)
		
/*
		// DESCRIPCION
		If  Alltrim(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_DESCRIPCION:TEXT) <>  ""
			cDescT:=(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_DESCRIPCION:TEXT)		//Descripcion
			If Len(AllTrim(cDescT)) > 55
				nLoop	:= 1
				For rt := 1 To Len(AllTrim(cDescT)) Step 55
					oPrint:Say(nDetY + (nLinDes * 35),0615,SUBSTR(cDescT,rt,55),oCouNew10)		//Descripcion
					nLoop ++
					nLinDes ++
					nFall ++
				Next rt
			Else
				oPrint:Say(nDetY,0615,Substr(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_DESCRIPCION:TEXT,1,55),oCouNew10)
				nLinDes ++
				nFall ++
			Endif
		Endif
*/
cCadena:= Alltrim(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_DESCRIPCION:TEXT)
nLimite:= 68
nResto:= len(cCadena)//-nLimite
nPosIni:= 1
nPosFin:= 0


IF LEN(cCadena)<68
oPrint:Say(nDetY,0480,U_CFDCarEsp(cCadena),oCouNew10)
			
ENDIF

while nResto >=68
//while len(cCadena) >=55

		nPosFin:= 68
		IF LEN(cCadena)>=68
			nPosFin:= rat(" ",substr(cCadena,nPosIni,nPosFin) )
		ELSE
			nPosFin:= LEN(cCadena) //68 
		ENDIF               
		IF nPosFin == 0
			cImprime:=cCadena
			//msgalert(cImprime) //imprimir
			oPrint:Say(nDetY,0480,U_CFDCarEsp(cImprime),oCouNew10)
					nLinDes ++
					nFall ++ 
			//BREAK	
		ENDIF
		cImprime:=substr(cCadena,nPosIni,nPosFin)
		IF LEN(alltrim(cImprime)) >= 40//LSERVIN 21/07/2015  
		oPrint:Say(nDetY + (nLinDes * 35),0480,U_fJustTex(U_CFDCarEsp(cImprime),68),oCouNew10)		//Descripcion
		ELSE  
		oPrint:Say(nDetY + (nLinDes * 35),0480,U_CFDCarEsp(cImprime),oCouNew10)		//Descripcion//LSERVIN 21/07/2015	
		ENDIF //LSERVIN 21/07/2015
		//oPrint:Say(nDetY + (nLinDes * 35),0480,U_fJustTex(U_CFDCarEsp(cImprime),nPosFin),oCouNew10)		//Descripcion
					//nLoop ++
					nLinDes ++
					nFall ++
	    nResto:= len(cCadena)-nPosIni
	    cCadena:=alltrim(substr(cCadena, nPosFin , len(cCadena)))

enddo

		//OBSERVACIONES
		If mv_par07 == 1
			// RUTINAS PARA BUSCAR LA SECUENCIA EN EL PEDIDO DE VENTA
			cQueryObs := " SELECT * "
	        cQueryObs += " FROM " + InitSqlName("SD2")+" SD2 "
	        cQueryObs += " WHERE SD2.D2_SERIE  = '"+cSerieLocal+"'"
	        cQueryObs += "   AND SD2.D2_DOC    = '"+cFolioLocal+"'"
	        cQueryObs += "   AND SD2.D2_COD    = '"+cProd +"'"
	        cQueryObs += "   AND SD2.D2_ITEM   = '"+cSec  +"'"
	        cQueryObs += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
	        cQueryObs += "   AND SD2.D_E_L_E_T_ = ' '"
	        dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQueryObs),cSQLObs,.T.,.T.)
	        If (cSQLObs)->(!eof())
	            Do while !eof()
	                cSecNumPed 	:= (cSQLObs)->D2_ITEMPV
	                //cPedimento  := (cSQLObs)->D2_PEDIM
	                cSecItFt    := (cSQLObs)->D2_NUMSEQ
	                (cSQLObs)->(Dbskip())
	            End
	        EndIf
	        (cSQLObs)->(Dbclosearea())
	        // EXTRAE LAS OBSERVACIONES DEL ITEM DEL CAMPO ESPECIFICO DE INTELBRAS
	        IF !EMPTY(cSecItFt)
					SD2->(DBSETORDER(4))
					SD2->(DbSeek(xFilial("SD2") + alltrim(cSecItFt),.T.))
					cObsItemFac := "" //Alltrim(SD2->D2_OBS)
	        ENDIF
	        //VERIFICA SI LAS OBSERVACIONES ESTA EN BLANCO PARA BUSCAR LAS DEL PEDIDO
			IF !empty(cPedido) // VERIFICA QUE EXISTA EL PEDIDO PARA BUSCAR LAS OBSERVACIONES
				SC6->(DbSeek(xFilial("SC6") + alltrim(cPedido) + alltrim(cSecNumPed) + alltrim(cProd)),.T.)
				cObsItemFac := cObsItemFac + Alltrim(SC6->C6_MOPC) //C6_VDOBS
			ENDIF

			cObs:=cObsItemFac		//Observacion
			If Len(AllTrim(cObs)) > 55
				nLoop	:= 1
				For O := 1 To Len(AllTrim(cObs)) Step 55
					oPrint:Say(nDetY + (nLinDes * 35),0615,SUBSTR(cObs,O,55),oCouNew10)		//Descripcion
					nLoop ++
					nLinDes ++
					nFall ++
				Next O
			Else
				IF !EMPTY(cObs)
					oPrint:Say(nDetY + (nLinDes * 35),0615,SUBS(cObs,1,55),oCouNew10)
					nLinDes ++
					nFall ++
				ENDIF
			EndIf
		EndIf

		//oPrint:Say(nDetY,	1530, (oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_UNIDAD:TEXT),	oCouNew10)
		oPrint:Say(nDetY,	1700, Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_VALORUNITARIO:TEXT), " 99,999,999.99"),	oCouNew10)
		oPrint:Say(nDetY,	1990, Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_IMPORTE:TEXT), " 99,999,999.99"),oCouNew10)

   		nDetY	+= 35
	EndIf
Elseif ( mv_par07 == 2 ) 				// Tipo Docto: credito

	dbSelectArea("SD1")
	dbSetOrder(1)
	dbSeek(xFilial("SD1") + cDOC + cSER + cCTE + cLOJA )

 	dbSelectArea("SF1")
	dbSetOrder(1)
	dbSeek(xFilial("SF1") + cDOC + cSER + cCTE + cLOJA )

	if ( ValType(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO) <> "O" )		// M·s de una partida en factura

		for i := 1 to Len(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO)

			nLinDes	:= 0

			if ( i > nTotItem )
				Exit
			endif

			if ( nFall > 31 ) 	// 31 lineas de detalle por p·gina como m·ximo.
				fGnBoxHead(nDetY + 100,	50, 2190, "LA IMPRESION DE ESTA NOTA DE CR…DITO CONTINUA EN LA P¡GINA " + strzero(nPagNum+1,2))

				SetNewPage(oXML)

				nDetY	:= 780

				fGnBoxCe(nDetY + nDifLBox,	50, 200, "       CANTIDAD")
				fGnBoxCe(nDetY + nDifLBox,	255, 350, "                    UM")
				fGnBoxCe(nDetY + nDifLBox,	610, 910, "                                                            DESCRIPCI”N")
				//fGnBoxCe(nDetY + nDifLBox,	1525, 150, "       UM")
				fGnBoxCe(nDetY + nDifLBox,	1775, 280, "               PRECIO U.")
				fGnBoxCe(nDetY + nDifLBox,	2030, 280, "               IMPORTE")

				nFall := 2
				nCurLine := nDetY
			endif

			// FPB EXTRAE EL CODIGO DE PRODUCTO Y LA SECUENCIA EN LA FACTURA
			cSec 	:= left(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_noIdentificacion:TEXT,4)
			cProd 	:= right(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_noIdentificacion:TEXT,len(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_noIdentificacion:TEXT) - 4)

   			//Datos del cuerpo de la factura
   			oPrint:Say(nDetY,	60,	Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_CANTIDAD:TEXT) ," 999,999.99"),	oCouNew10)
            //oPrint:Say(nDetY,	260, cProd, oCouNew11)
 
			// DESCRIPCION
			If  Alltrim(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_DESCRIPCION:TEXT) <>  ""
				cDescT:=(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_DESCRIPCION:TEXT)		//Descripcion
				If Len(AllTrim(cDescT)) > 55
					nLoop	:= 1
					For rt := 1 To Len(AllTrim(cDescT)) Step 55
						oPrint:Say(nDetY + (nLinDes * 35),0615,SUBSTR(cDescT,rt,55),oCouNew10)		//Descripcion
						nLoop ++
						nLinDes ++
						nFall ++
					Next rt
				Else
					oPrint:Say(nDetY,0615,Substr(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_DESCRIPCION:TEXT,1,55),oCouNew10)
					nLinDes ++
					nFall ++
				Endif
			Endif

			//OBSERVACIONES
			//RUTINAS PARA BUSCAR EL PEDIMENTO Y LAS OBSERVACIONES DEL ITEM DE LA NOTA
			cQueryObs := " SELECT * "
		    cQueryObs += " FROM " + InitSqlName("SD1")+" SD1 "
		    cQueryObs += " WHERE SD1.D1_SERIE  = '"+cSerieLocal+"'"
		    cQueryObs += "   AND SD1.D1_DOC    = '"+cFolioLocal+"'"
		    cQueryObs += "   AND SD1.D1_COD    = '"+cProd +"'"
		    cQueryObs += "   AND SD1.D1_ITEM   = '"+cSec  +"'"
		    cQueryObs += "   AND SD1.D1_FILIAL = '" + xFilial("SD1") + "'"
		    cQueryObs += "   AND SD1.D_E_L_E_T_ = ' '"
		    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQueryObs),cSQLObs,.T.,.T.)
		    If (cSQLObs)->(!eof())
		        Do while !eof()
		          	//cPedimento  := (cSQLObs)->D1_PEDIM
					cSecItFt    := (cSQLObs)->D1_NUMSEQ
		          	(cSQLObs)->(Dbskip())
		        End
		    EndIf
		    (cSQLObs)->(Dbclosearea())
	        // EXTRAE LAS OBSERVACIONES DEL ITEM DEL CAMPO ESPECIFICO DE INTELBRAS
	        IF !EMPTY(cSecItFt)
					SD1->(DBSETORDER(4))
					SD1->(DbSeek(xFilial("SD1") + alltrim(cSecItFt),.T.))
					//cObsItemFac := Alltrim(SD1->D1_OBS)
	        ENDIF
			cObs:=cObsItemFac		//Observacion
			If Len(AllTrim(cObs)) > 55
				nLoop	:= 1
				For O := 1 To Len(AllTrim(cObs)) Step 55
					oPrint:Say(nDetY + (nLinDes * 35),0615,SUBSTR(cObs,O,55),oCouNew10)
					nLoop ++
					nLinDes ++
					nFall ++
				Next O
			Else
				IF !EMPTY(cObs)
					oPrint:Say(nDetY + (nLinDes * 35),0615,SUBS(cObs,1,55),oCouNew10)
					nLinDes ++
					nFall ++
				ENDIF
			EndIf

			oPrint:Say(nDetY,	1530, (oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_UNIDAD:TEXT),	oCouNew10)
			oPrint:Say(nDetY,	1745, Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_VALORUNITARIO:TEXT)," 9,999,999.99"),	oCouNew10)
			oPrint:Say(nDetY,	2010, Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO[i]:_IMPORTE:TEXT), " 99,999,999.99"),oCouNew10)

			nDetY	+= (35 * nLinDes)
			nCurLine 	+= jmp
			nCurLine 	+= jmp
			cDescItems 	+= SD1->D1_VUNIT * (SD1->D1_DESC / 100) * SD1->D1_QUANT
			cRetItems 	+= SD1->D1_VALIMP2

			dbSelectArea("SF1")
			dbSetOrder(1)
			dbSeek(xFilial("SF1") + cDOC + cSER + cCTE + cLOJA )

		next i
	else

		nLinDes	:= 0

		// FPB EXTRAE EL CODIGO DE PRODUCTO Y LA SECUENCIA EN LA FACTURA
		cSec 	:= left(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_noIdentificacion:TEXT,4)
		cProd 	:= right(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_noIdentificacion:TEXT,len(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_noIdentificacion:TEXT) - 4)

   		//Datos del cuerpo de la factura
   		oPrint:Say(nDetY,	60,	Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_CANTIDAD:TEXT) ," 999,999.99"),	oCouNew10)
      	//oPrint:Say(nDetY,	260, cProd, oCouNew10)

		// DESCRIPCION
		If  Alltrim(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_DESCRIPCION:TEXT) <>  ""
			cDescT:=(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_DESCRIPCION:TEXT)		//Descripcion
			If Len(AllTrim(cDescT)) > 55
				nLoop	:= 1
				For rt := 1 To Len(AllTrim(cDescT)) Step 55
					oPrint:Say(nDetY + (nLinDes * 35),0615,SUBSTR(cDescT,rt,55),oCouNew10)		//Descripcion
					nLoop ++
					nLinDes ++
					nFall ++
				Next rt
			Else
				oPrint:Say(nDetY,0615,Substr(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_DESCRIPCION:TEXT,1,55),oCouNew10)
				nLinDes ++
				nFall ++
			Endif
		Endif

		//OBSERVACIONES
		//RUTINAS PARA BUSCAR EL PEDIMENTO Y LAS OBSERVACIONES DEL ITEM DE LA NOTA
		cQueryObs := " SELECT * "
	    cQueryObs += " FROM " + InitSqlName("SD1")+" SD1 "
	    cQueryObs += " WHERE SD1.D1_SERIE  = '"+cSerieLocal+"'"
	    cQueryObs += "   AND SD1.D1_DOC    = '"+cFolioLocal+"'"
	    cQueryObs += "   AND SD1.D1_COD    = '"+cProd +"'"
	    cQueryObs += "   AND SD1.D1_ITEM   = '"+cSec  +"'"
	    cQueryObs += "   AND SD1.D1_FILIAL = '" + xFilial("SD1") + "'"
	    cQueryObs += "   AND SD1.D_E_L_E_T_ = ' '"
	    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQueryObs),cSQLObs,.T.,.T.)
	    If (cSQLObs)->(!eof())
	        Do while !eof()
	          	//cPedimento  := (cSQLObs)->D1_PEDIM
				cSecItFt    := (cSQLObs)->D1_NUMSEQ
	          	(cSQLObs)->(Dbskip())
	        End
	    EndIf
	    (cSQLObs)->(Dbclosearea())
        // EXTRAE LAS OBSERVACIONES DEL ITEM DEL CAMPO ESPECIFICO DE INTELBRAS
        IF !EMPTY(cSecItFt)
				SD1->(DBSETORDER(4))
				SD1->(DbSeek(xFilial("SD1") + alltrim(cSecItFt),.T.))
				//cObsItemFac := Alltrim(SD1->D1_OBS)
        ENDIF
		cObs:=cObsItemFac		//Observacion
		If Len(AllTrim(cObs)) > 55
			nLoop	:= 1
			For O := 1 To Len(AllTrim(cObs)) Step 55
				oPrint:Say(nDetY + (nLinDes * 35),0615,SUBSTR(cObs,O,55),oCouNew10)
				nLoop ++
				nLinDes ++
				nFall ++
			Next O
		Else
			IF !EMPTY(cObs)
				oPrint:Say(nDetY + (nLinDes * 35),0615,SUBS(cObs,1,55),oCouNew10)
				nLinDes ++
				nFall ++
			ENDIF
		EndIf

		oPrint:Say(nDetY,	1530, (oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_UNIDAD:TEXT),	oCouNew10)
		oPrint:Say(nDetY,	1745, Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_VALORUNITARIO:TEXT)," 9,999,999.99"),	oCouNew10)
		oPrint:Say(nDetY,	2010, Transform(Val(oXML:_cfdi_COMPROBANTE:_cfdi_CONCEPTOS:_cfdi_CONCEPTO:_IMPORTE:TEXT), " 99,999,999.99"),oCouNew10)

		nDetY	+= (35 + nLinDes)

		nCurLine 	+= jmp
		cDescItems 	+= SD1->D1_VUNIT * (SD1->D1_DESC / 100) * SD1->D1_QUANT
		cRetItems 	+= SD1->D1_VALIMP2

	EndIf

Endif

nCurLine += 10

Return (nCurLine)

Static Function IsPageEnd(nCurY,nLimit)
	if (nCurY+10 >= nLimit)
		return .T.
	else
		return .F.
	endif
Return ()

Static Function SetNewPage(oXML)
	oPrint:EndPage()
	oPrint:StartPage()
	nPagNum++
	PrtHeader(oXML)
	nFotY	:= nDetY
Return ()

/*/
_____________________________________________________________________________
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
¶¶+-----------------------------------------------------------------------+¶¶
¶¶¶FunÁ‡o    ¶ CONHEC   ¶ Autor ¶   Marcos Simidu       ¶ Data ¶ 20/12/95 ¶¶¶
¶¶+----------+------------------------------------------------------------¶¶¶
¶¶¶DescriÁ‡o ¶ GRAVA NO BANCO DE CONHECIMENTO A IMAGEM                    ¶¶¶
¶¶+----------+------------------------------------------------------------¶¶¶
¶¶¶Uso       ¶ Nfiscal                                                    ¶¶¶
¶¶+-----------------------------------------------------------------------+¶¶
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ
/*/
Static Function CONHEC()

Local cArq

cAlias := Alias()
// ATUALIZA CADASTRO DE OBJETOS ( BANCO DE CONHECIMENTO ) ALIAS - ACB
DBSELECTAREA("ACB")
DBSETORDER(2)

If mv_par08 == 1
	cArq := "NF"+ALLTRIM(SF2->F2_DOC+SF2->F2_SERIE)+".PDF"
	//cArq := "NF"+ALLTRIM(SF2->F2_DOC+SF2->F2_SERIE)+"_PAG1.JPG"
Else
	cArq := "NF"+ALLTRIM(SF1->F1_DOC+SF1->F1_SERIE)+".PDF"
	//cArq := "NF"+ALLTRIM(SF1->F1_DOC+SF1->F1_SERIE)+"_PAG1.JPG"
EndIf

IF DBSEEK(XFILIAL("ACB")+cArq, .F.)
	RECLOCK("ACB", .F. )
	cNumAcb := ACB->ACB_CODOBJ
	lInsert := .F.
ELSE
	lInsert := .T.
	RECLOCK("ACB", .T. )
	cNumACB := GetSxeNum("ACB","ACB_CODOBJ")
	REPLACE ACB_FILIAL WITH XFILIAL("ACB")
	REPLACE ACB_CODOBJ WITH cNumACB
	REPLACE ACB_OBJETO WITH UPPER(cArq)
	If mv_par08 == 1
		REPLACE ACB_DESCRI WITH "NF"+ALLTRIM(SF2->F2_DOC+SF2->F2_SERIE)
	Else
		REPLACE ACB_DESCRI WITH "NF"+ALLTRIM(SF1->F1_DOC+SF1->F1_SERIE)
	EndIF
	MSUNLOCK()

	ConfirmSx8("ACB")

	// ATUALIZA AMARRACAO OBJTOS X CLIENTE
	DBSELECTAREA("AC9")
	DBSETORDER(2)//AC9_FILIAL+AC9_ENTIDA+AC9_FILENT+AC9_CODENT+AC9_CODOBJ
	If mv_par08 == 1
		IF !DBSEEK( XFILIAL("AC9")+"SF2"+XFILIAL("SF2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA+cNumAcb  , .F. )
			RECLOCK("AC9", .T. )
			REPLACE AC9_FILIAL WITH XFILIAL("AC9")
			REPLACE AC9_FILENT WITH XFILIAL("SF2")
			REPLACE AC9_ENTIDA WITH "SF2"
			REPLACE AC9_CODENT WITH SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA
			REPLACE AC9_CODOBJ WITH cNumACB
			MSUNLOCK()
		Endif
	Else
		IF !DBSEEK( XFILIAL("AC9")+"SF1"+XFILIAL("SF1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+cNumAcb  , .F. )
			RECLOCK("AC9", .T. )
			REPLACE AC9_FILIAL WITH XFILIAL("AC9")
			REPLACE AC9_FILENT WITH XFILIAL("SF1")
			REPLACE AC9_ENTIDA WITH "SF1"
			REPLACE AC9_CODENT WITH SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA
			REPLACE AC9_CODOBJ WITH cNumACB
			MSUNLOCK()
		Endif
	EndIf
ENDIF

DBSELECTAREA( cAlias )

Return ()

Static Function BuscaCadOri(cCadOrig,oXML)
		cCadOrig :="||"
		cCadOrig += Alltrim( oXML:_cfdi_COMPROBANTE:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_version:TEXT )  + "|"
	  	cCadOrig += Alltrim( oXML:_cfdi_COMPROBANTE:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_UUID:TEXT )  + "|"
		cCadOrig += Alltrim( oXML:_cfdi_COMPROBANTE:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_FechaTimbrado:TEXT )  + "|"
	 	cCadOrig += Alltrim( oXML:_cfdi_COMPROBANTE:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_selloCFD:TEXT )  + "|"
		cCadOrig += Alltrim( oXML:_cfdi_COMPROBANTE:_cfdi_Complemento:_tfd_TimbreFiscalDigital:_noCertificadoSAT:TEXT ) + "|"
		cCadOrig += "|"
Return(Nil)

Static Function MBSendMail(cAccount,cPassword,cServer,cFrom,cEmail,cAssunto,cMensagem,cBodyMsg,xAttach)

Local cEmailTo := ""
Local cEmailBcc:= ""
Local lResult  := .F.
Local cError   := ""
Local lRelauth := GetMv("MV_RELAUTH")		// Parametro que indica se existe autenticacao no e-mail
Local lRet	   := .F.
Local cConta   := ALLTRIM(cAccount)
Local xSenha   := ALLTRIM(cPassword)
Local aAttach  := ""
Local lVenEmail:= .T.

IF ValType(xAttach) <> "A"
   aAttach := { xAttach }
Else
   aAttach := xAttach
Endif

//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
//≥Envia o mail para a lista selecionada. Envia como BCC para que a pessoa pense≥
//≥que somente ela recebeu aquele email, tornando o email mais personalizado.   ≥
//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ

if empty(cEmail) // EMail del cliente vacÌo
	lVenEmail := TelaEmail(@cMensagem,cAssunto,@aAttach,@cEmail)
Endif
        
if lVenEmail //(TelaEmail(@cMensagem,cAssunto,@aAttach,@cEmail))

	cEmailTo := cEmail
	If At(";",cEmail) > 0 // existe um segundo e-mail.
		cEmailBcc:= SubStr(cEmail,At(";",cEmail)+1,Len(cEmail))
	Endif

	lResult := MailSmtpOn( cServer, cConta, xSenha, )

	// Se a conexao com o SMPT esta ok
	If lResult
		// Se existe autenticacao para envio valida pela funcao MAILAUTH
		If lRelauth
			lRet := Mailauth(cConta,xSenha)
		Else
			lRet := .T.
	    Endif

		If lRet

	        lResult := MailSend( cFrom, { cEmailTo }, { }, { cEmailBcc }, cAssunto, cBodyMsg, aAttach , .F. )

			If !lResult
				//Erro no envio do email
				cError:=MailGetErr( )
				Help(" ",1,"ATENCI”N",,cError+ " " + cEmailTo,4,5)
			Endif

		Else
			cError:=MailGetErr( )
			Help(" ",1,"AutenticaciÛn",,cError,4,5)
			MsgStop("Error en la autenticaciÛn","Hace la verificaciÛn de la cuenta y contraseÒa")
		Endif

		MailSmtpOff()  // Disconnect to Smtp Server

	Else
		//Erro na conexao com o SMTP Server
		cError:=MailGetErr( )
		Help(" ",1,"AtenciÛn",,cError,4,5)
	Endif

EndIf

Return(lResult)



/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒø±±
±±≥FunáÑo    ≥ TelaEmail   ≥ Autor ≥ Microsiga ≥          Data ≥07/08/03  ≥±±
±±√ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒ¥±±
±±≥DescriáÑo ≥Monta o e-mail para Cross-Posting                           ≥±±
±±√ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥±±
±±≥Uso	     ≥Lista de Contatos                                           ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
Static Function TelaEmail(cMensagem,cAssunto,aAttach,cEmail)
	Local oDlgMb
	Local oMens
	Local oSubj
	Local oAttach
	Local nAttach := 0 							// Controle do ListBox
	Local nOpcao  := 0
	Local lRet    := .F.

	cMensagem 	+= Space(100)
	cAttach   	:= ""
	nOpcRet 	:= 0

	while (nOpcRet == 0)
		DEFINE MSDIALOG oDlgMb FROM 05,2 TO 350,530 TITLE "ComposiciÛn del correo "+cAssunto PIXEL
			@ 02, 04 TO  25,260 OF oDlgMb PIXEL
			@ 09, 08 SAY "Para:" OF oDlgMb SIZE 40,8 PIXEL
			@ 09, 32 GET oSubj VAR cEmail OF oDlgMb SIZE 225,8 PIXEL

			@ 27, 04 TO 105,260 LABEL "Mensaje" OF oDlgMb PIXEL

			@ 33, 06 GET oMens VAR cMensagem WHEN .F. OF oDlgMb MEMO SIZE 250,70 PIXEL WHEN .T.

			@ 106,04 TO 155,260 LABEL "" OF oDlgMb PIXEL

			@ 109,06 LISTBOX oAttach VAR nAttach FIELDS HEADER "Anexos" SIZE 250,45 OF oDlgMb PIXEL NOSCROLL
			oAttach:SetArray(aAttach)
			oAttach:Refresh()
			DEFINE SBUTTON FROM 160 ,170 TYPE 3 PIXEL ACTION (RemoveAnexo(@aAttach,@oAttach)) ENABLE OF oDlgMb
			DEFINE SBUTTON FROM 160 ,202 TYPE 2 PIXEL ACTION Eval( {|| nOpcRet := 2, oDlgMb:End() }) ENABLE OF oDlgMb
			DEFINE SBUTTON FROM 160 ,234 TYPE 1 PIXEL ACTION Eval( {|| IIF(ValEmail(cEmail,cMensagem),nOpcRet := 1,nOpcRet := 0),oDlgMb:End()}) ENABLE OF oDlgMb
		ACTIVATE MSDIALOG oDlgMb CENTERED
	enddo

	oMainWnd:Refresh()

	if (nOpcRet == 2)
		Return .F.
	endif
Return .T.

/*/
_____________________________________________________________________________
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
¶¶+-----------------------------------------------------------------------+¶¶
¶¶¶FunÁ‰o    ¶ ValEmail    ¶Autor  ¶Microsiga           ¶ Data ¶07/08/03  ¶¶¶
¶¶+----------+------------------------------------------------------------¶¶¶
¶¶¶DescriÁ‰o ¶Valida o assunto e a mensagem do e-mail                     ¶¶¶
¶¶+----------+------------------------------------------------------------¶¶¶
¶¶¶Uso           ¶Lista de Contatos
¶¶+-----------------------------------------------------------------------+¶¶
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ
/*/
Static Function ValEmail(cEmail,cMensagem)
	Local lRet	:= .F.

	//+---------------------------------------+
	//¶Valida se foi digitada o assunto.      ¶
	//+---------------------------------------+
	if Empty(cEmail)
		Help(" ",1,"SEMEMAIL")
	else
        //+---------------------------------------+
        //¶Valida se foi digitada alguma mensagem.¶
        //+---------------------------------------+
        if Empty(cMensagem)
        	Help(" ",1,"SEMMENSAGE")
        else
 			lRet := .T.
        endif
	endif
Return(lRet)
/*/
________________________________________________________________________________
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
¶¶+---------------------------------------------------------------------------¶¶
¶¶¶FunÁ‰o    ¶ RemoveAnexo ¶  Autor  ¶Rafael M. Quadrotti    ¶ Data ¶07/08/03 ¶¶
¶¶+----------+----------------------------------------------------------------¶¶
¶¶¶DescriÁ‰o ¶Remove o Anexo de arquivos para o email                         ¶¶
¶¶+----------+----------------------------------------------------------------¶¶
¶¶¶Uso           ¶Lista de Contatos                                           ¶¶
¶¶+---------------------------------------------------------------------------¶¶
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ
/*/
Static Function RemoveAnexo(aAttach,oAttach)
	if Len(aAttach) > 0
	   ADel(aAttach,oAttach:nAt)  			// deleta o item
	   ASize(aAttach, Len(aAttach) - 1) 	//redimensiona o array
	endif

	oAttach:SetArray(aAttach)
	oAttach:Refresh()
Return .T.


/*
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫Programa  ≥AjustaSX1 ∫Autor  ≥Bruno Daniel Borges ∫ Data ≥ 17/03/2008  ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ Signature                                                  ∫±±
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
*/
Static Function AjustaSX1()
/*⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
  ≥ Verifica as perguntas selecionadas ≥
  ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ*/
	Local aRegs := {}
	Local cPerg := "EFAT002R"

	aAdd(aRegs,{cPerg,"01","De Fecha          ","De Fecha          ","De Fecha          ","mv_ch1","D", 08,0,2,"G","","mv_par01","","","","'01/04/09'","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"02","A Fecha           ","A Fecha           ","A Fecha           ","mv_ch2","D", 08,0,2,"G","","mv_par02","","","","'31/12/09'","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"03","De Serie          ","De Serie          ","De Serie          ","mv_ch3","C", 03,0,2,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"04","A Serie           ","A Serie           ","A Serie           ","mv_ch4","C", 03,0,2,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"05","De Factura        ","De Factura        ","De Factura        ","mv_ch5","C", 10,0,2,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"06","A Factura         ","A Factura         ","A Factura         ","mv_ch6","C", 10,0,2,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AAdd(aRegs,{cPerg,"07","Tipo de Documento ","Tipo de Documento ","Tipo de Documento ","mv_ch7","N", 01,0,1,"C","","mv_par07","Factura - NF","Factura - NF","Factura - NF","","","Nota de Credito - NCC","Nota de Credito - NCC","Nota de Credito - NCC","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"08","Entrada o Salida  ","Entrada o Salida  ","Entrada o Salida  ","mv_ch8","N", 01,0,1,"C","","mv_par08","Salida","Salida","Salida","","","Entrada","Entrada","Entrada","","","","","","","","","","","","","","","","","",""})

	LValidPerg( aRegs )

Return

/*/
______________________________________________________________________________
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
¶¶+------------------------------------------------------------------------+¶¶
¶¶¶Funcao    ¶ FATM01GZHE    ¶ Autor ¶ Jader            ¶ Data ¶ 12/set/06 ¶¶¶
¶¶+----------+-------------------------------------------------------------¶¶¶
¶¶¶Descricao ¶ Grava arquivo de log para envio do WF                       ¶¶¶
¶¶+----------+-------------------------------------------------------------¶¶¶
¶¶¶Uso       ¶ Exclusivo MICROSIGA.										   ¶¶¶
¶¶+----------+-------------------------------------------------------------¶¶¶
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ
/*/

Static Function FATM01GZHE(cRPS, cSerie, cParcela, cCliente, cLoja, cEMail01, cEMail02, cEMail03)

Local aAliasAnt := GetArea()

dbSelectArea("ZHE")

ZHE->( RecLock('ZHE', .T. ) )
ZHE->ZHE_TEMAIL := '01'
ZHE->ZHE_TPLINK := 'EN'
ZHE->ZHE_EMPRES := cEmpAnt
ZHE->ZHE_RPS    := cRPS
ZHE->ZHE_SERIE  := cSerie
ZHE->ZHE_PARCEL := cParcela
ZHE->ZHE_CLIENT := cCliente
ZHE->ZHE_LOJA   := cLoja
ZHE->ZHE_DATA   := Date()
ZHE->ZHE_HORA   := Time()

If (FieldPos('ZHE_SEQMEM') > 0)
	MSMM(,78,,cEMail01 + ';' + cEMail02 + ';' + cEMail03,1,,,"ZHE","ZHE_SEQMEM")
EndIf

ZHE->( MsUnLock() )

RestArea(aAliasAnt)

Return Nil

Static Function BtCan(cCad,cDoc,cSerie)
Local cTemp := ""
Local cRet := ""
Local nX := 0
Local nTipoMon := 0
Local cSali := ""

If mv_par08 == 1 //Si es Factura de Salida
	nTipoMon := SF2->F2_MOEDA
ELSE
	nTipoMon := SF1->F1_MOEDA
ENDIF

cRet  := Extenso( Val(cCad) ,      , nTipoMon ,        , IIF(nTipoMon ==1 .or. nTipoMon ==4 .or. nTipoMon ==5 ,"2","3") , 	 , .T. ,       , "2" )

Return (cRet)


/*
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫Programa  ≥fGnBoxHead ∫Autor  ≥Cleverson Schaefer  ∫ Data ≥  18/10/12   ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Desc.     ≥ Rutina para generar rectangulo llenado y con su texto       ∫±±
±±∫          ≥                                                             ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ Microsiga Mexico                                            ∫±±
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
*/

Static Function fGnBoxHead(nLinIni, nColIni, nTamBox, cTexBox)
**************************************************************

	nAltBox		:= 45
	nITextLin	:= 30
	nITextCol	:= 10

	oPrint:Fillrect( {nLinIni + 1 ,;
					  nColIni + 1 ,;
					  nLinIni + 1 + nAltBox ,;
					  nColIni + 1 + nTamBox };
					  ,oBrushGray, "-2")

	oPrint:Say( nLinIni + 1 + nITextLin,;
				nColIni + 1 + nITextCol,;
				cTexBox,;
				oArial09N,,CLR_WHITE,,2)

Return
/*
Static Function fGnBoxHead2(nLinIni, nColIni, nTamBox, cTexBox)
**************************************************************

	nAltBox		:= 45
	nITextLin	:= 30
	nITextCol	:= 10

	oPrint:Fillrect( {nLinIni + 1 ,;
					  nColIni + 1 ,;
					  nLinIni + 1 + nAltBox ,;
					  nColIni + 1 + nTamBox };
					  ,oBrushGray, "-2")

	oPrint:Say( nLinIni + 1 + nITextLin,;
				nColIni + 1 + nITextCol,;
				cTexBox,;
				oArial06,,CLR_WHITE,,2)

Return
*/

/*
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫Programa  ≥fGnBoxDet ∫Autor  ≥Cleverson Schaefer  ∫ Data ≥  18/10/12    ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Desc.     ≥ Rutina para generar rectangulo vacion que ser· llenado con  ∫±±
±±∫          ≥ la clase SAY()                                              ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ Microsiga Mexico                                            ∫±±
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
*/

Static Function fGnBoxDet(nLinIni, nColIni, nTamBox, nAltBox)
*************************************************************
	oPrint:Box( nLinIni + 2,;
				nColIni + 1,;
				nLinIni + 2 + nAltBox,;
				nColIni + 1 + nTamBox)

Return

// Funcion que muestra una ventana donde se puede informar las observaciones de la factura
// 30/01/2013 Filiberto Perez
STATIC Function InfObsFT(cDoc, cSerie)
	Local	nbansal		:=0
	PUBLIC   cObserva    := cObservaciones
	PUBLIC 	oDlg

	define msDialog oDlg title 'Observaciones de la factura ' from 00,00 to 150,600 pixel
	@ 003,003 GET oObserva VAR cObserva OF oDlg MULTILINE SIZE 267,50 COLORS 0, 16777215 NO VSCROLL PIXEL
	@ 060, 234 BUTTON oBtAceptar PROMPT "Aceptar" SIZE 037, 012 OF oDlg ACTION SaveObs(cDoc, cSerie) PIXEL
	ACTIVATE MSDIALOG oDlg CENTERED

	If nbansal == 0
		cObserva:=""
	Endif
return

STATIC Function SaveObs(cDoc, cSerie)
	cObservaciones := cObserva
	
	if  ( mv_par07 == 1 ) 					// factura
		DbSelectArea("SF2")
		DbSetOrder(1)
		DbSeek( xFilial("SF2") + cDoc + cSerie ) // B˙squeda exacta
		IF Found() // Eval˙a la devoluciÛn del ˙ltimo DbSeek realizado
			RecLock("SF2",.F.)
			SF2->F2_OBS := Alltrim(cObservaciones)
			MsUnLock() // Confirma y finaliza la operaciÛn
		ENDIF
	elseif ( mv_par07 == 2 ) 				// CREDITO
		DbSelectArea("SF1")
		DbSetOrder(1)
		DbSeek( xFilial("SF1") + cDoc + cSerie ) // B˙squeda exacta
		IF Found() // Eval˙a la devoluciÛn del ˙ltimo DbSeek realizado
			RecLock("SF1",.F.)
			SF1->F1_OBS := Alltrim(cObservaciones)
			MsUnLock() // Confirma y finaliza la operaciÛn
		ENDIF
	endif

	oDlg:End()
RETURN

// FPB FUNCION QUE GENERA LOS ITULOS DE LAS COLUMNAS CENTRALIZADOS.
Static Function fGnBoxCe(nLinIni, nColIni, nTamBox, cTexBox)

	nAltBox	:= 45
	nITextLin	:= 30
	nITextCol	:= 10
/*
	oPrint:Box( nLinIni + 2,;
				nColIni + 1,;
				nLinIni + 2 + nAltBox,;
				nColIni + 1 + nTamBox)
*/
	oPrint:Fillrect( {nLinIni + 1 ,;
					  nColIni + 1 ,;
					  nLinIni + 1 + nAltBox ,;
					  nColIni + 1 + nTamBox };
					  ,oBrushGray, "-2")

	oPrint:Say( nLinIni + 1 + nITextLin,;
				nColIni + 1 + nITextCol,;
				cTexBox,;
				oArial08N,,CLR_WHITE,,2)

/*
nRow 		NumÈrico 	Indica a coordenada vertical em pixels ou caracteres. X
nCol 		NumÈrico 	Indica a coordenada horizontal em pixels ou caracteres. X
cText 		Caracter 	Indica o texto que ser· impresso. X
oFont 		Objeto 		Indica o objeto do tipo TFont utilizado para definir as caracterÌsticas da fonte aplicada na exibiÁ„o do conte˙do do controle visual.
nWidth 		NumÈrico 	Indica a largura em pixels do objeto.
nHeigth 	NumÈrico 	Indica a altura em pixels do objeto.
nClrText 	NumÈrico 	Indica a cor do texto do objeto.
nAlignHorz 	NumÈrico 	Alinhamento Horizontal. Para mais informaÁıes sobre os alinhamentos disponÌveis, consulte a ·rea ObservaÁıes.
nAlignVert 	NumÈrico 	Alinhamento Vertical. Para mais informaÁıes sobre os alinhamentos disponÌveis, consulte a ·rea ObservaÁıes.

Tabela de cÛdigos de alinhamento horizontal.
ï0 - Alinhamento ‡ esquerda;
ï1 - Alinhamento ‡ direita;
ï2 - Alinhamento centralizado

Tabela de cÛdigos de alinhamento vertical.
ï0 - Alinhamento centralizado;
ï1 - Alinhamento superior;
ï2 - Alinhamento inferior
*/
Return

/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫Programa  ≥fJustTex  ∫ Autor ≥Reginaldo G.ribeiro ∫ Data ≥  23/04/15   ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Descricao ≥ FunÁ„o para deixar o Texto Justificado                     ∫±±
±±∫          ≥                                                            ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ Generico                                                   ∫±± 
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Parametro ≥ cmemo = texto a ser justificado                            ∫±± 
±±∫          ≥ nlen  = tamanho liite da linha do texto                    ∫±± 
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
User FUNCTION fJustTex(cMemo, nLen)
LOCAL nLin, cLin, lInic, lFim
Local aWords:={}
Local cNovo:=""
Local cWord, lContinua, nTotLin

   lInic:=.T.
   lFim:=.F.
   nTotLin:=MLCOUNT(cMemo, nLen)
   FOR nLin:=1 TO nTotLin

      cLin:=RTRIM(MEMOLINE(cMemo, nLen, nLin)) //recuperar

      IF EMPTY(cLin) //Uma linha em branco ->Considerar um par†grafo vazio
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

/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫Programa  ≥fJustTex  ∫ Autor ≥Reginaldo G.ribeiro ∫ Data ≥  23/04/15   ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Descricao ≥ FunÁ„o Calcula espacos necessarios para completar a linha  ∫±±
±±∫          ≥                                                            ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ Generico                                                   ∫±± 
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Parametro ≥nQt  = quantidade de separacoes que devem existir           ∫±± 
±±∫          ≥nTot = total de caracteres em branco excedentes a serem     ∫±± 
±±∫          ≥distribuidos                                                ∫±± 
±±∫          ≥nPos = a posicao de uma separacao em particular (comecando do zero) ∫±± 
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
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

/*FUNCION PARA ACTUALIZAR APROBADORES*/
STATIC FUNCTION APROBADO(cDoc, cSerie)

//13-JULIO-2015 SOLICITUD DE AMPLIACION DE 35 A 80 CARACTERES EN APROBADOR Y EMPRESA
Local oButton1
Public oGet1
Public cGet1 := PADR( ALLTRIM(SF2->F2_APROB1) ,80 ) //SPACE(35)
Public oGet2
Public cGet2 := PADR( ALLTRIM(SF2->F2_CARGO1) ,80 ) //SPACE(35)
Public oGet3
Public cGet3 := PADR( ALLTRIM(SF2->F2_EMPRES1) ,35 ) //SPACE(35)
Public oGet4
Public cGet4 := PADR( ALLTRIM(SF2->F2_APROB2) ,80 ) //SPACE(35)
Public oGet5
Public cGet5 := PADR( ALLTRIM(SF2->F2_CARGO2) ,80 ) //SPACE(35)
Public oGet6
Public cGet6 := PADR( ALLTRIM(SF2->F2_EMPRES2) ,35 ) //SPACE(35)
Public oGet7
Public cGet7 := PADR( ALLTRIM(SF2->F2_APROB3) ,80 ) //SPACE(35)
Public oGet8
Public cGet8 := PADR( ALLTRIM(SF2->F2_CARGO3) ,80 ) //SPACE(35)
Public oGet9
Public cGet9 := PADR( ALLTRIM(SF2->F2_EMPRES3) ,35 ) //SPACE(35)
Public oGet10
Public cGet10 := PADR( ALLTRIM(SF2->F2_APROB4) ,80 ) //SPACE(35)
Public oGet11
Public cGet11 := PADR( ALLTRIM(SF2->F2_CARGO4) ,80 ) //SPACE(35)
Public oGet12
Public cGet12 := PADR( ALLTRIM(SF2->F2_EMPRES4) ,35 ) //SPACE(35)

Public oGroup1
Public oGroup2
Public oGroup3
Public oGroup4

Public oSay1
Public oSay2
Public oSay3
Public oSay4
Public oSay5
Public oSay6
Public oSay7
Public oSay8
Public oSay9
Public oSay10
Public oSay11
Public oSay12

PUBLIC oDlg

  DEFINE MSDIALOG oDlg TITLE "ConfirmaciÛn Aprobadores" FROM 000, 000  TO 500, 500 COLORS 0, 16777215 PIXEL

    @ 006, 006 GROUP oGroup1 TO 057, 241 PROMPT "  Aprobador 1  " OF oDlg COLOR 0, 16777215 PIXEL
    @ 017, 012 SAY oSay1 PROMPT "Nombre:" SIZE 097, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 030, 012 SAY oSay2 PROMPT "Cargo:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 042, 012 SAY oSay3 PROMPT "Empresa:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 016, 047 GET oGet1 VAR cGet1 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 028, 047 GET oGet2 VAR cGet2 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 041, 047 GET oGet3 VAR cGet3 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 061, 006 GROUP oGroup2 TO 113, 241 PROMPT "  Aprobador 2  " OF oDlg COLOR 0, 16777215 PIXEL
    @ 073, 012 SAY oSay4 PROMPT "Nombre:" SIZE 097, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 085, 012 SAY oSay5 PROMPT "Cargo:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 098, 012 SAY oSay6 PROMPT "Empresa:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 071, 047 GET oGet4 VAR cGet4 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 084, 047 GET oGet5 VAR cGet5 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 096, 047 GET oGet6 VAR cGet6 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 118, 006 GROUP oGroup3 TO 169, 241 PROMPT "  Aprobador 3  " OF oDlg COLOR 0, 16777215 PIXEL
    @ 129, 012 SAY oSay7 PROMPT "Nombre:" SIZE 097, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 142, 012 SAY oSay8 PROMPT "Cargo:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 154, 012 SAY oSay9 PROMPT "Empresa:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 128, 047 GET oGet7 VAR cGet7 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 140, 047 GET oGet8 VAR cGet8 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 153, 047 GET oGet9 VAR cGet9 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 173, 006 GROUP oGroup4 TO 225, 241 PROMPT "  Aprobador 4  " OF oDlg COLOR 0, 16777215 PIXEL
    @ 185, 012 SAY oSay10 PROMPT "Nombre:" SIZE 097, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 197, 012 SAY oSay11 PROMPT "Cargo:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 210, 012 SAY oSay12 PROMPT "Empresa:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 183, 047 GET oGet10 VAR cGet10 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 196, 047 GET oGet11 VAR cGet11 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 208, 047 GET oGet12 VAR cGet12 SIZE 187, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 232, 200 BUTTON oButton1 PROMPT "Confirmar" SIZE 037, 012 OF oDlg ACTION GrvAprob() PIXEL
    //@ 072, 084 BUTTON oButton1 PROMPT "Confirmar" SIZE 037, 012 OF oDlg ACTION CONFIRMA(cGet1) PIXEL
    //@ 052, 143 BUTTON oButton1 PROMPT "Confirmar" SIZE 046, 012 OF oDlg ACTION INCPEDIDO() PIXEL

  ACTIVATE MSDIALOG oDlg CENTERED

                
RETURN

Static Function GrvAprob()

//msgalert("grabacion en tabla")

DbSelectArea("SF2")
DbSetOrder(1) 
DbSeek( xFilial("SF2") + F2_DOC + F2_SERIE ) // B˙squeda exacta

IF Found() // Eval˙a la devoluciÛn del ˙ltimo DbSeek realizado
	RecLock("SF2",.F.)
		SF2->F2_APROB1	:= ALLTRIM(cGet1)
		SF2->F2_CARGO1	:= ALLTRIM(cGet2)
		SF2->F2_EMPRES1	:= ALLTRIM(cGet3)
		SF2->F2_APROB2	:= ALLTRIM(cGet4)
		SF2->F2_CARGO2	:= ALLTRIM(cGet5)
		SF2->F2_EMPRES2	:= ALLTRIM(cGet6)
		SF2->F2_APROB3	:= ALLTRIM(cGet7)
		SF2->F2_CARGO3	:= ALLTRIM(cGet8)
		SF2->F2_EMPRES3	:= ALLTRIM(cGet9)
		SF2->F2_APROB4	:= ALLTRIM(cGet10)
		SF2->F2_CARGO4	:= ALLTRIM(cGet11)
		SF2->F2_EMPRES4	:= ALLTRIM(cGet12)
	MsUnLock() // Confirma y finaliza la operaciÛn
ENDIF

oDlg:End()                     
Return
