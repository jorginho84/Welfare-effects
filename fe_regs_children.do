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

clear all
set more off
program drop _all
set seed 100

use "$db/data_estimate", clear

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home
keep if cohort <= 2010


*----------------------*
*---------PREP---------*
*----------------------*


use "$db/data_estimate", clear

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home
keep if cohort <= 2011


*BATELLE
forval d = 0/11 {
	gen batelle_age`d'_t = BATTELLE_t_2010 if birth_year == 2010 - `d'
	replace batelle_age`d'_t = BATTELLE_t_2012 if birth_year == 2012 - `d' & batelle_age`d'_t == .
	replace batelle_age`d'_t = BATTELLE_t_2017  if birth_year == 2017 - `d' & batelle_age`d'_t == .
}
	
*TVIP
forval d = 0/11 {
	gen tvip_age`d'_t = TVIP_t_2010 if birth_year == 2010 - `d'
	replace tvip_age`d'_t = TVIP_t_2012 if birth_year == 2012 - `d' & tvip_age`d'_t == .
	replace tvip_age`d'_t = TVIP_t_2017  if birth_year == 2017 - `d' & tvip_age`d'_t == .
}

*CBCL
forval d = 0/11 {
	gen cbcl1_age`d'_t = CBCL1_t_2010 if birth_year == 2010 - `d'
	replace cbcl1_age`d'_t = CBCL1_t_2012 if birth_year == 2012 - `d' & cbcl1_age`d'_t == .
	replace cbcl1_age`d'_t = CBCL1_t_2017  if birth_year == 2017 - `d' & cbcl1_age`d'_t == .
}

*CBCL2
forval d = 0/11 {
	gen cbcl2_age`d'_t = CBCL2_t_2012 if birth_year == 2012 - `d'
	replace cbcl2_age`d'_t = CBCL2_t_2017  if birth_year == 2017 - `d' & cbcl2_age`d'_t == .
}

*Battelle lo normalizo!!
forval d = 0/11{
	qui: sum batelle_age`d'_t
	gen batelle_age`d'_z = (batelle_age`d'_t - r(mean))/r(sd)
}

gen batelle = .
gen tvip = .
gen cbcl = .

forval d = 11(-1)0{
	replace batelle = batelle_age`d'_z if batelle == .
	replace tvip = tvip_age`d'_t if tvip == .
	replace cbcl = cbcl1_age`d'_t if cbcl == .
	replace cbcl = cbcl2_age`d'_t if cbcl == .
}


*----------------------*
*---------PREP---------*
*----------------------*


*Below/above median of HH income at baseline
gen cat_income = .
replace cat_income = 1 if percentile_income_h <= 50
replace cat_income = 2 if percentile_income_h > 50 & percentile_income_h != .



foreach depvar in "batelle" "tvip" "cbcl"{
	
	qui: summarize `depvar'
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
	local nreg = 1
	
	*1. No controls
	qui: reg `depvar' min_center_34, vce(robust)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_34],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_34],.001),"%9.3f")
	local tstat = _b[min_center_34] / _se[min_center_34]
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
	qui: reg `depvar' min_center_34 $controls, vce(robust)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_34],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_34],.001),"%9.3f")
	local tstat = _b[min_center_34] / _se[min_center_34]
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
	qui: reghdfe `depvar' min_center_34 $controls, absorb(cohort comuna_cod) vce(robust)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_34],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_34],.001),"%9.3f")
	local tstat = _b[min_center_34] / _se[min_center_34]
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
	qui: reghdfe `depvar' min_center_34 $controls, absorb(cohort#comuna_cod) vce(robust)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_34],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_34],.001),"%9.3f")
	local tstat = _b[min_center_34] / _se[min_center_34]
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

*Names for table
local x = 1
foreach names in "Batelle" "TVIP" "CBCL" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}



*Table
file open itts using "$results/fe_estimates_children.tex", write replace
	file write itts "\begin{tabular}{lccccccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  & \multirow{2}{*}{Baseline mean} &  & \multicolumn{4}{c}{Estimated effects}                               \\" _n
	file write itts "             &  &                                &  & (1)   & (2) & (3) &   (4)  \\" _n
	file write itts "\midrule" _n
	
	local x = 1
	foreach depvar in "batelle" "tvip" "cbcl" {
		*Betas
		file write itts " `name_`x''    &  &         `mean_`depvar''       &  &  `beta_`depvar'_1'`stars_`depvar'_1'     &  `beta_`depvar'_2'`stars_`depvar'_2'    &  `beta_`depvar'_3'`stars_`depvar'_3'        &      `beta_`depvar'_4'`stars_`depvar'_4'     \\" _n
		
		*Standard errors
		file write itts "     &  &         			       &  &  (`se_beta_`depvar'_1')    &  (`se_beta_`depvar'_2')    &  (`se_beta_`depvar'_3')        &      (`se_beta_`depvar'_4')         \\" _n
		if `x' == 3{
			
		}
		else{
		file write itts " &  &                                &  &         &        &        &              &             \\" _n
		}
		local x = `x' + 1
	}
	
	file write itts "\midrule" _n
	file write itts "    Control variables         &  &                                &  & No   & Yes & Yes &   Yes  \\" _n
	file write itts "  	 Cohort and Municipality FEs         &  &                   &  & No  & No & Yes & Yes  \\" _n
	file write itts "    Cohort\$\times\$ Municipality FEs         &  &                 &  & No   & No  & No  &   Yes  \\" _n
	
	file write itts "\midrule" _n
	file write itts "    N         &  &                                &  & `n_batelle_1'   & `n_batelle_2' & `n_batelle_3' &   `n_batelle_4'  \\"
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts


**#  by edad

foreach `y' in 0 6 {
	
gen batelle`y' = .
gen tvip`y' = .
gen cbcl`y' = .

forval d = `y'+6(-1)`y'{
	replace batelle0 = batelle_age`d'_z if batelle0 == .
	replace tvip0 = tvip_age`d'_t if tvip0 == .
	replace cbcl0 = cbcl1_age`d'_t if cbcl0 == .
	replace cbcl0 = cbcl2_age`d'_t if cbcl0 == .
}
}

foreach depvar in "batelle0" "tvip0" "cbcl0"{
	
	qui: summarize `depvar'
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
	local nreg = 1
	
	*1. No controls
	qui: reg `depvar' min_center_34, vce(robust)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_34],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_34],.001),"%9.3f")
	local tstat = _b[min_center_34] / _se[min_center_34]
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
	qui: reg `depvar' min_center_34 $controls, vce(robust)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_34],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_34],.001),"%9.3f")
	local tstat = _b[min_center_34] / _se[min_center_34]
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
	qui: reghdfe `depvar' min_center_34 $controls, absorb(cohort comuna_cod) vce(robust)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_34],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_34],.001),"%9.3f")
	local tstat = _b[min_center_34] / _se[min_center_34]
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
	qui: reghdfe `depvar' min_center_34 $controls, absorb(cohort#comuna_cod) vce(robust)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
	local beta_`depvar'_`nreg' = string(round(-_b[min_center_34],.001),"%9.3f")
	local se_beta_`depvar'_`nreg' = string(round(_se[min_center_34],.001),"%9.3f")
	local tstat = _b[min_center_34] / _se[min_center_34]
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

*Names for table
local x = 1
foreach names in "Batelle" "TVIP" "CBCL" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}



*Table
file open itts using "$results/fe_estimates_children_`young'.tex", write replace
	file write itts "\begin{tabular}{lccccccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  & \multirow{2}{*}{Baseline mean} &  & \multicolumn{4}{c}{Estimated effects}                               \\" _n
	file write itts "             &  &                                &  & (1)   & (2) & (3) &   (4)  \\" _n
	file write itts "\midrule" _n
	
	local x = 1
	foreach depvar in "batelle0" "tvip0" "cbcl0" {
		*Betas
		file write itts " `name_`x''    &  &         `mean_`depvar''       &  &  `beta_`depvar'_1'`stars_`depvar'_1'     &  `beta_`depvar'_2'`stars_`depvar'_2'    &  `beta_`depvar'_3'`stars_`depvar'_3'        &      `beta_`depvar'_4'`stars_`depvar'_4'     \\" _n
		
		*Standard errors
		file write itts "     &  &         			       &  &  (`se_beta_`depvar'_1')    &  (`se_beta_`depvar'_2')    &  (`se_beta_`depvar'_3')        &      (`se_beta_`depvar'_4')         \\" _n
		if `x' == 3{
			
		}
		else{
		file write itts " &  &                                &  &         &        &        &              &             \\" _n
		}
		local x = `x' + 1
	}
	
	file write itts "\midrule" _n
	file write itts "    Control variables         &  &                                &  & No   & Yes & Yes &   Yes  \\" _n
	file write itts "  	 Cohort and Municipality FEs         &  &                   &  & No  & No & Yes & Yes  \\" _n
	file write itts "    Cohort\$\times\$ Municipality FEs         &  &                 &  & No   & No  & No  &   Yes  \\" _n
	
	file write itts "\midrule" _n
	file write itts "    N         &  &                                &  & `n_batelle0_1'   & `n_batelle0_2' & `n_batelle0_3' &   `n_batelle0_4'  \\"
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts

}