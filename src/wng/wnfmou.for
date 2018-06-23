C+ WNFMOU.FOR
C  WNB 890714
C
C  Revisions:
C	HjV 930519	Add //CHAR(0) in call to WNFMOU_X 
C	WNB 930520	Remove %VAL
C	HjV 930519	Remove //CHAR(0) in call to WNFMOU_X 
C			Now in WNFMOU_X.CEE itself
C	WNB 930811	Remove L_
C	CMV 940808	Add entry WNFMLI to list tapeunits
C
	LOGICAL FUNCTION WNFMOU(MCA,UNIT,ACC)
C
C  Mount a tape volume
C
C  Result:
C
C	WNFMOU_L = WNFMOU( MCA_J:IO, UNIT_C*:I, ACC_C*:I)
C				Mount a tape on the unit number UNIT,
C				corresponding to logical device MAG<unit>. MCA
C				is the magnetictape-control-area. ACC can be a
C				combination of R (default) or W, and U
C				to force unlabeled handling, and B to
C				force block handling, rather than address mode
C				for Reading.
C				Note: Only first char. of UNIT is used.
C
C	WNFMLI_L = WNFMLI()	List definitions of all tapeunits
C
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'MCA_O_DEF'			!MCA OFFSETS
C
C  Parameters:
C
C
C  Arguments:
C
	INTEGER MCA				!MCA ID
	CHARACTER*(*) UNIT			!UNIT TO MOUNT
	CHARACTER*(*) ACC			!ACCESS DATA
C
C  Entry points:
C
	LOGICAL WNFMLI				!LIST UNITS
C
C  Function references:
C
	LOGICAL WNGGVM				!GET VIRTUAL MEMORY
	INTEGER WNFTFC				!TEST FCA/MCA PRESENCE
	INTEGER WNFMOU_X			!MOUNT TAPE
	INTEGER WNFMLI_X			!GET NAME
	INTEGER WNCALN				!GET LENGTH OF STRING
C
C  Data declarations:
C
	CHARACTER*4 LUNIT			!FULL UNIT NAME
	CHARACTER*80 TXT			!DEFINITION OF UNIT
	CHARACTER*10 UNO			!UNIT NUMBERS
	DATA UNO/'0123456789'/
C-
	WNFMOU=.FALSE.					!ASSUME ERROR
	CALL WNFINI					!START SYSTEM
	IF (WNFTFC(MCA).NE.0) THEN			!STILL FILE OPEN/MOUNTED
	  CALL WNFCL(MCA)				!CLOSE FILE
	  CALL WNFDMO(MCA)				!DISMOUNT FILE
	END IF
	LUNIT='MAG'//UNIT(1:1)				!SET UNIT
	IF (.NOT.WNGGVM(MCAHDL,J)) RETURN		!GET MCA
	CALL WNGMVZ(MCAHDL,A_B(J-A_OB))			!ZERO MCA
	J1=(J-A_OB)/LB_J				!DUMMY ARRAY OFFSET
	A_J(J1+MCA_TID_J)=1				!INDICATE MCA
	A_J(J1+MCA_SIZE_J)=MCAHDL			!SET SIZE
	DO I=1,LEN(ACC)					!SET ACCESS
	  IF (ACC(I:I).EQ.'W' .OR. ACC(I:I).EQ.'w') THEN !OUTPUT
	    A_J(J1+MCA_BITS_J)=IOR(A_J(J1+MCA_BITS_J),MCA_M_OUT)
	  ELSE IF (ACC(I:I).EQ.'U' .OR. ACC(I:I).EQ.'u') THEN !UNLABELLED
	    A_J(J1+MCA_BITS_J)=IOR(A_J(J1+MCA_BITS_J),MCA_M_UNL)
	  ELSE IF (ACC(I:I).EQ.'B' .OR. ACC(I:I).EQ.'b') THEN !BLOCK MODE
	    A_J(J1+MCA_BITS_J)=IOR(A_J(J1+MCA_BITS_J),MCA_M_BLK)
	  END IF
	END DO
	E_C=WNFMOU_X(A_B(J-A_OB),LUNIT)			!DO MOUNT
	IF (IAND(E_C,1).EQ.1) THEN			!QUEUE MCA
	  WNFMOU=.TRUE.					!OK
	  MCA=J						!RETURN MCA ADDRESS
	  CALL WNFLFC(MCA)				!SET IN LINK LIST
	ELSE
	  CALL WNFDMO_X(A_B(J-A_OB))			!DISMOUNT IF NECESSARY
	  CALL WNGFVM(MCAHDL,J)				!FREE MCA
	  MCA=0						!MAKE SURE INDICATED
	END IF
C
	RETURN
C
	ENTRY WNFMLI
C
	WNFMLI=.TRUE.					!ALWAYS SUCCESS
C
	CALL WNCTXT(F_T,'!/Available tape units:')
	DO I1=1,10
	   LUNIT='MAG'//UNO(I1:I1)
	   E_C=WNFMLI_X(LUNIT,TXT,80)			!GET NAME
	   IF (IAND(E_C,1).EQ.1) THEN
	      I2=WNCALN(TXT)
	      CALL WNCTXT(F_T,'!AS - !AS',UNO(I1:I1),TXT(:I2)) !SHOW IF FOUND
	   END IF
	END DO	   
	CALL WNCTXT(F_T,
	1	'D - Disk tape (files <name>.000001 etc.).!/')
C
	RETURN
C
	END