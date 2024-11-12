/*
Estimation of WAOSS, for continuous treatments assuming quasi-stayers
*/

local user Jorge

if "`user'" == "andres"{
	cd 				"/Users/andres/Dropbox/jardines_elpi"
	global db 		"/Users/andres/Dropbox/jardines_elpi/data"
	global codes 	"/Users/andres/Dropbox/jardines_elpi/codes"
}
 
else if "`user'" == "Jorge-server"{
 
  global db "/home/jrodriguez/childcare/data"
  global codes "/home/jrodriguez/childcare/codes"
  global km "/home/jrodriguez/childcare/data"
  global results "/home/jrodriguez/childcare/results"          
}

else if "`user'" == "Jorge"{
 
  global db "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Data"
  global results "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Results"          
}

else if "`user'"=="Antonia"{
	global des "/Volumes/AKAC20/CC/CC_Jardines/Datos-Jardines"
	cd "$des"
	global db "$des/Data"
	global results "$des/resultados-anto/public_34/mprte"
	}

	if "`c(username)'" == "Cecilia" {
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

clear all
set more off
program drop _all
set seed 100

use "$db/data_estimate", clear

*dummy vars on educ
qui: tabulate m_educ, gen(m_educ)

global controls m_educ2 m_educ3 m_educ4 WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home

keep if cohort <= 2010
drop if min_center_NM == . | public_34 == .


*----------------------------------------------------------*
*---------PREP---------------------------------------------*
*----------------------------------------------------------*
//
// foreach var in wage hours_w d_work{
// 	egen `var'_18=rowmean( `var'_t7 `var'_t8)
// 	*gen `var'_18 = `var'_t7
// }
//
egen TVIP = rowmean(TVIP_age_2 TVIP_age_3)


*Below/above median of HH income at baseline
gen cat_income = .
replace cat_income = 1 if percentile_income_h <= 50
replace cat_income = 2 if percentile_income_h > 50 & percentile_income_h != .

foreach vars in "TVIP" "wage_18" "hours_w_18" "d_work_18" "min_center_34" "public_34" "cat_income"{
	drop if `vars' == .
}

gen one_1 = 1
collapse (mean) TVIP wage_18 hours_w_18 d_work_18 min_center_NM public_34 $controls cat_income (count) weight_n = min_center_NM, by (cohort comuna_cod)

xtset comuna_cod cohort
gen d_min = min_center_NM - L1.min_center_NM
sum d_min
count if d_min == 0


/*---------------------------------------------------------*/
/*----------------Distribution of shifts-------------------*/
/*---------------------------------------------------------*/

/*

twoway (histogram d_min if d_min >= -4 & d_min <= 4, fcolor(none)  color(blue*.7) fintensity(.5) lwidth(0.4) width(0.2) ), ///
ytitle("Density")  xtitle("Proximity changes (kms)") legend(off) ///
xlabel(, noticks) ///
ylabel(, nogrid)  ///
graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
scheme(s2mono) scale(1.2)

graph export "$results/density_delta_proximity.pdf", as(pdf) replace

*/

quietly do "/Users/jorge-home/Library/CloudStorage/Dropbox/Research/DN-early/Dynamic_childcare/Codes/dCH WAOSS estimation/did_continuous_nostayers.ado"


foreach depvar in "public_34" "wage_18" "hours_w_18" "d_work_18" "TVIP"{
	
	qui: summarize `depvar'
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
	*Low income
	did_continuous_nostayers `depvar' comuna_cod cohort min_center_34 if cat_income <= .5, weight(weight_n)
	local beta_`depvar'_1 = string(round(-e(theta_XX),.001),"%9.3f")
	local se_`depvar'_1 = string(round(e(sd_theta_XX),.001),"%9.3f")
	
	local tstat = e(theta_XX) / e(sd_theta_XX)
	local pval = 2*(1-normal(abs(`tstat')))
	*di `pval'
	if `pval' <= 0.01{
		local stars_`depvar'_1 = "***"
		
	}
	else if `pval' <= 0.05{
		local stars_`depvar'_1 = "**"
	}
	else if `pval' <= 0.1{
		local stars_`depvar'_1 = "*"
	}
	else{
		local stars_`depvar'_1 = " "
	}
	
	*High income
	did_continuous_nostayers `depvar' comuna_cod cohort min_center_34 if cat_income> .5, weight(weight_n)
	local beta_`depvar'_2 = string(round(-e(theta_XX),.001),"%9.3f")
	local se_`depvar'_2 = string(round(e(sd_theta_XX),.001),"%9.3f")
	
	local tstat = e(theta_XX) / e(sd_theta_XX)
	local pval = 2*(1-normal(abs(`tstat')))
	*di `pval'
	if `pval' <= 0.01{
		local stars_`depvar'_2 = "***"
		
	}
	else if `pval' <= 0.05{
		local stars_`depvar'_2 = "**"
	}
	else if `pval' <= 0.1{
		local stars_`depvar'_2 = "*"
	}
	else{
		local stars_`depvar'_2 = " "
	}

}



*Table
*Names for table
local x = 1
foreach names in "Monthly earnings" "Hours worked" "Work (=1)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}


file open itts using "$results/did_multiple.tex", write replace
	file write itts "\begin{tabular}{lcccccc}" _n
	file write itts "\toprule" _n
	file write itts "       &  & \multirow{2}{*}{Baseline mean} &  & \multicolumn{3}{c}{Estimated effects}    \\" _n
	file write itts "             &  & 	 &  & Low-income && High-income                               \\" _n
		file write itts "\midrule" _n
	file write itts "             &  &  &  &  &&                              \\" _n
	file write itts "  \multicolumn{7}{l}{\textbf{Panel A. Take-up}}                               \\" _n
	file write itts "             &  &  &  &  &&                              \\" _n
	file write itts "  Child care enrollment (=1)  &  &  `mean_public_34'   &  &`beta_public_34_1'`stars_public_34_1' &  &`beta_public_34_2'`stars_public_34_2'    \\" _n
	file write itts "           &  &     &  & 						(`se_public_34_1')   &  & 						(`se_public_34_2')                     \\" _n
	
	file write itts "             &  &  &  &  &&                              \\" _n
	file write itts "  \multicolumn{7}{l}{\textbf{Panel B. Mother's labor market outcomes}}                               \\" _n
	file write itts "             &  &  &  &  &&                              \\" _n
	local x = 1
	foreach depvar in "wage_18" "hours_w_18" "d_work_18" {

		file write itts " `name_`x''    &  &         `mean_`depvar''       &  &  `beta_`depvar'_1'`stars_`depvar'_1'  &  &  `beta_`depvar'_2'`stars_`depvar'_2'  \\" _n
		file write itts " 			    &  &        					    &  &  (`se_`depvar'_1')  &  &  (`se_`depvar'_2')    \\" _n
		local x = `x' + 1
	
		
	}
	file write itts "             &  &  &  &  &&                              \\" _n
	file write itts "  \multicolumn{7}{l}{\textbf{Panel C. Child outcomes}}                               \\" _n
	file write itts "             &  &  &  &  &&                              \\" _n
	file write itts "  Cognitive score (in \$ \sigma \$)  &  &  `mean_TVIP'   &  &`beta_TVIP_1'`stars_TVIP_1' &  &`beta_TVIP_2'`stars_TVIP_2'     \\" _n
	file write itts "           &  &     &  & 						(`se_TVIP_1')     &  & 						(`se_TVIP_2')                      \\" _n
	
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts

