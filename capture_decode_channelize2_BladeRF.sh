#!/bin/bash

#
# Add only the CA (Cell Allocation) according to SI type 1
#
CONFIGURATION="0B"
CA=""
C0=""
MA="0"
MAIO=0
HSN=0
KEY="00 00 00 00 00 00 00 00"
NSAMPLES=256000000

#############################################################

for x in $CA
do
  CA_FILES="$CA_FILES out/out_$x.cf"
done

minARFCN=`echo $CA | awk '{print $1}'`
maxARFCN=`echo $CA | awk '{print $NF}'`
c0POS=`echo $CA | awk -vchan=$C0 '{for(i=1;i<=NF;i++) if($i==chan)print (i-1)}'`
if [ x$c0POS == x ]
then
  echo "The main channel cannot be found in CA"
  exit
fi

ARFCN_fc=$((($maxARFCN+$minARFCN)/2))

if [ $ARFCN_fc -gt 125 ]
then
  FC=$((1805200000 + 200000*$(($ARFCN_fc-512))))
else
  FC=$((935000000 + 200000*$ARFCN_fc))
fi

BW=$((($maxARFCN-$minARFCN+1)*200))

if [ $BW -gt 10000 ]
then
  SR=19200000
  NCHANNELS=96
  pfbDECIM=16
  totDECIM=32
elif [ $BW -gt 200 ]
then
  SR=9600000
  NCHANNELS=48
  pfbDECIM=16
  totDECIM=64
elif [ $BW -eq 200 ]
then
  SR=1200000
  NCHANNELS=1
  pfbDECIM=1
  totDECIM=32
fi

echo "min_ARFCN: $minARFCN"
echo "max_ARFCN: $maxARFCN"
echo "Center ARFCN: "$ARFCN_fc
echo "Center frequency: $FC"khz
echo "Sampling rate: $SR" 
echo "Number of samples: $NSAMPLES"
echo "CA files: $CA_FILES"
echo "C0 ARFCN: $C0"
echo "C0 position: $c0POS"
echo "SR: $SR"
echo "BW: $BW"
echo "NCHANNELS: $NCHANNELS"
echo "pfbDECIM: $pfbDECIM"
echo "totDECIM: $totDECIM"

if [ $CONFIGURATION == "0B" ]
then
	echo "***	Fase 1: Captura:"
	echo "		"
	bladeRF-cli -e "set frequency rx $FC" -e "set samplerate rx $SR" -e 'set bandwidth rx 10M' -e 'set lnagain 6' -e 'set rxvga1 15' -e 'set rxvga2 3' -e "rx config file=/tmp/arfcn111.sc16q11 format=bin n=$NSAMPLES" -e 'rx start' -e 'rx' -e  'rx wait'
	echo 
	echo "***	Fase 1/2: conviertoformato..."
	/opt/bladeRF/converter_cfile /tmp/arfcn111.sc16q11 ./out/out.cf
	echo

	echo "***	Fase 2: Filtro Polifasico"
	echo "		./channelize2.py --inputfile='out/out.cf' --arfcn='$ARFCN_fc' --srate='$SR' --decimation='$pfbDECIM' --nchannels='$NCHANNELS' --nsamples=$NSAMPLES"
 	./channelize2.py --inputfile="out/out.cf" --arfcn="$ARFCN_fc" --srate="$SR" --decimation="$pfbDECIM" --nchannels="$NCHANNELS" --nsamples=$NSAMPLES
	echo

	echo "***	Fase 3: Decodificar:"
	
	echo "		./gsm_receiveBladeRF38.4_channelize.py -d '$totDECIM' -c '$CONFIGURATION' -k '$KEY' --c0pos $c0POS --ma '$MA' --maio $MAIO --hsn $HSN --inputfiles '$CA_FILES'"
	./gsm_receiveBladeRF38.4_channelize.py -d "$totDECIM" -c "$CONFIGURATION" -k "$KEY" --c0pos $c0POS --ma "$MA" --maio $MAIO --hsn $HSN --inputfiles "$CA_FILES"
	echo

else
	echo "		./gsm_receiveBladeRF38.4_channelize.py -d '$totDECIM' -c '$CONFIGURATION' -k '$KEY' --c0pos $c0POS --ma '$MA' --maio $MAIO --hsn $HSN --inputfiles '$CA_FILES'"
	./gsm_receiveBladeRF38.4_channelize.py -d "$totDECIM" -c "$CONFIGURATION" -k "$KEY" --c0pos $c0POS --ma "$MA" --maio $MAIO --hsn $HSN --inputfiles "$CA_FILES"
fi

