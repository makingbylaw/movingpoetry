import SimpleOpenNI.*;
SimpleOpenNI kinect;

// An array of buttons
Button[] buttons = new Button[100];//[# of buttons]
PFont font;
int i;
float p;
float        zoomF =0.5f;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
// the data from openni comes upside down
float        rotY = radians(0);
boolean      handsTrackFlag = false;
boolean      handsTrackFlag1 = false;
PVector      handVec = new PVector();
PVector      handVec1 = new PVector();
PVector      mapHandVec = new PVector();
color handPointCol = color(255, 0, 0);

ArrayList    handVecList = new ArrayList();
int          handVecListSize = 30;
String       lastGesture = "";

float[] theHandPos;

int currButton = 0;//this what we are tracking
int lastButton;//unless we get close to it



void setup() {
  size(850, 700);
  smooth();

  // A loop to evenly space out the buttons along the window
  for (int i = 0; i < buttons.length; i ++) {
    //   buttons[i] = new Button(i*100+25,height/2-25,50,50); //ex row

    buttons[i] = new Button(44, i*40+100, 50, 30) ; //(x,y,w,h)column I want on left side
  }

  for (int i = 0; i < buttons.length; i += 10) {
    //   buttons[i] = new Button(i*100+25,height/2-25,50,50); 

  //  buttons[i] = new Button(i*50+10, 500, 50, 50) ; //(x,y,w,h)row I want 
    buttons[i] = new Button(i*3+20, 450, 10, 10) ; //(x,y,w,h)row I want
  }

  //initialize the buttons with some text
  buttons[0].displayText = "";//the first button tracked
  buttons[1].displayText = "away";
  buttons[2].displayText = "with";
  buttons[3].displayText = "strawberry";
  buttons[4].displayText = "beer";
  buttons[5].displayText = "to";
  buttons[6].displayText = "want";
  buttons[7].displayText = "dream";
  buttons[8].displayText = "fly";  
  buttons[9].displayText = "of";
  buttons[10].displayText = "you";
  buttons[11].displayText = "make";


 
 
  //font = createFont("Arial",12,true); 
  font = loadFont("KhmerMN-Bold-48.vlw");

  textFont(font);
  buttons[3].w = textWidth("strawberry");

  kinect = new SimpleOpenNI(this);

  // mirror
  kinect.setMirror(true);

  // enable depthMap generation 
  if (kinect.enableDepth() == false)
  {
    println("Can't open the depthMap, maybe the camera is not connected!"); 
    exit();
    return;
  }

  // enable hands + gesture generation
  kinect.enableDepth();
  kinect.enableGesture();
  kinect.enableHands();

  // add focus gestures  / here i do have some problems on the mac, i only recognize raiseHand ? Maybe cpu performance ?
  kinect.addGesture("Wave");
  kinect.addGesture("Click");
  kinect.addGesture("RaiseHand");
}


void draw() {
  background(#203F74);
  strokeWeight(4);
  stroke(#EBEFF5);
  line(140, 480, 750, 480);
  stroke(#EBEFF5);
  fill(#EBEFF5);
  ellipse(740, 470, 3,3);


  // Show all the buttons
  for (int i = 0; i < buttons.length; i++) {
    buttons[i].display();
  }
  
  /////////////// 
  // update the cam
  kinect.update();
  kinect.convertRealWorldToProjective(handVec, mapHandVec);

  ////move the buttons 
  theHandPos = mapHandVec.array();//put that into an array

//    print("hand x: " + theHandPos[0] + "hand y: " + theHandPos[1]);


  //loop thru each button object
  //find dist betw x n y of our hand and x n y of our button
  for (int i = 0; i < buttons.length; i++) { 
    float distance = dist(theHandPos[0], theHandPos[1], buttons[i].x, buttons[i].y);  
    //if(theHandPos[0] == buttons[i].x && theHandPos[1] == buttons[i].y && i != currButton) {
  
   if (i != currButton && distance <= 30) {//for a button that we are not already tracking and it gets to <15
      //lastButton = currButton;
      currButton = i;//that button we havent been tracking becomes new button
      println("hit button " + i);
    }
  }
  //whatever that button is, we track
  buttons[currButton].x = theHandPos[0]; 
  buttons[currButton].y = theHandPos[1];

  //  image(kinect.depthImage(), 0, 0);

  //  stroke(handPointCol);
}

void mousePressed() {
  // When the mouse is pressed, we must check every single button
  for (int i = 0; i < buttons.length; i++) {
    buttons[i].check(mouseX, mouseY);
  }
}

void mouseDragged() {

  //loop through all the buttons
  for (int i = 0; i < buttons.length; i++) {   
    //if the button was clicked, move it
    if (buttons[i].on) {
      buttons[i].x = mouseX - buttons[i].xOff;
      buttons[i].y = mouseY - buttons[i].yOff;
    }
  }
}

void mouseReleased() {

  //when releasing the mouse, turn all the buttons to the off or locked state
  for (int i = 0; i < buttons.length; i++) {
    buttons[i].on = false;
  }
}



// -----------------------------------------------------------------
// gesture events

void onRecognizeGesture(String strGesture, PVector idPosition, PVector endPosition)
{
  println("onRecognizeGesture - strGesture: " + strGesture + ", idPosition: " + idPosition + ", endPosition:" + endPosition);

  lastGesture = strGesture;
  kinect.removeGesture(strGesture); 
  kinect.startTrackingHands(endPosition);
}

void onProgressGesture(String strGesture, PVector position, float progress)
{
  //println("onProgressGesture - strGesture: " + strGesture + ", position: " + position + ", progress:" + progress);
}

//hand event
void onCreateHands(int handId, PVector pos, float time)
{
  println("onCreateHands - handId: " + handId + ", pos: " + pos + ", time:" + time);

  handsTrackFlag = true;
  handVec = pos;

  handVecList.clear();
  handVecList.add(pos);
  handPointCol = color(0, 255, 0);//green dot
}

void onUpdateHands(int handId, PVector pos, float time)
{
  //println("onUpdateHandsCb - handId: " + handId + ", pos: " + pos + ", time:" + time);
  handVec = pos;

  handVecList.add(0, pos);
  if (handVecList.size() >= handVecListSize)
  { // remove the last point 
    handVecList.remove(handVecList.size()-1);
  }
}

void onDestroyHands(int handId, float time)
{
//  println("onDestroyHandsCb - handId: " + handId + ", time:" + time);

  handsTrackFlag = false;
  kinect.addGesture(lastGesture);
}

