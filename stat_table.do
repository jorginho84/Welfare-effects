/*

This do-file computes the descriptive stat table

*/

clear all
set matsize 800

local user Jorge-server

if "`user'" == "andres"{
	cd 				"/Users/andres/Dropbox/jardines_elpi"
	global db 		"/Users/andres/Dropbox/jardines_elpi/data"
	global codes 	"/Users/andres/Dropbox/jardines_elpi/codes"
}
 
else if "`user'" == "Jorge-server"{
 
  global db "/home/jrodriguezo/childcare/data"
  global codes "/home/jrodriguezo/childcare/codes"
  global results "/home/jrodriguezo/childcare/results"             
}

else if "`user'" == "Jorge"{
 
  global db "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Data"
  global results "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Results"          
}

	if "`c(username)'" == "Cecilia"{
	global des		"C:\Users\Cecilia\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
}

	if "`c(username)'" == "ccorrea"{
	global des		"G:\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\ccorrea\OneDrive - Universidad de los Andes\Documentos\GitHub\Welfare-effects"
}

cd "$des"

set more off

use "$db/data_estimate", clear


*Outcomes
qui: sum battelle
local mean_BATTELLE = string(round(r(mean),.001),"%9.3f")
local sd_BATTELLE = string(round(r(sd),.001),"%9.3f")

qui: sum tvip
local mean_TVIP = string(round(r(mean),.001),"%9.3f")
local sd_TVIP = string(round(r(sd),.001),"%9.3f")

// qui: sum cbcl
// local mean_CBCL = string(round(r(mean),.001),"%9.3f")
// local sd_CBCL = string(round(r(sd),.001),"%9.3f")

qui: sum d_work_18
local mean_d_work_18 = string(round(r(mean),.001),"%9.3f")
local sd_d_work_18 = string(round(r(sd),.001),"%9.3f")

foreach var in  wage hours_w  {	
	qui: sum `var'_18
	local mean_`var'_18 = string(round(r(mean),.01),"%9.2f")
	local sd_`var'_18 = string(round(r(sd),.01),"%9.2f")
}

*Treatment
qui: sum public_34
local mean_public_34 = string(round(r(mean),.001),"%9.3f")

*Instruments
foreach var in "34"{	
	qui: sum min_center_NM
	local mean_min_center_`var' = string(round(r(mean),.001),"%9.3f")
	local sd_min_center_`var' = string(round(r(sd),.001),"%9.3f")
}

*Covariates
forvalues x = 1/4{
		gen dum_m_educ_`x' = m_educ  == `x'
		replace dum_m_educ_`x' = . if m_educ == .
		qui: sum dum_m_educ_`x'
		local mean_dum_m_educ_`x' = string(round(r(mean),.001),"%9.3f")
		
}

foreach var in "num" "vo"{
	qui: sum WAIS_t_`var'
	local mean_WAIS_t_`var' = string(round(r(mean),.001),"%9.3f")
	local sd_WAIS_t_`var' = string(round(r(sd),.001),"%9.3f")
	
}


qui: sum m_age
local mean_m_age = string(round(r(mean),.01),"%9.2f")
local sd_m_age = string(round(r(sd),.01),"%9.2f")

foreach var in  dum_young_siblings f_home controles dum_smoke dum_alc{
	qui: sum `var'
	local mean_`var' = string(round(r(mean),.001),"%9.3f")
	local sd_`var' = string(round(r(sd),.001),"%9.3f")
	
}

// qui: sum PESO
// local mean_PESO = string(round(r(mean),.1),"%9.1f")
// local sd_PESO = string(round(r(sd),.1),"%9.1f")
//
// qui: sum TALLA
// local mean_TALLA = string(round(r(mean),.01),"%9.2f")
// local sd_TALLA = string(round(r(sd),.01),"%9.2f")

count 
local n_obs = r(N)
local n_obs = string(r(N),"%42.0fc")


**Table**
file open stats using "$results/stat_table.tex", write replace
	file write stats "\begin{tabular}{lllll}" _n
	file write stats "\toprule" _n
	file write stats "&  & \multicolumn{1}{c}{Mean} &                      & \multicolumn{1}{c}{SD} \\" _n
	file write stats "\midrule" _n
	file write stats "\textbf{Outcomes}         &  &  &  &    \\" _n
	file write stats "BATTELLE (in \$ \sigma \$)      &  &        `mean_BATTELLE'        & &         `sd_BATTELLE'               \\" _n
	file write stats "TVIP (in \$ \sigma \$)      &  &        `mean_TVIP'        & &         `sd_TVIP'               \\" _n
// 	file write stats "CBCL (in \$ \sigma \$)      &  &        `mean_CBCL'        & &         `sd_CBCL'               \\" _n
	file write stats "Earnings (monthly 2024 USD)      &  &           `mean_wage_18'                & &        `sd_wage_18'                 \\" _n
	file write stats "Hours worked (weekly)      &  &           `mean_hours_w_18'                & &        `sd_hours_w_18'                 \\" _n
	file write stats "Employed      &  &            `mean_d_work_18'              & &         `sd_d_work_18'               \\" _n
	file write stats "    &  &                      & &              \\" _n
	
	
	file write stats "\textbf{Treatment}         &  &  & &    \\" _n
	file write stats "Enrollment at 3-4  &  &         `mean_public_34'                 & &       -                 \\" _n
	file write stats "    &  &                      & &              \\" _n
	
	file write stats "\textbf{Policy}         &  &  & &    \\" _n
	/*file write stats "0-2 proximity (kms) &  &                `mean_min_center_02'          & &         `sd_min_center_02'                \\" _n*/
	file write stats "3-4 proximity (kms) &  &                     `mean_min_center_NM'      & &         `sd_min_center_NM'               \\" _n
	file write stats "    &  &                      & &              \\" _n
	
	file write stats "\textbf{Covariates}         &  &  & &    \\" _n
	file write stats "Mother: age &  &             `mean_m_age'             & &         `sd_m_age'               \\" _n
// 	file write stats "Mother: less than high school &  &           `mean_dum_m_educ_1'               & &        -                \\" _n
// 	file write stats "Mother: high school &  &           `mean_dum_m_educ_2'               & &        -                \\" _n
// 	file write stats "Mother: college incomplete &  &           `mean_dum_m_educ_3'               & &       -                 \\" _n
	file write stats "Mother: college + & &                    `mean_dum_m_educ_4'      & &          -             \\" _n
	file write stats "Wechsler Adults Intelligence Scale (number retention) &  &     `mean_WAIS_t_num'                     & &         `sd_WAIS_t_num'               \\" _n
	file write stats "Wechsler Adults Intelligence Scale (vocabulary) &  &         `mean_WAIS_t_vo'                 & &         `sd_WAIS_t_num'               \\" _n
	file write stats "Father at home  &  &              `mean_f_home'            & &        -                \\" _n
	file write stats "Have younger siblings  &  &      `mean_dum_young_siblings'                    & &        -               \\" _n
// 	file write stats "Risky pregnancy  &  &         `mean_risk'                 & &             `sd_risk'           \\" _n
// 	file write stats "Weight at birth (g)&  &     `mean_PESO'                     & &         `sd_PESO'               \\" _n
// 	file write stats "Lenght at birth (cm) &  &         `mean_TALLA'                 & &         `sd_TALLA'               \\" _n
	file write stats "Risk: not all pregnancy controls  &  &              `mean_controles'            & &        -                \\" _n
	file write stats "Risk: smoked during pregnancy  &  &              `mean_dum_smoke'            & &        -                \\" _n
	file write stats "Risk: alcohol during pregnancy  &  &              `mean_dum_alc'            & &        -                \\" _n 
	file write stats " & & & & \\" _n		
	file write stats "\midrule" _n
	file write stats "N  &  &    `n_obs'      & &       \\" _n
	
	file write stats "\bottomrule" _n
	file write stats "\end{tabular}" _n
file close stats






