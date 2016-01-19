#!/bin/bash

# This script select the corresponding file of the Spanish MDT.
# Usually two files are present, LIDAR and non LIDAR version for the same tile.
# We will select the LIDAR version if avaliable and output to a destination folder.
# Joaquín Escayo @ j.escayo@csic.es
# v 1.0 (19-01-2016)

DESTINATION=Peninsula
DIR=$(pwd)
OUT=$DIR/$DESTINATION
#Type of MDT (05 meters or 25 meters)
MDT=25

# MDT has 1111 sheets (check MTN50 map). Not every sheet exists.
# Sheets that doesn't exist: 4,5,16,17,19,42,499,524,548,549,797,
# Sheet 1105 has an special name: MDTXX-1105-1108.zip
# Attention! Check file extension of original IGN files, some zip files has spaces in the extension. (WTF?!)
for i in {0001..1111}
do
	LIDAR=MDT$MDT-$i-LIDAR.zip
	LIDARB=MDT$MDT-${i}B-LIDAR.zip
	NOLIDAR=MDT$MDT-$i.zip
	NOLIDARB=MDT$MDT-${i}B.zip
	
	# Select LIDAR file if exists:
	if [ -f $LIDAR ]
	then
		echo "Lidar version for $i exists"
		cp $LIDAR $OUT
	elif [ -f $NOLIDAR ]
	then
		echo "NON LIDAR version for $i exists"
		cp $NOLIDAR $OUT
	else
		echo "ERROR, NO FILE EXISTS FOR $i"
	fi
	# Testing if there is any B file for selected tile. Not every tile has B file.
	if [ -f $LIDARB ]
	then
		echo "LIDARB version for $i exists"
		cp $LIDARB $OUT
	elif [ -f $NOLIDARB ]
	then
		echo "NOLIDARB version for $i exists"
		cp $NOLIDARB $OUT
	else
		echo "NO B FILE FOR $i"
	fi
	# Special cases (sheet 1105)
	if [ $i == 1105 ]
	then
		cp MDT$MDT-1105-1108-LIDAR.zip $OUT
	fi
done
