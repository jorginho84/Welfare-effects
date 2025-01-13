/*
    This do-file estimates WTP and costs.
*/

local user Jorge-server

if "`user'" == "andres" {
    cd "/Users/andres/Dropbox/jardines_elpi"
    global db "/Users/andres/Dropbox/jardines_elpi/data"
    global codes "/Users/andres/Dropbox/jardines_elpi/codes"
} 
else if "`user'" == "Jorge-server" {
    global db "/home/jrodriguezo/childcare/data"
    global codes "/home/jrodriguezo/childcare/codes"
    global results "/home/jrodriguezo/childcare/results"
} 
else if "`user'" == "Jorge" {
    global db "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Data"
    global results "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Results"
} 
else if "`user'" == "Antonia" {
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

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings f_home PESO TALLA controles dum_smoke dum_alc

// Computing lifetime earnings
local annual_e = 4565 /* from Bravo, Mukhopadhyay, and Todd. 2002 dollars */
local discount = 0.03

local life_earnings = 0
forvalues y = 0/39 { /* 40 years working */
    local life_earnings = `life_earnings' + `annual_e'/(1+`discount')^`y'
}

// Display lifetime earnings
di `life_earnings'

// Fixed parameters
global tau = 0.35 /* tax rate */
global earnings = `life_earnings' /* lifetime earnings */
global cog_earnings = 1.114/6.511 /* Contreras, Urzua, Rodriguez (2023) */
global J_distance = 1 /* # of centers for a 1-km change in av distance */
global delta_J = 59880/70 /* cost of additional center per child */
global delta_N = 1654 /* Marginal cost of additional child */
global J = 2061 /* baseline # of centers */
global N = 30000 /* baseline number of children */
global kms_hours = 2*(1.5/60) /* hours saved (driving 40kms per hour) */

// Bootstrap draws
local draws = 500

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

// Define program to estimate WTP and costs
program benefits_cost, rclass
    tempvar pz pcat min_center_34_neg
    
    // Take-up estimate
    gen `min_center_34_neg' = -min_center_34
    qui: logit public_34 `min_center_34_neg' $controls i.comuna_cod i.cohort
    qui: margins, dydx(`min_center_34_neg') gen(takeup)
    qui: sum takeup1, meanonly
    local mean_takeup = r(mean)
    return scalar takeup_av = `mean_takeup'
    
    // Average participation
    qui: sum public_34, meanonly
    local mean_34 = r(mean)
    
    // Earnings
    qui: sum hwage_18 if public_34 == 1 & hwage_18 != 0, meanonly
    local mean_wage_D1 = r(mean)
    
    // Reduced form: effect on cognitive skills
    qui: reghdfe cog_factor min_center_34 $controls, absorb(cohort#comuna_cod) vce(cluster comuna_cod)
    local delta_cog = -_b[min_center_34]
    
    // WTPs for a one-hour reduction in distance
    local wtp_ch = `delta_cog' * $cog_earnings * $earnings / $kms_hours
    local wtp_p = `mean_wage_D1' * `mean_34'  * 5 * 52
    local wtp = `wtp_ch' + `wtp_p'
    
    return scalar wtp_ch = `wtp_ch'
    return scalar wtp_p = `wtp_p'
    return scalar wtp = `wtp'
    
    // Costs
    local prov_cost = ($delta_J * $J_distance) + ($delta_N * `mean_takeup')
    return scalar prov_cost = `prov_cost'
    
    qui: sum hwage_18 if hwage_18 != 0, meanonly
    local mean_wage = r(mean)
    
    qui: reghdfe hours_w_18 min_center_34 $controls, absorb(cohort#comuna_cod) vce(robust)
    local delta_hours = -_b[min_center_34]
    local rev_parents = `delta_hours' * `mean_wage' * 52 * $tau / $kms_hours /* assuming no effects from infra-marginal parents */
    local rev_children = `delta_cog' * $cog_earnings * $earnings * $tau / $kms_hours
    
    return scalar rev_parents = `rev_parents'
    return scalar rev_children = `rev_children'
    
    local costs = `prov_cost' - `rev_parents' - `rev_children'
    return scalar costs = `costs'
    
    // MVPF
    local mvpf = `wtp'/`costs'
    return scalar mvpf = `mvpf'
end

qui: benefits_cost
di r(wtp_ch)
di r(wtp_p)
di r(wtp)
di r(prov_cost)
di r(rev_parents)
di r(rev_children)
di r(costs)
di r(mvpf)
di r(takeup_av)

mat betas_original = r(wtp_ch)\r(wtp_p)\r(wtp)\r(prov_cost)\r(rev_children)\r(rev_parents)\r(costs)\r(mvpf)

local n_estimates = rowsof(betas_original)

tempfile data_aux
save `data_aux', replace

forvalues x = 1/`draws' {
    bsample
    qui: benefits_cost
    mat betas = r(wtp_ch)\r(wtp_p)\r(wtp)\r(prov_cost)\r(rev_children)\r(rev_parents)\r(costs)\r(mvpf)
    svmat betas
    keep betas1
    rename betas1 betas
    drop if betas == .
    egen par = seq()
    gen draw = `x'
    qui: reshape wide betas, i(draw) j(par)
    tempfile data_`x'
    qui: save `data_`x'', replace
    use `data_aux', clear
}

use `data_1', clear
forvalues x = 2/`draws' {
    append using `data_`x''
}

forvalues x = 1/8 {
    local beta_original_`x' = string(round(betas_original[`x',1],.001),"%9.2f")
    qui: sum betas`x'
    local left_`x' = betas_original[`x',1] - invnormal(0.975)*r(sd)
    local right_`x' = betas_original[`x',1] + invnormal(0.975)*r(sd)
}

// MVPF Figure 1
local beta_wtp_c = betas_original[1,1]
local beta_wtp_p = betas_original[2,1]
local beta_wtp = betas_original[3,1]

local prov_cost = betas_original[4,1]
local rev_c = betas_original[5,1]
local rev_p = betas_original[6,1]
local costs = betas_original[7,1]

local mvpf = betas_original[8,1]

clear
set obs 10
gen beta = .
gen lb = .
gen ub = .

replace lb = `left_1' if _n == 1
replace lb = `left_2' if _n == 2
replace lb = `left_3' if _n == 3
replace lb = `left_4' if _n == 5
replace lb = `left_5' if _n == 6
replace lb = `left_6' if _n == 7
replace lb = `left_7' if _n == 8
replace lb = `left_8' if _n == 10

replace ub = `right_1' if _n == 1
replace ub = `right_2' if _n == 2
replace ub = `right_3' if _n == 3
replace ub = `right_4' if _n == 5
replace ub = `right_5' if _n == 6
replace ub = `right_6' if _n == 7
replace ub = `right_7' if _n == 8
replace ub = `right_8' if _n == 10

replace beta = `beta_wtp_c' if _n == 1
replace beta = `beta_wtp_p' if _n == 2
replace beta = `beta_wtp' if _n == 3
replace beta = `prov_cost' if _n == 5
replace beta = `rev_c' if _n == 6
replace beta = `rev_p' if _n == 7
replace beta = `costs' if _n == 8

gen beta_mvpf = .
replace beta_mvpf = `mvpf' if _n == 10

gen lb_mvpf = .
gen ub_mvpf = .

replace lb_mvpf = lb if _n == 10
replace ub_mvpf = ub if _n == 10

egen x = seq()

label define lab_aux 1 "WTP children" 2 "WTP parents" 3 "WTP" 4 "" 5 "Provision cost" 6 "Revenues (children)" 7 "Revenues (parents)" 8 "Costs" 9 "" 10 "MVPF"
label values x lab_aux

splitvallabels x, length(10)
twoway (bar beta x, fcolor(sand) lcolor(sand)) ///
    (scatter beta x, msymbol(circle) msize(small) mcolor(black) mfcolor(black)) ///
    (rcap ub lb x, lpattern(solid) lcolor(black)) ///
    (bar beta_mvpf x, fcolor(ltblue) lcolor(ltblue) yaxis(2)) ///
    (scatter beta_mvpf x, msymbol(circle) msize(small) mcolor(black) mfcolor(black) yaxis(2)) ///
    (rcap ub_mvpf lb_mvpf x, lpattern(solid) lcolor(black) yaxis(2)), ///
    ytitle("WTP and costs (dollars)") ytitle("MVPF (dollars)", axis(2)) xtitle("") legend(off) ///
    xlabel(`r(relabel)', labsize(vsmall)) ylabel(,nogrid) ylabel(0(2)20, nogrid axis(2)) ///
    graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) ///
    scheme(s2mono) xline(4, lpattern(dash) lcolor(black)) xline(9, lpattern(dash) lcolor(black))
graph export "$results/mvpf.pdf", as(pdf) replace






