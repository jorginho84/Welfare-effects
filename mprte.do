/*
This do-file computes MPRTEs

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

clear all
set more off
program drop _all
set seed 100

use "$db/data_estimate", clear

global controls m_age m_college WAIS_t_num WAIS_t_vo f_home dum_young_siblings controles dum_smoke dum_alc

// Obtain cognitive factor

factor tvip3 battelle3, factors(1)
rotate, quartimin
predict cog_factor_aux
egen cog_factor = std(cog_factor_aux)

// Main loop of estimates
foreach depvar in "wage_18" "hours_w_18" "d_work_18" "cog_factor"{
	qui: mtefe `depvar' $controls i.comuna_cod i.cohort  (public_34 = min_center_NM),  pol(2) trimsupport(0.01) first noplot
	mat M=e(b)
	mat V=e(V)

	local mcol = colnumb(M,"mprte1")
	local vcol = colnumb(V,"mprte1")
	local vrow = rownumb(V,"effects:mprte1")
	
	local mprte_`depvar'    = M[1,`mcol']
	local mprte_se_`depvar' = sqrt(V[`vrow',`vcol'])
	local pval_`depvar'     = (2 * (1 - normal(abs(`mprte_`depvar''/ `mprte_se_`depvar''))))
	*-------------------------------FORMAT VALUES-------------------------------*
	if abs(`mprte_`depvar''   )>10 local mprte_`depvar'    = string(round(`mprte_`depvar''   ,.001),"%9.2f")
	if abs(`mprte_`depvar''   )<10 local mprte_`depvar'    = string(round(`mprte_`depvar''   ,.001),"%9.3f")
	if abs(`mprte_se_`depvar'')>10 local mprte_se_`depvar' = string(round(`mprte_se_`depvar'',.001),"%9.2f")
	if abs(`mprte_se_`depvar'')<10 local mprte_se_`depvar' = string(round(`mprte_se_`depvar'',.001),"%9.3f")
	
	local ast_`depvar'= ""
	if `pval_`depvar'' <= 0.1 &  `pval_`depvar'' > 0.05{
	local ast_`depvar' = "*"
		}
	else if `pval_`depvar'' <= 0.05 & `pval_`depvar'' > 0.01{
	local ast_`depvar' = "**"
		}
	else if `pval_`depvar'' <= 0.01 {
	local ast_`depvar' = "***"
		}
	
	*First stage analysis
	qui: reg public_34 min_center_NM $controls i.cohort i.comuna_cod if e(sample)
	local fs_`depvar' = string(round((-1)* _b[min_center_NM] ,.01),"%9.3f")
	qui: ivreg2 `depvar' (public_34=min_center_NM) $controls i.cohort i.comuna_cod if e(sample), robust
	qui: weakivtest
	local f_stat_`depvar' =  string(round(r(F_eff),.01),"%9.2f")
}


local x = 1
foreach names in "Monthly earnings" "Hours worked" "Work (=1)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}



file open itts using "$results/mprte_estimates.tex", write replace
	file write itts "\begin{tabular}{lcccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  & First stage &  & MPRTE                              \\" _n
	file write itts "\midrule" _n
	file write itts "             &  &                                &  &  \\" _n
	file write itts " \textbf{A. Labor market}           &  &    &  &                             \\" _n
	
	local x = 1
	foreach depvar in "wage_18" "hours_w_18" "d_work_18" {
		*Betas
		file write itts " `name_`x''    &  &         `fs_`depvar''       &  &  `mprte_`depvar''`ast_`depvar''     \\" _n
		
		*Standard errors - F test
		file write itts "     &  &        [`f_stat_`depvar''] 			       &  &  (`mprte_se_`depvar'')   \\" _n
				
		file write itts " &  &                                &  &         &        &        &              &             \\" _n
		
		local x = `x' + 1
	}
	file write itts " \textbf{B. Child outcomes}           &  &    &  &                             \\" _n
		*Betas
		file write itts " Cognitive score (\$ \sigma \$)    &  &         `fs_cog_factor'       &  &  `mprte_cog_factor'`ast_cog_factor' \\" _n
		
		*Standard errors - F test
		file write itts "     &  &        [`f_stat_cog_factor'] 			       &  &  (`mprte_se_cog_factor')   \\" _n
	
	        
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts


