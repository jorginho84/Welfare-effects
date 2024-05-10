
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



*----------------------*
*---------PREP---------*
*----------------------*

foreach var in wage hours_w d_work{
	egen `var'_18=rowmean( `var'_t7 `var'_t8)
	*gen `var'_18 = `var'_t7
}

egen TVIP = rowmean(TVIP_age_2 TVIP_age_3)

*Below/above median
qui: sum income_t0, d
scalar median_i = r(p50)
gen cat_income = .
replace cat_income = 1 if income_t0 <= median_i
replace cat_income = 2 if income_t0 > median_i & income_t0 != .



foreach depvar in "wage_18" "hours_w_18" "d_work_18" "TVIP" {
	
	qui: summarize `depvar'
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
	

	local nreg = 1
	*Overall
	qui: reghdfe `depvar' min_center_34 $controls, absorb(cohort#comuna_cod) vce(robust)
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
	
	
	*By gender
	forvalues g = 1/2{
		qui: reghdfe `depvar' min_center_34 $controls if gender == `g', absorb(cohort#comuna_cod) vce(robust)
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
	
	*By income
	forvalues g = 1/2{
		qui: reghdfe `depvar' min_center_34 $controls if cat_income == `g', absorb(cohort#comuna_cod) vce(robust)
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
	
	
	
	
}

*Names for table
local x = 1
foreach names in "Monthly earnings" "Hours worked" "Work (=1)" "Cognitive score (\$\sigma\$)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}



*Table
file open itts using "$results/fe_estimates.tex", write replace
	file write itts "\begin{tabular}{lcccccccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  & \multirow{2}{*}{Baseline mean} &  & \multicolumn{5}{c}{Sample}                               \\" _n
	file write itts "             &  &                                &  & Overall   & Male & Female &   Low-income & High-income \\" _n
	file write itts "\midrule" _n
	
	local x = 1
	foreach depvar in "wage_18" "hours_w_18" "d_work_18" "TVIP" {
		*Betas
		file write itts " `name_`x''    &  &         `mean_`depvar''       &  &  `beta_`depvar'_1'`stars_`depvar'_1'     &  `beta_`depvar'_2'`stars_`depvar'_2'    &  `beta_`depvar'_3'`stars_`depvar'_3'        &      `beta_`depvar'_4'`stars_`depvar'_4'      &       `beta_`depvar'_5'`stars_`depvar'_5'      \\" _n
		
		*Standard errors
		file write itts "     &  &         			       &  &  (`se_beta_`depvar'_1')    &  (`se_beta_`depvar'_2')    &  (`se_beta_`depvar'_3')        &      (`se_beta_`depvar'_4')      &       (`se_beta_`depvar'_5')     \\" _n
		file write itts " &  &                                &  &         &        &        &              &             \\" _n
		local x = `x' + 1
	}
	
	            
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts

stop!!

****Plots for slides**


*Earnings
clear
set obs 2
gen category = .
forvalues x = 1/2{
	gen beta_`x' = .
	gen lb_`x' = .
	gen ub_`x' = .
	
	
	replace beta_`x' = `beta_wage_18_`x'' if _n == `x'
	replace lb_`x' = `beta_wage_18_`x'' - `se_beta_wage_18_`x''*invnormal(0.975) if _n == `x'
	replace ub_`x' = `beta_wage_18_`x'' + `se_beta_wage_18_`x''*invnormal(0.975) if _n == `x'
	
	
	}
replace category = 2 if _n == 1
replace category = 3 if _n == 2



twoway (scatter beta_1 category, msymbol(circle)  mcolor(blue*.8) mfcolor(blue*.8)) ///
 (rcap ub_1 lb_1 category, lpattern(solid) lcolor(blue*.8) ) ///
 (scatter beta_2 category, msymbol(square)  mcolor(sand*.8) mfcolor(sand*.8)) ///
  (rcap ub_2 lb_2 category,  lpattern(solid) lcolor(sand*.8) ), ///
 ytitle("Effect on earnings")  xtitle("") legend(off) ///
 xlabel( 1.5 " " 2 "No controls" 3 "Full controls" 3.5 " ", noticks)  ///
   graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
 scheme(s2mono) yline(0, lpattern(dash) lcolor(black)) scale(2) ylabel(,nogrid)
 graph export "$results/fe_rf_wages.pdf", as(pdf) replace
 
 
*hours
clear
set obs 2
gen category = .
forvalues x = 1/2{
	gen beta_`x' = .
	gen lb_`x' = .
	gen ub_`x' = .
	
	
	replace beta_`x' = `beta_hours_w_18_`x'' if _n == `x'
	replace lb_`x' = `beta_hours_w_18_`x'' - `se_beta_hours_w_18_`x''*invnormal(0.975) if _n == `x'
	replace ub_`x' = `beta_hours_w_18_`x'' + `se_beta_hours_w_18_`x''*invnormal(0.975) if _n == `x'
	
	
}
replace category = 2 if _n == 1
replace category = 3 if _n == 2

twoway (scatter beta_1 category, msymbol(circle)  mcolor(blue*.8) mfcolor(blue*.8)) ///
 (rcap ub_1 lb_1 category, lpattern(solid) lcolor(blue*.8) ) ///
 (scatter beta_2 category, msymbol(square)  mcolor(sand*.8) mfcolor(sand*.8)) ///
  (rcap ub_2 lb_2 category,  lpattern(solid) lcolor(sand*.8) ), ///
 ytitle("Effect on hours")  xtitle("") legend(off) ///
 xlabel( 1.5 " " 2 "No controls" 3 "Full controls" 3.5 " ", noticks)  ///
   graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
 scheme(s2mono) yline(0, lpattern(dash) lcolor(black)) scale(2) ylabel(-0.1(0.2)0.8,nogrid)
 graph export "$results/fe_rf_hours.pdf", as(pdf) replace

*employment
clear
set obs 3
gen category = .
forvalues x = 1/2{
	gen beta_`x' = .
	gen lb_`x' = .
	gen ub_`x' = .
	
	
	replace beta_`x' = `beta_d_work_18_`x'' if _n == `x'
	replace lb_`x' = `beta_d_work_18_`x'' - `se_beta_d_work_18_`x''*invnormal(0.975) if _n == `x'
	replace ub_`x' = `beta_d_work_18_`x'' + `se_beta_d_work_18_`x''*invnormal(0.975) if _n == `x'
	
	
}
replace category = 2 if _n == 1
replace category = 3 if _n == 2


twoway (scatter beta_1 category, msymbol(circle)  mcolor(blue*.8) mfcolor(blue*.8)) ///
 (rcap ub_1 lb_1 category, lpattern(solid) lcolor(blue*.8) ) ///
 (scatter beta_2 category, msymbol(square)  mcolor(sand*.8) mfcolor(sand*.8)) ///
  (rcap ub_2 lb_2 category,  lpattern(solid) lcolor(sand*.8) ), ///
 ytitle("Effect on employment")  xtitle("") legend(off) ///
 xlabel( 1.5 " " 2 "No controls" 3 "Full controls" 3.5 " ", noticks)  ///
   graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
 scheme(s2mono) yline(0, lpattern(dash) lcolor(black)) scale(2) ylabel(,nogrid)
 graph export "$results/fe_rf_employment.pdf", as(pdf) replace


*test scores
clear
set obs 3
gen category = .
forvalues x = 1/2{
	gen beta_`x' = .
	gen lb_`x' = .
	gen ub_`x' = .
	
	
	replace beta_`x' = `beta_TVIP_`x'' if _n == `x'
	replace lb_`x' = `beta_TVIP_`x'' - `se_beta_TVIP_`x''*invnormal(0.975) if _n == `x'
	replace ub_`x' = `beta_TVIP_`x'' + `se_beta_TVIP_`x''*invnormal(0.975) if _n == `x'
	
	
}
replace category = 2 if _n == 1
replace category = 3 if _n == 2


twoway (scatter beta_1 category, msymbol(circle)  mcolor(blue*.8) mfcolor(blue*.8)) ///
 (rcap ub_1 lb_1 category, lpattern(solid) lcolor(blue*.8) ) ///
 (scatter beta_2 category, msymbol(square)  mcolor(sand*.8) mfcolor(sand*.8)) ///
  (rcap ub_2 lb_2 category,  lpattern(solid) lcolor(sand*.8) ), ///
 ytitle("Effect on test scores (SDs)")  xtitle("") legend(off) ///
 xlabel( 1.5 " " 2 "No controls" 3 "Full controls" 3.5 " ", noticks)  ///
   graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
 scheme(s2mono) yline(0, lpattern(dash) lcolor(black)) scale(1.8) ylabel(,nogrid)
 graph export "$results/fe_rf_tvip.pdf", as(pdf) replace

 *ylabel(-0.2(0.1)0.4, nogrid)  ///

/*

*Tables (for slides)
file open itts using "$results/fe_estimates_1.tex", write replace
	file write itts "\begin{tabular}{llm{1.7cm}cm{1.7cm}}" _n
	file write itts "\toprule" _n
	file write itts " &  &(1) && (2)  \\" _n
		file write itts "\midrule" _n
	file write itts " \multicolumn{5}{c}{\textbf{Panel A. Labor market outcomes}}   \\" _n
	file write itts " &&        &&                 \\" _n
	file write itts " Earnings (monthly USD) & & `beta_wage_18_1'`stars_wage_18_1' && `beta_wage_18_2'`stars_wage_18_2' \\" _n
	file write itts "  &  & (`se_beta_wage_18_1')  && (`se_beta_wage_18_2') \\" _n
	file write itts " &  &                       &  &       &&     \\" _n
	file write itts " Hours (weekly) &  & `beta_hours_w_18_1'`stars_hours_w_18_1' && `beta_hours_w_18_2'`stars_hours_w_18_2' \\" _n
	file write itts "  &  & (`se_beta_hours_w_18_1')  && (`se_beta_hours_w_18_2') \\" _n
	file write itts " &  &                       &  &       &&     \\" _n
	file write itts " Employment  &  & `beta_d_work_18_1'`stars_d_work_18_1' && `beta_d_work_18_2'`stars_d_work_18_2' \\" _n
	file write itts "  &  & (`se_beta_d_work_18_1')  && (`se_beta_d_work_18_2') \\" _n
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts


*Tables (for slides)
file open itts using "$results/fe_estimates_1.tex", write replace
	file write itts "\begin{tabular}{llm{1.7cm}cm{1.7cm}}" _n
	file write itts "\toprule" _n
	file write itts " &  &(1) && (2)  \\" _n
		file write itts "\midrule" _n
	file write itts " \multicolumn{5}{c}{\textbf{Panel A. Labor market outcomes}}   \\" _n
	file write itts " &&        &&                 \\" _n
	file write itts " Earnings (monthly USD) & & `beta_wage_18_1'`stars_wage_18_1' && `beta_wage_18_2'`stars_wage_18_2' \\" _n
	file write itts "  &  & (`se_beta_wage_18_1')  && (`se_beta_wage_18_2') \\" _n
	file write itts " &  &                       &  &       &&     \\" _n
	file write itts " Hours (weekly) &  & `beta_hours_w_18_1'`stars_hours_w_18_1' && `beta_hours_w_18_2'`stars_hours_w_18_2' \\" _n
	file write itts "  &  & (`se_beta_hours_w_18_1')  && (`se_beta_hours_w_18_2') \\" _n
	file write itts " &  &                       &  &       &&     \\" _n
	file write itts " Employment  &  & `beta_d_work_18_1'`stars_d_work_18_1' && `beta_d_work_18_2'`stars_d_work_18_2' \\" _n
	file write itts "  &  & (`se_beta_d_work_18_1')  && (`se_beta_d_work_18_2') \\" _n
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts


*Tables (for slides)
file open itts using "$results/fe_estimates_2.tex", write replace
	file write itts "\begin{tabular}{llm{1.7cm}cm{1.7cm}}" _n
	file write itts "\toprule" _n
	file write itts " &  &(1) && (2)  \\" _n
		file write itts "\midrule" _n
	
	file write itts " \multicolumn{5}{c}{\textbf{Panel B. Test scores}}   \\" _n
	file write itts " &  &                       &  &        \\" _n
	file write itts " Cognitive skills (in \$ \sigma \$)  &  & `beta_TVIP_1'`stars_TVIP_1' && `beta_TVIP_2'`stars_TVIP_2' \\" _n
	file write itts "  &  & (`se_beta_TVIP_1')  && (`se_beta_TVIP_2') \\" _n
	file write itts " &  &         &&                 \\" _n
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts

*/
