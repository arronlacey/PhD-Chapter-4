library(ggplot2)
library(gridExtra)
library(aod)
library(Rmisc)
library(reshape)
source("~/sail_login.r")


##### load epilepsy ####

edu<-data.frame(sqlQuery(channel,"

select distinct alf_e,gndr_cd,pupil_irn_e,csi,
  case when langsub in ('3','2') then 'Y' else 'N' end as langsub,
  case when scsub in ('3','2') then 'Y' else 'N' end as scsub,
  case when masub in ('3','2') then 'Y' else 'N' end as masub,
  year,smoke_st,autism_st,drug_type,birth_weight,mat_age,gest_age,wimd2011_quint,ep_st from
(
select distinct b.alf_e,b.gndr_cd, b.pupil_irn_e,c.masub,c.scsub,c.csi,case when c.ensub is null then c.cysub
                when c.ensub is not null then c.ensub end as langsub, c.year,smoke_st,autism_st,drug_type,
                                                          birth_weight,mat_age,gest_age,wimd2011_quint,
                case when ep.alf_e is not null then 'Y' else 'N' end as ep_st
from sailx031v.mothers_cohort_with_covariates a
inner join saileducv.pre16_alf_20101231 b 
on a.alf_e = b.alf_e
inner join saileducv.PRE16_KS1_20101231 c 
on b.pupil_irn_e = c.pupil_irn_e
inner join
(select distinct alf_e from   --monotherapy                                                                              
(select distinct a.alf_e, count(drug_type) as drug_count from sailx031v.mothers_cohort_with_covariates a 
group by a.alf_e)
where drug_count < 2) d   -- includes those that had no drug
on d.alf_e = a.alf_e

left join

(select distinct alf_e
from SAILWLGPV.GP_EVENT_ALF_CLEANSED
where event_cd like 'F25%') ep

on ep.alf_e = d.alf_e


where b.alf_e is not null
and drug_type in ('LTG','NO_DRUG','CBZ','SVPA')
)
                         "),stringsAsFactors=FALSE)


##### load controls ####

control_pool<-data.frame(sqlQuery(channel,"

select distinct alf_e,gndr_cd,pupil_irn_e,csi,
  case when langsub in ('3','2') then 'Y' else 'N' end as langsub,
  case when scsub in ('3','2') then 'Y' else 'N' end as scsub,
  case when masub in ('3','2') then 'Y' else 'N' end as masub,
  year,smoke_st,autism_st,drug_type,birth_weight,mat_age,gest_age,wimd2011_quint,'NULL' as ep_st from
(
select distinct alf_e, gndr_cd, pupil_irn_e,csi,masub,scsub,langsub,year,smoke_st,autism_st,drug_type,
                                                          birth_weight,mat_age,gest_age,wimd2011_quint from -- just to get days in sail GP
(select distinct mat_alf_e,mat_wob,alf_e,gndr_cd,wob,
birth_weight,mat_age,gest_age,pupil_irn_e,csi,masub,scsub,langsub,year,
smoke_st,autism_st,epilepsy_st,drug_type,
sum(dur) as days_sail,wimd2011_quint from

(select raw.*,
days(raw.to_dt) - days(raw.from_dt) as dur 
from

(select distinct a.*,
case when c.from_dt < a.wob - 5 years then a.wob - 5 years
          else c.from_dt end as from_dt,
case when c.to_dt > a.wob then a.wob
     else c.to_dt end as to_dt,c.wimd2011_quint
from

(select distinct f.mat_alf_e,f.mat_wob,b.alf_e,b.gndr_cd,f.wob,days(f.wob) - days(f.mat_wob) as days_to_birth,
f.birth_weight,f.mat_age,f.gest_age,
b.pupil_irn_e,c.csi,c.masub,c.scsub, case when c.ensub is null then c.cysub
                                                          when c.ensub is not null then c.ensub
                                                          end as langsub,c.year,
                                                          'NULL' as smoke_st,'NULL' as autism_st,'NULL' as epilepsy_st,'CONTROL' as drug_type 
                                                          from saileducv.pre16_alf_20101231 b 
inner join saileducv.PRE16_KS1_20101231 c 
on b.pupil_irn_e = c.pupil_irn_e
inner join sailNCCHV.child_20140227 f 
on b.alf_e = f.alf_e
where f.mat_age is not null
order by f.mat_alf_e
) a

inner join

(select distinct b.pupil_irn_e,min(c.year) as year from saileducv.pre16_alf_20101231 b 
inner join saileducv.PRE16_KS1_20101231 c 
on b.pupil_irn_e = c.pupil_irn_e
inner join sailNCCHV.child_20140227 f 
on b.alf_e = f.alf_e
where f.mat_age is not null
group by b.pupil_irn_e
) b

on a.pupil_irn_e = b.pupil_irn_e
and a.year = b.year

inner join

(select distinct arp.alf_e, ar.from_dt,ar.to_dt,w.wimd2011_quint from SAILWDSDV.AR_PERS_GP ARGP
inner join SAILWDSDV.AR_PERS arp
on arp.pers_id_e = argp.pers_id_e
join SAILWDSDV.AR_PERS_add AR -- the people on the AR
on arp.pers_id_e = ar.pers_id_e
join sailx031v.LSOA_refr w
on w.lsoa_cd = ar.lsoa_cd
join SAILWLGPV.PATIENT_ALF_CLEANSED GP -- contibuting gp practices
on ARGP.prac_cd_e = gP.prac_cd_E -- link the practices
) c

on a.mat_alf_e = c.alf_e
and a.wob between c.from_dt and c.to_dt

) raw
)
group by 
mat_alf_e,pupil_irn_e,mat_wob,alf_e,gndr_cd,wob,days_to_birth,
birth_weight,mat_age,gest_age,wimd2011_quint,drug_type,
epilepsy_st,autism_st,smoke_st,csi,langsub,masub,scsub,langsub,year
)
)
--where days_sail >= 365*2 

"),stringsAsFactors=FALSE)

#### All Wales Results ########################


##### load poly therapy #######################

poly<-data.frame(sqlQuery(channel,"

select distinct alf_e,gndr_cd,pupil_irn_e,csi,
  case when langsub in ('3','2') then 'Y' else 'N' end as langsub,
  case when scsub in ('3','2') then 'Y' else 'N' end as scsub,
  case when masub in ('3','2') then 'Y' else 'N' end as masub,
  year,smoke_st,autism_st,drug_type,birth_weight,mat_age,gest_age,wimd2011_quint,ep_st from
(
select distinct b.alf_e,b.gndr_cd,b.pupil_irn_e,c.csi,c.masub,c.scsub, case when c.ensub is null then c.cysub
                                                          when c.ensub is not null then c.ensub
                                                          end as langsub, c.year,smoke_st,autism_st,
case when d.poly_val = 'POLY_OTHER' then 'POLYTHERAPY' else 'POLYTHERAPY' end as drug_type,
                                                          birth_weight,mat_age,gest_age,wimd2011_quint,
                case when ep.alf_e is not null then 'Y' else 'N' end as ep_st
from saileducv.pre16_alf_20101231 b 
inner join saileducv.PRE16_KS1_20101231 c 
on b.pupil_irn_e = c.pupil_irn_e
inner join sailx031v.polytherapy d

left join

(select distinct alf_e
from SAILWLGPV.GP_EVENT_ALF_CLEANSED
where event_cd like 'F25%') ep

on ep.alf_e = d.alf_e

on b.alf_e = d.alf_e
where b.alf_e is not null)
                          "),stringsAsFactors=FALSE)

                 
                 
                 
#### PRESERVE POLYTHERAPY WITH VALPROATE

polyval<-data.frame(sqlQuery(channel,"

                          select distinct alf_e,gndr_cd,pupil_irn_e,csi,
                          case when langsub in ('3','2') then 'Y' else 'N' end as langsub,
                          case when scsub in ('3','2') then 'Y' else 'N' end as scsub,
                          case when masub in ('3','2') then 'Y' else 'N' end as masub,
                          year,smoke_st,autism_st,drug_type,birth_weight,mat_age,gest_age,wimd2011_quint,ep_st from
                          (
                          select distinct b.alf_e,b.gndr_cd,b.pupil_irn_e,c.csi,c.masub,c.scsub, case when c.ensub is null then c.cysub
                          when c.ensub is not null then c.ensub
                          end as langsub, c.year,smoke_st,autism_st,
                          case when d.poly_val = 'POLY_OTHER' then 'POLYOTHER' else 'POLYVAL' end as drug_type,
                          birth_weight,mat_age,gest_age,wimd2011_quint,
                          case when ep.alf_e is not null then 'Y' else 'N' end as ep_st
                          from saileducv.pre16_alf_20101231 b 
                          inner join saileducv.PRE16_KS1_20101231 c 
                          on b.pupil_irn_e = c.pupil_irn_e
                          inner join sailx031v.polytherapy d
                          
                          left join
                          
                          (select distinct alf_e
                          from SAILWLGPV.GP_EVENT_ALF_CLEANSED
                          where event_cd like 'F25%') ep
                          
                          on ep.alf_e = d.alf_e
                          
                          on b.alf_e = d.alf_e
                          where b.alf_e is not null)
                          "),stringsAsFactors=FALSE)



####################################### merge control_pool and edu to get matches ############

# case <-rbind(edu,poly)

#  poly therapies split
cases<-rbind(edu,poly)


#weight_cat<-unique(cut(cases$BIRTH_WEIGHT, 5))

#cases$BIRTH_WEIGHT_CAT<-cut(cases$BIRTH_WEIGHT, weight_cat)
#control_pool$BIRTH_WEIGHT_CAT<-cut(control_pool$BIRTH_WEIGHT, weight_cat)

edu.matched<-data.frame()
control.pool<-control_pool

#data.frame(merge(cases[1,c(1,12,14)],control.pool,by=c("MAT_AGE")))


for (i in 1:nrow(cases)){
edu.merged<-data.frame(merge(cases[i,],control.pool,by=c("MAT_AGE","WIMD2011_QUINT","GEST_AGE")))
filter<-with(edu.merged,edu.merged[1:4,])
edu.matched<-data.frame(rbind(filter,edu.matched))
control.pool<-control.pool[!control.pool$ALF_E %in% filter$ALF_E.y,]
}


controls<-subset(control_pool,control_pool$ALF_E %in% edu.matched$ALF_E.y)
#anyDuplicated(controls$ALF_E)
#controls<-controls[-382,]

## checks
#nrow(edu.matched[is.na(edu.matched$ALF_E.y),])
#nrow(edu.matched) - nrow(controls)
##full.match<-subset(data.frame(with(edu.matched,table(ALF_E.x))),Freq > 1)

##cases<-cases[cases$ALF_E %in% full.match$ALF_E.x,]




############################## add cohort flag to each table ##################

all_wales<-control_pool
all_wales$DRUG_TYPE<-"ALL_WALES"
case_control<-rbind(edu,controls,poly,all_wales)



#case_control$BIRTH_WEIGHT_CAT<-cut(case_control$BIRTH_WEIGHT, weight_cat)


#controls[,length(names(controls))-2]





########################################### summary stats #################



## distribution of drugs

data.frame(with(case_control,table(DRUG_TYPE)))

## only interested in CBZ,LTG,PHT and SVPA as number as large enough
case_control<-case_control[!
case_control$DRUG_TYPE %in% 
c("PRIM","CLON","TPM","VIG","PHNYT") | case_control$CSI %in% c("y","n"),]
case_control$DRUG_TYPE<-factor(case_control$DRUG_TYPE)
case_control$CSI<-factor(case_control$CSI)

## N per drug


## who passed?
n<-data.frame(with(case_control,table(DRUG_TYPE)))

csi<-data.frame(with(case_control,table(DRUG_TYPE,CSI)))
csi<-merge(csi,n,by="DRUG_TYPE")
csi.pc<-(csi$Freq.x/csi$Freq.y)*100
summary(csi.pc)
csi.plot<-cbind(csi,csi.pc)
csi.plot<-csi.plot[csi.plot$CSI =="Y",]
csi.plot<-csi.plot[with(csi.plot,order(-csi.pc)),]


## individual subjects

##
masub<-data.frame(with(case_control,table(DRUG_TYPE,MASUB)))
masub<-merge(masub,n,by="DRUG_TYPE")
masub.pc<-(masub$Freq.x/masub$Freq.y)*100
masub.plot<-cbind(masub,masub.pc)
masub.plot<-masub.plot[masub.plot$MASUB =="Y",]

langsub<-data.frame(with(case_control,table(DRUG_TYPE,LANGSUB)))
langsub<-merge(langsub,n,by="DRUG_TYPE")
langsub.pc<-(langsub$Freq.x/langsub$Freq.y)*100
langsub.plot<-cbind(langsub,langsub.pc)
langsub.plot<-langsub.plot[langsub.plot$LANGSUB =="Y",]

scsub<-data.frame(with(case_control,table(DRUG_TYPE,SCSUB)))
scsub<-merge(scsub,n,by="DRUG_TYPE")
scsub.pc<-(scsub$Freq.x/scsub$Freq.y)*100
scsub.plot<-cbind(scsub,scsub.pc)
scsub.plot<-scsub.plot[scsub.plot$SCSUB =="Y",]


############################################ plot graphs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

csi.plot$DRUG_TYPE<-factor(csi.plot$DRUG_TYPE, levels=unique(csi.plot$DRUG_TYPE[order(csi.plot$csi.pc)])) 
masub.plot$DRUG_TYPE<-factor(masub.plot$DRUG_TYPE, levels=masub.plot$DRUG_TYPE[order(masub.plot$masub.pc)])  
langsub.plot$DRUG_TYPE<-factor(langsub.plot$DRUG_TYPE, levels=langsub.plot$DRUG_TYPE[order(langsub.plot$langsub.pc)])
scsub.plot$DRUG_TYPE<-factor(scsub.plot$DRUG_TYPE, levels=scsub.plot$DRUG_TYPE[order(scsub.plot$scsub.pc)])



levels(scsub.plot$DRUG_TYPE)[1]<-"Polytherapy"
levels(scsub.plot$DRUG_TYPE)[2]<-"Lamotrigine"
levels(scsub.plot$DRUG_TYPE)[3]<-"Sodium Valproate"
levels(scsub.plot$DRUG_TYPE)[4]<-"No Drug"
levels(scsub.plot$DRUG_TYPE)[5]<-"Carbamazepine"
levels(scsub.plot$DRUG_TYPE)[6]<-"Control Group"
levels(scsub.plot$DRUG_TYPE)[7]<-"All Wales"

levels(csi.plot$DRUG_TYPE)[1]<-"Polytherapy"
levels(csi.plot$DRUG_TYPE)[2]<-"Lamotrigine"
levels(csi.plot$DRUG_TYPE)[3]<-"Sodium Valproate"
levels(csi.plot$DRUG_TYPE)[4]<-"No Drug"
levels(csi.plot$DRUG_TYPE)[5]<-"Carbamazepine"
levels(csi.plot$DRUG_TYPE)[6]<-"Control Group"
levels(csi.plot$DRUG_TYPE)[7]<-"All Wales"

levels(masub.plot$DRUG_TYPE)[1]<-"Polytherapy"
levels(masub.plot$DRUG_TYPE)[2]<-"Sodium Valproate"
levels(masub.plot$DRUG_TYPE)[3]<-"Lamotrigine"
levels(masub.plot$DRUG_TYPE)[4]<-"No Drug"
levels(masub.plot$DRUG_TYPE)[5]<-"Carbamazepine"
levels(masub.plot$DRUG_TYPE)[6]<-"Control Group"
levels(masub.plot$DRUG_TYPE)[7]<-"All Wales"

levels(langsub.plot$DRUG_TYPE)[1]<-"Polytherapy"
levels(langsub.plot$DRUG_TYPE)[2]<-"Lamotrigine"
levels(langsub.plot$DRUG_TYPE)[3]<-"Sodium Valproate"
levels(langsub.plot$DRUG_TYPE)[4]<-"No Drug"
levels(langsub.plot$DRUG_TYPE)[5]<-"Carbamazepine"
levels(langsub.plot$DRUG_TYPE)[6]<-"Control Group"
levels(langsub.plot$DRUG_TYPE)[7]<-"All Wales"


case_control.stats<-as.data.frame(case_control,stringsAsFactors=FALSE)
svpapoly<-read.csv("P:/laceya/polyvalalfs.csv")

levels(case_control.stats$DRUG_TYPE) <- c(levels(case_control.stats$DRUG_TYPE), "SVPAPOLY")

ccstats<-replace(case_control.stats$DRUG_TYPE, case_control.stats$ALF_E %in% svpapoly$ALF_E, "SVPAPOLY")



result<-case_control.stats[,c(4:7,11,16)]
levels(result$CSI) <- c(0,1,1)
levels(result$MASUB) <- c(0,1)
levels(result$LANGSUB) <- c(0,1)
levels(result$SCSUB) <- c(0,1)



##confidence interval


csi.summ<-group.CI(as.numeric(as.character(CSI))~DRUG_TYPE,result)
masub.summ<-group.CI(as.numeric(as.character(MASUB))~DRUG_TYPE,result)
scsub.summ<-group.CI(as.numeric(as.character(SCSUB))~DRUG_TYPE,result)
langsub.summ<-group.CI(as.numeric(as.character(LANGSUB))~DRUG_TYPE,result)

#csi.summ$DRUG_TYPE<-factor(csi.summ$DRUG_TYPE, levels=unique(csi.summ$DRUG_TYPE[order(csi.summ[3])])) 
#masub.summ$DRUG_TYPE<-factor(masub.summ$DRUG_TYPE, levels=masub.summ$DRUG_TYPE[order(masub.plot[3])])  
#langsub.summ$DRUG_TYPE<-factor(langsub.summ$DRUG_TYPE, levels=langsub.summ$DRUG_TYPE[order(langsub.summ[3])])
#scsub.summ$DRUG_TYPE<-factor(scsub.summ$DRUG_TYPE, levels=scsub.summ$DRUG_TYPE[order(scsub.summ[3])])


levels(scsub.summ$DRUG_TYPE)[6]<-"Polytherapy"
levels(scsub.summ$DRUG_TYPE)[2]<-"Lamotrigine"
levels(scsub.summ$DRUG_TYPE)[4]<-"Sodium Valproate"
levels(scsub.summ$DRUG_TYPE)[3]<-"No Drug"
levels(scsub.summ$DRUG_TYPE)[1]<-"Carbamazepine"
levels(scsub.summ$DRUG_TYPE)[5]<-"Control Group"
levels(scsub.summ$DRUG_TYPE)[7]<-"All Wales"

levels(csi.summ$DRUG_TYPE)[6]<-"Polytherapy"
levels(csi.summ$DRUG_TYPE)[2]<-"Lamotrigine"
levels(csi.summ$DRUG_TYPE)[4]<-"Sodium Valproate"
levels(csi.summ$DRUG_TYPE)[3]<-"No Drug"
levels(csi.summ$DRUG_TYPE)[1]<-"Carbamazepine"
levels(csi.summ$DRUG_TYPE)[5]<-"Control Group"
levels(csi.summ$DRUG_TYPE)[7]<-"All Wales"

levels(masub.summ$DRUG_TYPE)[6]<-"Polytherapy"
levels(masub.summ$DRUG_TYPE)[4]<-"Sodium Valproate"
levels(masub.summ$DRUG_TYPE)[2]<-"Lamotrigine"
levels(masub.summ$DRUG_TYPE)[3]<-"No Drug"
levels(masub.summ$DRUG_TYPE)[1]<-"Carbamazepine"
levels(masub.summ$DRUG_TYPE)[5]<-"Control Group"
levels(masub.summ$DRUG_TYPE)[7]<-"All Wales"

levels(langsub.summ$DRUG_TYPE)[6]<-"Polytherapy"
levels(langsub.summ$DRUG_TYPE)[2]<-"Lamotrigine"
levels(langsub.summ$DRUG_TYPE)[4]<-"Sodium Valproate"
levels(langsub.summ$DRUG_TYPE)[3]<-"No Drug"
levels(langsub.summ$DRUG_TYPE)[1]<-"Carbamazepine"
levels(langsub.summ$DRUG_TYPE)[5]<-"Control Group"
levels(langsub.summ$DRUG_TYPE)[7]<-"All Wales"


csi.plot<-merge(csi.plot,csi.summ)
masub.plot<-merge(masub.plot,masub.summ)
scsub.plot<-merge(scsub.plot,scsub.summ)
langsub.plot<-merge(langsub.plot,langsub.summ)

colnames(csi.plot)[6]<-"upper"
colnames(masub.plot)[6]<-"upper"
colnames(scsub.plot)[6]<-"upper"
colnames(langsub.plot)[6]<-"upper"
colnames(csi.plot)[8]<-"lower"
colnames(masub.plot)[8]<-"lower"
colnames(scsub.plot)[8]<-"lower"
colnames(langsub.plot)[8]<-"lower"


csi.limits<-aes(ymin=lower*100,ymax=upper*100)
masub.limits<-aes(ymin=lower*100,ymax=upper*100)
scsub.limits<-aes(ymin=lower*100,ymax=upper*100)
langsub.limits<-aes(ymin=lower*100,ymax=upper*100)

### csi
csi.graph<-ggplot(data=csi.plot,aes(x=DRUG_TYPE,y=csi.pc,fill=DRUG_TYPE,csi.pc),width=0.25) + 
geom_bar(stat="identity",position=position_dodge(),colour="black") + scale_fill_grey(guide=FALSE) + theme_classic() +
ggtitle("Core Subject Indicator") +
xlab("DRUG") +
ylab("% achieved pass") +
scale_y_continuous(limits=c(0,106),breaks=seq(0,100, by=10)) +
theme(axis.text.x = element_text(angle = 90,vjust=0.5),
      panel.grid.major= element_blank(),
      panel.background= element_blank(),
      plot.title = element_text(size=15,face="bold")) +
  annotate("text", x = 3,y= 100*csi.plot[7,6] + 2,label="*",size = 8) +
  annotate("text", x = 1,y= 100*csi.plot[6,6] + 2, label="*",size = 8) +
  annotate(x=c(1,1,6,6),y=c(98,99,99,98),"path") +
  annotate(x=c(3,3,6,6),y=c(105,106,106,105),"path") +
  geom_errorbar(csi.limits,position="dodge",width=0.2)



### maths

masub.graph<-ggplot(data=masub.plot,aes(x=DRUG_TYPE,y=masub.pc,fill=DRUG_TYPE,factor(masub.pc))) + 
geom_bar(stat="identity",position=position_dodge(),colour="black") + scale_fill_grey(guide=FALSE) + theme_classic() +
ggtitle("Mathematics") +
xlab("DRUG") +
ylab("% achieved pass") + 
scale_y_continuous(limits=c(0,106),breaks=seq(0,100, by=10)) +
theme(axis.text.x = element_text(angle = 90,vjust=0.5),
        panel.grid.major= element_blank(),
        panel.background= element_blank(),
      plot.title = element_text(size=15,face="bold")) + 
  annotate("text", x = 1,y= 100*masub.plot[6,6] + 2,label="*",size = 8) +
  annotate("text", x = 2,y= 100*masub.plot[7,6] + 2,label="*",size = 8) +
  annotate(x=c(1,1,6,6),y=c(98,99,99,98),"path") +
  annotate(x=c(2,2,6,6),y=c(105,106,106,105),"path")  +
  geom_errorbar(masub.limits,position="dodge",width=0.2)

  

## language

langsub.graph<-ggplot(data=langsub.plot,aes(x=DRUG_TYPE,y=langsub.pc,fill=DRUG_TYPE,factor(langsub.pc))) + 
  geom_bar(stat="identity",position=position_dodge(),colour="black") + scale_fill_grey(guide=FALSE) + theme_classic() +
  ggtitle("Language") +
  xlab("DRUG") +
  ylab("% achieved pass") + 
  scale_y_continuous(limits=c(0,106),breaks=seq(0,100, by=10)) +
  theme(axis.text.x = element_text(angle = 90,vjust=0.5),
        panel.grid.major= element_blank(),
        panel.background= element_blank(),
        plot.title = element_text(size=15,face="bold")) + 
  geom_errorbar(langsub.limits,position="dodge",width=0.2)


## science

     
scsub.graph<-ggplot(data=scsub.plot,aes(x=DRUG_TYPE,y=scsub.pc,fill=DRUG_TYPE)) + 
geom_bar(stat="identity",position=position_dodge(),colour="black") + scale_fill_grey(guide=FALSE) + theme_classic() +
ggtitle("Science") +
xlab("DRUG") +
ylab("% achieved pass") +
  scale_y_continuous(limits=c(0,106),breaks=seq(0,100, by=10)) +
theme(axis.text.x = element_text(angle = 90,vjust=0.5),
        panel.grid.major= element_blank(),
        panel.background= element_blank(),
      plot.title = element_text(size=15,face="bold")) + 
  annotate("text", x = 1,y= 100*scsub.plot[6,6]+2,label="*",size = 8) +
  annotate("text", x = 3,y= 100*scsub.plot[7,6]+2,label="**",size = 8) +
  annotate(x=c(1,1,6,6),y=c(98,99,99,98),"path") +
  annotate(x=c(3,3,6,6),y=c(105,106,106,105),"path") +
  geom_errorbar(scsub.limits,position="dodge",width=0.2)



graph<-grid.arrange(csi.graph,masub.graph,langsub.graph,scsub.graph,
main="Key Stage 1 Educational Attainment",ncol=2) 

title1<-textGrob("Key Stage 1 Educational Attainment",gp=gpar(fontface="bold",fontsize=15))

png(filename="education_graph_for_review.png",width=10,height=10,units="in",res=600)
grid.arrange(csi.graph,masub.graph,langsub.graph,scsub.graph,
             main=title1,ncol=2)
dev.off()


tiff(filename="education_graph_for_review.tif",width=6,height=7.5,units="in",res=300)
grid.arrange(csi.graph,masub.graph,langsub.graph,scsub.graph,
             main=title1,ncol=2)
dev.off()



df<-data.frame(
  trt=factor(c(1,1,2,2)),
  resp=c(1,5,3,4),
  group=factor(c(1,2,1,2)),
  se=c(0.1,0.3,0.3,0.2))

df2<-df[c(1,3),]

limits<-aes(ymax=resp+se,ymin=resp-se)

p<-ggplot(df,aes(fill=group,y=resp,x=trt))

p + geom_bar(stat="identity",position="dodge") + geom_errorbar(limits,position="dodge",width=0.25)









#########################################################################

######################################### p-values ################################################################
## create 'numeric' values to calculate averages

result2<-result[result$EP_ST=='N' || is.na(result$EP_ST),]
csi<-with(result2,table(CSI,DRUG_TYPE))
csi<-csi[-3,]
masub<-with(result2,table(MASUB,DRUG_TYPE))
langsub<-with(result2,table(LANGSUB,DRUG_TYPE))
scsub<-with(result2,table(SCSUB,DRUG_TYPE))


# pvalues for descriptive stats
#desc_stats.raw<-case_control.stats[,c(11:15)]

desc_stats.raw<-case_control[,c(11:15)]

wimd<-with(desc_stats.raw,table(WIMD2011_QUINT,DRUG_TYPE))


desc.split<-split(desc_stats.raw, desc_stats.raw$DRUG_TYPE)




# birth weight
for (i in 1:length(desc.split)){ 
  print(paste0(names(desc.split[i]),":   ",t.test(desc.split[[i]][2],desc.split[[5]][2])$p.value))
}
# maternal age
for (i in 1:length(desc.split)){ 
  print(paste0(names(desc.split[i]),":   ",t.test(desc.split[[i]][3],desc.split[[5]][3])$p.value))
}
# gest age
for (i in 1:length(desc.split)){ 
  print(paste0(names(desc.split[i]),":   ",t.test(desc.split[[i]][4],desc.split[[5]][4])$p.value))
}
# wimd
for (i in 1:length(desc.split)){ 
  print(paste0(names(desc.split[i]),":   ",t.test(desc.split[[i]][5],desc.split[[5]][5])$p.value))
}


stats.desc<-split(case_control,case_control$DRUG_TYPE)
stats.summary<-lapply(stats.desc, function(x) paste0(nrow(x),",",
                                                     nrow(x[x$GNDR_CD == 1,]),",",
                                                     formatC(paste0("meanWeight = ",mean(x$BIRTH_WEIGHT,na.rm=TRUE),digits=3)),",",
                                                     formatC(paste0("SDWeight = ",sd(x$BIRTH_WEIGHT,na.rm=TRUE),digits=3)),",",
                                                     formatC(paste0("meanAge = ",mean(x$MAT_AGE,na.rm=TRUE),digits=3)),",",
                                                     formatC(paste0("SDAge = ",sd(x$MAT_AGE,na.rm=TRUE),digits=3)),",",
                                                     formatC(paste0("meanGest = ",mean(x$GEST_AGE,na.rm=TRUE),digits=3)),",",
                                                     formatC(paste0("SDGest = ",sd(x$GEST_AGE,na.rm=TRUE),digits=3)),",",
                                                     nrow(x[x$EP_ST=="Y",]),",",
                                                     length(which(!is.na(x$SMOKE_ST))),",",
                                                     length(which(!is.na(x$AUTISM_ST))),",",
                                                     formatC(mean(x$WIMD2011_QUINT,na.rm=TRUE),digits=3),",",
                                                     formatC(paste0("SDWIMD = ",sd(x$WIMD2011_QUINT,na.rm=TRUE),digits=3)))
)

s<-summary(cases)

length(!complete.cases(cases$AUTISM_ST))




chisq.test(langsub[,c(1,5)])






dfn<-data.frame(group=c("A","B","C","D"),numb=c(12,24,36,48))
g<-ggplot(dfn,aes(group,numb))+geom_bar(stat="identity") 
g + geom_path(x=c(1,1,2,2),y=c(25,26,26,25))


##############################################################################








######## Significance test per drug on CSI, Maths, Science and Language


stats.csi<-list()
drugs<-data.frame(colnames(csi),stringsAsFactors=FALSE)
for (i in 1:nrow(drugs)){
  stats.csi[[i]]<-print(paste0(drugs[i,],",",sum(csi[,i]),",",paste0(round(csi[2,i]/sum(csi[,i]),4)*100,"%"),"(",round(chisq.test(csi[,c(i,5)])$p.value,3),")"
                               ,",",paste0(round(masub[2,i]/sum(masub[,i]),4)*100,"%"),"(",round(chisq.test(masub[,c(i,5)])$p.value,3),")"
                               ,",",paste0(round(scsub[2,i]/sum(scsub[,i]),4)*100,"%"),"(",round(chisq.test(scsub[,c(i,5)])$p.value,3),")"
                               ,",",paste0(round(langsub[2,i]/sum(langsub[,i]),4)*100,"%"),"(",round(chisq.test(langsub[,c(i,5)])$p.value,3),")"))
}

pvals<-list()
csi.pvals<-list()
for (i in 1:nrow(drugs)){
  csi.pvals[[i]]<-print(chisq.test(csi[,c(i,5)])$p.value)
}

masub.pvals<-list()
for (i in 1:nrow(drugs)){
  masub.pvals[[i]]<-print(chisq.test(masub[,c(i,5)])$p.value)
}

scsub.pvals<-list()
for (i in 1:nrow(drugs)){
  scsub.pvals[[i]]<-print(chisq.test(scsub[,c(i,5)])$p.value)
}

langsub.pvals<-list()
for (i in 1:nrow(drugs)){
  langsub.pvals[[i]]<-print(chisq.test(langsub[,c(i,5)])$p.value)
}

csi.adjust<-p.adjust(csi.pvals,method="bonferroni")
masub.adjust<-p.adjust(masub.pvals,method="bonferroni")
scsub.adjust<-p.adjust(scsub.pvals,method="bonferroni")
langsub.adjust<-p.adjust(langsub.pvals,method="bonferroni")




########## Poly therapy sub groups




polycomb<-read.csv("polytherapy_combinations.csv", header=F)








sqlQuery(channel,"insert into sailx031v.children_with_epilepsy_key_stage_1
         select distinct d1.* from
         
         (select distinct alf_e, event_cd, event_dt from SAILWLGPV.GP_EVENT_ALF_cleansed
         where event_cd like 'dn%'
         or event_cd like 'do%'
         and year(event_dt) - year(wob) between 6 and 7) d1
         
         inner join
         
         (select distinct alf_e, event_cd, event_dt from SAILWLGPV.GP_EVENT_ALF_cleansed
         where event_cd like 'dn%'
         or event_cd like 'do%') d2
         
         on d1.alf_e = d2.alf_e
         and d2.event_dt between d1.event_dt and d1.event_dt + 6 months")





############## maternal smoking exclusion

case_control.stats.non_smoker <- case_control.stats[case_control.stats$SMOKE_ST != 'smoker',]
result_ns<-case_control.stats.non_smoker[,c(4:7,11,16)]   #non-smokers

levels(result_ns$CSI) <- c(0,1,1)
levels(result_ns$MASUB) <- c(0,1)
levels(result_ns$LANGSUB) <- c(0,1)
levels(result_ns$SCSUB) <- c(0,1)




csi_ns<-with(result_ns,table(CSI,DRUG_TYPE))
csi_ns<-csi_ns[-3,]
masub_ns<-with(result_ns,table(MASUB,DRUG_TYPE))
langsub_ns<-with(result_ns,table(LANGSUB,DRUG_TYPE))
scsub_ns<-with(result_ns,table(SCSUB,DRUG_TYPE))






### p values non smoker


stats.csi_ns<-list()
drugs<-data.frame(colnames(csi_ns),stringsAsFactors=FALSE)
for (i in 1:nrow(drugs)){
  stats.csi_ns[[i]]<-print(paste0(drugs[i,],",",sum(csi_ns[,i]),",",paste0(round(csi_ns[2,i]/sum(csi_ns[,i]),4)*100,"%"),"(",round(chisq.test(csi_ns[,c(i,5)])$p.value,3),")"
                                  ,",",paste0(round(masub_ns[2,i]/sum(masub_ns[,i]),4)*100,"%"),"(",round(chisq.test(masub_ns[,c(i,5)])$p.value,3),")"
                                  ,",",paste0(round(scsub_ns[2,i]/sum(scsub_ns[,i]),4)*100,"%"),"(",round(chisq.test(scsub_ns[,c(i,5)])$p.value,3),")"
                                  ,",",paste0(round(langsub_ns[2,i]/sum(langsub_ns[,i]),4)*100,"%"),"(",round(chisq.test(langsub_ns[,c(i,5)])$p.value,3),")"))
}

pvals<-list()
csi_ns.pvals<-list()
for (i in 1:nrow(drugs)){
  csi_ns.pvals[[i]]<-print(chisq.test(csi_ns[,c(i,5)])$p.value)
}

masub_ns.pvals<-list()
for (i in 1:nrow(drugs)){
  masub_ns.pvals[[i]]<-print(chisq.test(masub_ns[,c(i,5)])$p.value)
}

scsub_ns.pvals<-list()
for (i in 1:nrow(drugs)){
  scsub_ns.pvals[[i]]<-print(chisq.test(scsub_ns[,c(i,5)])$p.value)
}

langsub_ns.pvals<-list()
for (i in 1:nrow(drugs)){
  langsub_ns.pvals[[i]]<-print(chisq.test(langsub_ns[,c(i,5)])$p.value)
}

csi_ns.adjust<-p.adjust(csi_ns.pvals,method="bonferroni")
masub_ns.adjust<-p.adjust(masub_ns.pvals,method="bonferroni")
scsub_ns.adjust<-p.adjust(scsub_ns.pvals,method="bonferroni")
langsub_ns.adjust<-p.adjust(langsub_ns.pvals,method="bonferroni")


csi_ns.adjust




csi_ns[,c(i,5)]




# control smokers


sqlQuery(channel,"select count(distinct c.alf_e) from session.ep_mothers_control a
inner join sailncchv.CHILD_BIRTHS b
         on a.ALF_E = b.ALF_E
         inner join sailwlgpv.GP_EVENT_ALF_CLEANSED c
         on b.MAT_ALF_E = c.ALF_E
         WHERE c.EVENT_CD IN ('137..','1372.' ,'1373.' ,'1374.' ,'1375.' ,'1376.' , '137a.','137b.','137I.' , '137c.' , '137C.' ,'137d.','137D.','137e.' ,'137E.', '137K.','137K0','137k.','137f.','137g.','137G.' ,'137h.' ,'137H.','137J.','137J0','137M.','137m.','137P.','137P.','137P0','137Q.' ,'137Q.','137R.','137V.' ,'137W.','137X.','137Y.','137Z.','137c.')
         and c.event_dt between b.wob - 9 months and b.wob")






########### polytherapy sub groups




svpapoly<-read.csv("P:/laceya/polyvalalfs.csv")
case_control.stats.polysub <- case_control.stats
case_control.stats.polysub$SMOKE_ST <- "NA"
case_control.stats.polysub$AUTISM_ST <- "NA"
case_control.stats.polysub$EP_ST <- "NA"
case_control.stats.polysub <- unique(case_control.stats.polysub)

levels(case_control.stats.polysub$DRUG_TYPE) <- c(levels(case_control.stats.polysub$DRUG_TYPE), "SVPAPOLY")

case_control.stats.polysub$DRUG_TYPE<-replace(case_control.stats.polysub$DRUG_TYPE, case_control.stats.polysub$ALF_E %in% svpapoly$ALF_E, "SVPAPOLY")
case_control.stats.polysub <- unique(case_control.stats.polysub)




result.polysub<-case_control.stats.polysub[,c(4:7,11,16)]
levels(result.polysub$CSI) <- c(0,1,1)
levels(result.polysub$MASUB) <- c(0,1)
levels(result.polysub$LANGSUB) <- c(0,1)
levels(result.polysub$SCSUB) <- c(0,1)




csi.polysub<-with(result.polysub,table(CSI,DRUG_TYPE))
csi.polysub<-csi.polysub[-3,]
masub.polysub<-with(result.polysub,table(MASUB,DRUG_TYPE))
langsub.polysub<-with(result.polysub,table(LANGSUB,DRUG_TYPE))
scsub.polysub<-with(result.polysub,table(SCSUB,DRUG_TYPE))




stats.csi.polysub<-list()
drugs<-data.frame(colnames(csi.polysub),stringsAsFactors=FALSE)
for (i in 1:nrow(drugs)){
  stats.csi.polysub[[i]]<-print(paste0(drugs[i,],",",sum(csi.polysub[,i]),",",paste0(round(csi.polysub[2,i]/sum(csi.polysub[,i]),5)*100,"%"),"(",round(chisq.test(csi.polysub[,c(i,5)])$p.value,3),")"
                                       ,",",paste0(round(masub.polysub[2,i]/sum(masub.polysub[,i]),5)*100,"%"),"(",round(chisq.test(masub.polysub[,c(i,5)])$p.value,3),")"
                                       ,",",paste0(round(scsub.polysub[2,i]/sum(scsub.polysub[,i]),5)*100,"%"),"(",round(chisq.test(scsub.polysub[,c(i,5)])$p.value,3),")"
                                       ,",",paste0(round(langsub.polysub[2,i]/sum(langsub.polysub[,i]),4)*100,"%"),"(",round(chisq.test(langsub.polysub[,c(i,5)])$p.value,3),")"))
}

pvals<-list()
csi.polysub.pvals<-list()
for (i in 1:nrow(drugs)){
  csi.polysub.pvals[[i]]<-print(chisq.test(csi.polysub[,c(i,5)])$p.value)
}

masub.polysub.pvals<-list()
for (i in 1:nrow(drugs)){
  masub.polysub.pvals[[i]]<-print(chisq.test(masub.polysub[,c(i,5)])$p.value)
}

scsub.polysub.pvals<-list()
for (i in 1:nrow(drugs)){
  scsub.polysub.pvals[[i]]<-print(chisq.test(scsub.polysub[,c(i,5)])$p.value)
}

langsub.polysub.pvals<-list()
for (i in 1:nrow(drugs)){
  langsub.polysub.pvals[[i]]<-print(chisq.test(langsub.polysub[,c(i,5)])$p.value)
}


#csi.polysub.pvals<-csi.polysub.pvals[-5]


csi.polysub.adjust<-p.adjust(csi.polysub.pvals,method="bonferroni")
masub.polysub.adjust<-p.adjust(masub.polysub.pvals,method="bonferroni")
scsub.polysub.adjust<-p.adjust(scsub.polysub.pvals,method="bonferroni")
langsub.polysub.adjust<-p.adjust(langsub.polysub.pvals,method="bonferroni")


csi.polysub.adjust




csi.polysub[,c(i,5)]





# skip to poly


print(chisq.test(csi.polysub[,c(4,5)])$p.value)
