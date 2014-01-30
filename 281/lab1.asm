;@Author: Shivanshu Goyal
;@Student Number: 33245127

;Alarm Clock (Lab 1) - EECE 281
;January 15 2014

$MODDE2

CLK EQU 33333333
FREQ_0 EQU 2000
FREQ_2 EQU 100
TIMER0_RELOAD EQU 65536-(CLK/(12*2*FREQ_0))
TIMER2_RELOAD EQU 65536-(CLK/(12*FREQ_2))

DEFAULT_HOUR EQU 3
DEFAULT_MINUTE EQU 15
DEFAULT_SECOND EQU 50

BUZZER_PIN EQU P0.1 ; The pin at which the buzzer is attached

ALARM_UNLOCK_PATTERN EQU 0b10010010

org 0000H  ;main program
	ljmp myprogram
	
org 000BH  ;interrupt for the buzzer
	ljmp ISR_timer0
	
org 002BH  ;timer 2 interrupt
	ljmp ISR_timer2

BSEG at 20H
realTimeAM: dbit 1
alarmTimeAM: dbit 1
setTimeAM: dbit 1
timesEqual: dbit 1 ;used when comparing real time vs alarm time
alarmBuzz: dbit 1 ;if set, the buzzer will go on. If cleared, it goes off

DSEG at 30H
Cnt_10ms: ds 1

realTimeHour: ds 1
realTimeMinute: ds 1
realTimeSecond: ds 1
alarmTimeHour: ds 1
alarmTimeMinute: ds 1
alarmTimeSecond: ds 1

setTimeHour: ds 1
setTimeMinute: ds 1
setTimeSecond: ds 1

CSEG

; Look-up table for 7-segment displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H

ISR_timer0:
	jb alarmBuzz,ISR_timer0_compliment
		sjmp ISR_timer0_return ;reload timer values and exit
	ISR_timer0_compliment:
		cpl BUZZER_PIN
	ISR_timer0_return:
	mov TH0, #high (TIMER0_RELOAD)
	mov TL0, #low (TIMER0_RELOAD)
	reti

ISR_timer2:
	push psw
	push acc
	push dpl
	push dph
	
	clr TF2;clear this bit for future interrupts
	
	;There should be a "tick" after 100 interrupts
	mov a, Cnt_10ms
	inc a
	mov Cnt_10ms, a
	
	cjne a, #100, do_nothing
	
	mov Cnt_10ms, #0
	
	;---TICK EVERY SECOND---
	cpl LEDRA.3
	lcall incrementTime_safe
	;if any switch is on, skip time display update and don't check for alarm
	mov a,SWA
	anl a,#00000011b
	cjne a,#0,do_nothing
		lcall updateTimeDisplay_safe
		lcall compareRealVsAlarmTime;check for alarm
		jnb timesEqual,do_nothing
		setb alarmBuzz ;;;;TURN ON ALARM SIGNAL
	;-------END TICK-------	

	do_nothing:
		pop dph
		pop dpl
		pop acc
		pop psw
		
		reti

;--------------------
;Compare current AM/PM with alarm AM/PM
;if they are equal then sets the timesEqual bit
;otherwise clears it
;--------------------
compareRealAMVsAlarmAM:
	push acc
	push psw
	clr a
	
	jb realTimeAM,compareRealAMVsAlarmAM_incA1
	compareRealAMVsAlarmAM_back:
	jb alarmTimeAM,compareRealAMVsAlarmAM_incA2
	
	sjmp compareRealAMVsAlarmAM_skip
	
	compareRealAMVsAlarmAM_incA1:
		inc a
		sjmp compareRealAMVsAlarmAM_back
	compareRealAMVsAlarmAM_incA2:
		inc a
	compareRealAMVsAlarmAM_skip:
		cjne a,#1,compareRealAMVsAlarmAM_areEqual
		clr timesEqual
		sjmp compareRealAMVsAlarmAM_done
	compareRealAMVsAlarmAM_areEqual:
		setb timesEqual
	compareRealAMVsAlarmAM_done:
		pop psw
		pop acc
		ret

;--------------------
;Compares current time with alarm time
;if they are equal then sets the timesEqual bit
;otherwise clears it
;--------------------
compareRealVsAlarmTime:
	push acc
	push psw
	mov a,realTimeHour
	CJNE a,alarmTimeHour,compareRealVsAlarmTime_notEqual
		mov a,realTimeMinute
		CJNE a,alarmTimeMinute,compareRealVsAlarmTime_notEqual
			mov a,realTimeSecond
			CJNE a,alarmTimeSecond,compareRealVsAlarmTime_notEqual
				lcall compareRealAMVsAlarmAM;sets the timesEqual bit accordingly
				jnb timesEqual,compareRealVsAlarmTime_notEqual
					setb timesEqual; TIMES ARE EQUAL!
					pop psw
					pop acc
					ret
	compareRealVsAlarmTime_notEqual:
		clr timesEqual
		pop psw
		pop acc
		ret


;-----------------
;Sub routine for calling updateTimeDisplay
;Used for reasoning about the correctness of code
;-----------------
updateTimeDisplay_safe:
	push dpl
	push dph
	push acc
	push b
	push psw
		lcall updateTimeDisplay
	pop psw
	pop b
	pop acc
	pop dph
	pop dpl
	ret
	
;-------------
;Sub routine for calling incrementTime
;Used for reasoning about the correctness of code
;-------------
incrementTime_safe:
	push acc
	push psw
		lcall incrementTime
	pop psw
	pop acc
	ret

;--------------
;Updates the HEX displays based on current time and AM/PM
;Note: Modifies dptr,a,b and maybe psw
;--------------
updateTimeDisplay:
	mov dptr,#myLUT
	;Display Second (tens):
	mov a,realTimeSecond
	mov b,#10
	div ab
	movc a,@a+dptr
	mov HEX3,a
	;Display Second (ones):
	mov a,b
	movc a,@a+dptr
	mov HEX2,a
	;Display Minute (tens):
	mov a,realTimeMinute
	mov b,#10
	div ab
	movc a,@a+dptr
	mov HEX5,a
	;Display Minute (ones):
	mov a,b
	movc a,@a+dptr
	mov HEX4,a
	;Display Hour (tens):
	mov a,realTimeHour
	mov b,#10
	div ab
	movc a,@a+dptr
	mov HEX7,a
	;Display Hour (ones):
	mov a,b
	movc a,@a+dptr
	mov HEX6,a
	;Display AM/PM:
	jb realTimeAM,updateTimeDisplay_showAM
		mov HEX0,#8CH ;show PM
		ret
	updateTimeDisplay_showAM:
		mov HEX0,#88H ;show AM
	ret
	
;--------------------
;Update Hour display routine for setting time/alarm
;--------------------
updateHourSettingDisplay:
	push acc
	push dph
	push dpl
	mov dptr,#myLUT
	;Display tens:
	mov a,setTimeHour
	mov b,#10
	div ab
	movc a,@a+dptr
	mov HEX7,a
	;Display ones:
	mov a,b
	movc a,@a+dptr
	mov HEX6,a
	pop dpl
	pop dph
	pop acc
	ret
	
;--------------------
;Update Minute display routine for setting time/alarm
;--------------------
updateMinuteSettingDisplay:
	push acc
	push dph
	push dpl
	mov dptr,#myLUT
	;Display tens:
	mov a,setTimeMinute
	mov b,#10
	div ab
	movc a,@a+dptr
	mov HEX5,a
	;Display ones:
	mov a,b
	movc a,@a+dptr
	mov HEX4,a
	pop dpl
	pop dph
	pop acc
	ret

;--------------------
;Update Second display routine for setting time/alarm
;--------------------
updateSecondSettingDisplay:
	push acc
	push dph
	push dpl
	mov dptr,#myLUT
	;Display tens:
	mov a,setTimeSecond
	mov b,#10
	div ab
	movc a,@a+dptr
	mov HEX3,a
	;Display ones:
	mov a,b
	movc a,@a+dptr
	mov HEX2,a
	pop dpl
	pop dph
	pop acc
	ret

;--------------------
;Update AM/PM display routine for setting time/alarm
;--------------------
updateAMPMSettingDisplay:
	push acc
	;Display AM/PM:
	jb setTimeAM,updateAMPMSettingDisplay_showAM
		mov HEX0,#8CH ;show PM
		pop acc
		ret
	updateAMPMSettingDisplay_showAM:
		mov HEX0,#88H ;show AM
	pop acc
	ret

;----------------
;Increments the time values stored in realTimeSec, realTimeMinute, realTimeHour
;Note: Modifies accumulator and maybe psw
;----------------
incrementTime:
	mov a,realTimeSecond
	CJNE a,#59,incrementTime_incSec
		mov realTimeSecond,#0
		mov a,realTimeMinute
		CJNE a,#59,incrementTime_incMin
			mov realTimeMinute,#0
			mov a,realTimeHour
			CJNE a,#11,incrementTime_continueCheckingHour
				cpl realTimeAM;Change AM to PM or PM to AM
			incrementTime_continueCheckingHour:
			CJNE a,#12,incrementTime_incHour
				mov realTimeHour,#1
				ret
			incrementTime_incHour:inc realTimeHour
			ret
		incrementTime_incMin:inc realTimeMinute
		ret
	incrementTime_incSec:inc realTimeSecond
	ret


;For a 33.33MHz clock, one cycle takes 30ns
WaitHalfSec:
	mov R2, #90
WaitHalfSec_L3: mov R1, #250
WaitHalfSec_L2: mov R0, #250
WaitHalfSec_L1: djnz R0, WaitHalfSec_L1
	djnz R1, WaitHalfSec_L2
	djnz R2, WaitHalfSec_L3
	ret
	
;Wait 28 milli seconds
WaitDebounce:
	mov R2, #5
WaitDebounce_L3: mov R1, #250
WaitDebounce_L2: mov R0, #250
WaitDebounce_L1: djnz R0, WaitDebounce_L1
	djnz R1, WaitDebounce_L2
	djnz R2, WaitDebounce_L3
	ret
	
;Wait 200 milliseconds
Wait200ms:
	mov R2, #35
Wait200ms_L3: mov R1, #250
Wait200ms_L2: mov R0, #250
Wait200ms_L1: djnz R0, Wait200ms_L1
	djnz R1, Wait200ms_L2
	djnz R2, Wait200ms_L3
	ret
	
myprogram:
	mov SP, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	mov P0MOD, #00000010B ;P0.1 is used for buzzer!
    
    clr alarmBuzz ; Turn off alarm initially
    
    ;---Set up Timer 0 for buzzer---
    mov TMOD,  #00000001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 ; Disable timer 0
	clr TF0
	mov TH0, #high (TIMER0_RELOAD)
	mov TL0, #low (TIMER0_RELOAD)
    setb TR0 ; Enable timer 0
    setb ET0 ; Enable timer 0 interrupt
    ;-------------------------------
    
    ;---Set up Timer 2 for buzzer---
    mov T2CON, #00H ; Autoreload is enabled, work as a timer
    clr TR2
    clr TF2
    ; Set up timer 2 to interrupt every 10ms
    mov RCAP2H,#high(TIMER2_RELOAD)
    mov RCAP2L,#low(TIMER2_RELOAD)
    setb TR2
    setb ET2
    ;-------------------------------
    
    ;--- initializing variables
    mov Cnt_10ms, #0
    mov realTimeHour, #DEFAULT_HOUR
	mov realTimeMinute, #DEFAULT_MINUTE
	mov realTimeSecond, #DEFAULT_SECOND
	clr realTimeAM;;The default value
	mov alarmTimeHour, #0
	mov alarmTimeMinute, #0
	mov alarmTimeSecond, #0
	setb alarmTimeAM;;The default value
	;--- end initialization
     
    setb EA  ; Enable all interrupts
	
	;---Routine for jumping to a BIG address
	sjmp forever
	longJump_forever_checkAlarmSwitch:
		ljmp forever_checkAlarmSwitch
	;---End Routine
	
	forever:
		
		;---Check if switch for turning off alarm is on:
		mov a,SWB
		cjne a,#ALARM_UNLOCK_PATTERN,forever_checkTimeAlarmSetSwitches
		clr alarmBuzz ; stop the signal for alarm
		clr BUZZER_PIN ; make sure alarm is off and not "left" on as it is complimented in ISR
		;---
		
		; %%%%%%%% Start checking if switches for setting time/alarm are on and set time, etc...
		forever_checkTimeAlarmSetSwitches:
		mov a,SWA
		anl a,#00000001b
		cjne a,#1,longJump_forever_checkAlarmSwitch; Time set switch is on
			;Move current time to setTime variables---
			mov setTimeHour,realTimeHour
			mov setTimeMinute,realTimeMinute
			mov setTimeSecond,realTimeSecond
			jb realTimeAM,forever_setSetTimeAM
				clr setTimeAM
				sjmp forever_checkTimeSetting
			forever_setSetTimeAM:
				setb setTimeAM
			;End moving variables---
			forever_checkTimeSetting:
			jb KEY.3,forever_checkMin ;Hour key is pressed
				lcall WaitDebounce ;Debounce
				jb KEY.3,forever_checkMin ;Hour key actually pressed
					mov a,setTimeHour
					;increment hour:
					cjne a,#12,forever_hourIncrementTimeSetting
						mov setTimeHour,#1
						sjmp forever_doneIncrementingHourTimeSetting
					forever_hourIncrementTimeSetting:
						inc setTimeHour
					forever_doneIncrementingHourTimeSetting:
					;done incrementing hour
					lcall updateHourSettingDisplay
					lcall Wait200ms;For next increment
			forever_checkMin:
			jb KEY.2,forever_checkSec ;Min key is pressed
				lcall WaitDebounce ;Debounce
				jb KEY.2,forever_checkSec ;Min key actually pressed
					mov a,setTimeMinute
					;increment minute:
					cjne a,#59,forever_minuteIncrementTimeSetting
						mov setTimeMinute,#0
						sjmp forever_doneIncrementingMinuteTimeSetting
					forever_minuteIncrementTimeSetting:
						inc setTimeMinute
					forever_doneIncrementingMinuteTimeSetting:
					;done incrementing minute
					lcall updateMinuteSettingDisplay
					lcall Wait200ms;For next increment
			forever_checkSec:
			jb KEY.1,forever_checkAMPM ;Sec key is pressed
				lcall WaitDebounce ;Debounce
				jb KEY.1,forever_checkAMPM ;Sec key actually pressed
					mov a,setTimeSecond
					;increment second:
					cjne a,#59,forever_secondIncrementTimeSetting
						mov setTimeSecond,#0
						sjmp forever_doneIncrementingSecondTimeSetting
					forever_secondIncrementTimeSetting:
						inc setTimeSecond
					forever_doneIncrementingSecondTimeSetting:
					;done incrementing second
					lcall updateSecondSettingDisplay
					lcall Wait200ms;For next increment
			forever_checkAMPM:
			mov a,SWC
			anl a,#00000010b
			cjne a,#02H,forever_checkTimeSetSwitchAgain ;AM/PM "key" is pressed
				lcall WaitDebounce ;Debounce
				mov a,SWC
				anl a,#00000010b
				cjne a,#02H,forever_checkTimeSetSwitchAgain; AM/PM "key" is actually pressed
					cpl setTimeAM
					lcall updateAMPMSettingDisplay
					lcall WaitHalfSec;For next increment (Wait longer because its not proper key)
			forever_checkTimeSetSwitchAgain:
		;See if the time setting switch is still on:
		mov a,SWA
		anl a,#00000001b
		cjne a,#1,forever_moveVariablesBack; Time set switch is still on
			ljmp forever_checkTimeSetting
		forever_moveVariablesBack:
			;move the time setting variables back to real time variables---
			mov realTimeHour,setTimeHour
			mov realTimeMinute,setTimeMinute
			mov realTimeSecond,setTimeSecond
			jb setTimeAM,forever_setSetTimeAM2
				clr realTimeAM
				sjmp forever_checkAlarmSwitch
			forever_setSetTimeAM2:
				setb realTimeAM
			;end moving variables---
		
		
		;----routine for jumping to a BIG address
		sjmp forever_checkAlarmSwitch
		longJump_forever:
			ljmp forever
		;----end routine
		
		
		;--------------------------------CHECKING IF ALARM SET SWITCH IS ON NOW
		forever_checkAlarmSwitch:
		mov a,SWA
		anl a,#00000010b
		cjne a,#02H,longJump_forever; Alarm set switch is on
			;----Initialize initial view for alarm (no alarm initially set as everything's zero)
			mov setTimeHour,alarmTimeHour
			mov setTimeMinute,alarmTimeMinute
			mov setTimeSecond,alarmTimeSecond
			jb alarmTimeAM,forever_setSetTimeAMalarm
				clr setTimeAM
				sjmp forever_initAlarmViews
			forever_setSetTimeAMalarm:
				setb setTimeAM
			forever_initAlarmViews:
			lcall updateHourSettingDisplay
			lcall updateMinuteSettingDisplay
			lcall updateSecondSettingDisplay
			lcall updateAMPMSettingDisplay
			;----End initialization
			forever_checkAlarmSetting:
			jb KEY.3,forever_checkMinAlarm ;Hour key is pressed
				lcall WaitDebounce ;Debounce
				jb KEY.3,forever_checkMinAlarm ;Hour key actually pressed
					mov a,setTimeHour
					;increment hour:
					cjne a,#12,forever_hourIncrementAlarmSetting
						mov setTimeHour,#1
						sjmp forever_doneIncrementingHourAlarmSetting
					forever_hourIncrementAlarmSetting:
						inc setTimeHour
					forever_doneIncrementingHourAlarmSetting:
					;done incrementing hour
					lcall updateHourSettingDisplay
					lcall Wait200ms;For next increment
			forever_checkMinAlarm:
			jb KEY.2,forever_checkSecAlarm ;Min key is pressed
				lcall WaitDebounce ;Debounce
				jb KEY.2,forever_checkSecAlarm ;Min key actually pressed
					mov a,setTimeMinute
					;increment minute:
					cjne a,#59,forever_minuteIncrementAlarmSetting
						mov setTimeMinute,#0
						sjmp forever_doneIncrementingMinuteAlarmSetting
					forever_minuteIncrementAlarmSetting:
						inc setTimeMinute
					forever_doneIncrementingMinuteAlarmSetting:
					;done incrementing minute
					lcall updateMinuteSettingDisplay
					lcall Wait200ms;For next increment
			forever_checkSecAlarm:
			jb KEY.1,forever_checkAMPMAlarm ;Sec key is pressed
				lcall WaitDebounce ;Debounce
				jb KEY.1,forever_checkAMPMAlarm ;Sec key actually pressed
					mov a,setTimeSecond
					;increment second:
					cjne a,#59,forever_secondIncrementAlarmSetting
						mov setTimeSecond,#0
						sjmp forever_doneIncrementingSecondAlarmSetting
					forever_secondIncrementAlarmSetting:
						inc setTimeSecond
					forever_doneIncrementingSecondAlarmSetting:
					;done incrementing second
					lcall updateSecondSettingDisplay
					lcall Wait200ms;For next increment
			forever_checkAMPMAlarm:
			mov a,SWC
			anl a,#00000010b
			cjne a,#02H,forever_checkAlarmSetSwitchAgain ;AM/PM "key" is pressed
				lcall WaitDebounce ;Debounce
				mov a,SWC
				anl a,#00000010b
				cjne a,#02H,forever_checkAlarmSetSwitchAgain; AM/PM "key" is actually pressed
					cpl setTimeAM
					lcall updateAMPMSettingDisplay
					lcall WaitHalfSec;For next increment (Wait longer because its not proper key)
			forever_checkAlarmSetSwitchAgain:
		;See if the alarm setting switch is still on:
		mov a,SWA
		anl a,#00000010b
		cjne a,#02H,forever_moveVariablesToAlarm; Time set switch is still on
			ljmp forever_checkAlarmSetting
		forever_moveVariablesToAlarm:
			;move the time setting variables to alarm time variables---
			mov alarmTimeHour,setTimeHour
			mov alarmTimeMinute,setTimeMinute
			mov alarmTimeSecond,setTimeSecond
			jb setTimeAM,forever_setSetTimeAM3;NOT THE BEST NAME FOR LABEL
				clr alarmTimeAM
				lcall updateTimeDisplay_safe;update displays before looping again
				ljmp forever
			forever_setSetTimeAM3:;NOT THE BEST NAME FOR LABEL
				setb alarmTimeAM
			;end moving variables---
			
			lcall updateTimeDisplay_safe ;update displays to show real time
			
	ljmp forever
	
END
