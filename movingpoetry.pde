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
  
// Line constants
final static int LINE_START_X = 100; // The starting X position for the line
final static int LINE_START_Y = 430; // The starting Y position for the line
final static int LINE_WIDTH = 650; // The width of the line

// Period constants
final static int PERIOD_START_Y = 420; // The starting Y position for the period
final static int PERIOD_START_X = 740; // The starting X position for the period

// Word constants
final static int WORD_START_Y = 20; // Starting Y position of the words
final static int WORD_START_X = 44;
final static int MAX_WORD_AREA_WIDTH = 600;
final static int MAX_WORD_AREA_HEIGHT = 300;
final static int WORD_HEIGHT = 30; // The word height
final static int WORD_PADDING = 20;  // Spacing between the word and its box

// Colors
final static color WORD_COLOR_SELECTING = #333333;
final static color WORD_COLOR_SELECTED = #eeee00;

// Cursor constants
final static int CURSOR_SIZE = 10; // The size of the cursor
final static int TIME_BEFORE_SELECTION = 1000; // Time in ms
final static int TIME_BEFORE_DROP = 1000; // Time in ms

// Set to enable/disable the mouse
final static boolean ENABLE_MOUSE = true;

// Gesture constants
final static String TRACKING_GESTURE = "RaiseHand";

// Flick constants
final static int FLICK_DELTA_REQUIREMENT = 50; // in pixels

// An array of "buttons" to hold each word
final Button[] wordTiles = new Button[words.length];
final Button cursor = new Button(10, 10, CURSOR_SIZE, CURSOR_SIZE);

// The font we're using
PFont font;

// Tracking flags
PVector handVector = new PVector();
PVector mappedHandVector = new PVector();
PVector lastPosition = new PVector();

// The dropped list of words - used only for ordering
final ArrayList droppedWords = new ArrayList();
// The ghost drop box - only ever drawn when it's on
final Button ghostDropBox = new Button(1, LINE_START_Y - WORD_HEIGHT, 1, WORD_HEIGHT);
int ghostBoxShownSince = 0;

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
  textSize(WORD_HEIGHT);

  // A loop to evenly space out the words buttons along the window
  int numberOfConflicts = 0;
  int startTime = millis();
  for (int i = 0; i < words.length; i++) {
    
    // Work out the best x and y positions to use
    boolean positionFound = false;
    float x = 0, y = 0;
    float w = textWidth(words[i]) + WORD_PADDING;
    float h = WORD_HEIGHT;
    
    // Find a position
    while (!positionFound) {
      x = random(0, MAX_WORD_AREA_WIDTH) + WORD_START_X;
      y = random(0, MAX_WORD_AREA_HEIGHT) + WORD_START_Y;
      
      // Make sure we aren't overlapping at all.
      boolean overlaps = false;
      for (int j = 0; j < i && !overlaps; j++) {
        
        // Check all four corners for overlaps
        overlaps = wordTiles[j].containsPoint(x, y) || wordTiles[j].containsPoint(x + w, y + h) ||
                   wordTiles[j].containsPoint(x + w, y) || wordTiles[j].containsPoint(x, y + h) ||
                   // Also check mid points
                   wordTiles[j].containsPoint(x + w/2, y) || wordTiles[j].containsPoint(x, y + h/2) ||
                   wordTiles[j].containsPoint(x + w/2, y + h/2) || wordTiles[j].containsPoint(x + w/2, y + h/2);
      }
      
      // Set if we found a position
      positionFound = !overlaps; 
      if (!positionFound) {
        numberOfConflicts++;
      }
    }
    
    // Create the word
    wordTiles[i] = new Button(x, y, w, h); 
    wordTiles[i].displayText = words[i];
    wordTiles[i].tag = i;
  }
  println("Scattered words with " + numberOfConflicts + " conflicts in " + (millis() - startTime) + "ms");
  
  // Set up the cursor
  cursor.on = true;
  cursor.drawFill = true;
  
  // Set up the ghost button
  ghostDropBox.outlineColor = #eeeeee;
  ghostDropBox.textColor = #eeeeee;

  // Set up the kinect if we aren't using mouse
  // A better use of this is actually compiler constants
  if (!ENABLE_MOUSE) {
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
  
    // add focus gesture
    kinect.addGesture(TRACKING_GESTURE);
  }
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

  if (ENABLE_MOUSE) {
    mappedHandVector.x = mouseX;
    mappedHandVector.y = mouseY;
  } else {
    // Update the camera
    kinect.update();
    kinect.convertRealWorldToProjective(handVector, mappedHandVector);
  }

  // Update the cursor position
  cursor.updatePosition(mappedHandVector);
  
  // Display the cursor
  cursor.display();
  
  // We need to decide whether we are moving or not
  if (selectedWord >= 0) {
    // We're currently moving this word
    wordTiles[selectedWord].updatePosition(mappedHandVector);
    
    // Also check to see if we're in a drop zone (or close to one)
    detectDropZone(mappedHandVector);
    
    // detect flick for dropping
    detectFlick(mappedHandVector);
    
  } else {
    // Detect if we are selecting a word
    detectSelectingWord(mappedHandVector);
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
  
  // Show the ghost button if necessary
  if (ghostDropBox.on) {
    ghostDropBox.display();
  }
}

void detectFlick(PVector position) {
  // If no word is selected or the ghost box is on then get out
  if (selectedWord < 0 || ghostDropBox.on)
    return;
 
  // Figure out if we do not have a last position yet
  if (lastPosition.x - 0.0 < 0.01 && lastPosition.y - 0.0 < 0.01) {
    lastPosition.x = position.x;
    lastPosition.y = position.y;
    return; 
  } 
  
  // Measure the distance
  float dist = dist(lastPosition.x, lastPosition.y, position.x, position.y);
  if (dist >= FLICK_DELTA_REQUIREMENT) {
    // Drop it at the last position
    wordTiles[selectedWord].updatePosition(lastPosition);
    selectedWord = -1;
  }
  
  // Set the last position
  lastPosition.x = position.x;
  lastPosition.y = position.y;
}

void detectSelectingWord(PVector position) {
  // If we have one selected - gtfo
  if (selectedWord >= 0)
    return;
  
  // Work out if which one we are currently considering
  int consider = -1;
  for (int i = 0; i < wordTiles.length; i++) {
    if (wordTiles[i].containsPoint(position)) {
      consider = i;
      break;
    }
  }
  
  // Check to see if it is the same as the one we are currently considering
  if (consider >= 0 && consider == consideringMovingWord) {
    
    // Check the time to see if we should upgrade this to a selected tile
    if (millis() - consideringMovingWordSince >= TIME_BEFORE_SELECTION) {
      println("selecting word " + wordTiles[consideringMovingWord].displayText);
      selectedWord = consideringMovingWord;
      consideringMovingWord = -1;
      // Set the last position
      lastPosition.x = position.x;
      lastPosition.y = position.y;
      
      // If this was previously selected then remove it from the drop box
      println("checking to see if we need to remove it from the line (" + wordTiles[selectedWord].tag + ")");
      for (int i = 0; i < droppedWords.size(); i++) {
        Button c = (Button)droppedWords.get(i);
        //println("button at " + i + " tag = " + c.tag + " " + c.displayText);
        if (c.tag == wordTiles[selectedWord].tag) {
          println("found it at position " + i);
          // Remove it from the array - and update the rest of the dropped words
          droppedWords.remove(i);
          
          // Adjust the rest
          float x;
          if (i > 0) {
            c = (Button)droppedWords.get(i-1);
            x = c.x + c.w;
          } else {
            x = LINE_START_X;
          }
          for (int j = i; j < droppedWords.size(); j++) {
            c = (Button)droppedWords.get(j);
            println("setting index " + j + " to " + x);
            c.x = x;
            x += c.w;
          }
          break;
        }
      }
    }
    
  } else {
    
    // Update the considering moving word and set the time 
    if (consider >= 0) {
      consideringMovingWordSince = millis();
      println("considering moving word " + wordTiles[consider].displayText);
    }
    consideringMovingWord = consider;
  }
}

void detectDropZone(PVector position) {
  // If nothing is selected then return
  if (selectedWord < 0) return;
  
  // Keep track of the last x position
  // By default this is the start of the line 
  float lastX = LINE_START_X;
  Button selected = wordTiles[selectedWord];
  float widthOfWord = selected.w;
  
  // Work out the detection line positions
  // For completeness we'll use three vectors
  // NB: We set the y now but change the x later
  float detectionLineY = LINE_START_Y - WORD_HEIGHT/2;
  PVector v1 = new PVector(lastX, detectionLineY);
  PVector v2 = new PVector(lastX, detectionLineY);
  PVector v3 = new PVector(lastX, detectionLineY);
  
  // Loop through the current list of words to see if we need to shift any over
  boolean hitSomething = false;
  for (int i = 0; i < droppedWords.size(); i++) {
    // Get the current button
    Button c = (Button)droppedWords.get(i);

    // Update the last x
    lastX += c.w;  

    // Set up the new detection vectors
    //v1.x = lastX;
    //v2.x = lastX + widthOfWord/2;
    //v3.x = lastX + widthOfWord;

    // Check for a hit
    //hitSomething = checkPointsForGhostBox(selected, v1, v2, v3, i + 1);
    //if (hitSomething) {
      // Move over other code to make way for the ghost
      //for (int j = i + 1; j < droppedWords.size(); j++) {
      //  c = (Button)droppedWords.get(j);
      //  c.x += ghostDropBox.w;
      //}
      //break;
    //}
  }
  
  // If none were hit, then check the "end zone"
  if (!hitSomething) {
    
    // Set up the new detection vectors
    v1.x = lastX;
    v2.x = lastX + widthOfWord/2;
    v3.x = lastX + widthOfWord;
    // Check for a hit
    hitSomething = checkPointsForGhostBox(selected, v1, v2, v3, droppedWords.size() + 1);
  } 
  
  // Assuming nothing was hit still, then turn off the ghost
  if (!hitSomething) {
    ghostDropBox.on = false;
    ghostBoxShownSince = 0;
  }
}

boolean checkPointsForGhostBox(Button selected, PVector v1, PVector v2, PVector v3, int tag) {
  // Check to see if any of these contains our word
  if (selected.containsPoint(v1) || selected.containsPoint(v2) || selected.containsPoint(v3)) {
    // If so, we create a drop box ghost (if not already there) and start the timer
    if (ghostDropBox.on && ghostDropBox.tag == tag) {
      // We've already started the timer - check the time
      if (millis() - ghostBoxShownSince >= TIME_BEFORE_DROP) {
        println("Dropping " + selected.displayText + " into ghost box");
        // Drop the word
        selected.x = ghostDropBox.x;
        selected.y = ghostDropBox.y;
        // Reset the box
        ghostDropBox.on = false;
        ghostDropBox.tag = 0;
        ghostBoxShownSince = 0;
        
        // Drop the word into the appropriate place
        //int index = tag - 1;
        //if (index < droppedWords.size()) {
          //insert it into the approrpriate place
        //  droppedWords.add(index, selected);
          /*
          // Update the other locations 
          for (int i = index + 1; i < droppedWords.size(); i++) {
            droppedWords.get(i).x = droppedWords.get(i).x + droppedWords[i-1].w;
          }*/
        //} else
        droppedWords.add(selected);
        
        // Unselect our box
        selectedWord = -1;
      } 
            
    } else {
      // Turn on the ghost box and add it to our list
      println("Enabling ghost box at " + v1.x + " for " + selected.displayText);
      ghostDropBox.on = true;
      ghostDropBox.x = v1.x;
      ghostDropBox.w = selected.w;
      ghostDropBox.tag = tag;
      ghostBoxShownSince = millis();
    }
    return true; 
  }
  return false;
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
}

void onUpdateHands(int handId, PVector pos, float time) {
  //println("onUpdateHandsCb - handId: " + handId + ", pos: " + pos);
  handVector = pos;
}

void onDestroyHands(int handId, float time) {
  println("Destroying hand " + handId);
  kinect.addGesture(TRACKING_GESTURE);
}

