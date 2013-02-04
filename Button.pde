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
  
  color outlineColor;
  color textColor;
  color fillColor;

  boolean drawBorder = true;
  boolean drawFill = false;
  
  final static color DEFAULT_OUTLINE_COLOR = #E3E7EA;
  final static color DEFAULT_TEXT_COLOR = #E8EDF5;

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
      this.x = coordinates[0];
      this.y = coordinates[1];
    }
  }
  
  boolean containsPoint(float x1, float y1) {
    return x1 >= this.x && x1 <= (this.x + this.w) &&
           y1 >= this.y && y1 <= (this.y + this.h); 
  }
  
  boolean containsPoint(float[] coordinates) {
    if (coordinates == null && coordinates.length < 2) return false;
    return this.containsPoint(coordinates[0], coordinates[1]); 
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
    
    // The color changes based on the state of the button
    rect(x, y, w, h);

    //draw the text
    if (displayText != null) {
      fill(textColor);
      text(displayText, (x+(w/2)), (y+(h/2)));
      textSize(h);
      textAlign(CENTER, CENTER);
    }
  }
} 

