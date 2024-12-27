/*
This do-file implemente the dChaisemartint and coauthors estimators
Design: DiD a the municipality level, non-staggered, treatment = 1 if 
municipality has an average of 500 meters of promixity or less.

*/


global db "/home/jrodriguezo/childcare/data"
global codes "/home/jrodriguezo/childcare/codes"
global results "/home/jrodriguezo/childcare/results"


***Setting up event-study design


use "$db/data_estimate", clear

*Obtaining cognitive scores (short term)
drop battelle tvip
egen batelle = rowmean(battelle_age3_z battelle_age4_z battelle_age5_z)
egen tvip = rowmean(tvip_age3_z tvip_age4_z tvip_age5_z)

collapse (mean) N_centers1000_NM min_center_NM public_34 d_work_18 wage_18 hours_w_18 tvip batelle (count) N_households = min_center_NM (count) weight_n_batelle = batelle (count) weight_n_tvip = tvip, by(comuna_cod cohort)
sort comuna_cod cohort
xtset comuna_cod cohort

gen treated_distance = .
replace treated_distance = 1 if min_center_NM <= .5
replace treated_distance = 0 if min_center_NM > .5


gen treated_centers = .
replace treated_centers = 1 if N_centers1000_NM > 2
replace treated_centers = 0 if N_centers1000_NM <= 2

did_multiplegt_stat public_34 comuna_cod cohort treated_distance, weights(N_households) exact_match cluster(comuna_cod) placebo(1)

*Estimates and plots
foreach depvar in "public_34" "wage_18" "hours_w_18" "d_work_18" "tvip" "batelle"{
	

	qui: summarize `depvar'
	local mean_`depvar' = string(round(r(mean),.001),"%9.3f")
	
	qui: did_multiplegt_stat `depvar' comuna_cod cohort treated_distance, weights(N_households) exact_match cluster(comuna_cod) placebo(1)
	local was_`depvar' = string(round(e(WAS)[1,1],.001),"%9.3f")
	local lb_was_`depvar' = string(round(e(WAS)[1,3],.001),"%9.3f")
	local ub_was_`depvar' = string(round(e(WAS)[1,4],.001),"%9.3f")

	local placebo_`depvar' = string(round(e(PlaceboWAS)[1,1],.001),"%9.3f")
	local lb_placebo_`depvar' = string(round(e(PlaceboWAS)[1,3],.001),"%9.3f")
	local ub_placebo_`depvar' = string(round(e(PlaceboWAS)[1,4],.001),"%9.3f")

	
	
}


***Table**


*Names for table
local x = 1
foreach names in "Earnings" "Hours" "Employment" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}



file open itts using "$results/dCH.tex", write replace
	file write itts "\begin{tabular}{lcccccc}" _n
	file write itts "\toprule" _n
	file write itts "             &  &   Baseline mean  & & ATE && Placebo  \\" _n
	file write itts "\midrule" _n
	file write itts "   &&     & &  &&  \\" _n
	file write itts "   \multicolumn{2}{l}{\textbf{A. Take-up}}  &    & &  &&   \\" _n
	file write itts "   &&     & &  &&  \\" _n
	
	file write itts "  Child care  &&   `mean_public_34'  & & `was_public_34' && `placebo_public_34'  \\" _n
	file write itts "              &&      & &  [`lb_was_public_34';`ub_was_public_34']  &&  [`lb_placebo_public_34';`ub_placebo_public_34'] \\" _n
	
	file write itts "   &&     & &  &&  \\" _n
	file write itts "   \multicolumn{2}{l}{\textbf{B. Labor market}}  &     & & &&   \\" _n
	file write itts "   &&     & &  &&  \\" _n
	
	local x = 1
	foreach depvar in "wage_18" "hours_w_18" "d_work_18" {

		file write itts "   `name_`x''  &&   `mean_`depvar''  & & `was_`depvar'' && `placebo_`depvar''  \\" _n
		file write itts "             &&          & & [`lb_was_`depvar'';`ub_was_`depvar'']  && [`lb_placebo_`depvar'';`ub_placebo_`depvar'']  \\" _n
		file write itts "   &&     & &  &&  \\" _n
		local x = `x' + 1

	}

	file write itts "   \multicolumn{2}{l}{\textbf{C. Cognitive test scores}}  &    & &  &&   \\" _n
	file write itts "   &&     & &  &&  \\" _n
	file write itts "  TVIP  &&   `mean_tvip'  & & `was_tvip' && `placebo_tvip' \\" _n
	file write itts "        &&   			 & & [`lb_was_tvip';`ub_was_tvip'] && [`lb_placebo_tvip';`ub_placebo_tvip']  \\" _n
	file write itts "   &&     & &  &&  \\" _n
	file write itts "  Batelle  &&   `mean_batelle'  & & `was_batelle' && `placebo_batelle'  \\" _n
	file write itts "            &&               & & [`lb_was_batelle';`ub_was_batelle']  && [`lb_placebo_batelle';`ub_placebo_batelle']  \\" _n
	file write itts "\bottomrule" _n
	file write itts "\end{tabular}" _n
file close itts



