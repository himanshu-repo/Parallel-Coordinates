import controlP5.*;
 
import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;

FloatTable data;

int columnCount, rowCount;

int columnSpacing;

int boxBottom, boxTop, boxLeft, boxRight, boxWidth, boxHeight;

// min and max at each column // these will get manipulated by keep
float[] maxVal;
float[] minVal;


// a layer behind, the actual max and min values 
float[] origMaxVal;
float[] origMinVal;


// filters for each column
float[] filterMin;
float[] filterMax;


int[] columnPositions;  // contains the fixed positions

int[] currentPositions;  // contains real time positions

int[] currentOrder;   // contains the current ranking of the columns in terms of position 
int[] reverseMap; // indices of this array represent current order , values contain the indices of the actual columns

int movingAxis = -1;

int inRegion = -1;

boolean drawingFilter = false;
int drawingFilterForCol = -1;

boolean[] ascending;


int K=5;
int[] clusterNumber;  // will store the cluster for each row based on a particular column
int columnToCluster = -1 ;

float[][] clusterCentroids;
float[][] sum;  // sum of each attribute in each cluster to calculate centroid
int[] count;  // elements in each cluster


color[] clusterColor = {  
                          color(156,39,176),  // purple
                          color(3,169,244),  //blue
                          color(174,234,0),     //teal
                          color(255,202,40),   //amber
                          color(230,74,25) // red
                        };

boolean[] showCluster;


int  tranparency = 100; 

int counter = 0;


///////////////////////////colors

color backgroundColor = color(50);

color tickColor = color(0,255);

color tickValueColor = color(255,255);

color labelColor = color(198,255);
//color labelColor = color(158,255);
//color labelColor = color(0,255);

color axisColor = color(0,150);

color widgetBackground = color(70);

color widgetBorder = color(20);


/////////////////////////fonts

PFont calibriB20;

PFont calibri15; 

PFont consolasB30; 
///////////////////////////


int wstartX;
 int wstartY;

 int padding = 20;
 int buttonWidth = 40; 
 
 //////////////////////////


int totalCountFiltered =0;

int[] filteredPerCluster;


//////////////////////////////////////////////////////////// final project additions

boolean notFilter[];  // keeps a track if a not filter has been drawn on an attribute

boolean notIsOn;

int filterTransparency = 120; 


boolean[] isActive; // keeps track of visibility of axes

int colsOn;

ControlP5 cp5;

CheckBox mycheckbox;


color checkedColor = color(0,255,0);
color uncheckedColor = color(255,0,0);


int checkboxDim=20;
  
int checkBoxstartX=30, checkBoxstartY=400;

PImage expandcursor;

int atMin = -1; // holds 0,1,-1 depending on if the cursor is at the top / bottom / neither of end of the filter 

int expandingFilterForCol = -1;

boolean expandingFilter=false;


int loadX=400, loadY=250, loadWidth=80, loadHeight=40;

int saveX=1200, saveY=250, saveWidth=80, saveHeight=40;

int keepX=800, keepY=250, keepWidth=80, keepHeight=40;


String expression;

ScriptEngine engine = new ScriptEngineManager().getEngineByName("JavaScript");

boolean displayExpErr = false;

int errStartTime;

boolean showTicks = true;

boolean showHisto = false;

///////////////////////////////////////////////////////////

void cluster()
{
    
  //clustering based on all attributes
  if( columnToCluster == -1)
  {
    
    //Step 1 : set the K first elements as the K centroids
    for(int i=0; i<K; i++)
    {
      for(int j=0; j<columnCount; j++)
      {
        clusterCentroids[i][j] = data.getFloat(i,j);
      }
    }  
    
    int numIterations = 0;
    int changed=1;
    
    while(changed!=0 && numIterations!=50 )
    {
        changed = 0;
      
        //Step 2 : Calculate distance of each point from the centroids
        
        float[] distance = new float[K];  // stores distance of a particular point from all centroids
        
        float tempValue;
        
        for(int q=0; q<rowCount; q++)  // for each data row
        {
          
          //tempValue = 0;
          
          // 1. for each clusterCentroid  calculate the distance
          for(int i=0; i<K; i++)      
          {
              // distance from centroid i 
              
              tempValue = 0;
              
              for(int j=0; j<columnCount; j++)    // for each column
              {
                  tempValue += pow( (clusterCentroids[i][j] - data.getFloat(q,j)) , 2 ) ; 
              }
              
              // No need to sqrt , can compare the square sum itself
              distance[i] = tempValue ;
          }
          
          //2. figure which distance is min
          
          float minValue = distance[0];
          int minIndex = 0;
          
          for(int i=1; i<K; i++)
          {
              if(distance[i]<minValue)
              {
                minValue = distance[i];
                minIndex = i;
              }
          }
          
          //3. assign to cluster with least distance if the new cluster is diff from old
          
          if(clusterNumber[q] != minIndex)
          {
              changed++;
              clusterNumber[q] = minIndex;
          }
                
        }
        
        // Once all the elements have been assigned, update the centroids
        
        
              // intialise sum and count vectors
              for(int i=0; i<K; i++)  // run through all centroids
              {
                   count[i] = 0;
                  
                  for(int j=0; j<columnCount; j++)  // run through all columns
                  {
                      sum[i][j] = 0.0;
                  }
              }
        
        int clusNum;
        
        for(int q=0; q<rowCount; q++)  // run through each row 
        {
            clusNum = clusterNumber[q];
          
            count[clusNum]++;
          
            for(int j=0; j<columnCount; j++)  // run through all columns
            {          
              sum[clusNum][j] += data.getFloat(q,j); 
            }
        } 
        
        //after calculating sum , do the average and store in centroid 
        for(int i=0; i<K; i++)  // run through all centroids
        {
            for(int j=0; j<columnCount; j++)  // run through all columns
            {
              clusterCentroids[i][j] = sum[i][j] / count[i] ;
              
              //sum[i][j] = 0;
              
            }
            //count[i] = 0;
        }
        
        //assign the sum to the centroids, clear the sum and count
        
       numIterations++; 
    }
  }
}





void setup()
{
  size(1600,900);
  //size(1280,840);
  //size(700,500);
  
  wstartX = width/2 - (padding*5 + buttonWidth*4)/2;
  
  //wstartX = 900;
  
  calibriB20 = loadFont("Calibri-Bold-20.vlw");
  consolasB30 = loadFont("Consolas-Bold-30.vlw");
  calibri15 = loadFont("Calibri-15.vlw");;
  
  //data = new FloatTable("cars.okc");
  
  data = new FloatTable("energy.okc");
  
  rowCount = data.getRowCount();
  columnCount = data.getColumnCount();
  
  clusterNumber = new int[rowCount];
  clusterCentroids = new float[K][columnCount];
  sum = new float[K][columnCount];
  count = new int[K];
  showCluster = new boolean[K];
  
  for(int i=0; i<K; i++)
  {
    showCluster[i] = true;
  }
  
  filteredPerCluster = new int[K];
  
  cluster();
    
  maxVal = new float[columnCount];
  minVal = new float[columnCount];
  
  origMaxVal = new float[columnCount];
  origMinVal = new float[columnCount];
  
  filterMax = new float[columnCount];
  filterMin = new float[columnCount];
  
  ascending = new boolean[columnCount];
  
  notFilter = new boolean[columnCount];
  
  isActive = new boolean[columnCount];
  
  colsOn = columnCount;
  
  for(int i = 0; i < columnCount; ++i)
   {
     filterMax[i] = maxVal[i] = origMaxVal[i] = data.getColumnMax(i);
     filterMin[i] = minVal[i] = origMinVal[i] = data.getColumnMin(i);
    
     ascending[i] = true;
     
     notFilter[i] = false;
     
     isActive[i] = true;
   }
  
    
  //drawing area box
  
  //lab3
  //int horizontalMargin = 0;
  
  int horizontalMargin = 100;
  
  /* // working for lab3
  boxBottom = height - 100 ;
  boxTop  = 300 ;
  */
  
  //trial 1
  boxBottom = height - 150 ;
  boxTop  = 350 ;
  
  /*//lab3
  boxLeft = horizontalMargin;
  boxRight = width - horizontalMargin;
  */
  boxLeft = horizontalMargin;
  boxRight = width;
  
  
  boxWidth = boxRight - boxLeft;
  boxHeight = boxBottom - boxTop;
  
  columnSpacing = boxWidth/(columnCount+1) ;

  columnPositions = new int[columnCount];
  
  currentPositions = new int[columnCount];
  
  currentOrder = new int[columnCount];
  
  reverseMap = new int[columnCount];
  
  int runningX = boxLeft + columnSpacing ;
  
  for(int i = 0; i < columnCount; ++i)
  {
    currentPositions[i] = columnPositions[i] = runningX;
    
    reverseMap[i] = currentOrder[i] = i;
    
    runningX += columnSpacing ;
  } 
  
  //wstartX = columnPositions[0] - 100 ;  
 
 
 //set it dalse to begin with
 notIsOn = false;
    
    
 expandcursor =  loadImage("varrow1.png");
 
 
 setInputBox();
 
 
}


void setInputBox()
{
    cp5 = new ControlP5(this);
    
    cp5.addTextfield("expression")
       .setPosition(200, boxBottom+75)
       .setSize(1100, 25)
       .setAutoClear(false)
       .setFont(calibri15)
       .setText("State & Total & Per_Capita & Residential & Commercial & Industrial & Transportation & Petroleum & Natural_Gas & Coal & Hydroelectric & Nuclear")
       ;
    
    expression = "State & Total & Per_Capita & Residential & Commercial & Industrial & Transportation & Petroleum & Natural_Gas & Coal & Hydroelectric & Nuclear";
    
    cp5.addBang("Submit").setPosition(1325, boxBottom+75).setSize(35, 25);
    cp5.addBang("Reset").setPosition(1385, boxBottom+75).setSize(35, 25);    
}

void Reset()
{
  cp5.get(Textfield.class,"expression").setText("State & Total & Per_Capita & Residential & Commercial & Industrial & Transportation & Petroleum & Natural_Gas & Coal & Hydroelectric & Nuclear");
  expression = "State & Total & Per_Capita & Residential & Commercial & Industrial & Transportation & Petroleum & Natural_Gas & Coal & Hydroelectric & Nuclear";
  
  for(int i=0; i<columnCount; i++)
  {
    isActive[i] = true;
  }
}

void Submit() {
  /*
  print("the following text was submitted :");
  expression = cp5.get(Textfield.class,"expression").getText();
  println(" textInput 1 = " + expression);
  */
  
  String temp = cp5.get(Textfield.class,"expression").getText();
  
  boolean flag = true;
  
  for(int currCol = 0; currCol < columnCount; ++currCol)
  {
      if(!isActive[currCol])
      {
        // check id inactive axis present in expr
        if(temp.indexOf(data.columnNames[currCol]) != -1)
        {
  
            flag = false;
            break;
        }
      }
  }
  
  if(flag)
  {
    print("Yes");
    expression = temp;
  }
  else
  {
    print("NO!!");
    
    displayExpErr = true;
    
    errStartTime = millis();
  }
   
}


boolean checkFilter(int currRow)
{
    boolean filterPass = true;
    
    float val;
    
    //String expression= cp5.get(Textfield.class,"expression").getText();
    
    String newexp = expression;
    
    for(int currCol = 0; currCol < columnCount; ++currCol)
    {
      
      filterPass = true;
      
      // final project - if axes not active dont do filter check on that attribute
      //assuming if an axis is deactive, it will not be a part of the exp
      if(!isActive[currCol])
      {
        continue;
      }
      
      // if a column name is not present in the expression do not check that column name at all
      if(newexp.indexOf(data.columnNames[currCol]) == -1)
      {
        continue;
      }
      
      val = data.getFloat(currRow,currCol);
      
     
      if(!notFilter[currCol])
      {
        if( val < filterMin[currCol] || val > filterMax[currCol])
        {
           filterPass = false;
           //break;
        }
      }
      else  // if the not filter is active on a column value should be outside the filter rather inside
      {
        if( (val >= filterMin[currCol] && val <= filterMax[currCol]) || val > maxVal[currCol] || val < minVal[currCol])
        {
           filterPass = false;
           //break;
        }
      }
      
      if(filterPass)
      {
        newexp = newexp.replace(data.columnNames[currCol],"1");
      }
      else
      {
        newexp = newexp.replace(data.columnNames[currCol],"0");
      }
      
    }
    
    String result="0.0";
   
    try
    {
      result = engine.eval(newexp).toString();
    }
    catch( ScriptException e)
    {
      println("blahshit!!");
    }
    
    
    if(result.equals("1.0"))
    {
      return true;
    }
    else
    {
      return false;
    }
}


void updateColPos()
{
    columnSpacing = boxWidth/(colsOn+1) ;
  
    int runningX = boxLeft + columnSpacing ;
  
    for(int i = 0; i < columnCount; ++i)
    {
      if(!isActive[reverseMap[i]])
        continue;
      
      currentPositions[i] = columnPositions[i] = runningX;
      
      reverseMap[i] = currentOrder[i] = i;
      
      runningX += columnSpacing ;
    } 
}



void drawAxes()
{ 
   strokeWeight(4);
   stroke(axisColor);
     
   for(int i = 0; i < columnCount; ++i)
   {
     //finalproject
     
     if(!isActive[reverseMap[i]])
       continue;
     
     //float maxVal = data.getColumnMax(i);
     //float minVal = data.getColumnMin(i);
     
     // draw axis according to currentPosition instead of fixedposition         
     //line(columnPositions[i], boxBottom, columnPositions[i], boxTop);
     line(currentPositions[i], boxBottom, currentPositions[i], boxTop);
     
     //text("Min: "+minVal, columnPositions[i],boxBottom + 20);
     //text("Max: "+maxVal, columnPositions[i],boxBottom + 40);     
   }
}


void drawDataLines()
{
    totalCountFiltered =0;
  
    for(int i=0; i<K; i++)
    {
      filteredPerCluster[i] =0;
    }
  
    noFill();
  
    strokeWeight(2);
      
    float x,y, val;
  
    boolean filterPass = false;
    
    //color c, newColor;
  
    //for(int currRow = 0; currRow < 10; ++currRow  )
    for(int currRow = 0; currRow < rowCount; ++currRow  )
    {
      
      if(!showCluster[clusterNumber[currRow]])
      {
        //continue;
        if( clusterNumber[currRow] == 1 || clusterNumber[currRow] == 2)
        {
          tranparency = 8;
        }
        else if(clusterNumber[currRow] == 0 )
        {
          tranparency = 15;
        }
        else
        {
          tranparency = 3;
        } 
      }
      else
      {
        tranparency = 100;
      }
      
      
      // draw a line only if it clears all filters
      
      filterPass = checkFilter(currRow);
      
      /*
      filterPass = true;
      
      for(int currCol = 0; currCol < columnCount; ++currCol)
      {
        
        // final project - if axes not active dont do filter check on that attribute
        if(!isActive[currCol])
          continue;
        
        val = data.getFloat(currRow,currCol);
        
        // working lab 3
        //if( val < filterMin[currCol] || val > filterMax[currCol])
        //{
         //  filterPass = false;
         //  break;
        //} 
         
        
        /////////finalProject
        if(!notFilter[currCol])
        {
          if( val < filterMin[currCol] || val > filterMax[currCol])
          {
             filterPass = false;
             break;
          }
        }
        else  // if the not filter is active on a column value should be outside the filter rather inside
        {
          //if( val >= filterMin[currCol] && val <= filterMax[currCol])
          //check for current max and min values as well
          if( (val >= filterMin[currCol] && val <= filterMax[currCol]) || val > maxVal[currCol] || val < minVal[currCol])
          {
             filterPass = false;
             break;
          }
        }
      }
      */
      
      
      if(filterPass)
      {
        totalCountFiltered++;
          
        filteredPerCluster[clusterNumber[currRow]]++;
        
        beginShape();
        
        for(int currCol = 0; currCol < columnCount; ++currCol)  // currCol being treated as current order
        {
              // final project - if axes not active dont draw this point
              if(!isActive[reverseMap[currCol]])
                continue;
          
              color c = clusterColor[clusterNumber[currRow]] ;
              
              color newColor = color( red(c), green(c), blue(c), tranparency);
              
              //stroke(clusterColor[clusterNumber[currRow]]);
              stroke(newColor);
          
              //instead of drawing column by column we have to draw in current order 
              //val = data.getFloat(currRow,currCol);
              val = data.getFloat(currRow,reverseMap[currCol]);
              
              // instead of fixed positions use current positions
              //x = columnPositions[currCol];
              x = currentPositions[currCol];
                           
             
               //if(ascending[currCol])
               if(ascending[reverseMap[currCol]])
               {
                   //y = map(val, minVal[currCol], maxVal[currCol], boxBottom, boxTop);
                 y = map(val, minVal[reverseMap[currCol]], maxVal[reverseMap[currCol]], boxBottom, boxTop);  
               }
               else
               {
                   y = map(val, minVal[reverseMap[currCol]], maxVal[reverseMap[currCol]], boxTop, boxBottom);
               }
              
              vertex(x, y);
              /*
              if(currCol ==0 || currCol == columnCount -1 )
              {
                curveVertex(x, y);
              }
              curveVertex(x, y);
               */       
           
               if(showHisto)
               {
                 stroke(255,0,0,180);
                 ellipse(x, y, 5, 5); 
              
                 stroke(newColor);   
               }
        }
  
        endShape();
      }  
    }  
    
    //tint(255, 255);
    
}

void changeMousePointer()
{
  boolean flag = false;
  
  // check for proximity with all the columns

  int i;

  for(i = 0; i < columnCount; ++i)  // i is used as current order 
  {
    if(!isActive[reverseMap[i]])
      continue;
    
    
    if( (mouseX <= (columnPositions[i] + 10) ) &&  (mouseX >= (columnPositions[i] - 10) ) && (mouseY >= boxTop) && ( mouseY <= boxBottom ))
    {
      flag = true;
      break;
    }
  }

  int filterMinX,filterMaxX;

  int buffer = 10;

  if(flag)
  {
    //inRegion = i;   //current column
   inRegion = reverseMap[i];       
    //cursor(CROSS);
    
    // check if the cursor is near the edege of the the filter
    
    //map the filter max and filter min to pixels
      
       float pixel1;
       float pixel2;

       if(expandingFilter == false)
       {
         if(ascending[i])
         {       
           pixel1 = map(filterMin[reverseMap[i]], minVal[reverseMap[i]], maxVal[reverseMap[i]], boxBottom, boxTop);
           pixel2 = map(filterMax[reverseMap[i]], minVal[reverseMap[i]], maxVal[reverseMap[i]], boxBottom, boxTop);      
         }
         else
         {
           pixel1 = map(filterMin[reverseMap[i]], minVal[reverseMap[i]], maxVal[reverseMap[i]], boxTop, boxBottom);
           pixel2 = map(filterMax[reverseMap[i]], minVal[reverseMap[i]], maxVal[reverseMap[i]], boxTop, boxBottom);
         }
         
         if( mouseY<(pixel1+buffer) &&  mouseY>(pixel1-buffer) ) 
         {
           cursor(expandcursor,10,10);
           
           atMin = 1; 
         }
         else if( mouseY<(pixel2+buffer) &&  mouseY>(pixel2-buffer) )
         {
           cursor(expandcursor,10,10);
           
           atMin = 0;
         }
         else
         {
           cursor(CROSS);
           
           atMin = -1;
         }
       }
  }
  else
  {
    inRegion = -1;
    cursor(ARROW);
  }
  
    
  // chceck for promixity with order buttons
  
  for(i = 0; i < columnCount; ++i)
  {
      if(!isActive[reverseMap[i]])
        continue;
    
      // check within a rectangle of 20*15
      if( (mouseX <= (columnPositions[i] + 10) ) &&  (mouseX >= (columnPositions[i] - 10) ) && (mouseY < boxTop-10) && ( mouseY > boxTop-25 ) )
      {
         // do this on click in that region
         //ascending[i] = !ascending[i];   
         
         //for now just change the mouse
         cursor(HAND);
         
      }
  }
  
  
  // check for proximity with labels
  
  for(i = 0; i < columnCount; ++i)
  {
    
     if(!isActive[reverseMap[i]])
        continue;
        
        
      if( (mouseX <= (columnPositions[i] + textWidth(data.getColumnName(i))/2 ) ) &&  (mouseX >= (columnPositions[i]) - textWidth(data.getColumnName(i))/2 ) && (mouseY < boxBottom+30) && ( mouseY > boxBottom +10 ) )
      {
        cursor(MOVE);
      }  
  }
  
  
  // check for clear filter
  
  if(mouseX>=20 && mouseX<= 120 && mouseY>= (height-60) && mouseY<=(height-20))
  {
    cursor(HAND);
  }
  
  
  // check for reset filter
  
  if(mouseX>=20 && mouseX<= 120 && mouseY>= (height-110) && mouseY<=(height-70))
  {
    cursor(HAND);
  }
  
  
  // check for cluster select 
  for(i=0; i<K; i++)
  {
    if( mouseX>= (wstartX + 15 + i*buttonWidth + padding*i) && mouseX<=(wstartX + 15 + i*buttonWidth + padding*i + 40) && mouseY>=(wstartY+30 + 10) && mouseY<=(wstartY+30 + 10 + 40) )
     {
       cursor(HAND);
     }  
    //rect(wstartX + 15 + i*buttonWidth + padding*i, wstartY+30 + 10, 40,40,15,15,15,15);
  }
  
  
  // check for column checkboxes
  /*
  for(int i=0; i<12; i++)
  {
      rect(checkBoxstartX,400+i*30,checkboxDim,checkboxDim,5);
  
      text(colNames[i], checkBoxstartX + checkboxDim + 10 ,400+i*30 + checkboxDim);
  }
  */
  
  if(mouseX>=checkBoxstartX && mouseX<=140 && mouseY>checkBoxstartY && mouseY<(checkBoxstartY+30*12))
  {
    cursor(HAND);
  }
  
  //check for save button
  //if(mouseX>=1200 && mouseX<=1280 && mouseY>=250 && mouseY<=290)
  if(mouseX>=saveX && mouseX<=(saveX+saveWidth) && mouseY>=saveY && mouseY<=(saveY+saveHeight))
  {
    cursor(HAND);
  }
  
  
  //check for load button
  //if(mouseX>=400 && mouseX<=480 && mouseY>=250 && mouseY<=290)
  if(mouseX>=loadX && mouseX<=(loadX+loadWidth) && mouseY>=loadY && mouseY<=(loadY+loadHeight))
  {
    cursor(HAND);
  }
  
  //check for keep button
  if(mouseX>=keepX && mouseX<=(keepX+keepWidth) && mouseY>=keepY && mouseY<=(keepY+keepHeight))
  {
    cursor(HAND);
  }
}

void drawRectangle()
{
  if(!notIsOn)
  {
    strokeWeight(4);
    stroke(0,filterTransparency);
    fill(140,filterTransparency);
    
    //rect(startX, startY, endX-startX, endY-startY);
    //rect(columnPositions[drawingFilterForCol]-10, startY, 20, endY-startY);
    //rect(currentPositions[currentOrder[drawingFilterForCol]]-10, startY, 20, endY-startY);
    rect(columnPositions[currentOrder[drawingFilterForCol]]-10, startY, 20, endY-startY);
  }
  else
  {
    strokeWeight(4);
    stroke(0,filterTransparency);
    fill(229,57,53,filterTransparency);
   
    rect(columnPositions[currentOrder[drawingFilterForCol]]-10, startY, 20, endY-startY);
  }
}


void drawFilters()
{
  
  
  strokeWeight(4);
  stroke(0,150);
  fill(140,150);
  
  for(int i = 0; i < columnCount; ++i)   // using i as orignal order 
  {
    
    if(!isActive[i]) //#check
      continue;
    
    if(!notFilter[i])
    {
      strokeWeight(4);
      stroke(0,filterTransparency);
      fill(140,filterTransparency);
    }
    else
    {
      strokeWeight(4);
      stroke(0,filterTransparency);
      fill(229,57,53,filterTransparency);
    }
    
    
    // if the entire range is not covered draw the filter rectangle
    
    //if( filterMax[i] != maxVal[i] && filterMin[i] != minVal[i] )
    if( filterMax[i] == maxVal[i] && filterMin[i] == minVal[i] )
    {
    }
    else
    {
      
      //map the filter max and filter min to pixels
      
       float pixel1;
       float pixel2;

       if(ascending[i])
       {       
         pixel1 = map(filterMin[i], minVal[i], maxVal[i], boxBottom, boxTop);
         pixel2 = map(filterMax[i], minVal[i], maxVal[i], boxBottom, boxTop);      
       }
       else
       {
         pixel1 = map(filterMin[i], minVal[i], maxVal[i], boxTop, boxBottom);
         pixel2 = map(filterMax[i], minVal[i], maxVal[i], boxTop, boxBottom);
       } 
             
       //rect(columnPositions[i]-10, pixel1, 20, pixel2 - pixel1);
       rect(currentPositions[currentOrder[i]]-10, pixel1, 20, pixel2 - pixel1);
       
       
       //////////////////drawing filter values
        stroke(tickValueColor);
      fill(tickValueColor);
      
      int yPix;
      
      if(ascending[i])
      {
        stroke(100,150);
        strokeWeight(1);
        fill(100,100);
        
        yPix = (int) map(filterMin[i],minVal[i],maxVal[i],boxBottom, boxTop );
        
        rect(currentPositions[currentOrder[i]] + 15 , yPix, (int)textWidth(Float.toString(filterMin[i])) , 15);
        
        fill(255);
        
        text( filterMin[i] , currentPositions[currentOrder[i]] + 15, yPix+10);
        
        //fill(70,150);
        //rect(currentPositions[currentOrder[i]] + 15 , (boxBottom+boxTop)/2 - 13, (int)textWidth(Float.toString((minVal[i] + maxVal[i])/2))*2 , 15);
        
        
        fill(100,100);
        
        yPix =(int) map(filterMax[i],minVal[i],maxVal[i],boxBottom, boxTop );
        
        rect(currentPositions[currentOrder[i]] + 15 , yPix, (int)textWidth(Float.toString(filterMax[i])) , 15);
        
        fill(255);
        
        text( filterMax[i] , currentPositions[currentOrder[i]] + 15, yPix+10);
        
       
        
        //text( minVal[i] , currentPositions[currentOrder[i]] + 15, boxBottom);  
        //text( (minVal[i] + maxVal[i])/2 , currentPositions[currentOrder[i]] + 15, (boxBottom+boxTop)/2);
        //text( maxVal[i] , currentPositions[currentOrder[i]] + 15, boxTop);
      }
      else
      {
        /*
        stroke(100,150);
        strokeWeight(1);
        fill(100,100);
        
        rect(currentPositions[currentOrder[i]] + 15 , boxBottom - 13, (int)textWidth(Float.toString(maxVal[i]))*2 , 15);
        
        
        fill(70,150);
        rect(currentPositions[currentOrder[i]] + 15 , (boxBottom+boxTop)/2 - 13, (int)textWidth(Float.toString((minVal[i] + maxVal[i])/2))*2 , 15);
        
        
        fill(100,100);
        rect(currentPositions[currentOrder[i]] + 15 , boxTop - 13, (int)textWidth(Float.toString(minVal[i]))*2 , 15);
        
        fill(255);
        
        text( minVal[i] , currentPositions[currentOrder[i]] + 15, boxTop);
        text( (minVal[i] + maxVal[i])/2 , currentPositions[currentOrder[i]] + 15, (boxBottom+boxTop)/2);
        text( maxVal[i] , currentPositions[currentOrder[i]] + 15, boxBottom );
        */
        
        
        stroke(100,150);
        strokeWeight(1);
        fill(100,100);
        
        yPix = (int) map(filterMin[i],minVal[i],maxVal[i], boxTop,boxBottom );
        
        rect(currentPositions[currentOrder[i]] + 15 , yPix, (int)textWidth(Float.toString(filterMin[i])) , 15);
        
        fill(255);
        
        text( filterMin[i] , currentPositions[currentOrder[i]] + 15, yPix+10);
        
        //fill(70,150);
        //rect(currentPositions[currentOrder[i]] + 15 , (boxBottom+boxTop)/2 - 13, (int)textWidth(Float.toString((minVal[i] + maxVal[i])/2))*2 , 15);
        
        
        fill(100,100);
        
        yPix =(int) map(filterMax[i],minVal[i],maxVal[i], boxTop,boxBottom );
        
        rect(currentPositions[currentOrder[i]] + 15 , yPix, (int)textWidth(Float.toString(filterMax[i])) , 15);
        
        fill(255);
        
        text( filterMax[i] , currentPositions[currentOrder[i]] + 15, yPix+10);
      }  
    
   }
       
       
    }
}


void drawOrderButtons()
{

  for(int i = 0; i < columnCount; ++i)    // using i as current order
  {
    
    if(!isActive[reverseMap[i]])   //#check
      continue;
    
    // draw an upfacing or downfacing triangle accordint to ascending array
    
    stroke(0,200);
    strokeWeight(4);
    fill(204, 102, 0);
    
    if(ascending[reverseMap[i]])
    {
        beginShape();
        
        /*        
        vertex ( currentPositions[i] - 10, boxTop - 10 ) ;
        vertex ( currentPositions[i] + 10, boxTop - 10 ) ;
        vertex ( currentPositions[i], boxTop - 23 ) ;
        */
        
        curveVertex ( currentPositions[i] - 10, boxTop - 10 ) ; // 1
        
        curveVertex ( currentPositions[i] - 10, boxTop - 10 ) ; //1
        
        curveVertex ( currentPositions[i] + 10, boxTop - 10 ) ; //2
        
        curveVertex ( currentPositions[i], boxTop - 23 ) ;   //3
                
        curveVertex ( currentPositions[i] - 10, boxTop - 10 ) ; //1
        
        curveVertex ( currentPositions[i] + 10, boxTop - 10 ) ; //2
        
        curveVertex ( currentPositions[i] + 10, boxTop - 10 ) ; //2
        
                
        endShape(CLOSE);
        
    }
    else
    {
        beginShape();
        
        /*
        vertex ( columnPositions[i] - 10, boxTop - 23 ) ;
        vertex ( columnPositions[i] + 10, boxTop - 23 ) ;
        vertex ( columnPositions[i], boxTop - 10 ) ;
        */
        /*
        vertex ( currentPositions[i] - 10, boxTop - 23 ) ; //1
        vertex ( currentPositions[i] + 10, boxTop - 23 ) ; //2
        vertex ( currentPositions[i], boxTop - 10 ) ;      //3
        */
        
        curveVertex ( currentPositions[i] - 10, boxTop - 23 ) ; //1
        
        curveVertex ( currentPositions[i] - 10, boxTop - 23 ) ; //1
        
        curveVertex ( currentPositions[i] + 10, boxTop - 23 ) ; //2
        
        curveVertex ( currentPositions[i], boxTop - 10 ) ;      //3
        
        curveVertex ( currentPositions[i] - 10, boxTop - 23 ) ; //1
        
        curveVertex ( currentPositions[i] + 10, boxTop - 23 ) ; //2
        
        curveVertex ( currentPositions[i] + 10, boxTop - 23 ) ; //2
        
        endShape(CLOSE);
    }
    
    noFill();
  
  }


}

void drawLabels()
{
    textFont(calibriB20,20);
  
  
    fill(100);
    stroke(70);
    strokeWeight(2);
  
    for(int i = 0; i < columnCount; ++i)
    {
       if(!isActive[reverseMap[i]])
       continue;
      
      /*
      if( (mouseX <= (columnPositions[i] + textWidth(data.getColumnName(i))/2 ) ) &&  (mouseX >= (columnPositions[i]) - textWidth(data.getColumnName(i))/2 ) && (mouseY < boxBottom+30) && ( mouseY > boxBottom +10 ) )
      {
        
      } */
     
       rect( (currentPositions[i]) - textWidth(data.getColumnName(reverseMap[i]))/2 - 5, boxBottom +10 , textWidth(data.getColumnName(reverseMap[i]))+10, 25 ,6); 
    }
  
    fill(labelColor);
    // fill(103,58,183);
    //stroke(0);
    //strokeWeight(4);
      
    for(int i = 0; i < columnCount; ++i)  // using i as current order
    {
      if(!isActive[reverseMap[i]])
       continue;
      
      // use currentPositions instead of column positions
      //text( data.getColumnName(i), columnPositions[i], boxBottom + 15 );
            
      text( data.getColumnName(reverseMap[i]), currentPositions[i] - textWidth(data.getColumnName(reverseMap[i]))/2, boxBottom + 30 );
    }
  
}


void drawTicks()
{
    
  textFont(calibri15,15);
  
  strokeWeight(4);
  
  
  for(int i=0; i<columnCount; i++)    // treating i as orignal order
  {
    
    if(!isActive[i])
     continue;
    
    strokeWeight(4);
    stroke(tickColor);
    
    line ( currentPositions[currentOrder[i]] , boxBottom, currentPositions[currentOrder[i]] +7 , boxBottom);
    line ( currentPositions[currentOrder[i]] , boxTop, currentPositions[currentOrder[i]] +7 , boxTop);
    line ( currentPositions[currentOrder[i]] , (boxTop+boxBottom)/2, currentPositions[currentOrder[i]] +7 , (boxTop+boxBottom)/2); 
    
    
    
    stroke(tickValueColor);
    fill(tickValueColor);
    
    if(ascending[i])
    {
      stroke(100,150);
      strokeWeight(1);
      fill(100,100);
      
      rect(currentPositions[currentOrder[i]] + 15 , boxBottom - 13, (int)textWidth(Float.toString(minVal[i]))*2 , 15);
      
      
      fill(70,150);
      rect(currentPositions[currentOrder[i]] + 15 , (boxBottom+boxTop)/2 - 13, (int)textWidth(Float.toString((minVal[i] + maxVal[i])/2))*2 , 15);
      
      
      fill(100,100);
      rect(currentPositions[currentOrder[i]] + 15 , boxTop - 13, (int)textWidth(Float.toString(maxVal[i]))*2 , 15);
      
      fill(255);
      
      text( minVal[i] , currentPositions[currentOrder[i]] + 15, boxBottom);
      text( (minVal[i] + maxVal[i])/2 , currentPositions[currentOrder[i]] + 15, (boxBottom+boxTop)/2);
      text( maxVal[i] , currentPositions[currentOrder[i]] + 15, boxTop);
    }
    else
    {
      stroke(100,150);
      strokeWeight(1);
      fill(100,100);
      
      rect(currentPositions[currentOrder[i]] + 15 , boxBottom - 13, (int)textWidth(Float.toString(maxVal[i]))*2 , 15);
      
      
      fill(70,150);
      rect(currentPositions[currentOrder[i]] + 15 , (boxBottom+boxTop)/2 - 13, (int)textWidth(Float.toString((minVal[i] + maxVal[i])/2))*2 , 15);
      
      
      fill(100,100);
      rect(currentPositions[currentOrder[i]] + 15 , boxTop - 13, (int)textWidth(Float.toString(minVal[i]))*2 , 15);
      
      fill(255);
      
      text( minVal[i] , currentPositions[currentOrder[i]] + 15, boxTop);
      text( (minVal[i] + maxVal[i])/2 , currentPositions[currentOrder[i]] + 15, (boxBottom+boxTop)/2);
      text( maxVal[i] , currentPositions[currentOrder[i]] + 15, boxBottom );
    }  
    
  }
  
  

}

void drawTitleBar()
{
  //noStroke();
  
  stroke(0,200);
  strokeWeight(4);
  
  fill(0,150,136);
  
  rect(0,0,width,50);
  
  textFont(consolasB30,30);
  
  fill(0,255);
  
  text("Energy DataSet", 30 , 35);
}

int clusterSelectHeight = 90;

int pieStartX, pieStartY;
int piePadding = 30;
int diameter = 80;


void drawClusterSelect()
{
  //stroke(100,100);
  strokeWeight(4);
  //fill(100,100);
  
  stroke(widgetBorder);
  fill(widgetBackground);
  
  textFont(calibriB20,18);
   
  String labelString = "Show/Hide Clusters";  
  
  wstartY = 100 + ((diameter+ 2*piePadding) - clusterSelectHeight)/2 ; 
    
  //wstartX = 900; 
    
  //rect(wstartX, 100, 320, 90,15,15,15,15);
  //rect(wstartX, 100, K*buttonWidth + (K+1)*padding, 90,15,15,15,15);
  rect(wstartX, wstartY, max( (K*buttonWidth + (K+1)*padding), (textWidth(labelString) + padding*2) ), clusterSelectHeight,15,15,15,15);

  
  
  //fill(labelColor);
  fill(0);
  
  text(labelString,wstartX+ max( (K*buttonWidth + (K+1)*padding), (textWidth(labelString) + padding*2) )/2 - textWidth(labelString)/2 , wstartY+25);
  
  for(int i=0; i<K; i++)
  {
    fill(clusterColor[i]);
    
    if(showCluster[i])
    {
      stroke(0);
      strokeWeight(4);
    }
    else
    {
      noStroke();
    }
        
    rect(wstartX + 15 + i*buttonWidth + padding*i, wstartY+30 + 10, 40,40,15,15,15,15);
  }

}



void drawPieChart()
{
  stroke(widgetBorder);
  strokeWeight(4);
  
    
  pieStartX = columnPositions[columnCount-1] - piePadding - diameter/2;
  pieStartY = 100 ;
  
  
  fill(widgetBackground);
  rect(pieStartX,pieStartY, diameter + piePadding*2, diameter + piePadding*2,15,15,15,15);
  
  float[] angles1;
  
  float[] angles2;
 
  float lastAngle = 0;
  
  
  
  angles1 = new float[2];
  
  angles2 = new float[K];
 
  angles1[0] = 360 * totalCountFiltered / rowCount ;
 
  angles1[1] = 360 - angles1[0];
 
  int pieCenterX = columnPositions[columnCount-1] ;
  int pieCenterY = pieStartY + piePadding + diameter/2 +10;

  String pieLabel = "Total Selected";
  
  fill(0);
  
  textFont(calibriB20,18);
   
  //text(pieLabel,pieCenterX - textWidth(pieLabel), pieStartY+10 );
 text(pieLabel,pieStartX+20, pieStartY+25 ); 
 
 //text("angle1: "+angles1[0], 100, 100 );
 //text("angle2: "+angles1[1], 100, 130 );
 
 color[] greys = {98, 168}; 
    
 
  for (int i = 1; i >= 0; i--)
  {
    //float gray = map(i, 0, 2, 0, 255);
    fill(greys[i]);
    arc(pieCenterX, pieCenterY, diameter, diameter, lastAngle, lastAngle+radians(angles1[i]));
    lastAngle += radians(angles1[i]);
  }
  
  fill(0);
  ellipse(pieCenterX, pieCenterY,diameter/2,diameter/2);

  fill(18,255,3);
  
  
  
  int percentage = (int) totalCountFiltered * 100/ rowCount ;
  
  String centerValue = percentage+"%" ; 
  
  textFont(calibriB20,15);
  
  text(centerValue, pieCenterX - textWidth(centerValue)/2 ,pieCenterY +2);

}

int histogramPadding = 20;

void drawHistogram()
{
  int histogramWidth = (K + K+1 + 2)*histogramPadding;
  
  int histogramHeight = 140;
  
  //int histogramStartX = columnPositions[0] - histogramWidth/2 ;
  int histogramStartX = 80;
  
  int histogramStartY = 100;
  
   String histogramLabel = "Current Cluster Distribution";
  
  fill(widgetBackground);
  stroke(widgetBorder);
  strokeWeight(4);
  //rect(histogramStartX, histogramStartY,histogramWidth,histogramHeight,15,15,15,15);
  rect(histogramStartX, histogramStartY,max(histogramWidth, textWidth(histogramLabel) + 4*histogramPadding ) ,histogramHeight,15,15,15,15);
  
  
  //axis 
  
  //vertical 
  
  int originX = histogramStartX+histogramPadding;
  
  int originY = histogramStartY + histogramHeight - histogramPadding ;
  
  //int verticalAxisHeight = (histogramStartY + histogramHeight - histogramPadding) - (histogramStartY + 2*histogramPadding);
  int verticalAxisHeight = 70;
 
  int horizontalAxisLength = ( histogramStartX +histogramWidth - histogramPadding) - (histogramStartX+histogramPadding);
  
    
  line(originX, originY, originX, originY - verticalAxisHeight );
  
  // horizontal
  
  line(originX, originY, originX + horizontalAxisLength, originY);
  
 
  
  textFont(calibriB20,18);
  fill(0);
  
  //text(histogramLabel, histogramStartX + histogramWidth/2 - textWidth(histogramLabel)/2 , histogramStartY+ 25 );
  text(histogramLabel, histogramStartX + histogramPadding , histogramStartY+ 25 );
  
  for(int i=0; i<K; i++)
  {
    fill(clusterColor[i]);
    stroke(clusterColor[i]);
    
    float percentage;
    
    if(totalCountFiltered!=0)
    {
      percentage = filteredPerCluster[i]*100/totalCountFiltered;
    }
    else
    {
      percentage = 0;
    }  
    
    float barHeight = map(percentage,0,100, 0, verticalAxisHeight );
    
    rect( originX + histogramPadding*(2*i +1) , originY, histogramPadding , -1 * barHeight  );
    
    textFont(calibriB20,15);
    
    fill(118,255,3);
    
    text((int)percentage+"%", originX + histogramPadding*(2*i +1), originY - barHeight - 10 );
  }
}

String clear = "Clear Filters";

void drawClearFilter()
{
  
  String clear = "Clear Filters";
  
  //stroke(widgetBorder);
  //fill(widgetBackground);
  
 // textFont(calibriB20,15);
  
  fill(100);
  stroke(70);
  strokeWeight(2);
  
  
  
  //rect(20,height - 60, textWidth(clear) +20, 40 , 15, 15 , 15 , 15);
  rect(20,height - 60, 100, 40 , 15, 15 , 15 , 15);

  textFont(calibriB20,17);
  
  //fill(0);
  fill(labelColor);
  
  text(clear, 20 + 10, height -45 + 10);

}

void drawResetData()
{
  String clear = "Reset Data";
  
  fill(100);
  stroke(70);
  strokeWeight(2);
  
  rect(20,height - 110, 100, 40 , 15, 15 , 15 , 15);

  textFont(calibriB20,17);
  
  fill(labelColor);
  
  text(clear, 20 + 10, height -95 + 10);
}


void drawNotifications()
{
  fill(255,0,0);
  
  if(notIsOn)
  {
    text("NOT brush active!",width-200,height-20);
  }
}




void drawCheckBoxes()
{
    /*
    cp5 = new ControlP5(this);
      mycheckbox = cp5.addCheckBox("MYCHECKBOX")
              .setPosition(285, 100)
              .setColorForeground(color(120))
              .setColorActive(color(255,0,0))
              .setColorLabel(color(0))
              .setSize(20, 20)
              .setItemsPerRow(1)
              .setSpacingColumn(30)
              .setSpacingRow(20)
              .addItem("Red", 0)
              .addItem("Green", 50)
              .addItem("Blue", 100)
              .addItem("Alpha", 150)
              ;
      */
      
      textFont(calibri15,15);
      /*
      cp5 = new ControlP5(this);
  
      mycheckbox = cp5.addCheckBox("MYCHECKBOX")
              .setPosition(50, 300)
              .setColorForeground(color(150))
              .setColorBackground(color(255,0,0))
              .setColorActive(color(0,255,0))
              .setColorLabel(color(255))
              .setSize(20, 20)
              .setItemsPerRow(1)
              .setSpacingColumn(10)
              .setSpacingRow(20)
              .addItem("State",0)
              .addItem("Total",1)
              .addItem("Per Capita",2)
              .addItem("Residential",2)
              .addItem("Commercial",3)
              .addItem("Industrial",4)
              .addItem("Transportation",5)
              .addItem("Petroleum",6)
              .addItem("Natural Gas",7)
              .addItem("Coal",8)
              .addItem("Hydroelectric",9)
              .addItem("Nuclear",10)
              ;                  
  
    mycheckbox.activate(5);
  */
  /*
  for(int i=0; i<columnCount ; i++)
  {  
      cp5.addItem("yes",i*5);
  }
  */
 
  
  String[] colNames = {"State","Total","Per Capita","Residential","Commercial","Industrial","Transportation","Petroleum","Natural Gas","Coal","Hydroelectric","Nuclear"};
  
  for(int i=0; i<12; i++)
  {
      if(isActive[i])
      {
        fill(checkedColor);
      }
      else
      {
        fill(uncheckedColor);
      }
    
      rect(checkBoxstartX,400+i*30,checkboxDim,checkboxDim,5);
      
      fill(150);
      
      text(colNames[i], checkBoxstartX + checkboxDim + 10 ,400+i*30 + checkboxDim);
  }
  
}

void drawSaveButton()
{ 
    textFont(calibriB20,20);
  
  
    fill(100);
    stroke(70);
    strokeWeight(2); 
  
   //rect(boxLeft + 3*(boxRight-boxLeft)/4 - 30, boxTop - 40 - 70, 60 , 40, 15);
   //text("Keep",boxLeft + 3*(boxRight-boxLeft)/4 - 15, boxTop - 40 - 70);
   
   //rect (1200, 250, 80,40,15);
   rect (saveX, saveY, saveWidth, saveHeight,15);
   
   fill(labelColor);
   
   //text("Save",1220,275);
   text("Save",saveX+20, saveY+25);
}

void drawLoadButton()
{
  textFont(calibriB20,20);
  
  
    fill(100);
    stroke(70);
    strokeWeight(2); 
  
   //rect(boxLeft + 3*(boxRight-boxLeft)/4 - 30, boxTop - 40 - 70, 60 , 40, 15);
   //text("Keep",boxLeft + 3*(boxRight-boxLeft)/4 - 15, boxTop - 40 - 70);
   
   //rect (400, 250, 80,40,15);
   rect (loadX, loadY, loadWidth,loadHeight,15);
   
   fill(labelColor);
   
   //text("Load",420,275);
   text("Load",loadX+20, loadY+25);
}

void drawKeep()
{
   textFont(calibriB20,20);
  
  
    fill(100);
    stroke(70);
    strokeWeight(2); 

   rect (keepX, keepY, keepWidth,keepHeight,15);
   
   fill(labelColor);

   text("Keep",keepX+20, keepY+25);

}

void drawExpErr()
{
  //print("called");
  
  stroke(255,0,0);
  fill(255,0,0);
  
  if((millis() - errStartTime) < 5000)
  {
    text("Please don't include invisible axes!",800,height-20);
  }
  else
  {
    errStartTime = 0;
    displayExpErr = false;
  }
}

void draw()
{
  //background(250,250,210);
  //background(255,255,240);
  background(backgroundColor);
 
 //text("Counter "+counter, 1000 , 40 );
 
 /********** Debugging code to check if data is being read in properly
 
   text("RowCount: "+rowCount, 100,120);
 
   text("ColumnCount: "+columnCount, 100,100);
    
    int k = 200;
  
    for(int i=0; i<data.getColumnNames().length;++i)
    {
      text(data.getColumnName(i), 100,k);
      
      k+= 50;
    }
  */

  /********* Debugging code to display table data
  strokeWeight(2);
  stroke(126);

  int currX = 100, currY = 100;

  for(int i=0; i<10;++i)
  {
      for(int j=0; j<columnCount;++j)
      {
        text(data.getFloat(i,j), currX, currY );
        currX += 50 ;
      }
      currY += 20 ;
      currX = 100;
  }
  */
  
  changeMousePointer();
  
  drawCheckBoxes();
  
  //drawAxes();
  
  drawTitleBar();
  
  drawClusterSelect();
  
  drawDataLines();
  
  drawPieChart();
  
  drawHistogram();
  
  if(mousePressed && mouseButton == LEFT && drawingFilterForCol != -1)
  {
    drawRectangle();
  } 
  
 
  
  drawAxes();
  
  if(showTicks)
  {
    drawTicks();
  }
  
  drawFilters();
  
  drawOrderButtons();    
  
  drawLabels();
  
  drawClearFilter();
  
  /*
  if(movingAxis != -1)
  {
    text(data.getColumnName(movingAxis),20,20);
  }
 
   text ("currentOrder[h]: "+ currentOrder[2], 300, 30);
  text ("currentOrder[w]: "+ currentOrder[3], 300, 45);
  text ("currentOrder[a]: "+ currentOrder[4], 300, 60);
  text ("reverseMap[2]: "+ data.getColumnName(reverseMap[2]), 450, 30);
  text ("reverseMap[3]: "+ data.getColumnName(reverseMap[3]), 450, 45);
  text ("reverseMap[4]: "+ data.getColumnName(reverseMap[4]), 450, 60);
  */
  
  /*
  // conditions for cluster box being tested
  for(int i=0; i<K; i++)
  {
     
    if( mouseX< (wstartX + 15 + i*buttonWidth + 40) && mouseX>(wstartX + 15 + i*buttonWidth) && mouseY<(wstartY+30 + 10 + 40) && mouseY>(wstartY+30 + 10) )
    {
        showCluster[i] = !showCluster[i];
    }
    
    int val1 = wstartX + 15 + i*buttonWidth ;
    int val2 = wstartX + 15 + i*buttonWidth + 40 ;
    
    text ("xmin"+i+": "+ val1, 50 + 200*i, 100);
    text ("xmax"+i+": "+ val2, 50 + 200*i, 145);
  } 
  
  text("mouse: "+mouseX+" "+ mouseY, 1000, 30);
  text("totalFilteredCount: "+totalCountFiltered, 1000, 30);
  
  for(int i=0; i<K; i++)
  {
    text("filteredPerCluster["+i+"]: "+filteredPerCluster[i], 1000, 30 + 30*(i+1));
  
  }*/
  
   //////////////////// finalproject addition
  
  drawNotifications(); 
  
  drawSaveButton();
  
  drawLoadButton();
  
  drawKeep();
  
  if(displayExpErr)
  {
    drawExpErr();
  }
  
  drawResetData();
}

int startX, startY , endX, endY;

void mousePressed()
{
  startX = mouseX;
  startY = mouseY;
  
  endX = mouseX;
  endY = mouseY;
  
  if( inRegion != -1)
  {
     if(atMin == -1)
     {
        drawingFilter = true;
        expandingFilter = false;
     }
     else
     {
       drawingFilter = false;
       expandingFilter = true;
     } 
  } 
  
  if(atMin == -1)
  {
    drawingFilterForCol = inRegion;
    expandingFilterForCol = -1;
  }
  else
  {
    drawingFilterForCol = -1;
    expandingFilterForCol = inRegion;
  }
  
  if(movingAxis == -1)
  {
    // check if mouse is on any of the labels
   for(int i = 0; i < columnCount; ++i)      // using i as current order
    {
        //if( (mouseX <= (columnPositions[i] + textWidth(data.getColumnName(i)) ) ) &&  (mouseX >= (columnPositions[i]) ) && (mouseY < boxBottom+20) && ( mouseY > boxBottom ) )
        //if( (mouseX <= (columnPositions[i] + textWidth(data.getColumnName(reverseMap[i])) ) ) &&  (mouseX >= (columnPositions[i]) ) && (mouseY < boxBottom+20) && ( mouseY > boxBottom ) )
        if( (mouseX <= (columnPositions[i] + textWidth(data.getColumnName(reverseMap[i]))/2 ) ) &&  (mouseX >= (columnPositions[i]) - textWidth(data.getColumnName(reverseMap[i]))/2 ) && (mouseY < boxBottom+30) && ( mouseY > boxBottom+10 ) )
        {
            // set the axis being moved to current axis
            
            // search in the currentorder array
            /*
            for(int j=0; j<columnCount; ++j)
            {
              if(currentOrder[j] == i)
              {
                movingAxis = j ;          // the actual axis being moved
                break;
              }
            }*/
            
            movingAxis = reverseMap[i];
            
        }  
    }
  }
}


void mouseReleased()
{
  
  //if( drawingFilter== true && inRegion!=-1)
  // filter should be atleast 3 pixels tall or else regular click
  if( drawingFilter && ( (endY-startY) > 3 || (endY-startY) < -3  )) 
  {
   
    
    // a filterDraw event just finished . Update filter min and max for that column
   
   // map the startY and endY points to attribute scale from pixel scale
   
     float val1;
     float val2;
   
     if(ascending[drawingFilterForCol])
     {
       val1 = map(startY, boxBottom, boxTop, minVal[drawingFilterForCol], maxVal[drawingFilterForCol] );
       val2 = map(endY, boxBottom, boxTop, minVal[drawingFilterForCol], maxVal[drawingFilterForCol] );
     }
     else
     {
       val1 = map(startY, boxTop, boxBottom, minVal[drawingFilterForCol], maxVal[drawingFilterForCol] );
       val2 = map(endY, boxTop, boxBottom, minVal[drawingFilterForCol], maxVal[drawingFilterForCol] );
     } 
   
     if(val1 < val2)
     {
        filterMin[drawingFilterForCol] = val1;
        filterMax[drawingFilterForCol] = val2;
     }
     else
     {
       filterMax[drawingFilterForCol] = val1;
       filterMin[drawingFilterForCol] = val2;
     }
    
    
    //////////finalProject
    if(notIsOn)
    {
      notFilter[drawingFilterForCol] = true;
    }
    
  }
  else if(expandingFilter==true)
  {
    expandingFilter = false;
    expandingFilterForCol = -1;
  }
  else
  {
      // it was a regular click , clear filters in this case if click outside the filter region
  
      if( inRegion != -1 )  // in some valid region
       {
         // check if the prev mouse position was outside the filter of the current region
         
         // map the filter values to pixels 
         
         float pixelMin = map(filterMin[inRegion], minVal[inRegion], maxVal[inRegion], boxBottom, boxTop);
         float pixelMax = map(filterMax[inRegion], minVal[inRegion], maxVal[inRegion], boxBottom, boxTop);
         
         if( pmouseY > pixelMin || pmouseY < pixelMax)   // clicked outside filter
         {
             //clear the filter 
             
             filterMax[inRegion] = maxVal[inRegion];
             filterMin[inRegion] = minVal[inRegion];
             
         }
         
         
         notFilter[inRegion] = false;
       } 
  }
  
  
   drawingFilter = false; 
   drawingFilterForCol = -1;
   
   movingAxis = -1;
   
   for(int i = 0; i < columnCount; ++i)
   {
       currentPositions[i] = columnPositions[i] ;
   }
   
   
}

void mouseDragged()
{
  
  float val; 
  int mousePos;
  
  if(drawingFilter == true)
  {
      endX = mouseX;
      
      if( mouseY<=boxBottom && mouseY>=boxTop)
      {
        endY = mouseY;
      }
      else if(mouseY>=boxBottom)
      {
        endY = boxBottom;
      }  
      else
      {
        endY = boxTop;
      }
  }
  else if(expandingFilter == true )
  {
      // update the filter 
      
      if( mouseY<=boxBottom && mouseY>=boxTop)
      {
        mousePos = mouseY;
      }
      else if(mouseY>=boxBottom)
      {
        mousePos = boxBottom;
      }  
      else
      {
        mousePos = boxTop;
      }
      
      if(atMin == 1)
      {
          if(ascending[expandingFilterForCol])
          {  
             val = map(mousePos, boxBottom, boxTop, minVal[expandingFilterForCol], maxVal[expandingFilterForCol]);
             
             if(val >= filterMax[expandingFilterForCol])
             {
                 atMin = 0;
                 
                 filterMax[expandingFilterForCol] = val;  
             }
             else
             {
               filterMin[expandingFilterForCol] = val;
             }  
          }
          else
          {
            val = map(mousePos,boxTop, boxBottom , minVal[expandingFilterForCol], maxVal[expandingFilterForCol]);
           
            if(val >= filterMax[expandingFilterForCol])
             {
                 atMin = 0;
                 
                 filterMax[expandingFilterForCol] = val;  
             }
             else
             {
               filterMin[expandingFilterForCol] = val;
             }
          } 
      }
      else if(atMin == 0) // at the max val
      {
          if(ascending[expandingFilterForCol])
          {
            val =   map(mousePos, boxBottom, boxTop, minVal[expandingFilterForCol], maxVal[expandingFilterForCol]);
            
            if(val < filterMin[expandingFilterForCol])
            {
              atMin = 1;
              filterMin[expandingFilterForCol] = val;
            }
            else
            {
              filterMax[expandingFilterForCol] = val;
            }
          }
          else
          {
            val = map(mousePos,boxTop, boxBottom , minVal[expandingFilterForCol], maxVal[expandingFilterForCol]);
            
            if(val < filterMin[expandingFilterForCol])
            {
              atMin = 1;
              filterMin[expandingFilterForCol] = val;
            }
            else
            {
              filterMax[expandingFilterForCol] = val;
            }
          }
      
      }
      
  }
 
  if(movingAxis != -1)
  {
     currentPositions[currentOrder[movingAxis]] = mouseX; 
      
     //text ("currentOrder[movingAxis]: "+ currentOrder[movingAxis], 300, 30);
      
     // if the axis getting dragged goes left of its left axis  .. check for first axis
     if(  currentOrder[movingAxis]!=0 && mouseX < columnPositions[ currentOrder[movingAxis] - 1 ] )
     { 
                  
         //text ("movingAxis: "+ movingAxis, 100, 30);
         //text ("currentOrder[movingAxis] - 1: "+ (currentOrder[movingAxis]-1), 100, 40);
        // text ("reverseMap[currentOrder[movingAxis] -1]: "+ reverseMap[currentOrder[movingAxis] -1], 100, 50);
        // text ("currentOrder[reverseMap[currentOrder[movingAxis] -1]]: "+ currentOrder[reverseMap[currentOrder[movingAxis] -1]], 100, 60);
         
          
        int temp1 = currentOrder[movingAxis];
        currentOrder[movingAxis] -= 1;
        currentOrder[ reverseMap[ temp1 - 1 ] ] += 1 ;
          
                  
         // swap for reversenmap
         /*
         int temp = reverseMap[currentOrder[movingAxis] + 1];
         
         reverseMap[currentOrder[movingAxis] + 1] = reverseMap[currentOrder[movingAxis] ] ;
         
         reverseMap[currentOrder[movingAxis] ] = temp;
         */
         
         int temp = reverseMap[temp1];
         
         reverseMap[temp1]  = reverseMap[temp1 - 1];
         
         reverseMap[temp1 - 1] = temp;
         
          for(int i = 0; i < columnCount; ++i)
          {
             currentPositions[i] = columnPositions[i] ;
          }
         
         currentPositions[currentOrder[movingAxis]] = mouseX;        
          
         //text("LEFT!!", 50, 10);
     }
     
     // if the axis getting dragged goes right of its right axis
     if( (currentOrder[movingAxis]!=columnCount-1)  && mouseX > columnPositions[ currentOrder[movingAxis] + 1 ] )
     {
         
                  
         int temp1 = currentOrder[movingAxis];
          currentOrder[movingAxis] += 1;
          currentOrder[ reverseMap[ temp1 + 1 ] ] -= 1 ;
         
         /*
         int temp = reverseMap[currentOrder[movingAxis] + 1];
         
         reverseMap[currentOrder[movingAxis] + 1] = reverseMap[currentOrder[movingAxis] ] ;
         
         reverseMap[currentOrder[movingAxis] ] = temp;
         */
         
         int temp = reverseMap[temp1];
         
         reverseMap[temp1]  = reverseMap[temp1 + 1];
         
         reverseMap[temp1 + 1] = temp;
         
          for(int i = 0; i < columnCount; ++i)
         {
             currentPositions[i] = columnPositions[i] ;
         }
         
         currentPositions[currentOrder[movingAxis]] = mouseX;
         
        // text("RIGHT!!", 50, 10);
     }
  }  
}

void saveCalled()
{
  selectInput("Save as:", "SaveAs");
}

void SaveAs(File selection)
{
  PrintWriter output;
  
  output = createWriter(selection);

  for(int i=0; i<columnCount; i++)
  {
    output.println(filterMin[i]+ "\t"+ filterMax[i]);
  }

  output.flush(); // Writes the remaining data to the file
  output.close(); // Finishes the file
}

void loadCalled()
{
  selectInput("Save as:", "Open");
}

void Open(File selection)
{
  BufferedReader reader;
  String line;
  
  reader = createReader(selection);
  
  try
  {
    line = reader.readLine();
  }
  catch (IOException e) {
    e.printStackTrace();
    line = null;
  }
  
  
  int ctr = 0;
  
  while(line != null)
  {
      String[] pieces = split(line, TAB);
      
      filterMin[ctr] = float(pieces[0]);
      filterMax[ctr] = float(pieces[1]);
      
      ctr++;
      
      try
      {
        line = reader.readLine();
      }
      catch (IOException e) {
        e.printStackTrace();
        line = null;
      }
  }
}


void keepCalled()
{
  for(int i=0; i<columnCount; i++)
  {
    if(!notFilter[i])
    {
       maxVal[i] = filterMax[i];
       minVal[i] = filterMin[i];
    }
  }
}

void mouseClicked()
{
  for(int i = 0; i < columnCount; ++i)  // i being used as order
  {
      
      // check within a rectangle of 20*15 for ascending/descending buttons
      if( (mouseX <= (columnPositions[i] + 10) ) &&  (mouseX >= (columnPositions[i] - 10) ) && (mouseY < boxTop-10) && ( mouseY > boxTop-25 ) )
      {
         // do this on click in that region
         ascending[reverseMap[i]] = !ascending[reverseMap[i]];   
         
         //for now just change the mouse
         //cursor(HAND);
         
      }
  }
  
  //check for show/hide cluster
  //rect(wstartX + 15 + i*buttonWidth + padding*i, wstartY+30 + 10, 40,40);
  for(int i=0; i<K; i++)
  {
    if( mouseX< (wstartX + 15 + i*buttonWidth + padding*i + 40) && mouseX>(wstartX + 15 + i*buttonWidth + padding*i) && mouseY<(wstartY+30 + 10 + 40) && mouseY>(wstartY+30 + 10) )
    {
        showCluster[i] = !showCluster[i];
    }
  }  
  
  
  // check for clear filter
  
  if(mouseX>=20 && mouseX<= 120 && mouseY>= (height-60) && mouseY<=(height-20))
  {
    //cursor(HAND);
    
    for(int i=0; i<columnCount; i++)
    {
      filterMax[i] = maxVal[i];
      filterMin[i] = minVal[i];
    }
    
  }
  
  // check for reset filter
  
  if(mouseX>=20 && mouseX<= 120 && mouseY>= (height-110) && mouseY<=(height-70))
  {
    //cursor(HAND);
    
    for(int i=0; i<columnCount; i++)
    {
      maxVal[i] = origMaxVal[i];
      minVal[i] = origMinVal[i];
    }
  }
  
  
  
  //check for visibility toggles
  if(mouseX>=checkBoxstartX && mouseX<=140 && mouseY>checkBoxstartY && mouseY<(checkBoxstartY+30*12))
  {
      int num = (mouseY-checkBoxstartY)/(checkboxDim+10);
    
      //isActive[(mouseY-checkBoxstartY)/(checkboxDim+10)] = !isActive[(mouseY-checkBoxstartY)/(checkboxDim+10)];
      isActive[num] = !isActive[num];
      
      //change the expression as well
      if(isActive[num]) //add with default &
      {
        expression = expression + " & " +  data.columnNames[num]; 
        
        cp5.get(Textfield.class,"expression").setText(expression);
      }
      else // something deactivated , remove it
      {
        // if it is not the first axis
        if(expression.indexOf(data.columnNames[num]) != 0 )
        {
          String tt1 = " & " +  data.columnNames[num] ;
          String tt2 = " | " +  data.columnNames[num] ;
          
          //test if it is and or or 
          if(tt1.indexOf(data.columnNames[num]) != -1 ) // it is and, replace and
          {
             expression = expression.replace(tt1,"");
          }
          else
          {
             expression = expression.replace(tt2,"");
          }
            
          cp5.get(Textfield.class,"expression").setText(expression);
        }
        else // it is the first axis
        {
            String tt1 =  data.columnNames[num] + " & ";
            String tt2 =  data.columnNames[num] + " | ";
            
            if(tt1.indexOf(data.columnNames[num]) != -1 ) // it is and, replace and
            {
               expression = expression.replace(tt1,"");
            }
            else
            {
               expression = expression.replace(tt2,"");
            }
            
            cp5.get(Textfield.class,"expression").setText(expression);
        }
      }
  }
  
  
  //check for save button
  if(mouseX>=saveX && mouseX<=(saveX+saveWidth) && mouseY>=saveY && mouseY<=(saveY+saveHeight))
  {
      saveCalled();
  }
  
  //check for load button
  //if(mouseX>=400 && mouseX<=480 && mouseY>=250 && mouseY<=290)
  if(mouseX>=loadX && mouseX<=(loadX+loadWidth) && mouseY>=loadY && mouseY<=(loadY+loadHeight))
  {
      loadCalled();
  }
  
  //check for keep button
  if(mouseX>=keepX && mouseX<=(keepX+keepWidth) && mouseY>=keepY && mouseY<=(keepY+loadHeight))
  {
      keepCalled();
  }
}



void keyPressed()
{
    if( key == 'n')
    {
      notIsOn = !notIsOn;
    }
    
    if( key == 't')
    {
      showTicks = !showTicks;
    }
    
    if( key == 'h')
    {
      showHisto = !showHisto;
    }
    
    /*
    if(key == '1')
    {
      isActive[1] = !isActive[1];
      
      if(isActive[1])// changed from false to true, inc active cols
      {
        colsOn++;
      }
      else
      {
        colsOn--;
      }
      
      //updateColPos();
    }
    if(key == '3')
    {
      isActive[3] = !isActive[3];
    }
    */
    
    if(key=='1')
    {
        K = 1;
        cluster();    
    }
    if(key=='2')
    {
        K = 2;    
        cluster();
    }
    if(key=='3')
    {
        K = 3;    
        cluster();
    }
    if(key=='4')
    {
        K = 4;    
        cluster();
    }
    if(key=='5')
    {
        K = 5;    
        cluster();
    }
}
