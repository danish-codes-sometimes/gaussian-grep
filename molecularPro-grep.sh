#! /bin/bash
#clear
# This script used for greping molecular properties (Ehumo, Elumo, Ionisation energy, electron affinity, global hardness, electronic chemical potential) from gaussian output.
# usage: ./molecularP-grep.sh gaussian-output.log


infile=$1
# Check for multiple jobs and consider the last job for the analysis
lastjobstarts=$(grep -n "Proceeding to internal job step number" $infile | awk -F: 'END{print $1}');
if [ -z "$lastjobstarts" ]
then
        lastjobstarts=0
fi

#===============================================================================================================================================================
#   extract data
#===============================================================================================================================================================
Ehomo=`tail -n+$lastjobstarts $infile | grep "Alpha  occ. eigenvalues" | tail -1 | awk '{print $NF}'`  ; 
Elumo=`tail -n+$lastjobstarts $infile | grep "Alpha virt. eigenvalues" | head -n -1 | sed -n "1p" | awk '{print $5}'`  ; 

# convert componnets to standard representation
Ehomo=`echo ${Ehomo} | sed 's/D/\*10\^/' | sed 's/+//'`
Elumo=`echo ${Elumo} | sed 's/D/\*10\^/' | sed 's/+//'`


# au * 27.211396132 = eV
Ehomo=$(echo "scale=8; ($Ehomo)*(27.211396132)" | bc -l);
Elumo=$(echo "scale=8; ($Elumo)*(27.211396132)" | bc -l);

# HOMO-LUMO gap
gap=$(echo "scale=8; ($Elumo)-($Ehomo)" | bc -l);

# The Ionisation energy (E) and electron affinity (A) can be expressed in terms of HOMO and LUMO orbital energies as I = - E HOMO and A = - E LUMO
I=$(echo "scale=8; ($Ehomo)*(-1)" | bc -l);
A=$(echo "scale=8; ($Elumo)*(-1)" | bc -l);

# global hardness which is associated with the stability of the molecule (etha) can be expressed as η = 1 / 2(E LUMO – E HOMO )
etha=$(echo "scale=8; 0.5*(($Elumo)-($Ehomo))" | bc -l);

# electronic chemical potential (μ) in terms of electron affinity and ionization potential is given by μ = 1 / 2(E HOMO + E LUMO )

mu=$(echo "scale=8; 0.5*(($Elumo)+($Ehomo))" | bc -l);

# The global electrophilicity index, ω = (μ^2) / 2η
omega=$(echo "scale=8; (($mu)^2/(2*($etha)))" | bc -l);


#===============================================================================================================================================================
#   print extracted data
#===============================================================================================================================================================
printf  "outfile: %s\n Ehomo(eV) = %.4f\n Elumo(eV) = %.4f \n Eg(eV) = %.4f \n I = %.4f \n A = %.4f \n η = %.4f \n ω = %.4f \n μ = %.4f\n" $infile $Ehomo $Elumo $gap $I $A $etha $mu $omega

printf "\n"
echo "---in kcal/mol---"
Ehomo_kcm=$(echo "scale=8; ($Ehomo*23.0609)" | bc -l);
Elumo_kcm=$(echo "scale=8; ($Elumo*23.0609)" | bc -l);
gap_kcm=$(echo "scale=8; ($gap*23.0609)" | bc -l);

printf "Ehomo(kcal/mol) = %.4f\n Elumo(kcal/mol) = %.4f \n Eg(kcal/mol) = %.4f \n" $Ehomo_kcm $Elumo_kcm $gap_kcm

