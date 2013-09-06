# README


Put your viaf XML authority files here. (VIAF Terms). You can download them at: http://viaf.org/viaf/data/ . 

## Pre-processing
Be aware that you will have to pre-process the data dump before storing as it is no wellformed xml.

Steps to cleanup data:
 + remove text represantation of viafID in front of each ns2:VIAFCluster element
 + remove whitspace before and after each ns2:VIAFCluster element
 + add a <ns2:VIAFClusters xmlns:ns2="http://viaf.org/viaf/terms#"> root-element wrapping the all VIAFCluster

