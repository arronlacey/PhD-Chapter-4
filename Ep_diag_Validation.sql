where TABSCHEMA like 'SAIL0387%';        -- SELECT ALL OF THE TABLES FOR THIS PROJECT

select * from SAIL0387V.EPCODES_20160317;             -- CLINICAL DATA
select * from SAIL0387V.EPCODES_20160317_ALF;          -- PERSONAL DATA

select * from SAIL0387V.CLEANED_GP_REGISTRATIONS_20151008;          -- PERSONAL DATA
select * from SAIL0387V.PATIENT_ALF_CLEANSED_20151008;         -- PERSONAL DATA
select * from SAIL0387V.GP_EVENT_CLEANSED_20151008;          -- PERSONAL DATA



select count (distinct ep.alf_pe) from SAIL0387V.EPCODES_20160317_ALF ep
inner join SAIL0387V.CLEANED_GP_REGISTRATIONS_20151008 gp
on ep.alf_pe = gp.alf_pe
and '2014-01-01' between gp.start_date and gp.end_date
inner join SAIL0387V.EPCODES_20160317 ep_st
on ep.system_id_pe = ep_st.system_id_pe
--and ep_st.LASTPTCONSDATE between gp.start_date and gp.end_date
where ep_st.epe = 'Y'


select count (distinct alf_pe) from SAIL0387V.CLEANED_GP_REGISTRATIONS_20151008



--- CHECK HOW MANY PEOPLE
select COUNT (DISTINCT SYSTEM_ID_PE) from SAIL0387V.EPCODES_20160317
WHERE EPE = 'N';



---CREATE TABLE OF OUR DATA JOINED TO GP DATA ON ALF AND GP RECORDS BEFORE CONSULTATION DATE
drop table SAIL0387V.EPI_DIAG_TO_GP;   -- DELETE TABLE (old table created previously - bfs)

CREATE TABLE SAIL0387V.EPI_DIAG_TO_GP AS (
INSERT INTO SAIL0387V.EPI_DIAG_TO_GP

SELECT DISTINCT D.*, C.EPE, C.CAUSE, C.TYPE, C.LASTPTCONSDATE, C.DIAG_DATE FROM



(
SELECT DISTINCT B.ALF_PE,B.GNDR_CD,B.WOB, A.* FROM   --MASTER SELECT STATEMENT CHOOSING WHICH COLUMNS FROM "A" AND "B" AFTER JOIN
(select * from SAIL0387V.EPCODES_20160317) A   -- SELECT ALL FROM <TABLENAME> AND CALL IT "A"
INNER JOIN
(select * from SAIL0387V.EPCODES_20160317_ALF) B  -- SELECT ALL FROM <TABLENAME> AND CALL IT "B"
ON A.SYSTEM_ID_PE = B.SYSTEM_ID_PE  -- JOIN THE TABLES ON SYSTEM_ID_PE (EXISTS IN BOTH TABLES SEE)
) C   -- CALL THIS JOINED TABLE "C"


--- JOIN GP TABLES

INNER JOIN

(
SELECT DISTINCT A.ALF_PE,A.GNDR_CD,A.WOB,A.LSOA_CD, A.START_DATE,A.END_DATE,B.* FROM
(SELECT * FROM SAIL0387V.PATIENT_ALF_CLEANSED_20151008) A 
INNER JOIN
(select * from SAIL0387V.GP_EVENT_CLEANSED_20151008) B
ON A.PRAC_CD_PE = B.PRAC_CD_PE
AND A.LOCAL_NUM_C_PE = B.LOCAL_NUM_C_PE
AND A.SOURCE_EXTRACT = B.SOURCE_EXTRACT
) D

ON C.ALF_PE = D.ALF_PE
--WHERE D.EVENT_DT > C.DIAG_DATE -- 1 year (we are thinking here of looking at patients whose diagnosis was recorded 1 year earlier than the real diagnosis)
--OR DIAG_DATE IS NULL
--AND D.EVENT_dt >'2010-01-01'
)
WITH NO DATA;

---selecting GP data after epilepsy diagnosis

  SELECT * FROM SAIL0387V.EPI_DIAG_TO_GP
  WHERE EPE='Y';


------------------------EPILEPSY DIAGNOSIS
DROP TABLE SAIL0387V.EPI_Validation;
CREATE TABLE SAIL0387V.EPI_Validation AS (
INSERT INTO SAIL0387V.EPI_Validation 
SELECT DISTINCT a.alf_pe, a.epe,a.diag_date, a.lastptconsdate,YEAR(a.lastptconsdate)- YEAR(a.wob) AS AGE_LASTCONDATE, case when d.alf_pe is not NULL 
                                      And dr.alf_pe is not NULL
                                      And ep.alf_pe is not NULL
                                      Then 'Y' else 'N' end as GP_DIAG -- AGE_DIAG hear should've been AGE_LASTCONDATE SO IT IS RENAMED LATER ON
                                      
FROM
(select * FROM SAIL0387V.EPI_DIAG_TO_GP) A 
left join
 (select distinct alf_pe, event_dt, epe from SAIL0387V.EPI_DIAG_TO_GP
where (event_cd like 'dn%'
or (event_cd like 'do%'))
--AND epe='Y' --AND EVENT_DT <= LASTPTCONSDATE --TO SELECT PATIENTS WITHOUT EPILEPSY USING LAST CONS DATE AS CUT OFF PIONT
) d on A.alf_pe=d.alf_pe                                                      --aeds prescribed

left join

(select distinct alf_pe, event_dt from SAIL0387V.EPI_DIAG_TO_GP
where (event_cd like 'dn%'
or (event_cd like 'do%'))
) dr
on dr.alf_pe = d.alf_pe 
and dr.event_dt between d.event_dt and d.event_dt + 6 months                --repeat prescription within 6 months
                 
left join

(select distinct alf_pe, event_dt from SAIL0387V.EPI_DIAG_TO_GP
where event_cd like 'F25%'
or event_cd like '1O30.%'
or event_cd like '667%'
) ep  --epilepsy diagnosis
on ep.alf_pe = d.alf_pe ) WITH NO DATA;
--and ep.event_dt between d.event_dt - 6 months and d.event_dt + 6 months;    -- epilepsy 6months either side of aed prescription

--ALTER TABLE SAIL0387V.EPI_Validation RENAME COLUMN AGE_DIAG TO AGE_LASTCONDATE;


Select * From SAIL0387V.EPI_Validation;



SELECT COUNT (DISTINCT alf_pe) FROM SAIL0387V.EPI_DIAG_TO_GP
WHERE epe='Y';

-- All ages

SELECT COUNT (DISTINCT alf_pe) FROM  SAIL0387V.EPI_Validation 
WHERE EPE='N' AND GP_DIAG ='N'; -- TRUE NEGATIVES (NO EPILEPSY IN HOSPITAL NEUROLOGY CLINIC, NO EPI DIAGNOSIS AND NO AED IN GP RECORDS)

SELECT COUNT (DISTINCT alf_pe) FROM  SAIL0387V.EPI_Validation 
WHERE EPE='Y' AND GP_DIAG ='N'; -- FALSE NEGATIVES (EPILEPSY IN HOSPITAL NEUROLOGY CLINIC, NO EPI DIAGNOSIS AND NO AED IN GP RECORDS)

SELECT COUNT (DISTINCT alf_pe) FROM  SAIL0387V.EPI_Validation 
WHERE EPE='Y' AND GP_DIAG ='Y'; -- TRUE POSITIVES (EPILEPSY IN HOSPITAL NEUROLOGY CLINIC, EPI DIAGNOSIS AND AED IN GP RECORDS)

SELECT COUNT (DISTINCT alf_pe) FROM  SAIL0387V.EPI_Validation 
WHERE EPE='N' AND GP_DIAG ='Y'; -- FALSE POSITIVES (NO EPILEPSY IN HOSPITAL NEUROLOGY CLINIC,NO EPI DIAGNOSIS AND NO AED IN GP RECORDS)

-----------------------------------------------------------------------------------------------------

-- get stats 

SELECT DISTINCT a.alf_pe, a.epe,a.diag_date, a.lastptconsdate,YEAR(a.lastptconsdate)- YEAR(a.wob) AS AGE_LASTCONDATE, case when d.alf_pe is not NULL 
                                      And dr.alf_pe is not NULL
                                      And ep.alf_pe is not NULL
                                      Then 'Y' else 'N' end as GP_DIAG 
                                      
FROM

(select distinct ep.alf_pe,ep.wob,ep_st.* from SAIL0387V.EPCODES_20160317 ep_st             -- CLINICAL DATA
inner join SAIL0387V.EPCODES_20160317_ALF ep
on ep.system_id_pe = ep_st.system_id_pe
inner join SAIL0387V.CLEANED_GP_REGISTRATIONS_20151008 reg
on ep.alf_pe = reg.alf_pe 
and '2014-01-01' between reg.start_date and reg.end_date) A 
left join
 (select distinct alf_pe, event_dt, epe from SAIL0387V.EPI_DIAG_TO_GP
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and event_dt between '2013-06-01' and '2014-06-01' 
--AND epe='Y' --AND EVENT_DT <= LASTPTCONSDATE --TO SELECT PATIENTS WITHOUT EPILEPSY USING LAST CONS DATE AS CUT OFF PIONT
) d on A.alf_pe=d.alf_pe                                                      --aeds prescribed

left join

(select distinct alf_pe, event_dt from SAIL0387V.EPI_DIAG_TO_GP
where (event_cd like 'dn%'
or (event_cd like 'do%'))
) dr
on dr.alf_pe = d.alf_pe 
and dr.event_dt between d.event_dt and d.event_dt + 6 months                --repeat prescription within 6 months
                 
left join

(select distinct alf_pe, event_dt from SAIL0387V.EPI_DIAG_TO_GP
where event_cd like 'F25%'
or event_cd like '1O30.%'
or event_cd in ('667B.','SC200')
) ep  --epilepsy diagnosis
on ep.alf_pe = d.alf_pe
and ep.event_dt <= d.event_dt
--and ep.event_dt between d.event_dt - 6 months and d.event_dt + 6 months;    -- epilepsy 6months either side of aed prescription
