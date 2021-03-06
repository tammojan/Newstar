C+ NMAXMH.FOR
C  WNB 910402
C
C  Revisions:
C	WNB 931214	Allow for P:
C
	SUBROUTINE NMAXMH(PTYPE,INFCA,MPHP,SNAM)
C
C  Show map header
C
C  Result:
C
C	CALL NMAXMH ( PTYPE_J:I, INFCA_J:I, MPHP_J:I, SNAM_J(*):I)
C					Show on output PTYPE the map at MPHP
C					of file INFCA.
C	CALL NMAEMH ( PTYPE_J:I, INFCA_J:I, MPHP_J:I, SNAM_J(*):I)
C					Edit map header
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'MPH_O_DEF'		!MAP HEADER
	INCLUDE 'GFH_O_DEF'
	INCLUDE 'SGH_O_DEF'
	INCLUDE 'MPH_E_DEF'		!EDIT INFORMATION
	INCLUDE 'GFH_E_DEF'
	INCLUDE 'SGH_E_DEF'
C
C  Parameters:
C
	INTEGER MXDEP			!MAX. NESTING DEPTH
	  PARAMETER (MXDEP=8)
	INTEGER D_GEDL			!GENERAL DATA
	  PARAMETER (D_GEDL=1)
C
C  Arguments:
C
	INTEGER PTYPE			!PRINT TYPE (f_p, f_t ETC)
	INTEGER INFCA			!FILE DESCRIPTOR
	INTEGER MPHP			!MAP HEADER POINTER
	INTEGER SNAM(*)			!SET NAME
C
C  Function references:
C
	LOGICAL WNFRD			!READ DATA
	LOGICAL WNFWR			!WRITE DATA
	INTEGER WNGGJ			!GET J
	CHARACTER*32 WNTTSG		!SHOW SET NUMBER
C
C  Data declarations:
C
	CHARACTER*8 PLIST(11)		!KNOWN P: AREAS
	  DATA PLIST/	'MPH','GFH','SGH',
	1		'B','I','J','E','D','X','Y',
	1		' '/
	INTEGER PLEN(0:1,11)		!P: LENGTH
	  DATA PLEN/	-1,MPHHDL,
	1		-1,GFHHDL,
	1		-1,SGHHDL,
	1		-1,LB_B,-1,LB_I,-1,LB_J,-1,LB_E,
	1		-1,LB_D,-1,LB_X,-1,LB_Y,
	1		0,0/
	INTEGER DEP			!CURRENT DEPTH
	INTEGER DEPAR(4,MXDEP)		!SAVE DEPTH
	INTEGER CHP,CHDL		!CURRENT HEADER LENGTH, PTR
	INTEGER CTYP,CEDP		!CURRENT HEADER TYPE #, PTR INTO EDIT
	INTEGER CHPT			!NEXT HEADER POINTER
	INTEGER PSZ(0:1)		!P: OFFSET AND SIZE
	BYTE MPH(0:MPHHDL-1)		!MAP HEADER
	  BYTE GFH(0:GFHHDL-1)
	  BYTE SGH(0:SGHHDL-1)
	  EQUIVALENCE (MPH,GFH,SGH)
	CHARACTER*8 D_G_EC(4,7)		!DATA TABLES
	  DATA D_G_EC/	'B','SB',' ',' ',
	1		'I','SI',' ',' ',
	1		'J','SJ',' ',' ',
	1		'E','E12.6',' ',' ',
	1		'D','D12.8',' ',' ',
	1		'X','26$EC12.6',' ',' ',
	1		'Y','26$DC12.8',' ',' '/
	INTEGER D_G_EJ(4,7)
	  DATA D_G_EJ/	0,1,0,LB_B,
	1		0,1,0,LB_I,
	1		0,1,0,LB_J,
	1		0,1,0,LB_E,
	1		0,1,0,LB_D,
	1		0,1,0,LB_X,
	1		0,1,0,LB_Y/
C-
C
C GET HEADER
C
	IF (.NOT.WNFRD(INFCA,MPHHDL,MPH,MPHP)) THEN
	  CALL WNCTXT(PTYPE,'Read error on input node')
	  RETURN
	END IF
C
C SHOW HEADER
C
	CALL WNCTXT(PTYPE,'!/Map header description !AS\:!/',
	1		WNTTSG(SNAM,0))
	CALL NSCXXS(PTYPE,MPH,MPHEDL,MPH_EC,MPH_EJ)	!ACTUAL SHOW
C
	RETURN
C
C NSCESH
C
	ENTRY NMAEMH(PTYPE,INFCA,MPHP,SNAM)
C
C INIT
C
	DEP=0					!CURRENT DEPTH
	CHP=MPHP				!HEADER POINTER
	CTYP=1					!CURRENT TYPE (MPH)
	CEDP=-1					!CURRENT POINTER IN EDIT LIST
	CHDL=MPHHDL				!CURRENT LENGTH
C
C ACTION
C
 10	CONTINUE
	DO WHILE (CTYP.GT.0)			!SOMETHING TO DO
	  IF (CHDL.LE.0) THEN			!GET NEW HEADER
	    IF (PLEN(0,CTYP).GE.0 .AND. CEDP.GT.0) THEN
	      CHDL=WNGGJ(MPH(PLEN(0,CTYP)))	!LENGTH FROM FILE
	    ELSE
	      CHDL=PLEN(1,CTYP)			!DEFAULT LENGTH
	    END IF
	    CHDL=MIN(CHDL,PLEN(1,CTYP))		!MAKE SURE NO PROBLEMS
	    IF (CHDL.LE.0) GOTO 20		!NOT PRESENT; RESTART CURRENT
	  END IF
C
C GET HEADER
C
	  IF (CHP.EQ.0 .AND.
	1		(CTYP.LT.2 .OR.
	1		(CTYP.GT.3 .AND. CTYP.LT.4) .OR.
	1		(CTYP.GT.10))) GOTO 20	!NOT PRESENT
	  IF (CHP.GT.0 .AND. CHP.LT.GFHHDL .AND.
	1		(CTYP.LT.4 .OR. CTYP.GT.10)) THEN !MUST BE GFH
	    CTYP=2
	    CHDL=PLEN(1,CTYP)
	    CHP=0
	    CEDP=-1
	  END IF
	  CALL WNGMVZ(PLEN(1,CTYP),MPH)		!CLEAR BEFORE READ
	  IF (.NOT.WNFRD(INFCA,CHDL,MPH,CHP)) THEN
	    CALL WNCTXT(PTYPE,'Read error on input node')
	    RETURN
	  END IF
C
C EDIT HEADER
C
	  CALL WNCTXT(PTYPE,'*** Editing !AS ***',PLIST(CTYP))
	  IF (DEP.GE.MXDEP) THEN		!SHIFT ONE
	    DO I=1,MXDEP-1
	      DO I1=1,4
	        DEPAR(I1,I)=DEPAR(I1,I+1)
	      END DO
	    END DO
	    DEP=MXDEP-1
	  END IF
	  DEP=DEP+1				!SAVE PREVIOUS
	  DEPAR(1,DEP)=CHP
	  DEPAR(2,DEP)=CTYP
	  DEPAR(3,DEP)=CEDP
	  DEPAR(4,DEP)=CHDL
	  IF (CTYP.EQ.1) THEN
	    CALL NSCXES(PTYPE,MPH,MPHEDL,MPH_EC,MPH_EJ,PLIST,
	1		CTYP,CEDP,CHPT,PSZ)
	  ELSE IF (CTYP.EQ.2) THEN
	    CALL NSCXES(PTYPE,MPH,GFHEDL,GFH_EC,GFH_EJ,PLIST,
	1		CTYP,CEDP,CHPT,PSZ)
	  ELSE IF (CTYP.EQ.3) THEN
	    CALL NSCXES(PTYPE,MPH,SGHEDL,SGH_EC,SGH_EJ,PLIST,
	1		CTYP,CEDP,CHPT,PSZ)
	  ELSE IF (CTYP.GE.4 .AND. CTYP.LE.10) THEN
	    CALL NSCXES(PTYPE,MPH,D_GEDL,
	1		D_G_EC(1,CTYP-3),D_G_EJ(1,CTYP-3),PLIST,
	1		CTYP,CEDP,CHPT,PSZ)
	  END IF
	  IF (CTYP.GE.1000) THEN		!RELATIVE ADDRESS
	    CTYP=MOD(CTYP,1000)			!GET CORRECT TYPE
	    CHPT=CHP+CHPT			!CATER FOR OFFSET GIVEN
	  END IF
	  IF (CTYP.GE.4 .AND. CTYP.LE.10) THEN
	    CHPT=CHPT+PSZ(0)*D_G_EJ(4,CTYP-3)	!CATER FOR GIVEN OFFSET
	    D_G_EJ(2,CTYP-3)=MAX(1,MIN(PSZ(1),MPHHDL/LB_Y)) !MAX. NUMBER TO DO
	  END IF
C
C REWRITE HEADER
C
	  IF (.NOT.WNFWR(INFCA,CHDL,MPH,CHP)) THEN
 30	    CONTINUE
	    CALL WNCTXT(PTYPE,'Write error on input node')
	    RETURN
	  END IF
	  CHP=CHPT				!NEXT HEADER POINTER
	  IF (CTYP.GE.4 .AND. CTYP.LE.10) THEN
	    CHDL=D_G_EJ(2,CTYP-3)*D_G_EJ(4,CTYP-3) !NEW LENGTH
	  ELSE
	    CHDL=0				!NEXT HEADER LENGTH
	  END IF
	END DO
C
C RETURN PREVIOUS LEVEL
C
	DEP=DEP-1
 20	CONTINUE
	IF (DEP.GT.0) THEN			!CAN DO MORE
	  CHP=DEPAR(1,DEP)
	  CTYP=DEPAR(2,DEP)
	  CEDP=DEPAR(3,DEP)
	  CHDL=DEPAR(4,DEP)
	  DEP=DEP-1
	  GOTO 10
	END IF
C
	RETURN
C
C
	END
