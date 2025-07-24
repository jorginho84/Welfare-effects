/*
This do-file checks the validity of identification assumption. It compares the correlation of distance to measures of baseline covariates

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

set more off
program drop _all

use "$db/data_estimate", clear

// PCA index
pca m_college WAIS_t_num WAIS_t_vo
predict pca_index_aux if e(sample), score
egen pca_index1 = std(pca_index_aux)

// Collapsing at the comuna level
collapse (mean) pca_index1 (median) min_center_NM, by(comuna_cod cohort)

// Generating residualized PCA index
qui: reghdfe pca_index1, absorb(cohort comuna_cod) residuals(pca_resid)

// Figure
twoway ///
    (scatter pca_index1 min_center_NM if min_center_NM < 8,msymbol(oh) msize(medium) mcolor(blue*.4)) ///
    (lfit pca_index1 min_center_NM if min_center_NM < 8, lcolor(blue*.7) lwidth(thick) lpattern(dash)) ///
    (scatter pca_resid min_center_NM if min_center_NM < 8, msymbol(dh) msize(medium) mcolor(sand*.7)) ///
    (lfit pca_resid min_center_NM if min_center_NM < 8, lcolor(sand*.9) lwidth(thick) lpattern(solid)), ///
    legend(order(1 "Raw Index"  3 "Residualized Index") region(lstyle(none))) ///
    ytitle("Covariate Index") ///
    xtitle("Proximity") ///
    plotregion(fcolor(white) color(white)) ///
    graphregion(color(white))
	
graph export "$results/pca_distance_two.pdf", as(pdf) replace	



stop!!


// Individual and residualized correlations
use "$db/data_estimate", clear
global controls m_age m_college WAIS_t_num WAIS_t_vo f_home dum_young_siblings controles dum_smoke dum_alc

***Programa

program define corrs, rclass

*Now, with controls except the var of interest	
foreach v in $controls {
    tempvar pro_resid1 pro_resid2
//     di "`v'"
    global exclude "`v'"
	global control_aux : list global(controls) - global(exclude)
// 	di "$control_aux"

		*No controls
		qui: corr `v' min_center_NM
		return scalar `v'_corr = r(rho)
	
		*W/ controls
    reghdfe min_center_NM $control_aux , absorb(cohort#comuna_cod) residuals(`pro_resid2')
		qui: corr `v' `pro_resid2'
		return scalar `v' = r(rho)
	drop `pro_resid2'
}
		

	
end


bootstrap  r(m_age_corr) r(m_college_corr) r(WAIS_t_num_corr) r(WAIS_t_vo_corr) r(f_home_corr) r(dum_young_siblings_corr)  /*r(PESO_corr) r(TALLA_corr)*/ r(controles_corr) r(dum_smoke_corr) r(dum_alc_corr) ///
 r(m_age) r(m_college) r(WAIS_t_num) r(WAIS_t_vo) r(f_home) r(dum_young_siblings) /*r(PESO) r(TALLA)*/ r(controles) r(dum_smoke) r(dum_alc), reps(500) seed(1234): corrs
mat betas = e(b)
mat betas_se = e(se)

preserve
clear
set obs 36
	
gen y = .
gen coeff_corr = .	
gen coeff = .	
gen lb_corr = .
gen ub_corr = .
gen lb = .
gen ub = .


forval x=1/36{
	replace y = -`x' if _n == `x'
}


forvalues x = 1/9{

	replace coeff_corr = betas[1,`x'] if _n == 3*`x' + (`x' - 2)
	replace lb_corr = betas[1,`x'] - betas_se[1,`x']*invnormal(0.975) if _n == 3*`x' + (`x' - 2)
	replace ub_corr = betas[1,`x'] + betas_se[1,`x']*invnormal(0.975) if _n == 3*`x' + (`x' - 2)
	
	replace coeff = betas[1,`x' + 9] if _n == 3*`x' + (`x' - 1)
	replace lb = betas[1,`x' + 9] - betas_se[1,`x' + 9]*invnormal(0.975) if _n == 3*`x' + (`x' - 1)
	replace ub = betas[1,`x' + 9] + betas_se[1,`x' + 9]*invnormal(0.975) if _n == 3*`x' + (`x' - 1)
		
	

	
}


twoway (scatter y coeff_corr, msymbol(circle)  mcolor(blue*.8) mfcolor(blue*.8)) ///
  (rcap ub_corr lb_corr y, horizontal lpattern(solid) lcolor(blue*.8) ) ///
  (scatter y coeff, msymbol(circle)  mcolor(sand*.8) mfcolor(sand*.8)) ///
  (rcap ub lb y, horizontal lpattern(solid) lcolor(sand*.8) ), ///
 xtitle("Correlation")  ytitle("") legend(order(1 "No controls" 3 "Full controls"))  ///
 ylabel(-2.5 "Mother's age" -6.5 "Mother college +" -10.5 "WAIS (number retention)" -14.5  "WAIS (vocabulary)"  -18.5 "Father at home" -22.5 "Have younger siblings"  -26.5 "Risk: not all pregnancy controls" -30.5 "Risk: smoked during pregnancy" -34.5 "Risk: alcohol during pregnancy", angle(horizontal))  ///
 xlabel(-0.1(0.05)0.1)  ///
 graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) ///
 plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
 scheme(s2mono) ylabel(, nogrid) xline(0, lpattern(dash) lcolor(black)) scale(1.2)

 graph export "$results/validity.pdf", as(pdf) replace	
 
restore	
	
	
	
	

