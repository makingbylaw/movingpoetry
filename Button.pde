// Button class
class Button {    

  // Button location and size
  float x; 
  float y;
  float w;   
  float h;

  float xOff;
  float yOff;
  
  // Is the button on or off?
  boolean on;  
  String displayText;

  // Apply a tag to the button if necessary  
  int tag;
  
  // Optional noise parameter for skewing button placement (store only)
  float noise;
  
  color outlineColor;
  color textColor;
  color fillColor;

  boolean drawBorder = true;
  boolean drawFill = false;
  
  final static color DEFAULT_OUTLINE_COLOR = #E3E7EA;
  final static color DEFAULT_TEXT_COLOR = #E8EDF5;
  
  // Variable keeping track of whether it is animating
  boolean isAnimating = false;
  // The start of the animation time
  // Used for calculating sine
  int startAnimationTime = 0;
  
  // The total time an animation lasts for
  final static int TOTAL_ANIMATION_TIME = 3000; // 3 s
  // The maximum radii to animate
  final static int MAX_RADII = 20;
  // The animation color to change the text to
  final static color ANIMATE_TO_COLOR = #ffffa5;  
  // The maximum change in font size (-ve and +ve)
  final static int FONT_SIZE_MARGIN = 5;

  // Constructor initializes all variables
  Button(float tempX, float tempY, float tempW, float tempH) {    
    x  = tempX;
    y  = tempY;   
    w  = tempW;   
    h  = tempH;

    //    botButtonx = tempX;
    //    botButtony = tempY+200;
    //    botButtonw = tempW+5;
    //    botButtonh = tempH+5;

    xOff = 0;
    yOff = 0;   

    on = false;  // Button always starts as off
    displayText = null;
    
    outlineColor = DEFAULT_OUTLINE_COLOR;
    textColor = DEFAULT_TEXT_COLOR;
  }    

  void check(int mx, int my) {
    // Check to see if a point is inside the rectangle
    if (mx > x && mx < x + w && my > y && my < y + h) {
      on = true;

      xOff = mx - x;
      yOff = my - y;
    }
    else {
      on = false;
    }
  }
  
  void updatePosition(float[] coordinates) {
    if (coordinates != null && coordinates.length > 1) {
      updatePosition(coordinates[0], coordinates[1]);
    }
  }
  
  void updatePosition(PVector vector) {
    if (vector != null) {
      updatePosition(vector.x, vector.y);
    }
  }
  
  void updatePosition(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  boolean containsPoint(PVector vector) {
    return containsPoint(vector.x, vector.y);
  }
  
  boolean containsPoint(float x1, float y1) {
    return x1 >= this.x && x1 <= (this.x + this.w) &&
           y1 >= this.y && y1 <= (this.y + this.h); 
  }
  
  boolean containsPoint(float[] coordinates) {
    if (coordinates == null && coordinates.length < 2) return false;
    return this.containsPoint(coordinates[0], coordinates[1]); 
  }
  
  /*
   * Starts animating the button
   */
  void startAnimating() {
    println("Starting to animate " + displayText);
    isAnimating = true;
    startAnimationTime = millis();
  }
  
  /*
   * Forces the button to stop animating. This is called every time 
   * it is hovered over or selected
   */
  void stopAnimating() {
    isAnimating = false;
  }

  // Draw the buttons
  void display() {

    rectMode(CORNER);
    if (drawBorder) {
      stroke(outlineColor);//button outline
      strokeWeight(.6);
    } else {
      noStroke();
    }
    
    if (drawFill) {
      fill(255);
    } else {
      noFill();
    }
        
    // Calculate the radii and text color
    float radii = 0.0;
    color tc = textColor;
    float textSize = h;
    if (isAnimating) {
      // If we've been animating for a while then stop animating
      int animationDuration = millis() - startAnimationTime;
      if (animationDuration > TOTAL_ANIMATION_TIME) {
        isAnimating = false;
      } else {
        // Calculate the path depending on the position on the Sine curve.
        // The min radii is 0 and the max radii is MAX_RADII
        // We'll use the absolute value of the sine curve so that it looks like a 
        // smooth animation.
        // In regards to pi, we define that 2pi = TOTAL_ANIMATION_TIME and 0 = 0
        // This also means that pi = TOTAL_ANIMATION_TIME/2
        float angle = PI * ((animationDuration*2.0)/TOTAL_ANIMATION_TIME);
        // Get the sin value (between -1 and 1)
        float x = sin(angle);
        
        // Calculate the radii
        //radii = abs(x * MAX_RADII);
        
        // Change the text size
        textSize = h + x * FONT_SIZE_MARGIN;
        
        // Also work out the text color
        tc = (int)(abs(x) * ANIMATE_TO_COLOR) + textColor;
      }
    }
    
    // The color changes based on the state of the button
    rect(x, y, w, h, radii);

    //draw the text
    if (displayText != null) {
      // Set the text color
      fill(tc);
      // Set the text size
      textSize(textSize);
      // Set the alignment
      textAlign(CENTER, CENTER);
      // Draw the text
      text(displayText, (x+(w/2)), (y+(h/2)));
    }
  }
} 

