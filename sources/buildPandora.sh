#!/bin/sh

#FLAGS="-fversion=USE_GLES -fversion=PANDORA -frelease -c -O2 -pipe"
FLAGS="-fversion=PANDORA -frelease -fno-section-anchors -c -O2 -pipe"

rm import/*.o*
rm src/abagames/util/*.o*
rm src/abagames/util/bulletml/*.o*
rm src/abagames/util/sdl/*.o*
rm src/abagames/tf/*.o*

cd import
$PNDSDK/bin/pandora-gdc $FLAGS *.d
rm openglu.o*
cd ..

cd src/abagames/util
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../import -I../.. *.d
cd ../../..

cd src/abagames/util/bulletml
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../../import -I../../.. *.d
cd ../../../..

cd src/abagames/util/sdl
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../../import -I../../.. *.d
cd ../../../..

cd src/abagames/tf
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../import -I../.. *.d
cd ../../..

#$PNDSDK/bin/pandora-gdc -o TUMIKI_Fighters -s -Wl,-rpath-link,$PNDSDK/usr/lib -L$PNDSDK/usr/lib -lGL -lSDL_mixer -lmad -lSDL -lts import/*.o* src/abagames/util/*.o* src/abagames/util/bulletml/*.o* src/abagames/util/sdl/*.o* src/abagames/tf/*.o* lib/arm/libbulletml_d.a
$PNDSDK/bin/pandora-gdc -o TUMIKI_Fighters -s -Wl,-rpath-link,$PNDSDK/usr/lib -L$PNDSDK/usr/lib -lGL -lSDL_mixer -lmad -lSDL -lts -lbulletml_d -L./lib/arm import/*.o* src/abagames/util/*.o* src/abagames/util/bulletml/*.o* src/abagames/util/sdl/*.o* src/abagames/tf/*.o*
