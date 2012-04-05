#include <GUIConstantsEx.au3>
#include <file.au3>
#include <Array.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#Include <GuiMenu.au3>


;#Include <Misc.au3>;for _IsPressed

#Region version and program info
Global Const $g_info_version = "0.4.7"
Global Const $g_info_author = "Trevor Pearson"
Global Const $g_info_parameters = "none: just input file chosen via gui"
Global Const $g_info_instructions = "This program reads a txt file and will type strings for the user.  Basically, it semi-automate complex tasks.  Prompts are also inputed from the file to explain what to do next."
if $CmdLine[0] == 1 Then
	if $CmdLine[1] == "/?" Then
		displyInfo()
		Exit
	EndIf
EndIf
#EndRegion

dim $HK_send = "^w"
dim $HK_inc = "^e"
dim $HK_dec = "^q"


Global $zoomPath

$zoomPath = RegRead("HKEY_CURRENT_USER\Software\Zoom","zoomPath")
if $zoomPath =="" Then
	RegWrite("HKEY_CURRENT_USER\Software\Zoom","zoomPath","REG_SZ",$zoomPath)
	$zoomPath = InputBox("Zoom","Define your new zoom folder","J:\zoom")
	if $zoomPath == "" Then
		Exit
	EndIf	
EndIf
if FileExists($zoomPath) == 0 Then
	if DirCreate($zoomPath)==0 Then
		MsgBox(0,"ERROR","Failed to create directory: "&$zoomPath)
		Exit
	EndIf		
EndIf

FileExtAssoc("zoo", "C:\zoom\zoom.exe %1")


Global $fileName = $zoomPath&"\pugsUpgrade.zoo"
;$dll = DllOpen("user32.dll")
dim $fileVersion = 0

;##### V2 Variables #######;
dim $cmdString = ""
dim $pmtString = ""
dim $exeString = ""
dim $cmdNum = 1
Global $cmdNumbers[1]
Global $jumpLines[1]
Global $fileChanged = 0
$cmdNumbers[0] = 0
$jumpLines[0] = 0
dim $var1Label = "testLabel"
dim $var1On = 0
Global $menujump_link[10]
Global $menujump = GUICtrlCreateMenu("Jump to...")
;##########################;

Global $newFileText ="zoomVersion=2"&@CRLF&"*nextCommand*"&@CRLF&"pmt=created new file: input the task here"&@CRLF&"STR=insert the text to be copied here"
Global $astrings
Global $x = 1
Global $aSize = 0

Global $GUI_zoom
Global $GUI_zoomPre

;####### Commands options #########;
Global $cmdTypes[4] = ["STR","RUN","CPY","RMV"]

;####### Phases ###########;
Global $phase1 = 1
Global $phase2 = 0
;##########################;

Global $cmd_lastChecked = "~notSet~"
Global $pmt_lastChecked = "~notSet~"

;#### OPTIONS #####
$OPTION_alwaysSave = False
;##################

;#### MODES ####
global $modeSwitch = 0
global $modes = StringSplit("", ",")
Global $currentMode = 0
global $modeList[10][5]
global $modeCount = 0
;##################

opt("GUIOnEventMode",1)



if $CmdLine[0] == 1 and FileExists($CmdLine[1]) Then
;~ 	MsgBox(0,"garrr",$CmdLine[1])
	$fileName = $CmdLine[1]
	;im guessing a batch file called this
	if WinExists("ZOOM CMD Window") Then
		WinClose("ZOOM CMD Window")
	EndIf
	
	zoomMain()
Else
	zoomPre()
EndIf



	while 1
		cmdChange()
		taskChange()
		sleep(100)
	WEnd


;##################
;#Global Functions#
;##################

Func updateGui()
	if $fileVersion == 1 Then
;~ 		MsgBox(0,"file version is",$fileVersion)
		updateGui1()
	ElseIf $fileVersion == 2 Then
;~ 		MsgBox(0,"file version is",$fileVersion)
		updateGui2()
	Else
		MsgBox(0,"ERROR: updateGui Function","File Version not supported")
	EndIf
EndFunc

Func exitButton()
;~ 	MsgBox(0,"exit button!","grr")
	if $fileVersion == 1 Then
;~ 		MsgBox(0,"file version is",$fileVersion)
		exitButton1()
	ElseIf $fileVersion >= 2 Then		
;~ 		MsgBox(0,"file version is",$fileVersion)
		exitButton2()
	Else
		Exit
	EndIf
EndFunc

Func saveZoom() ;save the zoom file
	
	If Not _FileWriteFromArray($fileName,$astrings,1) Then
		MsgBox(4096,"Error", " Error writing array to file     error:" & @error)
	EndIf
	$fileChanged = 0
	GUICtrlSetState($menuitem_save, $GUI_DISABLE)

EndFunc
Func saveAsZoom()
	
EndFunc
Func alwaysSaveOption() ;turn the alwaysSave option on
	if $OPTION_alwaysSave Then	
		GUICtrlSetState($menuitem_alwaysSave, $GUI_UNCHECKED)
		GUICtrlSetState($guiWritePmt, $GUI_SHOW)
		GUICtrlSetState($guiWriteCmd, $GUI_SHOW)
		$OPTION_alwaysSave = False
	Else
		GUICtrlSetState($menuitem_alwaysSave, $GUI_CHECKED)		
		GUICtrlSetState($guiWritePmt, $GUI_HIDE)
		GUICtrlSetState($guiWriteCmd, $GUI_HIDE)
		$OPTION_alwaysSave = True
	EndIf
	saveCurrentPage()
	GUICtrlSetBkColor($guiWritePmt,0xF2F2ED  )
	GUICtrlSetBkColor($guiWriteCmd,0xF2F2ED  )
EndFunc
Func saveCurrentPage() ; save the current visible page
	saveCmd2()
	savePmt2()
EndFunc

Func displyInfo()
	MsgBox(0,"INFO","Created by: " & $g_info_author & @CRLF &"Version " & $g_info_version & @CRLF & $g_info_parameters & @CRLF & $g_info_instructions)


EndFunc





#Region GUI Functions (Var1Toggle,TaskChange,cmdChange,changeZoomPath)
Func displayHelp()
	
;~ 	dim $HK_send = "^w"
;~ 	dim $HK_inc = "^e"
;~ 	dim $HK_dec = "^q"
	$hokeyString = "Hotkeys:"&@CRLF&"{ctrl}w  : Paste Command String and Go to Next Task"&@CRLF&"{ctrl}e  : Skip to Next Task"&@CRLF&"{ctrl}q  : Go back a Task"&@CRLF&@CRLF&"The different command types are"&@CRLF&"STR - this just types the string in"&@CRLF&"RUN - this runs the program just like a cmd line"&@CRLF&"CPY - This copies 1 file to another spot, use > in the center"&@CRLF&"RMV - This Removes the specified file. Be careful this accepts a * arg"
	$helpString = "Zoom is a program created to help automate simple and complex tasks.  It may be hard to get use to at first but can help quite a bit" &@CRLF
	
	MsgBox(0,"Zoom Help",$helpString &@CRLF& $hokeyString)



EndFunc

Func var1Toggle()
	if $var1On == 0 Then
		$var1On = 1
	Else
		$var1On = 0
	EndIf
	
	
	if $var1On == 0 Then
		$fileChanged = 1
		GUICtrlSetState($menuitem_save, $GUI_ENABLE)
		_ArrayDelete($astrings,2)
		$astrings[0] -=1
		$aSize = $astrings[0]

	;~ 	MsgBox(0,"astrings Size",$astrings[0])
	
		GUICtrlSetState($guiVar1Input,$GUI_HIDE)
		GUICtrlSetState($guiVar1Label,$GUI_HIDE)
		GUICtrlSetState($guiVar1preLabel,$GUI_HIDE)

		
;~ 		GUICtrlSetState($guiVar1Toggle,$GUI_SHOW)
		
	Else
		$varName = InputBox("Zoom","enter the new Vars name","var1")
		_ArrayInsert($astrings,2,"var1="&$varName)
		GUICtrlSetState($menuitem_save, $GUI_ENABLE)
		$fileChanged = 1
		
		$astrings[0] +=1
		$aSize = $astrings[0]
		GUICtrlSetState($guiVar1Input,$GUI_SHOW)
		GUICtrlSetState($guiVar1Label,$GUI_SHOW)
		GUICtrlSetState($guiVar1preLabel,$GUI_SHOW)
		
		GUICtrlSetData($guiVar1Label,$varName)
		
;~ 		GUICtrlSetState($guiVar1Toggle,$GUI_HIDE)
		
	EndIf
EndFunc

Func taskChange()
	if $phase2 ==1 Then  ;$pmt_lastChecked
		if StringCompare($pmt_lastChecked,GUICtrlRead($guiTask)) Then
			if StringCompare(StringTrimLeft($astrings[$x+1],4),GUICtrlRead($guiTask))==0 Then
				
				If $OPTION_alwaysSave == True Then
					savePmt2()
				Else
					GUICtrlSetBkColor($guiWritePmt,0xF2F2ED  )
				EndIf					
			Else
				
				If $OPTION_alwaysSave == True Then
					savePmt2()
				Else
					GUICtrlSetBkColor($guiWritePmt,0xff0000)
				EndIf	
			EndIf
		$pmt_lastChecked = GUICtrlRead($guiTask)		
		EndIf
	EndIf
EndFunc
Func cmdChange()
   
   
   if $phase2 ==1 Then
	  local $currentCmd = GUICtrlRead($guiComboCmdTypes)
	  local $prevCmd = StringLeft($astrings[$cmdNumbers[$cmdNum]+2],3)
;~ 		MsgBox(0,"grr",GUICtrlRead($guiTask))
		if StringCompare($cmd_lastChecked,$currentCmd&"="&GUICtrlRead($guiCmd)) Then
			if StringCompare($astrings[$x+2],$currentCmd&"="&GUICtrlRead($guiCmd))==0 Then
				
				If $OPTION_alwaysSave == True Then
					saveCmd2()
				Else
					GUICtrlSetBkColor($guiWriteCmd,0xF2F2ED)
				EndIf				
			Else
				
				If $OPTION_alwaysSave == True Then
					saveCmd2()
				Else
					GUICtrlSetBkColor($guiWriteCmd,0xff0000)
				EndIf	
			EndIf
		$cmd_lastChecked = $currentCmd&"="&GUICtrlRead($guiCmd)				
		EndIf
	EndIf
EndFunc

Func changeZoomPath()
	
	$zoomPath_old = $zoomPath
	
	$zoomPath = InputBox("Zoom","Define your new zoom folder",$zoomPath_old)
	While $zoomPath == ""
		$zoomPath = InputBox("Zoom","You must define a zoom folder",$zoomPath_old)
	WEnd	
	$fileName = $zoomPath & StringTrimLeft($fileName,stringlen($zoomPath_old))
	if FileExists($zoomPath) == 0 Then
		if DirCreate($zoomPath)==0 Then
			MsgBox(0,"ERROR","Failed to create directory: "&$zoomPath)
			Exit
		EndIf		
	EndIf
	RegWrite("HKEY_CURRENT_USER\Software\Zoom","zoomPath","REG_SZ",$zoomPath)

EndFunc

#EndRegion

#Region Operations (Initialize,Paste,Next,Previous,insert,delete,save,update,exit)
func initialize2()
	
	local $count = 0
	while $cmdNumbers[0] > 0
		_ArrayPop($cmdNumbers)
		$cmdNumbers[0] -=1
	WEnd
	while $jumpLines[0] > 0
		_ArrayPop($jumpLines)
		$jumpLines[0] -=1
	WEnd
	
	
	while $count <= $aSize
		if StringLeft($astrings[$count],13) == "*nextCommand*" then
			_ArrayAdd($cmdNumbers, $count)
			$cmdNumbers[0] +=1 ;inc the size
			if stringinstr($astrings[$count],"jump=") Then
			   $jumpLines[0] +=1
;~ 			   _ArrayAdd($jumpLines,$count&":"&StringTrimLeft($astrings[$count],19))
			   _ArrayAdd($jumpLines,$cmdNumbers[0]&":"&StringTrimLeft($astrings[$count],19))
			EndIf
			
		EndIf
		$count +=1
	WEnd

	if $cmdNumbers[0] < 1 Then
		MsgBox(0,"ERROR","no commands found")
		Exit
	EndIf
	
	loadJumpMenu()
	
EndFunc

Func pasteNext2()
	;disable hotkeys	
	HotKeySet($HK_send)
	HotKeySet($HK_dec)
	HotKeySet($HK_inc)
	
	local $sendString = GUICtrlRead($guiCmd)
	
	if $var1On == 1 And StringInStr($sendString,"*var1*") Then
		$sendString = StringReplace($sendString,"*var1*",GUICtrlRead($guiVar1Input))
	EndIf
	
	for $icount = 0 To $modeCount-1
		for $jcount = 0 to $modes[0]-1
			$sendString = stringReplace($sendString,"$"&$modeList[$icount][$jcount],$modeList[$icount][$jcount],0,1)
		Next
	Next
	
	send("{CTRLDOWN}")
	send("{CTRLUP}")
		
   
   if GUICtrlRead($guiComboCmdTypes) == "RUN" Then
		Run($sendString)		
   ElseIf GUICtrlRead($guiComboCmdTypes)== "CPY" Then
		$stringSplit = StringSplit($sendString,">")
		if $stringSplit[0] == 2 Then		
			if FileCopy($stringSplit[1],$stringSplit[2],1) ==0 Then
			   MsgBox(0,"ZOOM Copy","File Copy Failed: "&$sendString)
			EndIf
			
		Else
			MsgBox(0,"invalid copy command", "args should be split with '>' symbol once and only once")
		EndIf
		
   ElseIf GUICtrlRead($guiComboCmdTypes)== "RMV" Then
	  if FileDelete($sendString) == 0 Then
		 MsgBox(0,"ZOOM delete","File deletion failed: "&$sendString)
	  EndIf
		
   Else
		Send($sendString) ;grab the cmd one	
   EndIf
	
	
	forward2()
	
	;enable hotkeys
	HotKeySet($HK_send,"pasteNext"&$fileVersion)
	HotKeySet($HK_dec,"back"&$fileVersion)
	HotKeySet($HK_inc,"forward"&$fileVersion)

EndFunc


Func forward2()
	$cmdNum +=1
	if $cmdNum > $cmdNumbers[0] Then
		$cmdNum = $cmdNumbers[0]
		send("{CTRLUP}")
		Return 1
	EndIf
	
	updateGui()	
;~ 	send("{CTRLDOWN}")
	send("{CTRLUP}")

EndFunc
	
Func back2()
	$cmdNum -=1
	if $cmdNum < 1 Then
		$cmdNum = 1
		send("{CTRLUP}")
		Return 1
	EndIf
	
	updateGui()	
	send("{CTRLUP}")

EndFunc

Func updateGui2()
;~ 	MsgBox(0,"cmdnum",$cmdNum)
	$x = $cmdNumbers[$cmdNum]
	
	$pmtString = ""
	$cmdString = ""
	$exeString = ""
	
	if $x+2 <= $astrings[0] Then
		$pmtString = StringTrimLeft($astrings[$x+1],4)
		$cmdString = StringTrimLeft($astrings[$x+2],4)
	EndIf
	
   GUICtrlSetData($guiComboCmdTypes, StringLeft($astrings[$x+2],3),StringLeft($astrings[$x+2],3)) 
	  
	
	;$modes[0] is the number of mode types (pugs, dugs, tugs)
;~ 	$modeList
	for $icount = 0 To $modeCount-1
		for $jcount = 0 to $modes[0]-1
			$pmtString = stringReplace($pmtString,"$"&$modeList[$icount][$jcount],"$"&$modeList[$icount][$currentMode],0,1)
			$cmdString = stringReplace($cmdString,"$"&$modeList[$icount][$jcount],"$"&$modeList[$icount][$currentMode],0,1)
		Next
	Next
	
	
	GUICtrlSetData ( $guiTask, $pmtString )
	GUICtrlSetData ( $guiCmd, $cmdString )		
	GUICtrlSetData ( $guiCmdNum, $cmdNum &" of " & $cmdNumbers[0])		
EndFunc


Func savePmt2()
	$astrings[$x+1] = "pmt="&GUICtrlRead($guiTask)
	$fileChanged = 1
	GUICtrlSetState($menuitem_save, $GUI_ENABLE)
	
	$pmt_lastChecked="~notSet~"
EndFunc

Func saveCmd2()
	$astrings[$x+2] = GUICtrlRead($guiComboCmdTypes)&"="&GUICtrlRead($guiCmd)
	$fileChanged = 1
	GUICtrlSetState($menuitem_save, $GUI_ENABLE)
	$cmd_lastChecked = "~notSet~"
EndFunc


Func insertCmdBefore2()
	$fileChanged = 1
	GUICtrlSetState($menuitem_save, $GUI_ENABLE)
	;keep $cmdNum the same so you can insert the new text
;~ 	MsgBox(0,"astrings Size",$astrings[0])
	_ArrayInsert($astrings,$x,"*nextCommand*")
	_ArrayInsert($astrings,$x+1,"pmt=")
	_ArrayInsert($astrings,$x+2,"STR=")
	
	$astrings[0] +=3
	$aSize = $astrings[0]
;~ 	MsgBox(0,"astrings Size",$astrings[0])
	initialize2()
	updateGui2()
EndFunc

Func insertCmdAfter2()
	$fileChanged = 1
	GUICtrlSetState($menuitem_save, $GUI_ENABLE)
	;keep $cmdNum the same so you can insert the new text
;~ 	MsgBox(0,"astrings Size",$astrings[0])
	$x+=3
	_ArrayInsert($astrings,$x,"*nextCommand*")
	_ArrayInsert($astrings,$x+1,"pmt=")
	_ArrayInsert($astrings,$x+2,"STR=")
	
	$astrings[0] +=3
	$aSize = $astrings[0]
;~ 	MsgBox(0,"astrings Size",$astrings[0])
	$cmdNum +=1
	initialize2()
;~ 	MsgBox(0,"cmdnum",$cmdNum)
	updateGui2()
	
EndFunc

Func deleteCmd2()
	$fileChanged = 1
	GUICtrlSetState($menuitem_save, $GUI_ENABLE)
	_ArrayDelete($astrings,$x)
	_ArrayDelete($astrings,$x)
	_ArrayDelete($astrings,$x)
	$astrings[0] -=3
	$aSize = $astrings[0]
	
	initialize2()
	if $cmdNum > $cmdNumbers[0] Then
		$cmdNum = $cmdNumbers[0]
	EndIf
	updateGui2()
EndFunc



Func exitButton2()
	if $fileChanged == 1 and MsgBox(4+32,"Save?","Do you want to save changes?") == 6 Then
			
		If Not _FileWriteFromArray($fileName,$astrings,1) Then
			MsgBox(4096,"Error", " Error writing array to file     error:" & @error)
		else 
			send("{CTRLUP}")
			Exit
		EndIf
	Else
		send("{CTRLUP}")
		Exit
	EndIf
EndFunc

#EndRegion


#Region PreZoom (zoomPre, createNewZoom, loadZoom)
Func zoomPre()
	;### GUI ###
	
	Local $width = 200
	Local $height = 100
;~ 	opt("GUIOnEventMode",1)
	$GUI_zoomPre = GUICreate("Zoom", $width, $height,-1,-1,-1)
	GUICtrlCreateLabel("V. "& $g_info_version,$width-45,0)
;~ 	GUICtrlSetColor(-1,0x7BE239)
	$guiNewTask = GUICtrlCreateButton("Create New Task", $width*2/10,$height/9+5,$width*6/10,$height*3/9)
	$guiLoadTask = GUICtrlCreateButton("Load Task", $width*2/10, $height*5/9+3,$width*6/10,$height*3/9)
;~ 	GUICtrlCreatePic("C:\zoom\logo.jpg",0,0,$width*5/10-5,$height)
;~ 	GUISetBkColor(0x000000)
	
;~ 	GUICtrlSetBkColor($guiNewTask,0x7BE239)
;~ 	GUICtrlSetBkColor($guiLoadTask,0x7BE239)
	GUICtrlSetOnEvent($guiLoadTask,"loadZoom")
	GUICtrlSetOnEvent($guiNewTask,"createNewZoom")
	GUISetOnEvent($GUI_EVENT_CLOSE, "exitButton",$GUI_zoomPre)
	


	GUISetState(@SW_SHOW)

EndFunc

func createNewZoom()
	Local $counter = 1
;~ 	$fileName = "c:\zoom\newzoom.txt"
	$fileName = InputBox("New Zoom File", "Enter the path and name of the new zoom file",$zoomPath&"\newzoom1.zoo")
	if $fileName = "" Then
		return 1
	EndIf
	
	while FileExists($fileName)
		$fileName = InputBox("New Zoom File", "File Exists: try again",$zoomPath&"\newzoom1.zoo")
	

	WEnd
	$file = FileOpen($fileName,1)
	
	;Write the initial stuff
	FileWrite($file,$newFileText)
	
	
	FileClose($file)	
	GUISetOnEvent($GUI_EVENT_CLOSE, "",$GUI_zoomPre)
	GUIDelete($GUI_zoomPre)
	zoomMain()
	
EndFunc

Func loadZoom()
	
	$fileName = FileOpenDialog("ZOOM : Choose Input File",$zoomPath & "\","Text files (*.zoo;*.txt)",3)

	If @error Then
		return @error
	EndIf
	GUISetOnEvent($GUI_EVENT_CLOSE, "",$GUI_zoomPre)
	GUIDelete($GUI_zoomPre)
	zoomMain()
	
EndFunc

#EndRegion
Func zoomMain()
	$phase2 = 1
	$phase1 = 0
	$GUI_width = 510
	$GUI_height = 210

	If Not _FileReadToArray($fileName,$astrings) Then
		if @error == 2 Then
			FileWrite($fileName,$newFileText)
			If Not _FileReadToArray($fileName,$astrings) Then
				if @error Then
					MsgBox(4096,"Error", " Error creating new file and reading log to Array     error:" & @error)	
					Exit
				EndIf
			EndIf
			
		Else
		MsgBox(4096,"Error", " Error reading log to Array     error:" & @error)	
		Exit
		EndIf
	EndIf
	;_ArrayDisplay($astrings, "$avArray set manually 1D")
	$aSize = $astrings[0]
	if $aSize < 2 Then
		
		MsgBox(0,"Error","unknown file format")
		Exit
	EndIf
	;####################
	;#Check file verison#
	;####################
	if stringleft($astrings[1],4) == "pmt=" Then
		$fileVersion = 1
	ElseIf StringLeft($astrings[1],StringLen("zoomVersion=")) == "zoomVersion=" Then
		$fileVersion = StringTrimLeft($astrings[1],StringLen("zoomVersion="))
;~ 		if $astrings[0] > 2 And StringLeft($astrings[2],5) == "var1=" then 
;~ 			$var1On = 1
;~ 			$var1Label = StringTrimLeft($astrings[2],5)
;~ 		EndIf	
		$lineCounter = 0
		While ($lineCounter < $aSize)
			if StringLeft($astrings[$lineCounter],5) == "var1=" then 
				$var1On = 1
				$var1Label = StringTrimLeft($astrings[$lineCounter],5)
			EndIf	
			
			if StringLeft($astrings[$lineCounter],6) == "modes=" then 
				$modeSwitch = 1
				$modes = StringSplit(StringTrimLeft($astrings[$lineCounter],6),"~")
;~ 				MsgBox(0,"after trim",StringTrimLeft($astrings[$lineCounter],6),"~")
;~ 				MsgBox(0,"modesnum",$modes[0])
			elseif StringLeft($astrings[$lineCounter],4) == "mode" then 
				$temp = StringSplit(StringTrimLeft($astrings[$lineCounter],6),"~")
				for $count = 1 To $temp[0]
					$modeList[$modeCount][$count-1] = $temp[$count]
				Next
				$modeCount+=1
			EndIf
			
			if StringInStr($astrings[$lineCounter],"*nextCommand*") Then
				ExitLoop 
			EndIf
			
			$lineCounter+=1
		WEnd
		
		
			
	Else
		MsgBox(0,"ERROR","File Fomat not recognized")
		Exit
	EndIf
	;~ MsgBox(0,"file version is",$fileVersion)
	;~ Exit

	;##############
	;#Initialize###
	;##############
	if $fileVersion > 1 Then
		initialize2()
	EndIf


	AutoItSetOption ( "SendKeyDelay" ,0 )

	HotKeySet($HK_send,"pasteNext"&$fileVersion)
	HotKeySet($HK_dec,"back"&$fileVersion)
	HotKeySet($HK_inc,"forward"&$fileVersion)


	;### GUI ###
;~ 	opt("GUIOnEventMode",0)
;~ 	opt("GUIOnEventMode",1)
	Global $GUI_zoom = GUICreate("Zoom - "& $fileName, $GUI_width, $GUI_height+20,0,0,-1,$WS_EX_TOPMOST)
	$test = GUISetOnEvent($GUI_EVENT_CLOSE, "exitButton",$GUI_zoom)
;~ 	MsgBox(0,"guisetonevent_result",$test)
	GUICtrlCreateLabel("V. "& $g_info_version,450,10)

	GUICtrlCreateLabel("Task:", 30, 50)
	Global $guiTask = GUICtrlCreateEdit("this is my current task", 60, 50,380,60,$ES_MULTILINE)

	GUICtrlCreateLabel("Cmd Number:", 30, 115)
	Global $guiCmdNum = GUICtrlCreateLabel("1234567890", 100, 115) ;10 digit max - i dont think this matters

;~ 	GUICtrlCreateLabel("String:", 30, 140)
;~ 	GUICtrlCreateList("str|run",0,150)
   global $guiComboCmdTypes = GUICtrlCreateCombo("STR",9,140,48)
   local $tempCounter = 0
   while $tempCounter < UBound($cmdTypes)
	  GUICtrlSetData(-1, $cmdTypes[$tempCounter]) 
	  $tempCounter+=1
   WEnd
   
   
	
	Global $guiCmd = GUICtrlCreateEdit("this is my command", 60, 140,380,60,$ES_MULTILINE)
	;GUICtrlSetDefColor($g_color_inQueue)
;~ 	GUICtrlSetOnEvent($guiTask,"taskChange")
;~ 	GUICtrlSetOnEvent($guiCmd,"cmdChange")
	
	;~ GUICtrlCreateButton("OK", 70, 50, 60)

	;~ MsgBox(0,"file version is",$fileVersion)
	updateGui()

   GUICtrlSetOnEvent($guiComboCmdTypes,"cmdChange")
	
	
	Global $guiWritePmt = GUICtrlCreateButton("save",450,70,50,40)
	Global $guiWriteCmd = GUICtrlCreateButton("save",450,140,50,60)
	Global $guiWriteInsB = GUICtrlCreateButton("Insert New Command Before",170,110,145,30)
	Global $guiDelCmd = GUICtrlCreateButton("Delete",315,110,40,30)
	Global $guiWriteInsA = GUICtrlCreateButton("Insert New Command After",355,110,145,30)

	Global $guiVar1preLabel = GUICtrlCreateLabel(" *var1* :",$GUI_width/6,20)	
	Global $guiVar1Input = GUICtrlCreateInput("",$GUI_width/6 +50,15,100)
	Global $guiVar1Label = GUICtrlCreateLabel("12345678901234567",$GUI_width/6+155,20)
	Global $guiVar1Toggle = GUICtrlCreateButton("Toggle Var1",$GUI_width-135,10)
	GUICtrlSetData($guiVar1Label,$var1Label)
	
;~ 	GUICtrlSetLimit($guiVar1Label,10)
	
	if $var1On == 0 Then
		GUICtrlSetState($guiVar1Input,$GUI_HIDE)
		GUICtrlSetState($guiVar1Label,$GUI_HIDE)
		GUICtrlSetState($guiVar1preLabel,$GUI_HIDE)
		
	Else
;~ 		GUICtrlSetState($guiVar1Toggle,$GUI_HIDE)
	EndIf
   
	GUICtrlSetOnEvent ( $guiWritePmt, "savepmt"&$fileVersion)
	GUICtrlSetOnEvent ( $guiWriteCmd, "savecmd"&$fileVersion)
	GUICtrlSetOnEvent ( $guiWriteInsB, "insertCmdBefore"&$fileVersion)
	GUICtrlSetOnEvent ( $guiDelCmd, "deleteCmd"&$fileVersion)
	GUICtrlSetOnEvent ( $guiWriteInsA, "insertCmdAfter"&$fileVersion)
	
	GUICtrlSetOnEvent($guiVar1Toggle,"var1Toggle")


;######## MENU ########
	Global $menufile = GUICtrlCreateMenu("File")
;~ 	Global $menuitem_open = GUICtrlCreateMenuItem("Open", $menufile)
;~ 	GUICtrlSetState(-1, $GUI_DEFBUTTON)
	Global $menuitem_save = GUICtrlCreateMenuItem("Save File", $menufile)
	GUICtrlSetState(-1, $GUI_DISABLE);only enabled when it saves somethin
	Global $menuitem_exit = GUICtrlCreateMenuItem("Exit", $menufile)
	
	
	
	Global $menuoptions = GUICtrlCreateMenu("Options")
	Global $menucommand = GUICtrlCreateMenu("Command")
	Global $menumode = GUICtrlCreateMenu("Mode")
	Global $menuvars = GUICtrlCreateMenu("Vars")	
	
	Global $menuhelp = GUICtrlCreateMenu("Help")
	Global $menuitem_alwaysSave = GUICtrlCreateMenuItem("autoSave Field Changes", $menuoptions)
	Global $menuitem_nextCommand = GUICtrlCreateMenuItem("next command (ctrl+e)", $menucommand)
	Global $menuitem_prevCommand = GUICtrlCreateMenuItem("prev command (ctrl+q)", $menucommand)
	Global $menuitem_runCommand = GUICtrlCreateMenuItem("run command (ctrl+w)", $menucommand)	
	
	
	loadJumpMenu()
	
	;modes
	$tempNum = 0
;~ 	MsgBox(0,"modes",$modes[0])
	Global $modesMenu[6]
	for $count = 1 To $modes[0]
		$modesMenu[$count]=GUICtrlCreateMenuItem( $modes[$count], $menumode)	
		GUICtrlSetOnEvent ( -1, "changeMode"&$count)
	Next
		
	if ($modeSwitch==1) Then
		GUICtrlSetState ( $modesMenu[1], $GUI_CHECKED )
	EndIf
	
   GUICtrlCreateMenuItem( "manageModes", $menumode)	
   GUICtrlSetOnEvent ( -1, "manageModes")
   
	
	Global $menuitem_genHelp = GUICtrlCreateMenuItem("Help", $menuhelp)
;~ 	Global $menuitem_zoomPath = GUICtrlCreateMenuItem("Change Zoom Folder", $menuoptions)
;~ 	GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlSetOnEvent ( $menuitem_alwaysSave, "alwaysSaveOption")
	
	GUICtrlSetOnEvent ( $menuitem_nextCommand, "forward2")
	GUICtrlSetOnEvent ( $menuitem_prevCommand, "back2")
	GUICtrlSetOnEvent ( $menuitem_runCommand, "pasteNext2")
	
	
	GUICtrlSetOnEvent ( $menuitem_genHelp, "displayHelp")
;~ 	GUICtrlSetOnEvent ( $menuitem_zoomPath, "changeZoomPath")
	GUICtrlSetOnEvent ( $menuitem_save, "saveZoom")
	GUICtrlSetOnEvent ( $menuitem_exit, "exitButton")
	
	
	
;~ 	$recentfilesmenu = GUICtrlCreateMenu("Recent Files", $menufile, 1)

;##### End of Menu ####
	GUISetState(@SW_SHOW)

;~ 	while 1
;~ 		sleep(100)
;~ 	WEnd
EndFunc
Func manageModes()
   Local $rowNum = 10
   Local $colNum = 4
   Local $colSep = 120, $rowSep = 30
   Global $guiModes = GUICreate("Zoom - Manage Modes",100+$colSep*$colNum,60+$rowSep*$rowNum)
   Local $columns[5][20]
   Local $col = 0
   Local $row=0
   
   
   While $col <4
	  $row = 0
	  while $row <10
		 if $row==0 Then
			$columns[$col][$row] = GUICtrlCreateInput("Name"&$col,70+($colSep*$col),35+($rowSep*$row),60)
		 ElseIf $row==1 Then
			$columns[$col][$row] = GUICtrlCreateInput("code_"&$col&"_"&$row,50+($colSep*$col),35+($rowSep*$row),100)
		 Else
			$columns[$col][$row] = GUICtrlCreateInput("",50+($colSep*$col),35+($rowSep*$row),100)
		 EndIf
		 $row+=1
		 
	  WEnd
	  $col+=1
   WEnd
	  
   
   
   GUISetState(@SW_SHOW)
   $test = GUISetOnEvent($GUI_EVENT_CLOSE, "exitModes",$guiModes)
   
   $guiModes_info = GUICtrlCreateLabel("Mode Special Prefix Character: $",50,10)
   $guuiModes_save = GUICtrlCreateButton("Save Modes",245,330)
   GUICtrlSetOnEvent(-1,"modes_saveArray")
EndFunc

Func modes_saveArray()
   
   local $ctr = 0
   
   
;~    while $ctr < $colNum
;~ 	  $row = 0
;~ 	  while $row <10
;~ 		 if $row==0 Then
;~ 			$columns[$col][$row]
;~ 		 Else
;~ 			$columns[$col][$row]
;~ 		 EndIf
;~ 		 $row+=1
;~ 		 
;~ 	  WEnd
;~ 	  $col+=1
;~    WEnd
	  
   GUIDelete($guiModes)

EndFunc

   

Func exitModes()
   GUIDelete($guiModes)
EndFunc


func loadJumpMenu()

   GUICtrlDelete($menujump)
   $menujump = GUICtrlCreateMenu("Jump to...")
   $ctr= 0
   while $ctr<$jumpLines[0]
	  $menujump_link[$ctr] = GUICtrlCreateMenuItem($jumpLines[$ctr+1], $menujump)	
	  GUICtrlSetOnEvent ( -1, "jump")
	  $ctr+=1
   WEnd
	
   GUICtrlCreateMenuItem("create jump...", $menujump)	
   GUICtrlSetOnEvent ( -1, "newJump")
   
EndFunc

func newJump()
   local $name 
   
   $name = InputBox("Zoom - Add Jump","Add the jump name, leave blank to delete")
  

   If $name == "" Then
	  $astrings[$cmdNumbers[$cmdNum]] = "*nextCommand*"
   Else
	  $astrings[$cmdNumbers[$cmdNum]] = "*nextCommand* jump="&$name
   EndIf
   $fileChanged = 1
   GUICtrlSetState($menuitem_save, $GUI_ENABLE)
   initialize2()
   
EndFunc


func jump()
   Local $ctr2 = 0
   while $ctr2 < 100
	  
	  if $menujump_link[$ctr2] == @GUI_CTRLID Then
		 $cmdNum =StringLeft($jumpLines[$ctr2+1],StringInStr($jumpLines[$ctr2+1],":")-1)
		 updateGui()
		 ExitLoop
	  EndIf   
	  $ctr2+=1
   WEnd
	  
 EndFunc
	
Func changeMode1()
	changeMode(1)	
EndFunc
Func changeMode2()
	changeMode(2)	
EndFunc
Func changeMode3()
	changeMode(3)	
EndFunc
Func changeMode4()
	changeMode(4)	
EndFunc
Func changeMode5()
	changeMode(5)	
EndFunc

Func changeMode($modeNum)
	$currentMode = $modeNum-1
	for $counter = 1 to $modes[0]	
		GUICtrlSetState ( $modesMenu[$counter], $GUI_UNCHECKED )	
	Next
	
	GUICtrlSetState ( $modesMenu[$modeNum], $GUI_CHECKED )	
	
EndFunc

Func comboCmdChange()
   local $currentCmd = GUICtrlRead($guiComboCmdTypes)
   local $prevCmd = StringLeft($astrings[$cmdNumbers[$cmdNum]+2],3)
   
   if $phase2 ==1 Then
;~ 		MsgBox(0,"grr",GUICtrlRead($guiTask))
			if StringCompare($currentCmd,$prevCmd)==0 Then
				
				If $OPTION_alwaysSave == True Then
					saveCmd2()
				Else
					GUICtrlSetBkColor($guiWriteCmd,0xF2F2ED)
				EndIf				
			Else
				
				If $OPTION_alwaysSave == True Then
					saveCmd2()
				Else
					GUICtrlSetBkColor($guiWriteCmd,0xff0000)
				EndIf	
			EndIf
	EndIf
EndFunc

;~ FileExtAssoc("zoo", "C:\zoom\zoom.exe %1")

func FileExtAssoc($sExt, $sApplication)
    RunWait(@COMSPEC & " /c ASSOC ." & $sExt & "=Zoom", "", @SW_HIDE)
    RunWait(@COMSPEC & " /c FTYPE Zoom=" & $sApplication , "", @SW_HIDE)
;~     MsgBox(0,"File Extension Application Association",'"' & $sExt & '"is now asscoiated with "' & $sApplication & '"',3)
EndFunc



;~ 	GUICtrlSetBkColor($guiWriteCmd,0x00ff00)


#cs example:
zoomVersion=2
*nextCommand*
pmt=this is the first commands
cmd=paste test 1
*nextCommand*
pmt=#paste# in putty
cmd=msp0tapis

#ce

#cs List of improvment ideas
;add menu
;add autosave task/cmd changes option
;add save file option
;add more vars option
;custom zoom folder location - defined in registry
;option to change zoom folder location

#ce

#cs
;3.3.0
added option for cmd line argument

;3.1.0
when cmd/task has not been saved, "save" is red
toggle var1 button added

;3.0.0
added a sweet intro gui
having "run:" in the cmd line will now run that program

;2.1.0
added custom input var1, this is useful when using strings that vary case by case


;2.0.2
modified exit code to prompt to save if file has been changed.

;2.0.1
added a ctrl down before the up only after text is pasted, this will stop ctrl from being stuck down,
  but the user will have too lift the ctrl button before doing another command

;2.0.0
;added input file version 2 support
added features for 2.0 ZoomTasks include
- buttons with functions : insert cmd before/after, delete cmd, save task/cmd
- users can use blank files to start new zoom tasks
- changes are saved upon Exit


;1.2.2
;started adding support for version 2 file formats

;1.2.1
;changed revision formating
;added ctrlup on Exit
;changed cmd field to editable, now whatever is in the cmd edit box is sent, so the user can change it
;inc command at end will not do a gui refresh

;1.2
; fixed hotkeys so ctrl doesnt need to be presses again every time
; fixed edit boxes to be multiline and readonly
#ce