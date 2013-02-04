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
final static int MIN_HIT_DISTANCE = 30; // TODO: Do we need this?

// Line constants
final static int LINE_START_X = 140; // The starting X position for the line
final static int LINE_START_Y = 430; // The starting Y position for the line
final static int LINE_WIDTH = 610; // The width of the line

// Period constants
final static int PERIOD_START_Y = 420; // The starting Y position for the period
final static int PERIOD_START_X = 740; // The starting X position for the period

// Word constants
final static int WORD_START_Y = 20; // Starting Y position of the words
final static int WORD_HEIGHT = 30; // The word height
final static int WORD_GAP = 10; // The gap between each word
final static color WORD_COLOR_SELECTING = #333333;
final static color WORD_COLOR_SELECTED = #eeee00;

// Cursor constants
final static int CURSOR_SIZE = 10; // The size of the cursor
final static int TIME_BEFORE_SELECTION = 1000; // Time in ms

// Gesture constants
final static String TRACKING_GESTURE = "RaiseHand";

// An array of "buttons" to hold each word
final Button[] wordTiles = new Button[words.length];
final Button cursor = new Button(10, 10, CURSOR_SIZE, CURSOR_SIZE);

// The font we're using
PFont font;

// Tracking flags
PVector handVector = new PVector();
PVector mappedHandVector = new PVector();

// We need to keep track of moving words etc
int selectedWord = -1;
int consideringMovingWord = -1;
int consideringMovingWordSince = 0;

void setup() {
  size(850, 700);
  smooth();
  
  // Set the font first of all
  font = loadFont("KhmerMN-Bold-48.vlw");
  textFont(font);

  // A loop to evenly space out the words buttons along the window
  for (int i = 0; i < words.length; i++) {
    
    // Create these going down the page
    wordTiles[i] = new Button(44, i* (WORD_HEIGHT + WORD_GAP) + WORD_START_Y, textWidth(words[i]), WORD_HEIGHT); 
    wordTiles[i].displayText = words[i];
  }
  
  // Set up the cursor
  cursor.on = true;
  cursor.drawFill = true;

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
  //kinect.addGesture("Wave");
  //kinect.addGesture("Click");
  kinect.addGesture(TRACKING_GESTURE);
}


void draw() {
  
  // Draw a line down the bottom of the page with a full stop
  // TODO: Move these to constants
  background(#203F74);
  strokeWeight(4);
  stroke(#EBEFF5);
  // NB: x1, y1, x2, y2
  line(LINE_START_X, LINE_START_Y, LINE_START_X + LINE_WIDTH, LINE_START_Y);
  stroke(#EBEFF5);
  fill(#EBEFF5);
  ellipse(PERIOD_START_X, PERIOD_START_Y, 3,3);

  // Update the camera
  kinect.update();
  kinect.convertRealWorldToProjective(handVector, mappedHandVector);

  // Get the hand position 
  float[] theHandPosition = mappedHandVector.array();
  
  // Update the cursor position
  cursor.updatePosition(theHandPosition);
  
  // Display the cursor
  cursor.display();
  
  // We need to decide whether we are moving or not
  if (selectedWord >= 0) {
    // We're currently moving this word
    wordTiles[selectedWord].updatePosition(theHandPosition);
  } else {
    // Work out if which one we are currently considering
    int consider = -1;
    for (int i = 0; i < wordTiles.length; i++) {
      if (wordTiles[i].containsPoint(theHandPosition)) {
        consider = i;
        break;
      }
    }
    
    // Check to see if it is the same as the one we are currently considering
    if (consider >= 0 && consider == consideringMovingWord) {
      
      // Check the time to see if we should upgrade this to a selected tile
      if (millis() - consideringMovingWordSince >= TIME_BEFORE_SELECTION) {
        selectedWord = consideringMovingWord;
        consideringMovingWord = -1;
      }
      
    } else {
      
      // Update the considering moving word and set the time 
      consideringMovingWord = consider;
      consideringMovingWordSince = millis();
    }
  }
  
  // If the cursor is hovering over a box then change the state
  for (int i = 0; i < wordTiles.length; i++) {
    
    if (selectedWord == i) {
      wordTiles[i].outlineColor = WORD_COLOR_SELECTED;
    } else if (consideringMovingWord == i) {
      wordTiles[i].outlineColor = WORD_COLOR_SELECTING;
    } else {
      wordTiles[i].outlineColor = Button.DEFAULT_OUTLINE_COLOR;
    }
  }

  // Show all the buttons
  for (int i = 0; i < wordTiles.length; i++) {
    wordTiles[i].display();
  }

//    print("hand x: " + theHandPos[0] + "hand y: " + theHandPos[1]);
/*
  // loop through each button object to find the closest one to our hand within our threshold
  int closestButton = -1;
  float closestDistance = MIN_HIT_DISTANCE;
  for (int i = 0; i < wordTiles.length; i++) { 
    float distance = dist(theHandPosition[0], theHandPosition[1], wordTiles[i].x, wordTiles[i].y);  
  
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
*/  
/*  
  // Update the selected button with the hand coordinates
  if (selectedButton >= 0 && selectedButton < wordTiles.length) {
    wordTiles[selectedButton].updatePosition(theHandPosition); 
  }
*/
}

void mousePressed() {
  // When the mouse is pressed, we must check every single button
  for (int i = 0; i < wordTiles.length; i++) {
    wordTiles[i].check(mouseX, mouseY);
  }
}

void mouseDragged() {

  //loop through all the buttons
  for (int i = 0; i < wordTiles.length; i++) {   
    //if the button was clicked, move it
    if (wordTiles[i].on) {
      wordTiles[i].x = mouseX - wordTiles[i].xOff;
      wordTiles[i].y = mouseY - wordTiles[i].yOff;
    }
  }
}

void mouseReleased() {

  //when releasing the mouse, turn all the buttons to the off or locked state
  for (int i = 0; i < wordTiles.length; i++) {
    wordTiles[i].on = false;
  }
}

// -----------------------------------------------------------------
// gesture events

void onRecognizeGesture(String gesture, PVector idPosition, PVector endPosition) {
  
  println(gesture + ", idPosition: " + idPosition + ", endPosition:" + endPosition);
  kinect.removeGesture(TRACKING_GESTURE); 
  kinect.startTrackingHands(endPosition);
}

void onProgressGesture(String strGesture, PVector position, float progress) {
  
  //println("onProgressGesture - strGesture: " + strGesture + ", position: " + position + ", progress:" + progress);
}

//hand event
void onCreateHands(int handId, PVector pos, float time) {
  
  println("onCreateHands - handId: " + handId + ", pos: " + pos);
  handVector = pos;

  //handVectorList.clear();
  //handVectorList.add(pos);
}

void onUpdateHands(int handId, PVector pos, float time) {
  
  //println("onUpdateHandsCb - handId: " + handId + ", pos: " + pos);
  handVector = pos;

  //handVectorList.add(0, pos);
  //if (handVectorList.size() >= MAX_HAND_VECTOR_LIST_SIZE) { 
    // remove the last point 
  //  handVectorList.remove(handVectorList.size()-1);
  //}
}

void onDestroyHands(int handId, float time) {
  println("Destroying hand " + handId);
  kinect.addGesture(TRACKING_GESTURE);
  //kinect.stopTrackingHands();
}

