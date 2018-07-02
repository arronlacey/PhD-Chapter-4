-----------------------------------------------------
Prevalence
-----------------------------------------------------

syear <- seq(1999,2009)
eyear <- seq(2001,2011)
myear <- seq(2000,2010)

for (i in 1:length(syear)){
c<-sqlQuery(channel,paste("

--create table sailx031v.ep_dep_prev_hb_prev as (
insert into sailx031v.ep_dep_prev_hb_prev
select count(distinct alf_e) as num_persons, pyear,gndr_cd,wimd2011_dec,hb_cd,age_band from
(select distinct d.alf_e,",myear[i]," as pyear,d.gndr_cd,wimd2011_dec,v.hb_cd,
case when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(d.WOB))) between 0 and 5 then '0-5'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(d.WOB))) between 6 and 12 then '6-12'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(d.WOB))) between 13 and 21 then '13-21'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(d.WOB))) between 22 and 45 then '22-45'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(d.WOB))) between 46 and 64 then '46-64'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(d.WOB))) between 65 and 110 then '65-110'
else 'other' end as age_band from

(select distinct alf_e,gndr_cd, min(event_dt) as min_dt,wob
from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')
group by alf_e,gndr_cd,wob) d --aeds prescribed in year of interest

inner join

(select distinct alf_e, event_dt from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')) dr
on dr.alf_e = d.alf_e 
and dr.event_dt > d.min_dt

inner join

(select distinct alf_e, event_dt,wob from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'F25%'
or (event_cd like '1O30.%'
or (event_cd like '667%)))
and (event_dt <= '",myear[i],"-01-01')
) ep  --epilepsy diagnosis
on ep.alf_e = d.alf_e

inner join

(select distinct alf_e,pers_id_e,dod from SAILHNARV.AR_pers
where (dod > '",myear[i],"-01-01'
or (dod is null))) ar
on ar.alf_e = ep.alf_e

inner join

(select distinct pers_id_e,from_dt,to_dt from SAILHNARV.AR_PERS_GP
where '",myear[i],"-01-01' between from_dt and to_dt) gp
on ar.pers_id_e = gp.pers_id_e

inner join

(select distinct pers_id_e,lsoa_cd from SAILHNARV.AR_PERS_add
where '",myear[i],"-01-01' between from_dt and to_dt )ad
on ad.pers_id_e = gp.pers_id_e

inner join

(select distinct lsoa_cd,wimd2011_dec from sailx031v.LSOA_refr) w
on w.lsoa_cd = ad.lsoa_cd

inner join

(select distinct lsoa_cd,hb_cd from sailrefrv.LSOA_refr) v
on v.lsoa_cd = ad.lsoa_cd
)
group by pyear,gndr_cd,wimd2011_dec,hb_cd,age_band
--)
--with no data

",sep=""))

}
 

----------------------------------------------
--Incidence
----------------------------------------------
syear <- seq(1999,2009)
eyear <- seq(2001,2011)
myear <- seq(2000,2010)

for (i in 1:length(syear)){
b<-sqlQuery(channel,paste("

--create table sailx031v.ep_dep_inc_hb_dep as (
--insert into sailx031v.ep_dep_inc_hb_dep
select count(distinct alf_e) as num_persons,pyear,gndr_cd,wimd2011_dec,hb_cd,age_band from
(select distinct epop.alf_e,'",myear[i],"' as pyear, epop.gndr_cd,wimd2011_dec,v.hb_cd,
case when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(epop.WOB))) between 0 and 5 then '0-5'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(epop.WOB))) between 6 and 12 then '6-12'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(epop.WOB))) between 13 and 21 then '13-21'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(epop.WOB))) between 22 and 45 then '22-45'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(epop.WOB))) between 46 and 64 then '46-64'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(epop.WOB))) between 65 and 110 then '65-110'
else 'other' end as age_band from

(select distinct d.alf_e,d.gndr_cd,d.wob from
(select distinct alf_e,gndr_cd, min(event_dt) as min_dt,
wob from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')
group by alf_e,gndr_cd,wob) d --aeds prescribed in year of interest

inner join

(select distinct alf_e,event_dt from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')) dr --repeat prescription
on dr.alf_e = d.alf_e
and dr.event_dt > d.min_dt
and dr.event_dt between d.min_dt and d.min_dt + 6 months

inner join

(select distinct alf_e, event_dt from SAILWLGPV.GP_EVENT_ALF

where (event_cd like 'F25%'
or (event_cd like '1O30.%'
or (event_cd like '667%')))
and (event_dt between '",myear[i],"-01-01' and '",myear[i],"-12-31')
) ep  --epilepsy diagnosis
on ep.alf_e = d.alf_e
and ep.event_dt between d.min_dt - 6 months and d.min_dt + 6 months

left join
(select distinct alf_e from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%%'))
and (event_dt < '",syear[i],"-06-01')) dx --exlcusion of aeds in previous years
on dx.alf_e = d.alf_e

left join
(select distinct alf_e from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'F25%'
or (event_cd like '1O30.%'
or (event_cd like '667%')))
and (event_dt < '",syear[i],"-12-31')) epx --exlusion of epilepsy in previous years
on epx.alf_e = ep.alf_e

where dx.alf_e is null
and epx.alf_e is null
) epop

inner join

(select distinct alf_e,pers_id_e,dod from SAILHNARV.AR_pers
where (dod > '",myear[i],"-01-01'
or (dod is null))) ar
on ar.alf_e = epop.alf_e

inner join

(select distinct pers_id_e,from_dt,to_dt from SAILHNARV.AR_PERS_GP
where '",myear[i],"-01-01' between from_dt and to_dt) gp
on ar.pers_id_e = gp.pers_id_e

inner join

(select distinct pers_id_e,lsoa_cd from SAILHNARV.AR_PERS_add
where '",myear[i],"-01-01' between from_dt and to_dt )ad
on ad.pers_id_e = gp.pers_id_e

inner join

(select distinct lsoa_cd,wimd2011_dec from sailx031v.LSOA_refr) w
on w.lsoa_cd = ad.lsoa_cd

inner join

(select distinct lsoa_cd,hb_cd from sailrefrv.LSOA_refr) v
on v.lsoa_cd = ad.lsoa_cd)

group by pyear,gndr_cd,wimd2011_dec,hb_cd,age_band
--)
--with no data

",sep=""))
 
}



----------------------------------------------
--Population
----------------------------------------------
syear <- seq(1999,2009)
eyear <- seq(2001,2011)
myear <- seq(2000,2010)

for (i in 1:length(myear)){
a<-sqlQuery(channel,paste("

--create table sailx031v.ep_dep_pop_hb_dep as(
insert into sailx031v.ep_dep_pop_hb_dep
select count(distinct arp.alf_e) as num_persons,arp.gndr_cd,",myear[i]," as pyear, w.hb_cd,wimd2011_dec,
case when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 0 and 5 then '0-5'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 6 and 12 then '6-12'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 13 and 21 then '13-21'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 22 and 45 then '22-45'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 46 and 64 then '46-64'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 65 and 110 then '65-110'
else 'other' end as age_band from SAILHNARV.AR_PERS_GP ARGP  -- persons on the ar and who they were with
join SAILHNARV.AR_PERS ARP -- the people on the AR
on argp.pers_id_e = arp.pers_id_e
join SAILHNARV.AR_PERS_add AR -- the people on the AR
on argp.pers_id_e = ar.pers_id_e
join SAILWLGPV.PATIENT_ALF GP -- contibuting gp practices
on ARGP.prac_cd_e = gP.prac_cd_E -- link the practices
join sailx031v.LSOA_REFR l
on ar.lsoa_cd = l.lsoa_cd
join sailrefrv.LSOA_REFR w
on ar.lsoa_cd = w.lsoa_cd
where '",myear[i],"-01-01' between argp.from_dt and argp.to_dt
and '",myear[i],"-01-01' between ar.from_dt and ar.to_dt
and (arp.dod >= '",myear[i],"-01-01'
or (arp.dod is null))
group by wimd2011_dec,arp.gndr_cd,w.hb_cd,
case when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 0 and 5 then '0-5'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 6 and 12 then '6-12'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 13 and 21 then '13-21'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 22 and 45 then '22-45'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 46 and 64 then '46-64'
when TIMESTAMPDIFF(256,CHAR(TIMESTAMP_ISO('",myear[i],"-01-01') - TIMESTAMP_ISO(arp.WOB))) between 65 and 110 then '65-110'
else 'other' end
)
with no data

",sep=""))


}


-----------------------------------------------------------------
--Prevalence by local health board

syear <- seq(1999,2009)
eyear <- seq(2001,2011)
myear <- seq(2000,2010)

for (i in 1:length(myear)){
sqlQuery(channel,paste("

create table sailx031v.ep_prev_hb_dep as(
--insert into sailx031v.ep_prev_hb_dep
select count(distinct d.alf_e) as num_persons,'2010-01-01' as pyear,w.hb_cd,v.wimd_2011_dec from

((select distinct alf_e,gndr_cd, min(event_dt) as min_dt,wob
from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')
group by alf_e,gndr_cd,wob) d --aeds prescribed in year of interest

inner join

(select distinct alf_e, event_dt from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')) dr
on dr.alf_e = d.alf_e 
and dr.event_dt > d.min_dt

inner join

(select distinct alf_e, event_dt,wob from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'F25%'
or (event_cd like '1O30.%'))
and (event_dt <= '",myear[i],"-01-01')
) ep  --epilepsy diagnosis
on ep.alf_e = d.alf_e

inner join

(select distinct alf_e,pers_id_e,dod from SAILHNARV.AR_pers
where (dod > '",myear[i],"-01-01'
or (dod is null))) ar
on ar.alf_e = ep.alf_e

inner join

(select distinct pers_id_e,from_dt,to_dt from SAILHNARV.AR_PERS_GP
where '",myear[i],"-01-01' between from_dt and to_dt) gp
on ar.pers_id_e = gp.pers_id_e

inner join

(select distinct pers_id_e,lsoa_cd from SAILHNARV.AR_PERS_add
where '",myear[i],"-01-01' between from_dt and to_dt )ad
on ad.pers_id_e = gp.pers_id_e


inner join

(select distinct lsoa_cd,msoa_cd,hb_cd from SAILREFRV.LSOA_refr) w
on ad.lsoa_cd = w.lsoa_cd)

inner join

(select distinct lsoa_cd,wimd2011_dec from sailx031v.LSOA_refr) v
on v.lsoa_cd = ad.lsoa_cd

group by v.wimd2011_dec,w.hb_cd

",sep=""))


}

----------------------------------------------
--Incidence by local health board
----------------------------------------------
syear <- seq(1999,2009)
eyear <- seq(2001,2011)
myear <- seq(2000,2010)

for (i in 1:length(syear)){
a<-sqlQuery(channel,paste("

insert into sailx031v.ep_dep_inc_hb_dep
select count(distinct epop.alf_e) as num_persons,",myear[i]," as pyear,w.hb_cd,v.wimd2011_dec from

(select distinct d.alf_e,d.gndr_cd,d.wob from
(select distinct alf_e,gndr_cd, min(event_dt) as min_dt,
wob from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')
group by alf_e,gndr_cd,wob) d --aeds prescribed in year of interest

inner join

(select distinct alf_e,event_dt from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')) dr --repeat prescription
on dr.alf_e = d.alf_e
and dr.event_dt > d.min_dt
and dr.event_dt between d.min_dt and d.min_dt + 6 months

inner join

(select distinct alf_e, event_dt from SAILWLGPV.GP_EVENT_ALF

where (event_cd like 'F25%'
or (event_cd like '1O30.%'
or (event_cd like '667%')))
and (event_dt between '",myear[i],"-01-01' and '",myear[i],"-12-31')
) ep  --epilepsy diagnosis
on ep.alf_e = d.alf_e
and ep.event_dt between d.min_dt - 6 months and d.min_dt + 6 months

left join
(select distinct alf_e from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%%'))
and (event_dt < '",syear[i],"-06-01')) dx --exlcusion of aeds in previous years
on dx.alf_e = d.alf_e

left join
(select distinct alf_e from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'F25%'
or (event_cd like '1O30.%'
or (event_cd like '667%')))
and (event_dt < '",syear[i],"-12-31')) epx --exlusion of epilepsy in previous years
on epx.alf_e = ep.alf_e

where dx.alf_e is null
and epx.alf_e is null
) epop

inner join

(select distinct alf_e,pers_id_e,dod from SAILHNARV.AR_pers
where (dod > '",myear[i],"-01-01'
or (dod is null))) ar
on ar.alf_e = epop.alf_e

inner join

(select distinct pers_id_e,from_dt,to_dt from SAILHNARV.AR_PERS_GP
where '",myear[i],"-01-01' between from_dt and to_dt) gp
on ar.pers_id_e = gp.pers_id_e

inner join

(select distinct pers_id_e,lsoa_cd from SAILHNARV.AR_PERS_add
where '",myear[i],"-01-01' between from_dt and to_dt )ad
on ad.pers_id_e = gp.pers_id_e

inner join

(select distinct lsoa_cd,hb_cd from sailrefrv.LSOA_refr) w
on w.lsoa_cd = ad.lsoa_cd

inner join

(select distinct lsoa_cd,wimd2011_dec from sailx031v.LSOA_refr) v
on v.lsoa_cd = ad.lsoa_cd

group by v.wimd2011_dec,w.hb_cd

 ",sep=""))
 
}


----------------------------------------------
--Population for local health boards
----------------------------------------------
syear <- seq(1999,2009)
eyear <- seq(2001,2011)
myear <- seq(2000,2010)

for (i in 1:length(myear)){
b<-sqlQuery(channel,paste("

insert into sailx031v.ep_pop_hb_dep
select count(distinct arp.alf_e),",myear[i]," as pyear, l.hb_cd
from SAILHNARV.AR_PERS_GP ARGP  -- persons on the ar and who they were with
join SAILHNARV.AR_PERS ARP -- the people on the AR
on argp.pers_id_e = arp.pers_id_e
join SAILHNARV.AR_PERS_add AR -- the people on the AR
on argp.pers_id_e = ar.pers_id_e
join SAILWLGPV.PATIENT_ALF GP -- contibuting gp practices
on ARGP.prac_cd_e = gP.prac_cd_E -- link the practices
join sailrefrv.LSOA_REFR l
on ar.lsoa_cd = l.lsoa_cd
where '",myear[i],"-01-01' between argp.from_dt and argp.to_dt
and '",myear[i],"-01-01' between ar.from_dt and ar.to_dt
and (arp.dod >= '",myear[i],"-01-01'
or (arp.dod is null))
group by l.hb_cd

",sep=""))

}





---------combine to get prevalence and incidence with population denom

prev_hb<-sqlQuery(channel,paste("select a.num_persons as num_epilepsy, b.num_persons as population,
case when a.num_persons is not null then cast(a.num_persons as float) /cast(b.num_persons as float)
else 0 end as prevalence,
b.pyear as year, b.gndr_cd, b.wimd2011_dec, b.hb_cd,b.age_band from sailx031v.ep_dep_prev_hb_prev a
right join sailx031v.ep_dep_pop_hb_dep b
on a.pyear = b.pyear
and a.gndr_cd=b.gndr_cd
and a.age_band = b.age_band
and a.wimd2011_dec = b.wimd2011_dec
and a.hb_cd = b.hb_cd
order by a.pyear,a.wimd2011_dec,a.age_band",sep=""))

save(inc_hb,file="inc_hb.Rda")




sqlQuery(channel,paste("select * from sailx031v.ep_dep_prev_hb_prev",sep=""))
sqlQuery(channel,paste("select * from sailx031v.ep_dep_inc_hb_dep ",sep=""))
sqlQuery(channel,paste("select * from sailx031v.ep_dep_pop_hb_dep",sep=""))



inc_hb<-sqlQuery(channel,paste("select a.num_persons as num_epilepsy, b.num_persons as population,
case when a.num_persons is not null then cast(a.num_persons as float) /cast(b.num_persons as float)
else 0 end as incidence ,
b.pyear as year, b.gndr_cd, b.wimd2011_dec, b.hb_cd, b.age_band from sailx031v.ep_dep_inc_hb_dep2 a
right join sailx031v.ep_dep_pop_hb_dep b
on a.pyear = b.pyear
and a.gndr_cd=b.gndr_cd
and a.age_band = b.age_band
and a.wimd2011_dec = b.wimd2011_dec
and a.hb_cd = b.hb_cd
order by a.pyear,a.wimd2011_dec,a.age_band",sep=""))




----------------------------------------------
--Incidence
----------------------------------------------
syear <- seq(1999,2009)
eyear <- seq(2001,2011)
myear <- seq(2000,2010)

for (i in 1:length(syear)){
b<-sqlQuery(channel,paste("

--create table sailx031v.ep_inc_lsoa as (
insert into sailx031v.ep_inc_lsoa
select count(distinct alf_e) as num_persons,pyear,lsoa_cd from
(select distinct epop.alf_e,'",myear[i],"' as pyear,v.lsoa_cd from

(select distinct d.alf_e,d.gndr_cd,d.wob from
(select distinct alf_e,gndr_cd, min(event_dt) as min_dt,
wob from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')
group by alf_e,gndr_cd,wob) d --aeds prescribed in year of interest

inner join

(select distinct alf_e,event_dt from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%'))
and (event_dt between '",syear[i],"-06-01' and '",eyear[i],"-06-01')) dr --repeat prescription
on dr.alf_e = d.alf_e
and dr.event_dt > d.min_dt
and dr.event_dt between d.min_dt and d.min_dt + 6 months

inner join

(select distinct alf_e, event_dt from SAILWLGPV.GP_EVENT_ALF

where (event_cd like 'F25%'
or (event_cd like '1O30.%'
or (event_cd like '667%')))
and (event_dt between '",myear[i],"-01-01' and '",myear[i],"-12-31')
) ep  --epilepsy diagnosis
on ep.alf_e = d.alf_e
and ep.event_dt between d.min_dt - 6 months and d.min_dt + 6 months

left join
(select distinct alf_e from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'dn%'
or (event_cd like 'do%%'))
and (event_dt < '",syear[i],"-06-01')) dx --exlcusion of aeds in previous years
on dx.alf_e = d.alf_e

left join
(select distinct alf_e from SAILWLGPV.GP_EVENT_ALF
where (event_cd like 'F25%'
or (event_cd like '1O30.%'
or (event_cd like '667%')))
and (event_dt < '",syear[i],"-12-31')) epx --exlusion of epilepsy in previous years
on epx.alf_e = ep.alf_e

where dx.alf_e is null
and epx.alf_e is null
) epop

inner join

(select distinct alf_e,pers_id_e,dod from SAILHNARV.AR_pers
where (dod > '",myear[i],"-01-01'
or (dod is null))) ar
on ar.alf_e = epop.alf_e

inner join

(select distinct pers_id_e,from_dt,to_dt from SAILHNARV.AR_PERS_GP
where '",myear[i],"-01-01' between from_dt and to_dt) gp
on ar.pers_id_e = gp.pers_id_e

inner join

(select distinct pers_id_e,lsoa_cd from SAILHNARV.AR_PERS_add
where '",myear[i],"-01-01' between from_dt and to_dt )ad
on ad.pers_id_e = gp.pers_id_e

inner join

(select distinct lsoa_cd,wimd2011_dec from sailx031v.LSOA_refr) w
on w.lsoa_cd = ad.lsoa_cd

inner join

(select distinct lsoa_cd,hb_cd from sailrefrv.LSOA_refr) v
on v.lsoa_cd = ad.lsoa_cd)
group by pyear,lsoa_cd
--)
--with no data

",sep=""))
 
}




syear <- seq(1999,2009)
eyear <- seq(2001,2011)
myear <- seq(2000,2010)

for (i in 1:length(myear)){
b<-sqlQuery(channel,paste("
--create table sailx031v.ep_pop_lsoa_cd as(
insert into sailx031v.ep_pop_lsoa_cd
select count(distinct arp.alf_e) as pop,",myear[i]," as pyear, l.lsoa_cd
from SAILHNARV.AR_PERS_GP ARGP  -- persons on the ar and who they were with
join SAILHNARV.AR_PERS ARP -- the people on the AR
on argp.pers_id_e = arp.pers_id_e
join SAILHNARV.AR_PERS_add AR -- the people on the AR
on argp.pers_id_e = ar.pers_id_e
join SAILWLGPV.PATIENT_ALF GP -- contibuting gp practices
on ARGP.prac_cd_e = gP.prac_cd_E -- link the practices
join sailrefrv.LSOA_REFR l
on ar.lsoa_cd = l.lsoa_cd
where '",myear[i],"-01-01' between argp.from_dt and argp.to_dt
and '",myear[i],"-01-01' between ar.from_dt and ar.to_dt
and (arp.dod >= '",myear[i],"-01-01'
or (arp.dod is null))
group by l.lsoa_cd
--)
--with no data

",sep=""))

}



inc<-sqlQuery(channel,paste("
select a.num_persons as num_epilepsy, b.num_persons as population,
case when a.num_persons is not null then cast(a.num_persons as float) /cast(b.num_persons as float)
else 0 end as prevalence,
b.pyear as year, b.gndr_cd, b.wimd2011_dec, b.hb_cd,b.age_band from sailx031v.ep_dep_inc_hb_dep2 a
right join sailx031v.ep_dep_pop_hb_dep b
on a.pyear = b.pyear
and a.gndr_cd=b.gndr_cd
and a.age_band = b.age_band
and a.wimd2011_dec = b.wimd2011_dec
and a.hb_cd = b.hb_cd
order by a.pyear,a.wimd2011_dec,a.age_band
",sep=""))




select count(distinct arp.alf_e) as pop, l.lsoa_cd
from SAILHNARV.AR_PERS_GP ARGP  -- persons on the ar and who they were with
join SAILHNARV.AR_PERS ARP -- the people on the AR
on argp.pers_id_e = arp.pers_id_e
join SAILHNARV.AR_PERS_add AR -- the people on the AR
on argp.pers_id_e = ar.pers_id_e
join SAILWLGPV.PATIENT_ALF GP -- contibuting gp practices
on ARGP.prac_cd_e = gP.prac_cd_E -- link the practices
join sailrefrv.LSOA_REFR l
on ar.lsoa_cd = l.lsoa_cd
where argp.from_dt <= '2010-01-01' and argp.to_dt >= '2004-01-01'      --get anyone who has lived in lsoa over the 10 years
group by l.lsoa_cd


	
