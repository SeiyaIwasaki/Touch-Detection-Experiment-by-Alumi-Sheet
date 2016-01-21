/********************************************
    アルミ箔を内包した布スイッチにおける
    指の接触検知の実験
    
    2015 Iwasaki Seiya
********************************************/

#include <CapacitiveSensor.h>		// 静電容量センサライブラリ

#define SAMPLING 30                     // サンプリング数（精度と計測時間はトレードオフ）
#define TRANS_PIN 2                     // センサ送信ピン番号
#define RECIEVE_PIN 3                   // センサ受信ピン番号

CapacitiveSensor *sensor;               // 静電容量計測クラス

void setup() {
    
    /** 静電容量計測クラスの初期化 **/
    sensor = new CapacitiveSensor(TRANS_PIN, RECIEVE_PIN);
    sensor->set_CS_AutocaL_Millis(0xFFFFFFFF);
    sensor->reset_CS_AutoCal();

    /** シリアル通信 **/
    Serial.begin(9600);
}

void loop() {
    
    /** 静電容量を測定して送信する **/
    delay(10);
    long value = sensor->capacitiveSensor(SAMPLING);
    Serial.print(value);
    Serial.println();

}
