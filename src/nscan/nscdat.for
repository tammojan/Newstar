C+ NSCDAT.FOR
C  WNB 900130
C
C  Revisions:
C	WNB 910826	Retain parameters
C	WNB 911031	Add WERR
C	HjV 920520	HP does not allow extended source lines
C	WNB 920814	More buffers in output file for LOAD
C	WNB 921221	Add AERR
C	JPH 930416	L_x/L_B --> LB_x. - Headings
C	HJV/JPH 930524	Keywords xxx_SCAN --> xxx_SCN_NODE, SETS --> SCN_SETS
C	HjV 930607	Change keyword INOUT_SCN_NODE to SCN_NODE
C	WNB 930819	Add NOPT
C	JPH 931007	Correct default label for DUMP and UVFITS disk output
C	CMV 931220	Pass FCA of input file to WNDXLP and WNDSTA/Q
C	CMV 940223	New option LIST
C	CMV 940422	Add LOADIF option and IFSETS prompt
C       HjV 940519      Add OLD_DATTYP
C	CMV 940808	Add call to WNFMLI to list tape definitions
C       HjV 941107	Add OUTPUT_VOLUME
C	JPH 950109	Correct backtrack targets, ADD WNFCLS.
C			Consistently interpret #/cntrl-D as backtrack request. 
C			 (It was treated as a null reply in a few cases.)
C	JPH 950118	WARC option (CMV 941012)
C	CMV 950123	Add suboptions for WARC
C       HjV 950116	Add LEIDEN, change LOADIF in IFLOAD
C	HjV 951113	Change WARC into ARC. Add another subsection for ARC.
C	CMV 970206	Add BITPIX for UVFITS
C
	SUBROUTINE NSCDAT
C
C  Get NSCAN program parameters
C
C  Result:
C
C	CALL NSCDAT	will ask and set all program parameters
C
C PIN references:
C
C	OPTION
C	WERR_OPTION
C	INPUT_UNIT
C	OUTPUT_UNIT
C	INPUT_FILE
C	OUTPUT_FILE
C       OUTPUT_VOLUME
C	INPUT_LABELS
C	OUTPUT_LABEL
C	INTEGRATION TIME
C	CHANNELS
C	POINTING SETS
C	OUTPUT_SCN_NODE
C	INPUT_SCN_NODE
C	SCN_NODE
C	SCN_SETS
C	POLARISATION
C	UVFITS_POLAR
C	HAB_OFFSET
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'CBITS_DEF'
	INCLUDE 'NSC_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
C
C  Function references:
C
	LOGICAL WNDPAR			!GET DWARF PARAMETER
	LOGICAL WNDNOD			!GET NODE NAME
	LOGICAL WNFMOU			!MOUNT TAPE
	LOGICAL WNFOP,WNFOPF		!OPEN FILE
	CHARACTER*80 WNFTVL		!GET VOLUME HEADER
	LOGICAL WNDSTQ			!GET SETS TO DO
	LOGICAL NSCPLS,NSCPL2		!GET POL. TO DO/USE
C
C  Data declarations:
C
	INTEGER POLCD			!DEFAULT POLARISATION
	CHARACTER*80 VOLHD		!VOLUME HEADER
	CHARACTER*160 FILOUT		!OUTPUT FILE NAME
	CHARACTER*6 ARCWHO		!WHAT KIND OF TAPE: WSRT OR LEIDEN
C-
c %*(L_J/L_B)%*LB_J% %*(L_E/L_B)%*LB_E% %,L_J/L_B%,LB_J% %,L_E/L_B%,LB_E%
C
C SET DEFAULTS
C
	UNIT='""'
	IFILE='""'
	OUNIT='""'
	NODIN=' '
	OINT=120
	NODOUT=' '
	NLAB(1)=0
	NPTC(1)=0
	NCHAN(1)=0
	POLCD=XYX_M
	INTOFF(1)=0
	OFILE='""'
	OLAB=0
	SETS(0,0)=0
C
C GET OPTION
C
 100	CONTINUE
	IF (.NOT.WNDPAR('OPTION',OPTION,LEN(OPTION),J0,'QUIT')) THEN
	  OPTION='QUIT'				!ASSUME END
	ELSE IF (J0.LE.0) THEN
	  OPTION='QUIT'				!ASSUME END
	END IF

C ****************************************************************************
C LOAD/LIST WSRT
C ****************************************************************************
	IF (OPT.EQ.'LOA'.OR.OPT.EQ.'IFL'.OR.OPT.EQ.'LEI'.OR.
	1	OPT.EQ.'LIS'.OR.OPT.EQ.'ARC') THEN	!LOAD/LIST WSRT/LEIDEN
C
	   IF (OPT.EQ.'ARC' .OR. OPT.EQ.'LIS') THEN	!GET SUBOPTION
 8	      CONTINUE
	      IF (.NOT.WNDPAR('TYPE_TAPE',ARCWHO,LEN(ARCWHO),
	1	   J0,'WSRT')) THEN
		 IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
		 GOTO 8					!REPEAT
	      ELSE IF (J0.EQ.0) THEN
		 GOTO 100				!RETRY OPTION
	      ELSE IF (J0.LT.0) THEN
		 GOTO 8					!MUST SPECIFY
	      END IF
	      IF (OPT.EQ.'LIS') OPTION=ARCWHO(1:1)//'IST'
	   END IF

	   IF (OPT.EQ.'ARC') THEN			!GET SUBOPTION
 9	      CONTINUE
	      IF (.NOT.WNDPAR('ARC_OPTION',OPTION,LEN(OPTION),
	1	   J0,'ARCHIVE')) THEN
		 IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
		 GOTO 9					!REPEAT
	      ELSE IF (J0.EQ.0) THEN
		 GOTO 100				!RETRY OPTION
	      ELSE IF (J0.LT.0) THEN
		 GOTO 9					!MUST SPECIFY
	      END IF
	      OPTION=ARCWHO(1:1)//'AR'//OPTION(1:1)
	   ENDIF
C
 10	  CONTINUE
	  IF (.NOT.WNDPAR('INPUT_UNIT',UNIT,LEN(UNIT),J0,UNIT)) THEN !GET UNIT
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
	    GOTO 10				!REPEAT
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN	!LIST TAPEUNITS AND RETRY
	    CALL WNFMLI()
	    GOTO 10
	  ELSE IF (J0.EQ.0) THEN
	    GOTO 100				!RETRY OPTION
	  ELSE IF (J0.LT.0) THEN
	    GOTO 10				!MUST SPECIFY
	  END IF
	  IF (UNIT.EQ.'D') THEN			!DISK INPUT
 11	    CONTINUE
	    IF (.NOT.WNDPAR('INPUT_FILE',IFILE,LEN(IFILE),J0,IFILE)) THEN
	      IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 10	!RETRY UNIT
	      GOTO 11				!REPEAT
	    ELSE IF (J0.EQ.0) THEN
	      GOTO 10				!RETRY UNIT
	    ELSE IF (J0.LT.0) THEN
	      GOTO 11				!MUST SPECIFY
	    END IF
	  ELSE					!TAPE INPUT
	    IF (.NOT.WNFMOU(IMCA,UNIT,'R')) THEN !MOUNT TAPE
	      CALL WNCTXT(F_TP,'Cannot mount tape on unit !AS (!XJ)'
	1			,UNIT,E_C)
	      GOTO 10				!RETRY UNIT
	    END IF
	    VOLHD=WNFTVL(IMCA)			!GET VOLUME HEADER
	    IF (VOLHD(1:4).EQ.'VOL1') THEN
	      CALL WNCTXT(F_TP,'!/Volume !AS mounted on unit !AS!/',
	1			VOLHD(5:10),UNIT)
	    ELSE
	      CALL WNCTXT(F_TP,'!/Unlabeled tape mounted on unit !AS!/',
	1			UNIT)
	    END IF
	  END IF
	  IF (OPT.EQ.'LOA'.OR.OPT.EQ.'IFL'.OR.OPT.EQ.'LEI') THEN
	     IF (OPT.EQ.'LOA'.OR.OPT.EQ.'IFL') THEN
 19	       CONTINUE
	       IF (.NOT.WNDPAR('INTEGRATION_TIME',OINT,LB_J,J0,
	1		A_B(-A_OB),OINT,1)) THEN
	         IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 10	!RETRY UNIT
	         GOTO 19				!REPEAT
	       ELSE IF (J0.EQ.0) THEN
	         GOTO 10				!RETRY UNIT
	       ELSE IF (J0.LT.0) THEN
	         GOTO 19				!MUST SPECIFY
	       END IF
	       OINT=MAX(10,OINT)
C
 18	       CONTINUE
	       IFSETS=0					!DEFAULT: NONE
	       IF (OPTION(1:6).EQ.'IFLOAD') THEN
	         IF (.NOT.WNDPAR('IFSETS',IFSETS,LB_J,J0,'60')) THEN
	           IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 10	!RETRY UNIT
	           GOTO 18				!REPEAT
	         ELSE IF (J0.EQ.0) THEN
	           GOTO 10				!RETRY UNIT
	         ELSE IF (J0.LT.0) THEN
	           IFSETS=18				!MUST SPECIFY
	         END IF
	       END IF
	     END IF
C
 30	     CONTINUE
	     CALL WNFCL(FCAOUT)
	     IF (.NOT.WNDNOD('OUTPUT_SCN_NODE',NODOUT,'SCN',
	1		'U',NODOUT,FILOUT)) THEN
	       IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 10!RETRY UNIT
	       GOTO 30				!REPEAT
	     ELSE IF (E_C.EQ.DWC_NULLVALUE) THEN
	       GOTO 10				!RETRY UNIT
	     ELSE IF (E_C.EQ.DWC_WILDCARD) THEN
	       GOTO 30				!MUST SPECIFY
	     END IF
	     IF (.NOT.WNFOPF(FCAOUT,FILOUT,'U',10,0,0,0)) THEN !OUTPUT SCAN FILE
	       GOTO 30				!RETRY
	     END IF
	  END IF
C
C GET JOBS
C
	  NJOB=0				!# OF JOBS
 15	  CONTINUE
	  IF (NJOB.GE.MXNJOB) GOTO 900		!NO MORE
	  NJOB=NJOB+1
 16	  CONTINUE
	  IF (OPT.EQ.'LOA'.OR.OPT.EQ.'IFL'.OR.OPT.EQ.'LEI') 
	1      CALL WNCTXT(F_TP,
	1	'!/Specify parameters for job !UJ\:!/',NJOB)
 14	  CONTINUE
	  IF (NJOB.EQ.1) THEN			!DEFAULTS
	    IF (NLAB(NJOB).LE.0) THEN
	      JS=WNDPAR('INPUT_LABELS',ILAB(1,NJOB),
	1			MXNLAB*LB_J,NLAB(NJOB),'*')
	    ELSE
	      JS=WNDPAR('INPUT_LABELS',ILAB(1,NJOB),
	1			MXNLAB*LB_J,NLAB(NJOB),
	1			A_B(-A_OB),ILAB(1,NJOB),NLAB(NJOB))
	    END IF
	  ELSE
	    IF (NLAB(NJOB).LE.0) THEN
	      JS=WNDPAR('INPUT_LABELS',ILAB(1,NJOB),
	1			MXNLAB*LB_J,NLAB(NJOB),'""')
	    ELSE
	      JS=WNDPAR('INPUT_LABELS',ILAB(1,NJOB),
	1			MXNLAB*LB_J,NLAB(NJOB),
	1			A_B(-A_OB),ILAB(1,NJOB),NLAB(NJOB))
	    END IF
	  END IF
	  IF (.NOT.JS) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) THEN	!READY
!!	      NJOB=NJOB-1			!NO MORE JOBS
!!	      GOTO 900
	      GOTO 10
	    END IF
	    GOTO 14				!RETRY
	  END IF
	  IF (NLAB(NJOB).EQ.0) THEN		!READY
	    NJOB=NJOB-1
	    GOTO 900
	  END IF
	  IF (NJOB.LT.MXNJOB) NLAB(NJOB+1)=0	!DEFAULT FOR NEXT
	  IF (OPT.EQ.'LEI') THEN
	     POL(NJOB)=XYX_M			!XX, XY, YX, YY
	     GOTO 900				!ONLY ONE JOB
	  END IF
 191	  CONTINUE
	  IF (OPT.EQ.'WAR' .OR. OPT.EQ.'LAR' .OR. OPT.EQ.'LIS') THEN
	    IPTC(1,NJOB)=1
	    NPTC(NJOB)=1
	  ELSEIF (OPT.EQ.'WIS') THEN
	    JS=WNDPAR('POINTING_SETS',IPTC(1,NJOB),MXNPTC*LB_J,
	1			NPTC(NJOB),'1')	!JUST ONE FOR THE LIST
	  ELSE IF (NPTC(NJOB).EQ.0) THEN
	    JS=WNDPAR('POINTING_SETS',IPTC(1,NJOB),MXNPTC*LB_J,
	1			NPTC(NJOB),'*')	!GET CHANNELS TO DO
	  ELSE
	    JS=WNDPAR('POINTING_SETS',IPTC(1,NJOB),MXNPTC*LB_J,
	1			NPTC(NJOB),A_B(-A_OB),
	1			IPTC(1,NJOB),NPTC(NJOB))
	  END IF
	  IF (.NOT.JS) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 16	!RETRY JOB
	    GOTO 191				!ERROR
	  END IF
	  IF (NPTC(NJOB).EQ.0) GOTO 16		!RETRY JOB
	  IF (NJOB.LT.MXNJOB) NPTC(NJOB+1)=0	!DEFAULT FOR NEXT
 17	  CONTINUE
	  IF (OPT.EQ.'LOA'.OR.OPT.EQ.'IFL') THEN
	     IF (NCHAN(NJOB).LE.0) THEN
	       JS=WNDPAR('CHANNELS',CHAN(1,NJOB),MXNCHN*LB_J,
	1			NCHAN(NJOB),'*') !GET CHANNELS TO DO
	     ELSE
	       JS=WNDPAR('CHANNELS',CHAN(1,NJOB),MXNCHN*LB_J,
	1			NCHAN(NJOB),A_B(-A_OB),
	1			CHAN(1,NJOB),NCHAN(NJOB))
	     END IF
	     IF (.NOT.JS) THEN
	       IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 16 !RETRY JOB
	       GOTO 17				 !ERROR
	     END IF
	     IF (NCHAN(NJOB).EQ.0) GOTO 16	 !RETRY JOB
	     IF (NJOB.LT.MXNJOB) NCHAN(NJOB+1)=0 !DEFAULT FOR NEXT
C
	     IF (.NOT.NSCPLS(0,POLCD)) GOTO 16	!GET POLARISATIONS
	     POLCD=IOR(POLCD,X_M)		!MAKE SURE ALWAYS XX
	     IF (IAND(POLCD,YX_M).NE.0) POLCD=XYX_M !MAKE SURE NO ISOLATED XY,YX
	     POL(NJOB)=POLCD			!SAVE
C
 181	     CONTINUE
	     IF (.NOT.WNDPAR('HAB_OFFSET',INTOFF(NJOB),LB_E,J0,
	1		A_B(-A_OB),INTOFF(NJOB),1)) THEN
	       IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 16 !RETRY JOB
	       GOTO 181				 !ERROR
	     END IF
	     IF (J0.EQ.0) GOTO 16		!RETRY JOB
	     IF (J0.LT.0) INTOFF(NJOB)=0	!SET NO OFFSET
C
	     INTOFF(NJOB)=MAX(0.,INTOFF(NJOB))
	     IF (NJOB.LT.MXNJOB) INTOFF(NJOB+1)=INTOFF(NJOB)
	     GOTO 15				!MORE JOBS
	  ELSE
	     POL(NJOB)=0			!LOAD NOTHING FOR LIST
	     GOTO 900				!ONLY ONE JOB
	  END IF

C ****************************************************************************
C DUMP WSRT
C ****************************************************************************
	ELSE IF (OPT.EQ.'DUM') THEN
 20	  CONTINUE
	  IF (.NOT.WNDPAR('INPUT_UNIT',UNIT,LEN(UNIT),J0,UNIT)) THEN !GET UNIT
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
	    GOTO 20				!REPEAT
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN	!LIST TAPEUNITS AND RETRY
	    CALL WNFMLI()
	    GOTO 20
	  ELSE IF (J0.EQ.0) THEN
	    GOTO 100				!RETRY OPTION
	  ELSE IF (J0.LT.0) THEN
	    GOTO 20				!MUST SPECIFY
	  END IF
	  IF (UNIT.EQ.'D') THEN			!DISK INPUT
 21	    CONTINUE
	    IF (.NOT.WNDPAR('INPUT_FILE',IFILE,LEN(IFILE),J0,IFILE)) THEN
	      IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 20	!RETRY UNIT
	      GOTO 21				!REPEAT
	    ELSE IF (J0.EQ.0) THEN
	      GOTO 20				!RETRY UNIT
	    ELSE IF (J0.LT.0) THEN
	      GOTO 21				!MUST SPECIFY
	    END IF
	  ELSE					!TAPE INPUT
	    IF (.NOT.WNFMOU(IMCA,UNIT,'R')) THEN !MOUNT TAPE
	      CALL WNCTXT(F_TP,'Cannot mount tape on unit !AS (!XJ)',
	1			UNIT,E_C)
	      GOTO 20				!RETRY UNIT
	    END IF
	    VOLHD=WNFTVL(IMCA)			!GET VOLUME HEADER
	    IF (VOLHD(1:4).EQ.'VOL1') THEN
	      CALL WNCTXT(F_TP,'!/Volume !AS mounted on unit !AS!/',
	1			VOLHD(5:10),UNIT)
	    ELSE
	      CALL WNCTXT(F_TP,'!/Unlabeled tape mounted on unit !AS!/',
	1			UNIT)
	    END IF
	  END IF
 22	  CONTINUE
	  IF (.NOT.WNDPAR('OUTPUT_UNIT',OUNIT,LEN(OUNIT),J0,OUNIT)) THEN !OUTPUT
	    IF (E_C.EQ.DWC_ENDOFLOOP) THEN	!RETRY OPTION
	      CALL WNFDMO(IMCA)			!DISMOUNT
	      GOTO 20				!RETRY INPUT_UNIT
	    END IF
	    GOTO 22				!REPEAT
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN	!LIST TAPEUNITS AND RETRY
	    CALL WNFMLI()
	    GOTO 22
	  ELSE IF (J0.EQ.0) THEN
	    CALL WNFDMO(IMCA)			!DISMOUNT INPUT
	    GOTO 100				!RETRY OPTION
	  ELSE IF (J0.LT.0) THEN
	    GOTO 22				!MUST SPECIFY
	  END IF
	  IF (OUNIT.EQ.'D') THEN		!DISK OUTPUT
 23	    CONTINUE
	    IF (.NOT.WNDPAR('OUTPUT_FILE',OFILE,LEN(OFILE),J0,OFILE)) THEN
	      IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 20	!RETRY UNIT
	      GOTO 23				!REPEAT
	    ELSE IF (J0.EQ.0) THEN
	      GOTO 22				!RETRY UNIT
	    ELSE IF (J0.LT.0) THEN
	      GOTO 23				!MUST SPECIFY
	    END IF
	  ELSE					!TAPE OUTPUT
	    IF (.NOT.WNFMOU(OMCA,OUNIT,'W')) THEN !MOUNT TAPE
	      CALL WNCTXT(F_TP,'Cannot mount tape on unit !AS (!XJ)',
	1			OUNIT,E_C)
	      GOTO 22				!RETRY UNIT
	    END IF
	    VOLHD=WNFTVL(OMCA)			!GET VOLUME HEADER
	    IF (VOLHD(1:4).EQ.'VOL1') THEN
	      CALL WNCTXT(F_TP,'!/Volume !AS mounted on unit !AS!/',
	1			VOLHD(5:10),OUNIT)
	      OFILE=VOLHD(5:10)
	    ELSE
	      CALL WNCTXT(F_TP,'!/Unlabeled tape mounted on unit !AS!/',
	1			OUNIT)
 27	      CONTINUE
	      IF (.NOT.WNDPAR('OUTPUT_VOLUME',OFILE,LEN(OFILE),J0,'""')) THEN
	        IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 22	!RETRY UNIT
	        GOTO 27				!REPEAT
	      ELSE IF (J0.EQ.0) THEN
	        GOTO 22				!RETRY UNIT
	      ELSE IF (J0.LT.0) THEN
	        GOTO 27				!MUST SPECIFY
	      END IF
	    END IF
	  END IF
 24	  CONTINUE
	  IF (NLAB(1).LE.0) THEN
	    JS=WNDPAR('INPUT_LABELS',ILAB(1,1),MXNLAB*LB_J,
	1			NLAB(1),'*')
	  ELSE
	    JS=WNDPAR('INPUT_LABELS',ILAB(1,1),MXNLAB*LB_J,
	1			NLAB(1),A_B(-A_OB),
	1			ILAB(1,1),NLAB(1))
	  END IF
	  IF (.NOT.JS) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) THEN	!NONE
!!	      NLAB(1)=0				!NONE SPECIFIED
!!	    ELSE
!!	      GOTO 24				!RETRY
	      GOTO 20
	    END IF
	  END IF
 25	  CONTINUE
	  IF (OUNIT.EQ.'D' .AND. OLAB.EQ.0) 	!Correct default for disk label
	1	OLAB=1				! is 1
	  IF (.NOT.WNDPAR('OUTPUT_LABEL',OLAB,LB_J,J0,
	1		A_B(-A_OB),OLAB,1)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) THEN	!RETRY OPTION
!!	      J0=0				!NOT SPECIFIED
!!	    ELSE
!!	      GOTO 25				!RETRY
	      GOTO 20
	    END IF
	  END IF
	  IF (J0.LE.0) OLAB=0			!START AT EOT
	  IF (OUNIT.EQ.'D' .AND. OLAB.EQ.0) 	!Correct default for disk label
	1	OLAB=1				! is 1

C ****************************************************************************
C FROM OLD
C ****************************************************************************
	ELSE IF (OPT.EQ.'FRO') THEN
 40	  CONTINUE
	  IF (.NOT.WNDPAR('INPUT_FILE',IFILE,LEN(IFILE),J0,IFILE)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
	    GOTO 40				!REPEAT
	  ELSE IF (J0.EQ.0) THEN
	    GOTO 100				!RETRY OPTION
	  ELSE IF (J0.LT.0) THEN
	    GOTO 40				!MUST SPECIFY
	  END IF
          IF (.NOT.WNDPAR('OLD_DATTYP',DECSW,LB_J,J0,'0')) THEN
            IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100  !RETRY OPTION
            GOTO 90                             !RETRY
          END IF
          IF (J0.EQ.0) GOTO 100                 !RETRY OPTION
          IF (J0.LT.0) GOTO 40                  !MUST SPECIFY
 41	  CONTINUE
	  CALL WNFCL(FCAOUT)
	  IF (.NOT.WNDNOD('OUTPUT_SCN_NODE',NODOUT,'SCN',
	1		'U',NODOUT,FILOUT)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 40	!RETRY FILE
	    GOTO 41				!REPEAT
	  ELSE IF (E_C.EQ.DWC_NULLVALUE) THEN
	    GOTO 40				!RETRY FILE
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN
	    GOTO 41				!MUST SPECIFY
	  END IF
	  IF (.NOT.WNFOP(FCAOUT,FILOUT,'U')) THEN !OPEN OUTPUT SCAN FILE
	    GOTO 41				!RETRY
	  END IF

C ****************************************************************************
C TO OLD
C ****************************************************************************
	ELSE IF (OPT.EQ.'TO_') THEN
 50	  CONTINUE
	  IF (.NOT.WNDPAR('OUTPUT_FILE',OFILE,LEN(OFILE),J0,OFILE)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
	    GOTO 50				!REPEAT
	  ELSE IF (J0.EQ.0) THEN
	    GOTO 100				!RETRY OPTION
	  ELSE IF (J0.LT.0) THEN
	    GOTO 50				!MUST SPECIFY
	  END IF
 51	  CONTINUE
	  CALL WNFCL(FCAOUT)
	  IF (.NOT.WNDNOD('INPUT_SCN_NODE',NODIN,'SCN','R',NODIN,IFILE)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 50	!RETRY FILE
	    GOTO 51				!REPEAT
	  ELSE IF (E_C.EQ.DWC_NULLVALUE) THEN
	    GOTO 50				!RETRY FILE
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN
	    GOTO 51				!MUST SPECIFY
	  END IF
	  IF (.NOT.WNFOP(FCAIN,IFILE,'R')) THEN	!OPEN INPUT SCAN FILE
	    GOTO 51				!RETRY
	  END IF
 52	  CONTINUE
	  IF (.NOT.WNDSTQ('SCN_SETS',MXNSET,SETS)) THEN !SETS TO COPY
	    CALL WNFCL(FCAIN)
	    GOTO 50				!RETRY FILE
	  END IF
	  IF (SETS(0,0).EQ.0) GOTO 52		!NO SETS SPECIFIED

C ****************************************************************************
C CONVERT VAX TO LOCAL
C ****************************************************************************
C
	ELSE IF (OPT.EQ.'CVX') THEN
 60	  CONTINUE
 61	  CONTINUE
	  CALL WNFCL(FCAOUT)
	  IF (.NOT.WNDNOD('SCN_NODE',NODOUT,'SCN',
	1		'R',NODOUT,FILOUT)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
	    GOTO 61				!REPEAT
	  ELSE IF (E_C.EQ.DWC_NULLVALUE) THEN
	    GOTO 100				!RETRY OPTION
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN
	    GOTO 61				!MUST SPECIFY
	  END IF
	  IF (.NOT.WNFOP(FCAOUT,FILOUT,'U')) THEN !OPEN OUTPUT SCAN FILE
	    GOTO 61				!RETRY
	  END IF
C ****************************************************************************
C CONVERT TO NEWEST VERSION; OPTION
C ****************************************************************************
	ELSE IF (OPT.EQ.'NVS' .OR. OPT.EQ.'NOP') THEN
 70	  CONTINUE
 71	  CONTINUE
	  CALL WNFCL(FCAOUT)
	  IF (.NOT.WNDNOD('SCN_NODE',NODOUT,'SCN',
	1		'R',NODOUT,FILOUT)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
	    GOTO 71				!REPEAT
	  ELSE IF (E_C.EQ.DWC_NULLVALUE) THEN
	    GOTO 100				!RETRY OPTION
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN
	    GOTO 71				!MUST SPECIFY
	  END IF
	  IF (.NOT.WNFOP(FCAOUT,FILOUT,'U')) THEN !OPEN OUTPUT SCAN FILE
	    GOTO 71				!RETRY
	  END IF
C ****************************************************************************
C CONVERT MOSAIC TAPE ERROR
C ****************************************************************************
	ELSE IF (OPT.EQ.'WER' .OR. OPT.EQ.'AER'
	1	.OR. OPT.EQ.'VFI') THEN
 72	  CONTINUE
	  IF (OPT.EQ.'WER') THEN
	    IF (.NOT.WNDPAR('WERR_OPTION',OPTION,
	1		LEN(OPTION),J0,'QUIT')) THEN
	      OPTION='QUIT'			!ASSUME END
	    ELSE IF (J0.LE.0) THEN
	      OPTION='QUIT'			!ASSUME END
	    END IF
	    IF (OPT.EQ.'QUI') GOTO 100		!RETRY OPTION
	  END IF
 73	  CONTINUE
	  CALL WNFCL(FCAOUT)
	  IF (.NOT.WNDNOD('SCN_NODE',NODOUT,'SCN',
	1		'R',NODOUT,FILOUT)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
	    GOTO 73				!REPEAT
	  ELSE IF (E_C.EQ.DWC_NULLVALUE) THEN
	    GOTO 100				!RETRY OPTION
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN
	    GOTO 73				!MUST SPECIFY
	  END IF
	  IF (.NOT.WNFOP(FCAOUT,FILOUT,'U')) THEN !OPEN OUTPUT SCAN FILE
	    GOTO 73				!RETRY
	  END IF
 74	  CONTINUE
	  IF (.NOT.WNDSTQ('SCN_SETS',MXNSET,SETS,FCAOUT)) THEN !SETS TO CORRECT
	    CALL WNFCL(FCAOUT)
	    GOTO 73				!RETRY FILE
	  END IF
	  IF (SETS(0,0).EQ.0) GOTO 74		!NO SETS SPECIFIED

C ****************************************************************************
C WRITE UVFITS
C ****************************************************************************
	ELSE IF (OPT.EQ.'UVF') THEN
 82	  CONTINUE
	  IF (.NOT.WNDPAR('OUTPUT_UNIT',OUNIT,LEN(OUNIT),J0,OUNIT)) THEN !OUTPUT
	    IF (E_C.EQ.DWC_ENDOFLOOP) THEN	!RETRY OPTION
	      GOTO 100				!RETRY OPTION
	    END IF
	    GOTO 82				!REPEAT
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN	!LIST TAPEUNITS AND RETRY
	    CALL WNFMLI()
	    GOTO 82
	  ELSE IF (J0.EQ.0) THEN
	    GOTO 100				!RETRY OPTION
	  ELSE IF (J0.LT.0) THEN
	    GOTO 82				!MUST SPECIFY
	  END IF
	  IF (OUNIT.EQ.'D') THEN		!DISK OUTPUT
 83	    CONTINUE
	    IF (.NOT.WNDPAR('OUTPUT_FILE',OFILE,LEN(OFILE),J0,OFILE)) THEN
	      IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 82	!RETRY UNIT
	      GOTO 83				!REPEAT
	    ELSE IF (J0.EQ.0) THEN
	      GOTO 82				!RETRY UNIT
	    ELSE IF (J0.LT.0) THEN
	      GOTO 83				!MUST SPECIFY
	    END IF
	  ELSE					!TAPE OUTPUT
	    IF (.NOT.WNFMOU(OMCA,OUNIT,'W')) THEN !MOUNT TAPE
	      CALL WNCTXT(F_TP,'Cannot mount tape on unit !AS (!XJ)',
	1			OUNIT,E_C)
	      GOTO 82				!RETRY UNIT
	    END IF
	    VOLHD=WNFTVL(OMCA)			!GET VOLUME HEADER
	    IF (VOLHD(1:4).EQ.'VOL1') THEN
	      CALL WNCTXT(F_TP,'!/Volume !AS mounted on unit !AS!/',
	1			VOLHD(5:10),OUNIT)
	    ELSE
	      CALL WNCTXT(F_TP,'!/Unlabeled tape mounted on unit !AS!/',
	1			OUNIT)
	    END IF
	  END IF
 85	  CONTINUE
	  IF (OUNIT.EQ.'D' .AND. OLAB.EQ.0) 	!Correct default for disk label
	1	OLAB=1				! is 1
	  IF (.NOT.WNDPAR('OUTPUT_LABEL',OLAB,LB_J,J0,
	1			A_B(-A_OB),OLAB,1)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) THEN	!RETRY OPTION
!!	      J0=0				!NOT SPECIFIED
	      goto 82
	    ELSE
	      GOTO 85				!RETRY
	    END IF
	  END IF
	  IF (J0.LE.0) THEN
	    IF (OUNIT.EQ.'D') THEN
	      OLAB=1				!START AT 1
	    ELSE
	      OLAB=0				!START AT EOT
	    END IF
	  END IF
 81	  CONTINUE
	  CALL WNFCL(FCAIN)
	  IF (.NOT.WNDNOD('INPUT_SCN_NODE',NODIN,'SCN','R',NODIN,IFILE)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 82	!RETRY OUTPUT
	    GOTO 81				!REPEAT
	  ELSE IF (E_C.EQ.DWC_NULLVALUE) THEN
	    GOTO 82				!RETRY OUTPUT
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN
	    GOTO 81				!MUST SPECIFY
	  END IF
	  IF (.NOT.WNFOP(FCAIN,IFILE,'R')) THEN	!OPEN INPUT SCAN FILE
	    GOTO 81				!RETRY
	  END IF
 84	  CONTINUE
	  IF (.NOT.WNDSTQ('SCN_SETS',MXNSET,SETS,FCAIN)) THEN !SETS TO COPY
!!	    GOTO 82				!RETRY OUTPUT
	    goto 81
	  END IF
!!	  IF (SETS(0,0).EQ.0) GOTO 81		!NO SETS SPECIFIED
	  IF (IAND(POLCD,XYX_M).EQ.XYX_M) POLCD=IQUV_M
	  IF (.NOT.NSCPL2(0,POLCD)) GOTO 81	!GET POL. TO DO
	  POL(1)=POLCD				!SAVE
 88	  CONTINUE
	  OINT=16					!DEFAULT
	  IF (.NOT.WNDPAR('BITPIX',OINT,LB_J,J0,
	1		A_B(-A_OB),OINT,1)) THEN
	     IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 84		!RETRY UNIT
	     GOTO 88					!REPEAT
	  ELSE IF (J0.EQ.0) THEN
	     GOTO 84					!RETRY SCNSETS
	  ELSE IF (J0.LT.0) THEN
	     GOTO 88					!MUST SPECIFY
	  END IF
	  IF (OINT.LT.0) THEN				!SHOULD BE -32,16,32
	     OINT=-32
	  ELSE IF (OINT.LT.16) THEN
	     OINT=16
	  ELSE IF (OINT.GT.16) THEN
	     OINT=32
	  END IF

C ****************************************************************************
C PRINT FITS
C ****************************************************************************
	ELSE IF (OPT.EQ.'PFI') THEN
 90	  CONTINUE
	  IF (.NOT.WNDPAR('INPUT_UNIT',UNIT,LEN(UNIT),J0,UNIT)) THEN !GET UNIT
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 100	!RETRY OPTION
	    GOTO 90				!REPEAT
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN	!LIST TAPEUNITS AND RETRY
	    CALL WNFMLI()
	    GOTO 90
	  ELSE IF (J0.EQ.0) THEN
	    GOTO 100				!RETRY OPTION
	  ELSE IF (J0.LT.0) THEN
	    GOTO 90				!MUST SPECIFY
	  END IF
	  IF (UNIT.EQ.'D') THEN			!DISK INPUT
 91	    CONTINUE
	    IF (.NOT.WNDPAR('INPUT_FILE',IFILE,LEN(IFILE),J0,IFILE)) THEN
	      IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 90	!RETRY UNIT
	      GOTO 91				!REPEAT
	    ELSE IF (J0.EQ.0) THEN
	      GOTO 90				!RETRY UNIT
	    ELSE IF (J0.LT.0) THEN
	      GOTO 91				!MUST SPECIFY
	    END IF
	  ELSE					!TAPE INPUT
	    IF (.NOT.WNFMOU(IMCA,UNIT,'R')) THEN !MOUNT TAPE
	      CALL WNCTXT(F_TP,'Cannot mount tape on unit !AS (!XJ)'
	1			,UNIT,E_C)
	      GOTO 90				!RETRY UNIT
	    END IF
	    VOLHD=WNFTVL(IMCA)			!GET VOLUME HEADER
	    IF (VOLHD(1:4).EQ.'VOL1') THEN
	      CALL WNCTXT(F_TP,'!/Volume !AS mounted on unit !AS!/',
	1			VOLHD(5:10),UNIT)
	    ELSE
	      CALL WNCTXT(F_TP,'!/Unlabeled tape mounted on unit !AS!/',
	1			UNIT)
	    END IF
	  END IF
 92	  CONTINUE
	  IF (NLAB(1).LE.0) THEN
	    JS=WNDPAR('INPUT_LABELS',ILAB(1,1),
	1			MXNLAB*LB_J,NLAB(1),'*')
	  ELSE
	    JS=WNDPAR('INPUT_LABELS',ILAB(1,1),
	1			MXNLAB*LB_J,NLAB(1),
	1			A_B(-A_OB),ILAB(1,1),NLAB(1))
	  END IF
	  IF (.NOT.JS) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 91	!RETRY
	    GOTO 91				!RETRY
	  END IF
	  IF (NLAB(1).EQ.0) GOTO 91		!RETRY
	END IF
C
 900	CONTINUE
	RETURN					!READY
C
C
	END
