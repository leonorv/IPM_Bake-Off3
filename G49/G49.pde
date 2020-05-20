// Bakeoff #3 - Escrita de Texto em Smartwatches
// IPM 2019-20, Semestre 2
// Entrega: exclusivamente no dia 22 de Maio, até às 23h59, via Discord

// Processing reference: https://processing.org/reference/

import java.util.Arrays;
import java.util.Collections;
import java.util.Random;

// Screen resolution vars;
float PPI, PPCM;
float SCALE_FACTOR;

float minSizeW;
float minSizeH;
float final_size;

//Flags 
boolean hasStarted = false;

// Finger parameters
PImage fingerOcclusion;
int FINGER_SIZE;
int FINGER_OFFSET;

// Arm/watch parameters
PImage arm;
int ARM_LENGTH;
int ARM_HEIGHT;

// Arrow parameters
PImage leftArrow, rightArrow;
int ARROW_SIZE;

//Image arrow
PShape arrows;
PShape delete;
PShape space;

//Image non-interactive
PImage bcd;
PImage fgh;
PImage no;
PImage uvw;
PImage jkl;
PImage yz;
PImage qrs;
PImage arrows2;

// Study properties
String[] phrases;                   // contains all the phrases that can be tested
int NUM_REPEATS            = 2;     // the total number of phrases to be tested
int currTrialNum           = 0;     // the current trial number (indexes into phrases array above)
String currentPhrase       = "";    // the current target phrase
String currentTyped        = "";    // what the user has typed so far
char currentLetter         = 'a';
String currentWord         = "";
String[] typed = new String[NUM_REPEATS];

// Performance variables
float startTime            = 0;     // time starts when the user clicks for the first time
float finishTime           = 0;     // records the time of when the final trial ends
float lastTime             = 0;     // the timestamp of when the last trial was completed
float lettersEnteredTotal  = 0;     // a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0;     // a running total of the number of letters expected (correct phrases)
float errorsTotal          = 0;     // a running total of the number of errors (when hitting next)

//Setup frequent words array
ArrayList<StringList> frequentWords = new ArrayList<StringList>(); //26 letters!

StringList recomendations = new StringList();

//Setup window and vars - runs once
void setup()
{
  //size(900, 900);
  fullScreen();
  textFont(createFont("Arial", 24));  // set the font to arial 24
  noCursor();                         // hides the cursor to emulate a watch environment
  
  // Load images
  arm = loadImage("arm_watch.png");
  fingerOcclusion = loadImage("finger.png");
  leftArrow = loadImage("left.png");
  rightArrow = loadImage("right.png");
  arrows = loadShape("arrows.svg");
  delete = loadShape("delete.svg");
  space = loadShape("space.svg");
  bcd = loadImage("bcd.png");
  fgh = loadImage("fgh.png");
  jkl = loadImage("jkl.png");
  no = loadImage("no.png");
  qrs = loadImage("qrs.png");
  uvw = loadImage("uvw.png");
  yz = loadImage("yz.png");
  arrows2 = loadImage("arrows2.png");
  
  // Load phrases
  phrases = loadStrings("phrases.txt");                       // load the phrase set into memory
  Collections.shuffle(Arrays.asList(phrases), new Random());  // randomize the order of the phrases with no seed
  
  for(int i=0; i< 26; i++) frequentWords.add(new StringList()); //initialize frequent words
  
  
  //Load and setup frequent words
  String[] frequent_word = loadStrings("frequent_words.txt");
  for (String word: frequent_word) {
    int index = word.charAt(0) - 'a';
    frequentWords.get(index).append(word);
  }
  
  // Scale targets and imagens to match screen resolution
  SCALE_FACTOR = 1.0 / displayDensity();          // scale factor for high-density displays
  String[] ppi_string = loadStrings("ppi.txt");   // the text from the file is loaded into an array.
  PPI = float(ppi_string[1]);                     // set PPI, we assume the ppi value is in the second line of the .txt
  PPCM = PPI / 2.54 * SCALE_FACTOR;               // do not change this!
  
  FINGER_SIZE = (int)(11 * PPCM);
  FINGER_OFFSET = (int)(0.8 * PPCM);
  ARM_LENGTH = (int)(19 * PPCM);
  ARM_HEIGHT = (int)(11.2 * PPCM);
  ARROW_SIZE = (int)(2.2 * PPCM);
  
  arm.resize(ARM_LENGTH, ARM_HEIGHT);
  fingerOcclusion.resize(FINGER_SIZE, FINGER_SIZE);       
  
}

void draw()
{ 
  // Check if we have reached the end of the study
  if (finishTime != 0)  return;
 
  background(255);                                                         // clear background
  
  // Draw arm and watch background
  imageMode(CENTER);
  image(arm, width/2, height/2);
  
  // Check if we just started the application
  if (startTime == 0 && !mousePressed)
  {
    fill(0);
    textAlign(CENTER);
    text("Tap to start time!", width/2, height/2);
  }
  else if (startTime == 0 && mousePressed) nextTrial();                    // show next sentence
  
  // Check if we are in the middle of a trial
  else if (startTime != 0)
  {
    textAlign(LEFT);
    textSize(28);
    fill(100);
    text("Phrase " + (currTrialNum + 1) + " of " + NUM_REPEATS, width/2 - 4.0*PPCM, height/2 - 8.1*PPCM);   // write the trial count
    text("Target:    " + currentPhrase, width/2 - 4.0*PPCM, height/2 - 7.1*PPCM);                           // draw the target string
    fill(0);
    text("Entered:  " + currentTyped + "|", width/2 - 4.0*PPCM, height/2 - 6.1*PPCM);                      // draw what the user has entered thus far 
    
    // Draw very basic ACCEPT button - do not change this!
    textAlign(CENTER);
    noStroke();
    fill(0, 250, 0);
    rect(width/2 - 2*PPCM, height/2 - 5.1*PPCM, 4.0*PPCM, 2.0*PPCM);
    fill(0);
    text("ACCEPT >", width/2, height/2 - 4.1*PPCM);
    
    // Draw screen areas
    // simulates text box - not interactive
    stroke(0);
    fill(211,211,211);
    rect(width/2 - 2.0*PPCM, height/2 - 2.0*PPCM, 4.0*PPCM, 1.0*PPCM);
    textAlign(CENTER);
    fill(0);
    
    final_size = 24;
    
    for (int i = 0; i < recomendations.size(); i++) { //print recomendations
      // calculate minimum size to fit width
      minSizeW = 24/textWidth(recomendations.get(i)) * (4.0*PPCM/3.5);
      // calculate minimum size to fit height
      minSizeH = 24 / (textDescent() + textAscent()) * 1.0*PPCM;
      if (min(minSizeW, minSizeH) < final_size) {
        final_size = min(minSizeW, minSizeH);
      }
    }
    
    if (keyX == 0 && keyY == 0) {
      imageMode(CORNER);
      image(bcd, width/2 - 1.9*PPCM, height/2 - 1.9*PPCM, 3.8*PPCM, 0.8*PPCM);
    }
    
    else if (keyX == 1 && keyY == 0) {
      imageMode(CORNER);
      image(fgh, width/2 - 1.9*PPCM, height/2 - 1.9*PPCM, 3.8*PPCM, 0.8*PPCM);
    }
    
    else if (keyX == 2 && keyY == 0) {
      imageMode(CORNER);
      image(jkl, width/2 - 1.9*PPCM, height/2 - 1.9*PPCM, 3.8*PPCM, 0.8*PPCM);
    }
    
    else if (keyX == 0 && keyY == 1) {
      imageMode(CORNER);
      image(no, width/2 - 1.9*PPCM, height/2 - 1.9*PPCM, 3.8*PPCM, 0.8*PPCM);
    }
    
    else if (keyX == 1 && keyY == 1) {
      imageMode(CORNER);
      image(qrs, width/2 - 1.9*PPCM, height/2 - 1.9*PPCM, 3.8*PPCM, 0.8*PPCM);
    }
    
    else if (keyX == 2 && keyY == 1) {
      imageMode(CORNER);
      image(uvw, width/2 - 1.9*PPCM, height/2 - 1.9*PPCM, 3.8*PPCM, 0.8*PPCM);
    }
    
    else if (keyX == 3 && keyY == 1) {
      imageMode(CORNER);
      image(yz, width/2 - 1.9*PPCM, height/2 - 1.9*PPCM, 3.8*PPCM, 0.8*PPCM);
    }
    else {
      for (int i = 0; i < recomendations.size(); i++) { //print recomendations
        textSize(final_size);
        text(recomendations.get(i), width/2 - (2.8-((i+1)*4.0)/3.0)*PPCM, height/2 - 1.5*PPCM);
      }
    }
    
    
    
    // THIS IS THE ONLY INTERACTIVE AREA (4cm x 4cm); do not change size
    stroke(0, 255, 0);
    noFill();
    rect(width/2 - 2.0*PPCM, height/2 - 1.0*PPCM, 4.0*PPCM, 3.0*PPCM);
    
    stroke(0);
    
    char letter = 'A';

    //First row
    for(int i = 0;i < 3;i++){
      pushMatrix();
      pushStyle();
      translate(width/2 - (2f-i*4f/3f)*PPCM, height/2 - 1f*PPCM);
      if(keyY == 0 && keyX == i) {
        strokeWeight(2.0);
      }
      
      rect(0, 0, 4f/3f*PPCM, 1f*PPCM);
      stroke(0);
      textAlign(CENTER);
      textSize(PPCM/2);
      text(letter++, (2f/3f)*PPCM, 1f*(PPCM/2)); 
      textSize(PPCM/3);
      text(letter++,(1f/3f)*PPCM, 1f*(PPCM/2)); //left
      text(letter++,(2f/3f)*PPCM, 1f*(PPCM/2) + (1f/3f)*PPCM); //down
      text(letter++, 1f*PPCM, 1f*(PPCM/2)); //right
     
      popStyle();
      popMatrix();
    }
    
    // Second row
    float pos;
    for(int i = 0;i < 4;i++){
      pushMatrix();
      pushStyle();
      translate(width/2 - (2f-i)*PPCM, height/2);
      if(keyY == 1 && keyX == i) {
        strokeWeight(2.0);
      }
      rect(0, 0, 1f*PPCM, 1f*PPCM);
      textSize(PPCM/2);
      
      if (i == 0) 
        pos = 1f/3f;
      else if(i == 3)
        pos = 2f/3f;
      else
        pos = 1f/2f;
        
      text(letter++, pos*PPCM, (5f/6f)*PPCM);
     
      textSize(PPCM/3);
      
      if (i != 0) 
        text(letter++, (pos-1f/3f)*PPCM, (5f/6f)*PPCM); //left
        
      text(letter++, pos*PPCM, (1f/3f)*PPCM); //up
      
      if (i != 3)
        text(letter++, (pos+1f/3f)*PPCM, (5f/6f)*PPCM); //right
        
      popStyle();
      popMatrix();
     
    }
    
    //Third row
    for(int i = 0;i < 3;i++){
      pushMatrix();
      pushStyle();
      translate(width/2 - (2.0f-i*4f/3f)*PPCM,height/2 + 1f*PPCM);
      if(keyY == 2 && keyX == i) {
        strokeWeight(2.0);
      }
      rect(0,0, 4f/3f*PPCM, 1f*PPCM);
      if (i == 0) {
        shapeMode(CENTER);
        shape(space,(2f/3f)*PPCM,(2f/3f)*PPCM, PPCM/1.8, PPCM/1.8); 
      }
      if (i == 1) {
          shapeMode(CENTER);
          pushMatrix();
          translate((2f/3f)*PPCM,(1.5f/3f)*PPCM);
          rotate(-PI/4);
          shape(arrows, 0 , 0, PPCM/1.3*arrows.width/arrows.height, PPCM/1.3);
          popMatrix();
        
      }
      if (i == 2) {
        shapeMode(CENTER);
        shape(delete,(2f/3f)*PPCM,(1.5f/3f)*PPCM, PPCM/2.4*arrows.width/arrows.height, PPCM/2.4);
      }
      popStyle();
      popMatrix();
    }
    if (keyX == 1 && keyY == 2) {
      imageMode(CENTER);
      image(arrows2, width/2, height/2 + 0.5f*PPCM);
      arrows2.resize(195,150);
    }
  }
  
  // Draw the user finger to illustrate the issues with occlusion (the fat finger problem)
  imageMode(CORNER);
  image(fingerOcclusion, mouseX - FINGER_OFFSET, mouseY - FINGER_OFFSET);
}

// Check if mouse click was within certain bounds
boolean didMouseClick(float x, float y, float w, float h)
{
  return (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h);
}


int keyX,keyY;
PVector begin,end;

void mouseReleased(){
  if(begin.x != 0 && hasStarted){
    end = new PVector(mouseX,mouseY);
    PVector v1,v2;
    v1 = end.sub(begin);
    v2 = new PVector(1,0);
    char letter = 'a';
    
    if(keyY == 0){
        letter += 4*keyX;
    }else if(keyY == 1){
      if(keyX == 0)
        letter += 4*3;
      else
        letter += 4*3+3+4*(keyX-1);
    }
    
    if(v1.mag() > 0.1*PPCM){
      float angle = PVector.angleBetween(v1,v2);
      
      if (keyY < 2) {
      
      
          if(angle < PI/4){//right
            if(keyY == 1 && (keyX == 0 || keyX == 3))letter += 2;
            else letter += 3;
          }else if(angle < 3*PI/4){ //up or down
            if(keyY == 1 && keyX == 0) letter += 1;
            else letter += 2;
          }else{ //left
            letter += 1;
          }
      }
      else {
        if(keyX == 1 && currentTyped.length() > 0) {
          //for recomendations
          if(angle < 4.0*PI/10){//right
              currentTyped += recomendations.get(2).substring(currentWord.length(), recomendations.get(2).length()) + ' ';
          }else if(angle < 6.0*PI/10){ //up or down
              currentTyped += recomendations.get(1).substring(currentWord.length(), recomendations.get(1).length()) + ' ';
          }else{ //left
              currentTyped += recomendations.get(0).substring(currentWord.length(), recomendations.get(0).length()) + ' ';
          }
       }
      }
     
     
     }
    
    
    
    if(keyY != 2) {
      currentTyped += letter;
    }
      
      if (currentTyped.length() > 0) {
        String[] currentWords = splitTokens(currentTyped);
        currentWord = currentWords[currentWords.length - 1];
      
   
    
    recomendations = new StringList();
    
      if (currentTyped.charAt(currentTyped.length()-1) != ' ') {
        for (String word : frequentWords.get(currentWord.charAt(0) - 'a')) { //added recomendations
          String subword;
          if (word.length() >= currentWord.length()) subword = word.substring(0, currentWord.length());
          else continue;
          if (currentWord.equals(subword)) recomendations.append(word);
          if (recomendations.size() == 3) break;
        }
      }
      else {
        currentWord = "";
        recomendations.append("the");
        recomendations.append("of");
        recomendations.append("and");
      }
      
     }
  }
  else hasStarted = true;
  keyX = -1;
  keyY = -1;
}

void mousePressed()
{
  begin=new PVector(0,0);
  if (didMouseClick(width/2 - 2*PPCM, height/2 - 5.1*PPCM, 4.0*PPCM, 2.0*PPCM)) nextTrial();                         // Test click on 'accept' button - do not change this!
  else if(didMouseClick(width/2 - 2*PPCM, height/2 - 1*PPCM, 4*PPCM, 3*PPCM))  // Test click on 'keyboard' area - do not change this condition! 
  {
    // YOUR KEYBOARD IMPLEMENTATION NEEDS TO BE IN HERE! (inside the condition)
   
    begin = new PVector(mouseX,mouseY);
    
    //First row
    for(int i = 0;i < 3;i++){
      if(didMouseClick(width/2 - (2f-i*4f/3f)*PPCM, height/2 - 1f*PPCM, 4f/3f*PPCM, 1f*PPCM)){
        keyX = i;
        keyY = 0;
        return;
      }
    }
    
    
    // Second row
    for(int i = 0;i < 4;i++){
      if(didMouseClick(width/2 - (2f-i)*PPCM, height/2, 1f*PPCM, 1f*PPCM)){
        keyX = i;
        keyY = 1;
        return;
      }
    }
    
    //Third row
    for(int i = 0;i < 3;i++){
      if(didMouseClick(width/2 - (2f-i*4f/3f)*PPCM, height/2 + 1f*PPCM, 4f/3f*PPCM, 1f*PPCM)){
        if (i == 0) currentTyped+=" ";                   // if underscore, consider that a space bar
        else if (i == 2 && currentTyped.length() > 0)    // if `, treat that as a delete command
          currentTyped = currentTyped.substring(0, currentTyped.length() - 1);
        keyX = i;
        keyY = 2;
        return;
      }
    }
    
  }
  else System.out.println("debug: CLICK NOT ACCEPTED");
}


void nextTrial()
{
  if (currTrialNum >= NUM_REPEATS) return;                                            // check to see if experiment is done
  
  // Check if we're in the middle of the tests
  else if (startTime != 0 && finishTime == 0)                                         
  {
    System.out.println("==================");
    System.out.println("Phrase " + (currTrialNum+1) + " of " + NUM_REPEATS);
    System.out.println("Target phrase: " + currentPhrase);
    System.out.println("Phrase length: " + currentPhrase.length());
    System.out.println("User typed: " + currentTyped);
    System.out.println("User typed length: " + currentTyped.length());
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim()));
    System.out.println("Time taken on this trial: " + (millis() - lastTime));
    System.out.println("Time taken since beginning: " + (millis() - startTime));
    System.out.println("==================");
    lettersExpectedTotal += currentPhrase.trim().length();
    lettersEnteredTotal += currentTyped.trim().length();
    errorsTotal += computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
    typed[currTrialNum] = currentTyped;
  }
  
  // Check to see if experiment just finished
  if (currTrialNum == NUM_REPEATS - 1)                                           
  {
    finishTime = millis();
    System.out.println("==================");
    System.out.println("Trials complete!"); //output
    System.out.println("Total time taken: " + (finishTime - startTime));
    System.out.println("Total letters entered: " + lettersEnteredTotal);
    System.out.println("Total letters expected: " + lettersExpectedTotal);
    System.out.println("Total errors entered: " + errorsTotal);

    float wpm = (lettersEnteredTotal / 5.0f) / ((finishTime - startTime) / 60000f);   // FYI - 60K is number of milliseconds in minute
    float cps = lettersEnteredTotal / ((finishTime - startTime) / 1000f);
    float freebieErrors = lettersExpectedTotal * .05;                                 // no penalty if errors are under 5% of chars
    float penalty = max(0, (errorsTotal - freebieErrors) / ((finishTime - startTime) / 60000f));
    
    System.out.println("Raw WPM: " + wpm);
    System.out.println("Freebie errors: " + freebieErrors);
    System.out.println("Penalty: " + penalty);
    System.out.println("WPM w/ penalty: " + (wpm - penalty));                         // yes, minus, because higher WPM is better: NET WPM
    System.out.println("Characters per second: " + cps);
    System.out.println("==================");
    
    printResults(wpm, freebieErrors, penalty, cps);
    
    currTrialNum++;                                                                   // increment by one so this mesage only appears once when all trials are done
    return;
  }

  else if (startTime == 0)                                                            // first trial starting now
  {
    System.out.println("Trials beginning! Starting timer...");
    startTime = millis();                                                             // start the timer!
  } 
  else currTrialNum++;                                                                // increment trial number

  lastTime = millis();                                                                // record the time of when this trial ended
  currentTyped = "";                                                                  // clear what is currently typed preparing for next trial
  currentPhrase = phrases[currTrialNum];                                              // load the next phrase!
}

// Print results at the end of the study
void printResults(float wpm, float freebieErrors, float penalty, float cps)
{
  background(0);       // clears screen
  
  textFont(createFont("Arial", 16));    // sets the font to Arial size 16
  fill(255);    //set text fill color to white
  text(day() + "/" + month() + "/" + year() + "  " + hour() + ":" + minute() + ":" + second(), 100, 20);   // display time on screen
  
  text("Finished!", width / 2, height / 2); 
  
  int h = 20;
  for(int i = 0; i < NUM_REPEATS; i++, h += 40 ) {
    text("Target phrase " + (i+1) + ": " + phrases[i], width / 2, height / 2 + h);
    text("User typed " + (i+1) + ": " + typed[i], width / 2, height / 2 + h+20);
  }
  
  text("Raw WPM: " + wpm, width / 2, height / 2 + h+20);
  text("Freebie errors: " + freebieErrors, width / 2, height / 2 + h+40);
  text("Penalty: " + penalty, width / 2, height / 2 + h+60);
  text("WPM with penalty: " + max((wpm - penalty), 0), width / 2, height / 2 + h+80);
  text("Characters per second: " + cps, width / 2, height / 2 + h+100);

  saveFrame("results-######.png");    // saves screenshot in current folder    
}

// This computes the error between two strings (i.e., original phrase and user input)
int computeLevenshteinDistance(String phrase1, String phrase2)
{
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++) distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++) distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
}
