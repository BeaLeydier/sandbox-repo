


clear 
set more off

cd "C:\Users\bl517\Documents\HDN-SP\ECA\AgingConsumption\Data\Georgia 2000"

local usepath "C:\Users\wb461621\Documents\HDN-SP\ECA\AgingConsumption\Data\ECAPOV Data\Georgia\GEO_2000_HIS_v01_M_v01_A_ECAPOV.dta" 

local savepath "C:\Users\wb461621\Documents\HDN-SP\ECA\AgingConsumption\Data\Georgia 2000"

use "`usepath'", clear


*Household id


rename hhid idh3
destring idh3, replace
label var idh3 "Household id"



*Individual id

rename pid idp 
destring idp, replace
label var idp "Individual id"
sort idh idp
distinct idh idp

*******************************************
*Household and Individual Weight variables
*******************************************

gen hhwgt=int(weight+sign(weight)/2)
label var hhwgt "Household sampling weight"

gen indwgt= hhwgt*hhsize
label var indwgt "Person weight"

*svyset psu [pweight=hhwgt], strata(strata)

*Rename health variable

rename health g6pc
label var g6pc "Health"

*************************
*Households with a Widow
*************************

gen widow =1 if marstat==5
replace widow =0 if marstat!=5

sort idh idp
preserve
collapse (sum) widow, by (idh)
gen widow_hh = 1 if widow==1
replace widow_hh =0 if widow==0
label var widow_hh "HH w Widow"

*merging
save "hhtype_test.dta", replace
restore
sort idh idp
*drop _m
merge m:1  idh using "hhtype_test.dta", keepusing (widow_hh)
tab _merge
drop _merge
erase "hhtype_test.dta"


***********************
*Households on pension
***********************

gen hhpension = 1 if sh_pens != 0
replace hhpension = 0 if sh_pens == 0
replace hhpension = . if sh_pens == .
label var hhpension "households receiving pension"


*********************************************
*Household Types based on Household head age
*********************************************

gen head = 1 if reltohed==1 
replace head = 0 if reltohed != 1
replace head = . if reltohed ==.


preserve
sort idh head
collapse (first) head age, by (idh)

gen headage = 1 if age<30
*replace headage = 2 if age>19 & age <30 
replace headage = 3 if age>29 & age<40
replace headage = 4 if age>39 & age<50 
replace headage = 5 if age>49 & age<60 
replace headage = 6 if age>59 & age<70
replace headage = 7 if age>69 & age<80
replace headage = 8 if age> 79 
replace headage = . if age == .
label var headage "Household Head Age"
la def lblheadage 1 "1. Household Head less than 30" 3 "3. Household Head in 30s" 4 "4. Household Head in 40s" ///
5 "5. Household Head in 50s" 6 "6. Household Head in 60s" 7 "7. Household Head in 70s" ///
8 "8. Household Head 80+"

label values headage lblheadage

keep headage idh
sort idh
save "hhtype_age_test.dta", replace
restore

sort idh idp
merge m:1 idh using "hhtype_age_test.dta", keepusing (headage)
tab _merge
drop _merge
erase "hhtype_age_test.dta"


*************************
* Female Household Head
*************************

gen gender = 2 if female==1
replace gender = 1 if female==0

la de lblgender 1 "Male" 2 "Female", replace 

label var gender "Gender"
label values gender lblgender


preserve
sort idh head gender
collapse (first) head gender, by (idh)
gen femalehh = 1 if gender==2
replace femalehh = 0 if gender ==1
replace femalehh = . if gender==.
label var femalehh "Female Household Head"
keep femalehh idh
sort idh
save "hhtype_femaleHH_test.dta", replace
restore

sort idh idp
merge m:1 idh using "hhtype_femaleHH_test.dta", keepusing (femalehh)
tab _merge
drop _merge
erase "hhtype_femaleHH_test.dta"


**********************************************
*Household Types based on household structure
**********************************************

gen byte elderly=1 if age>=60 & age<120
replace elderly=0 if age<60 
label var elderly "Elderly (60+)"
la de elderly  0 "Not elderly (0-59)" 1 "Elderly (60+)"
lab val elderly elderly

gen byte workingage=.
replace workingage =1 if age >=15 & age <60
replace workingage =0 if workingage !=1
la de workingage 1 "Working Age (15-59)" 0 "Non-Working Age (0-15 or 60+)", replace
label var workingage "Working Age (15-59)"
lab val workingage workingage

gen byte youth=.
replace youth =1 if age <15
replace youth =0 if age>=15 & age <120
label var youth "Youth (0-14)"
la de youth 1 "Youth (0-14)" 0 "Non-Youth (15+)", replace
lab val youth youth


sort idh idp
preserve
collapse (sum) workingage elderly youth idp, by(idh)
sort idh idp
gen hhtype_gen =. 
replace hhtype_gen =1 if elderly >=1 & (workingage ==0 & youth ==0)
replace hhtype_gen =2 if elderly ==0 
replace hhtype_gen =3 if elderly >=1 & (workingage >=1 | youth >=1)  
la de hhtype_gen 1 "Elderly-Only Households" 2 "Non-Elderly Households" 3 "Some Elderly Households"
label var hhtype_gen "Living Arrangements - Basic"
la val hhtype_gen hhtype_gen

gen hhtype_det =. 
replace hhtype_det =1 if elderly ==1 & (workingage ==0 & youth ==0)
replace hhtype_det =2 if elderly >1  & (workingage ==0 & youth ==0)
replace hhtype_det =3 if elderly ==0 & (workingage >=1 & youth ==0)
replace hhtype_det =4 if elderly >=1 & (workingage >=1 & youth ==0)
replace hhtype_det =5 if elderly >=1 & (workingage ==0 & youth >=1)
replace hhtype_det =6 if elderly >=1 & (workingage >=1 & youth >=1)
replace hhtype_det =7 if elderly ==0 & (workingage >=1 & youth >=1) | elderly ==0 & (workingage ==0 & youth >=1)

la def hhtype_det 1 "1. Elderly only - lone" 2 "2. Elderly only - 2+" 3 "3. Working age only"  4 "4. Elderly with Working age" ///
5 "5. Elderly with Youth" 6 "6. Elderly with Working age and Youth" 7 "7. Working age with Youth; Youth Only" , replace
label var hhtype_det "Living Arrangements - Detailed"
la val hhtype_det hhtype_det
save "hhtype_test.dta", replace
restore
*drop _m
sort idh idp
merge m:1 idh using "hhtype_test.dta", keepusing (hhtype_gen hhtype_det)
tab _merge
erase "hhtype_test.dta"
drop _merge

preserve
sort idh idp
collapse (max) youth workingage elderly hhtype_gen idp, by (idh)
gen hh_eld_none=1 if hhtype_gen==2
replace hh_eld_none=0 if hhtype_gen!=2
label var hh_eld_none "HH No Elderly"
gen hh_eld_any=1 if hhtype_gen==1|hhtype_gen==3
replace hh_eld_any=0 if hhtype_gen==2
label var hh_eld_any "HH w Any Elderly"
gen hh_eld_only=1 if hhtype_gen==1
replace hh_eld_only=0 if hhtype_gen!=1
label var hh_eld_only "HH Only Elderly"
gen hh_eld_some=1 if hhtype_gen==3
replace hh_eld_some=0 if hhtype_gen!=3
label var hh_eld_some "HH Mixed"
save "hhtype_test.dta", replace
restore
sort idh idp
*drop _m
merge m:1 idh using "hhtype_test.dta", keepusing (hh_eld_any hh_eld_some hh_eld_only hh_eld_none)
tab _merge
erase "hhtype_test.dta"
drop _merge

la def  hh_eld_none 1 "Yes_Non-Elderly HH" 0 " No_Elderly in HH", replace 
la val hh_eld_none hh_eld_none
ta hh_eld_none
la de hh_eld_any 0 "No - No Elderly in HH" 1 "Yes - Either Elderly-Only or Mixed HH", replace
la val hh_eld_any hh_eld_any
la de hh_eld_some 0 "No - No Elderly in HH" 1 "Yes - Elderly & Non-Eld HH", replace
la val hh_eld_some hh_eld_some
la de hh_eld_only 0 "No - No Elderly in HH" 1 "Yes - Elderly-Only HH", replace
la val hh_eld_only hh_eld_only
la de hh_eld_none 0 "No - Have Elderly in HH" 1 "Yes - Non-Elderly HH", replace
la val hh_eld_none hh_eld_none


*************
*Coresidence
************* 

sort idh idp
*drop a
preserve

gen coresident = .
replace coresident =1 if hhtype_gen==3 
///Elderly living with non-elderly
replace coresident =0 if hhtype_gen!=3 
///Elderly-only hh
la def coresident 1 "Yes_w_non-elderly" 0 " No_Elderly-only", replace 
la val coresident coresident
save "hhtype_test.dta", replace
restore
sort idh idp
*drop _m
merge 1:1 idh idp using "hhtype_test.dta", keepusing (coresident)
tab _merge
erase "hhtype_test.dta"
drop _merge
label var coresident "Elderly live w/ non-elderly"

****************************
*Dependency Ratio Variables
****************************

sort idh idp

preserve
collapse (sum) youth workingage elderly, by (idh)
gen nyouth = youth
gen nworkingage = workingage
gen nelderly = elderly

egen ndepends = rsum(nyouth nelderly)

*HH Dependency Ratio
gen hh_tot_dep_rat = ndepends/nworkingage
label var hh_tot_dep_rat "HH Total Dependency Ratio"


*Elderly Dependency Ratio
gen hh_eld_dep_rat = nelderly/nworkingage
label var hh_eld_dep_rat "HH Elderly Dependency Ratio"

*Youth Dependency Ratio
gen hh_you_dep_rat = nyouth/nworkingage
label var hh_you_dep_rat "HH Youth Dependency Ratio"

egen hhsize1 = rsum(nyouth nworkingage nelderly)
save "depratiovarsGEO2000.dta", replace
restore

sort idh idp
merge m:1 idh using "depratiovarsGEO2000.dta", keepusing (nyouth nelderly nworkingage hh_tot_dep_rat hh_eld_dep_rat hh_you_dep_rat hhsize1)
tab _merge
drop _merge

******************
*Education Level
******************

rename edlev eduind
recode eduind 1 = 0
recode eduind 2 = 3
recode eduind 0 = 2
recode eduind 5 = 1

label var eduind "Education Level Completed - Individual"
la de lbleduind  1 "No Education" 2 "Primary" 3 "Secondary" 4 "Post Secondary" 
label values eduind  lbleduind


gen eduhead = eduind if head==1
replace eduhead = . if eduind==. 
label var eduhead "Education Level Completed - HH Head"
la de lbleduhead  1 "No Education" 2 "Primary" 3 "Secondary" 4 "Post Secondary" 
label values eduhead  lbleduhead




**************************************
*Averages - Gender (Individual level)
**************************************

logout, save(Average-Gender65GEO2000.xls) excel replace: tab gender if age>=65

logout, save(Average-Gender75GEO2000.xls) excel replace: tab gender if age>=75

********************************
*Making CPI and PPP Adjustments
********************************

foreach var of varlist g1pc g2pc g3pc g4pc g5pc g6pc g7pc g8pc g9pc g10pc g11pc g12pc rent gall durables {
summarize `var' [aw=popw]
local mcons = r(mean)
	 replace `var' = `var'/icp2005/cpi2005
}

**Identifying and dropping duplicates

sort idh reltohed
quietly by idh reltohed: gen dup = cond(_N==1,0,_n)
tab dup
list idh age gender marstat head if reltohed==1 & dup>0

*Checks

list idh age gender marstat head if reltohed==1 & dup>0

drop if idh==67531 | idh==67556 | idh==68084 | idh==68232 | idh==68596 | idh==69086 | idh==69336 | idh==69543 | idh==69824 | idh==70268 | idh==71124 | idh==71360 ///
 | idh==71416 | idh==71562 | idh==71701 | idh==72602

list idh age gender marstat reltohed if head==0 & hhsize==1
 
recode reltohed 2 = 1 if hhsize==1 & head==0
recode reltohed 3 = 1 if hhsize==1 & head==0
recode reltohed 4 = 1 if hhsize==1 & head==0
recode reltohed 5 = 1 if hhsize==1 & head==0
recode reltohed 6 = 1 if hhsize==1 & head==0
recode reltohed 8 = 1 if hhsize==1 & head==0

replace head = 1 if reltohed==1

**///Collapsing data to household level///

distinct idh idp

sort idh reltohed
collapse (first) g1pc g2pc g3pc g4pc g5pc g6pc g7pc g8pc g9pc g10pc g11pc g12pc durables hhtype_det hhtype_gen femalehh headage age gender head ///
hhpension coresident hhsize weight hhsize1 nelderly nworkingage nyouth hh_tot_dep_rat hh_eld_dep_rat hh_you_dep_rat widow_hh gallT eduind eduhead reltohed, by (idh)

tab reltohed
drop if head==0 & (reltohed==2 | reltohed==3 | reltohed==5 | reltohed==8)


distinct idh


label var g1pc "Food Consumption"
label var g2pc "Alcohol/Tobacco"
label var g3pc "Clothing"
label var g4pc "Housing"
label var g5pc "Furnishing"
label var g6pc "Health"
label var g7pc "Transport"
label var g8pc "Communications" 
label var g9pc "Recreation"
label var g10pc "Education"
label var g11pc "Hostel/Restaurant"
label var g12pc "Misc"
label var durables "Durables"
label var hh_tot_dep_rat "HH Total Dependency Ratio"
label var hh_eld_dep_rat "HH Elderly Dependency Ratio"
label var hh_tot_dep_rat "HH Total Dependency Ratio"


*******************************************
*Household and Individual Weight variables
*******************************************

gen hhwgt=int(weight+sign(weight)/2)
label var hhwgt "Household sampling weight"

gen indwgt= hhwgt*hhsize
label var indwgt "Person weight"

*************************************
*Dependency Ratio and Household Size
*************************************

xtile hh_tot_dep_rat_q = hh_tot_dep_rat [pw=weight*hhsize1], n(4)
sum hh_tot_dep_rat if hh_tot_dep_rat_q==3
gen high_dep_rat_line=r(max)

gen high_dep_rat_hh =1 if hh_tot_dep_rat>=high_dep_rat_line
replace high_dep_rat_hh =0 if hh_tot_dep_rat<high_dep_rat_line
label var high_dep_rat_hh "High HH Total Dependency Ratio"

sum hh_tot_dep_rat if hh_tot_dep_rat_q==1
gen low_dep_rat_line=r(max)

gen low_dep_rat_hh =1 if hh_tot_dep_rat<=low_dep_rat_line
replace low_dep_rat_hh =0 if hh_tot_dep_rat>low_dep_rat_line
label var low_dep_rat_hh "Low HH Total Dependency Ratio"


*********
*HH Size
*********

xtile hh_size_c = hhsize1 [pw=weight*hhsize1], n(4)
sum hhsize1 if hh_size_c==3
gen large_hh_line=r(max)
gen large_hhsize = 1 if hhsize1>=large_hh_line
replace large_hhsize = 0 if hhsize1<large_hh_line
label var large_hhsize "Large HH Size - Top 75%"

sum hhsize1 if hh_size_c==1
gen small_hh_line=r(max)
gen small_hhsize = 1 if hhsize1<=small_hh_line
replace small_hhsize = 0 if hhsize1>small_hh_line
label var small_hhsize "Small HH Size - Bottom 25%"


*******************
*Household Welfare
*******************

xtile hh_welfare_c = gallT [pw=weight*hhsize1], n(100)
sum gallT if hh_welfare_c==75
gen q4_hhline=r(max)
gen q4_hh = 1 if gallT>=q4_hhline
replace q4_hh = 0 if gallT < q4_hhline
label var q4_hh "Non-Poor HH - Top 75%"

sum gallT if hh_welfare_c==25
gen q1_hhline=r(max)
gen q1_hh = 1 if gallT<=q1_hhline
replace q1_hh = 0 if gallT>q1_hhline 
label var q1_hh "Poor HH - Bottom 25%"


*******************
*Means - HH Level
*******************

logout, save (Mean_FemaleHHGEO2000.xsl) excel replace: tab femalehh
logout, save (Mean_FemaleHH_HeadAgeGEO2000.xsl) excel replace: tab headage femalehh

**Sample averages across different categories according to the age of household head

logout, save(Averages-HeadageGEO2000.xls) excel replace: tab headage

logout, save(Average-Headage-HouseholdGEO2000.xls) excel replace: tab headage if head==1

global consumption g1pc g2pc g3pc g4pc g5pc g6pc g7pc g8pc g9pc g10pc g11pc g12pc durables

********************
*Average Consumption
********************

preserve
collapse $consumption [pweight=indwgt]
outsheet using "Consumption_2000GEO.xls", replace
restore

**************************************
*Average comsumption of each category 
**************************************

**///By Household Head Education///

preserve
collapse $consumption [pweight=indwgt], by (eduhead)
outsheet using "ConsumptionHHEdu_2000GEO.xls", replace
restore

**///By Household Head Age///

preserve
collapse $consumption [pweight=indwgt], by (headage)
outsheet using "ConsumptionHHage_2000GEO.xls", replace
restore

**///By Gender of Household Head///

tab femalehh

preserve
collapse $consumption [pweight=indwgt], by (femalehh) 
outsheet using "ConsumptionFemaleHH2000GEO.xls", replace
restore

**///By Gender & Household Head Age///

preserve
collapse $consumption [pweight=indwgt], by (femalehh headage) 
outsheet using "ConsumptionFemaleHH_2000GEO.xls", replace
restore


***///Consumption shares over time for synthetic household types///

**Consumption across household types (general - 3 categories)

preserve
collapse $consumption [pweight=indwgt], by (hhtype_gen) 
outsheet using "ConsumptionHHType_Gen2000GEO.xls", replace
restore


*Consumption across household types (Detailed - 7 categories)

preserve
collapse $consumption [pweight=indwgt], by (hhtype_det) 
outsheet using "ConsumptionHHType_Det2000GEO.xls", replace
restore

**Consumption - Pension

preserve
collapse $consumption [pweight=indwgt], by (hhpension)
outsheet using "ConsumptionPensionHH2000GEO.xls", replace
restore

** Consumption patterns in Households with a widow 

preserve
collapse $consumption [pweight=indwgt], by (widow_hh)
outsheet using "ConsumptionWidowHH2000GEO.xls", replace
restore

** Consumption in top welfare quartile households

preserve
collapse $consumption [pweight=indwgt], by (q4_hh)
outsheet using "ConsumptionTopQuintile2000GEO.xls", replace
restore

** Consumption in bottom welfare quartile households

preserve
collapse $consumption [pweight=indwgt], by (q1_hh)
outsheet using "ConsumptionBottomQuintile2000GEO.xls", replace
restore


** Consumption in small households

preserve
collapse $consumption [pweight=indwgt], by (small_hhsize)
outsheet using "ConsumptionSmallHH2000GEO.xls", replace
restore

** Consumption in large households

preserve
collapse $consumption [pweight=indwgt], by (large_hhsize)
outsheet using "ConsumptionLargeHH2000GEO.xls", replace
restore

** Consumption in High Dependency Ratio households

preserve
collapse $consumption [pweight=indwgt], by (high_dep_rat_hh)
outsheet using "ConsumptionHighDepRatio2000GEO.xls", replace
restore


** Consumption in Low Dependency Ratio households
preserve
collapse $consumption [pweight=indwgt], by (low_dep_rat_hh)
outsheet using "ConsumptionLowDepRatio2000GEO.xls", replace
restore

************************
*Distribution by Headage
************************

cd "C:\Users\wb461621\Documents\HDN-SP\ECA\AgingConsumption\Data\Georgia 2000"

logout, save (Dist_HeadAgeGEO2000.xsl) excel replace: table headage, row col

logout, save (DistPop_HeadAgeGEO2000.xsl) excel replace: table headage [pweight=indwgt], row col 

save georgia2000updated, replace
