/*
This file computes FE estimates of proximity to mother's labor market outcomes

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
	
if "`c(username)'" == "ccorrea"{
	global des		"G:\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\ccorrea\OneDrive - Universidad de los Andes\Documentos\GitHub\Welfare-effects"
}

if "`c(username)'" == "Cecilia" {
	global des		"C:\Users\Cecilia\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
}


clear all
set more off
program drop _all
set seed 100

use "$db/data_estimate", clear

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home
// keep if cohort <= 2011



*----------------------*
*---------PREP---------*
*----------------------*



*Below/above median of HH income at baseline
qui: sum income_t0, d
scalar median_i = r(p50)
gen cat_income = .
replace cat_income = 1 if income_t0 <= median_i
replace cat_income = 2 if income_t0 > median_i & income_t0 != .



foreach depvar in "wage_18" "hours_w_18" "d_work_18"{
	
	qui: summarize `depvar'
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
	

	local nreg = 1
	
	*1. No controls
	 reg `depvar' min_center_NM, vce(robust)
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_NM],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_NM],.001),"%9.3f")
	local tstat = _b[min_center_NM] / _se[min_center_NM]
	local pval = 2*(1-normal(abs(`tstat')))
	*di `pval'
	if `pval' <= 0.01{
		local stars_`depvar'_`nreg' = "***"
		
	}
	else if `pval' <= 0.05{
		local stars_`depvar'_`nreg' = "**"
	}
	else if `pval' <= 0.1{
		local stars_`depvar'_`nreg' = "*"
	}
	else{
		local stars_`depvar'_`nreg' = " "
	}
	local nreg = `nreg' + 1
	
	*2. No Fes
	 reg `depvar' min_center_NM $controls, vce(robust)
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_NM],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_NM],.001),"%9.3f")
	local tstat = _b[min_center_NM] / _se[min_center_NM]
	local pval = 2*(1-normal(abs(`tstat')))
	*di `pval'
	if `pval' <= 0.01{
		local stars_`depvar'_`nreg' = "***"
		
	}
	else if `pval' <= 0.05{
		local stars_`depvar'_`nreg' = "**"
	}
	else if `pval' <= 0.1{
		local stars_`depvar'_`nreg' = "*"
	}
	else{
		local stars_`depvar'_`nreg' = " "
	}
	local nreg = `nreg' + 1
	
	*3. Time and groups FEs
	reghdfe `depvar' min_center_NM $controls, absorb(cohort comuna_cod) vce(robust)
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_NM],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_NM],.001),"%9.3f")
	local tstat = _b[min_center_NM] / _se[min_center_NM]
	local pval = 2*(1-normal(abs(`tstat')))
	*di `pval'
	if `pval' <= 0.01{
		local stars_`depvar'_`nreg' = "***"
		
	}
	else if `pval' <= 0.05{
		local stars_`depvar'_`nreg' = "**"
	}
	else if `pval' <= 0.1{
		local stars_`depvar'_`nreg' = "*"
	}
	else{
		local stars_`depvar'_`nreg' = " "
	}
	
	local nreg = `nreg' + 1
	
	*4. Full FEx
	 reghdfe `depvar' min_center_NM $controls, absorb(cohort#comuna_cod) vce(robust)
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_NM],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_NM],.001),"%9.3f")
	local tstat = _b[min_center_NM] / _se[min_center_NM]
	local pval = 2*(1-normal(abs(`tstat')))
	*di `pval'
	if `pval' <= 0.01{
		local stars_`depvar'_`nreg' = "***"
		
	}
	else if `pval' <= 0.05{
		local stars_`depvar'_`nreg' = "**"
	}
	else if `pval' <= 0.1{
		local stars_`depvar'_`nreg' = "*"
	}
	else{
		local stars_`depvar'_`nreg' = " "
	}
	
	
	
	local nreg = `nreg' + 1
	
	
	
}
stp
*Names for table
local x = 1
foreach names in "Monthly earnings" "Hours worked" "Work (=1)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}



*Table
file open itts using "$results/fe_estimates_lm.tex", write replace
	file write itts "\begin{tabular}{lccccccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  & \multirow{2}{*}{Baseline mean} &  & \multicolumn{4}{c}{Estimated effects}                               \\" _n
	file write itts "             &  &                                &  & (1)   & (2) & (3) &   (4)  \\" _n
	file write itts "\midrule" _n
	
	local x = 1
	foreach depvar in "wage_18" "hours_w_18" "d_work_18" {
		*Betas
		file write itts " `name_`x''    &  &         `mean_`depvar''       &  &  `beta_`depvar'_1'`stars_`depvar'_1'     &  `beta_`depvar'_2'`stars_`depvar'_2'    &  `beta_`depvar'_3'`stars_`depvar'_3'        &      `beta_`depvar'_4'`stars_`depvar'_4'     \\" _n
		
		*Standard errors
		file write itts "     &  &         			       &  &  (`se_beta_`depvar'_1')    &  (`se_beta_`depvar'_2')    &  (`se_beta_`depvar'_3')        &      (`se_beta_`depvar'_4')         \\" _n
		if `x' == 3{
			
		}
		else{
		file write itts " &  &                                &  &         &        &        &                         \\" _n
		}
		local x = `x' + 1
	}
	
	file write itts "\midrule" _n
	file write itts "    Control variables         &  &                                &  & No   & Yes & Yes &   Yes  \\" _n
	file write itts "  	 Cohort and Municipality FEs         &  &                   &  & No  & No & Yes & Yes  \\" _n
	file write itts "    Cohort\$\times\$ Municipality FEs         &  &                 &  & No   & No  & No  &   Yes  \\" _n
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts


stop

/*--------------------------------------------------------------------------------*/
/*----------------   Effects across income       ----------------------------------*/
/*--------------------------------------------------------------------------------*/


*Names for table
local x = 1
foreach names in "earnings (monthly US\$)" "hours worked" "employment (in %)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}

local xx = 1
foreach depvar in "wage_18" "hours_w_18" "d_work_18"{
	preserve


	forvalues x = 1/2{
		qui: reghdfe `depvar' min_center_34 $controls if cat_income == `x', absorb(cohort#comuna_cod) vce(robust)
		local beta_takeup_`x' = -_b[min_center_34]*100
		local ub_takeup_`x' = (-_b[min_center_34] + _se[min_center_34]*invnormal(0.975))*100
		local lb_takeup_`x' = (-_b[min_center_34] - _se[min_center_34]*invnormal(0.975))*100
			
	}
	
	
	clear
	set obs  3
	gen effects = .
	gen lb = .
	gen ub = .
	replace effects = `beta_takeup_1' if _n == 1
	replace lb = `lb_takeup_1' if _n == 1
	replace ub = `ub_takeup_1' if _n == 1

	replace effects = `beta_takeup_2' if _n == 3
	replace lb = `lb_takeup_2' if _n == 3
	replace ub = `ub_takeup_2' if _n == 3

	egen x = seq()

	twoway (bar effects x, barwidth(1.2) color(black*.7) fintensity(.5)  lwidth(0.4) ) ///
	(scatter effects x, msymbol(circle) mcolor(black*.7) mfcolor(black*.7)) ///
		(rcap ub lb x, lpattern(solid) lcolor(black*.7) ), ///
		ytitle("Effect on `name_`xx''")  xtitle("") legend(off) ///
		xlabel(1 "Low-income" 3 "High-income", noticks) ///
		ylabel(, nogrid)  ///
		graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
		plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
		scheme(s2mono) scale(1.7) yline(0, lpattern(dash) lcolor(black))
		*text(1.7 1.6  "Overall effect = `beta_takeup' pp (S.E. = `se_beta_takeup')", place(e) color(blue*.8) size(medsmall)) ///
		

	graph export "$results/`depvar'_low_high.pdf", as(pdf) replace
	
	local xx = `xx' + 1
	
	restore


}
