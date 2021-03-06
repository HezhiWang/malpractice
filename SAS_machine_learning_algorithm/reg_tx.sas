proc sql;
  update DCH070SL.Merged_all
  set avg_num_phyvis_CLAIM = 0 where avg_num_phyvis_CLAIM = .;
quit;run;

proc sql;
update DCH070SL.Merged_all 
set avg_er_vis_CLAIM = 0 where avg_er_vis_CLAIM = .;
quit;run;

proc sql;
update DCH070SL.Merged_all 
set avg_er_vis_PDE = 0 where avg_er_vis_PDE = .;
quit;run;

proc sql;
update DCH070SL.Merged_all 
set avg_num_phyvis_PDE = 0 where avg_num_phyvis_PDE = .;
quit;run;

proc sql;
update DCH070SL.Merged_all 
set avg_loscnt = 0 where avg_loscnt = .;
quit;run;

proc sql;
update DCH070SL.Merged_all 
set avg_mdcr_pmt_amt = 0 where avg_mdcr_pmt_amt = .;
quit;run;

proc sql;
  update DCH070SL.Merged_all_TX
  set avg_num_phyvis_CLAIM = 0 where avg_num_phyvis_CLAIM = .;
quit;run;

proc sql;
update DCH070SL.Merged_all_TX
set avg_er_vis_CLAIM = 0 where avg_er_vis_CLAIM = .;
quit;run;

proc sql;
update DCH070SL.Merged_all_TX
set avg_er_vis_PDE = 0 where avg_er_vis_PDE = .;
quit;run;

proc sql;
update DCH070SL.Merged_all_TX
set avg_num_phyvis_PDE = 0 where avg_num_phyvis_PDE = .;
quit;run;

proc sql;
update DCH070SL.Merged_all_TX
set avg_loscnt = 0 where avg_loscnt = .;
quit;run;

proc sql;
update DCH070SL.Merged_all_TX
set avg_mdcr_pmt_amt = 0 where avg_mdcr_pmt_amt = .;
quit;run;


data temp;
set DCH070SL.Merged_all;
n=ranuni(8);
proc sort data=temp;
  by n;
  data train test;
   set temp nobs=nobs;
   if _n_<=.7*nobs then output train;
    else output test;
   run;


ods graphics on;

proc glmselect data=train testdata=test
               seed=1 plots(stepAxis=number)=(criterionPanel ASEPlot);
   partition fraction(validate=0.3);

  class sex PrimarySpecialty;
   model Target = sex|PrimarySpecialty|Num_of_Patients_CLAIM|Avg_PMT_AMT_CLAIM|Avg_PRVDR_PMT_AMT_CLAIM|Num_of_Male_CLAIM|Num_of_Female_CLAIM|Avg_patient_birth_year_CLAIM|Race_Unknown_CLAIM|Race_White_CLAIM|Race_Black_CLAIM|Race_Other_CLAIM
   |Race_Asian_CLAIM|Race_Hispanic_CLAIM|Race_North_American_Native_CLAIM|NUM_OF_DEATH_PATIENT_CLAIM|avg_num_phyvis_CLAIM|avg_er_vis_CLAIM|avg_loscnt|avg_mdcr_pmt_amt|Num_of_Patients_PDE|Num_of_Male_PDE|Num_of_Female_PDE
   |Avg_Quantity_Dispensed_PDE|Avg_Days_Supply_PDE|Avg_Drug_Cost_PDE|Avg_patient_birth_year_PDE|Race_Unknown_PDE|Race_White_PDE|Race_Black_PDE|Race_Other_PDE|Race_Asian_PDE|Race_Hispanic_PDE|Race_North_American_Native_PDE|NUM_OF_DEATH_PATIENT_PDE
  |avg_num_phyvis_PDE|avg_er_vis_PDE|phy_exp|phy_age|avg_num_phyvis_CLAIM|avg_er_vis_CLAIM|avg_er_vis_PDE|avg_num_phyvis_PDE|avg_loscnt|avg_mdcr_pmt_amt @2
           / selection=stepwise(choose = validate
                                select = sl)
             hierarchy=single stb;
  code file = ‘/sas/vrdc/users/dch070/files/_uploads/reg-code.sas’;
  score data = DCH070SL.Merged_all_TX out = DCH070SL.Merged_all_TX_reg;
run;
ods graphics off;

proc sql;
update DCH070SL.Merged_all_TX_reg
set p_Target = 1 where p_Target > 1;
quit;run;

proc sql;
update DCH070SL.Merged_all_TX_reg
set p_Target = 0 where p_Target < 0;
quit;run;

proc sql;
    create table DCH070SL.predict_TX_reg as
    select FIPSCounty, Year, sum(p_Target) as predict_sum
    from DCH070SL.Merged_all_TX_reg
    group by FIPSCounty, Year
    order by FIPSCounty, Year;
run;quit;

pro sql;
create table DCH070SL.predict_merge_reg as
select a.FIPSCounty, a.Year, a.predict_sum, b.count
from DCH070SL.predict_TX_reg as a
inner join 
DCH070SL.malpracticetx as b
on input(a.FIPSCounty,10.) = b.fips_char
and a.year = b.year;
run; quit;

data DCH070SL.predict_merge_reg;
set DCH070SL.predict_merge_reg;
error_per = (predict_sum - count) / count;
run;

proc means data=DCH070SL.predict_merge_reg n mean max min range std fw=8;
   var error;
run;