#!/bin/bash
clear 

#Μουστάκας Αριστείδης AEM: 2380
#Γιώργος Τσανακτσίδης ΑΕΜ: 2418
#Παναγιώτης Μαρουλίδης ΑΕΜ: 2431


# Κατα την διάρκεια της συλλογής των στατιστικών,  πηγαίνοντας να υπολογίσουμε τα στατιστικά κάποιων απ αυτές παρατηρήσαμε ότι παρότι πριν πάμε να προσπελάσουμε το αρχείο proc κάποιας διεργασίας ελέγχουμε αν εκέινη εκτελείται ακόμα , εκέινη τερματίζει (είτε από το προγραμμα είτε μόνης της) αμέσως αφού περάσει τον έλεγχο και έτσι ίσως εμφανιστουν κάποια μηνύματα ότι πάμε να προσπελάσουμε το αρχείο proc μιας διεργασίας η οποία δεν υπάρχει. Αυτό δεν επηρεάζει την συλλογή των στατιστικών καθώς έχουμε βάλει ελέγχους που τσεκάρουν πριν χρησιμοποιήσουν την θέση του πίνακα του περιέχει τα αντίστοιχα στατιστικά της διεργασίας και αν αυτή η θέση είναι άδεια (δηλαδή η διεργασία τερματισε) δεν την συμπεριλαμβανουν υπόψιν. 


#Σκοτώνει όλες τις διεργασίες του chormium και ανοιγει ένα νέο παράθυρο Chromium.
openChromium()
{
killall chromium-browser
chromium-browser &
sleep 5
}



#Ανοιγουν ένα ένα τα καινουρια tabs με καθυστέρηση 5 δευτερολέπτων διαβάζοντας απο το αρχείο url.in .
openURLS()
{
while read line;
do
    chromium-browser --new-tab "$line" &
     sleep 5
done < url.in
sleep 10
}



#Σκοτώνει την πιο πρόσφατη διεργασία του chromium.
killLatest()
{
sleep 5
declare myarr=("${!1}")
kill -9 ${myarr[-1]} &> /dev/null

}



# η killer δημιουργεί εναν πίνακα με τις διεργσίες του chromium και όσο δεν είναι άδειος καλώ την  killLatest για να σκοτώσει την πιο πρόσφατη διεργσία.
killer()
{
arrlen2=1
while [[ $arrlen2 -gt  0 ]]
do
# στο myarr μπαίνουν όλες οι διεργασίες του chromium ταξινομημένες από την πρώτη προς την τελευταία (με βάση το χρόνο)
# με τη χρήση του --sort start_time
myarr=($( ps -eo pid,comm,etime --sort start_time | grep chromium-browse | awk '{print $1}')) 
arrlen2=${#myarr[@]}

if [[ $arrlen2 -gt  0 ]]; 
then killLatest myarr[@]
fi

done
}

#εκτυπώνει στο data.out έναν πίνακα 8 θέσεων με στατιστικά για τις διεργασιες του chormium μια συγκεκριμένη χρονική στιγμή.
statistics()
{
#Αρχικά, στον πίνακα all_proc βάζω τα pids των διεργασιών του chromium και έτσι υπολογίζω πόσες διεργασίες έχει ο chromium και το αποθηκεύω στην 2η θέση του πίνακα final_arr
declare xronos1=("${!1}") 
all_proc=($( ps -eo pid,comm,etime --sort start_time | grep chromium-browse | awk '{print $1}'))
numOfProc=${#all_proc[@]}    
i=0
final_arr[1]=$numOfProc

#Βρίσκω πόσα threads χρησιμοποιεί κάθε διεργασία του chromium, έπειτα βρίσκω την διεργασία με τον μεγαλύτερο αριθμό threads και τον μέσο όρο threads και τα αποθηκεύω στην 3η και 4η θέση αντιστοίχως   
while [[ $numOfProc -gt $i ]];   
do
file="/proc/${all_proc[i]}/status">/dev/null #έλεγχος αν υπάρχει ακόμα αρχείο prοc για την συγκεκριμένη διεργασία ή αυτή έχει τερματίσει.
if [ -f $file ]; 
then
numOfTreads[i]=$(cat /proc/${all_proc[i]}/status | grep Threads | awk '{print $2}' )>/dev/null #παίρνω στοιχεία για τα threads που χρησιμοποιεί κάθε διεργασία του chromium .
fi 
i=$(( $i + 1))
done

sum=0
j=0
max=-1		
while [[ $numOfProc -gt $j ]];  # Αυτό το while βρίσκει την διεργασία του chromium που χρησιμοποιεί τα περισσότερα threads.
do
wq=${numOfTreads[j]}
if [ -n "$wq" ] # κοιτάει αν η μεταβλητή δεν είναι άδεια
then
sum=$(( $sum + ${numOfTreads[j]} ))
if [ ${numOfTreads[j]} -gt $max ]
	then max=${numOfTreads[j]}
fi
fi
j=$(( $j + 1))
done
if [ $numOfProc -gt 0 ]
then
mo=$(echo "scale=2;$sum / $numOfProc" | bc)
else
mo=0
fi
final_arr[2]=$max
final_arr[3]=$mo

#Βρίσκω το RSS κάθε διεργασίας και τα αποθηκεύω στον πίνακα RSS_array, έπειτα την συνολική κατανάλωση μνήμης και την μέγιστη κατανάλωση μνήμης ανά διεργασία και τα αποθηκεύω στην 5η και 6η θέση αντίστοιχα του πίνακα final_arr.
RSS_array=($( ps -C chromium-browser -O rss | awk '{print $2}')) #πίνακας me Rss διεργασιών
j=1
sumRSS=0
maxRss=-1;
while [[ $numOfProc -ge $j ]]; 
do
za=${RSS_array[j]}
if [ -n "$za" ]  # κοιτάει αν η μεταβλητή δεν είναι άδεια
then
sumRSS=$(( $sumRSS + ${RSS_array[j]} ))
if [ ${RSS_array[j]} -gt $maxRss ]
	then maxRss=${RSS_array[j]}
fi
fi
j=$(( $j + 1))
done

sumRSS_MB=$(echo "scale=2;$sumRSS / 1024" | bc) #μετατροπή σε MB
maxRss=$(echo "scale=2;$maxRss / 1024" | bc) #μετατροπή σε MB
final_arr[4]=$sumRSS_MB
final_arr[5]=$maxRss


#Υπολογίζω το voluntary context switches κάθε διεργασίας του chromium και μετά τον μέσο αριθμό voluntar context switches και τον αποθηκεύω στην 7η θέση του πίνακα.
i=0
while [[ $numOfProc -gt $i ]];   
do
file="/proc/${all_proc[i]}/status" #έλεγχος αν υπάρχει ακόμα αρχείο prοc για την συγκεκριμένη διεργασία ή αυτή έχει τερματίσει.
if [ -f $file ]; 
then
numOfVolConSw[i]=$(cat /proc/${all_proc[i]}/status | grep voluntary_ctxt_switches | grep -v non| awk '{print $2}' ) #δημιουργώ έναν πίνακα που περιεχει το voluntary_ctxt_switches κάθε διεργασίας του chromium. 
fi 
i=$(( $i + 1))
done 
j=0
sum_vol=0
while [[ $numOfProc -gt $j ]];   
do
ww=${numOfVolConSw[j]}
if [ -n "$ww" ]  # κοιτάει αν η μεταβλητή δεν είναι άδεια
then
sum_vol=$(( $sum_vol + ${numOfVolConSw[j]} ))
fi
j=$(( $j + 1))
done
if [ $numOfProc -gt 0 ]
then
mo_vol=$(echo "scale=2;$sum_vol / $numOfProc" | bc)
else
mo_vol=0
fi
final_arr[6]=$mo_vol

#Υπολογίζω το nonvoluntary context switches κάθε διεργασίας του chromium και μετά τον μέσο αριθμό nonvoluntar context switches και τον αποθηκεύω στην 8η θέση του πίνακα
i=0
while [[ $numOfProc -gt $i ]];   
do
file="/proc/${all_proc[i]}/status" #έλεγχος αν υπάρχει ακόμα αρχείο prοc για την συγκεκριμένη διεργασία ή αυτή έχει τερματίσει.
if [ -f $file ];
then
numOfNonVolConSw[i]=$(cat /proc/${all_proc[i]}/status | grep nonvoluntary_ctxt_switches | awk '{print $2}' ) #δημιουργώ έναν πίνακα που περιεχει το nonvoluntary_ctxt_switches κάθε διεργασίας του chromium. 
fi 
i=$(( $i + 1))
done
j=0
sum_nonvol=0
while [[ $numOfProc -gt $j ]];   
do
zz=${numOfNonVolConSw[j]}
if [ -n "$zz" ]  # κοιτάει αν η μεταβλητή δεν είναι άδεια.
then
sum_nonvol=$(( $sum_nonvol + ${numOfNonVolConSw[j]} ))
fi
j=$(( $j + 1))
done
if [ $numOfProc -gt 0 ]
then
mo_nonvol=$(echo "scale=2;$sum_nonvol / $numOfProc" | bc)
else
mo_nonvol=0
fi
final_arr[7]=$mo_nonvol


#Στην πρώτη θέση του πίνακα έχουμε τον χρόνο που υπολογίζεται το κάθε σετ στατιστικών.
final_arr[0]=$xronos1
echo ${final_arr[*]} >> data.out
}

#τρέχει στο παρασκήνιο, καλέι κάθε 0,5 sec και όσο υπάρχουν διεργασίες του chromium την statistics η οποία συλλέγει κάποια στατιστικά για εκείνη την χρονικλη στιγμη
statscaller()
{
number_proc=1
xronos1=0
 > data.out #σβήνω ότι υπάρχει στο data.out
while [[ $number_proc -gt  0 ]]
do
# στο process_arr μπαίνουν όλες οι διεργασίες του chromium ταξινομημένες από την πρώτη προς την τελευταία (με βάση το χρόνο)
# με τη χρήση του --sort start_time
process_arr=($( ps -eo pid,comm,etime --sort start_time | grep chromium-browse | awk '{print $1}'))
number_proc=${#process_arr[@]}
if [[ $number_proc -gt  0 ]];
then statistics xronos1 & sleep 0.5
fi
xronos1=$(echo "scale=1;$xronos1 + 0.5" | bc)
done
}



openChromium &> /dev/null
statscaller &
openURLS &> /dev/null
sleep 30
killer &> /dev/null
gnuplot myscript.gp
