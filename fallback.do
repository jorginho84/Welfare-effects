/*
This do-file computes fallback options

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
  global codes "/Users/jorge-home/Library/CloudStorage/Dropbox/Research/DN-early/Dynamic_childcare/Codes"
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
global controls m_age m_college WAIS_t_num WAIS_t_vo f_home dum_young_siblings  controles dum_smoke dum_alc	


// Data preparation

gen type_care_private = type_care34 == 2
gen type_care_home = type_care34 == 4 | type_care34 == 3

// Reduced-form estimates

reghdfe public_34 min_center_NM $controls, absorb(cohort#comuna_cod) vce(cluster comuna_cod)
local rf_beta_public = string(round(-_b[min_center_NM],.001),"%9.3f")
local rf_se_public = string(round(_se[min_center_NM],.001),"%9.3f")
local n_obs_public = string(e(N), "%9.0fc")
local rf_pval_public = 2 * (1 - normal(abs(_b[min_center_NM] / _se[min_center_NM])))
if `rf_pval_public' <= 0.01 {
    local rf_stars_public = "***"
} 
else if `rf_pval_public' <= 0.05 {
    local rf_stars_public = "**"
} 
else if `rf_pval_public' <= 0.1 {
    local rf_stars_public = "*"
} 
else {
    local rf_stars_public = " "
}


reghdfe type_care_private min_center_NM $controls, absorb(cohort#comuna_cod) vce(cluster comuna_cod)
local rf_beta_private = string(round(-_b[min_center_NM],.001),"%9.3f")
local rf_se_private = string(round(_se[min_center_NM],.001),"%9.3f")
local n_obs_private = string(e(N), "%9.0fc")
local rf_pval_private = 2 * (1 - normal(abs(_b[min_center_NM] / _se[min_center_NM])))
if `rf_pval_private' <= 0.01 {
    local rf_stars_private = "***"
} 
else if `rf_pval_private' <= 0.05 {
    local rf_stars_private = "**"
} 
else if `rf_pval_private' <= 0.1 {
    local rf_stars_private = "*"
} 
else {
    local rf_stars_private = " "
}

reghdfe type_care_home min_center_NM $controls, absorb(cohort#comuna_cod) vce(cluster comuna_cod)
local rf_beta_home = string(round(-_b[min_center_NM],.001),"%9.3f")
local rf_se_home = string(round(_se[min_center_NM],.001),"%9.3f")
local n_obs_home = string(e(N), "%9.0fc")
local rf_pval_home = 2 * (1 - normal(abs(_b[min_center_NM] / _se[min_center_NM])))
if `rf_pval_home' <= 0.01 {
    local rf_stars_home = "***"
} 
else if `rf_pval_home' <= 0.05 {
    local rf_stars_home = "**"
} 
else if `rf_pval_home' <= 0.1 {
    local rf_stars_home = "*"
} 
else {
    local rf_stars_home = " "
}


// Treatment effects

ivreghdfe type_care_home $controls (public_34 = min_center_NM), absorb(cohort#comuna_cod)
matrix b = e(b)
local te_beta_home = string(round(b[1, "public_34"],.001),"%9.3f")
matrix V = e(V)
local te_se_home = string(round(sqrt(V[1, 1]), .001), "%9.3f")
local n_obs_home = string(e(N), "%9.0fc")
local te_pval_home = 2 * (1 - normal(abs(b[1, "public_34"] / sqrt(V[1, 1]))))
if `te_pval_home' <= 0.01 {
    local te_stars_home = "***"
} 
else if `te_pval_home' <= 0.05 {
    local te_stars_home = "**"
} 
else if `te_pval_home' <= 0.1 {
    local te_stars_home = "*"
} 
else {
    local te_stars_home = " "
}


ivreghdfe type_care_private $controls (public_34 = min_center_NM), absorb(cohort#comuna_cod)
matrix b = e(b)
local te_beta_private = string(round(b[1, "public_34"],.001),"%9.3f")
matrix V = e(V)
local te_se_private = string(round(sqrt(V[1, 1]), .001), "%9.3f")
local n_obs_private = string(e(N), "%9.0fc")
local te_pval_private = 2 * (1 - normal(abs(b[1, "public_34"] / sqrt(V[1, 1]))))
if `te_pval_private' <= 0.01 {
    local te_stars_private = "***"
} 
else if `te_pval_private' <= 0.05 {
    local te_stars_private = "**"
} 
else if `te_pval_private' <= 0.1 {
    local te_stars_private = "*"
} 
else {
    local te_stars_private = " "
}

// Table for LaTeX

// Table for LaTeX

file open itts using "$results/fallback.tex", write replace
    file write itts "\begin{tabular}{lcccccc}" _n
    file write itts "\toprule" _n
    file write itts "Take-up & \multicolumn{3}{c}{Reduced-form} & & \multicolumn{2}{c}{Treatment effects} \\"_n
        file write itts " & (1) & (2) & (3) & & (4) & (5) \\" _n
    file write itts "\midrule" _n
    file write itts "Public center             & `rf_beta_public'`rf_stars_public' &     &     & &     &     \\" _n
    file write itts "                          & (`rf_se_public') &     &     & &     &     \\" _n
    file write itts "                          &     &     &     & &     &     \\" _n
    file write itts "Private center            &     & `rf_beta_private'`rf_stars_private' &     & & `te_beta_private'`te_stars_private' &     \\" _n
    file write itts "                          &     & (`rf_se_private') &     & & (`te_se_private') &     \\" _n
    file write itts "                          &     &     &     & &     &     \\" _n
    file write itts "Home care/informal        &     &     & `rf_beta_home'`rf_stars_home' & &     & `te_beta_home'`te_stars_home' \\" _n
    file write itts "                          &     &     & (`rf_se_home') & &     & (`te_se_home') \\" _n
    file write itts "\midrule" _n
    file write itts "   N obs                  & `n_obs_public' & `n_obs_private' & `n_obs_home' & & `n_obs_private' & `n_obs_home' \\" _n
    
    file write itts "\bottomrule" _n
    file write itts "\end{tabular}" _n
file close itts


