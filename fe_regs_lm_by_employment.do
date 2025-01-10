**** This dofile generates table of heterogeneous effects on mothers' labor market outcomes, by employment at baseline

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

clear all
set more off
program drop _all
set seed 100

use "$db/data_estimate", clear

// global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home
global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings f_home PESO TALLA controles dum_smoke dum_alc

*----------------------*
*---------PREP---------*
*----------------------*


// recode elegible_t02 (0 = 2) , gen(cat_income)
recode d_work_t02 (0 = 1) (1 = 2) , gen(cat_income) //Low income = did not work 2 years before birth. 


**# Tabla que une cat_income 1 y 2

forval c = 1/2{

foreach depvar in "wage_18" "hours_w_18" "d_work_18"{
	
	qui: summarize `depvar' if cat_income == `c'
	local mean_`depvar'_`c' = string(round(r(mean),.001),"%9.3f")
	
	*4. Full FEx
	 reghdfe `depvar' min_center_NM $controls if cat_income == `c', absorb(cohort#comuna_cod) vce(cluster comuna_cod)
	local n_`depvar'_`c' = string(e(N),"%42.0fc")
	local beta_`depvar'_`c' = string(round(-_b[min_center_NM],.001),"%9.3f")
	local se_beta_`depvar'_`c' = string(round(_se[min_center_NM],.001),"%9.3f")
	local tstat = _b[min_center_NM] / _se[min_center_NM]

	local pval = 2*(1-normal(abs(`tstat')))
	*di `pval'
	if `pval' <= 0.01{
		local stars_`depvar'_`c' = "***"
		
	}
	else if `pval' <= 0.05{
		local stars_`depvar'_`c' = "**"
	}
	else if `pval' <= 0.1{
		local stars_`depvar'_`c' = "*"
	}
	else{
		local stars_`depvar'_`c' = " "
	}
	

	
}

}

*Names for table
local x = 1
foreach names in "Monthly earnings" "Hours worked" "Work (=1)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}



*Table: main text

file open itts using "$results/fe_estimates_lm_bycatincome.tex", write replace
	file write itts "\begin{tabular}{lcccccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  &\multicolumn{2}{c}{Unemployed at baseline}  &  & \multicolumn{2}{c}{Employed at baseline}                             \\" _n
	file write itts "    \cmidrule{2-4}    \cmidrule{6-7}   " _n
	file write itts "             &  & Baseline mean &  Estimated effect &  & Baseline mean &  Estimated effect                               \\" _n
	file write itts "\midrule" _n
	
	local x = 1
	foreach depvar in "wage_18" "hours_w_18" "d_work_18" {
		*Betas
		file write itts " `name_`x''    &  &   `mean_`depvar'_1'  &   `beta_`depvar'_1'`stars_`depvar'_1' &  &   `mean_`depvar'_2' &   `beta_`depvar'_2'`stars_`depvar'_2'       \\" _n
		
		*Standard errors
		file write itts "     &  &         			       &   (`se_beta_`depvar'_1') &  &         			       &   (`se_beta_`depvar'_2')     \\" _n
		if `x' == 3{
			
		}
		else{
		file write itts " &  &                                &  &     &&    \\" _n
		}
		local x = `x' + 1
	}
	
		
	file write itts "\midrule" _n
	file write itts "    N  obs.       &  &    \multicolumn{2}{c}{`n_wage_18_1'  }  & &  \multicolumn{2}{c}{`n_wage_18_2'  } \\" _n
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts















