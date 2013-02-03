// Button class

class Button {    

  // Button location and size
  float x; 
  float x1;  
  float y;
  float y1;  
  float w;   
  float h;


  float xOff;
  float yOff;  
  // Is the button on or off?
  boolean on;  
  String displayText;

  // Constructor initializes all variables
  Button(float tempX, float tempY, float tempW, float tempH) {    
    x  = tempX;
    y  = tempY;   
    w  = tempW+5;   
    h  = tempH+5;

    //    botButtonx = tempX;
    //    botButtony = tempY+200;
    //    botButtonw = tempW+5;
    //    botButtonh = tempH+5;

    xOff = 0;
    yOff = 0;   

    on = false;  // Button always starts as off
    displayText = "";
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

  // Draw the buttons
  void display() {

    rectMode(CORNER);
    stroke(#E3E7EA);//button outline
    strokeWeight(.6);
    //noStroke();
    noFill();
    // The color changes based on the state of the button
    //    if (on) {
    //      fill(255);
    //    } else {
    //      fill(255);
    //    }

    rect(x, y, w, h);

  

   

    //draw the text
    if (displayText!="") {
      fill(#E8EDF5);
  
      text(displayText, (x+(w/2)), (y+(h/2)));
      textSize(35);
      textAlign(CENTER, CENTER);
    }

;
  }
} 

