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

*----------------------*
*---------PREP---------*
*----------------------*


use "$db/data_estimate", clear

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home


*Below/above median of HH income at baseline
gen cat_income = .
replace cat_income = 1 if percentile_income_h <= 50
replace cat_income = 2 if percentile_income_h > 50 & percentile_income_h != .

**# All ages **


foreach depvar in "battelle" "tvip" "cbcl"{
	
	preserve //Nos quedamos con el N más chico de todas las regresiones (reg 4, de cada test)
	qui: reghdfe `depvar' min_center_NM $controls, absorb(cohort#comuna_cod) vce(robust)
	keep if e(sample) == 1
	
	qui: summarize `depvar'
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
	local nreg = 1
	
	*1. No controls
	qui: reg `depvar' min_center_NM, vce(robust)
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
	qui: reg `depvar' min_center_NM $controls, vce(robust)
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
	qui: reghdfe `depvar' min_center_NM $controls, absorb(cohort comuna_cod) vce(robust)
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
	qui: reghdfe `depvar' min_center_NM $controls, absorb(cohort#comuna_cod) vce(robust)
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
	
	restore
	
	local nreg = `nreg' + 1
	
	
	
}

*Names for table
local x = 1
foreach names in "Battelle" "TVIP" "CBCL" {
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
	foreach depvar in "battelle" "tvip" "cbcl" {
		*Betas
		file write itts " `name_`x'' (N = `n_`depvar'_4')    &  &         `mean_`depvar''       &  &  `beta_`depvar'_1'`stars_`depvar'_1'     &  `beta_`depvar'_2'`stars_`depvar'_2'    &  `beta_`depvar'_3'`stars_`depvar'_3'        &      `beta_`depvar'_4'`stars_`depvar'_4'     \\" _n
		
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
	
	*file write itts "\midrule" _n
	*file write itts "    N         &  &                                &  & `n_battelle_1'   & `n_battelle_2' & `n_battelle_3' &   `n_battelle_4'  \\"
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts






**Effects by age (figures)


*En caso de que niño/a tenga dos valores en tescore, se promedian.
*test3 == edad 3 a 5. test6 == edades 6 +
egen battelle3 = rowmean(battelle_age3_z battelle_age4_z battelle_age5_z)
egen tvip3 = rowmean(tvip_age3_z tvip_age4_z tvip_age5_z)
egen cbcl3 = rowmean(cbcl*_age3_z cbcl*_age4_z cbcl*_age5_z)

egen battelle6 = rowmean(battelle_age6_z battelle_age7_z battelle_age8_z battelle_age9_z battelle_age10_z battelle_age11_z)
egen tvip6 = rowmean(tvip_age6_z tvip_age7_z tvip_age8_z tvip_age9_z tvip_age10_z tvip_age11_z)
egen cbcl6 = rowmean(cbcl*_age6_z cbcl*_age7_z cbcl*_age8_z cbcl*_age9_z cbcl*_age10_z cbcl*_age11_z)

qui: reghdfe `depvar' min_center_NM $controls, absorb(cohort#comuna_cod) vce(robust)


foreach depvar in "battelle" "tvip" "cbcl"{

	preserve
	foreach age of numlist 3 6 {
		reghdfe `depvar'`age' min_center_NM $controls , absorb(cohort#comuna_cod) vce(robust)
		local beta_takeup_`age' = -_b[min_center_NM]
		local ub_takeup_`age' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))
		local lb_takeup_`age' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))
			
	}

	clear
	set obs  3
	gen effects = .
	gen lb = .
	gen ub = .
	replace effects = `beta_takeup_3' if _n == 1
	replace lb = `lb_takeup_3' if _n == 1
	replace ub = `ub_takeup_3' if _n == 1

	replace effects = `beta_takeup_6' if _n == 3
	replace lb = `lb_takeup_6' if _n == 3
	replace ub = `ub_takeup_6' if _n == 3

	egen x = seq()

	twoway (bar effects x, barwidth(1.2) color(black*.7) fintensity(.5)  lwidth(0.4) ) ///
	(scatter effects x, msymbol(circle) mcolor(black*.7) mfcolor(black*.7)) ///
		(rcap ub lb x, lpattern(solid) lcolor(black*.7) ), ///
		ytitle("Effect on `name_`xx''")  xtitle("") legend(off) ///
		xlabel(1 "Ages 3-5" 3 "Ages 6-11", noticks) ///
		ylabel(, nogrid)  ///
		graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
		plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
		scheme(s2mono) scale(1.7) yline(0, lpattern(dash) lcolor(black))
		*text(1.7 1.6  "Overall effect = `beta_takeup' pp (S.E. = `se_beta_takeup')", place(e) color(blue*.8) size(medsmall)) ///
		

	graph export "$results/fe_estimates_`depvar'_short-longterm.pdf", as(pdf) replace

	restore
}




stop!!



**# Efecto testscores por género
*Names for table
local x = 1
foreach names in "Battelle" "TVIP" "CBCL" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}

local xx = 1
foreach depvar in "battelle" "tvip" "cbcl"{
	preserve


	forvalues x = 1/2{
		reghdfe `depvar' min_center_NM $controls if gender == `x', absorb(cohort#comuna_cod) vce(robust)
		local beta_takeup_`x' = -_b[min_center_NM] //Por qué se multiplica por 100??
		local ub_takeup_`x' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))
		local lb_takeup_`x' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))
			
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
		xlabel(1 "Male" 3 "Female", noticks) ///
		ylabel(, nogrid)  ///
		graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
		plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
		scheme(s2mono) scale(1.7) yline(0, lpattern(dash) lcolor(black))
		*text(1.7 1.6  "Overall effect = `beta_takeup' pp (S.E. = `se_beta_takeup')", place(e) color(blue*.8) size(medsmall)) ///
		

	graph export "$results/fe_estimates_`depvar'_gender.pdf", as(pdf) replace
	
	local xx = `xx' + 1
	
	restore


}



stp 
**# Tabla efectos 3 a 5 años, 6 +, y total

rename (battelle tvip cbcl) (battelle0 tvip0 cbcl0)

// foreach y1 in 0 1 2 {
foreach depvar in "battelle" "tvip" "cbcl"{
// 	local depvar = "battelle"
	preserve //Nos quedamos con el N más chico de todas las regresiones (reg 4, de cada test)
	qui: reghdfe `depvar'0 min_center_NM $controls, absorb(cohort#comuna_cod) vce(robust)
	keep if e(sample) == 1
	
	qui: summarize `depvar'0
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
	local nreg = 1
	
	*1. Full FEx -- efecto en 3 a 5 años.
	qui: reghdfe `depvar'3 min_center_NM $controls, absorb(cohort#comuna_cod) vce(robust)
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
	
	
	*2. Full FEx -- efecto en 6+ años.
	qui: reghdfe `depvar'6 min_center_NM $controls, absorb(cohort#comuna_cod) vce(robust)
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
	
	
	*3. Full FEx - total
	qui: reghdfe `depvar'0 min_center_NM $controls, absorb(cohort#comuna_cod) vce(robust)
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
	
	restore
	
	local nreg = `nreg' + 1
	
	
	
}

*Names for table
local x = 1
foreach names in "Battelle" "TVIP" "CBCL" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}



*Table
file open itts using "$results/fe_estimates_children_total.tex", write replace
	file write itts "\begin{tabular}{lcccccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  & \multirow{2}{*}{Baseline mean} &  & \multicolumn{3}{c}{Estimated effects}                               \\" _n
	file write itts "             &  &                                &  & (1)   & (2) & (3)  \\" _n
	file write itts "\midrule" _n
	
	local x = 1
	foreach depvar in "battelle" "tvip" "cbcl" {
		*Betas
		file write itts " `name_`x'' (N = `n_`depvar'_4')   &  &         `mean_`depvar''       &  &  `beta_`depvar'_1'`stars_`depvar'_1'     &  `beta_`depvar'_2'`stars_`depvar'_2'    &  `beta_`depvar'_3'`stars_`depvar'_3'          \\" _n
		
		*Standard errors
		file write itts "     &  &         			       &  &  (`se_beta_`depvar'_1')    &  (`se_beta_`depvar'_2')    &  (`se_beta_`depvar'_3')            \\" _n
		if `x' == 3{
			
		}
		else{
		file write itts " &  &                                &  &         &        &        &   \\" _n
		}
		local x = `x' + 1
	}
	
	file write itts "\midrule" _n
	file write itts "    Control variables         &  &                                &  & Yes   & Yes & Yes \\" _n
	file write itts "  	 Cohort and Municipality FEs         &  &                   &   & Yes & Yes & Yes  \\" _n
	file write itts "    Cohort\$\times\$ Municipality FEs         &  &                 &   & Yes  & Yes  &   Yes  \\" _n
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts




