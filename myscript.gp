set xlabel "time from start (s)"
set ylabel "count"
set autoscale
set term png size 1000, 800
set output "test.png"
plot "data.out" using 1:2 with lines title "πλήθος διεργασιών που ανήκουν στον Chromium", "data.out" using 1:3 with lines title "μέγιστο πλήθος threads", "data.out" using 1:4 with lines title "μέσο πλήθος threads ανά διεργασία", "data.out" using 1:5 with lines title "συνολ. κατανάλωση μνήμης(RSS) από όλες τις διεργασίες σε MB", "data.out" using 1:6 with lines title "μέγιστη κατανάλωση μνήμης (RSS) ανά διεργασία σε MB", "data.out" using 1:7 with lines title "μέσο πλήθος voluntary context switches ανά διεργασία", "data.out" using 1:8 with lines title "μέσο πλήθος non-voluntary context switches ανά διεργασία" 
