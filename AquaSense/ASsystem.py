import pyrebase
import time
from log_data import log_data

# import required libraries for Temperature sensor
import glob

# import required libraries for pH sensor
import board
import busio
import adafruit_ads1x15.ads1115 as ADS
from adafruit_ads1x15.analog_in import AnalogIn

min_voltage = 0.10
max_voltage = 2.20

config = {
	 "apiKey": "AIzaSyAWBHIL31na4QOi4kZ2yDK9ic4YRo-UBEQ",
 	 "authDomain": "aquaculture-e52cb.firebaseapp.com",
 	 "databaseURL": "https://aquaculture-e52cb-default-rtdb.asia-southeast1.firebasedatabase.app",
 	 "projectId": "aquaculture-e52cb",
	 "storageBucket": "aquaculture-e52cb.firebasestorage.app",
 	 "messagingSenderId": "642958416070",
 	 "appId": "1:642958416070:web:cc8d420a35be8b2b855fc7",
 	 "measurementId": "G-ZLTRV2N80P"
	};

firebase = pyrebase.initialize_app(config)
db = firebase.database()


base_dir = '/sys/bus/w1/devices/'
device_folder = glob.glob(base_dir + '28*')
if not device_folder:
	print("DS18B20notr detected. Check wiring!")
	exit(1)
device_file = device_folder[0] + '/w1_slave'

def read_temp_raw():
	with open(device_file, 'r') as f:
		return f.readlines()

def read_temp():
	lines = read_temp_raw()
	while lines[0].strip()[-3:] != 'YES':
		time.sleep(0.2)
		lines = read_temp_raw()
	equals_pos = lines[1].find('t=')
	if equals_pos != -1:
		temp_string = lines[1][equals_pos+2:]
		temp_c = float(temp_string) / 1000.0
		return temp_c
	else:
		return None

def voltage_to_ntu(voltage, clear_voltage = 1.90, cloudy_voltage = 0.92, max_ntu = 100):
	voltage = max(min(voltage, clear_voltage), cloudy_voltage)
	percent = (clear_voltage - voltage) / (clear_voltage - cloudy_voltage)
	ntu = percent * max_ntu
	return round(ntu, 2)


i2c = busio.I2C(board.SCL, board.SDA)
ads = ADS.ADS1115(i2c)
chan = AnalogIn(ads, ADS.P0)
chan_water = AnalogIn(ads, ADS.P1)
chan_turbidity = AnalogIn(ads, ADS.P2)

def get_water_level_percent(water_level, min_voltage, max_voltage):
	percent = (water_level - min_voltage) / (max_voltage - min_voltage) * 100
	percent = max(0, min(100, percent))
	return percent

try:
	while True:

		temperature = read_temp()
		voltage = chan.voltage
		ph_value = 7 - ((2.5 - voltage) / 0.18) - 0.4
		water_level = chan_water.voltage
		water_level_percent = get_water_level_percent(water_level, min_voltage, max_voltage)
		turbidity_voltage = chan_turbidity.voltage
		turbidity_ntu = voltage_to_ntu(turbidity_voltage)

		if temperature is not None and ph_value is not None and water_level is not None and turbidity_ntu is not None:
			temperature = round(temperature, 2)
			ph_value = round(ph_value, 2)
			water_level_percent = round(water_level_percent, 1)
			turbidity_voltage = round(turbidity_voltage, 3)
			turbidity_ntu = round(turbidity_ntu,2)
			log_data(temperature, ph_value, water_level_percent, turbidity_ntu)
			print("Temperature: {:.2f} C, pH Voltage: {:.3f} V, Estimated pH: {:.2f}, Water level sensor voltage: {:.2f}, Water level: {:.1f}%, Turbidity: {:.2f} NTU, Turbidity Voltage: {:.3f} V) ".format(temperature, voltage, ph_value, water_level,  water_level_percent, turbidity_ntu, turbidity_voltage))

			data = {
				"temperature_C": temperature,
				"pH Value": ph_value,
				"Water Level": water_level_percent,
				"Turbidity_NTU": turbidity_ntu
				}

			db.child("Sensors").set(data)
			print("Data uploaded to Firebase:", data)

		else:
			print("Sensor reading failed. Check connection.")

		time.sleep(1)

except KeyboardInterrupt:
	print("\nProgram stopped manually")
