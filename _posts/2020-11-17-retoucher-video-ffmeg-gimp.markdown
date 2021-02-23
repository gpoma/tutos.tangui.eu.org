# Comment retoucher une vidéo grace à ffmepg et gimp

## 1/ Exporter la vidéo en jpeg 

    ffmpeg -i input.mp4 -qscale:v 2 output_%06d.jpg

## 2/ Retoucher les images voulues grace à gimp

    gimp output_00010*.jpg 

## 3/ Réordonner les images

    i=0; for file in output*jpg ; do  i=$((i+1)) ; printf "mv $file output_%08d ; \n" $i ; done  | sh

## 4/ Reconstituer la vidéo 

    ffmpeg -i output_%06d.jpg output.mp4

## 5/ Réincruster le son

    ffmpeg -i input.mp4 -vn -acodec copy output.aac
    ffmpeg -i output.mp4 -i output.aac output_final.mp3
