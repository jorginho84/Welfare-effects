/*
This file computes Fixed Effects (FE) estimates of proximity on mother's labor market outcomes, children's test scores,
and take-up of public centers. The main variable of interest is the distance to the nearest center (min_center_NM). 
These models control for the supply of centers near the household.
*/

// Define the user
local user Jorge-server

// Set paths based on the user
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

// Set paths for Cecilia based on the system username
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

// Define control variables
global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home



// Preparing variables

drop battelle tvip
egen battelle = rowmean(battelle_age3_z battelle_age4_z battelle_age5_z)
egen tvip = rowmean(tvip_age3_z tvip_age4_z tvip_age5_z)



// Main loop of estimates
foreach depvar in "public_34" "wage_18" "hours_w_18" "d_work_18" "battelle" "tvip"{
	
	qui: summarize `depvar'
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
	local nreg = 1
	
	
	
	*Full FEx
	reghdfe `depvar' min_center_NM N_centers1000_NM $controls, absorb(cohort#comuna_cod) vce(cluster comuna_cod)
	local n_`depvar' = string(e(N),"%42.0fc")
	local beta_`depvar' = string(round(-_b[min_center_NM],.001),"%9.3f")
	local se_beta_`depvar' = string(round(_se[min_center_NM],.001),"%9.3f")
	local tstat = _b[min_center_NM] / _se[min_center_NM]

	local pval = 2*(1-normal(abs(`tstat')))
	*di `pval'
	if `pval' <= 0.01{
		local stars_`depvar' = "***"
		
	}
	else if `pval' <= 0.05{
		local stars_`depvar' = "**"
	}
	else if `pval' <= 0.1{
		local stars_`depvar' = "*"
	}
	else{
		local stars_`depvar' = " "
	}
	
	
	
	local nreg = `nreg' + 1
	
	
	
}

// Names for tables
local x = 1
foreach names in "Monthly earnings" "Hours worked" "Work" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}




// Write results to a tex file

file open itts using "$results/fe_estimates_Ncenters.tex", write replace
	file write itts "\begin{tabular}{lcccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  & Baseline mean &  & Estimated effect                               \\" _n
	file write itts "\midrule" _n
	file write itts " &  &                                &  &         \\" _n
	file write itts " \multicolumn{2}{l}{\textbf{A. Take-up} }  &                                &  &         \\" _n
	file write itts " &  &                                &  &         \\" _n
    file write itts " Child care enrollment (\$N = `n_public_34' \$)    &  &         `mean_public_34'       &  &  `beta_public_34'`stars_public_34'       \\" _n
    file write itts "     &  &         			       &  &  (`se_beta_public_34')      \\" _n
    file write itts " &  &                                &  &         \\" _n
	
	local x = 1
	file write itts " \multicolumn{2}{l}{\textbf{B. Labor market} }  &                                &  &         \\" _n
	file write itts " &  &                                &  &         \\" _n
	foreach depvar in "wage_18" "hours_w_18" "d_work_18" {
		
		*Betas
		file write itts " `name_`x'' (\$N = `n_`depvar'' \$)    &  &         `mean_`depvar''       &  &  `beta_`depvar''`stars_`depvar''       \\" _n
		
		*Standard errors
		file write itts "     &  &         			       &  &  (`se_beta_`depvar'')      \\" _n
		file write itts " &  &                                &  &         \\" _n
		local x = `x' + 1
	}

	file write itts " \multicolumn{2}{l}{\textbf{C. Test scores} }  &                                &  &         \\" _n
	file write itts " &  &                                &  &         \\" _n
	file write itts " Batelle (\$N = `n_battelle' \$)    &  &         `mean_batelle'       &  &  `beta_battelle'`stars_battelle'       \\" _n
	file write itts "     &  &         			       &  &  (`se_beta_battelle')      \\" _n
	file write itts " &  &                                &  &         \\" _n
	file write itts " TVIP (\$N = `n_tvip' \$)    &  &         `mean_tvip'       &  &  `beta_tvip'`stars_tvip'       \\" _n
	file write itts "     &  &         			       &  &  (`se_beta_tvip')      \\" _n
	
	       
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts

