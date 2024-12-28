import os

RMQ_CONFIG = {
  'credentials': {
    'username': 'admin',
    'password': os.environ['rmq_passwd']
  },
  'host': os.environ['rmq_ip'],
  'exchange': 'applicare',
  'queue': 'backend_queue'
}

SCRAPING_CONFIG = {
  'rate_limit': 1, # seconds between requests
  'headers': {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  },
  'retail_urls': {
    'homedepot': 'https://www.homedepot.com/b/Appliances',
    'lowes': 'https://www.lowes.com/l/shop/appliances'
  },
  'parts_urls': {
    'repairclinic': 'https://www.repairclinic.com',
    'partselect': 'https://www.partselect.com',
    'appliancepartspros': 'https://www.appliancepartspros.com'
  },
  'manufacturer_urls': {
    'whirlpool': 'https://www.whirlpoolparts.com/',
    'lg': 'https://lgparts.com/',
    'samsung': 'https://samsungparts.com/', # 'https://www.samsung.com/us/support/',
    'ge': 'https://www.geappliances.com/ge/parts/'
  }
}

APPLIANCE_PROBLEMS = {
  'washer': {
    'drum': ['bearing', 'belt', 'motor', 'seal'],
    'control': ['panel', 'board', 'buttons', 'display'],
    'water_system': ['pump', 'hose', 'valve', 'filter'],
    'door': ['lock', 'seal', 'hinge', 'handle']
  },
  'dryer': {
    'heating': ['element', 'thermostat', 'fuse', 'gas_valve'],
    'airflow': ['vent', 'blower', 'duct', 'filter'],
    'drum': ['belt', 'roller', 'glide', 'bearing'],
    'control': ['panel', 'board', 'timer', 'switch']
  },
  'refrigerator': {
    'cooling': ['compressor', 'evaporator', 'condenser', 'fan'],
    'defrost': ['heater', 'timer', 'thermostat', 'sensor'],
    'ice_maker': ['motor', 'valve', 'mold', 'ejector'],
    'sealing': ['gasket', 'door_seal', 'hinge', 'closure']
  }
}

APPLIANCE_FILTERS = { # demo has limited scope
  'types': ['washer', 'dryer', 'refrigerator'],
  'brands': ['whirlpool', 'lg', 'samsung', 'ge'] #, 'frigidaire', 'maytag']
}

DB_CONFIG = {
  'select_appliances': '''
    SELECT brand, model, type 
    FROM appliances 
    WHERE type IN (%s) AND brand IN (%s)
  ''',
  'insert_appliance': '''
    INSERT INTO appliances (brand, model, type, source, url) 
    VALUES (%(brand)s, %(model)s, %(type)s, %(source)s, %(url)s)
    ON DUPLICATE KEY UPDATE 
    source = VALUES(source), 
    url = VALUES(url)
  ''',
  'insert_part': '''
    INSERT INTO parts 
    (part_name, part_number, price, type, problem_area, source, url, appliance_model) 
    VALUES 
    (%(name)s, %(part_number)s, %(price)s, %(type)s, %(problem_area)s, %(source)s, %(url)s, %(appliance_model)s)
  '''
}

TEST_CONFIG = { # for testing purposes
  'enabled': True,
  'output_file': 'scraper_test_output.json',
  'mock_db_response': {
    'results': [
      {'brand': 'whirlpool', 'model': 'WTW5000DW', 'type': 'washer'},
      {'brand': 'lg', 'model': 'WM3900HWA', 'type': 'washer'},
      {'brand': 'samsung', 'model': 'RF28R7551SR', 'type': 'refrigerator'}
    ]
  },
  'mock_scraped_data': {
    'repairclinic': [
      {
        'name': 'Washer Drive Belt',
        'part_number': 'WPW10006384',
        'price': '$29.99',
        'type': 'belt',
        'problem_area': 'drum',
        'source': 'repairclinic',
        'url': 'https://www.repairclinic.com/part/details/washer-belt-wp10006384'
      },
      {
        'name': 'Door Boot Seal',
        'part_number': 'WPW10290499',
        'price': '$89.99',
        'type': 'seal',
        'problem_area': 'door',
        'source': 'repairclinic',
        'url': 'https://www.repairclinic.com/part/details/door-seal-wp10290499'
      }
    ],
    'partselect': [
      {
        'name': 'Water Pump',
        'part_number': 'LP6000',
        'price': '$45.99',
        'type': 'pump',
        'problem_area': 'water_system',
        'source': 'partselect',
        'url': 'https://www.partselect.com/parts/LP6000-water-pump'
      }
    ],
    'whirlpool': [
      {
        'name': 'Control Board Assembly',
        'part_number': 'W10480777',
        'price': '$159.99',
        'type': 'board',
        'problem_area': 'control',
        'source': 'whirlpool',
        'url': 'https://www.whirlpoolparts.com/parts/W10480777'
      }
    ],
    'samsung': [
      {
        'name': 'Refrigerator Compressor',
        'part_number': 'DA97-12540A',
        'price': '$249.99',
        'type': 'compressor',
        'problem_area': 'cooling',
        'source': 'samsung',
        'url': 'https://samsungparts.com/products/DA97-12540A'
      },
      {
        'name': 'Evaporator Fan Motor',
        'part_number': 'DA31-00028E',
        'price': '$89.99',
        'type': 'fan',
        'problem_area': 'cooling',
        'source': 'samsung',
        'url': 'https://samsungparts.com/products/DA31-00028E'
      }
    ]
  }
}