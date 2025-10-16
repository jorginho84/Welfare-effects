/*
WTP and take up levels
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

global controls m_age m_college WAIS_t_num WAIS_t_vo f_home dum_young_siblings  /*PESO TALLA*/ controles dum_smoke dum_alc

// Computing lifetime earnings
local annual_e = 4565 * 2.29434 /* from Bravo, Mukhopadhyay, and Todd. From 2002 to 2024 to dollars */
local discount = 0.03

local life_earnings = 0
forvalues y = 0/39 { /* 40 years working */
    local life_earnings = `life_earnings' + `annual_e'/(1+`discount')^`y'
}

// Discount back to 3 years of age (assuming individuals start working at 20)
local life_earnings = `life_earnings' / (1 + `discount')^(17)

// Display lifetime earnings
di `life_earnings'

// Fixed parameters
global tau = 0.35 /* tax rate */
global earnings = `life_earnings' /* lifetime earnings */
global cog_earnings = 1.114/6.511 /* Contreras, Urzua, Rodriguez (2023) */
global J_distance = 1 /* # of centers for a 1-km change in av distance */
global delta_J = (55 * 37508.22 * 8)/943.58 /* cost of additional center per child. 55 UF * pesos_to_UF/exchange rate  */
global delta_N = (194814/943.58)*12 /* Marginal cost of additional child. VTF transfer per year. In 2024 dollars*/
global J = 2061 /* baseline # of centers */
global N = 30000 /* baseline number of children */
global kms_hours = 2*24/60 /* hours saved (walking 24 mins), round trip */
global depreciation = 0.05 /* depreciation rate */
global cost_capital = 0.05 /* cost of capital */


// Obtain cognitive factor
factor tvip3 battelle3, factors(1)
rotate, quartimin
predict cog_factor_aux
egen cog_factor = std(cog_factor_aux)

// Hourly wage
forvalues x = 7/8 {
    gen hwage_t`x' = wage_t`x'/(hours_w_t`x'*4.5) if wage_t`x' != 0 & hours_w_t`x' != 0
}
egen hwage_18 = rowmean(hwage_t7 hwage_t8)

// Dummy for cohort x region
egen cohort_region = group(cohort region)
tab cohort_region, gen(cohort_region_fe)

program benefits_cost, rclass
	args takeup
    tempvar pz pcat min_center_34_neg
	
	
	*Average participation
	qui: sum public_34, meanonly
	local mean_34 = r(mean)
	
	*Earnings
	qui: sum hwage_18 if public_34 == 1 & hwage_18 != 0, meanonly
	local mean_wage_D1 = r(mean)
	
	
	*MPRTE
	qui: mtefe cog_factor $controls i.comuna_cod i.cohort cohort_region_fe2-cohort_region_fe70 (public_34 = min_center_NM), pol(2) trimsupport(0.01) noplot
	mat M = e(b)
	local mcol3 = colnumb(M,"mprte1")
	local mprte3_aux    = M[1,`mcol3']
	local wtp_ch = `mprte3_aux'*$cog_earnings * $earnings * `takeup' 
	local wtp_p = `mean_wage_D1' * `mean_34'  * 5 * 52 * $kms_hours 
	local wtp = `wtp_ch' + `wtp_p'
	
	return scalar wtp_ch = `wtp_ch'
	return scalar wtp_p = `wtp_p'
	return scalar wtp = `wtp'
	
	*Costs
	local prov_cost = ($delta_J * $J_distance * ($depreciation + $cost_capital)) + ($delta_N * `takeup')
	return scalar prov_cost = `prov_cost'
	
	qui: mtefe wage_18 $controls i.comuna_cod i.cohort cohort_region_fe2-cohort_region_fe70 (public_34 = min_center_NM), pol(2) trimsupport(0.01) noplot
	mat M = e(b)
	local mcol3 = colnumb(M,"mprte1")
	local mprte3_h    = M[1,`mcol3']
	local rev_parents = `mprte3_h' * 12 * `takeup' * $tau  /*assuming no effects from infra-marginal parents*/
	local rev_children = `mprte3_aux' * $cog_earnings * $earnings * `takeup' * $tau 
	
	return scalar rev_parents = `rev_parents'
	return scalar rev_children = `rev_children'
	
	local costs = `prov_cost' - `rev_parents' - `rev_children'
	return scalar costs = `costs'
	
	*MVPF
	local mvpf = `wtp'/`costs'
	return scalar mvpf = `mvpf'

	

end


local z = 1
foreach x of numlist 0.01(0.01)0.15{
	qui: benefits_cost `x'
	local wtp_`z' = r(wtp)
	local costs_`z' = r(costs)
	local mvpf_`z' = r(mvpf)
	local z = `z' + 1
	
}

clear
set obs 15
gen wtp = .
gen costs = .
gen mvpf = .
gen takeup = .

forvalues x = 1/15{
	replace wtp = `wtp_`x'' if _n == `x'
	replace costs = `costs_`x'' if _n == `x'
	replace mvpf = `mvpf_`x'' if _n == `x'
	replace takeup = `x'/100 if _n == `x'	
}



twoway (connected wtp takeup,lcolor(sand*.8) msymbol(circle) mcolor(sand*.8)) ///
 (connected costs takeup,lcolor(blue*.8) msymbol(circle) mcolor(blue*.8)), ///
  ytitle("WTP and costs (dollars)") xtitle("Take up") legend(order(1 "WTP" 2 "Costs") ring(0) bplacement(nw)) ///
 ylabel(,nogrid)  ///
   graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white)) scale(1.5)  ///
 scheme(s2mono) 
graph export "$results/wtp_cost_takeup.pdf", as(pdf) replace

twoway (connected mvpf takeup,  msymbol(square) lcolor(black*.8)), ///
   ytitle("MVPF (dollars)") xtitle("Take up") legend(off) ///
 ylabel(,nogrid)  ///
   graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
 scheme(s2mono)   scale(1.5) 
graph export "$results/mvpf_takeup.pdf", as(pdf) replace
