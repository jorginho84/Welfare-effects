/*
This do-file checks the validity of identification assumption
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



set more off
program drop _all

use "$db/data_estimate", clear

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home

*Father in college
gen f_college = f_educ >= 4
replace f_college = . if f_educ == .

*Controles embarazo
gen controles = q_control_2012 >= 7
replace controles = . if q_control_2012 == .

*Peso al nacer
gen PESO = PESO_2010
replace PESO = PESO_2012 if PESO == . 

*Talla al nacer
gen TALLA = TALLA_2010
replace TALLA = TALLA_2012 if TALLA == . 

program define corrs, rclass
	tempvar pro_resid
	
	
	qui: reghdfe min_center_34 $controls , absorb(cohort#comuna_cod) residuals(`pro_resid')
		
	foreach depvar in "f_college" "married" "dum_smoke" "dum_alc" "PESO" "TALLA"{
		qui: corr `depvar' `pro_resid'
		return scalar `depvar' = r(rho)
		qui: corr `depvar' min_center_34
		return scalar `depvar'_corr = r(rho)
	
	}
	

	
end

corrs
di r(married_corr)
di r(married)
di r(f_college_corr)
di r(f_college)





bootstrap r(f_college_corr) r(married_corr) r(dum_smoke_corr) r(dum_alc_corr) r(PESO_corr) r(TALLA_corr) ///
 r(f_college) r(married) r(dum_smoke) r(dum_alc) r(PESO) r(TALLA), reps(500) seed(1234): corrs
mat betas = e(b)
mat betas_se = e(se)


clear
set obs 24
	
gen y = .
gen coeff_corr = .	
gen coeff = .	
gen lb_corr = .
gen ub_corr = .
gen lb = .
gen ub = .


forval x=1/24{
	replace y = -`x' if _n == `x'
}


forvalues x = 1/6{

	replace coeff_corr = betas[1,`x'] if _n == 3*`x' + (`x' - 2)
	replace lb_corr = betas[1,`x'] - betas_se[1,`x']*invnormal(0.975) if _n == 3*`x' + (`x' - 2)
	replace ub_corr = betas[1,`x'] + betas_se[1,`x']*invnormal(0.975) if _n == 3*`x' + (`x' - 2)
	
	replace coeff = betas[1,`x' + 6] if _n == 3*`x' + (`x' - 1)
	replace lb = betas[1,`x' + 6] - betas_se[1,`x' + 6]*invnormal(0.975) if _n == 3*`x' + (`x' - 1)
	replace ub = betas[1,`x' + 6] + betas_se[1,`x' + 6]*invnormal(0.975) if _n == 3*`x' + (`x' - 1)
		
	

	
}

twoway (scatter y coeff_corr, msymbol(circle)  mcolor(blue*.8) mfcolor(blue*.8)) ///
  (rcap ub_corr lb_corr y, horizontal lpattern(solid) lcolor(blue*.8) ) ///
  (scatter y coeff, msymbol(circle)  mcolor(sand*.8) mfcolor(sand*.8)) ///
  (rcap ub lb y, horizontal lpattern(solid) lcolor(sand*.8) ), ///
 xtitle("Correlation")  ytitle("") legend(order(1 "No controls" 3 "Full controls"))  ///
 ylabel(-2.5 "Father college +" -6.5 "Married" -10.5 "Smoke during pregnancy" -14.5 "Alcohol during pregnancy" ///
 	-18.5 "Length at birth" -22.5 "Weight at birth", angle(horizontal)) ///
 xlabel(-0.1(0.05)0.1)  ///
 graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) ///
 plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
 scheme(s2mono) ylabel(, nogrid) xline(0, lpattern(dash) lcolor(black)) scale(1.2)
 
 
graph export "$results/validity.pdf", as(pdf) replace
