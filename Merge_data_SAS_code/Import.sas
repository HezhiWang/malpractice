FILENAME REFFILE '/Files/_uploads/ama-master.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.AMA_master;
	GETNAMES=YES;
RUN;

FILENAME REFFILE '/Files/_uploads/malpractice.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.Malpractice;
	GETNAMES=YES;
RUN;