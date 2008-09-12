C+ NLEIDEN.FOR
C  HjV 950116
C
C  Revisions:
C       HjV 951113	Test if specified label not deleted in MEDIAD
C			Add ARC-option
C	CMV 000701	Be more relaxed in considering something deleted (for CDRoms)
C
	SUBROUTINE NLEIDEN(TYP)
C
C  Load LEIDEN data into SCN file
C
C  Result:
C
C	CALL NLEIDEN(TYP_J:I)	will load LEIDEN data in SCN file if TYP is 0,
C				or list LEIDEN data if TYP is 1, 
C				or list and update Scissor if TYP is 2.
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'CBITS_DEF'
        INCLUDE 'FDL_O_DEF'			!FD BLOCK
        INCLUDE 'FDL_T_DEF'
        INCLUDE 'IHL_O_DEF'			!IH BLOCK
        INCLUDE 'IHL_T_DEF'
	INCLUDE 'GFH_O_DEF'			!GENERAL FILE HEADER
	INCLUDE 'SGH_O_DEF'			!SUB-GROUP HEADER
	INCLUDE 'STH_O_DEF'			!SET HEADER
	INCLUDE 'NSC_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
	INTEGER TYP				!Can be 0,1 or 2
C
C  Function references:
C
	LOGICAL WNFOP,WNFOPF			!OPEN FILE
	LOGICAL WNFRD				!READ DATA
	LOGICAL WNFWR				!WRITE DATA
	INTEGER WNFEOF				!FILE POSITION
	DOUBLE PRECISION WNGDNF			!NORM. ANGLE
	INTEGER WNCALN				!STRING LENGTH
	LOGICAL WNDLNG,WNDLNF			!LINK SUB-GROUP
	LOGICAL NLEIRD				!READ DATA
	LOGICAL NLEIWD				!WRITE DATA
	CHARACTER*80 WNFTVL			!GET VOLUME HEADER
	INTEGER WNFSCI				!CALL DATABASE
	INTEGER WNFSCC				!CLOSE DATABASE
C
C  Data declarations:
C
	LOGICAL OUT				!WRITE SCN FILE?
	CHARACTER*6 LTXT			!LABEL NAME
	CHARACTER*(IHL_FIELD_N) FNAM		!FIELD NAME
	DOUBLE PRECISION MJDHA0			!MJD AT HA=0
	REAL FWGT				!MAX. WEIGHT
C
        BYTE FDL(0:FDLHDL-1)                    !FD
          INTEGER*2 FDLI(0:FDLHDL/2-1)
          INTEGER   FDLJ(0:FDLHDL/4-1)
          REAL*4    FDLE(0:FDLHDL/4-1)
          REAL*8    FDLD(0:FDLHDL/8-1)
          EQUIVALENCE (FDL,FDLI,FDLJ,FDLE,FDLD)
        BYTE IHL(0:IHLHDL-1)                    !IH
          INTEGER*2 IHLI(0:IHLHDL/2-1)
          INTEGER   IHLJ(0:IHLHDL/4-1)
          REAL*4    IHLE(0:IHLHDL/4-1)
          REAL*8    IHLD(0:IHLHDL/8-1)
          EQUIVALENCE (IHL,IHLI,IHLJ,IHLE,IHLD)
C
	BYTE STH(0:STHHDL-1)			!SET HEADER
	  INTEGER*2 STHI(0:STHHDL/2-1)
	  INTEGER   STHJ(0:STHHDL/4-1)
	  REAL STHE(0:STHHDL/4-1)
	  REAL*8 STHD(0:STHHDL/8-1)
	  EQUIVALENCE (STH,STHI,STHJ,STHE,STHD)
C
C	Some buffers passed to lower level routines. 
C
	INTEGER*2 DBUF(2,0:MXDATN-1)			!INPUT BUFFER
	INTEGER*2 TMPBUF(3,0:MXDATX-1)			!OUTPUT BUFFER
C
	INTEGER FCAT				!TMP FILE DESCRIPTOR
	INTEGER NCHT				!# OF CHANNELS DONE
        INTEGER BINT                            !BASIC INTEGRATION TIME
	REAL OHAB				!START HA SCANS
	INTEGER ONS(6)				!INTEGRATION DATA
	INTEGER NPOL				!# OF POLARISATIONS FOUND
	INTEGER POLS(0:3)			!INDICATE POLS TO DO
	INTEGER NIFR				!INTERFEROMETER COUNT
	INTEGER IFRT(9,0:MXNIFR-1)		!INTERFEROMETER DESCRIPTION
	INTEGER F_XX				!OUTPUT FOR FORMATS
	CHARACTER*80 VOLUME			!VOLUME HEADER
	INTEGER*2 FVERS				!Tape-format version
	INTEGER OBSDATE				!Obs. date (yyddd)
	REAL*8  OBSSTART			!Obs. start-time in SEC.
	REAL*8  OBSEND				!Obs. end-time in SEC.
	INTEGER*2 OLSYS				!Online program nr.
	CHARACTER*3 PRNAME			!Initals project scientist
	INTEGER NBL				!# block within dataset
	INTEGER*2 BYPBL				!# bytes per block
	INTEGER*2 FBNDS,FBNDE			!start/end freq.band
	INTEGER*2 DIPOLE			!DIPOLE number
	CHARACTER*1024 WARC			!BUFFER FOR ARCHIVE
	CHARACTER*16 FIELD			!Field name
C-
C
C INIT
C
	OUT=(TYP.EQ.0)				!ONLY SCN FILE IF TYP=0
	IF (OUT) THEN
	   F_XX=F_TP				!BOTH SCREEN AND LOG
	ELSE
	   F_XX=F_T				!ONLY SCREEN
	END IF
	IF (.NOT.WNFOP(FCAT,'NSCAN.TMP','WT')) THEN !OPEN TMP FILE
	  CALL WNCTXT(F_TP,'Cannot open TMP file (!XJ)',E_C)
	  GOTO 900
	END IF
	VOLUME=' '				!DEFAULT NO VOLUME
	IF (UNIT.NE.'D') VOLUME=WNFTVL(IMCA)	!GET VOLUME HEADER
C
	J1=0					!JOB COUNT
 30	CONTINUE
	J1=J1+1					!NEXT JOB
	IF (J1.GT.NJOB) GOTO 900		!READY
	J=0					!START LABEL INPUT
	IF (OUT) THEN
	  IF (.NOT.WNDLNG(GFH_LINKG_1,0,SGH_GROUPN_1,FCAOUT,SGPH(0),
	1		SGNR(0))) THEN
	    CALL WNCTXT(F_TP,'!/Cannot create sub-group')
	    GOTO 800				!NEXT JOB
	  END IF				!SUB-GROUP LINKED
	  CALL WNCTXT(F_P,'!_')			!NEW PAGE
	  CALL WNCTXT(F_TP,'!/Job !UJ\: Group !UJ',J1,SGNR(0))
	ELSE
	  CALL WNCTXT(F_TP,
	1	   'Label Seq.nr    Fieldname    Pro- '//
	1	   'Duration   Obs.-time       RA         Dec   ')
	  CALL WNCTXT(F_TP,
	1	   '                             ject '//
	1	   '  hhmm    yyddd hhmm      deg         deg   ')
	END IF
C
C DO A LABEL
C
 10	CONTINUE
	J=J+1					!COUNT INPUT LABEL
	IF (NLAB(J1).LT.0) THEN			!ALL LABELS ON TAPE
	  J0=J					!NEXT INPUT LABEL
	ELSE IF (J.LE.NLAB(J1)) THEN
	  J0=ILAB(J,J1)				!NEXT INPUT LABEL
	ELSE
	  GOTO 800				!READY WITH JOB
	END IF
C
C Check MEDIAD, If label does not exist (probably deleted), skip and go to next
C
	IF (UNIT.NE.'D' .AND. UNIT.NE.'1') THEN
	  CALL WNCTXS(WARC,
	1    'SELECT=MEDIAD VOLUME=!AS LABEL=!UJ ',
	1    VOLUME(5:10),J0)
	  J2=WNFSCI(WARC)
	  IF (MOD(J2,100).NE.0) THEN
	     CALL WNFSCS(WARC)
	     CALL WNCTXT(F_TP,'Label !UJ can not be used, '//
	1	'it is probably deleted in archive MEDIAD',J0)
	     GOTO 10				!NEXT LABEL
	  END IF
	  IF (J.EQ.1) THEN
	     J2=WNFSCC()
	     IF (MOD(J2,100).NE.0) THEN
	        CALL WNFSCS(WARC)
	        CALL WNCTXT(F_TP,'Could not close archive MEDIAD, error !SJ',J2)
	        GOTO 10				!NEXT LABEL
	     END IF
	  END IF
	END IF
C
C OPEN INPUT
C
	IF (UNIT.EQ.'D') THEN			!DISK INPUT
	  CALL WNCTXS(LTXT,'!6$ZJ',J0)		!MAKE LABEL NAME
	  IF (.NOT.WNFOP(IMCA,IFILE(1:WNCALN(IFILE))//'.'//LTXT,'R')) THEN
	    IF (NLAB(J1).GT.0)
	1	CALL WNCTXT(F_XX,'Cannot find file !AS\.!AS',IFILE,LTXT)
	    GOTO 800				!STOP JOB
	  END IF
	ELSE					!TAPE INPUT
	  IF (.NOT.WNFOPF(IMCA,' ','R',0,0,0,J0)) THEN
	    CALL WNCTXT(F_XX,'Cannot find label !UJ',J0)
	    GOTO 800				!NEXT JOB
	  END IF
	END IF
	IF (OUT) THEN
	  IF (.NOT.WNDLNG(SGPH(0)+SGH_LINKG_1,0,SGH_GROUPN_1,FCAOUT,
	1		SGPH(1),SGNR(1))) THEN	!LINK SUB-GROUP
	    CALL WNCTXT(F_TP,'!/Cannot create sub-group')
	    GOTO 700				!NEXT LABEL
	  END IF
	  CALL WNCTXT(F_TP,'!4CLabel !3$UJ: Sub-group !UJ\.!UJ',
	1		J0,SGNR(0),SGNR(1))
	END IF
C
C READ FD-BLOCK
C
	J2=0					!DATA POINTER
 20	CONTINUE
	IF (.NOT.WNFRD(IMCA,FDLHDL,FDL,J2)) THEN !READ FD BLOCK
	  CALL WNCTXT(F_XX,'Read error FD at !XJ',J2)
	  GOTO 700				!NEXT LABEL
	END IF
	IBMSW=.FALSE.				!ASSUME NON-IBM
	DECSW=.FALSE.				!ASSUME LOCAL
	IF (FDL(FDL_CBT_1).NE.ICHAR('F') .OR.
	1	FDL(FDL_CBT_1+1).NE.ICHAR('D')) THEN
	  IBMSW=.TRUE.				!ASSUME IBM
	  CALL WNTTIL(FDLHDL,FDL,FDL_T)		!TRANSLATE
	  IF (FDL(FDL_CBT_1).NE.ICHAR('F') .OR.
	1	FDL(FDL_CBT_1+1).NE.ICHAR('D')) THEN
 23	    CONTINUE
	    CALL WNCTXT(F_XX,'Cannot find FD block')
	    GOTO 700				!NEXT LABEL
	  END IF
	ELSE IF (FDLI(FDL_CBI_I).NE.32767) THEN
	  DECSW=.TRUE.				!ASSUME FROM DEC
	  CALL WNTTDL(FDLHDL,FDL,FDL_T)		!TRANSLATE
	  IF (FDLI(FDL_CBI_I).NE.32767) GOTO 23
C
C	DECStation/Alpha has the same swapping sequence as VAX D/G,
C	but uses IEEE floating point format. The test on FDL_CBI is
C	therefore not sufficient. Since raw data is assumed to be in
C	IBM (type -1) or VAX D (type 1) format, the following test is
C	safe and sufficient. 
C
	ELSE IF (PRGDAT.EQ.6) THEN
	  DECSW=.TRUE.				!ASSUME FROM DEC
	  CALL WNTTDL(FDLHDL,FDL,FDL_T)		!TRANSLATE
	  IF (FDLI(FDL_CBI_I).NE.32767) GOTO 23
	END IF
C
C GET POLARISATIONS TO DO
C
	DO I=0,3				!SET POL. TO DO
	  POLS(I)=1				!SET WANTED
	END DO
	NPOL=4					!CNT POL
	ONS(1)=-1
C
C MAKE SET HEADER TEMPLATE
C
	CALL WNGMVZ(STHHDL,STH(0))		!CLEAR
	STHI(STH_LEN_I)=STHHDL			!LENGTH
	STHI(STH_VER_I)=STHHDV			!VERSION
	STHJ(STH_NIFR_J)=FDLI(FDL_NRINTF_I)	!# OF INTERF.
	STHI(STH_CHAN_I)=FDLI(FDL_FREQBND_I)	!FREQUENCY BAND
C	STHI(STH_BEC_I)=IAND('0000ffff'X,OHWJ(OHW_CONFNR_J)) !BACKEND CODE
	IF (OUT) THEN
	   IF (.NOT.WNDLNF(SGPH(1)+SGH_LINKG_1,0,SGH_GROUPN_1,FCAOUT,
	1	SGPH(2),SGNR(2))) THEN !FIND/CREATE SUB-GROUP
	      CALL WNCTXT(F_TP,'!/Cannot link sub-group')
	      GOTO 700				!NEXT LABEL
	   END IF
	END IF
	FVERS=FDLI(FDL_FVERS_I)			!Tape version format
	NBL=FDLJ(FDL_NBL_J)			!# OF BLOCKS WITHIN DATASET
	BYPBL=FDLI(FDL_BYPBL_I)			!# BYTES PER BLOCK
	FBNDS=FDLI(FDL_FREQBND_I)		!First freq.band
	FBNDE=FDLI(FDL_FREQBND_I)+FDLI(FDL_TOTFREQ_I)-1  !Last freq.band
C
C MAKE TMP FILE
C
	NCHT=0					!COUNT SELECTED
	NIFR=0					!NO IFR SEEN
	I3=STHI(STH_CHAN_I)			!FREQ.BAND
	FWGT=0					!MAX. WEIGHT
C
C READ INTERFEROMETERS
C
	IF (.NOT.NLEIRD(IMCA,FCAT,FDLI(FDL_NRINTF_I),FDLJ(FDL_OFFINTF_J),
	1    BINT,INTOFF(J1),ONS,OHAB,MJDHA0,NIFR,IFRT,
	1    STH,STHI,STHJ,STHE,STHD,
	1    OBSDATE,OBSSTART,OBSEND,OLSYS,PRNAME,FIELD,
	1    FWGT,DIPOLE,DBUF,TMPBUF)) GOTO 700
	IF (OUT) THEN
	   IF (NIFR.GT.0) THEN	!SOME TO WRITE
	      STHE(STH_WFAC_E)=1.-FWGT
	      IF (.NOT.NLEIWD(FCAT,ONS,OHAB,NIFR,IFRT,POLS,
	1	   BINT,STH(0),MJDHA0,J1,I3,
	1	   FWGT,TMPBUF)) GOTO 700
	   END IF
	ELSE
	   CALL NLEILU (TYP,VOLUME(5:10),J0,FVERS,
	1		OBSDATE,OBSSTART,OBSEND,OLSYS,PRNAME,FIELD,
	1		NBL,BYPBL,FBNDS,FBNDE,DIPOLE,
	1		STH,STHI,STHJ,STHE,STHD)
	END IF
C
C FINISH LABEL
C
 700	CONTINUE
	CALL WNFCL(IMCA)			!CLOSE LABEL
	GOTO 10					!NEXT LABEL
C
C FINISH JOB
C
 800	CONTINUE
	GOTO 30					!NEXT JOB
C
C READY
C
 900	CALL WNFCL(IMCA)			!CLOSE INPUT
	CALL WNFDMO(IMCA)			!DISMOUNT INPUT
	CALL WNFCL(FCAT)			!CLOSE/DELETE TMP FILE
	IF (OUT) THEN
	   CALL NSCPFH(F_TP,FCAOUT)		!SHOW FILE HEADER
	   CALL NSCPFL(F_TP,FCAOUT,NODOUT,.FALSE.)	!SHOW LAYOUT
	   CALL WNFCL(FCAOUT)			!CLOSE OUTPUT
	END IF
C
	RETURN					!READY
C
C
	END
