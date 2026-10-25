/*
  GuvenYuzuk v0.2 - Hareketsizlik / titreme / SOS takip firmware'i
  Kart : Seeed Studio XIAO nRF52840 Sense
  Kart paketi : "Seeed nRF52 Boards" (mbed OLMAYAN surum)
  Kutuphane   : "Seeed Arduino LSM6DS3"

  Telefona Bluetooth (Nordic UART servisi) uzerinden su satirlari gonderir:
    HB,<sira>,<hareket>,<siddet>,<pil_mV>,<pil_%>,<bayrak>   -> kalp atisi (varsayilan 30 sn)
    RAW,<delta_milli_g>                                      -> saniyede 5 kez (RAW,1 acikken)
    VER,0.2                                                  -> VER? sorgusuna yanit
    SOS,<sira>                                               -> kullanici 3 kez hizlica vurdu
    TRM,<sira>                                               -> uzun sureli ritmik titreme
  bayrak: bit0 = son periyotta SOS oldu, bit1 = son periyotta titreme oldu

  Telefondan gelen komutlar:
    VER?                                                     -> surum sorusu, "VER,0.2\n" doner
    RAW,1 / RAW,0                                            -> canli ivme akisini acar / kapatir
    CFG,<esik_mg>,<aralik_sn>                                -> hareket esigi ve kalp atisi araligini gunceller
    BUZ,<ms>                                                 -> bildirim / LED yak
    ACK,<sira>                                               -> SOS veya TRM teyidi
*/

#include <bluefruit.h>
#include <LSM6DS3.h>
#include <Wire.h>
#include <math.h>

// ======================= AYARLAR =======================
float    moveThresholdG   = 0.025f; // |dX|+|dY|+|dZ| bunu asarsa "mikro hareket" (CFG ile degisebilir)
uint32_t heartbeatMs      = 30000;  // kalp atisi araligi (CFG ile degisebilir)

// SOS: kisa surede art arda vurus
const float    TAP_THRESHOLD_G    = 0.90f;  // vurus sayilacak ani sarsinti
const uint8_t  TAP_COUNT_FOR_SOS  = 3;      // kac vurus SOS sayilsin
const uint16_t TAP_DEBOUNCE_MS    = 80;     // ayni vurusu iki kez saymamak icin
const uint16_t TAP_WINDOW_MS      = 1200;   // vuruslarin hepsi bu sure icinde olmali

// Titreme dedektoru (deneysel)
const float    TREMOR_MIN_HZ      = 3.0f;
const float    TREMOR_MAX_HZ      = 8.0f;
const float    TREMOR_MIN_ENERGY  = 0.0015f; // g^2, kalibre edilecek
const uint8_t  TREMOR_WINDOWS     = 10;      // 10 x 2 sn = 20 sn kesintisiz titreme
const uint32_t TREMOR_COOLDOWN_MS = 60000;   // alarmdan sonra tekrar icin bekleme

#define DEBUG_PRINT 0   // 1 yaparsan Seri Monitore kalibrasyon verisi basar
// =======================================================

const uint16_t SAMPLE_MS      = 10;   // 100 Hz ornekleme
const uint16_t WINDOW_SAMPLES = 200;  // 2 sn'lik titreme penceresi

LSM6DS3 imu(I2C_MODE, 0x6A);
BLEUart bleuart;
BLEDis  bledis;

// Durum degiskenleri
float px = 0, py = 0, pz = 0;
bool  firstSample = true;

uint32_t moveCount = 0;
float    intensitySum = 0;
uint8_t  seq = 0;
uint8_t  flags = 0;
bool     pendingSos = false;
bool     pendingTremor = false;

// Canli hareket (RAW) ve komut durumlari
bool     rawMode = false;
uint32_t nextRaw = 0;
float    rawMaxDelta = 0;
String   rxBuffer = "";

uint8_t  tapCount = 0;
uint32_t firstTapMs = 0, lastTapMs = 0;

float    lowPass = 1.0f;
float    prevHp = 0;
int8_t   hpState = 0;
uint16_t crossings = 0;
float    energySum = 0;
uint16_t windowN = 0;
uint8_t  tremorStreak = 0;
uint32_t lastTremorAlarm = 0;

uint32_t lastHeartbeat = 0;
uint32_t nextSample = 0;

// Fonksiyon bildirimleri
void ledBlink(uint8_t pin, uint8_t times);
uint16_t readBatteryMv();
uint8_t batteryPercent(uint16_t mv);
void sendLine(const String &line);
void sendEvent(const char *type);
void onConnect(uint16_t conn);
void onDisconnect(uint16_t conn, uint8_t reason);
void setupBle();
void handleTap(float delta, uint32_t now);
void handleTremor(float x, float y, float z, uint32_t now);
void processCommand(String cmd);
void checkBleUartRx();

// ---------------- Yardimcilar ----------------
void ledBlink(uint8_t pin, uint8_t times) {
  for (uint8_t i = 0; i < times; i++) {
    digitalWrite(pin, LOW);  delay(80);   // XIAO LED'leri ters mantik: LOW = yanik
    digitalWrite(pin, HIGH); delay(80);
  }
}

uint16_t readBatteryMv() {
#if defined(PIN_VBAT) && defined(VBAT_ENABLE)
  uint32_t raw = analogRead(PIN_VBAT);
  // 1M / 510k gerilim bolucu, 2.4V referans, 12 bit
  float mv = raw * (2400.0f / 4095.0f) * (1510.0f / 510.0f);
  return (uint16_t)mv;
#else
  return 0;
#endif
}

uint8_t batteryPercent(uint16_t mv) {
  if (mv >= 4150) return 100;
  if (mv <= 3300) return 0;
  if (mv >= 3800) return 60 + (mv - 3800) * 40 / 350;   // 3.80-4.15V -> %60-100
  return (mv - 3300) * 60 / 500;                        // 3.30-3.80V -> %0-60
}

void sendLine(const String &line) {
  Serial.println(line);
  if (Bluefruit.connected() && bleuart.notifyEnabled()) {
    bleuart.print(line + "\n");
  }
}

void sendEvent(const char *type) {
  seq++;
  String line = String(type) + "," + String(seq);
  sendLine(line);
}

// ---------------- BLE Komut Yonetimi ----------------
void processCommand(String cmd) {
  cmd.trim();
  if (cmd.length() == 0) return;

  if (cmd == "VER?") {
    sendLine("VER,0.2");
  } else if (cmd == "RAW,1") {
    rawMode = true;
    rawMaxDelta = 0;
    nextRaw = millis() + 200;
  } else if (cmd == "RAW,0") {
    rawMode = false;
  } else if (cmd.startsWith("CFG,")) {
    int firstComma = cmd.indexOf(',');
    int secondComma = cmd.indexOf(',', firstComma + 1);
    if (firstComma > 0) {
      if (secondComma > 0) {
        int th = cmd.substring(firstComma + 1, secondComma).toInt();
        int interval = cmd.substring(secondComma + 1).toInt();
        if (th >= 5 && th <= 200) moveThresholdG = th / 1000.0f;
        if (interval >= 5 && interval <= 120) heartbeatMs = (uint32_t)interval * 1000;
      } else {
        int th = cmd.substring(firstComma + 1).toInt();
        if (th >= 5 && th <= 200) moveThresholdG = th / 1000.0f;
      }
    }
  } else if (cmd.startsWith("BUZ,")) {
    int comma = cmd.indexOf(',');
    int ms = (comma > 0) ? cmd.substring(comma + 1).toInt() : 100;
    if (ms > 0 && ms <= 3000) {
      ledBlink(LED_BLUE, 2);
    }
  } else if (cmd.startsWith("ACK,")) {
    // SOS / TRM onaylandi
  }
}

void checkBleUartRx() {
  while (bleuart.available()) {
    char c = (char)bleuart.read();
    if (c == '\n' || c == '\r') {
      if (rxBuffer.length() > 0) {
        processCommand(rxBuffer);
        rxBuffer = "";
      }
    } else if (rxBuffer.length() < 64) {
      rxBuffer += c;
    }
  }
}

// ---------------- BLE ----------------
void onConnect(uint16_t conn) {
  Serial.println("Telefon baglandi");
  rawMode = false;
  rawMaxDelta = 0;
  rxBuffer = "";
  // Bekleyen olaylari baglanir baglanmaz ilet
  delay(500);
  if (pendingSos)    { sendEvent("SOS"); }
  if (pendingTremor) { sendEvent("TRM"); }
  pendingSos = pendingTremor = false;
}

void onDisconnect(uint16_t conn, uint8_t reason) {
  Serial.print("Baglanti koptu, sebep 0x");
  Serial.println(reason, HEX);
  rawMode = false;
  rxBuffer = "";
}

void setupBle() {
  Bluefruit.autoConnLed(false);          // mavi LED'i kapat (pil tasarrufu)
  Bluefruit.begin();
  Bluefruit.setTxPower(4);               // vucut sinyali zayiflatir, biraz guclu tut
  Bluefruit.setName("GuvenYuzuk");
  Bluefruit.Periph.setConnInterval(160, 320);  // 200-400 ms: az enerji
  Bluefruit.Periph.setConnectCallback(onConnect);
  Bluefruit.Periph.setDisconnectCallback(onDisconnect);

  bledis.setManufacturer("DIY");
  bledis.setModel("GuvenYuzuk v0.2");
  bledis.begin();

  bleuart.begin();

  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  Bluefruit.Advertising.addService(bleuart);
  Bluefruit.ScanResponse.addName();
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(160, 1600);  // once hizli, sonra yavas yayin
  Bluefruit.Advertising.setFastTimeout(30);
  Bluefruit.Advertising.start(0);                // surekli yayin
}

// ---------------- Algilama ----------------
void handleTap(float delta, uint32_t now) {
  if (delta < TAP_THRESHOLD_G) return;
  if (now - lastTapMs < TAP_DEBOUNCE_MS) return;

  if (tapCount == 0 || now - firstTapMs > TAP_WINDOW_MS) {
    tapCount = 1;
    firstTapMs = now;
  } else {
    tapCount++;
  }
  lastTapMs = now;

  if (tapCount >= TAP_COUNT_FOR_SOS) {
    tapCount = 0;
    flags |= 0x01;
    if (Bluefruit.connected()) sendEvent("SOS");
    else pendingSos = true;
    ledBlink(LED_RED, 3);   // kullaniciya "SOS alindi" geri bildirimi
  }
}

void handleTremor(float x, float y, float z, uint32_t now) {
  float mag = sqrtf(x * x + y * y + z * z);
  lowPass += 0.05f * (mag - lowPass);      // ~0.8 Hz alcak geciren
  float hp = mag - lowPass;                // yercekimi/yavas hareket ayiklandi

  energySum += hp * hp;

  // Histerezisli sifir gecisi sayimi
  const float H = 0.01f;
  if (hpState <= 0 && hp > H)  { if (hpState < 0) crossings++; hpState = 1; }
  if (hpState >= 0 && hp < -H) { if (hpState > 0) crossings++; hpState = -1; }

  if (++windowN < WINDOW_SAMPLES) return;

  float seconds = WINDOW_SAMPLES * SAMPLE_MS / 1000.0f;
  float freq    = crossings / 2.0f / seconds;
  float energy  = energySum / WINDOW_SAMPLES;

#if DEBUG_PRINT
  Serial.print("tremor f="); Serial.print(freq, 1);
  Serial.print(" e=");       Serial.println(energy, 5);
#endif

  bool rhythmic = (freq >= TREMOR_MIN_HZ && freq <= TREMOR_MAX_HZ &&
                   energy >= TREMOR_MIN_ENERGY);
  tremorStreak = rhythmic ? tremorStreak + 1 : 0;

  if (tremorStreak >= TREMOR_WINDOWS && now - lastTremorAlarm > TREMOR_COOLDOWN_MS) {
    lastTremorAlarm = now;
    tremorStreak = 0;
    flags |= 0x02;
    if (Bluefruit.connected()) sendEvent("TRM");
    else pendingTremor = true;
  }

  windowN = 0; crossings = 0; energySum = 0;
}

// ---------------- Arduino ----------------
void setup() {
  Serial.begin(115200);

  pinMode(LED_RED, OUTPUT);   digitalWrite(LED_RED, HIGH);
  pinMode(LED_GREEN, OUTPUT); digitalWrite(LED_GREEN, HIGH);
  pinMode(LED_BLUE, OUTPUT);  digitalWrite(LED_BLUE, HIGH);

#if defined(PIN_VBAT) && defined(VBAT_ENABLE)
  // VBAT_ENABLE surekli LOW kalmali (sarj sirasinda pin guvenligi icin)
  pinMode(VBAT_ENABLE, OUTPUT);
  digitalWrite(VBAT_ENABLE, LOW);
  analogReference(AR_INTERNAL_2_4);
  analogReadResolution(12);
#endif

#ifdef PIN_LSM6DS3TR_C_POWER
  pinMode(PIN_LSM6DS3TR_C_POWER, OUTPUT);
  digitalWrite(PIN_LSM6DS3TR_C_POWER, HIGH);
  delay(20);
#endif

  // Hassas ve dusuk guclu IMU ayari
  imu.settings.gyroEnabled     = 0;    // jiroskop kapali: pil tasarrufu
  imu.settings.accelEnabled    = 1;
  imu.settings.accelRange      = 2;    // +-2g: en hassas aralik
  imu.settings.accelSampleRate = 104;  // Hz
  imu.settings.accelBandWidth  = 50;

  if (imu.begin() != 0) {
    Serial.println("HATA: Hareket sensoru baslatilamadi!");
    while (1) ledBlink(LED_RED, 1);
  }

  setupBle();
  ledBlink(LED_GREEN, 2);   // "hazirim"
  Serial.println("GuvenYuzuk hazir");

  lastHeartbeat = millis();
  nextSample = millis();
}

void loop() {
  uint32_t now = millis();

  // Telefondan gelen Bluetooth komutlarini dinle
  if (Bluefruit.connected()) {
    checkBleUartRx();
  }

  if ((int32_t)(now - nextSample) >= 0) {
    nextSample += SAMPLE_MS;

    float x = imu.readFloatAccelX();
    float y = imu.readFloatAccelY();
    float z = imu.readFloatAccelZ();

    if (firstSample) {
      px = x; py = y; pz = z;
      lowPass = sqrtf(x * x + y * y + z * z);
      firstSample = false;
    }

    float delta = fabsf(x - px) + fabsf(y - py) + fabsf(z - pz);
    px = x; py = y; pz = z;

    if (delta > rawMaxDelta) {
      rawMaxDelta = delta;
    }

    if (delta > moveThresholdG) {
      if (moveCount < 65535) moveCount++;
      intensitySum += delta;
    }

#if DEBUG_PRINT
    static uint8_t dbg = 0;
    if (++dbg >= 10) { dbg = 0; Serial.print("delta:"); Serial.println(delta, 4); }
#endif

    handleTap(delta, now);
    handleTremor(x, y, z, now);
  }

  // Canli hareket bildirimi (RAW, saniyede 5 kez = 200 ms)
  if (rawMode && (int32_t)(now - nextRaw) >= 0) {
    nextRaw = now + 200;
    uint16_t mg = (uint16_t)(rawMaxDelta * 1000.0f);
    sendLine("RAW," + String(mg));
    rawMaxDelta = 0;
  }

  // Durum sinyali (Kalp atisi)
  if (now - lastHeartbeat >= heartbeatMs) {
    lastHeartbeat = now;
    uint16_t mv = readBatteryMv();
    uint32_t inten = (uint32_t)(intensitySum * 100.0f);
    if (inten > 65535) inten = 65535;

    seq++;
    String line = "HB," + String(seq) + "," + String(moveCount) + "," +
                  String(inten) + "," + String(mv) + "," +
                  String(batteryPercent(mv)) + "," + String(flags);
    sendLine(line);

    moveCount = 0;
    intensitySum = 0;
    flags = 0;
  }

  // Bir sonraki ornege kadar islemciyi dinlendir (FreeRTOS delay = uyku)
  int32_t wait = (int32_t)(nextSample - millis());
  if (wait > 0) delay(wait);
}

