seed = -1

seqfile = ../../input/YRI8_Altai.chrX.test100.phy
Imapfile = ../../input/YRI8_Altai.chrX.Imap.txt
jobname = msci_test

speciesdelimitation = 0
speciestree = 0

species&tree = 2 YRI Neanderthal
12 1
((YRI,Y[&phi=0.050000])X,(Neanderthal,X[&phi=0.050000])Y)R;

usedata = 1
nloci = 100
cleandata = 0

thetaprior = 3 0.002 e
tauprior = 3 0.002
phiprior = 1 1

finetune = 1
print = 1 0 0 0

burnin = 2000
sampfreq = 5
nsample = 5000

threads = 1
