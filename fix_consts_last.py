import os

files = [
    "lib/presentation/screens/create_plan_screen.dart",
    "lib/presentation/screens/active_workout_screen.dart"
]

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    content = content.replace('const Text(', 'Text(')
    content = content.replace('const InputDecoration(', 'InputDecoration(')
    
    with open(f, 'w') as file:
        file.write(content)

