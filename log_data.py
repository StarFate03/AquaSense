import sqlite3
from datetime import datetime

def log_data(temperature, ph_value, water_level_percent, turbidity):
	conn = sqlite3.connect('aquaculture.db')
	c = conn.cursor()

	c.execute('''CREATE TABLE IF NOT EXISTS sensor_data
			(id INTEGER PRIMARY KEY AUTOINCREMENT,
			timestamp TEXT,
			temperature REAL,
			ph_value REAL,
			water_level_percent REAL,
			turbidity REAL)''')

	timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
	c.execute('INSERT INTO sensor_data (timestamp, temperature, ph_value, water_level_percent, turbidity) VALUES (?, ?, ?, ?, ?)',
		(timestamp, temperature, ph_value, water_level_percent, turbidity))
	conn.commit()
	conn.close()
