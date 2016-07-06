//  Tiago Brizolara, 2013
//  Uses Maxim, GUI
//
//  The artistic part:
//
//  A simple synthesizer.
//  The main idea is for Android:
//  Control morprhing between different waveforms using rotation around x. Control pitch with rotation around y. So I'm trying here to have a musical instrument - a thing that a person can get used on how to manipulate to make sound.
//  Since this code isn't the Android version: instead of accelerometer, the control is on mouse down. Position x of mouse controls picth and y controls waveshape morphing.
//  
//  The pedagogical part (physicists/musicians/engineers...):
//
//  * Drag mouse from top to bottom to see/hear the morphing  (OR rotate your Android phone from horizontal till he faces you)
//  * Hear how the perceived loudness increases, for example, as a sine becomes a sawtooth
//  This is because the sawtooth can be tought as equal to the correspondent sine plus infinite harmonics, weighted as 1/n (Fourier decomposition). So, if its the sine + more harmonics, it carries more power.
//  * Look how the wavelength decreases (frequency increases) as we click to the right, raising the pitch
//  * The frequency grows linearly in the right direction (we can notice the wavelength changes linearly as we click to the right direction). Observe how the pitch goes up nonlinearly (the consecutive vertical lines are more and more far apart as we go to the right). So, our perception of pitch is not linear in relation to the frequency. No surprise, as we know that doubling a frequency means hearing an octave up...
//  * The green lines are the harmonic series. The fundamental is at the lef, first harmonic (octave) and 2n harmonic (octave + fifth) are inside the window and 4th harmonic (2 octaves) is at the right corner. Note that just the octaves fit perfectly with the equally tempered scale (the gray lines). Look at the 3rd harmonic line - a natural fifth has a higher frequency than the equally-tempered one
//

Slider volumeSlider;
RadioButtons waveTopRdButtons;   // upper buttons, to select "upper" waveshape
RadioButtons waveBottomRdButtons;// lower buttons, to select "lower" waveshape

//  Y coordinates of top and bottom of the region where the waveshape is
//going to be drawn:
int waveshapePanelYTop, waveshapePanelYBottom;

final int SINEWAVE       = 0;
final int SAWTOOTHWAVE   = 1;
final int SQUAREWAVE     = 2;
final int TRIANGULARWAVE = 3;
final int CUSTOMWAVE     = 4; // not being used

//  the waveshape of the first and second AudioPlayers 
//(audioPlayers[0 and 1], below). We start with sine and sawtooth selected
int [] waveType = {SINEWAVE, SAWTOOTHWAVE};

Maxim maxim;

AudioPlayer audioPlayers[];

float speed = 1;  //  speed of wavetable looping. Controls frequency (pitch)
float morph = 0;  //  controls the morphing between the waveshapes of 
  //the upper and lower wave  

float generalVolume = 0.2;
float accelerometerX = 0.;
float accelVolumeFactor = 1.;

int lastMouseX, lastMouseY;
boolean justStarted = true;

//--------------------------------------------------------------
void setup() {  
  
  size(540, 380);
  
  /**** MAXIM *****/
  maxim = new Maxim(this);  
  //audioPlayers = new AudioPlayer[2];
  audioPlayers = new AudioPlayer[8];
  
  waveshapePanelYTop    = (int)(0.15*height);
  waveshapePanelYBottom = (int)(0.85*height);
  volumeSlider = new Slider("vol.",
    0.2, 0.0, 1.0, // value, minim, maximum
    width - 20, 2, 16, (int)((0.2)*height)-4, UPWARDS // x, y, w, h, ori
  );
  volumeSlider.setInactiveColor(color(255, 0, 0));
  
  String [] waveTopRdButtonsNames = {"0", "1", "2", "3"};
  int numberOfButtonsInRow = 4;
  int border = 0;
  int buttonsSpace = width-24;
  int buttonsWidth = buttonsSpace/numberOfButtonsInRow;
  int buttonsHeight = waveshapePanelYTop - 2;
  waveTopRdButtons = new RadioButtons(waveTopRdButtonsNames, numberOfButtonsInRow,
    border, border, 
    buttonsWidth, buttonsHeight, HORIZONTAL);
  waveBottomRdButtons = new RadioButtons(waveTopRdButtonsNames, numberOfButtonsInRow,
    border, waveshapePanelYBottom, 
    buttonsWidth, buttonsHeight, HORIZONTAL);
     
  PImage [] imgsTopButtons = {
    loadImage("sine.png"),
    loadImage("sawtooth.png"),
    loadImage("square.png"),
    loadImage("triangle.png")
  };
  PImage [] imgsTopButtons_inactive = {
    loadImage("sine_bw.png"),
    loadImage("sawtooth_bw.png"),
    loadImage("square_bw.png"),
    loadImage("triangle_bw.png")
  };
  PImage [] imgsBottomButtons = {
    loadImage("sine.png"),
    loadImage("sawtooth.png"),
    loadImage("square.png"),
    loadImage("triangle.png")
  };
  PImage [] imgsBottomButtons_inactive = {
    loadImage("sine_bw.png"),
    loadImage("sawtooth_bw.png"),
    loadImage("square_bw.png"),
    loadImage("triangle_bw.png")
  };  
         
  /*would use just 2 AudioPlayers and load files on runtime, but
  loading files is too slow, messing things up
  for(int plyr=0; plyr<2; plyr++)
  {
    //loadWaveform(audioPlayers[plyr], waveType[plyr]);
    switch(waveType[plyr])
    {
      case SINEWAVE:       audioPlayers[plyr] = maxim.loadFile("sine_441Hz_100samples.wav");       break;
      case SAWTOOTHWAVE:   audioPlayers[plyr] = maxim.loadFile("sawtooth_441Hz_100samples.wav");   break;
      case SQUAREWAVE:     audioPlayers[plyr] = maxim.loadFile("square_441Hz_100samples.wav");     break;
      case TRIANGULARWAVE: audioPlayers[plyr] = maxim.loadFile("triangular_441Hz_100samples.wav"); break;
    }
    audioPlayers[plyr].setLooping(true);
    audioPlayers[plyr].play();
  }*/
  
  waveTopRdButtons.setAllActiveImages(imgsTopButtons);
  waveTopRdButtons.setAllInactiveImages(imgsTopButtons_inactive);
  waveTopRdButtons.set("0");
  waveBottomRdButtons.setAllActiveImages(imgsBottomButtons);
  waveBottomRdButtons.setAllInactiveImages(imgsBottomButtons_inactive);
  waveBottomRdButtons.set("1");
  
  audioPlayers[0] = maxim.loadFile/*("sine_86_1328125Hz_512mais2samples");*/("        sine_220_5Hz__200samples.wav");
  audioPlayers[1] = maxim.loadFile/*("sawtooth_86_1328125Hz_512mais2samples");*/("sawtooth_220_5Hz__200samples.wav");
  audioPlayers[2] = maxim.loadFile/*("square_86_1328125Hz_512mais2samples");*/("    square_220_5Hz__200samples.wav");
  audioPlayers[3] = maxim.loadFile/*("triangle_86_1328125Hz_512mais2samples");*/("triangle_220_5Hz__200samples.wav");
  audioPlayers[4] = maxim.loadFile/*("sine_86_1328125Hz_512mais2samples");*/("        sine_220_5Hz__200samples.wav");
  audioPlayers[5] = maxim.loadFile/*("sawtooth_86_1328125Hz_512mais2samples");*/("sawtooth_220_5Hz__200samples.wav");
  audioPlayers[6] = maxim.loadFile/*("square_86_1328125Hz_512mais2samples");*/("    square_220_5Hz__200samples.wav");
  audioPlayers[7] = maxim.loadFile/*("triangle_86_1328125Hz_512mais2samples");*/("triangle_220_5Hz__200samples.wav");
  for(int plyr=0; plyr<8; plyr++)
  {
    audioPlayers[plyr].setLooping(true);
    audioPlayers[plyr].volume(0);
  }
  
  //audioPlayers[waveType[0]].play();
  
  lastMouseX = 0;
  lastMouseY = height/2;
  
  //mouseReleased();
}

//-------------------------------------------------------------
void draw() {
  
  //  black background
  fill(0);
  stroke(0);
  rect(0, 0, width, height);
  
  //  gray lines: equally-tempered tones
  stroke(40, 40, 40, 255);
  strokeWeight(2);
  for(int i=0; i<25; i++)
  {
     line( width/3f * (pow(2,i/12f) - 1), 0,
           width/3f * (pow(2,i/12f) - 1), height-1);
  }
  //  green: first 4 harmonics (fundamental, octave, octave+5th, 2 octaves)
  stroke(40, 80, 40, 255);
  strokeWeight(1);
  for(int i=1; i<=4; i++)
  {
    line( width/3f * (i - 1), 0,
          width/3f * (i - 1), height-1);
  }
  
  //  red: current pitch
  stroke(255, 0, 0, 255);
  line(mouseX, 0, mouseX, height-1);
  
  //  red: horizontal touch coordinate
  //line(0, mouseY, width, mouseY);
  
  //  waveshape
  //  Note that what is been drawn is not being read from the audio buffer data.
  //  This is because visualization gets better if we already know the
  //waveshape and don't need to adjust the audio buffer data to the window
  
  stroke(200, 0, 150, 255);
  strokeWeight(4);
  
  float [] firstPoint = {0., height/2 };// (x,y) for start line point
  float [] nextPoint = {0., 0. };       // (x,y) for end line point
  
  int fullAmplitude = (waveshapePanelYBottom - waveshapePanelYTop + 1);
  float half_amplitude = fullAmplitude/2.;
  int currentPeriod = 1;
  float wavelength = width/speed;
  float half_wavelength = wavelength/2.;
  float i_in_lambda = -1; // iterates inside a wavelength
  float saw_sum = 0;
  float square_sum = 0;
  float triang_sum = 0;
  float sine_sum = 0;
  float sumUPPER = 0;
  float sumBOTTOM = 0;
  
  if(waveType[0] == TRIANGULARWAVE || waveType[1] == TRIANGULARWAVE)
    firstPoint[1] = 0.;
  
  int jump = 4;  //  para dispositivos rapidos, pode diminuir bastante o jump, ateh mesmo para 1

  switch(waveType[0]) {
    case SINEWAVE:        sumUPPER = 0.;                break;
    case SAWTOOTHWAVE:    sumUPPER = 0.;                break;
    case SQUAREWAVE:      sumUPPER = half_amplitude;    break;
    case TRIANGULARWAVE:  sumUPPER =  - half_amplitude; break;
  }
  
  switch(waveType[1]) {
    case SINEWAVE:        sumBOTTOM = 0.;                break;
    case SAWTOOTHWAVE:    sumBOTTOM = 0.;                break;
    case SQUAREWAVE:      sumBOTTOM = half_amplitude;    break;
    case TRIANGULARWAVE:  sumBOTTOM =  - half_amplitude; break;
  }
  
  firstPoint[1] = height/2 +  // 0 at the vertical center of the screen
      (1-morph)*sumUPPER
        + 
      morph*sumBOTTOM;

  for(int i = 1; i<width; i+=jump)
  {
    nextPoint[0] = i;
    
    i_in_lambda += jump;
    if(i_in_lambda > wavelength)
      i_in_lambda -= i_in_lambda;
    
    switch(waveType[0])
    {
      case SINEWAVE:
        sumUPPER = half_amplitude*sin(TWO_PI*i/wavelength);
      break;
      
      case SAWTOOTHWAVE:
        //  calculating sawtooth contribution
        //  The math here is: a sawtooth is a diagonal line
        sumUPPER = half_amplitude/half_wavelength * i_in_lambda;  //  a sawtooth is just a diagonal line
        if(i_in_lambda > half_wavelength) 
          sumUPPER -= fullAmplitude;
      break;
      
      case SQUAREWAVE:
        //  calculating square contribution
        sumUPPER = half_amplitude;
        if(i_in_lambda > half_wavelength) 
          sumUPPER = -half_amplitude;
      break;
      
      case TRIANGULARWAVE:
        //  calculating triangular contribution
        sumUPPER = fullAmplitude/half_wavelength * i_in_lambda - half_amplitude;
        if(i_in_lambda > wavelength/2f) 
          sumUPPER = fullAmplitude * (0.5 - (i_in_lambda-half_wavelength)/half_wavelength);      
      break;      
    }
    
    switch(waveType[1])
    {
      case SINEWAVE:
        sumBOTTOM = half_amplitude*sin(TWO_PI*i/wavelength);
      break;
      
      case SAWTOOTHWAVE:
        //  calculating sawtooth contribution
        //  The math here is: a sawtooth is a diagonal line
        sumBOTTOM = half_amplitude/half_wavelength * i_in_lambda;  //  a sawtooth is just a diagonal line
        if(i_in_lambda > half_wavelength) 
          sumBOTTOM -= fullAmplitude;
      break;
      
      case SQUAREWAVE:
        //  calculating square contribution
        sumBOTTOM = half_amplitude;
        if(i_in_lambda > half_wavelength) 
          sumBOTTOM = -half_amplitude;
      break;
      
      case TRIANGULARWAVE:
        //  calculating triangular contribution
        sumBOTTOM = fullAmplitude/half_wavelength * i_in_lambda - half_amplitude;
        if(i_in_lambda > half_wavelength) 
          sumBOTTOM = fullAmplitude * (0.5- (i_in_lambda-half_wavelength)/half_wavelength);      
      break;      
    }
    
    nextPoint[1] = height/2 +  // 0 at the vertical center of the screen
      (1-morph)*sumUPPER
        + 
      morph*sumBOTTOM;
    
    //  drawing the line and updating for next draw
    line( firstPoint[0], firstPoint[1], nextPoint[0], nextPoint[1]);
    firstPoint[0] = nextPoint[0];
    firstPoint[1] = nextPoint[1];
  }
  
  lastMouseX = mouseX;
  lastMouseY = mouseY;
  
  volumeSlider.display();

  waveTopRdButtons.display();
  waveBottomRdButtons.display();

}

//---------------------------------------------------------
void update()
{
  //  Paranoid care about the players...
  if(justStarted)
  {
    if(audioPlayers[waveType[0]].isPlaying())
    {
      audioPlayers[waveType[1]+4].play();
      justStarted = false;
      return;
    }
    else {
      audioPlayers[waveType[0]].play();
    }
  }
  
  generalVolume = volumeSlider.val;  
  
  //  speed: from 1 (left side of the screen) to 4 (right side)
  //  Remember that 2 means octave and 4, two octaves
  speed = 1 + mouseX/(float)width * 3;
  //if(speed < 0)
    speed = abs(speed);
  
  audioPlayers[waveType[0]].speed(speed);
  audioPlayers[waveType[1]+4].speed(speed);
  
  //  morphing:
  //  To the top of the screen, strenghtens sine and weakens sawtooth.
  //  To the bottom, the inverse
  if(mouseY > waveshapePanelYTop && mouseY < waveshapePanelYBottom)
  {
    morph = (mouseY-waveshapePanelYTop)/(float)(waveshapePanelYBottom-waveshapePanelYTop);
  }
  
  audioPlayers[waveType[0]].volume(  generalVolume * (1-morph));
  audioPlayers[waveType[1]+4].volume(generalVolume * morph);
}

//---------------------------------------------------------------
void mouseDragged() {
  volumeSlider.mouseDragged();
  update();    
}

void mousePressed() {
  volumeSlider.mousePressed();
  update();
}

//---------------------------------------------------------------
void mouseReleased()
{
  
  //  Update state of GUI
  //volumeSlider.mouseReleased();
  waveTopRdButtons.mouseReleased();
  waveBottomRdButtons.mouseReleased();
  
  //
  //  - Updates waveform according to the button clicked
  //  - Or just turn sound off if no button clicked
  //
  if(mouseY  < waveshapePanelYTop)  //  upper waveform
  {
    //  - player representing the upper waveform
    int newTopWaveType = int(waveTopRdButtons.get());
    if(newTopWaveType != waveType[0])  //  selected a different waveshape
    {
      if(newTopWaveType == -1) // no button got selected (how??)
      {
        newTopWaveType = waveType[0];
        switch(waveType[0])
        {
          case 0: waveTopRdButtons.set("0"); break;
          case 1: waveTopRdButtons.set("1"); break;
          case 2: waveTopRdButtons.set("2"); break;
          case 3: waveTopRdButtons.set("3"); break;
        }
        //  The line below do the work instead of using the switch above, but String(..)
        //is not compilng here in Android mode
        //waveTopRdButtons.set(String(newTopWaveType));
      }
      else  //   a button got selected
      {
        waveType[0] = newTopWaveType;
        //loadWaveform(audioPlayers[0], waveType[0]);
        for(int i=0; i<4; i++)
        {
          if(i != newTopWaveType)
          {
            audioPlayers[i]./*stop();*/volume(0);
          }
          else
          {
            if(audioPlayers[i].isPlaying() == false) {
              audioPlayers[i].play();
              println("Now playing!");
            }
            audioPlayers[i].volume(accelVolumeFactor * generalVolume*(1-morph));
          }
        }
      }
    }
  }
  else if(mouseY > waveshapePanelYBottom)  //  lower waveform
  {
    //  - player representing the lower waveform
    int newBottomWaveType = int(waveBottomRdButtons.get());
    if(newBottomWaveType != waveType[1])  //  selected a different waveshape
    {
      if(newBottomWaveType == -1) // no button got selected (how??)
      {
        newBottomWaveType = waveType[1];
        switch(waveType[1])
        {
          case 0: waveBottomRdButtons.set("0"); break;
          case 1: waveBottomRdButtons.set("1"); break;
          case 2: waveBottomRdButtons.set("2"); break;
          case 3: waveBottomRdButtons.set("3"); break;
        }
        //  The line below do the work instead of using the switch above, but String(..)
        //is not compilng here in Android mode
        //waveBottomRdButtons.set(String(newBottomWaveType));
      }
      else
      {
        waveType[1] = newBottomWaveType;
        //loadWaveform(audioPlayers[1], waveType[1]);
        for(int i=0; i<4; i++)
        {
          if(i != newBottomWaveType)
          {
            audioPlayers[i+4]./*stop();*/volume(0);
          }
          else
          {
            if(audioPlayers[i+4].isPlaying() == false)
            {
              audioPlayers[i+4].play();
              println("Now playing!");
            }
            audioPlayers[i+4].volume(accelVolumeFactor*generalVolume*morph);
          }
        }
      }
    }
  }
  
  //  all players get muted on mouse up
  for(int i=0; i<8; i++){
    audioPlayers[i]./*stop();*/volume(0);
  }
  
}
//-----------------------------------------------------------------
/* would use just 2 AudioPlayers and load files on runtime, but it gets buggy
void loadWaveform(AudioPlayer a_audioPlayer, int a_waveform)
{
  switch(a_waveform)
  {
    case SINEWAVE:       a_audioPlayer = maxim.loadFile("sine_441Hz_100samples.wav");       break;
    case SAWTOOTHWAVE:   a_audioPlayer = maxim.loadFile("sawtooth_441Hz_100samples.wav");   break;
    case SQUAREWAVE:     a_audioPlayer = maxim.loadFile("square_441Hz_100samples.wav");     break;
    case TRIANGULARWAVE: a_audioPlayer = maxim.loadFile("triangular_441Hz_100samples.wav"); break;
  }
  a_audioPlayer.setLooping(true);
  a_audioPlayer.play();
}*/



int HORIZONTAL = 0;
int VERTICAL   = 1;
int UPWARDS    = 2;
int DOWNWARDS  = 3;

class Widget
{

  
  PVector pos;
  PVector extents;
  String name;

  color inactiveColor = color(60, 60, 100);
  color activeColor = color(100, 100, 160);
  color bgColor = inactiveColor;
  color lineColor = color(255);
  
  
  
  void setInactiveColor(color c)
  {
    inactiveColor = c;
    bgColor = inactiveColor;
  }
  
  color getInactiveColor()
  {
    return inactiveColor;
  }
  
  void setActiveColor(color c)
  {
    activeColor = c;
  }
  
  color getActiveColor()
  {
    return activeColor;
  }
  
  void setLineColor(color c)
  {
    lineColor = c;
  }
  
  color getLineColor()
  {
    return lineColor;
  }
  
  String getName()
  {
    return name;
  }
  
  void setName(String nm)
  {
    name = nm;
  }


  Widget(String t, int x, int y, int w, int h)
  {
    pos = new PVector(x, y);
    extents = new PVector (w, h);
    name = t;
    //registerMethod("mouseEvent", this);
  }

  void display()
  {
  }

  boolean isClicked()
  {
    
    if (mouseX > pos.x && mouseX < pos.x+extents.x 
      && mouseY > pos.y && mouseY < pos.y+extents.y)
    {
      return true;
    }
    else
    {
      return false;
    }
  }
  
  public void mouseEvent(MouseEvent event)
  {
    //if (event.getFlavor() == MouseEvent.PRESS)
    //{
    //  mousePressed();
    //}
  }
  
  
  boolean mousePressed()
  {
    return isClicked();
  }
  
  boolean mouseDragged()
  {
    return isClicked();
  }
  
  
  boolean mouseReleased()
  {
    return isClicked();
  }
}

class Button extends Widget
{
  PImage activeImage = null;
  PImage inactiveImage = null;
  PImage currentImage = null;
  color imageTint = color(255);
  
  Button(String nm, int x, int y, int w, int h)
  {
    super(nm, x, y, w, h);
  }
  
  void setImage(PImage img)
  {
    setInactiveImage(img);
    setActiveImage(img);
  }
  
  void setInactiveImage(PImage img)
  {
    if(currentImage == inactiveImage || currentImage == null)
    {
      inactiveImage = img;
      currentImage = inactiveImage;
    }
    else
    {
      inactiveImage = img;
    }
  }
  
  void setActiveImage(PImage img)
  {
    if(currentImage == activeImage || currentImage == null)
    {
      activeImage = img;
      currentImage = activeImage;
    }
    else
    {
      activeImage = img;
    }
  }
  
  void setImageTint(float r, float g, float b)
  {
    imageTint = color(r,g,b);
  }

  void display()
  {
    if(currentImage != null)
    {
      
      //float imgHeight = (extents.x*currentImage.height)/currentImage.width;
      
      //  [Brizo] Why this?
      //float imgWidth = (extents.y*currentImage.width)/currentImage.height;
      
      pushStyle();
      imageMode(CORNER);
      tint(imageTint);
      //image(currentImage, pos.x, pos.y, imgWidth, extents.y);
      image(currentImage, pos.x, pos.y, extents.x, extents.y);  //  [Brizo]
      stroke(bgColor);
      noFill();
      //rect(pos.x, pos.y, imgWidth,  extents.y);
      rect(pos.x, pos.y, extents.x,  extents.y);  //  [Brizo]
      noTint();
      popStyle();
    }
    else
    {
      pushStyle();
      stroke(lineColor);
      fill(bgColor);
      rect(pos.x, pos.y, extents.x, extents.y);
  
      fill(lineColor);
      textAlign(CENTER, CENTER);
      text(name, pos.x + 0.5*extents.x, pos.y + 0.5* extents.y);
      popStyle();
    }
  }
  
  boolean mousePressed()
  {
    if (super.mousePressed())
    {
      if (bgColor == activeColor)
      {
        bgColor = inactiveColor;
      } else
      {
        bgColor = activeColor;
      }
      
      if(activeImage != null)
        currentImage = activeImage;
      return true;
    }
    return false;
  }
  
  boolean mouseReleased()
  {
    if (super.mouseReleased())
    {
      bgColor = inactiveColor;
      if(inactiveImage != null)
        currentImage = inactiveImage;
      return true;
    }
    return false;
  }
}

class Toggle extends Button
{
  boolean on = false;

  Toggle(String nm, int x, int y, int w, int h)
  {
    super(nm, x, y, w, h);
  }


  boolean get()
  {
    return on;
  }

  void set(boolean val)
  {
    on = val;
    if (on)
    {
      bgColor = activeColor;
      if(activeImage != null)
        currentImage = activeImage;
    }
    else
    {
      bgColor = inactiveColor;
      if(inactiveImage != null)
        currentImage = inactiveImage;
    }
  }

  void toggle()
  {
    set(!on);
  }

  
  boolean mousePressed()
  {
    return super.isClicked();
  }

  boolean mouseReleased()
  {
    if (super.mouseReleased())
    {
      toggle();
      return true;
    }
    return false;
  }
}

class RadioButtons extends Widget
{
  public Toggle [] buttons;
  
  RadioButtons (String [] names,int numButtons, int x, int y, int w, int h, int orientation)
  {
    super("", x, y, w*numButtons, h);
    buttons = new Toggle[numButtons];
    for (int i = 0; i < buttons.length; i++)
    {
      int bx, by;
      if(orientation == HORIZONTAL)
      {
        //bx = x+i*(w+5);
        bx = x+i*w;  //  [Brizo] no borders for now
        println(w);
        println(bx);
        by = y;
      }
      else
      {
        bx = x;
        by = y+i*(h+5);
      }
      buttons[i] = new Toggle(names[i], bx, by, w, h);
    }
  }
  
  void setNames(String [] names)
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(i >= names.length)
        break;
      buttons[i].setName(names[i]);
    }
  }
  
  void setImage(int i, PImage img)
  {
    setInactiveImage(i, img);
    setActiveImage(i, img);
  }
  
  void setAllImages(PImage [] img)
  {
    setAllInactiveImages(img);
    setAllActiveImages(img);
  }
  
  void setInactiveImage(int i, PImage img)
  {
    buttons[i].setInactiveImage(img);
  }

  
  void setAllInactiveImages(PImage [] img)
  {
    for (int i = 0; i < buttons.length; i++)
    {
      buttons[i].setInactiveImage(img[i]);
    }
  }
  
  void setActiveImage(int i, PImage img)
  {
    
    buttons[i].setActiveImage(img);
  }
  
  
  
  void setAllActiveImages(PImage [] img)
  {
    for (int i = 0; i < buttons.length; i++)
    {
      buttons[i].setActiveImage(img[i]);
    }
  }

  void set(String buttonName)
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].getName().equals(buttonName))
      {
        buttons[i].set(true);
      }
      else
      {
        buttons[i].set(false);
      }
    }
  }
  
  int get()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].get())
      {
        return i;
      }
    }
    return -1;
  }
  
  String getString()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].get())
      {
        return buttons[i].getName();
      }
    }
    return "";
  }

  void display()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      strokeWeight(2);  //  [Brizo]
      buttons[i].display();
    }
  }

  boolean mousePressed()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].mousePressed())
      {
        return true;
      }
    }
    return false;
  }
  
  boolean mouseDragged()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].mouseDragged())
      {
        return true;
      }
    }
    return false;
  }

  boolean mouseReleased()
  {
    for (int i = 0; i < buttons.length; i++)
    {
      if(buttons[i].mouseReleased())
      {
        for(int j = 0; j < buttons.length; j++)
        {
          if(i != j)
            buttons[j].set(false);
        }
        //buttons[i].set(true);
        return true;
      }
    }
    return false;
  }
}

class Slider extends Widget
{
  float minimum;
  float maximum;
  float val;
  int textWidth = 60;
  int orientation = HORIZONTAL;

  Slider(String nm, float v, float min, float max, int x, int y, int w, int h, int ori)
  {
    super(nm, x, y, w, h);
    val = v;
    minimum = min;
    maximum = max;
    orientation = ori;
    if(orientation == HORIZONTAL)
      textWidth = 60;
    else
      textWidth = 20;
    
  }

  float get()
  {
    return val;
  }

  void set(float v)
  {
    val = v;
    val = constrain(val, minimum, maximum);
  }

  void display()
  {
    
    float textW = textWidth;
    if(name == "")
      textW = 0;
    pushStyle();
    //textAlign(LEFT, TOP);
    textAlign(LEFT, TOP);
    fill(lineColor);
    text(name, pos.x, pos.y);
    strokeWeight(2);  //  [Brizo]
    stroke(lineColor);
    noFill();
    if(orientation ==  HORIZONTAL){
      rect(pos.x+textW, pos.y, extents.x-textWidth, extents.y);
    } else {
      rect(pos.x, pos.y+textW, extents.x, extents.y-textW);
    }
    noStroke();
    fill(bgColor);
    float sliderPos; 
    if(orientation ==  HORIZONTAL){
        sliderPos = map(val, minimum, maximum, 0, extents.x-textW-4); 
        rect(pos.x+textW+2, pos.y+2, sliderPos, extents.y-4);
    } else if(orientation ==  VERTICAL || orientation == DOWNWARDS){
        sliderPos = map(val, minimum, maximum, 0, extents.y-textW-4); 
        rect(pos.x+2, pos.y+textW+2, extents.x-4, sliderPos);
    } else if(orientation == UPWARDS){
        sliderPos = map(val, minimum, maximum, 0, extents.y-textW-4); 
        rect(pos.x+2, pos.y+textW+2 + (extents.y-textW-4-sliderPos), extents.x-4, sliderPos);
    };
    popStyle();
  }

  
  boolean mouseDragged()
  {
    if (super.mouseDragged())
    {
      float textW = textWidth;
      if(name == "")
        textW = 0;
      if(orientation ==  HORIZONTAL){
        set(map(mouseX, pos.x+textW, pos.x+extents.x-4, minimum, maximum));
      } else if(orientation ==  VERTICAL || orientation == DOWNWARDS){
        set(map(mouseY, pos.y+textW, pos.y+extents.y-4, minimum, maximum));
      } else if(orientation == UPWARDS){
        set(map(mouseY, pos.y+textW, pos.y+extents.y-4, maximum, minimum));
      };
      return true;
    }
    return false;
  }

  boolean mouseReleased()
  {
    if (super.mouseReleased())
    {
      float textW = textWidth;
      if(name == "")
        textW = 0;
      if(orientation ==  HORIZONTAL){
        set(map(mouseX, pos.x+textW, pos.x+extents.x-10, minimum, maximum));
      } else if(orientation ==  VERTICAL || orientation == DOWNWARDS){
        set(map(mouseY, pos.y+textW, pos.y+extents.y-10, minimum, maximum));
      } else if(orientation == UPWARDS){
        set(map(mouseY, pos.y+textW, pos.y+extents.y-10, maximum, minimum));
      };
      return true;
    }
    return false;
  }
}

class MultiSlider extends Widget
{
  Slider [] sliders;
  /*
  MultiSlider(String [] nm, float min, float max, int x, int y, int w, int h, int orientation)
  {
    super(nm[0], x, y, w, h*nm.length);
    sliders = new Slider[nm.length];
    for (int i = 0; i < sliders.length; i++)
    {
      int bx, by;
      if(orientation == HORIZONTAL)
      {
        bx = x;
        by = y+i*h;
      }
      else
      {
        bx = x+i*w;
        by = y;
      }
      sliders[i] = new Slider(nm[i], 0, min, max, bx, by, w, h, orientation);
    }
  }
  */
  MultiSlider(int numSliders, float min, float max, int x, int y, int w, int h, int orientation)
  {
    super("", x, y, w, h*numSliders);
    sliders = new Slider[numSliders];
    for (int i = 0; i < sliders.length; i++)
    {
      int bx, by;
      if(orientation == HORIZONTAL)
      {
        bx = x;
        by = y+i*h;
      }
      else
      {
        bx = x+i*w;
        by = y;
      }
      sliders[i] = new Slider("", 0, min, max, bx, by, w, h, orientation);
    }
  }
  
  void setNames(String [] names)
  {
    for (int i = 0; i < sliders.length; i++)
    {
      if(i >= names.length)
        break;
      sliders[i].setName(names[i]);
    }
  }

  void set(int i, float v)
  {
    if(i >= 0 && i < sliders.length)
    {
      sliders[i].set(v);
    }
  }
  
  float get(int i)
  {
    if(i >= 0 && i < sliders.length)
    {
      return sliders[i].get();
    }
    else
    {
      return -1;
    }
    
  }

  void display()
  {
    for (int i = 0; i < sliders.length; i++)
    {
      sliders[i].display();
    }
  }

  
  boolean mouseDragged()
  {
    for (int i = 0; i < sliders.length; i++)
    {
      if(sliders[i].mouseDragged())
      {
        return true;
      }
    }
    return false;
  }

  boolean mouseReleased()
  {
    for (int i = 0; i < sliders.length; i++)
    {
      if(sliders[i].mouseReleased())
      {
        return true;
      }
    }
    return false;
  }
}


