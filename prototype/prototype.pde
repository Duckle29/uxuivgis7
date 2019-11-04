import processing.sound.*;
SinOsc sine;

int window_width = 600;
int window_height = 400;


color button_color = color(255,0,0);
int button_diameter = 50;
int button_pos[] = new int[2];
int eta_pos[]  = new int[2];
int etas_pos[]  = new int[2];
int d1_string_pos[] = new int[2];
int d2_string_pos[] = new int[2];
int d3_string_pos[] = new int[2];
int d4_string_pos[] = new int[2];

color idle_color        = color(255);
color highlight_color   = color(204);


float distance_to_start = 0.0f;
float eta = 0.0f;
float distance_from_optimal = 0.0f;
float etas = 0.0f;

int p = 0;
boolean was_sim_running = false;
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

    this.Update();
  }  


  private void UpdateDistance ()
  {
    distance_to_start = -position[0]/sin(angle);
  }

  private void UpdateETA()
  {
    eta = distance_to_start/this.speed;
  }

  public void Update()
  {
    UpdateDistance();
    UpdateETA();
  }

}

 Boat boat;

void setup()
{
  size(800, 600);
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
  update();
  background(0);
  
  
  int[] string_alignment = {CENTER, CENTER};
  draw_string("Distance to startline:", color(255,0,0), d3_string_pos, 16, string_alignment);
  draw_string("Expected distance at start:", color(255,0,0), d4_string_pos, 16, string_alignment);
  draw_string(String.valueOf(distance_to_start) + " m", color(255,0,0), d1_string_pos, 32, string_alignment);
  draw_string(String.valueOf(distance_from_optimal) + " m", color(255,0,0), d2_string_pos, 32, string_alignment);
  draw_string(String.valueOf(eta) + " s", color(255, 0,0), eta_pos, 32, string_alignment);
  draw_string(String.valueOf(etas) + " s", color(255, 0,0), etas_pos, 32, string_alignment);
  fill(button_color);
  ellipse(button_pos[0],button_pos[1],button_diameter,button_diameter);



}

void update()
{
  
  if(!was_sim_running && is_sim_running)
  {
    //new simulation
    boat = new Boat(new float[] {-100.0, 0}, QUARTER_PI, 10);
    button_color = color(0, 255, 0);
    
    beep(500, 1000, 300, 1.0);
  } 
  else if (was_sim_running && !is_sim_running)
  {
    //stop a running simulation
    button_color = color(255,0,0);
    distance_to_start = 0.0f;
    distance_from_optimal = 0.0f;
    eta = 0.0f;
  }
  else if (was_sim_running && is_sim_running)
  {
    //update an already running simulation
    boat.Update();
    
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
    was_sim_running = is_sim_running;
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