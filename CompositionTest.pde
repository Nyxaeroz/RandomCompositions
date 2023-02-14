// parameters for image and preview size
int canvas_width;
int canvas_height;
int display_width;
int display_height;
boolean use_preview = false;

// parameters for color picking
Table table;
int total_palettes = 676;
int total_colors = 5;
int palette = floor(random(676));;

// parameters for generation
boolean generate_batch = false;
int fuzzyness = 5000000;
boolean use_rect = true;
float intersection_thold = 0.6;
  

// used for saving generated images
import java.io.File;
PGraphics toSave;

void setup() {
  //size(424,300);
  size(1754, 1240);
  canvas_width = 3508/2;
  canvas_height = 2480/2;
  display_width = 424/2;
  display_height = 300/2;
  
  table = loadTable("colors.csv", "csv, header");
  
  // for controlled batch generation:
  if (generate_batch) {
    for (int i = 0; i < 10; i++) {
      createComp();
      savePNG();
    }
  } else createComp();
  print(palette);
}

void draw() {
  
}

// automatic name generation, including palette and iteration number
void savePNG() {
    // loop to choose unique file name
    int i = 0;
    File new_comp;
    do {
      i++;
      new_comp = new File(sketchPath() + "/comps/composition-p" + palette + "-v" + i + ".png");
      println(sketchPath() + "/comps/composition-p" + palette + "-v" + i + ".png exists?" + new_comp.exists());
    } while (new_comp.exists());
    
    toSave.save(sketchPath() + "/comps/composition-p" + palette + "-v" + i + ".png"); 
}


void keyReleased() {
  if (key == 's') {
     savePNG();
  }
}

void createComp() {
PGraphics bg = createGraphics(canvas_width, canvas_height);
  bg.beginDraw();
  bg.background(get_color_from_palette(palette, 0));
  bg.endDraw();
  
  // number of layers under rectangle
  int layer_nr = floor(random(5, 11));
  
  //number of layers over rectangle
  int layer_nr_over = floor(random(3));
  
  PGraphics[] layers = new PGraphics[layer_nr + 1 + layer_nr_over];
  
  
  for (int i = 0; i < layer_nr; i++) {
    PGraphics new_layer;
    int layer_type = floor(random(2));
    int color_type = floor(random(4) + 1);
    switch (layer_type) {
      case 0: new_layer = line_layer(canvas_width, canvas_height, get_color_from_palette(palette, color_type));
      break;
      default: new_layer = circle_layer(canvas_width, canvas_height, get_color_from_palette(palette, color_type));
      break;
    }
    layers[i] = new_layer;
  }

  
  for (int i = layer_nr; i < layer_nr + 1 + layer_nr_over; i++) {
    PGraphics new_layer;
    int layer_type = floor(random(2));
    int color_type = floor(random(4) + 1);
    switch (layer_type) {
      case 0: new_layer = line_layer(canvas_width, canvas_height, get_color_from_palette(palette, color_type));
      break;
      default: new_layer = circle_layer(canvas_width, canvas_height, get_color_from_palette(palette, color_type));
      break;
    }
    layers[i] = new_layer;
  }
  
  
  PGraphics merged = createGraphics(canvas_width, canvas_height);
  merged.beginDraw();
  
  merged.image(bg, 0, 0, canvas_width, canvas_height);  
  
  for (int i = 0; i < layer_nr; i++) {
    merged.image(layers[i], 0, 0, canvas_width, canvas_height);
    if (i > 0 && random(1) < intersection_thold) {
      PGraphics intersect = intersection_layer(layers[i-1], layers[i], canvas_width, canvas_height, get_color_from_palette(palette, floor(random(5))));
      merged.image(intersect, 0, 0, canvas_width, canvas_height);  
    }
  }
  
  if (use_rect) {
    PGraphics rect = createGraphics(floor(0.9 * canvas_width), floor(0.9 * canvas_height));
    rect.beginDraw();
    rect.background(get_color_from_palette(palette, 0));
    rect.endDraw();
    layers[layer_nr] = rect;
  
    merged.image(rect, floor(0.05 * canvas_width), floor(0.05 * canvas_height), floor(0.9 * canvas_width), floor(0.9 * canvas_height));
  }
  
  for (int i = layer_nr + 1; i < layer_nr + 1 + layer_nr_over; i++) {
    merged.image(layers[i], 0, 0, canvas_width, canvas_height);
    if (i > 0 && random(1) < 0.6) {
      PGraphics intersect = intersection_layer(layers[i-1], layers[i], canvas_width, canvas_height, get_color_from_palette(palette, floor(random(5))));
      merged.image(intersect, 0, 0, canvas_width, canvas_height);  
    }
  
  }
  merged.endDraw();
  
  PGraphics fuzzy = stochastic_pointillism(merged, fuzzyness, 0, canvas_width, 0, canvas_height, 0);

  toSave = createGraphics(canvas_width, canvas_height);
  toSave.beginDraw();
  toSave.image(merged, 0, 0, canvas_width, canvas_height);
  toSave.image(fuzzy, 0, 0, canvas_width, canvas_height);
  toSave.endDraw(); 
  
  if (use_preview){
    image(merged, 0, 0, display_width, display_height);
    image(fuzzy, 0, 0, display_width, display_height);
  }
}

// get color from pallete
// if rcol < 0 or rcol > nr of colors in the palette, choose a random color from the palette
color get_color_from_palette(int palette, int rcol) {
  int col = rcol;
  if (rcol < 0 || rcol > total_colors) {
    col = floor(random(total_colors));
  }
  int r = table.getInt(palette, col * 3);
  int g = table.getInt(palette, col * 3 + 1);
  int b = table.getInt(palette, col * 3 + 2);
  return color(r,g,b);
}

// Rotate vector v with angle angle around rot_center
//   1. translate v so that rot_center coincides with the origin
//   2. rotate
//   3. translate back with rot_center
// Returns rotated vector
PVector rotate_vector(float angle, PVector v, PVector rot_center) {
  float new_v_x = (v.x - rot_center.x) * cos(angle) - (v.y - rot_center.y) * sin(angle) + rot_center.x;
  float new_v_y = (v.x - rot_center.x) * sin(angle) + (v.y - rot_center.y) * cos(angle) + rot_center.y;

  return new PVector(new_v_x, new_v_y);
}

// create a layer with a random number of lines with a random angle
PGraphics line_layer(int xdim, int ydim, color c) {
  PGraphics layer = createGraphics(xdim, ydim);

  float angle = random(-.5, .5) * PI;
  int nr = int(random(1, 6));

  // calculate 'reference line'
  int y = int(random(0, ydim));
  PVector q1 = new PVector(-xdim, y);
  PVector q2 = new PVector(2*xdim, y);
  PVector center = new PVector(random(0, xdim), y);

  // corners of rotated line
  PVector p1 = rotate_vector(angle, q1, center);
  PVector p2 = rotate_vector(angle, q2, center);

  // draw nr many lines
  float offset = 0;
  for (int i = 0; i < nr; i++) {
    int stroke = int(random(5, 30));
    offset += .5 * stroke;
    layer.beginDraw();
    layer.noStroke();
    layer.beginShape();
    layer.fill(c);
    layer.vertex(p1.x + offset, p1.y);
    layer.vertex(p2.x + offset, p2.y);
    layer.vertex(p2.x + stroke + offset, p2.y);
    layer.vertex(p1.x + stroke + offset, p1.y);
    layer.endShape(CLOSE);
    layer.endDraw();

    offset += 1.5 * stroke;
  }

  print("Line layer angle:", angle, ", offset:", offset, ", nr:", nr, "\n");

  return layer;
}

// return layer of dimension w*h with color c that is the the intersection of layer1 and layer2
PGraphics intersection_layer(PGraphics layer1, PGraphics layer2, int w, int h, color c) {

  PGraphics intersect_mask = createGraphics(w, h);
  PGraphics intersect = createGraphics(w, h);

  PGraphics copy = createGraphics(w, h);
  copy.beginDraw();
  copy.loadPixels();
  arrayCopy(layer1.pixels, copy.pixels);
  copy.updatePixels();
  copy.endDraw();

  copy.beginDraw();
  copy.mask(layer2);
  copy.endDraw();

  intersect_mask.beginDraw();
  intersect_mask.background(0);
  intersect_mask.image(copy, 0, 0);
  intersect_mask.loadPixels();
  for (int i = 0; i < canvas_width * canvas_height; i++) {
    if (intersect_mask.pixels[i] != color(0,0,0)) {
      intersect_mask.pixels[i] = 255;
    }
  }
  intersect_mask.updatePixels();
  intersect_mask.endDraw();

  intersect.beginDraw();
  intersect.background(c);
  intersect.mask(intersect_mask);
  intersect.endDraw();

  return intersect;
}

// create a layer with a random number of randomly sized circles
// size inversely correlated to nr of circles
PGraphics circle_layer(int xdim, int ydim, color c) {
  PGraphics circles = createGraphics(canvas_width, canvas_height);
  float nr = random(3,10);
  float radius_mean = map(nr, 3, 10, 200, 20);
  circles.beginDraw();
  for (int i = 0; i < nr; i++) {
    circles.fill(c);
    circles.noStroke();
    circles.circle(random(0, canvas_width), random(0, canvas_height), randomGaussian() * radius_mean);
  }
  circles.endDraw();
  return circles;
}

// apply pointillism on a layer base_layer to create texture, using density nr of points, within the xymin/max bounds using an offset
PGraphics stochastic_pointillism(PGraphics base_layer,
                           int density, 
                           float rxmin, 
                           float rxmax, 
                           float rymin, 
                           float rymax, 
                           int offset){
  PGraphics layer = createGraphics(int(rxmax - rxmin), int(rymax - rymin));
                             
  int variation;
  float rx,ry;
  int pix;
  float r,g,b;
  image(base_layer, 0, 0, int(rxmax - rxmin), int(rymax - rymin));
  
  layer.beginDraw();
  for(int i = 0; i <= density; i++) {
    rx = random(rxmin-offset,rxmax+1+offset);
    ry = random(rymin-offset,rymax+1+offset);
    pix = get(int(rx),int(ry));
    r = red(pix);
    g = green(pix);
    b = blue(pix);
    
    layer.strokeCap(ROUND);
    variation=int(random(1,4));
    switch(variation){
      case 1:
      layer.stroke(r-10,g-10,b-10);
      break;
      case 2:
      layer.stroke(r-5,g-5,b-5);
      break;
      case 3:
      layer.stroke(r-random(1,6),g-random(1,6),b-random(1,6));
      break;
    }
    layer.strokeWeight(2);
    layer.point(rx,ry);
  }
 layer.endDraw();
 
 return layer;
}
