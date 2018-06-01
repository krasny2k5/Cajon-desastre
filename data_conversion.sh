#!/bin/bash
# This script convert a bunch of Geotif files into Ascii column files. It is used to introduce the data into PAF program.
# Joaquin Escayo @ 2018
# j.escayo@csic.es

mkdir temp
TEMPDIR=$(pwd)/temp
DEM=$(pwd)/DEM/dem_italia_filled.tif

# Remap DEM for nodata=0 and no no_data values. https://trac.osgeo.org/gdal/ticket/3880
#gdalwarp src.tif src_nodata_remapped.tif -dstnodata 0
#gdal_translate src_nodata_remapped.tif src_remapped.tif -a_nodata none
#gdaldem src_remapped.tif

gdaltindex $TEMPDIR/clip.shp MSBAS_20100728T170946_UD.bin.geo.tif
gdalwarp -ot float32 -t_srs EPSG:32633 -overwrite -dstnodata -9999 -cutline $TEMPDIR/clip.shp -crop_to_cutline $DEM $TEMPDIR/DEM_clipped.tif
gdalwarp -ot float32 -tr 500 500 -overwrite -dstnodata -9999 -r average $TEMPDIR/DEM_clipped.tif $TEMPDIR/DEM_clipped_resampled.tif

DEM_CLIPPED=$TEMPDIR/DEM_clipped.tif
DEM_CLI_RES=$TEMPDIR/DEM_clipped_resampled.tif

# filelist creation
ls *.tif > file_list.txt

# Conversion to UTM, source EPSG:4326 (latlong) destination EPSG:32633

mkdir UTM

for i in *.tif; do
echo ""
gdalwarp -s_srs EPSG:4326 -srcnodata 0 -t_srs EPSG:32633 -dstnodata -9999 $i UTM/$i 
done

mkdir UTM_resampled_average

for i in $(ls UTM/*.tif); do
echo ""
#gdalwarp -tr 500 500 -r average -dstnodata -9999 $i UTM_resampled_average/$(basename $i)
done

mkdir UTM_resampled_mode

for i in $(ls UTM/*.tif); do
echo ""
gdalwarp -tr 500 500 -r mode -dstnodata -9999 $i UTM_resampled_mode/$(basename $i)
done

for u in UTM_resampled_average UTM_resampled_mode; do
cd $u
for i in *_EW*.tif; do
echo "Archivo EW: $i"
UD=$(echo $i | sed 's/EW/UD/g')
echo "Archivo UD: $UD"
gdal_merge.py -a_nodata -9999 -separate $DEM_CLI_RES $UD $i -o $(echo $i | sed 's/_EW/_3b/g')
done

for i in *_3b*; do
gdal2xyz.py -band 1 -band 2 -band 3 $i $(echo $i | sed 's/tif/txt/g')
done

for i in *.txt; do
echo "processing $i"
sed -i '/-9999/d' $i
#awk '{printf "%.0f %.0f %.0f %.3f %.3f\n", $1, $2, $3, $4, $5}' $i > tmp && mv tmp $i     
#awk '{print $1, $2, $3, "0", "0", $4, "1", $5, "1", "0", "1"}' $i > $(echo $i | sed 's/.txt/_antonio.txt/g')
#New method, only one order:
awk '{printf "%.0f %.0f %.0f %.0f %.0f %.3f %.0f %.3f %.0f %.0f %.0f\n", $1, $2, $3,"0", "0",  $4, "1", $5, "1", "0", "1"}' $i > tmp && mv tmp $i
done

cd ..
done

#UTM lo hacemos diferente (DEM DIFERENTE)

cd UTM
for i in *_EW*.tif; do
echo "Archivo EW: $i"
UD=$(echo $i | sed 's/EW/UD/g')
echo "Archivo UD: $UD"
gdal_merge.py -a_nodata -9999 -separate $DEM_CLIPPED $UD $i -o $(echo $i | sed 's/_EW/_3b/g')
done

for i in *_3b*; do
gdal2xyz.py -band 1 -band 2 -band 3 $i $(echo $i | sed 's/tif/txt/g')
done

for i in *.txt; do
sed -i '/-9999/d' $i
awk '{printf "%.0f %.0f %.0f %.0f %.0f %.3f %.0f %.3f %.0f %.0f %.0f\n", $1, $2, $3,"0", "0",  $4, "1", $5, "1", "0", "1"}' $i > tmp && mv tmp $i
done
