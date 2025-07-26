# Fishly - IoT Aquaculture Monitoring System 🐟

A comprehensive IoT solution for monitoring aquaculture systems using Flutter mobile app, Raspberry Pi sensors, and Firebase real-time database.

## 📱 Features

### Mobile App (Flutter)
- **Real-time sensor monitoring** - Temperature, pH, water level, and turbidity
- **Interactive charts** - Historical data visualization with FL Chart
- **Smart notifications** - Critical alerts when values exceed safe ranges
- **Multi-pond support** - Monitor multiple aquaculture systems
- **Dark/Light themes** - Customizable UI experience
- **Unit conversion** - Metric/Imperial temperature units

### Sensor Monitoring
- **Temperature**: DS18B20 waterproof sensor (Safe range: 20-30°C)
- **pH Level**: Analog pH sensor (Safe range: 6.5-8.5)
- **Water Level**: Analog water level sensor (Alert when >80%)
- **Turbidity**: Analog turbidity sensor (Alert when >80 NTU)

### Backend Services
- **Firebase Realtime Database** - Live sensor data storage
- **Firebase Functions** - Automated threshold monitoring
- **Local SQLite logging** - Backup data storage on Raspberry Pi

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Raspberry Pi   │───▶│   Firebase      │───▶│  Flutter App    │
│  + Sensors      │    │   Database      │    │  (Mobile)       │
│  + Python       │    │  + Functions    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                        │                        │
        ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Local SQLite    │    │  Notifications  │    │ Real-time       │
│ Database        │    │  & Alerts       │    │ Monitoring      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Getting Started

### Prerequisites
- **Hardware**: Raspberry Pi, DS18B20, pH sensor, water level sensor, turbidity sensor, ADS1115 ADC
- **Software**: Flutter SDK, Firebase account, Python 3.x
- **Services**: Firebase project with Realtime Database enabled

### Hardware Setup
1. Connect DS18B20 temperature sensor to GPIO pin
2. Connect analog sensors to ADS1115 ADC:
   - pH sensor → A0
   - Water level sensor → A1  
   - Turbidity sensor → A2
3. Connect ADS1115 to Raspberry Pi I2C pins

### Software Installation

#### 1. Raspberry Pi Setup
```bash
# Install required Python packages
pip install pyrebase4 adafruit-circuitpython-ads1x15

# Clone and setup sensor reading script
# Update Firebase config in read_temp_ph_level.py
python read_temp_ph_level.py
```

#### 2. Flutter App Setup
```bash
# Install Flutter dependencies
flutter pub get

# Configure Firebase
# Add your google-services.json (Android) and GoogleService-Info.plist (iOS)

# Run the app
flutter run
```

#### 3. Firebase Functions Setup
```bash
# Initialize and deploy monitoring functions
firebase init functions
firebase deploy --only functions
```

## 📊 Sensor Specifications

| Sensor | Range | Safe Values | Alert Conditions |
|--------|-------|-------------|------------------|
| **Temperature** | 0-100°C | 20-30°C | < 20°C or > 30°C |
| **pH Level** | 0-14 pH | 6.5-8.5 | < 6.5 or > 8.5 |
| **Water Level** | 0-100% | < 80% | ≥ 80% |
| **Turbidity** | 0-100+ NTU | < 80 NTU | ≥ 80 NTU |

## 🔧 Configuration

### Firebase Configuration
Update `read_temp_ph_level.py` with your Firebase credentials:
```python
config = {
    "apiKey": "your-api-key",
    "authDomain": "your-project.firebaseapp.com", 
    "databaseURL": "https://your-project.firebasedatabase.app",
    "projectId": "your-project-id",
    "storageBucket": "your-project.appspot.com",
    "messagingSenderId": "your-sender-id",
    "appId": "your-app-id"
}
```

### Sensor Calibration
- **pH Sensor**: Calibrate using pH 4.0, 7.0, and 10.0 buffer solutions
- **Temperature**: DS18B20 is factory calibrated
- **Water Level**: Adjust voltage thresholds based on tank height
- **Turbidity**: Calibrate with known NTU standards

## 📱 App Screenshots

- **Monitor Page**: Real-time sensor readings with status indicators
- **Statistics Page**: Historical data with interactive charts  
- **Notifications**: Critical alerts and system status
- **Profile**: Settings, units, and user preferences

## 🔔 Notification System

The system automatically monitors sensor values and sends notifications when:
- Temperature exceeds safe aquaculture ranges
- pH levels become harmful to fish
- Water levels require attention
- Turbidity indicates water quality issues

## 🐛 Troubleshooting

### Common Issues
- **Negative pH readings**: Check sensor wire connections
- **Constant notifications**: Verify threshold values in Firebase Functions
- **No sensor data**: Ensure Raspberry Pi sensors are properly connected
- **App crashes**: Check Firebase configuration and internet connectivity

### Sensor Debugging
```python
# Add debug output to see raw sensor values
print(f"Raw voltage: {voltage:.3f}V, Calculated pH: {ph_value:.2f}")
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- Create an issue in this repository
- Check the troubleshooting section above
- Review Firebase and Flutter documentation

## 🎯 Future Enhancements

- [ ] Water quality predictions using ML
- [ ] Multiple farm management
- [ ] Export data analytics
- [ ] Integration with feeding systems
- [ ] Weather API integration
- [ ] Multi-language support

---

**Built with ❤️ for sustainable aquaculture monitoring**
