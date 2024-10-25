************************************************************************************************************************************************************
*This command, under development, estimates the so-called WAOSS in <<de Chaisemartin, Clément, Xavier D'Haultfoeuille, Félix Pasquier, and Gonzalo Vazquez-Bare. 2023. "Difference-in-differences estimators for treatments continuously distributed at every period." arXiv preprint arXiv:2201.06898>>, in a particular continuous DID design (in <<Difference-in-Differences Estimators with Continuous Treatments and no Stayers, Clément de Chaisemartin, Xavier D'Haultfoeuille and Gonzalo Vazquez-Bare, (2023)>>) where from period 1 to 2 all the units change treatment status (NO STAYERS).

*Note: For any questions or suggestions about options to include in the upcoming STATA command of this version, please contact the authors.
*************************************************************************************************************************************************************
capture program drop did_continuous_nostayers
program did_continuous_nostayers, eclass
	version 12.0
	syntax varlist(min=4 max=4 numeric) [if] [in] [, weight(varlist numeric) ]
	
	preserve
quietly{
//tokenize the varlist
tokenize `varlist'

//dropping observations not included in the if condition
	if "`if'" !=""{
	keep `if'
	}
// dropping observations not included in the in condition
	if "`in'" !=""{
	keep `in'
	} 
	
//rename varlist
cap drop Y_XX
cap drop D_XX
cap drop T_XX
cap drop ID_XX

gen Y_XX = `1'
gen ID_XX =  `2'
egen T_XX =  group(`3')
gen D_XX = `4'

//Weight option
gen weight_XX = 1
if ("`weight'"!=""){
	replace weight_XX = `weight'
}

**# Bookmark #1: Format the data
xtset ID_XX T_XX

//Generate delta = D_2 - D_1
sort ID_XX T_XX
bysort ID_XX : gen deltaD_XX = D.D_XX
///>put it at the same level of D_1
bysort ID_XX: egen delta_temp = mean(deltaD_XX)
drop deltaD_XX
rename delta_temp deltaD_XX

//Generate deltaY = Y_2 - Y_1
bysort ID_XX: gen deltaY_XX = D.Y_XX
///>put it  at the same level of D_1
bysort ID_XX: egen delta_temp = mean(deltaY_XX)
drop deltaY_XX
rename delta_temp deltaY_XX

//We have all the variable we need at the first year so we can drop the second year line
quietly drop if T_XX == 2
rename  D_XX D1_XX

sum weight_XX
scalar W_XX = r(sum)
scalar N_XX = _N

**# Bookmark #2 Estimate \widehat{\lambda}
//quietly 
reg deltaY_XX D1_XX deltaD_XX c.D1_XX#c.deltaD_XX c.deltaD_XX#c.deltaD_XX [aweight=weight_XX]

predict predicted_XX, xb  
gen eps_XX = deltaY_XX - predicted_XX
matrix b_XX =e(b)'
**# Bookmark #3 Computation of \theta
gen signdeltaD_XX = (deltaD_XX>0) -(deltaD_XX<0) 
mkmat deltaY_XX, mat(deltaY_XX)
mkmat D1_XX, mat(D1_XX)
gen const_XX = 1
mkmat const_XX, mat(const_XX)
matrix num_theta_XX = deltaY_XX - b_XX[5..5,1...]*const_XX - b_XX[1..1,1...]*D1_XX

svmat num_theta_XX
rename num_theta_XX1 num_theta_XX
replace num_theta_XX = signdeltaD_XX*num_theta_XX
gen num_theta_wXX = num_theta_XX*weight_XX //weight option

sum num_theta_wXX
scalar exp_num_theta_XX = r(sum)
gen abs_deltaD_XX = signdeltaD_XX*deltaD_XX
gen abs_deltaD_wXX = abs_deltaD_XX*weight_XX //weight option
sum abs_deltaD_wXX
scalar denom_theta_XX = r(sum)

scalar theta_XX = scalar(exp_num_theta_XX)/scalar(denom_theta_XX)

//di scalar(theta_XX)
ereturn scalar theta_XX = theta_XX

**# Bookmark #4 Variance of theta

///>Computation of the Influence Function

//generate sqrt(w)*u
gen X2_XX = sqrt(weight_XX)*D1_XX*deltaD_XX
gen X3_XX = sqrt(weight_XX)*deltaD_XX*deltaD_XX
gen sqrt_weight_XX = sqrt(weight_XX)
gen D1_wXX = sqrt(weight_XX)*D1_XX
gen deltaD_wXX = sqrt(weight_XX)*deltaD_XX

matrix accum Xcross_XX = sqrt_weight_XX D1_wXX deltaD_wXX X2_XX X3_XX , noconstant //because the const now represents my sqrt_weight_XX due to the weight option

matrix Q_XX = invsym(Xcross_XX)

//Generate w*u
gen X2_wXX = weight_XX*D1_XX*deltaD_XX
gen X3_wXX = weight_XX*deltaD_XX*deltaD_XX
gen D1_w2XX = weight_XX*D1_XX
gen deltaD_w2XX = weight_XX*deltaD_XX


mkmat  weight_XX D1_w2XX deltaD_w2XX X2_wXX X3_wXX , mat(u_XX)
matrix ut_XX = u_XX'

//matrix IF = Q*ut*predicted
matrix Qut_XX = (Q_XX*ut_XX)'
svmat Qut_XX

forvalues i=1/5{
gen IF`i'_XX = Qut_XX`i'*eps_XX*scalar(N_XX) //instead of scalar(W_XX)
}

//Compute the partial derivative : sgn(deltaD)*deriv(g)(D1,0)
gen derivg_alph0_XX = const_XX
gen derivg_alph1_XX = D1_XX
gen deriv0_XX = signdeltaD_XX*derivg_alph0_XX*weight_XX
sum deriv0_XX
scalar exp_deriv0_XX =r(sum)/scalar(W_XX)

gen deriv1_XX = signdeltaD_XX*derivg_alph1_XX*weight_XX
sum deriv1_XX
scalar exp_deriv1_XX = r(sum)/scalar(W_XX)

gen Expderiv_IF_XX = scalar(exp_deriv0_XX)*IF1_XX + scalar(exp_deriv1_XX)*IF2_XX

scalar E_w_denom_theta_XX = scalar(denom_theta_XX)/scalar(W_XX)

gen Phi_XX = (num_theta_XX - Expderiv_IF_XX -scalar(theta_XX)*abs_deltaD_XX)/scalar(E_w_denom_theta_XX)

gen Phi_wXX = weight_XX*Phi_XX //weight option
sum Phi_wXX
scalar E_w_Phi_XX = r(sum)/scalar(W_XX)

//demeaning Phi_XX, taking the square and weighting it //weight option
replace Phi_XX = Phi_XX - scalar(E_w_Phi_XX)
replace Phi_XX = Phi_XX*Phi_XX
replace Phi_XX = Phi_XX*weight_XX
sum Phi_XX

scalar var_theta_XX = r(mean)/scalar(W_XX) 
scalar sd_theta_XX = sqrt(scalar(var_theta_XX))
scalar LB_XX = scalar(theta_XX) - 1.96*scalar(sd_theta_XX)
scalar UB_XX = scalar(theta_XX) + 1.96*scalar(sd_theta_XX)


ereturn scalar sd_theta_XX = sd_theta_XX
}
**# Bookmark #5 Output display

matrix res_mat_XX = J(1,4,.) 

matrix res_mat_XX[1,1] = theta_XX
matrix res_mat_XX[1,2] = sd_theta_XX
matrix res_mat_XX[1,3] = LB_XX
matrix res_mat_XX[1,4] = UB_XX

matrix rownames res_mat_XX= "WAOSS"
matrix colnames res_mat_XX= "Estimate" "SE" "LB CI" "UB CI" 

display _newline
di as input "{hline 60}"
di as input _skip(20) "Estimation of the WAOSS"
di as input "{hline 60}"
noisily matlist res_mat_XX
di as input "{hline 60}"
restore
	end
