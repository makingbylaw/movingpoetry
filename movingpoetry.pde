import SimpleOpenNI.*;
SimpleOpenNI kinect;

// Create an array of words that we will use for the poetry
final String[] words = new String[] { 
  "away", 
  "with", 
  "strawberry", 
  "beer", 
  "to", 
  "want", 
  "dream", 
  "fly", 
  "of",
  "you",
  "make"
  };
  
// Constant keeping track of the minimum hit distance
final int MIN_HIT_DISTANCE = 30;
// The gap between each placeholder 
final int PLACEHOLDER_GAP = 50;
// The starting X position for all placeholders
final int PLACEHOLDER_START_X = 180;
// The starting Y position for all placeholders
final int PLACEHOLDER_START_Y = 400;
// The starting X position for the line
final int LINE_START_X = 140;
// The distance below the placeholders to start the line
final int LINE_Y_DIST = 30;
// The width of the line
final int LINE_WIDTH = 610;
// The distance below the placehoders for the period
final int PERIOD_Y_DIST = 20;
// The starting X position for the period
final int PERIOD_START_X = 740;
// Starting Y position of the words
final int WORD_START_Y = 20; /* was 80 */
final int WORD_HEIGHT = 30;
final int WORD_GAP = 10;

// An array of buttons
// to begin with this is the number of words + placeholders to hold these also
final Button[] buttons = new Button[words.length * 2];

// The font we're using
PFont font;

// Tracking flags
boolean handsTrackFlag = false;
PVector handVec = new PVector();
PVector mapHandVec = new PVector();
color handPointCol = color(255, 0, 0);

ArrayList handVecList = new ArrayList();
int handVecListSize = 30;
String lastGesture = null;

float[] theHandPos;

// Keep track of the button we are tracking
int selectedButton = words.length;

void setup() {
  size(850, 700);
  smooth();
  
  // Set the font first of all
  font = loadFont("KhmerMN-Bold-48.vlw");
  textFont(font);

  // A loop to evenly space out the words buttons along the window
  for (int i = 0; i < words.length; i++) {
    
    // Create these going down the page
    buttons[i] = new Button(44, i* (WORD_HEIGHT + WORD_GAP) + WORD_START_Y, textWidth(words[i]), WORD_HEIGHT); 
    buttons[i].displayText = words[i];
  }

  // Set up the placeholder buttons
  for (int i = words.length; i < buttons.length; i++) {
    
    // Create these along the bottom (variable x coordinate)
    buttons[i] = new Button((i-words.length) * PLACEHOLDER_GAP + PLACEHOLDER_START_X, PLACEHOLDER_START_Y, 10, 10);
  }

  // Create the kinect controller
  kinect = new SimpleOpenNI(this);

  // Reflect the x/y coordinates to avoid rotational mapping (the data comes in
  //  with the opposite coordinate system)
  kinect.setMirror(true);

  // enable depthMap generation 
  if (!kinect.enableDepth()) {
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
  
  // Draw a line down the bottom of the page with a full stop
  // TODO: Move these to constants
  background(#203F74);
  strokeWeight(4);
  stroke(#EBEFF5);
  // NB: x1, y1, x2, y2
  line(LINE_START_X, PLACEHOLDER_START_Y + LINE_Y_DIST, 
       LINE_START_X + LINE_WIDTH, PLACEHOLDER_START_Y + LINE_Y_DIST);
  stroke(#EBEFF5);
  fill(#EBEFF5);
  ellipse(PERIOD_START_X, PLACEHOLDER_START_Y + PERIOD_Y_DIST, 3,3);

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

  // loop through each button object to find the closest one to our hand within our threshold
  int closestButton = -1;
  float closestDistance = MIN_HIT_DISTANCE;
  for (int i = 0; i < buttons.length; i++) { 
    float distance = dist(theHandPos[0], theHandPos[1], buttons[i].x, buttons[i].y);  
  
    // Check to see if the distance between the hand and this button is less than the min distance
    if (distance < MIN_HIT_DISTANCE && distance < closestDistance) { 
      // Set the closest distance
      closestDistance = distance;
      closestButton = i;    
    }
  }
  
  // Update the selected button
  // If it isn't already selected, select it
  if (closestButton >= 0 && selectedButton != closestButton) {
    //that button we havent been tracking becomes new button
    println("hit button " + closestButton);
    selectedButton = closestButton;
  }
  
  // Update the selected button with the hand coordinates
  if (selectedButton >= 0 && selectedButton < buttons.length) {
    buttons[selectedButton].x = theHandPos[0]; 
    buttons[selectedButton].y = theHandPos[1];
  }
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

void onRecognizeGesture(String strGesture, PVector idPosition, PVector endPosition) {
  
  println("onRecognizeGesture - strGesture: " + strGesture + ", idPosition: " + idPosition + ", endPosition:" + endPosition);

  lastGesture = strGesture;
  kinect.removeGesture(strGesture); 
  kinect.startTrackingHands(endPosition);
}

void onProgressGesture(String strGesture, PVector position, float progress) {
  
  //println("onProgressGesture - strGesture: " + strGesture + ", position: " + position + ", progress:" + progress);
}

//hand event
void onCreateHands(int handId, PVector pos, float time) {
  
  println("onCreateHands - handId: " + handId + ", pos: " + pos + ", time:" + time);

  handsTrackFlag = true;
  handVec = pos;

  handVecList.clear();
  handVecList.add(pos);
  handPointCol = color(0, 255, 0); //green dot
}

void onUpdateHands(int handId, PVector pos, float time) {
  //println("onUpdateHandsCb - handId: " + handId + ", pos: " + pos + ", time:" + time);
  handVec = pos;

  handVecList.add(0, pos);
  if (handVecList.size() >= handVecListSize) { 
    // remove the last point 
    handVecList.remove(handVecList.size()-1);
  }
}

void onDestroyHands(int handId, float time) {
//  println("onDestroyHandsCb - handId: " + handId + ", time:" + time);

  handsTrackFlag = false;
  if (lastGesture != null && lastGesture.length() > 0)
    kinect.addGesture(lastGesture);
}

