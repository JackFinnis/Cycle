import json

with open('CycleRoutes.json', 'r') as f:
    routes = json.load(f)['features']

newRoutes = []

for feature in routes:
    route = {}
    coords = []

    route['coords'] = coords
