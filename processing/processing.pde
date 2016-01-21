/********************************************
    アルミ箔を内包した布スイッチにおける
    指の接触検知の実験
    
    2015 Iwasaki Seiya
********************************************/

import processing.serial.*;
import java.util.Arrays;

Serial port;                    // シリアル通信用クラス
long capValue;                  // 送信された静電容量の計測値を格納

final int fps = 30;             // フレームレート
final int squareQty = 3 * 3;    // 布スイッチ上のマス目の数
final int detectionNum = 6;     // 静電容量を検出する回数
final int detectionTime = 3;    // 静電容量の検出時間（秒）
final int detectionFrameNum = detectionTime * fps;

// detectionTime時間内に計測された静電容量の最小値・最大値・平均値
boolean isDetecting = false;
boolean isTouched = false;
double[][]   capEmp = new double[detectionNum][3];
double[][][] capVal = new double[detectionNum][squareQty][3];
int stageNo = 0;
int detectionCounter = 0;
int detectingCounter = -1;
int preDetectingCount = -1;
int squareCounter = 0;
int frameCounter = 0;
int[] detectionOrder = new int[squareQty];

PrintWriter writer;

void setup(){
    /** Serial通信の設定 **/
    printArray(Serial.list());            // 選択可能なシリアルポート一覧
    String portName = Serial.list()[0];
    port = new Serial(this, portName, 9600);
    
    /** Arduino 画面設定 **/
    size(displayWidth, displayHeight);
    frameRate(fps);
    smooth();
    colorMode(RGB, 256, 256, 256, 256);
    fill(#000000);
    rectMode(CENTER);
    textAlign(CENTER);
    PFont myf = createFont("メイリオ", 36, true);
    textFont(myf);

    /** 計測データ格納配列の初期化 **/
    for(int i = 0; i < detectionNum; i++){
        capEmp[i][0] = (int)Double.POSITIVE_INFINITY;
        capEmp[i][1] = (int)Double.NEGATIVE_INFINITY;
        capEmp[i][2] = 0;
        for(int j = 0; j < capVal[i].length; j++){
            capVal[i][j][0] = (int)Double.POSITIVE_INFINITY;
            capVal[i][j][1] = (int)Double.NEGATIVE_INFINITY;
            capVal[i][j][2] = 0;
        }
    }
}


void draw(){
    background(#ffffff);
    switch(stageNo){
        case 0:
            displayStartup();
            break;
        case 1:
            displayInstruction();
            break;
        case 2:
            displayExpCount();
            break;
        case 3:
            displayExpCountCorner();
            displayCapEmpDetection();
            break;
        case 4:
            displayExpCountCorner();
            displayCapEmpDetecting();
            completeDetectionIfNeeded();
            break;
        case 5:
            displayExpCountCorner();
            displayCapValDetection();
            break;
        case 6:
            displayExpCountCorner();
            displayInstructionSquare();
            break;
        case 7:
            displayExpCountCorner();
            displayDetectingSquare();
            completeDetectionIfNeeded();
            break;
        case 8:
            displayCompleteExp();
            saveData();
            frameCounter = 0;
            stageNo = 9;
            break;
        case 9:
            displayCompleteExp();
            if(frameCounter > fps * 3){
                exit();
            }
            break;
        default:
            break;
    }
    frameCounter++;
    if(isDetecting) {
        detectingCounter++;
    }
    //text((int)capValue, width / 2, height - 50);
}


/*-- 静電容量の計測値を格納 --*/
void detectCap(){
    if(isDetecting == false || detectingCounter >= detectionFrameNum || preDetectingCount == detectingCounter) return;
    preDetectingCount = detectingCounter;

    if(isTouched == false){
        if(capEmp[detectionCounter][0] > capValue){
            capEmp[detectionCounter][0] = capValue;
        }
        if(capEmp[detectionCounter][1] < capValue){
            capEmp[detectionCounter][1] = capValue;
        }
        capEmp[detectionCounter][2] += capValue;
    }else{
        if(capVal[detectionCounter][detectionOrder[squareCounter]][0] > capValue){
            capVal[detectionCounter][detectionOrder[squareCounter]][0] = capValue;
        }
        if(capVal[detectionCounter][detectionOrder[squareCounter]][1] < capValue){
            capVal[detectionCounter][detectionOrder[squareCounter]][1] = capValue;
        }
        capVal[detectionCounter][detectionOrder[squareCounter]][2] += capValue;
    }
    
}


/*-- 静電容量の計測完了時の処理 **/
void completeDetectionIfNeeded(){
    if(detectingCounter < detectionFrameNum) return;
    
    switch(stageNo){
        case 4:
            stageNo = 5;
            frameCounter = 0;
            capEmp[detectionCounter][2] /= detectingCounter;
            printArray(capEmp[detectionCounter]);
            break;
        case 7:
            if(squareCounter < squareQty){
                capVal[detectionCounter][detectionOrder[squareCounter]][2] /= detectingCounter;
                squareCounter++;
                stageNo = 6;
                frameCounter = 0;
            }
            if(squareCounter == squareQty){
                if(detectionCounter < detectionNum){
                    detectionCounter++;
                    stageNo = 2;
                    frameCounter = 0;
                }
                if(detectionCounter == detectionNum){
                    stageNo = 8;
                    frameCounter = 0;
                }
            }
            break;
        default:
            break;
    }
    detectingCounter = -1;
    isDetecting = false;
}


/*-- 実験開始画面 --*/
void displayStartup(){
    text(startupStr, width / 2, height / 2);
    if(keyPressed && key == ENTER){
        key = 0;
        stageNo = 1;
        frameCounter = 0;
    }
}


/*-- 実験指示の表示 --*/
void displayInstruction(){
    text(instructionStr, width / 2, height / 2);
    if(keyPressed && key == ENTER){
        key = 0;
        stageNo = 2;
        frameCounter = 0;
    }
}


/*-- 何回目の接触検知かを表示 --*/
void displayExpCount(){
    text(str(detectionCounter + 1) + expCountStr, width / 2, height / 2);
    if(frameCounter == fps * 3){
        stageNo = 3;
        frameCounter = 0;
    }
}


/*-- 何回目の接触検知かを左角に表示 --*/
void displayExpCountCorner(){
    textSize(24);
    textAlign(LEFT);
    text(str(detectionCounter + 1) + expCountCornerStr, 20, 50);
    textAlign(CENTER);
}


/*-- 非接触時の静電容量を計測する旨を表示 --*/
void displayCapEmpDetection(){
    text(capEmpDetectionStr, width / 2, height / 2);
    if(keyPressed && key == ENTER){
        key = 0;
        stageNo = 4;
        frameCounter = 0;
        isDetecting = true;
        isTouched = false;
    }
}


/*-- 非接触時の静電容量を計測中である旨を表示 --*/
void displayCapEmpDetecting(){
    fill(#aa2222);
    text(capEmpDetectingStr, width / 2, height / 2);
    fill(#000000);
}


/*-- 接触時の静電容量を計測する旨を表示 --*/
void displayCapValDetection(){
    text(capValDetectionStr, width / 2, height / 2);
    if(keyPressed && key == ENTER){
        key = 0;
        stageNo = 6;
        frameCounter = 0;
        squareCounter = 0;
        setDetectionOrder();
    }
}


/*-- 接触してもらうマス目の指示 --*/
void displayInstructionSquare(){
    text(instructionSquareStr, width / 2, 100);
    drawSquare();
    if(keyPressed && key == ENTER){
        key = 0;
        stageNo = 7;
        frameCounter = 0;
        isDetecting = true;
        isTouched = true;
    }
}


/*-- 計測中のマス目の指示 --*/
void displayDetectingSquare(){
    fill(#aa2222);
    text(capValDetectingStr, width / 2, 100);
    fill(#000000);
    drawSquare();
}


/*-- マス目の表示 --*/
void drawSquare(){
    int referencePointX = width / 2 - (displayHeight / 2 / 3) * 2;
    int referencePointY = height / 2 - (displayHeight / 2 / 3) * 2;
    noStroke();
    fill(#7fffff);
    rect(referencePointX + (displayHeight / 2 / 3) * (detectionOrder[squareCounter] % 3 + 1),
         referencePointY + (displayHeight / 2 / 3) * (floor(detectionOrder[squareCounter] / 3) + 1),
         (displayHeight / 2 / 3),(displayHeight / 2 / 3));
    
    stroke(#7fbfff);
    strokeWeight(2);
    noFill();
    rect(width / 2, height / 2, displayHeight / 2, displayHeight / 2);
    line(width / 2 - (displayHeight / 2 / 2) + (displayHeight / 2 / 3),
         height / 2 - (displayHeight / 2 / 2),
         width / 2 - (displayHeight / 2 / 2) + (displayHeight / 2 / 3),
         height / 2 + (displayHeight / 2 / 2));
    line(width / 2 - (displayHeight / 2 / 2) + (displayHeight / 2 / 3) * 2,
         height / 2 - (displayHeight / 2 / 2),
         width / 2 - (displayHeight / 2 / 2) + (displayHeight / 2 / 3) * 2,
         height / 2 + (displayHeight / 2 / 2));
    line(width / 2 - (displayHeight / 2 / 2),
         height / 2 - (displayHeight / 2 / 2) + (displayHeight / 2 / 3),
         width / 2 + (displayHeight / 2 / 2),
         height / 2 - (displayHeight / 2 / 2) + (displayHeight / 2 / 3));
    line(width / 2 - (displayHeight / 2 / 2),
         height / 2 - (displayHeight / 2 / 2) + (displayHeight / 2 / 3) * 2,
         width / 2 + (displayHeight / 2 / 2),
         height / 2 - (displayHeight / 2 / 2) + (displayHeight / 2 / 3) * 2);
    fill(#000000);
}


/*-- 実験完了の旨を表示 --*/
void displayCompleteExp(){
    text(completeExpStr, width / 2, height / 2);
}


/*-- 静電容量を検出するマス目の順番をランダムに設定する --*/
void setDetectionOrder(){
    for(int i = 0; i < detectionOrder.length; i++){
        detectionOrder[i] = -1;
    }
    for(int i = 0; i < detectionOrder.length; i++){
        int index = floor(random(9));
        for(int j = 0; j <= i; j++){
            if(detectionOrder[j] == index){
                i--;
                break;
            }
            if(j == i){
                detectionOrder[j] = index;
            }
        }
    }
}


/*-- 実験データのファイル出力 --*/
void saveData(){
    // 各回のマス目ごとのデータ出力
    writer = createWriter("result/per_square.csv");
    for(int i = 0; i < detectionNum; i++){
        writer.println(str((int)capEmp[i][0]) + "," +
                      str((int)capEmp[i][1]) + "," +
                      str((int)capEmp[i][2]) + ",");
        for(int j = 0; j < squareQty; j++){
            writer.println(str((int)capVal[i][j][0]) + "," +
                           str((int)capVal[i][j][1]) + "," +
                           str((int)capVal[i][j][2]) + ",");
        }
    }
    writer.flush();
    writer.close();

    // 各回の全てのマス目のデータを統合したデータ出力
    writer = createWriter("result/all_square.csv");
    for(int i = 0; i < detectionNum; i++){
        writer.println(str((int)capEmp[i][0]) + "," +
                       str((int)capEmp[i][1]) + "," +
                       str((int)capEmp[i][2]) + ",");
        double[] mma = getMMA(capVal[i]);
        writer.println(str((int)mma[0]) + "," +
                       str((int)mma[1]) + "," +
                       str((int)mma[2]) + ",");
    }
    writer.flush();
    writer.close();
}

/** 2次元配列の中から最小・最大・平均を格納した配列を返す **/
double[] getMMA(double[][] box){
    double min = (int)Double.POSITIVE_INFINITY;
    double max = (int)Double.NEGATIVE_INFINITY;
    double avg = 0;
    for(int i = 0; i < box.length; i++){
        if(box[i][0] < min) min = box[i][0];
        if(box[i][1] > max) max = box[i][1];
        avg += box[i][2] * detectionFrameNum;
    }
    avg /= detectionFrameNum * box.length;
    return new double[]{min, max, avg};
}

/*-- シリアル通信 --*/
void serialEvent(Serial p){
    // 改行区切りでデータを読み込む (¥n == 10)
    String inString = p.readStringUntil(10);
    try{
        if(inString != null){
            inString = trim(inString);
            capValue = Long.valueOf(inString);
        }
    }catch(Exception e){
        e.printStackTrace();
    }
    detectCap();
}