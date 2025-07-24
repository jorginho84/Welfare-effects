/*
This file computes FE estimates of proximity to mother's labor market outcomes

*/


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


clear all
set more off
program drop _all
set seed 100

use "$db/data_estimate", clear

global controls m_age m_college WAIS_t_num WAIS_t_vo f_home dum_young_siblings controles dum_smoke dum_alc



// Main loop of estimates

foreach depvar in "wage_18" "hours_w_18" "d_work_18"{
	
	qui: summarize `depvar'
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
		local nreg = 1
	
	*1. No controls
	 reg `depvar' min_center_NM, vce(cluster comuna_cod)
	 local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
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
	 reg `depvar' min_center_NM $controls, vce(cluster comuna_cod)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
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
	reghdfe `depvar' min_center_NM $controls, absorb(cohort comuna_cod) vce(cluster comuna_cod)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
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
	reghdfe `depvar' min_center_NM $controls, absorb(cohort#comuna_cod) vce(cluster comuna_cod)
	local n_`depvar'_`nreg' = string(e(N),"%42.0fc")
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

*Names for table
local x = 1
foreach names in "Monthly earnings (2024 USD)" "Hours worked" "Work (=1)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}



*Table: main text

file open itts using "$results/fe_estimates_lm.tex", write replace
	file write itts "\begin{tabular}{lcccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  & Baseline mean &  & Estimated effect                               \\" _n
	file write itts "\midrule" _n
	
	local x = 1
	foreach depvar in "wage_18" "hours_w_18" "d_work_18" {
		*Betas
		file write itts " `name_`x''    &  &         `mean_`depvar''       &  &  `beta_`depvar'_4'`stars_`depvar'_4'       \\" _n
		
		*Standard errors
		file write itts "     &  &         			       &  &  (`se_beta_`depvar'_4')      \\" _n
		if `x' == 3{
			
		}
		else{
		file write itts " &  &                                &  &         \\" _n
		}
		local x = `x' + 1
	}
	
		
	file write itts "\midrule" _n
	file write itts "    N  obs.       &  &                        \multicolumn{3}{c}{`n_wage_18_1'  }    \\" _n
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts


*Table: appendix
file open itts using "$results/fe_estimates_lm_appendix.tex", write replace
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
	
	file write itts "\midrule" _n
	file write itts "    N         &  &                                &  & `n_wage_18_1'   & `n_wage_18_2' & `n_wage_18_3' &   `n_wage_18_4'  \\"
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts








*Table: appendix
file open itts using "$results/fe_estimates_lm_appendix.tex", write replace
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
	
	file write itts "\midrule" _n
	file write itts "    N         &  &                                &  & `n_wage_18_1'   & `n_wage_18_2' & `n_wage_18_3' &   `n_wage_18_4'  \\"
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts





