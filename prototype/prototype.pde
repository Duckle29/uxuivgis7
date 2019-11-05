import processing.sound.*;
SinOsc sine;

int window_width = 600;
int window_height = 400;

//User Interface
color button_color = color(255, 0, 0);
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
HScrollbar speed_scrollbar;
PImage boat_image;


color idle_color        = color(255);
color highlight_color   = color(204);

//Simulation physical parameters
float distance_to_start = 0.0f;
float eta = 0.0f;
float distance_from_optimal = 0.0f;
float etas = 0.0f;
float last_frame_time = 0.0f;
float time_from_optimal = 0.0f;
float delta_time = 0.0f;
static final float max_time_minutes = 0.5;
static final float max_time_milliseconds = max_time_minutes * 60 * 1000;
float countdown = 0.0f;
float boat_speed = 2.5f;

//IO
int beep_tone_base = 300; // Hz
float beep_freq = 0.0f; // Hz
float beep_slope = -0.1f; // Hz per second
float beep_offset = 1.5f; // Hz
float time_hysteresis = 10.0f; // Seconds
float bad_zone_penalty = 50; // Hz
float upper_beep_bound = 4.0f;
float lower_beep_bound = 0.5f;

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
    speed = speed_scrollbar.getPos1();
    angle = angle_scrollbar.getPos();

    position[0] = speed  * cos(angle) * (delta_time/1000) + position[0]  ;

    distance_to_start = abs(position[0]/abs(cos(angle)));
  }

  private void UpdateOptPos ()
  {
    float distance_travel_potential = this.speed * (countdown / 1000);
    distance_from_optimal = distance_to_start - distance_travel_potential;
    time_from_optimal = distance_from_optimal / this.speed;
  }

  private void UpdateETA()
  {
    // dt = dx/v
    eta = max(0, distance_to_start/this.speed);
  }

  public void Update(float delta_time)
  {
    UpdateDistance(delta_time);
    UpdateOptPos();
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
  speed_scrollbar = new HScrollbar(0, int(height * 0.45), int(width * 0.25), 16, 16);
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

void draw() {
  float frame_time = millis();
  delta_time = 1000/60.0f;//frame_time - last_frame_time;
  last_frame_time = frame_time;

  color text_color = color(0);

  update(delta_time);
  background(0);

  if (time_from_optimal < time_hysteresis && time_from_optimal > 0)
  {
    text_color = color(0, 255, 0);
  } else if ( time_from_optimal > 0)
  {
    text_color = color(242, 144, 8);
  } else
  {
    text_color = color(255, 0, 0);
  }


  int[] string_alignment = {CENTER, CENTER};
  angle_scrollbar.update();
  angle_scrollbar.display();
  speed_scrollbar.update();
  speed_scrollbar.display();

  draw_string("Distance to startline:", color(255, 0, 0), d3_string_pos, 16, string_alignment);
  draw_string("Expected distance at start:", color(255, 0, 0), d4_string_pos, 16, string_alignment);
  draw_string(String.valueOf(int(distance_to_start)) + " m", color(255, 0, 0), d1_string_pos, 64, string_alignment);
  draw_string(String.valueOf(int(distance_from_optimal)) + " m", text_color, d2_string_pos, 64, string_alignment);
  draw_string(String.valueOf(int(eta)) + " s", color(255, 0, 0), eta_pos, 64, string_alignment);
  draw_string(String.valueOf(int(time_from_optimal)) + " s", text_color, etas_pos, 64, string_alignment);
  //debug string
  draw_string(String.valueOf(int(countdown/1000)) + " s", color(140, 140,140), delta_time_pos, 32, string_alignment);

  fill(button_color);
  ellipse(button_pos[0], button_pos[1], button_diameter, button_diameter);

  translate(100, 100);
  rotate(angle_scrollbar.getPos());
  scale(0.2, 0.2);
  image(boat_image, 0, 0);
  if(countdown <= 0 || distance_to_start < 0.5)
  {
    is_sim_running = false;
    reset = false;
  }
}

void update(float delta_time)
{

  if (is_sim_running)
  {
    if (reset)
    {
      //new simulation
      last_frame_time = millis();
      countdown = max_time_milliseconds;
      boat = new Boat(new float[] {-25.0, 0}, QUARTER_PI, boat_speed);
      button_color = color(0, 255, 0);
      sound_handler();
      reset = false;
    } else
    {
      //update an already running simulation
      button_color = color(0, 0, 255);
      boat.Update(delta_time);
      countdown = countdown - delta_time;
      sound_handler();
    }
  } else 
  {
    //stop a running simulation
    button_color = color(255, 0, 0);
    distance_to_start = 0.0f;
    distance_from_optimal = 0.0f;
    eta = 0.0f;
    reset = true;
    sine.stop();
  }
}

int laste_toggle = 0;
boolean state = false;
void beep(int on_time, int off_time, int freq, float amp)
{
  sine.play();
  sine.freq(freq);
  if (state)
  {
    if (millis() - laste_toggle >= on_time)
    {
      sine.amp(0);
      state = false;
      laste_toggle = millis();
    }
  } else if (millis() - laste_toggle >= off_time)
  {
    sine.amp(amp);
    state = true;
    laste_toggle = millis();
  }
}

/* Interrupts called by processing on events */
void mousePressed() {
  if ((mouseButton == LEFT) && mouseOverCircle(button_pos, button_diameter))
  {
    is_sim_running = !is_sim_running;
  }
}

void keyPressed(){
  if (key == CODED){
    if (keyCode == LEFT){
      angle_scrollbar.newspos = angle_scrollbar.newspos - 0.5;
      if (angle_scrollbar.spos < angle_scrollbar.sposMin){
        angle_scrollbar.newspos = angle_scrollbar.sposMax;
        angle_scrollbar.spos = angle_scrollbar.sposMax;
      }
    }
    if (keyCode == RIGHT){
      angle_scrollbar.newspos = angle_scrollbar.newspos + 0.5;
      if (angle_scrollbar.spos > angle_scrollbar.sposMax){
        angle_scrollbar.newspos = angle_scrollbar.sposMin;
        angle_scrollbar.spos = angle_scrollbar.sposMin;
      }
    }
    if (keyCode == UP){
      if (speed_scrollbar.spos < speed_scrollbar.sposMax){
        speed_scrollbar.newspos = speed_scrollbar.newspos + 1;
      }
    }
    if (keyCode == DOWN){
      if (speed_scrollbar.spos > speed_scrollbar.sposMin){
        speed_scrollbar.newspos = speed_scrollbar.newspos - 1;
      }
    }
  }
}

float fudge = 1.0f;

void sound_handler()
{
  beep_freq = beep_slope * time_from_optimal + beep_offset;
  float beep_tone = beep_tone_base;

  //if (time_from_optimal < time_hysteresis && time_from_optimal > 0)
  //{
  //  beep_freq = beep_offset;
  //}

  if (time_from_optimal < fudge) //0)
  {
    beep_tone += bad_zone_penalty;
  } else if (time_from_optimal > fudge)//time_from_optimal > time_hysteresis)
  {
    beep_tone -= bad_zone_penalty;
  }

  if (beep_freq > upper_beep_bound) 
    beep_freq = upper_beep_bound;
  else if (beep_freq < lower_beep_bound)
    beep_freq = lower_beep_bound;
  beep(int((1000/beep_freq)*0.75), int((1000/beep_freq)*0.25), int(beep_tone), 1);
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
  float getPos1() {
    //map spos from [sposMin, sposMax] -> [-Pi, Pi]
    //(val - A)*(b-a)/(B-A) + a
    return (spos - sposMin) * (2.5)/(sposMax - sposMin);// * ratio;
  }
}
