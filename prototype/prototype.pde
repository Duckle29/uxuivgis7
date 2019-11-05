import processing.sound.*;
SinOsc sine;

int window_width = 600;
int window_height = 400;

//User Interface
color button_color = color(255,0,0);
int button_diameter = 50;
int button_pos[] = new int[2];
int eta_pos[]  = new int[2];
int etas_pos[]  = new int[2];
int d1_string_pos[] = new int[2];
int d2_string_pos[] = new int[2];
int d3_string_pos[] = new int[2];
int d4_string_pos[] = new int[2];
int delta_time_pos[] = new int[2];
HScrollbar angle_scrollbar;
PImage boat_image;


color idle_color        = color(255);
color highlight_color   = color(204);

//Simulation physical parameters
float distance_to_start = 0.0f;
float eta = 0.0f;
float distance_from_optimal = 0.0f;
float etas = 0.0f;
float last_frame_time = 0.0f;
float delta_time = 0.0f;
static final float max_time_minutes = 5;
static final float max_time_milliseconds = max_time_minutes * 60 * 1000;
float countdown = 0.0f;

//Program logic
int p = 0;
boolean reset = true;
boolean is_sim_running = false;

class Boat {
  private float[] start_line_min = new float[] {0.0f, 0.0f};
  private float[] start_line_max = new float[] {0.0f, 50.0f};

  float position[] = new float[2];
  float angle;
  float speed;
  
  Boat (float[] pos, float angle, float sp)
  {
    this.position = pos;
    this.angle = angle;
    this.speed = sp;

    this.Update(0);
  }  


  private void UpdateDistance (float delta_time)
  {
    //dx = v_x * dt
    angle = angle_scrollbar.getPos();

    position[0] = speed  * cos(angle) * (delta_time/1000) + position[0]  ;

    distance_to_start = abs(position[0]/abs(cos(angle)));
  }

  private void UpdateETA()
  {
    // dt = dx/v
    eta = max(0,distance_to_start/this.speed);
  }

  public void Update(float delta_time)
  {
    UpdateDistance(delta_time);
    UpdateETA();
  }

}

 Boat boat;

void setup()
{
  size(800, 600);
  delta_time_pos = new int[] {int(width * 0.9), int(height * 0.9)};
  button_pos[0] = 60;
  button_pos[1] =  int(height * 0.8);
  eta_pos[0] = int(width  * 0.8);
  eta_pos[1] = int(height * 0.25);
  etas_pos[0] = int(width  * 0.8);
  etas_pos[1] = int(height * 0.75);
  d1_string_pos[0] = int(width * 0.4);
  d1_string_pos[1] = int(height * 0.25);
  d2_string_pos[0] = int(width * 0.4);
  d2_string_pos[1] = int(height * 0.75);
  d3_string_pos[0] = int(width * 0.6);
  d3_string_pos[1] = d1_string_pos[1] - 25;
  d4_string_pos[0] = int(width * 0.6);
  d4_string_pos[1] = d2_string_pos[1] - 25;
  angle_scrollbar = new HScrollbar(0, int(height * 0.4), int(width * 0.25), 16, 16);
  boat_image = loadImage("boat.png");
  //boat = new Boat(new float[] {-100.0, 0}, QUARTER_PI, 0.5);
  imageMode(CENTER);
  sine = new SinOsc(this);
  frameRate(60);
}


void draw_string(String s, color fill_color, int[] position, int size, int[] align)
{
    fill(fill_color);
    textSize(size);
    textAlign(align[0], align[1]);
    text(s, position[0], position[1]);
}

/* Returns true if the mouse is over the circle passed */
boolean mouseOverCircle(int[] center, int diameter) 
{
  float disX = center[0] - mouseX;
  float disY = center[1] - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}

void draw(){
  float frame_time = millis();
  delta_time = 1000/60.0f;//frame_time - last_frame_time;
  last_frame_time = frame_time;
  
  update(delta_time);
  background(0);
  
  
  int[] string_alignment = {CENTER, CENTER};
  angle_scrollbar.update();
  angle_scrollbar.display();

  draw_string("Distance to startline:", color(255,0,0), d3_string_pos, 16, string_alignment);
  draw_string("Expected distance at start:", color(255,0,0), d4_string_pos, 16, string_alignment);
  draw_string(String.valueOf(int(distance_to_start)) + " m", color(255,0,0), d1_string_pos, 32, string_alignment);
  draw_string(String.valueOf(nf(distance_from_optimal,0,0)) + " m", color(255,0,0), d2_string_pos, 32, string_alignment);
  draw_string(String.valueOf(nf(eta,0,1)) + " s", color(255, 0,0), eta_pos, 32, string_alignment);
  draw_string(String.valueOf(nf(countdown/1000,0,1)) + " s", color(255, 0,0), etas_pos, 32, string_alignment);
  //debug string
  ///draw_string(String.valueOf(frame_time) + " ms", color(140, 140,140), delta_time_pos, 32, string_alignment);
  
  fill(button_color);
  ellipse(button_pos[0],button_pos[1],button_diameter,button_diameter);

  translate(100, 100);
  rotate(angle_scrollbar.getPos());
  scale(0.2, 0.2);
  image(boat_image, 0, 0);

}

void update(float delta_time)
{
  
  if(is_sim_running)
  {
    if(reset)
    {
      //new simulation
      last_frame_time = millis();
      countdown = max_time_milliseconds;
      boat = new Boat(new float[] {-100.0, 0}, QUARTER_PI, 0.5);
      button_color = color(0, 255, 0);
      beep(500, 1000, 300, 1.0);
      reset = false;
    }
    else
    {
    //update an already running simulation
    button_color = color(0,0,255);
    boat.Update(delta_time);
    countdown = countdown - delta_time;
    }
  } 
  else 
  {
    //stop a running simulation
    button_color = color(255,0,0);
    distance_to_start = 0.0f;
    distance_from_optimal = 0.0f;
    eta = 0.0f;
    reset = true;
  }
}

int laste_toggle = 0;
boolean state = false;
void beep(int on_time, int off_time, int freq, float amp)
{
  sine.play();
  sine.freq(freq);
  if(state)
  {
    if(millis() - laste_toggle >= on_time)
    {
      sine.amp(0);
      state = false;
      laste_toggle = millis();
    }
  }
  else if(millis() - laste_toggle >= off_time)
  {
    sine.amp(amp);
    state = true;
    laste_toggle = millis();
  }
}

/* Interrupts called by processing on events */
void mousePressed(){
  if((mouseButton == LEFT) && mouseOverCircle(button_pos, button_diameter))
  {
    is_sim_running = !is_sim_running;
  }
}

void keyPressed(){
  if (key == 32){
    if(p < 2){
      p++;
    }
    else if(p == 2){
      p = 1;
    }
  }
  if (key == BACKSPACE){
    if(p == 2){
      p = 0;
    }
  }
}


class HScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  int loose;              // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;

  HScrollbar (float xp, float yp, int sw, int sh, int l) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos + swidth/2 - sheight/2;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    loose = l;
  }

  void update() {
    if (overEvent()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 1) {
      spos = spos + (newspos-spos)/loose;
    }
  }

  float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }

  boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
       mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  void display() {
    noStroke();
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if (over || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(spos, ypos, sheight, sheight);
  }

  float getPos() {
    //map spos from [sposMin, sposMax] -> [-Pi, Pi]
    //(val - A)*(b-a)/(B-A) + a
    return (spos - sposMin) * (2 * PI)/(sposMax - sposMin) - PI;// * ratio;
  }
}
