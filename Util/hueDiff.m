<<<<<<< HEAD
function hdiff = hueDiff(h1,h2)

h1 = h1 * 2 * pi;
h2 = h2 * 2 * pi;

hdiff = abs(wrapToPi(h1 - h2));
hdiff = hdiff / (2*pi);
=======
function hdiff = hueDiff(hue1,hue2)

hue1_angle = hue1 * 2 * pi;
hue2_angle = hue2 * 2 * pi;

hdiff_angle = hue1_angle - hue2_angle;

hdiff = wrapToPi(hdiff_angle) / (2*pi);
>>>>>>> origin/master
