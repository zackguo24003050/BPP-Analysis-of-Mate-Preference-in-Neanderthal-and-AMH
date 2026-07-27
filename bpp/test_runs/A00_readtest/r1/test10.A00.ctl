seed = -1

seqfile = ../../input/YRI8_Altai.chrX.test10.phy
Imapfile = ../../input/YRI8_Altai.chrX.Imap.txt
jobname = out

speciesdelimitation = 0
speciestree = 0

species&tree = 2 YRI Neanderthal
12 1
(YRI, Neanderthal);

usedata = 1
nloci = 10
cleandata = 0

thetaprior = 3 0.002 e
tauprior = 3 0.002

finetune = 1

print = 1 0 0 0
burnin = 1000
sampfreq = 2
nsample = 2000

threads = 1 1 1
